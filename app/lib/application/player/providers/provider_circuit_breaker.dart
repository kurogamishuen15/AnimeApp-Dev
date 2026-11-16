import '../../../domain/player/providers/playback_provider_contract.dart';

enum ProviderCircuitState { closed, open, halfOpen }

enum CircuitPermit { allow, probe, deny }

/// Resource-scoped 3 failures / 60 seconds breaker with one half-open probe.
final class ProviderCircuitBreaker {
  ProviderCircuitBreaker({
    required this._clock,
    this.failureThreshold = 3,
    this.cooldown = const Duration(seconds: 60),
  }) {
    if (failureThreshold < 1 || cooldown <= Duration.zero) {
      throw ArgumentError('Circuit-breaker policy is invalid.');
    }
  }

  final DateTime Function() _clock;
  final int failureThreshold;
  final Duration cooldown;
  int _consecutiveFailures = 0;
  DateTime? _openUntil;
  bool _probeInFlight = false;
  PlaybackProviderFailureKind? _lastFailure;

  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get openUntil => _openUntil;
  PlaybackProviderFailureKind? get lastFailure => _lastFailure;
  bool get probeInFlight => _probeInFlight;

  ProviderCircuitState get state {
    final DateTime? until = _openUntil;
    if (until == null) return ProviderCircuitState.closed;
    if (_clock().isBefore(until)) return ProviderCircuitState.open;
    return ProviderCircuitState.halfOpen;
  }

  CircuitPermit acquirePermit() {
    final DateTime? until = _openUntil;
    if (until == null) return CircuitPermit.allow;
    if (_clock().isBefore(until)) return CircuitPermit.deny;
    if (_probeInFlight) return CircuitPermit.deny;
    _probeInFlight = true;
    return CircuitPermit.probe;
  }

  void recordSuccess() {
    _consecutiveFailures = 0;
    _openUntil = null;
    _probeInFlight = false;
    _lastFailure = null;
  }

  void recordFailure(PlaybackProviderFailure failure) {
    _lastFailure = failure.kind;
    if (failure.kind == PlaybackProviderFailureKind.cancelled) {
      releaseProbe();
      return;
    }
    if (_probeInFlight) {
      if (!failure.kind.countsTowardCircuit) {
        // A permanent/non-transient response (for example 403 or unsupported)
        // ends the probe without imposing another transport cooldown.
        releaseProbe();
        return;
      }
      _openForCooldown();
      return;
    }
    if (!failure.kind.countsTowardCircuit) return;
    _consecutiveFailures++;
    if (_consecutiveFailures >= failureThreshold) _openForCooldown();
  }

  /// A canceled half-open probe does not prove health or failure; allow a
  /// later caller to perform the probe without consuming another 60 seconds.
  void releaseProbe() {
    if (_probeInFlight) _probeInFlight = false;
  }

  void _openForCooldown() {
    _consecutiveFailures = failureThreshold;
    _openUntil = _clock().add(cooldown);
    _probeInFlight = false;
  }
}
