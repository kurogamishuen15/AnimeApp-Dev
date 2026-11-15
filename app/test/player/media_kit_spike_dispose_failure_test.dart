import 'dart:async';

import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adapter closes its stream and quarantines a failed dispose', () async {
    int disposeCalls = 0;
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine.forTesting(
      disposePlayer: (player) async {
        disposeCalls++;
        // Release the real test Player, then inject the failure response. This
        // exercises adapter failure bookkeeping without leaking libmpv.
        await player.dispose();
        throw StateError('injected dispose failure');
      },
    );
    final Completer<void> streamClosed = Completer<void>();
    engine.snapshots.listen((_) {}, onDone: streamClosed.complete);

    await expectLater(engine.dispose(), throwsStateError);
    await streamClosed.future;
    await expectLater(engine.dispose(), throwsStateError);
    expect(disposeCalls, 1);
    expect(
      () => MediaKitSpikeEngine(),
      throwsStateError,
      reason: 'An uncertain dispose must keep the single-player lease held.',
    );
  });
}
