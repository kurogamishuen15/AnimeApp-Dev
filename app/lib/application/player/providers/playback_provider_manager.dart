import 'dart:async';

import '../../../domain/player/providers/playback_provider_contract.dart';
import '../../../domain/player/providers/playback_source.dart';
import 'provider_circuit_breaker.dart';

final class PlaybackProviderRegistration {
  const PlaybackProviderRegistration({
    required this.provider,
    this.priority = 0,
    this.enabled = true,
  });

  final PlaybackSourceProvider provider;
  final int priority;
  final bool enabled;
}

final class PlaybackProviderDiagnostic {
  const PlaybackProviderDiagnostic({
    required this.id,
    required this.circuit,
    required this.consecutiveFailures,
    required this.openUntil,
    required this.lastFailure,
    required this.probeInFlight,
    required this.resolutionCircuit,
    required this.resolutionConsecutiveFailures,
    required this.resolutionOpenUntil,
    required this.resolutionLastFailure,
    required this.resolutionProbeInFlight,
  });

  final PlaybackProviderId id;
  final ProviderCircuitState circuit;
  final int consecutiveFailures;
  final DateTime? openUntil;
  final PlaybackProviderFailureKind? lastFailure;
  final bool probeInFlight;
  final ProviderCircuitState resolutionCircuit;
  final int resolutionConsecutiveFailures;
  final DateTime? resolutionOpenUntil;
  final PlaybackProviderFailureKind? resolutionLastFailure;
  final bool resolutionProbeInFlight;
}

/// Orchestrates providers, fallback and source/server ordering; it never owns
/// or calls the native playback engine.
final class PlaybackProviderManager {
  PlaybackProviderManager({
    required Iterable<PlaybackProviderRegistration> providers,
    required DateTime Function() clock,
    this.circuitFailureThreshold = 3,
    this.circuitCooldown = const Duration(seconds: 60),
  }) : _clock = clock {
    final List<PlaybackProviderRegistration> ordered =
        providers
            .where((PlaybackProviderRegistration item) => item.enabled)
            .toList()
          ..sort((
            PlaybackProviderRegistration a,
            PlaybackProviderRegistration b,
          ) {
            final int priority = b.priority.compareTo(a.priority);
            return priority != 0
                ? priority
                : a.provider.id.value.compareTo(b.provider.id.value);
          });
    final Set<PlaybackProviderId> ids = {};
    for (final PlaybackProviderRegistration item in ordered) {
      if (!ids.add(item.provider.id)) {
        throw ArgumentError('Playback provider IDs must be unique.');
      }
      _registrations[item.provider.id] = item;
      _breakers[item.provider.id] = ProviderCircuitBreaker(
        clock: clock,
        failureThreshold: circuitFailureThreshold,
        cooldown: circuitCooldown,
      );
      _resolutionBreakers[item.provider.id] = ProviderCircuitBreaker(
        clock: clock,
        failureThreshold: circuitFailureThreshold,
        cooldown: circuitCooldown,
      );
    }
    _ordered = List.unmodifiable(ordered);
  }

  final DateTime Function() _clock;
  final int circuitFailureThreshold;
  final Duration circuitCooldown;
  final Map<PlaybackProviderId, PlaybackProviderRegistration> _registrations =
      {};
  final Map<PlaybackProviderId, ProviderCircuitBreaker> _breakers = {};
  final Map<PlaybackProviderId, ProviderCircuitBreaker> _resolutionBreakers =
      {};
  late final List<PlaybackProviderRegistration> _ordered;
  final Map<String, _SharedProviderRequest> _inFlight = {};
  final Map<String, _SharedProviderRequest> _providerRequests = {};

  PlaybackSourceProvider? provider(PlaybackProviderId id) =>
      _registrations[id]?.provider;

  List<PlaybackProviderDiagnostic> get diagnostics => List.unmodifiable([
    for (final PlaybackProviderRegistration item in _ordered)
      _diagnostic(item.provider.id),
  ]);

  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) => _deduplicate<List<PlaybackSource>>(
    'sources:${episode.requestKey}',
    cancellation,
    (PlaybackCancellationToken sharedCancellation) =>
        _findSources(episode, sharedCancellation),
  );

  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolveBestStream(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) => _deduplicate<ResolvedPlaybackStream>(
    'resolve:${episode.requestKey}',
    cancellation,
    (PlaybackCancellationToken sharedCancellation) async {
      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await _resolveCandidates(
            episode,
            sharedCancellation,
            stopAfterFirst: true,
          );
      return switch (result) {
        PlaybackProviderSuccess<List<ResolvedPlaybackStream>>(:final value)
            when value.isNotEmpty =>
          PlaybackProviderSuccess(value.first),
        PlaybackProviderSuccess<List<ResolvedPlaybackStream>>() ||
        PlaybackProviderEmpty<List<ResolvedPlaybackStream>>() =>
          const PlaybackProviderEmpty(),
        PlaybackProviderUnsupported<List<ResolvedPlaybackStream>>(
          :final capability,
        ) =>
          PlaybackProviderUnsupported(capability),
        PlaybackProviderFailed<List<ResolvedPlaybackStream>>(:final failure) =>
          PlaybackProviderFailed(failure),
      };
    },
  );

  /// Resolves every server candidate in provider/source/server priority order.
  /// The application may try the next URI if the playback engine rejects one.
  Future<PlaybackProviderResult<List<ResolvedPlaybackStream>>>
  resolveCandidates(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) => _deduplicate<List<ResolvedPlaybackStream>>(
    'resolve-candidates:${episode.requestKey}',
    cancellation,
    (PlaybackCancellationToken sharedCancellation) =>
        _resolveCandidates(episode, sharedCancellation, stopAfterFirst: false),
  );

  Future<PlaybackProviderResult<List<PlaybackSource>>> _findSources(
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation,
  ) async {
    PlaybackProviderFailure? lastFailure;
    for (final PlaybackProviderRegistration registration in _ordered) {
      if (cancellation.isCancelled) {
        return const PlaybackProviderFailed(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        );
      }
      final PlaybackSourceProvider provider = registration.provider;
      if (!provider.capabilities.contains(
        PlaybackProviderCapability.episodeSources,
      )) {
        continue;
      }
      final PlaybackProviderResult<List<PlaybackSource>> result =
          await _fetchProviderSources(provider, episode, cancellation);
      switch (result) {
        case PlaybackProviderSuccess<List<PlaybackSource>>(:final value):
          if (value.isNotEmpty) return result;
        case PlaybackProviderEmpty<List<PlaybackSource>>():
          break;
        case PlaybackProviderUnsupported<List<PlaybackSource>>():
          break;
        case PlaybackProviderFailed<List<PlaybackSource>>(:final failure):
          lastFailure = failure;
      }
    }
    return lastFailure == null
        ? const PlaybackProviderEmpty()
        : PlaybackProviderFailed(lastFailure);
  }

  Future<PlaybackProviderResult<List<ResolvedPlaybackStream>>>
  _resolveCandidates(
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation, {
    required bool stopAfterFirst,
  }) async {
    PlaybackProviderFailure? lastFailure;
    final List<ResolvedPlaybackStream> candidates = [];
    for (final PlaybackProviderRegistration registration in _ordered) {
      if (cancellation.isCancelled) {
        return const PlaybackProviderFailed(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        );
      }
      final PlaybackSourceProvider provider = registration.provider;
      if (!provider.capabilities.contains(
            PlaybackProviderCapability.resolveServer,
          ) ||
          !provider.capabilities.contains(
            PlaybackProviderCapability.episodeSources,
          )) {
        continue;
      }
      final ProviderCircuitBreaker breaker = _resolutionBreakers[provider.id]!;
      final CircuitPermit permit = breaker.acquirePermit();
      if (permit == CircuitPermit.deny) {
        lastFailure = PlaybackProviderFailure(
          PlaybackProviderFailureKind.circuitOpen,
          retryAfter: _remainingCooldown(breaker),
        );
        continue;
      }
      final PlaybackProviderResult<List<PlaybackSource>> sourceResult =
          await _findOnlyProviderSources(provider, episode, cancellation);
      if (sourceResult case PlaybackProviderFailed<List<PlaybackSource>>(
        :final failure,
      )) {
        if (permit == CircuitPermit.probe) breaker.releaseProbe();
        lastFailure = failure;
        continue;
      }
      if (sourceResult is PlaybackProviderEmpty<List<PlaybackSource>> ||
          sourceResult is PlaybackProviderUnsupported<List<PlaybackSource>>) {
        if (permit == CircuitPermit.probe) breaker.releaseProbe();
        continue;
      }
      if (sourceResult case PlaybackProviderSuccess<List<PlaybackSource>>(
        :final value,
      )) {
        if (value.isEmpty) {
          if (permit == CircuitPermit.probe) breaker.releaseProbe();
          continue;
        }
        final List<PlaybackSource> sources = [...value]..sort(_compareSource);
        for (final PlaybackSource source in sources) {
          final List<PlaybackServer> servers = [...source.servers]
            ..sort(_compareServer);
          for (final PlaybackServer server in servers) {
            if (cancellation.isCancelled) {
              if (permit == CircuitPermit.probe) breaker.releaseProbe();
              return const PlaybackProviderFailed(
                PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
              );
            }
            try {
              final PlaybackProviderResult<ResolvedPlaybackStream> result =
                  await provider.resolveServer(
                    source,
                    server,
                    cancellation: cancellation,
                  );
              switch (result) {
                case PlaybackProviderSuccess<ResolvedPlaybackStream>(
                  :final value,
                ):
                  if (value.providerId != provider.id ||
                      value.sourceId != source.id ||
                      value.serverId != server.id) {
                    final PlaybackProviderFailure failure =
                        const PlaybackProviderFailure(
                          PlaybackProviderFailureKind.invalidResponse,
                        );
                    _recordFailure(breaker, permit, failure);
                    lastFailure = failure;
                    if (breaker.state == ProviderCircuitState.open) break;
                    continue;
                  }
                  breaker.recordSuccess();
                  candidates.add(value);
                  if (stopAfterFirst) {
                    return PlaybackProviderSuccess(
                      List.unmodifiable(candidates),
                    );
                  }
                case PlaybackProviderEmpty<ResolvedPlaybackStream>():
                  breaker.recordSuccess();
                case PlaybackProviderUnsupported<ResolvedPlaybackStream>():
                  if (permit == CircuitPermit.probe) {
                    breaker.recordFailure(
                      const PlaybackProviderFailure(
                        PlaybackProviderFailureKind.unsupported,
                      ),
                    );
                  }
                case PlaybackProviderFailed<ResolvedPlaybackStream>(
                  :final failure,
                ):
                  _recordFailure(breaker, permit, failure);
                  lastFailure = failure;
              }
              if (breaker.state == ProviderCircuitState.open) break;
            } catch (_) {
              if (cancellation.isCancelled) {
                if (permit == CircuitPermit.probe) breaker.releaseProbe();
                return const PlaybackProviderFailed(
                  PlaybackProviderFailure(
                    PlaybackProviderFailureKind.cancelled,
                  ),
                );
              }
              final PlaybackProviderFailure failure = PlaybackProviderFailure(
                PlaybackProviderFailureKind.unavailable,
              );
              _recordFailure(breaker, permit, failure);
              lastFailure = failure;
              if (breaker.state == ProviderCircuitState.open) break;
            }
          }
        }
      }
    }
    if (candidates.isNotEmpty) {
      return PlaybackProviderSuccess(List.unmodifiable(candidates));
    }
    return lastFailure == null
        ? const PlaybackProviderEmpty()
        : PlaybackProviderFailed(lastFailure);
  }

  Future<PlaybackProviderResult<List<PlaybackSource>>> _findOnlyProviderSources(
    PlaybackSourceProvider provider,
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation,
  ) async {
    return _fetchProviderSources(provider, episode, cancellation);
  }

  Future<PlaybackProviderResult<List<PlaybackSource>>> _fetchProviderSources(
    PlaybackSourceProvider provider,
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation,
  ) {
    final String key = '${provider.id.value}:${episode.requestKey}';
    return _joinShared<List<PlaybackSource>>(
      _providerRequests,
      key,
      cancellation,
      (PlaybackCancellationToken sharedCancellation) =>
          _executeProviderSources(provider, episode, sharedCancellation),
    );
  }

  Future<PlaybackProviderResult<List<PlaybackSource>>> _executeProviderSources(
    PlaybackSourceProvider provider,
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation,
  ) async {
    if (cancellation.isCancelled) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );
    }
    final ProviderCircuitBreaker breaker = _breakers[provider.id]!;
    final CircuitPermit permit = breaker.acquirePermit();
    if (permit == CircuitPermit.deny) {
      return PlaybackProviderFailed(
        PlaybackProviderFailure(
          PlaybackProviderFailureKind.circuitOpen,
          retryAfter: _remainingCooldown(breaker),
        ),
      );
    }
    try {
      final PlaybackProviderResult<List<PlaybackSource>> result = await provider
          .findSources(episode, cancellation: cancellation);
      switch (result) {
        case PlaybackProviderSuccess<List<PlaybackSource>>(:final value):
          if (_validateSources(provider, episode, value) != null) {
            const PlaybackProviderFailure failure = PlaybackProviderFailure(
              PlaybackProviderFailureKind.invalidResponse,
            );
            _recordFailure(breaker, permit, failure);
            return const PlaybackProviderFailed(failure);
          }
          breaker.recordSuccess();
          return result;
        case PlaybackProviderEmpty<List<PlaybackSource>>():
          breaker.recordSuccess();
          return result;
        case PlaybackProviderUnsupported<List<PlaybackSource>>():
          if (permit == CircuitPermit.probe) {
            breaker.recordFailure(
              const PlaybackProviderFailure(
                PlaybackProviderFailureKind.unsupported,
              ),
            );
          }
          return result;
        case PlaybackProviderFailed<List<PlaybackSource>>(:final failure):
          _recordFailure(breaker, permit, failure);
          return result;
      }
    } catch (_) {
      if (cancellation.isCancelled) {
        if (permit == CircuitPermit.probe) breaker.releaseProbe();
        return const PlaybackProviderFailed(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        );
      }
      const PlaybackProviderFailure failure = PlaybackProviderFailure(
        PlaybackProviderFailureKind.unavailable,
      );
      _recordFailure(breaker, permit, failure);
      return const PlaybackProviderFailed(failure);
    }
  }

  String? _validateSources(
    PlaybackSourceProvider provider,
    PlaybackEpisode episode,
    List<PlaybackSource> sources,
  ) {
    final Set<String> ids = {};
    for (final PlaybackSource source in sources) {
      if (source.providerId != provider.id ||
          source.episode.requestKey != episode.requestKey ||
          !ids.add(source.id) ||
          ((source.servers.length > 1 || sources.length > 1) &&
              !provider.capabilities.contains(
                PlaybackProviderCapability.sourceAlternatives,
              ))) {
        return 'Provider source identity is invalid or repeated.';
      }
    }
    return null;
  }

  int _compareSource(PlaybackSource a, PlaybackSource b) {
    final int priority = b.priority.compareTo(a.priority);
    return priority != 0 ? priority : a.id.compareTo(b.id);
  }

  int _compareServer(PlaybackServer a, PlaybackServer b) {
    final int priority = b.priority.compareTo(a.priority);
    return priority != 0 ? priority : a.id.compareTo(b.id);
  }

  Duration? _remainingCooldown(ProviderCircuitBreaker breaker) {
    final DateTime? until = breaker.openUntil;
    if (until == null) return null;
    final Duration remaining = until.difference(_clock());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _recordFailure(
    ProviderCircuitBreaker breaker,
    CircuitPermit permit,
    PlaybackProviderFailure failure,
  ) {
    if (permit == CircuitPermit.probe &&
        failure.kind == PlaybackProviderFailureKind.cancelled) {
      breaker.releaseProbe();
    } else {
      breaker.recordFailure(failure);
    }
  }

  PlaybackProviderDiagnostic _diagnostic(PlaybackProviderId id) {
    final ProviderCircuitBreaker breaker = _breakers[id]!;
    return PlaybackProviderDiagnostic(
      id: id,
      circuit: breaker.state,
      consecutiveFailures: breaker.consecutiveFailures,
      openUntil: breaker.openUntil,
      lastFailure: breaker.lastFailure,
      probeInFlight: breaker.probeInFlight,
      resolutionCircuit: _resolutionBreakers[id]!.state,
      resolutionConsecutiveFailures:
          _resolutionBreakers[id]!.consecutiveFailures,
      resolutionOpenUntil: _resolutionBreakers[id]!.openUntil,
      resolutionLastFailure: _resolutionBreakers[id]!.lastFailure,
      resolutionProbeInFlight: _resolutionBreakers[id]!.probeInFlight,
    );
  }

  Future<PlaybackProviderResult<T>> _deduplicate<T>(
    String key,
    PlaybackCancellationToken cancellation,
    Future<PlaybackProviderResult<T>> Function(
      PlaybackCancellationToken sharedCancellation,
    )
    create,
  ) => _joinShared<T>(_inFlight, key, cancellation, create);

  Future<PlaybackProviderResult<T>> _joinShared<T>(
    Map<String, _SharedProviderRequest> requests,
    String key,
    PlaybackCancellationToken cancellation,
    Future<PlaybackProviderResult<T>> Function(
      PlaybackCancellationToken sharedCancellation,
    )
    create,
  ) {
    if (cancellation.isCancelled) {
      return Future.value(
        const PlaybackProviderFailed(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        ),
      );
    }
    _SharedProviderRequest? request = requests[key];
    if (request != null && !request.hasLiveWaiters) {
      request.cancelIfOrphaned();
      if (identical(requests[key], request)) requests.remove(key);
      request = null;
    }
    if (request == null) {
      final PlaybackCancellationToken sharedCancellation =
          PlaybackCancellationToken();
      final Future<PlaybackProviderResult<Object?>> future =
          create(sharedCancellation).then<PlaybackProviderResult<Object?>>(
            (PlaybackProviderResult<T> value) =>
                value as PlaybackProviderResult<Object?>,
          );
      late final _SharedProviderRequest createdRequest;
      createdRequest = _SharedProviderRequest(
        future,
        sharedCancellation,
        onOrphaned: () {
          if (identical(requests[key], createdRequest)) requests.remove(key);
        },
      );
      request = createdRequest;
      requests[key] = createdRequest;
      future.whenComplete(() {
        if (identical(requests[key], request)) requests.remove(key);
      });
    }
    return request.wait(cancellation).then((Object result) {
      if (result is _WaiterCancelled) {
        return PlaybackProviderFailed<T>(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        );
      }
      return result as PlaybackProviderResult<T>;
    });
  }
}

final class _SharedProviderRequest {
  _SharedProviderRequest(
    this.future,
    this.cancellation, {
    required this.onOrphaned,
  });

  final Future<PlaybackProviderResult<Object?>> future;
  final PlaybackCancellationToken cancellation;
  final void Function() onOrphaned;
  final Set<PlaybackCancellationToken> _waiterTokens = {};
  int _waiters = 0;
  bool _completed = false;

  bool get hasLiveWaiters => _waiterTokens.any(
    (PlaybackCancellationToken token) => !token.isCancelled,
  );

  void cancelIfOrphaned() {
    if (_waiters == 0 || !hasLiveWaiters) {
      cancellation.cancel();
      onOrphaned();
    }
  }

  Future<Object> wait(PlaybackCancellationToken waiterCancellation) async {
    _waiters++;
    _waiterTokens.add(waiterCancellation);
    unawaited(
      future.then<void>(
        (_) => _completed = true,
        onError: (Object _) {
          _completed = true;
        },
      ),
    );
    try {
      final Object result = await Future.any<Object>([
        future,
        waiterCancellation.whenCancelled.then<Object>(
          (_) => _WaiterCancelled(),
        ),
      ]);
      if (result is _WaiterCancelled) {
        return result;
      }
      return result;
    } finally {
      _waiters--;
      _waiterTokens.remove(waiterCancellation);
      if (_waiters == 0 && !_completed) {
        cancelIfOrphaned();
      }
    }
  }
}

final class _WaiterCancelled {}
