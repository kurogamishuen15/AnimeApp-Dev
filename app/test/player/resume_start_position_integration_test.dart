import 'dart:async';
import 'dart:io';

import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/application/player/spike_player_coordinator.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opt-in real-engine check: `KONGROO_TEST_LOCAL_MEDIA=1 flutter test ...`.
/// After seeking to a resume point and playing, the first positive position the
/// engine reports must already be near that point, not near zero. The full
/// module path needs a rendering surface and is verified visually, not here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bool enabled = Platform.environment['KONGROO_TEST_LOCAL_MEDIA'] == '1';
  final File fixture = File('../.ai-local/f2.2/fixtures/spike.mp4');

  test(
    'local fixture seeks to a resume point in the real engine before advancing',
    () async {
      const Duration start = Duration(seconds: 3);
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final player = SpikePlayerCoordinator(engine);
      addTearDown(player.dispose);
      await player.initialize();
      await player.open(fixture.absolute.uri);
      await player.restoreStartPosition(
        start,
        cancellation: PlaybackCancellationToken(),
      );
      expect(player.state.observedPosition, start);
      final Completer<Duration> firstPositive = Completer<Duration>();
      final StreamSubscription<PlaybackSpikeSnapshot> sub = engine.snapshots
          .listen((PlaybackSpikeSnapshot s) {
            if (s.position > const Duration(milliseconds: 100) &&
                !firstPositive.isCompleted) {
              firstPositive.complete(s.position);
            }
          });
      addTearDown(sub.cancel);

      await player.play();
      final Duration first = await firstPositive.future.timeout(
        const Duration(seconds: 30),
      );
      await player.pause();
      expect(
        first,
        greaterThanOrEqualTo(start - const Duration(milliseconds: 500)),
      );
    },
    skip: enabled ? false : 'set KONGROO_TEST_LOCAL_MEDIA=1 to run',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
