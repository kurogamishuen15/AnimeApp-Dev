import 'dart:async';
import 'dart:io';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/animesdigital/animesdigital_html_parser.dart';
import 'package:anime_app/data/player/providers/animesdigital/animesdigital_playback_provider.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'searches exact titles and lazily finds the requested episode',
    () async {
      final List<String> requests = [];
      final HttpServer server = await _server((HttpRequest request) async {
        requests.add(request.uri.path);
        switch (request.uri.path) {
          case '/':
            await _html(request, '<a href="/anime/a/one-piece/">One Piece</a>');
          case '/anime/a/one-piece/':
            await _html(request, '''
            <a href="/anime/a/one-piece/page/2/">Older</a>
            <a href="/video/a/3/">One Piece Episódio 3</a>
            ''');
          case '/anime/a/one-piece/page/2/':
            await _html(
              request,
              '<a href="/video/a/1/">One Piece Episódio 1</a>',
            );
          default:
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
        }
      });
      addTearDown(() => server.close(force: true));
      final AnimesDigitalPlaybackProvider provider = _provider(server);
      addTearDown(provider.close);

      final PlaybackProviderResult<List<SourceAnimeMatch>> search =
          await provider.searchAnime(
            _identity(),
            cancellation: PlaybackCancellationToken(),
          );
      expect(search, isA<PlaybackProviderSuccess<List<SourceAnimeMatch>>>());
      final SourceAnimeMatch match =
          (search as PlaybackProviderSuccess<List<SourceAnimeMatch>>)
              .value
              .single;
      expect(match.evidence, AnimeMatchEvidence.exactTitle);

      final PlaybackProviderResult<EpisodeRef> episode = await provider
          .findEpisode(
            match,
            episodeNumber: 1,
            cancellation: PlaybackCancellationToken(),
          );
      expect(
        episode,
        isA<PlaybackProviderSuccess<EpisodeRef>>(),
        reason: 'failure=${_failure(episode)}',
      );
      expect(
        (episode as PlaybackProviderSuccess<EpisodeRef>).value.episodeId,
        'http://${server.address.address}:${server.port}/video/a/1/',
      );
      expect(requests, [
        '/',
        '/anime/a/one-piece/',
        '/anime/a/one-piece/page/2/',
      ]);
    },
  );

  test(
    'normalizes source through the existing manager and host resolver',
    () async {
      final HttpServer server = await _server((HttpRequest request) async {
        switch (request.uri.path) {
          case '/':
            await _html(request, '<a href="/anime/a/one-piece/">One Piece</a>');
          case '/anime/a/one-piece/':
            await _html(
              request,
              '<a href="/video/a/1/">One Piece Episódio 1</a>',
            );
          case '/video/a/1/':
            await _html(
              request,
              '<iframe src="https://api.anivideo.net/videohls.php?d=https%3A%2F%2Fcdn.example.org%2Fmaster.m3u8"></iframe>',
            );
          default:
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
        }
      });
      addTearDown(() => server.close(force: true));
      final AnimesDigitalPlaybackProvider provider = _provider(
        server,
        parser: AnimesDigitalHtmlParser(
          allowedMediaHosts: const <String>['cdn.example.org'],
        ),
      );
      addTearDown(provider.close);
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: <PlaybackProviderRegistration>[
          PlaybackProviderRegistration(
            provider: provider,
            cacheTtl: Duration.zero,
            version: provider.adapterVersion,
          ),
        ],
        videoHostResolvers: <PlaybackVideoHostResolverRegistration>[
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(),
            version: '1.0.0',
          ),
        ],
        clock: () => DateTime.utc(2026, 11, 16),
      );

      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await manager.resolveCandidates(
            PlaybackEpisode.fromIdentity(_identity(), episodeNumber: 1),
            cancellation: PlaybackCancellationToken(),
          );

      expect(
        result,
        isA<PlaybackProviderSuccess<List<ResolvedPlaybackStream>>>(),
      );
      final PlayableSource stream =
          (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
              .value
              .single;
      expect(stream.uri, Uri.https('cdn.example.org', '/master.m3u8'));
      expect(stream.format, PlaybackMediaFormat.hls);
      expect(stream.providerId.value, 'animesdigital');
      expect(stream.httpHeaders.values, {
        'Referer': 'https://api.anivideo.net/',
      });
    },
  );

  test('blocks cross-origin redirects and maps ordinary HTTP errors', () async {
    final HttpServer redirectServer = await _server((
      HttpRequest request,
    ) async {
      request.response.statusCode = HttpStatus.found;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'https://outside.example/',
      );
      await request.response.close();
    });
    addTearDown(() => redirectServer.close(force: true));
    final AnimesDigitalPlaybackProvider redirectProvider = _provider(
      redirectServer,
    );
    addTearDown(redirectProvider.close);

    final PlaybackProviderResult<List<SourceAnimeMatch>> redirected =
        await redirectProvider.searchAnime(
          _identity(),
          cancellation: PlaybackCancellationToken(),
        );
    expect(_failure(redirected), PlaybackProviderFailureKind.blocked);

    final HttpServer forbiddenServer = await _server((
      HttpRequest request,
    ) async {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
    });
    addTearDown(() => forbiddenServer.close(force: true));
    final AnimesDigitalPlaybackProvider forbiddenProvider = _provider(
      forbiddenServer,
    );
    addTearDown(forbiddenProvider.close);

    expect(
      _failure(
        await forbiddenProvider.searchAnime(
          _identity(),
          cancellation: PlaybackCancellationToken(),
        ),
      ),
      PlaybackProviderFailureKind.forbidden,
    );
  });

  test('cancels an in-flight request and bounds streamed HTML', () async {
    final Completer<void> requestStarted = Completer<void>();
    final Completer<void> releaseResponse = Completer<void>();
    final Completer<void> responseFinished = Completer<void>();
    final HttpServer slowServer = await _server((HttpRequest request) async {
      if (!requestStarted.isCompleted) requestStarted.complete();
      await releaseResponse.future;
      try {
        await _html(request, '<html></html>');
      } on HttpException {
        // The client intentionally canceled the request before the response.
      } finally {
        responseFinished.complete();
      }
    });
    addTearDown(() => slowServer.close(force: true));
    final AnimesDigitalPlaybackProvider slowProvider = _provider(slowServer);
    addTearDown(slowProvider.close);
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();
    final Future<PlaybackProviderResult<List<SourceAnimeMatch>>> pending =
        slowProvider.searchAnime(_identity(), cancellation: cancellation);
    await requestStarted.future;
    cancellation.cancel();
    expect(_failure(await pending), PlaybackProviderFailureKind.cancelled);
    releaseResponse.complete();
    await responseFinished.future;

    final HttpServer largeServer = await _server((HttpRequest request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.contentLength =
          AnimesDigitalPlaybackProvider.maxHtmlBytes + 1;
      request.response.add(
        List<int>.filled(AnimesDigitalPlaybackProvider.maxHtmlBytes + 1, 0x61),
      );
      await request.response.close();
    });
    addTearDown(() => largeServer.close(force: true));
    final AnimesDigitalPlaybackProvider largeProvider = _provider(largeServer);
    addTearDown(largeProvider.close);

    expect(
      _failure(
        await largeProvider.searchAnime(
          _identity(),
          cancellation: PlaybackCancellationToken(),
        ),
      ),
      PlaybackProviderFailureKind.invalidResponse,
    );
  });

  test(
    'enforces a total deadline while response chunks keep arriving',
    () async {
      final HttpServer slowStreamServer = await _server((
        HttpRequest request,
      ) async {
        request.response.headers.contentType = ContentType.html;
        try {
          for (int chunk = 0; chunk < 20; chunk++) {
            request.response.write('<html>$chunk</html>');
            await request.response.flush();
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }
          await request.response.close();
        } on HttpException {
          // The provider cancels the response when its total deadline expires.
        } on SocketException {
          // The provider cancels the response when its total deadline expires.
        }
      });
      addTearDown(() => slowStreamServer.close(force: true));
      final AnimesDigitalPlaybackProvider provider = _provider(
        slowStreamServer,
        requestTimeout: const Duration(milliseconds: 180),
      );
      addTearDown(provider.close);
      final Stopwatch elapsed = Stopwatch()..start();

      final PlaybackProviderResult<List<SourceAnimeMatch>> result =
          await provider.searchAnime(
            _identity(),
            cancellation: PlaybackCancellationToken(),
          );

      expect(_failure(result), PlaybackProviderFailureKind.timeout);
      expect(elapsed.elapsed, lessThan(const Duration(seconds: 2)));
    },
  );

  test('shares one deadline across title lookup requests', () async {
    final HttpServer server = await _server((HttpRequest request) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        await _html(request, '<html></html>');
      } on HttpException {
        // The operation deadline may cancel a later title lookup.
      } on SocketException {
        // The operation deadline may cancel a later title lookup.
      }
    });
    addTearDown(() => server.close(force: true));
    final AnimesDigitalPlaybackProvider provider = _provider(
      server,
      requestTimeout: const Duration(milliseconds: 220),
    );
    addTearDown(provider.close);
    final AnimeIdentity identity = AnimeIdentity(
      localId: AnimeId('one-piece'),
      titles: const <String>['One Piece', 'ONE PIECE', 'Wan Pisu'],
    );
    final Stopwatch elapsed = Stopwatch()..start();

    final PlaybackProviderResult<List<SourceAnimeMatch>> result = await provider
        .searchAnime(identity, cancellation: PlaybackCancellationToken());

    expect(_failure(result), PlaybackProviderFailureKind.timeout);
    expect(elapsed.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('requires exact identity and reports a missing search title', () async {
    var requests = 0;
    final HttpServer server = await _server((HttpRequest request) async {
      requests++;
      await _html(
        request,
        '<a href="/anime/a/one-piece/">One Piece Film Red</a>',
      );
    });
    addTearDown(() => server.close(force: true));
    final AnimesDigitalPlaybackProvider provider = _provider(server);
    addTearDown(provider.close);

    final PlaybackProviderResult<List<SourceAnimeMatch>> result = await provider
        .searchAnime(_identity(), cancellation: PlaybackCancellationToken());
    expect(result, isA<PlaybackProviderEmpty<List<SourceAnimeMatch>>>());
    expect(requests, 1);

    final PlaybackProviderResult<List<SourceAnimeMatch>> missing =
        await provider.searchAnime(
          AnimeIdentity(localId: AnimeId('no-title')),
          cancellation: PlaybackCancellationToken(),
        );
    expect(_failure(missing), PlaybackProviderFailureKind.missingId);
  });
}

AnimeIdentity _identity() => AnimeIdentity(
  localId: AnimeId('one-piece'),
  titles: const <String>['One Piece'],
);

AnimesDigitalPlaybackProvider _provider(
  HttpServer server, {
  AnimesDigitalHtmlParser? parser,
  Duration requestTimeout = const Duration(seconds: 20),
}) => AnimesDigitalPlaybackProvider(
  baseUrl: 'http://${server.address.address}:${server.port}/',
  parser: parser,
  requestTimeout: requestTimeout,
);

Future<HttpServer> _server(Future<void> Function(HttpRequest) handle) async {
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  server.listen((HttpRequest request) => unawaited(handle(request)));
  return server;
}

Future<void> _html(HttpRequest request, String value) async {
  request.response.headers.contentType = ContentType.html;
  request.response.write(value);
  await request.response.close();
}

PlaybackProviderFailureKind? _failure<T>(PlaybackProviderResult<T> result) =>
    result is PlaybackProviderFailed<T> ? result.failure.kind : null;
