import 'dart:async';
import 'dart:collection';

import '../../../domain/player/providers/playback_provider_contract.dart';
import '../../../domain/player/providers/playback_source.dart';
import 'playback_source_cache.dart';
import 'provider_circuit_breaker.dart';

final class PlaybackProviderRegistration {
  const PlaybackProviderRegistration({
    required this.provider,
    this.priority = 0,
    this.enabled = true,
    this.cacheTtl = const Duration(seconds: 30),
    this.version = '1.0.0',
  });

  final PlaybackSourceProvider provider;
  final int priority;
  final bool enabled;
  final Duration cacheTtl;
  final String version;
}

final class PlaybackVideoHostResolverRegistration {
  const PlaybackVideoHostResolverRegistration({
    required this.resolver,
    this.priority = 0,
    this.enabled = true,
    this.version = '1.0.0',
  });

  final PlaybackVideoHostResolver resolver;
  final int priority;
  final bool enabled;
  final String version;
}

final class PlaybackProviderDiagnostic {
  const PlaybackProviderDiagnostic({
    required this.id,
    required this.version,
    required this.circuit,
    required this.consecutiveFailures,
    required this.openUntil,
    required this.lastFailure,
    required this.probeInFlight,
  });

  final PlaybackProviderId id;
  final String version;
  final ProviderCircuitState circuit;
  final int consecutiveFailures;
  final DateTime? openUntil;
  final PlaybackProviderFailureKind? lastFailure;
  final bool probeInFlight;
}

final class PlaybackVideoHostDiagnostic {
  const PlaybackVideoHostDiagnostic({
    required this.hostId,
    required this.circuit,
    required this.consecutiveFailures,
    required this.openUntil,
    required this.lastFailure,
    required this.probeInFlight,
  });

  final String hostId;
  final ProviderCircuitState circuit;
  final int consecutiveFailures;
  final DateTime? openUntil;
  final PlaybackProviderFailureKind? lastFailure;
  final bool probeInFlight;
}

/// Orchestrates providers, fallback and source/server ordering; it never owns
/// or calls the native playback engine.
final class PlaybackProviderManager {
  static const int maxHostCircuitBreakers = 128;

  PlaybackProviderManager({
    required Iterable<PlaybackProviderRegistration> providers,
    Iterable<PlaybackVideoHostResolverRegistration> videoHostResolvers =
        const [],
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
      if (item.cacheTtl < Duration.zero ||
          item.cacheTtl > const Duration(minutes: 5)) {
        throw ArgumentError(
          'Provider source cache TTL must be between 0 and 5 minutes.',
        );
      }
      if (!_isSemanticVersion(item.version)) {
        throw ArgumentError('Provider version must use semantic versioning.');
      }
      _registrations[item.provider.id] = item;
      _breakers[item.provider.id] = ProviderCircuitBreaker(
        clock: clock,
        failureThreshold: circuitFailureThreshold,
        cooldown: circuitCooldown,
      );
    }
    _ordered = List.unmodifiable(ordered);

    final List<PlaybackVideoHostResolverRegistration> orderedResolvers =
        videoHostResolvers
            .where((PlaybackVideoHostResolverRegistration item) => item.enabled)
            .toList()
          ..sort((
            PlaybackVideoHostResolverRegistration a,
            PlaybackVideoHostResolverRegistration b,
          ) {
            final int priority = b.priority.compareTo(a.priority);
            return priority != 0
                ? priority
                : a.resolver.resolverId.compareTo(b.resolver.resolverId);
          });
    final Set<String> resolverIds = {};
    for (final PlaybackVideoHostResolverRegistration item in orderedResolvers) {
      if (item.resolver.resolverId.trim().isEmpty ||
          !resolverIds.add(item.resolver.resolverId) ||
          !_isSemanticVersion(item.version)) {
        throw ArgumentError('Video host resolver IDs must be unique.');
      }
    }
    _videoHostResolvers = List.unmodifiable(orderedResolvers);
  }

  final DateTime Function() _clock;
  final int circuitFailureThreshold;
  final Duration circuitCooldown;
  final Map<PlaybackProviderId, PlaybackProviderRegistration> _registrations =
      {};
  final Map<PlaybackProviderId, ProviderCircuitBreaker> _breakers = {};
  final LinkedHashMap<String, ProviderCircuitBreaker> _hostBreakers =
      LinkedHashMap<String, ProviderCircuitBreaker>();
  final PlaybackSourceCache _sourceCache = PlaybackSourceCache(capacity: 128);
  late final List<PlaybackProviderRegistration> _ordered;
  late final List<PlaybackVideoHostResolverRegistration> _videoHostResolvers;
  final Map<String, _SharedProviderRequest> _inFlight = {};
  final Map<String, _SharedProviderRequest> _providerRequests = {};

  PlaybackSourceProvider? provider(PlaybackProviderId id) =>
      _registrations[id]?.provider;

  List<PlaybackProviderRegistration> get providerRegistrations => _ordered;

  List<PlaybackVideoHostResolverRegistration> get resolverRegistrations =>
      _videoHostResolvers;

  List<PlaybackProviderDiagnostic> get diagnostics => List.unmodifiable([
    for (final PlaybackProviderRegistration item in _ordered)
      _diagnostic(item.provider.id),
  ]);

  List<PlaybackVideoHostDiagnostic> get hostDiagnostics => List.unmodifiable([
    for (final String hostId in (_hostBreakers.keys.toList()..sort()))
      _hostDiagnostic(hostId),
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
    return switch (lastFailure) {
      final PlaybackProviderFailure failure => PlaybackProviderFailed(failure),
      null => const PlaybackProviderEmpty(),
    };
  }

  Future<PlaybackProviderResult<List<ResolvedPlaybackStream>>>
  _resolveCandidates(
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation, {
    required bool stopAfterFirst,
  }) async {
    PlaybackProviderFailure? lastFailure;
    void recordFailure(PlaybackProviderFailure failure) {
      int detail(PlaybackProviderFailure value) {
        if (value.kind == PlaybackProviderFailureKind.rateLimited &&
            value.retryAfter != null) {
          return 10;
        }
        if (value.httpStatus == null) return 0;
        return 1 + (value.stage?.index ?? 0);
      }

      final PlaybackProviderFailure? previous = lastFailure;
      if (previous == null || detail(failure) >= detail(previous)) {
        lastFailure = failure;
      }
    }

    final List<ResolvedPlaybackStream> candidates = [];
    final Map<String, _HostResolutionAttempt> hostAttempts = {};
    for (final PlaybackProviderRegistration registration in _ordered) {
      if (cancellation.isCancelled) {
        _finishHostAttempts(hostAttempts);
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
      final PlaybackProviderResult<List<PlaybackSource>> sourceResult =
          await _findOnlyProviderSources(provider, episode, cancellation);
      if (sourceResult case PlaybackProviderFailed<List<PlaybackSource>>(
        :final failure,
      )) {
        recordFailure(failure);
        continue;
      }
      if (sourceResult is PlaybackProviderEmpty<List<PlaybackSource>> ||
          sourceResult is PlaybackProviderUnsupported<List<PlaybackSource>>) {
        continue;
      }
      if (sourceResult case PlaybackProviderSuccess<List<PlaybackSource>>(
        :final value,
      )) {
        final List<PlaybackSource> sources = [...value]..sort(_compareSource);
        for (final PlaybackSource source in sources) {
          final List<PlaybackServer> servers = [...source.servers]
            ..sort(_compareServer);
          for (final PlaybackServer server in servers) {
            if (cancellation.isCancelled) {
              _finishHostAttempts(hostAttempts);
              return const PlaybackProviderFailed(
                PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
              );
            }
            if (server.expiresAt case final DateTime expiry
                when !expiry.isAfter(_clock())) {
              const PlaybackProviderFailure failure = PlaybackProviderFailure(
                PlaybackProviderFailureKind.expired,
              );
              recordFailure(failure);
              continue;
            }
            final PlaybackVideoHostResolver? resolver = _resolverFor(server);
            if (resolver == null) {
              lastFailure ??= PlaybackProviderFailure(
                server.kind == PlaybackCandidateKind.embed
                    ? PlaybackProviderFailureKind.unsupportedEmbed
                    : PlaybackProviderFailureKind.unsupported,
              );
              continue;
            }
            final String hostKey = server.hostKey;
            final ProviderCircuitBreaker? hostBreaker = _hostBreaker(hostKey);
            if (hostBreaker == null) {
              recordFailure(
                const PlaybackProviderFailure(
                  PlaybackProviderFailureKind.circuitOpen,
                ),
              );
              continue;
            }
            final ProviderCircuitBreaker breaker = hostBreaker;
            _HostResolutionAttempt? attempt = hostAttempts[hostKey];
            if (attempt == null) {
              final CircuitPermit permit = breaker.acquirePermit();
              if (permit == CircuitPermit.deny) {
                recordFailure(
                  PlaybackProviderFailure(
                    PlaybackProviderFailureKind.circuitOpen,
                    retryAfter: _remainingCooldown(breaker),
                  ),
                );
                continue;
              }
              attempt = _HostResolutionAttempt(breaker, permit);
              hostAttempts[hostKey] = attempt;
            }
            if (attempt.permit == CircuitPermit.deny) {
              recordFailure(
                PlaybackProviderFailure(
                  PlaybackProviderFailureKind.circuitOpen,
                  retryAfter: _remainingCooldown(breaker),
                ),
              );
              continue;
            }
            try {
              final PlaybackProviderResult<ResolvedPlaybackStream> result =
                  await resolver.resolve(
                    source,
                    server,
                    cancellation: cancellation,
                  );
              switch (result) {
                case PlaybackProviderSuccess<ResolvedPlaybackStream>(
                  :final value,
                ):
                  if (value.isExpiredAt(_clock())) {
                    const PlaybackProviderFailure failure =
                        PlaybackProviderFailure(
                          PlaybackProviderFailureKind.expired,
                        );
                    attempt.lastFailure = failure;
                    recordFailure(failure);
                    continue;
                  }
                  if (value.providerId != provider.id ||
                      value.sourceId != source.id ||
                      value.serverId != server.id) {
                    final PlaybackProviderFailure failure =
                        const PlaybackProviderFailure(
                          PlaybackProviderFailureKind.invalidResponse,
                        );
                    attempt.lastFailure = failure;
                    recordFailure(failure);
                    continue;
                  }
                  attempt.succeeded = true;
                  candidates.add(value);
                  if (stopAfterFirst) {
                    _finishHostAttempts(hostAttempts);
                    return PlaybackProviderSuccess(
                      List.unmodifiable(candidates),
                    );
                  }
                case PlaybackProviderEmpty<ResolvedPlaybackStream>():
                  break;
                case PlaybackProviderUnsupported<ResolvedPlaybackStream>():
                  attempt.lastFailure ??= const PlaybackProviderFailure(
                    PlaybackProviderFailureKind.unsupported,
                  );
                  lastFailure ??= attempt.lastFailure;
                case PlaybackProviderFailed<ResolvedPlaybackStream>(
                  :final failure,
                ):
                  attempt.lastFailure = failure;
                  recordFailure(failure);
              }
            } catch (_) {
              if (cancellation.isCancelled) {
                _finishHostAttempts(hostAttempts);
                return const PlaybackProviderFailed(
                  PlaybackProviderFailure(
                    PlaybackProviderFailureKind.cancelled,
                  ),
                );
              }
              final PlaybackProviderFailure failure = PlaybackProviderFailure(
                PlaybackProviderFailureKind.unavailable,
              );
              attempt.lastFailure = failure;
              recordFailure(failure);
            }
          }
        }
      }
    }
    _finishHostAttempts(hostAttempts);
    if (candidates.isNotEmpty) {
      return PlaybackProviderSuccess(List.unmodifiable(candidates));
    }
    return switch (lastFailure) {
      final PlaybackProviderFailure failure => PlaybackProviderFailed(failure),
      null => const PlaybackProviderEmpty(),
    };
  }

  PlaybackVideoHostResolver? _resolverFor(SourceCandidate server) {
    for (final PlaybackVideoHostResolverRegistration registration
        in _videoHostResolvers) {
      if (registration.resolver.supports(server)) return registration.resolver;
    }
    return null;
  }

  ProviderCircuitBreaker? _hostBreaker(String hostId) {
    final ProviderCircuitBreaker? existing = _hostBreakers.remove(hostId);
    if (existing != null) {
      _hostBreakers[hostId] = existing;
      return existing;
    }

    if (_hostBreakers.length >= maxHostCircuitBreakers) {
      String? evictable;
      for (final MapEntry<String, ProviderCircuitBreaker> entry
          in _hostBreakers.entries) {
        if (!entry.value.probeInFlight &&
            entry.value.state != ProviderCircuitState.open) {
          evictable = entry.key;
          break;
        }
      }
      if (evictable == null) return null;
      _hostBreakers.remove(evictable);
    }

    final ProviderCircuitBreaker created = ProviderCircuitBreaker(
      clock: _clock,
      failureThreshold: circuitFailureThreshold,
      cooldown: circuitCooldown,
    );
    _hostBreakers[hostId] = created;
    return created;
  }

  void _finishHostAttempts(Map<String, _HostResolutionAttempt> attempts) {
    for (final _HostResolutionAttempt attempt in attempts.values) {
      if (attempt.succeeded) {
        attempt.breaker.recordSuccess();
        continue;
      }
      final PlaybackProviderFailure? failure = attempt.lastFailure;
      if (failure != null) {
        if (failure.countsTowardCircuit) {
          _recordFailure(attempt.breaker, attempt.permit, failure);
        } else {
          if (attempt.permit == CircuitPermit.probe) {
            attempt.breaker.releaseProbe();
          }
          attempt.breaker.recordFailure(failure);
        }
      } else if (attempt.permit == CircuitPermit.probe) {
        // Empty outcomes do not establish host health.
        attempt.breaker.releaseProbe();
      }
    }
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
  ) async {
    final String key = '${provider.id.value}:${episode.requestKey}';
    final List<PlaybackSource>? cached = _sourceCache.read(key, _clock());
    if (cached != null) {
      return PlaybackProviderSuccess<List<PlaybackSource>>(cached);
    }
    final PlaybackProviderResult<List<PlaybackSource>> result =
        await _joinShared<List<PlaybackSource>>(
          _providerRequests,
          key,
          cancellation,
          (PlaybackCancellationToken sharedCancellation) =>
              _executeProviderSources(provider, episode, sharedCancellation),
        );
    if (result case PlaybackProviderSuccess<List<PlaybackSource>>(:final value)
        when value.isNotEmpty) {
      final PlaybackProviderRegistration? registration =
          _registrations[provider.id];
      final DateTime now = _clock();
      DateTime? validUntil;
      for (final PlaybackSource source in value) {
        for (final SourceCandidate candidate in source.servers) {
          final DateTime? expiry = candidate.expiresAt;
          if (expiry != null &&
              (validUntil == null || expiry.isBefore(validUntil))) {
            validUntil = expiry;
          }
        }
      }
      _sourceCache.write(
        key,
        value,
        now: now,
        ttl: registration?.cacheTtl ?? Duration.zero,
        validUntil: validUntil,
      );
    }
    return result;
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
      version: _registrations[id]!.version,
      circuit: breaker.state,
      consecutiveFailures: breaker.consecutiveFailures,
      openUntil: breaker.openUntil,
      lastFailure: breaker.lastFailure,
      probeInFlight: breaker.probeInFlight,
    );
  }

  PlaybackVideoHostDiagnostic _hostDiagnostic(String hostId) {
    final ProviderCircuitBreaker breaker = _hostBreakers[hostId]!;
    return PlaybackVideoHostDiagnostic(
      hostId: hostId,
      circuit: breaker.state,
      consecutiveFailures: breaker.consecutiveFailures,
      openUntil: breaker.openUntil,
      lastFailure: breaker.lastFailure,
      probeInFlight: breaker.probeInFlight,
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

  static final RegExp _semanticVersionPattern = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-((?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)'
    r'(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?'
    r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
  );

  static bool _isSemanticVersion(String version) =>
      _semanticVersionPattern.hasMatch(version.trim());
}

final class _HostResolutionAttempt {
  _HostResolutionAttempt(this.breaker, this.permit);

  final ProviderCircuitBreaker breaker;
  final CircuitPermit permit;
  bool succeeded = false;
  PlaybackProviderFailure? lastFailure;
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
