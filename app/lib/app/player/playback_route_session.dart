import 'package:flutter/widgets.dart';

/// The closeable player session owned by the playback navigation route.
///
/// Keeping the route contract small lets tests control close completion without
/// constructing a second native player.
abstract interface class PlaybackRouteSession {
  Widget build();

  Future<void> close();
}
