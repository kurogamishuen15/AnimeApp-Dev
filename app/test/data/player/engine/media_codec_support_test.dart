import 'dart:ffi';

import 'package:anime_app/data/player/engine/media_codec_support_io.dart';
import 'package:anime_app/data/player/engine/media_codec_support_linux.dart';
import 'package:anime_app/data/player/engine/media_codec_support_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Codec boundary: every platform must report the same contract, and Linux
/// must prefer the bundled decoder installed by `local_codec.cmake`.
void main() {
  const String bundleExecutable = '/app/build/bundle/anime_app';
  const String bundledCodec = '/app/build/bundle/lib/libopenh264.so.8';

  LinuxMediaCodecSupport linux({
    String executable = bundleExecutable,
    Map<String, String> environment = const {},
    Set<String> existing = const {},
    DynamicLibrary Function(String path)? openLibrary,
  }) => LinuxMediaCodecSupport(
    environment: environment,
    resolvedExecutable: executable,
    isRegularFile: existing.contains,
    openLibrary: openLibrary ?? (_) => DynamicLibrary.process(),
  );

  group('linux', () {
    test('reports the bundled decoder installed next to the application', () {
      final MediaCodecReport report = linux(existing: const {bundledCodec})
          .prepare();
      expect(report.strategy, MediaCodecStrategy.bundled);
      expect(report.decoderPath, bundledCodec);
      expect(report.prepared, isTrue);
    });

    test('loads an explicitly configured decoder that is not bundled', () {
      const String override = '/opt/codecs/libopenh264.so.8';
      final MediaCodecReport report = linux(
        executable: '/tmp/anime_app',
        environment: const {linuxOpenH264PathVariable: override},
        existing: const {override},
      ).prepare();
      expect(report.strategy, MediaCodecStrategy.preloaded);
      expect(report.decoderPath, override);
    });

    test('honours the explicit override', () {
      const String override = '/opt/codecs/libopenh264.so.8';
      final MediaCodecReport report = linux(
        environment: const {linuxOpenH264PathVariable: override},
        existing: const {override, bundledCodec},
      ).prepare();
      expect(report.decoderPath, override);
    });

    test('reports the system policy when no decoder is present', () {
      final MediaCodecReport report = linux(executable: '/opt/anime_app')
          .prepare();
      expect(report.strategy, MediaCodecStrategy.system);
      expect(report.decoderPath, isNull);
      expect(report.prepared, isFalse);
    });

    test(
      'a failed preload falls back to the system policy without throwing',
      () {
        final MediaCodecReport report = linux(
          executable: '/tmp/anime_app',
          environment: const {
            linuxOpenH264PathVariable: '/opt/codecs/libopenh264.so.8',
          },
          existing: const {'/opt/codecs/libopenh264.so.8'},
          openLibrary: (String path) => throw ArgumentError('not a library'),
        ).prepare();
        expect(report.strategy, MediaCodecStrategy.system);
        expect(report.detail, contains('not a library'));
      },
    );

    test('candidates never search cwd or executable ancestors', () {
      final List<String> candidates = LinuxCodecLocator(
        resolvedExecutable: bundleExecutable,
        isRegularFile: (_) => false,
      ).candidates();
      expect(candidates, [bundledCodec]);
      expect(
        candidates.any((String path) => path.contains('.ai-local')),
        isFalse,
      );
      expect(
        candidates.any((String path) => path.startsWith('/home/')),
        isFalse,
      );
    });
  });

  group('platform dispatch', () {
    test('android and windows delegate to the platform decoder', () {
      final MediaCodecSupportRegistry android = MediaCodecSupportRegistry(
        operatingSystem: 'android',
      );
      final MediaCodecReport androidReport = android.prepare();
      expect(androidReport.platform, 'android');
      expect(androidReport.strategy, MediaCodecStrategy.platform);
      expect(androidReport.prepared, isTrue);

      final MediaCodecReport windowsReport = MediaCodecSupportRegistry(
        operatingSystem: 'windows',
      ).prepare();
      expect(windowsReport.platform, 'windows');
      expect(windowsReport.strategy, MediaCodecStrategy.platform);
    });

    test('unknown platforms stay on the system policy', () {
      final MediaCodecReport report = MediaCodecSupportRegistry(
        operatingSystem: 'macos',
      ).prepare();
      expect(report.platform, 'macos');
      expect(report.strategy, MediaCodecStrategy.system);
      expect(report.prepared, isFalse);
    });

    test('the registry is injectable for every branch', () {
      final MediaCodecReport report = MediaCodecSupportRegistry(
        operatingSystem: 'linux',
        linux: linux(existing: const {bundledCodec}),
      ).prepare();
      expect(report.strategy, MediaCodecStrategy.bundled);
    });
  });
}
