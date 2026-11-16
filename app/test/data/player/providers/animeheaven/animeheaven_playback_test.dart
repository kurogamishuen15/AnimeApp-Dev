import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/animeheaven/animeheaven_http.dart';
import 'package:anime_app/data/player/providers/animeheaven/animeheaven_mp4_resolver.dart';
import 'package:anime_app/data/player/providers/animeheaven/animeheaven_playback_provider.dart';
import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'composition resolves real provider alternatives through host resolver',
    () async {
      final _AnimeHeavenAdapter adapter = _AnimeHeavenAdapter();
      final Dio client = Dio()..interceptors.add(adapter);
      final PlaybackProvidersModule module = PlaybackProvidersModule.open(
        httpClient: client,
        clock: () => DateTime.utc(2026, 11, 16),
      );
      addTearDown(module.close);
      final PlaybackEpisode episode = _episode();

      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await module.manager.resolveCandidates(
            episode,
            cancellation: PlaybackCancellationToken(),
          );

      expect(
        result,
        isA<PlaybackProviderSuccess<List<ResolvedPlaybackStream>>>(),
      );
      final List<ResolvedPlaybackStream> streams =
          (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
              .value;
      // One mirror returns a redirect and is rejected without following it;
      // the remaining mirrors survive for the existing picker/player fallback.
      expect(streams.map((ResolvedPlaybackStream item) => item.serverId), [
        'mirror-ct',
        'mirror-ck',
      ]);
      expect(
        streams.every(
          (ResolvedPlaybackStream item) =>
              item.providerId.value == 'animeheaven',
        ),
        isTrue,
      );
      expect(
        adapter.requests
            .where((RequestOptions item) => item.path.endsWith('/gate.php'))
            .single
            .headers['Cookie'],
        'key=a1b2',
      );
      expect(
        adapter.requests
            .where((RequestOptions item) => item.path.endsWith('/gate.php'))
            .single
            .followRedirects,
        isFalse,
      );
      expect(
        adapter.requests
            .where((RequestOptions item) => item.path.endsWith('.mp4'))
            .every(
              (RequestOptions item) => item.headers['Range'] == 'bytes=0-31',
            ),
        isTrue,
      );
    },
  );

  test('provider does not search without an exact title candidate', () async {
    final _AnimeHeavenAdapter adapter = _AnimeHeavenAdapter();
    final AnimeHeavenPlaybackProvider provider = AnimeHeavenPlaybackProvider(
      client: Dio()..interceptors.add(adapter),
    );
    final PlaybackProviderResult<List<PlaybackSource>> result = await provider
        .findSources(
          PlaybackEpisode(animeId: AnimeId('test-no-title'), episodeNumber: 1),
          cancellation: PlaybackCancellationToken(),
        );

    expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    expect(adapter.requests, isEmpty);
  });

  test(
    'resolver checks MP4 bytes and MIME while tolerating CDN range metadata',
    () async {
      final _AnimeHeavenAdapter adapter = _AnimeHeavenAdapter();
      final AnimeHeavenMp4Resolver resolver = AnimeHeavenMp4Resolver(
        client: Dio()..interceptors.add(adapter),
      );
      final PlaybackProviderSuccess<List<PlaybackSource>> providerResult =
          await AnimeHeavenPlaybackProvider(
                client: Dio()..interceptors.add(adapter),
              ).findSources(
                _episode(),
                cancellation: PlaybackCancellationToken(),
              )
              as PlaybackProviderSuccess<List<PlaybackSource>>;
      final PlaybackSource source = providerResult.value.single;
      final PlaybackServer server = source.servers.firstWhere(
        (PlaybackServer item) => item.id == 'mirror-ct',
      );

      final PlaybackProviderResult<ResolvedPlaybackStream> result =
          await resolver.resolve(
            source,
            server,
            cancellation: PlaybackCancellationToken(),
          );

      expect(result, isA<PlaybackProviderSuccess<ResolvedPlaybackStream>>());
      final ResolvedPlaybackStream stream =
          (result as PlaybackProviderSuccess<ResolvedPlaybackStream>).value;
      expect(stream.uri, server.endpoint);
      expect(stream.httpHeaders.isEmpty, isTrue);
    },
  );

  test('cancelled lookup performs no network requests', () async {
    final _AnimeHeavenAdapter adapter = _AnimeHeavenAdapter();
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken()
      ..cancel();
    final PlaybackProviderResult<List<PlaybackSource>> result =
        await AnimeHeavenPlaybackProvider(
          client: Dio()..interceptors.add(adapter),
        ).findSources(_episode(), cancellation: cancellation);

    expect(result, isA<PlaybackProviderFailed<List<PlaybackSource>>>());
    expect(
      (result as PlaybackProviderFailed<List<PlaybackSource>>).failure.kind,
      PlaybackProviderFailureKind.cancelled,
    );
    expect(adapter.requests, isEmpty);
  });

  test('cancellation interrupts an active response stream', () async {
    final StreamController<Uint8List> responseBody =
        StreamController<Uint8List>();
    final Completer<void> responseListening = Completer<void>();
    final Completer<void> responseCancelled = Completer<void>();
    responseBody.onListen = () => responseListening.complete();
    responseBody.onCancel = () => responseCancelled.complete();
    final Dio client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<ResponseBody>(
                    requestOptions: options,
                    statusCode: 200,
                    headers: Headers.fromMap(<String, List<String>>{
                      'content-type': <String>['text/html'],
                    }),
                    data: ResponseBody(
                      responseBody.stream,
                      200,
                      headers: <String, List<String>>{
                        'content-type': <String>['text/html'],
                      },
                    ),
                  ),
                );
              },
        ),
      );
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();
    final Future<AnimeHeavenHttpResponse> request = AnimeHeavenHttp(client)
        .getHtml(
          Uri.https('animeheaven.me', '/search.php?q=One+Piece'),
          headers: const <String, String>{},
          cancellation: cancellation,
        );
    addTearDown(client.close);
    addTearDown(responseBody.close);

    await responseListening.future;
    cancellation.cancel();

    await expectLater(
      request,
      throwsA(
        isA<AnimeHeavenHttpFailure>().having(
          (AnimeHeavenHttpFailure error) => error.kind,
          'kind',
          PlaybackProviderFailureKind.cancelled,
        ),
      ),
    );
    await responseCancelled.future;
  });

  test('HTTP reader handles many small body chunks', () async {
    final List<Uint8List> chunks = List<Uint8List>.generate(
      512,
      (_) => Uint8List.fromList(<int>[0x41]),
    );
    final Dio client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<ResponseBody>(
                    requestOptions: options,
                    statusCode: 200,
                    headers: Headers.fromMap(<String, List<String>>{
                      'content-type': <String>['text/html'],
                    }),
                    data: ResponseBody(
                      Stream<Uint8List>.fromIterable(chunks),
                      200,
                      headers: <String, List<String>>{
                        'content-type': <String>['text/html'],
                      },
                    ),
                  ),
                );
              },
        ),
      );
    addTearDown(client.close);
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();

    final AnimeHeavenHttpResponse response = await AnimeHeavenHttp(client)
        .getHtml(
          Uri.https('animeheaven.me', '/search.php?q=One+Piece'),
          headers: const <String, String>{},
          cancellation: cancellation,
        );

    expect(response.body, List<int>.filled(chunks.length, 0x41));
    cancellation.cancel();
  });

  test('TLS certificate failures classify as network errors', () async {
    final Dio client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.badCertificate,
                    error: const TlsException('invalid certificate'),
                  ),
                );
              },
        ),
      );
    addTearDown(client.close);

    await expectLater(
      AnimeHeavenHttp(client).getHtml(
        Uri.https('animeheaven.me', '/search.php?q=One+Piece'),
        headers: const <String, String>{},
        cancellation: PlaybackCancellationToken(),
      ),
      throwsA(
        isA<AnimeHeavenHttpFailure>().having(
          (AnimeHeavenHttpFailure error) => error.kind,
          'kind',
          PlaybackProviderFailureKind.network,
        ),
      ),
    );
  });
}

PlaybackEpisode _episode() => PlaybackEpisode(
  animeId: AnimeId('anilist.21'),
  episodeNumber: 1,
  animeTitles: const <String>['One Piece'],
);

final class _AnimeHeavenAdapter extends Interceptor {
  final List<RequestOptions> requests = <RequestOptions>[];
  static const String _gateKey = 'a1b2';
  static final Uint8List _mp4Prefix = Uint8List.fromList(<int>[
    0x00,
    0x00,
    0x00,
    0x18,
    0x66,
    0x74,
    0x79,
    0x70,
    0x69,
    0x73,
    0x6f,
    0x6d,
  ]);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    final Uri uri = options.uri;
    int status = 200;
    String contentType = 'text/html; charset=utf-8';
    String contentRange = '';
    List<int> bytes = <int>[];

    if (uri.path == '/search.php') {
      bytes = utf8Bytes('''
<div class='similarimg'><a href='/anime.php?id=21&amp;type=tv'>detail</a>
<div class='similarname'><a>One Piece</a></div></div>
''');
    } else if (uri.path == '/anime.php') {
      bytes = utf8Bytes('''
<a onclick='gatea("$_gateKey")'><div class='watch2'>1</div></a>
''');
    } else if (uri.path == '/gate.php') {
      if (options.headers['Cookie'] != 'key=$_gateKey') {
        status = 403;
      }
      bytes = utf8Bytes('''
<!-- <source src="https://ax.animeheaven.me/decoy.mp4?$_gateKey"> -->
<source src="https://ax.animeheaven.me/one.mp4?$_gateKey&amp;sig=hidden">
<source src="https://ct.animeheaven.me/one.mp4?$_gateKey&amp;sig=hidden">
<source src="https://ck.animeheaven.me/one.mp4?$_gateKey&amp;sig=hidden">
''');
    } else if (uri.path.endsWith('.mp4')) {
      contentType = 'video/mp4';
      contentRange = 'bytes 0-179874826/179874827';
      if (uri.host.startsWith('ax.')) {
        status = 302;
        contentType = 'text/html';
      }
      bytes = _mp4Prefix;
    } else {
      status = 404;
      contentType = 'text/html';
    }

    final Map<String, List<String>> headerMap = <String, List<String>>{
      'content-type': <String>[contentType],
      if (contentRange.isNotEmpty) 'content-range': <String>[contentRange],
    };
    final ResponseBody body = ResponseBody(
      Stream<Uint8List>.value(Uint8List.fromList(bytes)),
      status,
      headers: headerMap,
    );
    handler.resolve(
      Response<ResponseBody>(
        requestOptions: options,
        statusCode: status,
        headers: Headers.fromMap(headerMap),
        data: body,
      ),
    );
  }
}

List<int> utf8Bytes(String value) => value.codeUnits;
