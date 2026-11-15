import 'dart:convert';
import 'dart:io';

import 'package:anime_app/application/player/diagnostics/playback_performance.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final File source = File(
    Platform.environment['KONGROO_PERF_SOURCE'] ??
        '../.ai-local/player-demo/real/episode-1.mkv',
  ).absolute;

  test(
    'libmpv reports live native counters for authorized local media',
    () async {
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      try {
        await engine.initialize();
        await engine.open(source.uri);
        await engine.play();
        // A fixed observation window is intentional for this performance
        // probe. No VideoController is attached, so texture/compositor costs
        // and actual displayed FPS are outside this test's evidence.
        for (var i = 0; i < 3; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
          final PlaybackPerformanceSample sample = await engine
              .samplePerformance();
          expect(sample.rssBytes, greaterThan(0));
          debugPrintSynchronously(
            'KONGROO_PERF_NATIVE ${jsonEncode({'nominal_fps': sample.nominalFps, 'decoded_fps': sample.decodedFps, 'vo_drops': sample.framesDropped, 'decoder_drops': sample.decoderFramesDropped, 'avsync_seconds': sample.avSyncSeconds, 'cache_seconds': sample.cacheSeconds, 'hwdec_current': sample.hardwareDecoder, 'video_codec': sample.videoCodec, 'audio_codec': sample.audioCodec, 'vo': sample.videoOutput, 'ao': sample.audioOutput, 'rss_bytes': sample.rssBytes})}',
          );
        }
      } finally {
        await engine.dispose();
      }
    },
    skip: source.existsSync() ? false : 'Real media absent. Run tools/player/prepare_real_player_demo.py first.',
  );
}
