import 'dart:io';

import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'player_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enabled = Platform.environment['KONGROO_TEST_LOCAL_HLS'] == '1';

  test(
    'libmpv opens relative HLS and observes failure when its segment is denied',
    () async {
      final fixture = resolveF2_2Fixture();
      final encoded = await Process.run('ffmpeg', [
        '-hide_banner',
        '-loglevel',
        'error',
        '-i',
        fixture.path,
        '-t',
        '4',
        '-c:v',
        'mpeg2video',
        '-c:a',
        'mp2',
        '-f',
        'mpegts',
        'pipe:1',
      ], stdoutEncoding: null);
      expect(encoded.exitCode, 0, reason: encoded.stderr.toString());
      final segment = encoded.stdout as List<int>;
      expect(segment, isNotEmpty);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <(String, int)>[];
      server.listen((request) async {
        final response = request.response;
        final path = request.uri.path;
        switch (path) {
          case '/master.m3u8':
            response.headers.set(
              'content-type',
              'application/vnd.apple.mpegurl',
            );
            response.write(
              '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=800000\ngood.m3u8\n',
            );
          case '/good.m3u8' || '/denied.m3u8':
            response.headers.set(
              'content-type',
              'application/vnd.apple.mpegurl',
            );
            final name = path == '/good.m3u8' ? 'segment.ts' : 'denied.ts';
            response.write(
              '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:4\n'
              '#EXT-X-MEDIA-SEQUENCE:0\n#EXTINF:4.0,\n$name\n#EXT-X-ENDLIST\n',
            );
          case '/segment.ts':
            response.headers.set('content-type', 'video/mp2t');
            response.contentLength = segment.length;
            response.add(segment);
          case '/denied.ts':
            response.statusCode = HttpStatus.forbidden;
          default:
            response.statusCode = HttpStatus.notFound;
        }
        requests.add((path, response.statusCode));
        await response.close();
      });
      Uri uri(String path) => Uri.http('127.0.0.1:${server.port}', path);
      final good = uri('/master.m3u8');
      final denied = uri('/denied.m3u8');
      final engine = MediaKitSpikeEngine(demoSources: {good, denied});
      try {
        await engine.initialize();
        await engine.open(good, sourceGeneration: 1);
        await engine.play();
        final advanced = await engine.snapshots
            .firstWhere(
              (state) =>
                  state.sourceGeneration == 1 &&
                  (state.position > const Duration(milliseconds: 200) ||
                      state.error != null),
            )
            .timeout(const Duration(seconds: 9));
        expect(advanced.error, isNull);
        expect(
          requests,
          containsAll([
            ('/master.m3u8', 200),
            ('/good.m3u8', 200),
            ('/segment.ts', 200),
          ]),
        );

        await engine.open(denied, sourceGeneration: 2);
        if (engine.currentSnapshot.error == null) {
          final error = await engine.snapshots
              .firstWhere(
                (state) => state.sourceGeneration == 2 && state.error != null,
              )
              .timeout(const Duration(seconds: 9));
          expect(error.error, isNotEmpty);
        }
        expect(
          requests,
          containsAll([('/denied.m3u8', 200), ('/denied.ts', 403)]),
        );
        expect(engine.currentSnapshot.position, Duration.zero);
      } finally {
        await engine.dispose();
        await server.close(force: true);
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
