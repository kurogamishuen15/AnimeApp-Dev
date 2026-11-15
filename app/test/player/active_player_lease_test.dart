import 'dart:async';

import 'package:anime_app/data/player/engine/active_player_lease.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'slot remains reserved and concurrent releases share completion',
    () async {
      final ActivePlayerLease lease = ActivePlayerLease.acquire();
      final Completer<void> nativeRelease = Completer<void>();
      int cleanupCalls = 0;

      final Future<void> first = lease.release(() {
        cleanupCalls++;
        return nativeRelease.future;
      });
      final Future<void> second = lease.release(() async => cleanupCalls++);
      bool firstCompleted = false;
      unawaited(first.then((_) => firstCompleted = true));

      expect(identical(first, second), isTrue);
      expect(cleanupCalls, 1);
      expect(() => ActivePlayerLease.acquire(), throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(firstCompleted, isFalse);

      nativeRelease.complete();
      await Future.wait([first, second]);

      final ActivePlayerLease next = ActivePlayerLease.acquire();
      await next.release(() async {});
    },
  );

  test(
    'retry refuses to take over a live Player without a dispose request',
    () async {
      final ActivePlayerLease lease = ActivePlayerLease.acquire();
      expect(ActivePlayerLease.retryPendingRelease, throwsStateError);
      await lease.release(() async {});
    },
  );

  test(
    'failed cleanup keeps slot reserved and permits a successful retry',
    () async {
      final ActivePlayerLease lease = ActivePlayerLease.acquire();
      int attempts = 0;

      await expectLater(
        lease.release(() async {
          attempts++;
          if (attempts == 1) {
            throw StateError('injected native dispose failure');
          }
        }),
        throwsStateError,
      );
      expect(() => ActivePlayerLease.acquire(), throwsStateError);

      await ActivePlayerLease.retryPendingRelease();
      expect(attempts, 2);
      final ActivePlayerLease next = ActivePlayerLease.acquire();
      await next.release(() async {});
    },
  );

  test(
    'retry cannot replace the cleanup callback owned by the lease',
    () async {
      final ActivePlayerLease lease = ActivePlayerLease.acquire();
      int originalCalls = 0;
      int replacementCalls = 0;

      await expectLater(
        lease.release(() async {
          originalCalls++;
          if (originalCalls == 1) throw StateError('first attempt failed');
        }),
        throwsStateError,
      );

      await lease.release(() async => replacementCalls++);
      expect(originalCalls, 2);
      expect(replacementCalls, 0);
      final ActivePlayerLease next = ActivePlayerLease.acquire();
      await next.release(() async {});
    },
  );
}
