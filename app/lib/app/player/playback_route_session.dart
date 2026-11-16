import 'dart:async';

import 'package:flutter/widgets.dart';

/// The closeable player session owned by the playback navigation route.
///
/// Keeping the route contract small lets tests control close completion without
/// constructing a second native player.
abstract interface class PlaybackRouteSession {
  Widget build();

  Future<void> close();
}

/// Cooperative cancellation request for a player startup operation.
///
/// Requesting cancellation never interrupts a native Future or releases its
/// lease. The startup owner must observe the request at safe points, finish
/// cleanup, and only then complete its loader Future.
final class PlaybackRouteOpenCancellation {
  bool _requested = false;

  bool get isRequested => _requested;

  void request() => _requested = true;

  void throwIfRequested() {
    if (_requested) throw const PlaybackRouteOpenCancelled();
  }
}

final class PlaybackRouteOpenCancelled implements Exception {
  const PlaybackRouteOpenCancelled();
}

/// Startup could not begin because another native player still owns the slot.
///
/// This UI-facing error keeps the route independent from the data-layer lease
/// implementation while allowing the caller to return safely to the catalog.
final class PlaybackRoutePlayerBusy extends StateError {
  PlaybackRoutePlayerBusy()
    : super('Another native player still owns the playback slot.');
}

/// A close attempt failed and reports whether the native player is retained.
final class PlaybackRouteCleanupFailure implements Exception {
  const PlaybackRouteCleanupFailure({
    required this.cause,
    required this.nativePlayerStillOwned,
    required this.nonNativeCleanupFailed,
  });

  final Object cause;
  final bool nativePlayerStillOwned;
  final bool nonNativeCleanupFailed;
}
