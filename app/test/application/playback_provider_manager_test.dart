import 'dart:async';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/application/player/providers/provider_circuit_breaker.dart';
import 'package:anime_app/data/player/providers/mock/mock_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'orders sources and servers by priority with stable tie breaks',
    () async {
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('alternatives'),
        scenario: MockPlaybackScenario.alternatives,
        unavailableServerIds: {'primary-server'},
      );
      final PlaybackProviderManager manager = _manager([provider]);

      final PlaybackProviderResult<ResolvedPlaybackStream> result =
          await manager.resolveBestStream(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );

      expect(result, isA<PlaybackProviderSuccess<ResolvedPlaybackStream>>());
      final ResolvedPlaybackStream stream =
          (result as PlaybackProviderSuccess<ResolvedPlaybackStream>).value;
      expect(stream.sourceId, 'source-japanese-1080p');
      expect(stream.serverId, 'backup-server');
      expect(provider.attemptedServers, ['primary-server', 'backup-server']);
    },
  );

  test('resolves all provider alternatives in stable priority order', () async {
    final MockPlaybackProvider provider = MockPlaybackProvider(
      id: PlaybackProviderId('alternatives'),
      scenario: MockPlaybackScenario.alternatives,
    );
    final PlaybackProviderManager manager = _manager([provider]);

    final PlaybackProviderSuccess<List<ResolvedPlaybackStream>> result =
        await manager.resolveCandidates(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        ) as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>;

    expect(
      result.value.map((ResolvedPlaybackStream stream) => stream.serverId),
      ['primary-server', 'backup-server', 'english-server'],
    );
    expect(provider.attemptedServers, [
      'primary-server',
      'backup-server',
      'english-server',
    ]);
  });

  test(
    'falls back from unavailable and empty providers in configured order',
    () async {
      final MockPlaybackProvider unavailable = MockPlaybackProvider(
        id: PlaybackProviderId('unavailable'),
        scenario: MockPlaybackScenario.providerError,
      );
      final MockPlaybackProvider empty = MockPlaybackProvider(
        id: PlaybackProviderId('empty'),
        scenario: MockPlaybackScenario.empty,
      );
      final MockPlaybackProvider healthy = MockPlaybackProvider(
        id: PlaybackProviderId('healthy'),
      );
      final PlaybackProviderManager manager = _manager([
        (unavailable, 30),
        (empty, 20),
        (healthy, 10),
      ]);

      final PlaybackProviderResult<List<PlaybackSource>> result = await manager
          .findSources(_episode(), cancellation: PlaybackCancellationToken());

      expect(result, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      expect(unavailable.findCalls, 1);
      expect(empty.findCalls, 1);
      expect(healthy.findCalls, 1);
      expect(manager.provider(healthy.id), same(healthy));
    },
  );

  test(
    'falls back to the next provider when every server for a source fails',
    () async {
      final MockPlaybackProvider unavailableSource = MockPlaybackProvider(
        id: PlaybackProviderId('source-down'),
        scenario: MockPlaybackScenario.unavailableSource,
      );
      final MockPlaybackProvider healthy = MockPlaybackProvider(
        id: PlaybackProviderId('fallback'),
      );
      final PlaybackProviderManager manager = _manager([
        (unavailableSource, 20),
        (healthy, 10),
      ]);

      final PlaybackProviderSuccess<ResolvedPlaybackStream> result =
          await manager.resolveBestStream(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          ) as PlaybackProviderSuccess<ResolvedPlaybackStream>;
      expect(result.value.providerId, healthy.id);
      expect(unavailableSource.resolveCalls, 1);
      expect(manager.diagnostics.first.resolutionConsecutiveFailures, 1);
      expect(healthy.resolveCalls, 1);
    },
  );

  test(
    'resolution failures have their own 3/60 circuit despite successful lookup',
    () async {
      final _MutableClock clock = _MutableClock();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('server-flaky'),
        scenario: MockPlaybackScenario.unavailableSource,
      );
      final PlaybackProviderManager manager = _manager([
        provider,
      ], clock: clock);

      for (int i = 0; i < 3; i++) {
        final PlaybackProviderResult<ResolvedPlaybackStream> result =
            await manager.resolveBestStream(
              _episode(),
              cancellation: PlaybackCancellationToken(),
            );
        expect(result, isA<PlaybackProviderFailed<ResolvedPlaybackStream>>());
      }
      expect(provider.findCalls, 3);
      expect(provider.resolveCalls, 3);
      expect(
        manager.diagnostics.single.resolutionCircuit,
        ProviderCircuitState.open,
      );

      await manager.resolveBestStream(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(provider.findCalls, 3);
      expect(
        provider.resolveCalls,
        3,
        reason: 'open resolver circuit skips the server',
      );

      clock.advance(const Duration(seconds: 60));
      provider.scenario = MockPlaybackScenario.valid;
      final PlaybackProviderResult<ResolvedPlaybackStream> recovered =
          await manager.resolveBestStream(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );
      expect(recovered, isA<PlaybackProviderSuccess<ResolvedPlaybackStream>>());
      expect(
        manager.diagnostics.single.resolutionCircuit,
        ProviderCircuitState.closed,
      );
    },
  );

  test(
    'opens after 3 eligible failures and recovers after the 60 second probe',
    () async {
      final _MutableClock clock = _MutableClock();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('flaky'),
        scenario: MockPlaybackScenario.providerError,
      );
      final PlaybackProviderManager manager = _manager([
        provider,
      ], clock: clock);

      for (int i = 0; i < 3; i++) {
        final PlaybackProviderResult<List<PlaybackSource>> result =
            await manager.findSources(
              _episode(),
              cancellation: PlaybackCancellationToken(),
            );
        expect(result, isA<PlaybackProviderFailed<List<PlaybackSource>>>());
      }
      expect(manager.diagnostics.single.circuit, ProviderCircuitState.open);
      expect(manager.diagnostics.single.consecutiveFailures, 3);
      expect(
        manager.diagnostics.single.openUntil,
        clock.now.add(const Duration(seconds: 60)),
      );

      await manager.findSources(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        provider.findCalls,
        3,
        reason: 'open circuit does not call provider',
      );

      clock.advance(const Duration(seconds: 60));
      provider.scenario = MockPlaybackScenario.valid;
      final PlaybackProviderResult<List<PlaybackSource>> recovered =
          await manager.findSources(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );
      expect(recovered, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      expect(provider.findCalls, 4);
      expect(manager.diagnostics.single.circuit, ProviderCircuitState.closed);
      expect(manager.diagnostics.single.consecutiveFailures, 0);
    },
  );

  test(
    'half-open allows one concurrent probe across independent requests',
    () async {
      final _MutableClock clock = _MutableClock();
      final Completer<void> gate = Completer<void>();
      final Completer<void> started = Completer<void>();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('probe'),
        scenario: MockPlaybackScenario.providerError,
      );
      final PlaybackProviderManager manager = _manager([
        provider,
      ], clock: clock);
      for (int i = 0; i < 3; i++) {
        await manager.findSources(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        );
      }
      clock.advance(const Duration(seconds: 60));
      provider.scenario = MockPlaybackScenario.valid;
      provider.requestGate = gate;
      provider.requestStarted = started;

      final Future<PlaybackProviderResult<List<PlaybackSource>>> probe = manager
          .findSources(
            _episode(number: 1),
            cancellation: PlaybackCancellationToken(),
          );
      await started.future;
      final PlaybackProviderResult<List<PlaybackSource>> parallel =
          await manager.findSources(
            _episode(number: 2),
            cancellation: PlaybackCancellationToken(),
          );
      expect(parallel, isA<PlaybackProviderFailed<List<PlaybackSource>>>());
      expect(provider.findCalls, 4);

      gate.complete();
      expect(await probe, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      expect(manager.diagnostics.single.circuit, ProviderCircuitState.closed);
    },
  );

  test(
    'cancelled half-open lookup releases the probe without counting failure',
    () async {
      final _MutableClock clock = _MutableClock();
      final Completer<void> gate = Completer<void>();
      final Completer<void> started = Completer<void>();
      final Completer<void> requestCompleted = Completer<void>();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('cancel-probe'),
        scenario: MockPlaybackScenario.providerError,
      );
      final PlaybackProviderManager manager = _manager([
        provider,
      ], clock: clock);
      for (int i = 0; i < 3; i++) {
        await manager.findSources(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        );
      }
      clock.advance(const Duration(seconds: 60));
      provider.scenario = MockPlaybackScenario.valid;
      provider.requestGate = gate;
      provider.requestStarted = started;
      provider.requestCompleted = requestCompleted;
      final PlaybackCancellationToken token = PlaybackCancellationToken();
      final Future<PlaybackProviderResult<List<PlaybackSource>>> pending =
          manager.findSources(_episode(number: 3), cancellation: token);
      await started.future;
      token.cancel();
      final PlaybackProviderFailed<List<PlaybackSource>> cancelled =
          await pending as PlaybackProviderFailed<List<PlaybackSource>>;
      expect(cancelled.failure.kind, PlaybackProviderFailureKind.cancelled);
      gate.complete();
      await requestCompleted.future;
      expect(manager.diagnostics.single.probeInFlight, isFalse);
      expect(manager.diagnostics.single.circuit, ProviderCircuitState.halfOpen);
    },
  );

  test('deduplicates concurrent identical requests', () async {
    final Completer<void> gate = Completer<void>();
    final MockPlaybackProvider provider = MockPlaybackProvider(
      id: PlaybackProviderId('deduplicated'),
      requestGate: gate,
    );
    final PlaybackProviderManager manager = _manager([provider]);
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();

    final Future<PlaybackProviderResult<List<PlaybackSource>>> first = manager
        .findSources(_episode(), cancellation: cancellation);
    final Future<PlaybackProviderResult<List<PlaybackSource>>> second = manager
        .findSources(_episode(), cancellation: cancellation);
    expect(provider.findCalls, 1);
    gate.complete();
    final List<PlaybackProviderResult<List<PlaybackSource>>> results =
        await Future.wait([first, second]);
    expect(results[0], isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
    expect(results[1], isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
  });

  test(
    'one canceled waiter does not cancel another deduplicated caller',
    () async {
      final Completer<void> gate = Completer<void>();
      final Completer<void> started = Completer<void>();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('independent-cancellation'),
        requestGate: gate,
        requestStarted: started,
      );
      final PlaybackProviderManager manager = _manager([provider]);
      final PlaybackCancellationToken firstToken = PlaybackCancellationToken();
      final PlaybackCancellationToken secondToken = PlaybackCancellationToken();

      final Future<PlaybackProviderResult<List<PlaybackSource>>> first = manager
          .findSources(_episode(), cancellation: firstToken);
      await started.future;
      final Future<PlaybackProviderResult<List<PlaybackSource>>> second =
          manager.findSources(_episode(), cancellation: secondToken);
      firstToken.cancel();

      expect(
        await first,
        isA<PlaybackProviderFailed<List<PlaybackSource>>>().having(
          (PlaybackProviderFailed<List<PlaybackSource>> result) =>
              result.failure.kind,
          'failure kind',
          PlaybackProviderFailureKind.cancelled,
        ),
      );
      gate.complete();
      expect(
        await second,
        isA<PlaybackProviderSuccess<List<PlaybackSource>>>(),
      );
      expect(provider.findCalls, 1);
    },
  );

  test('a request after the last waiter cancels starts fresh work', () async {
    final Completer<void> gate = Completer<void>();
    final Completer<void> started = Completer<void>();
    final MockPlaybackProvider provider = MockPlaybackProvider(
      id: PlaybackProviderId('retry-after-cancel'),
      requestGate: gate,
      requestStarted: started,
    );
    final PlaybackProviderManager manager = _manager([provider]);
    final PlaybackCancellationToken firstToken = PlaybackCancellationToken();
    final Future<PlaybackProviderResult<List<PlaybackSource>>> first = manager
        .findSources(_episode(), cancellation: firstToken);
    await started.future;
    firstToken.cancel();
    expect(
      await first,
      isA<PlaybackProviderFailed<List<PlaybackSource>>>().having(
        (PlaybackProviderFailed<List<PlaybackSource>> result) =>
            result.failure.kind,
        'failure kind',
        PlaybackProviderFailureKind.cancelled,
      ),
    );

    final Future<PlaybackProviderResult<List<PlaybackSource>>> retry = manager
        .findSources(_episode(), cancellation: PlaybackCancellationToken());
    expect(provider.findCalls, 2);
    gate.complete();
    expect(await retry, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
  });

  test(
    'source listing and resolution share one in-flight provider lookup',
    () async {
      final Completer<void> gate = Completer<void>();
      final Completer<void> started = Completer<void>();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('shared-query'),
        requestGate: gate,
        requestStarted: started,
      );
      final PlaybackProviderManager manager = _manager([provider]);
      final PlaybackEpisode episode = _episode();

      final Future<PlaybackProviderResult<List<PlaybackSource>>> listing =
          manager.findSources(
            episode,
            cancellation: PlaybackCancellationToken(),
          );
      await started.future;
      final Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolving =
          manager.resolveBestStream(
            episode,
            cancellation: PlaybackCancellationToken(),
          );
      expect(provider.findCalls, 1);
      gate.complete();
      expect(
        await listing,
        isA<PlaybackProviderSuccess<List<PlaybackSource>>>(),
      );
      expect(
        await resolving,
        isA<PlaybackProviderSuccess<ResolvedPlaybackStream>>(),
      );
      expect(provider.findCalls, 1);
      expect(provider.resolveCalls, 1);
    },
  );

  test(
    'cancellation and invalid provider response do not block healthy fallback',
    () async {
      final MockPlaybackProvider malformed = MockPlaybackProvider(
        id: PlaybackProviderId('malformed'),
        scenario: MockPlaybackScenario.malformed,
      );
      final MockPlaybackProvider healthy = MockPlaybackProvider(
        id: PlaybackProviderId('healthy'),
      );
      final PlaybackProviderManager manager = _manager([
        (malformed, 20),
        (healthy, 10),
      ]);
      final PlaybackProviderSuccess<List<PlaybackSource>> result =
          await manager.findSources(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          ) as PlaybackProviderSuccess<List<PlaybackSource>>;
      expect(result.value.single.providerId, healthy.id);
      expect(
        manager.diagnostics.first.lastFailure,
        PlaybackProviderFailureKind.invalidResponse,
      );

      final PlaybackCancellationToken cancelled = PlaybackCancellationToken()
        ..cancel();
      final PlaybackProviderFailed<List<PlaybackSource>> cancellation =
          await manager.findSources(
            _episode(number: 9),
            cancellation: cancelled,
          ) as PlaybackProviderFailed<List<PlaybackSource>>;
      expect(cancellation.failure.kind, PlaybackProviderFailureKind.cancelled);
    },
  );

  test('rejects wrong-episode, undeclared-alternative, and mismatched resolution data', () async {
    final MockPlaybackProvider wrongEpisode = MockPlaybackProvider(
      id: PlaybackProviderId('wrong-episode'),
      scenario: MockPlaybackScenario.wrongEpisode,
    );
    final MockPlaybackProvider healthy = MockPlaybackProvider(
      id: PlaybackProviderId('valid-fallback'),
    );
    final PlaybackProviderManager episodeManager = _manager([
      (wrongEpisode, 20),
      (healthy, 10),
    ]);
    final PlaybackProviderSuccess<List<PlaybackSource>> episodeResult =
        await episodeManager.findSources(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        ) as PlaybackProviderSuccess<List<PlaybackSource>>;
    expect(episodeResult.value.single.providerId, healthy.id);
    expect(
      episodeManager.diagnostics.first.lastFailure,
      PlaybackProviderFailureKind.invalidResponse,
    );

    final MockPlaybackProvider undeclaredAlternatives = MockPlaybackProvider(
      id: PlaybackProviderId('no-alternative-capability'),
      scenario: MockPlaybackScenario.alternatives,
      capabilities: const {PlaybackProviderCapability.episodeSources},
    );
    final PlaybackProviderManager capabilityManager = _manager([
      undeclaredAlternatives,
      healthy,
    ]);
    final PlaybackProviderSuccess<List<PlaybackSource>> capabilityResult =
        await capabilityManager.findSources(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        ) as PlaybackProviderSuccess<List<PlaybackSource>>;
    expect(capabilityResult.value.single.providerId, healthy.id);

    final MockPlaybackProvider wrongResolution = MockPlaybackProvider(
      id: PlaybackProviderId('wrong-resolution'),
      scenario: MockPlaybackScenario.malformedResolution,
    );
    final PlaybackProviderManager resolutionManager = _manager([
      (wrongResolution, 20),
      (healthy, 10),
    ]);
    final PlaybackProviderSuccess<ResolvedPlaybackStream> resolutionResult =
        await resolutionManager.resolveBestStream(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        ) as PlaybackProviderSuccess<ResolvedPlaybackStream>;
    expect(resolutionResult.value.providerId, healthy.id);
    expect(
      resolutionManager.diagnostics
          .singleWhere(
            (PlaybackProviderDiagnostic item) => item.id == wrongResolution.id,
          )
          .resolutionLastFailure,
      PlaybackProviderFailureKind.invalidResponse,
    );
  });

  test('isolates circuits and rejects duplicate provider identifiers', () {
    final MockPlaybackProvider duplicateA = MockPlaybackProvider(
      id: PlaybackProviderId('same'),
    );
    final MockPlaybackProvider duplicateB = MockPlaybackProvider(
      id: PlaybackProviderId('same'),
    );
    expect(() => _manager([duplicateA, duplicateB]), throwsArgumentError);
  });
}

PlaybackProviderManager _manager(
  Iterable<Object> entries, {
  _MutableClock? clock,
}) => PlaybackProviderManager(
  providers: entries.map((Object entry) {
    if (entry is MockPlaybackProvider) {
      return PlaybackProviderRegistration(provider: entry);
    }
    final (MockPlaybackProvider, int) typed =
        entry as (MockPlaybackProvider, int);
    return PlaybackProviderRegistration(provider: typed.$1, priority: typed.$2);
  }),
  clock: clock == null ? () => DateTime.utc(2026, 11, 10) : clock.call,
);

PlaybackEpisode _episode({int number = 1}) =>
    PlaybackEpisode(animeId: AnimeId('test-series'), episodeNumber: number);

final class _MutableClock {
  DateTime now = DateTime.utc(2026, 11, 10);

  DateTime call() => now;
  void advance(Duration delta) => now = now.add(delta);
}
