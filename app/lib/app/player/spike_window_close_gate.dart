import 'dart:async';

/// Coordinates GTK close requests with playback cleanup without cancelling it.
final class SpikeWindowCloseGate {
  SpikeWindowCloseGate(
    this._closePlayback,
    this._retryPendingCleanup,
    this._onCleanupFailure, {
    this.closeWatchdog = const Duration(seconds: 15),
    void Function()? onCleanupPending,
  }) : _onCleanupPending = onCleanupPending ?? _ignoreCleanupPending;

  final Future<void> Function() _closePlayback;
  final Future<void> Function() _retryPendingCleanup;
  final void Function() _onCleanupFailure;
  final Duration closeWatchdog;
  final void Function() _onCleanupPending;
  Future<bool>? _cleanup;
  Future<bool>? _pendingRequest;
  bool _closeApproved = false;

  Future<bool> requestClose() {
    if (_closeApproved) return Future<bool>.value(true);
    final Future<bool>? pending = _pendingRequest;
    if (pending != null) return pending;

    final Future<bool> cleanup = _cleanup ??= _close();
    _observeCleanup(cleanup);
    final Future<bool> request = _waitForCleanup(cleanup);
    _pendingRequest = request;
    unawaited(
      request.then<void>(
        (_) => _clearPendingRequest(request),
        onError: (Object _, StackTrace _) => _clearPendingRequest(request),
      ),
    );
    return request;
  }

  Future<bool> _waitForCleanup(Future<bool> cleanup) async {
    try {
      return await cleanup.timeout(closeWatchdog);
    } on TimeoutException {
      try {
        _onCleanupPending();
      } catch (_) {
        // A watchdog notification must never turn an unsafe close into success.
      }
      return false;
    }
  }

  void _observeCleanup(Future<bool> cleanup) {
    unawaited(
      cleanup.then<void>(
        (bool allowClose) {
          if (identical(_cleanup, cleanup)) _cleanup = null;
          if (allowClose) _closeApproved = true;
        },
        onError: (Object _, StackTrace _) {
          if (identical(_cleanup, cleanup)) _cleanup = null;
        },
      ),
    );
  }

  Future<bool> _close() async {
    try {
      await _closePlayback();
      return true;
    } catch (_) {
      try {
        // A module-open failure can still leave a cleanup callback pending.
        // A failed native dispose remains quarantined and must keep the window.
        await _retryPendingCleanup();
        return true;
      } catch (_) {
        try {
          _onCleanupFailure();
        } catch (_) {
          // The OS close decision must remain false even if error UI fails.
        }
        return false;
      }
    }
  }

  void _clearPendingRequest(Future<bool> request) {
    if (identical(_pendingRequest, request)) _pendingRequest = null;
  }

  static void _ignoreCleanupPending() {}
}
