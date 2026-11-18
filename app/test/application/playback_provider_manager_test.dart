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
    'versions are SemVer and successful source results use bounded TTL',
    () async {
      final _MutableClock clock = _MutableClock();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('versioned-provider'),
      );
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: [
          PlaybackProviderRegistration(
            provider: provider,
            cacheTtl: const Duration(seconds: 5),
            version: '1.2.3-rc.1+build.7',
          ),
        ],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(
            resolver: provider,
            version: '2.0.0+host.4',
          ),
        ],
        clock: clock.call,
      );

      expect(
        manager.providerRegistrations.single.version,
        '1.2.3-rc.1+build.7',
      );
      expect(manager.resolverRegistrations.single.version, '2.0.0+host.4');
      expect(manager.diagnostics.single.version, '1.2.3-rc.1+build.7');
      await manager.findSources(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      await manager.findSources(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(provider.findCalls, 1);

      clock.advance(const Duration(seconds: 6));
      await manager.findSources(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(provider.findCalls, 2);

      for (final String invalidVersion in [
        'latest',
        '1.2',
        '01.2.3',
        '1.2.3-',
        '1.2.3-alpha.',
      ]) {
        expect(
          () => PlaybackProviderManager(
            providers: [
              PlaybackProviderRegistration(
                provider: MockPlaybackProvider(
                  id: PlaybackProviderId('invalid-version'),
                ),
                version: invalidVersion,
              ),
            ],
            clock: clock.call,
          ),
          throwsArgumentError,
          reason: 'Invalid provider version: $invalidVersion',
        );
      }
    },
  );

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
    'tries later servers before counting an exhausted resolution request',
    () async {
      final _MultiServerProvider provider = _MultiServerProvider(
        failedServerIds: const {'server-1', 'server-2', 'server-3'},
      );
      final PlaybackProviderManager manager = _manager([provider]);

      final PlaybackProviderResult<ResolvedPlaybackStream> result =
          await manager.resolveBestStream(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );

      expect(result, isA<PlaybackProviderSuccess<ResolvedPlaybackStream>>());
      expect(
        (result as PlaybackProviderSuccess<ResolvedPlaybackStream>)
            .value
            .serverId,
        'server-4',
      );
      expect(provider.attemptedServerIds, [
        'server-1',
        'server-2',
        'server-3',
        'server-4',
      ]);
      expect(
        manager.hostDiagnostics.single.circuit,
        ProviderCircuitState.closed,
      );
    },
  );

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
    'a provider 403 does not prevent a configured fallback provider',
    () async {
      final MockPlaybackProvider forbidden = MockPlaybackProvider(
        id: PlaybackProviderId('forbidden'),
        scenario: MockPlaybackScenario.forbidden,
      );
      final MockPlaybackProvider authorizedFallback = MockPlaybackProvider(
        id: PlaybackProviderId('authorized-fallback'),
      );
      final PlaybackProviderManager manager = _manager([
        (forbidden, 20),
        (authorizedFallback, 10),
      ]);

      final PlaybackProviderSuccess<List<PlaybackSource>> result =
          await manager.findSources(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          ) as PlaybackProviderSuccess<List<PlaybackSource>>;

      expect(result.value.single.providerId, authorizedFallback.id);
      expect(forbidden.findCalls, 1);
      expect(authorizedFallback.findCalls, 1);
      expect(
        manager.diagnostics.first.lastFailure,
        PlaybackProviderFailureKind.forbidden,
      );
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

      final PlaybackProviderResult<ResolvedPlaybackStream> rawResult =
          await manager.resolveBestStream(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );
      final PlaybackProviderSuccess<ResolvedPlaybackStream> result =
          rawResult as PlaybackProviderSuccess<ResolvedPlaybackStream>;
      expect(result.value.providerId, healthy.id);
      expect(unavailableSource.resolveCalls, 1);
      expect(
        manager.hostDiagnostics
            .singleWhere(
              (PlaybackVideoHostDiagnostic item) =>
                  item.hostId == 'source-down.mock.invalid',
            )
            .consecutiveFailures,
        1,
      );
      expect(healthy.resolveCalls, 1);
    },
  );

  test('host resolution failures have their own 3/60 circuit', () async {
    final _MutableClock clock = _MutableClock();
    final MockPlaybackProvider provider = MockPlaybackProvider(
      id: PlaybackProviderId('server-flaky'),
      scenario: MockPlaybackScenario.unavailableSource,
    );
    final PlaybackProviderManager manager = _manager([provider], clock: clock);

    for (int i = 0; i < 3; i++) {
      final PlaybackProviderResult<ResolvedPlaybackStream> result =
          await manager.resolveBestStream(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );
      expect(result, isA<PlaybackProviderFailed<ResolvedPlaybackStream>>());
    }
    expect(provider.findCalls, 1);
    expect(provider.resolveCalls, 3);
    expect(manager.hostDiagnostics.single.circuit, ProviderCircuitState.open);

    await manager.resolveBestStream(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(provider.findCalls, 1);
    expect(
      provider.resolveCalls,
      3,
      reason: 'open host circuit skips resolution after discovery',
    );

    clock.advance(const Duration(seconds: 60));
    provider.scenario = MockPlaybackScenario.valid;
    final PlaybackProviderResult<ResolvedPlaybackStream> recovered =
        await manager.resolveBestStream(
          _episode(),
          cancellation: PlaybackCancellationToken(),
        );
    expect(recovered, isA<PlaybackProviderSuccess<ResolvedPlaybackStream>>());
    expect(manager.hostDiagnostics.single.circuit, ProviderCircuitState.closed);
  });

  test(
    'host circuit registry remains bounded and evicts least-recent use',
    () async {
      final _ManyHostProvider provider = _ManyHostProvider(candidateCount: 130);
      final PlaybackProviderManager manager = _manager([provider]);

      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await manager.resolveCandidates(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );

      expect(
        result,
        isA<PlaybackProviderFailed<List<ResolvedPlaybackStream>>>(),
      );
      expect(
        manager.hostDiagnostics,
        hasLength(PlaybackProviderManager.maxHostCircuitBreakers),
      );
      expect(
        manager.hostDiagnostics.any(
          (PlaybackVideoHostDiagnostic item) =>
              item.hostId == 'media-0.example.org',
        ),
        isFalse,
      );
      expect(
        manager.hostDiagnostics.any(
          (PlaybackVideoHostDiagnostic item) =>
              item.hostId == 'media-129.example.org',
        ),
        isTrue,
      );
    },
  );

  test('host circuits are shared across independent anime providers', () async {
    final _MutableClock clock = _MutableClock();
    final _DestinationSourceProvider first = _DestinationSourceProvider(
      PlaybackProviderId('catalog-one'),
    );
    final _DestinationSourceProvider second = _DestinationSourceProvider(
      PlaybackProviderId('catalog-two'),
    );
    final _FailingSharedHostResolver resolver = _FailingSharedHostResolver();
    final PlaybackProviderManager manager = PlaybackProviderManager(
      providers: [
        PlaybackProviderRegistration(provider: first, priority: 20),
        PlaybackProviderRegistration(provider: second, priority: 10),
      ],
      videoHostResolvers: [
        PlaybackVideoHostResolverRegistration(resolver: resolver),
      ],
      clock: clock.call,
    );

    for (int i = 0; i < 3; i++) {
      final PlaybackProviderResult<ResolvedPlaybackStream> result =
          await manager.resolveBestStream(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );
      expect(result, isA<PlaybackProviderFailed<ResolvedPlaybackStream>>());
    }
    expect(resolver.calls, 6);
    expect(manager.hostDiagnostics.single.hostId, 'media.example');
    expect(manager.hostDiagnostics.single.circuit, ProviderCircuitState.open);

    await manager.resolveBestStream(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      resolver.calls,
      6,
      reason: 'open host breaker blocks both providers',
    );
  });

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
    'non-transient half-open result does not restart the cooldown',
    () async {
      final _MutableClock clock = _MutableClock();
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('non-transient-probe'),
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
      final DateTime initialOpenUntil = manager.diagnostics.single.openUntil!;
      clock.advance(const Duration(seconds: 60));
      provider.scenario = MockPlaybackScenario.malformed;

      final PlaybackProviderFailed<List<PlaybackSource>> probeResult =
          await manager.findSources(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          ) as PlaybackProviderFailed<List<PlaybackSource>>;
      expect(
        probeResult.failure.kind,
        PlaybackProviderFailureKind.invalidResponse,
      );
      expect(manager.diagnostics.single.circuit, ProviderCircuitState.halfOpen);
      expect(manager.diagnostics.single.probeInFlight, isFalse);
      expect(manager.diagnostics.single.openUntil, initialOpenUntil);

      provider.scenario = MockPlaybackScenario.valid;
      final PlaybackProviderResult<List<PlaybackSource>> recovery =
          await manager.findSources(
            _episode(),
            cancellation: PlaybackCancellationToken(),
          );
      expect(recovery, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      expect(manager.diagnostics.single.circuit, ProviderCircuitState.closed);
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
    'does not collide cache keys for titles containing separators',
    () async {
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: PlaybackProviderId('key-collision'),
      );
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: <PlaybackProviderRegistration>[
          PlaybackProviderRegistration(
            provider: provider,
            cacheTtl: const Duration(seconds: 30),
          ),
        ],
        clock: DateTime.now,
      );
      final PlaybackEpisode oneTitle = PlaybackEpisode(
        animeId: AnimeId('same-anime'),
        episodeNumber: 1,
        animeTitles: const <String>['blue|lock'],
      );
      final PlaybackEpisode twoTitles = PlaybackEpisode(
        animeId: AnimeId('same-anime'),
        episodeNumber: 1,
        animeTitles: const <String>['blue', 'lock'],
      );

      expect(oneTitle.requestKey, isNot(twoTitles.requestKey));
      await manager.findSources(
        oneTitle,
        cancellation: PlaybackCancellationToken(),
      );
      await manager.findSources(
        twoTitles,
        cancellation: PlaybackCancellationToken(),
      );
      expect(provider.findCalls, 2);
    },
  );

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
      resolutionManager.hostDiagnostics
          .singleWhere(
            (PlaybackVideoHostDiagnostic item) =>
                item.hostId == 'wrong-resolution.mock.invalid',
          )
          .lastFailure,
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
}) {
  final List<(PlaybackSourceProvider, int)> registrations = entries.map((
    Object entry,
  ) {
    if (entry is PlaybackSourceProvider) {
      return (entry, 0);
    }
    final (PlaybackSourceProvider, int) typed =
        entry as (PlaybackSourceProvider, int);
    return typed;
  }).toList();
  return PlaybackProviderManager(
    providers: registrations.map(
      ((PlaybackSourceProvider, int) entry) =>
          PlaybackProviderRegistration(provider: entry.$1, priority: entry.$2),
    ),
    videoHostResolvers: registrations
        .where((entry) => entry.$1 is PlaybackVideoHostResolver)
        .map(
          ((PlaybackSourceProvider, int) entry) =>
              PlaybackVideoHostResolverRegistration(
                resolver: entry.$1 as PlaybackVideoHostResolver,
                priority: entry.$2,
              ),
        ),
    clock: clock == null ? () => DateTime.utc(2026, 11, 10) : clock.call,
  );
}

PlaybackEpisode _episode({int number = 1}) =>
    PlaybackEpisode(animeId: AnimeId('test-series'), episodeNumber: number);

final class _MutableClock {
  DateTime now = DateTime.utc(2026, 11, 10);

  DateTime call() => now;
  void advance(Duration delta) => now = now.add(delta);
}

final class _MultiServerProvider
    implements PlaybackSourceProvider, PlaybackVideoHostResolver {
  _MultiServerProvider({required this._failedServerIds});

  final Set<String> _failedServerIds;
  final List<String> attemptedServerIds = [];

  @override
  final PlaybackProviderId id = PlaybackProviderId('multi-server');

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    PlaybackProviderCapability.sourceAlternatives,
  };

  @override
  String get resolverId => 'test-multi-server-resolver';

  @override
  String get hostId => 'test-multi-server';

  @override
  bool supports(SourceCandidate server) => true;

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) async => PlaybackProviderSuccess([
    PlaybackSource(
      id: 'multi-server-source',
      providerId: id,
      episode: episode,
      language: 'ja',
      quality: 'auto',
      servers: [
        for (int index = 1; index <= 4; index++)
          PlaybackServer(
            id: 'server-$index',
            endpoint: Uri.https('media.example', '/$index'),
          ),
      ],
    ),
  ]);

  @override
  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve(
    PlaybackSource source,
    SourceCandidate server, {
    required PlaybackCancellationToken cancellation,
  }) async {
    attemptedServerIds.add(server.id);
    if (_failedServerIds.contains(server.id)) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.network),
      );
    }
    return PlaybackProviderSuccess(
      ResolvedPlaybackStream(
        providerId: id,
        sourceId: source.id,
        serverId: server.id,
        uri: server.endpoint,
      ),
    );
  }
}

final class _DestinationSourceProvider implements PlaybackSourceProvider {
  _DestinationSourceProvider(this.id);

  @override
  final PlaybackProviderId id;

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
  };

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) async => PlaybackProviderSuccess([
    PlaybackSource(
      id: '${id.value}-source',
      providerId: id,
      episode: episode,
      language: 'unknown',
      quality: 'unknown',
      servers: [
        SourceCandidate(
          id: '${id.value}-candidate',
          hostId: 'shared-host',
          endpoint: Uri.https('media.example', '/episode.mp4'),
          provenance: 'contract test',
        ),
      ],
    ),
  ]);
}

final class _FailingSharedHostResolver implements PlaybackVideoHostResolver {
  int calls = 0;

  @override
  String get hostId => 'shared-host';

  @override
  String get resolverId => 'shared-host-test-resolver';

  @override
  bool supports(SourceCandidate candidate) =>
      candidate.hostId == hostId && candidate.endpoint.host == 'media.example';

  @override
  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve(
    PlaybackSource source,
    SourceCandidate candidate, {
    required PlaybackCancellationToken cancellation,
  }) async {
    calls++;
    return const PlaybackProviderFailed(
      PlaybackProviderFailure(PlaybackProviderFailureKind.network),
    );
  }
}

final class _ManyHostProvider
    implements PlaybackSourceProvider, PlaybackVideoHostResolver {
  _ManyHostProvider({required this.candidateCount});

  final int candidateCount;

  @override
  final PlaybackProviderId id = PlaybackProviderId('many-hosts');

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    PlaybackProviderCapability.sourceAlternatives,
  };

  @override
  String get hostId => 'many-hosts-resolver';

  @override
  String get resolverId => 'many-hosts-resolver';

  @override
  bool supports(SourceCandidate candidate) => candidate.hostId == hostId;

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) async => PlaybackProviderSuccess([
    PlaybackSource(
      id: 'many-hosts-source',
      providerId: id,
      episode: episode,
      language: 'unknown',
      quality: 'unknown',
      servers: [
        for (int index = 0; index < candidateCount; index++)
          SourceCandidate(
            id: 'candidate-$index',
            hostId: hostId,
            endpoint: Uri.https('media-$index.example.org', '/episode.mp4'),
          ),
      ],
    ),
  ]);

  @override
  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve(
    PlaybackSource source,
    SourceCandidate candidate, {
    required PlaybackCancellationToken cancellation,
  }) async => const PlaybackProviderFailed(
    PlaybackProviderFailure(PlaybackProviderFailureKind.network),
  );
}
