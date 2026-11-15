import 'dart:async';

import 'package:anime_app/app/player/spike_window_close_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'window close waits for playback cleanup and coalesces callers',
    () async {
      final Completer<void> cleanup = Completer<void>();
      int closeCalls = 0;
      final SpikeWindowCloseGate gate = SpikeWindowCloseGate(
        () {
          closeCalls++;
          return cleanup.future;
        },
        () async {},
        () {},
      );

      final Future<bool> first = gate.requestClose();
      final Future<bool> second = gate.requestClose();
      bool completed = false;
      unawaited(first.then((_) => completed = true));
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(closeCalls, 1);

      cleanup.complete();
      expect(await first, isTrue);
    },
  );

  test(
    'failed native cleanup keeps the window open and reports failure',
    () async {
      bool reported = false;
      final SpikeWindowCloseGate gate = SpikeWindowCloseGate(
        () async => throw StateError('dispose failed'),
        () async => throw StateError('lease quarantined'),
        () => reported = true,
      );

      expect(await gate.requestClose(), isFalse);
      expect(reported, isTrue);
    },
  );

  test('startup cleanup can allow close after module open fails', () async {
    int retries = 0;
    final SpikeWindowCloseGate gate = SpikeWindowCloseGate(
      () async => throw StateError('open failed'),
      () async {
        retries++;
      },
      () {},
    );

    expect(await gate.requestClose(), isTrue);
    expect(retries, 1);
  });

  test(
    'watchdog keeps window open without cancelling or duplicating cleanup',
    () async {
      final Completer<void> cleanup = Completer<void>();
      int closeCalls = 0;
      int pendingNotifications = 0;
      final SpikeWindowCloseGate gate = SpikeWindowCloseGate(
        () {
          closeCalls++;
          return cleanup.future;
        },
        () async {},
        () {},
        closeWatchdog: const Duration(milliseconds: 1),
        onCleanupPending: () => pendingNotifications++,
      );

      expect(await gate.requestClose(), isFalse);
      expect(pendingNotifications, 1);
      expect(cleanup.isCompleted, isFalse);

      final Future<bool> retry = gate.requestClose();
      await Future<void>.delayed(Duration.zero);
      expect(closeCalls, 1, reason: 'A watchdog does not cancel cleanup.');
      cleanup.complete();
      expect(await retry, isTrue);
      expect(await gate.requestClose(), isTrue);
      expect(closeCalls, 1);
    },
  );
}
