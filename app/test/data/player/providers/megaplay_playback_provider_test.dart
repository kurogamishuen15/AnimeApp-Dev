import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/data/player/providers/megaplay/megaplay_playback_provider.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

PlaybackEpisode _episode({bool withId = true}) => PlaybackEpisode(
  animeId: AnimeId('test'),
  episodeNumber: 9,
  externalAnimeIds: [
    if (withId)
      ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '100240',
      ),
  ],
);

void main() {
  for (final bool encrypted in [false, true]) {
    test(
      'exact ID episode resolves ${encrypted ? "encrypted" : "clear"} HLS through manager',
      () async {
        const String file =
            'https://fetch.nexabloom.top/a/master.m3u8?token=fixture';
        Map<String, Object> answer = {
          'sources': {'file': file},
        };
        if (encrypted) {
          final List<int> key = List.filled(32, 0);
          key.setRange(0, 16, utf8.encode('i?LMTAx0Q6,:}50U'));
          final box = await AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty)
              .encrypt(
                utf8.encode(jsonEncode({'file': file})),
                secretKey: SecretKey(key),
                nonce: utf8.encode("W0;27ToaUpl_P%'c"),
              );
          answer = {
            'enc': base64Url.encode(box.cipherText).replaceAll('=', ''),
          };
        }
        final pages = _Pages(answer: jsonEncode(answer));
        final Dio client = Dio()..httpClientAdapter = pages;
        addTearDown(() => client.close(force: true));
        final provider = MegaPlayPlaybackProvider(client);
        final manager = PlaybackProviderManager(
          providers: [PlaybackProviderRegistration(provider: provider)],
          videoHostResolvers: [
            PlaybackVideoHostResolverRegistration(
              resolver: DirectMediaHostResolver(),
            ),
          ],
          clock: DateTime.now,
        );
        final result = await manager.resolveCandidates(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        );
        expect(
          result,
          isA<PlaybackProviderSuccess<List<ResolvedPlaybackStream>>>(),
        );
        final stream =
            (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
                .value
                .single;
        expect(stream.uri.toString(), file);
        expect(stream.format, PlaybackMediaFormat.hls);
        expect(stream.httpHeaders.values, {
          'Referer': 'https://megaplay.buzz/',
          'Origin': 'https://megaplay.buzz',
          'User-Agent': 'Kongroo/0.1 (public anime catalog client)',
        });
        expect(pages.requests.map((request) => request.uri.path), [
          '/stream/ani/100240/9/sub',
          '/lib/newclient.min.js',
          '/stream/getSourcesNew',
        ]);
        expect(pages.requests.first.headers['Referer'], 'https://hianimes.re/');
        expect(
          pages.requests[1].headers['Referer'],
          'https://megaplay.buzz/stream/ani/100240/9/sub',
        );
        expect(
          pages.requests.last.headers['X-Requested-With'],
          'XMLHttpRequest',
        );
        expect(pages.requests.last.uri.queryParametersAll['id'], [
          'File09',
          'File09',
        ]);
        expect(
          pages.requests.last.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('cookie')),
        );
      },
    );
  }

  test('dub uses its own exact endpoint and identity', () async {
    final pages = _Pages(
      answer: '{"sources":{"file":"https://cdn.anime.org/master.m3u8"}}',
    );
    final client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = MegaPlayPlaybackProvider(
      client,
      variant: MegaPlayAudioVariant.dub,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    final source =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value.single;
    expect(source.providerId.value, 'megaplay-dub');
    expect(source.id, endsWith(':dub'));
    expect(source.providerAnnouncedLanguage, 'dub');
    expect(pages.requests.first.uri.path, '/stream/ani/100240/9/dub');
  });

  test('provider captions survive resolution with declared languages; unsafe tracks skipped', () async {
    final pages = _Pages(
      answer: jsonEncode({
        'sources': {'file': 'https://cdn.anime.org/master.m3u8'},
        'tracks': [
          {
            'kind': 'captions',
            'label': 'Spanish(Latin America)',
            'file': 'https://captions.anime.org/es.vtt',
            'default': true,
          },
          {
            'kind': 'captions',
            'label': 'English',
            'file': 'https://captions.anime.org/en.vtt',
          },
          {
            'kind': 'thumbnails',
            'label': 'Preview',
            'file': 'https://captions.anime.org/thumb.vtt',
          },
          {
            'kind': 'captions',
            'label': 'Local',
            'file': 'https://127.0.0.1/es.vtt',
          },
          {
            'kind': 'captions',
            'label': 'Not VTT',
            'file': 'https://captions.anime.org/es.html',
          },
          {
            'kind': 'captions',
            'label': 'Duplicate',
            'file': 'https://captions.anime.org/es.vtt',
          },
        ],
      }),
    );
    final client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final manager = PlaybackProviderManager(
      providers: [
        PlaybackProviderRegistration(
          provider: MegaPlayPlaybackProvider(client),
        ),
      ],
      videoHostResolvers: [
        PlaybackVideoHostResolverRegistration(
          resolver: DirectMediaHostResolver(),
        ),
      ],
      clock: DateTime.now,
    );
    final result = await manager.resolveCandidates(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    final stream =
        (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
            .value
            .single;
    expect(stream.subtitles.map((track) => track.language), ['es', 'en']);
    expect(stream.subtitles.first.isDefault, isTrue);
    expect(stream.subtitles.first.label, 'Spanish(Latin America)');
    expect(stream.subtitles.first.uri.host, 'captions.anime.org');
  });

  test('Retry-After is shared across sub and dub for the same host', () async {
    final pages = _Pages(embedStatus: 429);
    final client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final transport = PublicPlaybackHttp(client, {'megaplay.buzz'});
    final manager = PlaybackProviderManager(
      providers: [
        for (final variant in MegaPlayAudioVariant.values)
          PlaybackProviderRegistration(
            provider: MegaPlayPlaybackProvider(
              client,
              transport: transport,
              variant: variant,
            ),
          ),
      ],
      clock: DateTime.now,
    );
    final result = await manager.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(result, isA<PlaybackProviderFailed<List<PlaybackSource>>>());
    expect(pages.requests, hasLength(1));
  });

  test('missing AniList ID and cancellation make no requests', () async {
    final pages = _Pages();
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = MegaPlayPlaybackProvider(client);
    final missing = await provider.findSources(
      _episode(withId: false),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (missing as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.missingId,
    );
    final cancelled = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken()..cancel(),
    );
    expect(
      (cancelled as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.cancelled,
    );
    expect(pages.requests, isEmpty);
  });

  for (final int status in [403, 404]) {
    test('embed $status stops without retries or alternate IDs', () async {
      final pages = _Pages(embedStatus: status);
      final Dio client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final result = await MegaPlayPlaybackProvider(client)
          .findSources(_episode(), cancellation: PlaybackCancellationToken());
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        status == 403
            ? PlaybackProviderFailureKind.forbidden
            : PlaybackProviderFailureKind.notFound,
      );
      expect(pages.requests, hasLength(1));
    });
  }

  test(
    'malformed encrypted source fails and does not try another route',
    () async {
      final pages = _Pages(answer: '{"enc":"YWJj"}');
      final Dio client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final result = await MegaPlayPlaybackProvider(client)
          .findSources(_episode(), cancellation: PlaybackCancellationToken());
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        PlaybackProviderFailureKind.invalidResponse,
      );
      expect(pages.requests, hasLength(3));
    },
  );

  test('retired route with no file falls back within same family', () async {
    final pages = _Pages(
      answer: '{}',
      fallbackAnswer:
          '{"sources":[{"file":"https://cdn.anime.org/master.m3u8"}]}',
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final result = await MegaPlayPlaybackProvider(client)
        .findSources(_episode(), cancellation: PlaybackCancellationToken());
    expect(result, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
    expect(pages.requests.last.uri.path, '/stream/getSources');
  });

  test('private source URL is rejected', () async {
    final pages = _Pages(
      answer: '{"sources":{"file":"https://127.0.0.1/master.m3u8"}}',
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final result = await MegaPlayPlaybackProvider(client)
        .findSources(_episode(), cancellation: PlaybackCancellationToken());
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.invalidResponse,
    );
  });

  test('MyAnimeList fallback serves when the AniList route misses',
      () async {
    // Verified live 2026-11-17: 2Dhive embeds MegaPlay by MyAnimeList id, and
    // that route answers with its own data-id when the AniList route misses.
    final pages = _Pages(
      aniMissing: true,
      answer: '{"sources":{"file":"https://cdn.anime.org/master.m3u8"}}',
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = MegaPlayPlaybackProvider(client);
    final manager = PlaybackProviderManager(
      providers: [PlaybackProviderRegistration(provider: provider)],
      videoHostResolvers: [
        PlaybackVideoHostResolverRegistration(
          resolver: DirectMediaHostResolver(),
        ),
      ],
      clock: DateTime.now,
    );
    final result = await manager.resolveCandidates(
      PlaybackEpisode(
        animeId: AnimeId('test'),
        episodeNumber: 9,
        externalAnimeIds: [
          ExternalAnimeId(
            providerId: MetadataProviderId('anilist'),
            value: '100240',
          ),
          ExternalAnimeId(
            providerId: MetadataProviderId('myanimelist'),
            value: '36511',
          ),
        ],
      ),
      cancellation: PlaybackCancellationToken(),
    );
    final streams =
        (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>).value;
    expect(streams.single.uri.toString(), 'https://cdn.anime.org/master.m3u8');
    final List<String> paths =
        pages.requests.map((RequestOptions request) => request.uri.path).toList();
    expect(paths.first, '/stream/ani/100240/9/sub');
    expect(paths, contains('/stream/mal/36511/9/sub'));
    expect(paths.last, '/stream/getSourcesNew');
    expect(
      pages.requests
          .where((RequestOptions request) =>
              request.uri.path == '/stream/mal/36511/9/sub')
          .first
          .headers['Referer'],
      'https://hianimes.re/',
    );
  });
}

final class _Pages implements HttpClientAdapter {
  _Pages({
    this.answer = '{}',
    this.embedStatus = 200,
    this.fallbackAnswer,
    this.aniMissing = false,
  });
  final String answer;
  final String? fallbackAnswer;
  final int embedStatus;
  final bool aniMissing;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.uri.path;
    final bool aniMiss = aniMissing && path.startsWith('/stream/ani/');
    return ResponseBody.fromString(
      switch (path) {
        '/stream/ani/100240/9/sub' ||
        '/stream/ani/100240/9/dub' => '<div data-id="File09"></div>',
        '/stream/mal/36511/9/sub' => '<div data-id="MalFile09"></div>',
        '/lib/newclient.min.js' =>
          '"stream/getSourcesNew" "stream/getSources/evil"',
        '/stream/getSources' => fallbackAnswer ?? answer,
        _ => answer,
      },
      aniMiss
          ? 404
          : path == '/stream/ani/100240/9/sub'
          ? embedStatus
          : 200,
      headers: {
        'content-type': ['application/json'],
        if (embedStatus == 429) 'retry-after': ['60'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
