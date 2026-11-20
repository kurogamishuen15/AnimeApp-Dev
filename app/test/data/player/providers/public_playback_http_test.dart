import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Dio client;
  late PublicPlaybackHttp http;
  late List<(String, String?, String?)> received;
  late Completer<void> hanging;

  setUp(() async {
    received = [];
    hanging = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = Dio()..httpClientAdapter = _Loopback(server.port);
    http = PublicPlaybackHttp(client, const {'video.example.org'});

    server.listen((request) async {
      final HttpResponse response = request.response;
      received.add((
        request.method,
        request.headers.value('referer'),
        request.headers.value('user-agent'),
      ));
      response.headers.set('server', 'fixture');
      switch (request.uri.path) {
        case '/manifest.m3u8':
          response.headers.contentType = ContentType(
            'application',
            'vnd.apple.mpegurl',
          );
          if (request.method == 'GET') {
            response.write('#EXTM3U\n#EXT-X-ENDLIST');
          }
        case '/good.mp4':
          response.headers.contentType = ContentType('video', 'mp4');
        case '/forbidden.mp4':
          response.statusCode = HttpStatus.forbidden;
          response.headers.contentType = ContentType.html;
        case '/challenge.mp4':
          response.statusCode = HttpStatus.forbidden;
          response.headers.set('cf-mitigated', 'challenge');
        case '/cf-challenge-page.mp4':
          response.statusCode = HttpStatus.forbidden;
          response.headers.contentType = ContentType.html;
          response.write(
            '<!DOCTYPE html><html><head><title>Just a moment...</title>'
            '</head><body><script src="/cdn-cgi/challenge-platform/x.js">'
            '</script></body></html>',
          );
        case '/cf-block-page.mp4':
          response.statusCode = HttpStatus.forbidden;
          response.headers.contentType = ContentType.html;
          response.write(
            '<!DOCTYPE html><html><head>'
            '<title>Attention Required! | Cloudflare</title></head><body>'
            'Sorry, you have been blocked</body></html>',
          );
        case '/quota.mp4':
          response.statusCode = HttpStatus.tooManyRequests;
          response.headers.set('retry-after', '19');
        case '/error.mp4':
          response.statusCode = HttpStatus.internalServerError;
          response.headers.contentType = ContentType.json;
        case '/redirect.mp4':
          response.headers.set('set-cookie', 'fixture=private; Path=/');
          response.statusCode = HttpStatus.found;
          response.headers.set('location', '/good.mp4');
        case '/cross-origin.mp4':
          response.statusCode = HttpStatus.found;
          response.headers.set(
            'location',
            'https://other.example.org/good.mp4',
          );
        case '/bad-mime.mp4':
          response.headers.contentType = ContentType.text;
        case '/scoped.mp4':
          response.headers.contentType = ContentType('video', 'mp4');
          if (request.headers.value('referer') == null) {
            response.statusCode = HttpStatus.forbidden;
          }
        case '/large-catalog.json':
          response.headers.contentType = ContentType.json;
          response.add(List<int>.filled(3 * 1024 * 1024, 0x20));
        case '/binary-catalog':
          response.headers.contentType = ContentType.binary;
          response.add([0xff, 0x00, 0xfe, 0x80]);
        case '/hanging.mp4':
          hanging.complete();
          return;
        default:
          response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    });
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  Future<Uri> probe(
    String path, {
    PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(),
    PlaybackCancellationToken? cancellation,
  }) => http.checkMp4(
    Uri.https('video.example.org', path),
    cancellation ?? PlaybackCancellationToken(),
    allows: (Uri uri) => uri.host == 'video.example.org' && uri.port == 443,
    headers: headers,
  );

  Matcher failure(PlaybackProviderFailureKind kind, int status) =>
      isA<PublicPlaybackFailure>()
          .having((error) => error.kind, 'kind', kind)
          .having((error) => error.status, 'response', status)
          .having((error) => error.stage, 'stage', PlaybackHttpStage.media);

  test(
    'reading a media manifest uses GET; diagnostic stage does not select HEAD',
    () async {
      final body = await http.read(
        Uri.https('video.example.org', '/manifest.m3u8'),
        PlaybackCancellationToken(),
        stage: PlaybackHttpStage.media,
      );
      expect(body, startsWith('#EXTM3U'));
      expect(received.single.$1, 'GET');
    },
  );

  test(
    'classifies HTTP denial, challenge, server failure and invalid MIME',
    () async {
      await expectLater(
        probe('/forbidden.mp4'),
        throwsA(failure(PlaybackProviderFailureKind.forbidden, 403)),
      );
      await expectLater(
        probe('/challenge.mp4'),
        throwsA(failure(PlaybackProviderFailureKind.challenge, 403)),
      );
      await expectLater(
        probe('/error.mp4'),
        throwsA(failure(PlaybackProviderFailureKind.unavailable, 500)),
      );
      await expectLater(
        probe('/bad-mime.mp4'),
        throwsA(failure(PlaybackProviderFailureKind.invalidResponse, 200)),
      );
      expect((await probe('/good.mp4')).path, '/good.mp4');
      expect(received.map((item) => item.$1), everyElement('HEAD'));
    },
  );

  test('a body-read 403 separates challenge pages from WAF blocks', () async {
    // `cf-mitigated` is the documented signal; the page title is the fallback
    // when a proxy strips it. A block page is not a challenge: it means the
    // site owner (not the visitor) has to change the policy.
    await expectLater(
      http.read(
        Uri.https('video.example.org', '/cf-challenge-page.mp4'),
        PlaybackCancellationToken(),
        stage: PlaybackHttpStage.media,
      ),
      throwsA(failure(PlaybackProviderFailureKind.challenge, 403)),
    );
    await expectLater(
      http.read(
        Uri.https('video.example.org', '/cf-block-page.mp4'),
        PlaybackCancellationToken(),
        stage: PlaybackHttpStage.media,
      ),
      throwsA(failure(PlaybackProviderFailureKind.forbidden, 403)),
    );
    await expectLater(
      http.read(
        Uri.https('video.example.org', '/forbidden.mp4'),
        PlaybackCancellationToken(),
        stage: PlaybackHttpStage.media,
      ),
      throwsA(failure(PlaybackProviderFailureKind.forbidden, 403)),
    );
  });

  test(
    'honors Retry-After and keeps the cooldown scoped to the origin',
    () async {
      await expectLater(
        probe('/quota.mp4'),
        throwsA(
          isA<PublicPlaybackFailure>().having(
            (error) => error.retryAfter,
            'Retry-After',
            const Duration(seconds: 19),
          ),
        ),
      );
      await expectLater(
        probe('/good.mp4'),
        throwsA(
          isA<PublicPlaybackFailure>().having(
            (error) => error.kind,
            'kind',
            PlaybackProviderFailureKind.rateLimited,
          ),
        ),
      );
      expect(received, hasLength(1));
    },
  );

  test(
    'follows only an admitted same-origin redirect without cookies',
    () async {
      expect((await probe('/redirect.mp4')).path, '/good.mp4');
      await expectLater(
        probe('/cross-origin.mp4'),
        throwsA(failure(PlaybackProviderFailureKind.blocked, 302)),
      );
      expect(received.map((item) => item.$1), ['HEAD', 'HEAD', 'HEAD']);
      expect(received.map((item) => item.$3), everyElement(isNotNull));
      expect(received.every((item) => item.$3!.startsWith('Kongroo/')), isTrue);
    },
  );

  test(
    'keeps explicitly allowed Referer and User-Agent scoped to one request',
    () async {
      await expectLater(
        probe('/scoped.mp4'),
        throwsA(failure(PlaybackProviderFailureKind.forbidden, 403)),
      );
      final PlaybackRequestHeaders headers = PlaybackRequestHeaders({
        'Referer': 'https://catalog.example.net/',
        'User-Agent': 'Kongroo-test/1.0',
      });
      await probe('/scoped.mp4', headers: headers);
      await probe('/good.mp4');
      expect(received[1], (
        'HEAD',
        'https://catalog.example.net/',
        'Kongroo-test/1.0',
      ));
      expect(received[2].$2, isNull);
      expect(received[2].$3, isNot('Kongroo-test/1.0'));
    },
  );

  test('cancels an in-flight request', () async {
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();
    final Future<void> checked = expectLater(
      probe('/hanging.mp4', cancellation: cancellation),
      throwsA(
        isA<PublicPlaybackFailure>().having(
          (error) => error.kind,
          'kind',
          PlaybackProviderFailureKind.cancelled,
        ),
      ),
    );
    await hanging.future.timeout(const Duration(seconds: 3));
    cancellation.cancel();
    await checked;
  });

  test('preserves binary bytes and keeps text validation strict', () async {
    final Uri uri = Uri.https('video.example.org', '/binary-catalog');
    expect(
      await http.readBytes(
        uri,
        PlaybackCancellationToken(),
        headers: PlaybackRequestHeaders({
          'Referer': 'https://catalog.example.net/',
        }),
      ),
      [0xff, 0x00, 0xfe, 0x80],
    );
    await expectLater(
      http.read(uri, PlaybackCancellationToken()),
      throwsA(
        isA<PublicPlaybackFailure>().having(
          (error) => error.kind,
          'kind',
          PlaybackProviderFailureKind.invalidResponse,
        ),
      ),
    );
    expect(received.map((item) => item.$2), [
      'https://catalog.example.net/',
      null,
    ]);
  });

  test('honors a caller-supplied response limit above the default', () async {
    final Uint8List body = await http.readBytes(
      Uri.https('video.example.org', '/large-catalog.json'),
      PlaybackCancellationToken(),
      maxResponseBytes: 4 * 1024 * 1024,
    );
    expect(body, hasLength(3 * 1024 * 1024));
  });
}

/// Exercises HTTPS policy with loopback I/O without changing the production URL.
final class _Loopback implements HttpClientAdapter {
  _Loopback(this.port);

  final int port;
  final IOHttpClientAdapter _adapter = IOHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => _adapter.fetch(
    options.copyWith(baseUrl: 'http://127.0.0.1:$port', path: options.uri.path),
    stream,
    cancelFuture,
  );

  @override
  void close({bool force = false}) => _adapter.close(force: force);
}
