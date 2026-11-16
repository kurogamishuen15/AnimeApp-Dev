import 'dart:async';

/// Reserves the single native-player slot until asynchronous cleanup succeeds.
///
/// Concurrent [release] calls share the same Future. If cleanup fails, the
/// lease stays active and a later call retries the original cleanup callback.
final class ActivePlayerLease {
  ActivePlayerLease._();

  static ActivePlayerLease? _active;

  /// Whether an allocated native player still owns the exclusive slot.
  static bool get hasActiveLease => _active != null;

  static ActivePlayerLease acquire() {
    if (_active != null) throw ActivePlayerLeaseInUse();
    final ActivePlayerLease lease = ActivePlayerLease._();
    _active = lease;
    return lease;
  }

  /// Retries cleanup for an active lease whose previous cleanup failed.
  /// Throws if a live owner has not requested cleanup yet.
  static Future<void> retryPendingRelease() {
    final ActivePlayerLease? active = _active;
    if (active == null) return Future<void>.value();
    final Future<void> Function()? cleanup = active._cleanup;
    if (cleanup == null) {
      throw ActivePlayerLeaseInUse();
    }
    return active.release(cleanup);
  }

  Future<void>? _releaseFuture;
  Future<void> Function()? _cleanup;
  bool _released = false;

  Future<void> release(Future<void> Function() cleanup) {
    if (_released) return Future<void>.value();
    _cleanup ??= cleanup;
    final Future<void> Function() cleanupToRun = _cleanup!;
    final Future<void>? current = _releaseFuture;
    if (current != null) return current;

    final Completer<void> completer = Completer<void>();
    final Future<void> future = completer.future;
    _releaseFuture = future;

    () async {
      try {
        // Always retry the original owner's cleanup. Accepting a replacement
        // callback here could release the global slot without disposing the
        // resource that acquired it.
        await cleanupToRun();
        _released = true;
        if (identical(_active, this)) _active = null;
        completer.complete();
      } catch (error, stack) {
        completer.completeError(error, stack);
      } finally {
        if (identical(_releaseFuture, future)) _releaseFuture = null;
      }
    }();

    return future;
  }
}

/// A different live engine still owns the single native-player slot.
final class ActivePlayerLeaseInUse extends StateError {
  ActivePlayerLeaseInUse()
    : super('An active media_kit Player still owns the lease.');
}
