import 'dart:async';

import 'playback_source.dart';

enum PlaybackProviderCapability {
  episodeSources,
  sourceAlternatives,
  resolveServer,
}

enum PlaybackProviderFailureKind {
  unavailable,
  network,
  timeout,
  rateLimited,
  invalidResponse,
  unauthorized,
  unsupported,
  cancelled,
  circuitOpen,
}

extension PlaybackProviderFailureKindPolicy on PlaybackProviderFailureKind {
  /// Transient provider/service failures count toward the 3/60 breaker.
  bool get countsTowardCircuit => switch (this) {
    PlaybackProviderFailureKind.unavailable ||
    PlaybackProviderFailureKind.network ||
    PlaybackProviderFailureKind.timeout ||
    PlaybackProviderFailureKind.rateLimited => true,
    PlaybackProviderFailureKind.invalidResponse ||
    PlaybackProviderFailureKind.unauthorized ||
    PlaybackProviderFailureKind.unsupported ||
    PlaybackProviderFailureKind.cancelled ||
    PlaybackProviderFailureKind.circuitOpen => false,
  };
}

final class PlaybackProviderFailure {
  const PlaybackProviderFailure(this.kind, {this.retryAfter});

  final PlaybackProviderFailureKind kind;
  final Duration? retryAfter;
}

sealed class PlaybackProviderResult<T> {
  const PlaybackProviderResult();
}

final class PlaybackProviderSuccess<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderSuccess(this.value);
  final T value;
}

final class PlaybackProviderEmpty<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderEmpty();
}

final class PlaybackProviderUnsupported<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderUnsupported(this.capability);
  final PlaybackProviderCapability capability;
}

final class PlaybackProviderFailed<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderFailed(this.failure);
  final PlaybackProviderFailure failure;
}

/// Cooperative cancellation. Providers must check it before expensive work.
final class PlaybackCancellationToken {
  bool _cancelled = false;
  final Completer<void> _cancelledSignal = Completer<void>();
  final Set<void Function()> _cancelListeners = {};

  bool get isCancelled => _cancelled;
  Future<void> get whenCancelled => _cancelledSignal.future;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancelledSignal.complete();
    final List<void Function()> listeners = List.of(_cancelListeners);
    _cancelListeners.clear();
    for (final void Function() listener in listeners) {
      try {
        listener();
      } on Object {
        // Cancellation must reach remaining listeners even when one callback
        // is faulty; callers observe cancellation through [whenCancelled].
      }
    }
  }

  /// Registers a one-shot callback and returns an unregister function.
  /// Registering after cancellation invokes the callback immediately.
  void Function() addCancelListener(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _cancelListeners.add(listener);
    return () => _cancelListeners.remove(listener);
  }
}

abstract interface class PlaybackSourceProvider {
  PlaybackProviderId get id;
  Set<PlaybackProviderCapability> get capabilities;

  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  });

  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolveServer(
    PlaybackSource source,
    PlaybackServer server, {
    required PlaybackCancellationToken cancellation,
  });
}
