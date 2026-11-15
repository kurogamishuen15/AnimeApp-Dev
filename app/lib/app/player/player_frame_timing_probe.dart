import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in Flutter frame timings. These are UI/raster timings, not video FPS.
final class PlayerFrameTimingProbe {
  PlayerFrameTimingProbe({this.interval = const Duration(seconds: 10)}) {
    SchedulerBinding.instance.addTimingsCallback(_record);
    _timer = Timer.periodic(interval, (_) => _flush());
  }

  final Duration interval;
  late final Timer _timer;
  int _frames = 0;
  int _over16ms = 0;
  int _maxBuildUs = 0;
  int _maxRasterUs = 0;

  void _record(List<FrameTiming> timings) {
    for (final FrameTiming timing in timings) {
      _frames++;
      final int build = timing.buildDuration.inMicroseconds;
      final int raster = timing.rasterDuration.inMicroseconds;
      if (build + raster > 16667) _over16ms++;
      if (build > _maxBuildUs) _maxBuildUs = build;
      if (raster > _maxRasterUs) _maxRasterUs = raster;
    }
  }

  void _flush() {
    debugPrint(
      'KONGROO_FLUTTER_FRAMES interval_ms=${interval.inMilliseconds} '
      'frames=$_frames build_plus_raster_over_16ms=$_over16ms '
      'max_build_us=$_maxBuildUs max_raster_us=$_maxRasterUs',
    );
    _frames = 0;
    _over16ms = 0;
    _maxBuildUs = 0;
    _maxRasterUs = 0;
  }

  void dispose() {
    _timer.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_record);
  }
}
