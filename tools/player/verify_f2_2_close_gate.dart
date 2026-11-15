import 'dart:async';

import '../../app/lib/app/player/spike_window_close_gate.dart';

Future<void> main() async {
  final Completer<void> cleanup = Completer<void>();
  int closeCalls = 0;
  int pendingNotices = 0;
  final SpikeWindowCloseGate gate = SpikeWindowCloseGate(
    () {
      closeCalls++;
      return cleanup.future;
    },
    () async {},
    () {},
    closeWatchdog: const Duration(milliseconds: 20),
    onCleanupPending: () => pendingNotices++,
  );

  final Future<bool> first = gate.requestClose();
  final Future<bool> duplicate = gate.requestClose();
  _check(identical(first, duplicate), 'simultaneous close was not coalesced');
  _check(!await first, 'pending cleanup incorrectly allowed window close');
  _check(!cleanup.isCompleted, 'watchdog completed the native cleanup');
  _check(pendingNotices == 1, 'pending state was not reported once');
  _check(closeCalls == 1, 'cleanup callback ran more than once');

  final Future<bool> retry = gate.requestClose();
  await Future<void>.delayed(Duration.zero);
  _check(closeCalls == 1, 'retry started a second concurrent cleanup');
  cleanup.complete();
  _check(await retry, 'completed cleanup did not permit window close');
  _check(await gate.requestClose(), 'successful close decision was not kept');
  _check(closeCalls == 1, 'successful close was redundantly disposed');
  print('PASS: watchdog response, no cancellation, coalescing, safe retry');
}

void _check(bool condition, String message) {
  if (!condition) throw StateError(message);
}
