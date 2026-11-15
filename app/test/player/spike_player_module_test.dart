import 'dart:async';
import 'dart:io';

import 'package:anime_app/app/player/spike_player_module.dart';
import 'package:anime_app/data/player/engine/active_player_lease.dart';
import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid open arguments leave input catalogs caller-owned', () async {
    int disposeCalls = 0;

    await expectLater(
      SpikePlayerModule.open(
        null,
        externalSubtitleCatalog: _UnusedSubtitleCatalog(),
        disposeExternalSubtitleCatalog: () => disposeCalls++,
      ),
      throwsArgumentError,
    );

    expect(disposeCalls, 0);
  });

  test('post-preflight lease contention remains recoverable', () async {
    ActivePlayerLease? concurrentOwner;
    try {
      await expectLater(
        SpikePlayerModule.open(
          File('fixture.mkv'),
          engineFactory: () {
            concurrentOwner = ActivePlayerLease.acquire();
            throw ActivePlayerLeaseInUse();
          },
        ),
        throwsA(isA<ActivePlayerLeaseInUse>()),
      );
      expect(
        ActivePlayerLease.acquire,
        throwsA(isA<ActivePlayerLeaseInUse>()),
        reason: 'The losing open must not disturb the concurrent owner lease.',
      );
    } finally {
      await concurrentOwner?.release(() async {});
    }
  });

  test(
    'open awaits rollback after synchronous engine factory failure',
    () async {
      final Completer<void> cleanupStarted = Completer<void>();
      final Completer<void> cleanupGate = Completer<void>();
      ActivePlayerLease? failedStartupLease;
      bool openCompleted = false;
      final Future<SpikePlayerModule> opening = SpikePlayerModule.open(
        File('fixture.mkv'),
        engineFactory: () {
          failedStartupLease = ActivePlayerLease.acquire();
          unawaited(
            failedStartupLease!.release(() {
              if (!cleanupStarted.isCompleted) cleanupStarted.complete();
              return cleanupGate.future;
            }),
          );
          throw StateError('synchronous engine construction failed');
        },
      );
      unawaited(
        opening.then<void>(
          (_) => openCompleted = true,
          onError: (Object _, StackTrace _) => openCompleted = true,
        ),
      );

      await cleanupStarted.future;
      await Future<void>.delayed(Duration.zero);
      expect(openCompleted, isFalse);
      expect(ActivePlayerLease.acquire, throwsA(isA<ActivePlayerLeaseInUse>()));

      cleanupGate.complete();
      await expectLater(opening, throwsStateError);
      final ActivePlayerLease next = ActivePlayerLease.acquire();
      await next.release(() async {});
    },
  );

  test(
    'failed synchronous rollback is reported as unsafe startup cleanup',
    () async {
      final Completer<void> cleanupStarted = Completer<void>();
      final Completer<void> cleanupGate = Completer<void>();
      ActivePlayerLease? failedStartupLease;
      int cleanupAttempts = 0;
      final Future<SpikePlayerModule> opening = SpikePlayerModule.open(
        File('fixture.mkv'),
        engineFactory: () {
          failedStartupLease = ActivePlayerLease.acquire();
          unawaited(
            failedStartupLease!.release(() async {
              cleanupAttempts++;
              if (cleanupAttempts == 1) {
                cleanupStarted.complete();
                await cleanupGate.future;
              }
            }),
          );
          throw StateError('synchronous engine construction failed');
        },
      );

      await cleanupStarted.future;
      cleanupGate.completeError(StateError('injected dispose failure'));
      await expectLater(
        opening,
        throwsA(isA<SpikePlayerStartupCleanupFailure>()),
      );
      await ActivePlayerLease.retryPendingRelease();
      expect(cleanupAttempts, 2);
      final ActivePlayerLease next = ActivePlayerLease.acquire();
      await next.release(() async {});
    },
  );
}

final class _UnusedSubtitleCatalog implements ExternalSubtitleCatalog {
  @override
  Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download(
    ExternalSubtitleCandidate candidate,
  ) async => const ExternalSubtitleFailure(ExternalSubtitleFailureKind.unknown);

  @override
  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  ) async => const ExternalSubtitleFailure(ExternalSubtitleFailureKind.unknown);
}
