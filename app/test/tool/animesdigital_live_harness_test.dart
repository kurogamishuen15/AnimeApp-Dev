import 'package:flutter_test/flutter_test.dart';

import '../../tool/animesdigital_live_harness.dart' as live_harness;

void main() {
  group('live harness diagnostics', () {
    test('redacts URLs while preserving the referenced extension', () {
      final String diagnostic = live_harness.redactLiveProbeDiagnostic(
        '[hls] URL https://media.example/path/index.m3u8?token=secret '
        'is not allowed',
      );

      expect(diagnostic, contains('extension=m3u8'));
      expect(diagnostic, contains('is not allowed'));
      expect(diagnostic, isNot(contains('media.example')));
      expect(diagnostic, isNot(contains('secret')));
    });

    test('summarizes HLS URI tags without exposing paths or queries', () {
      final Uri base = Uri.https('origin.example', '/master.m3u8');
      const String manifest = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=100000
variant/index.m3u8?sig=secret
#EXT-X-MEDIA:TYPE=IMAGE,URI="https://images.example/poster.webp?token=secret"
''';

      final String summary = live_harness.summarizeHlsReferences(
        base,
        manifest,
      );

      expect(summary, contains('EXT-X-MEDIA:webp=1'));
      expect(summary, contains('variant:m3u8=1'));
      expect(summary, contains('non_https=0'));
      expect(summary, contains('cross_origin=1'));
      expect(summary, isNot(contains('secret')));
      expect(summary, isNot(contains('images.example')));
      expect(summary, isNot(contains('/poster.webp')));
    });

    test('summarizes opaque or non-HTTPS references without throwing', () {
      final String summary = live_harness.summarizeHlsReferences(
        Uri.https('origin.example', '/master.m3u8'),
        '#EXTM3U\n'
        '#EXT-X-MEDIA:TYPE=IMAGE,URI="data:image/webp;base64,AA=="\n',
      );

      expect(summary, contains('non_https=1'));
      expect(summary, contains('cross_origin=1'));
      expect(summary, isNot(contains('base64')));
    });
  });
}
