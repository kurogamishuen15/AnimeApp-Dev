import 'dart:async';

/// A single, low cost observation of the active native player. Null means the
/// property was unavailable; zero is a measured value. `decodedFps` is mpv's
/// estimated video filter output rate, not compositor/display FPS.
final class PlaybackPerformanceSample {
  const PlaybackPerformanceSample({
    required this.collectedAt,
    this.sampleFailed = false,
    this.nominalFps,
    this.decodedFps,
    this.positionEventsPerSecond,
    this.framesDropped,
    this.decoderFramesDropped,
    this.avSyncSeconds,
    this.totalAvSyncChangeSeconds,
    this.cacheSeconds,
    this.hardwareDecoder,
    this.videoCodec,
    this.audioCodec,
    this.videoOutput,
    this.audioOutput,
    this.videoWidth,
    this.videoHeight,
    this.pixelFormat,
    this.audioChannels,
    this.audioSampleRate,
    this.videoBitrate,
    this.audioBitrate,
    this.rssBytes,
  });

  final DateTime collectedAt;
  final bool sampleFailed;
  final double? nominalFps;
  final double? decodedFps;

  /// Rate of native position notifications received by the engine, not UI FPS.
  final double? positionEventsPerSecond;
  final int? framesDropped;
  final int? decoderFramesDropped;
  final double? avSyncSeconds;
  final double? totalAvSyncChangeSeconds;
  final double? cacheSeconds;
  final String? hardwareDecoder;
  final String? videoCodec;
  final String? audioCodec;
  final String? videoOutput;
  final String? audioOutput;
  final int? videoWidth;
  final int? videoHeight;
  final String? pixelFormat;
  final String? audioChannels;
  final int? audioSampleRate;
  final double? videoBitrate;
  final double? audioBitrate;
  final int? rssBytes;
}

abstract interface class PlaybackPerformanceSource {
  Future<PlaybackPerformanceSample> samplePerformance();
}

/// Starts polling only while explicitly enabled. Samples never overlap and a
/// late completion after stop is discarded. stop/dispose wait for an in-flight
/// native read; a timer cannot cancel a native call already in progress.
final class PlaybackPerformanceCollector {
  PlaybackPerformanceCollector(
    this.source, {
    this.interval = const Duration(seconds: 1),
    this.ticks,
  }) {
    if (interval < const Duration(seconds: 1)) {
      throw ArgumentError.value(interval, 'interval', 'Must be at least 1 s');
    }
  }

  final PlaybackPerformanceSource source;
  final Duration interval;

  /// Test hook; production uses the fixed periodic interval.
  final Stream<void>? ticks;
  final StreamController<PlaybackPerformanceSample> _samples =
      StreamController<PlaybackPerformanceSample>.broadcast();
  // This subscription is cancelled in stop/dispose.
  // ignore: cancel_subscriptions
  StreamSubscription<void>? _subscription;
  Future<void>? _inFlight;
  int _generation = 0;
  bool _active = false;
  bool _disposed = false;

  Stream<PlaybackPerformanceSample> get samples => _samples.stream;
  bool get active => _active;

  void start() {
    if (_disposed) throw StateError('Performance collector is disposed.');
    if (_active) return;
    _active = true;
    final int generation = ++_generation;
    _subscription = (ticks ?? Stream<void>.periodic(interval, (_) {})).listen((
      _,
    ) {
      _poll(generation);
    });
    _poll(generation);
  }

  void _poll(int generation) {
    if (!_active || generation != _generation || _inFlight != null) return;
    final Future<void> operation = _collect(generation);
    _inFlight = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_inFlight, operation)) _inFlight = null;
      }),
    );
  }

  Future<void> _collect(int generation) async {
    PlaybackPerformanceSample sample;
    try {
      sample = await source.samplePerformance();
    } catch (_) {
      sample = PlaybackPerformanceSample(
        collectedAt: DateTime.now(),
        sampleFailed: true,
      );
    }
    if (_active && generation == _generation && !_samples.isClosed) {
      _samples.add(sample);
    }
  }

  Future<void> stop() async {
    _active = false;
    _generation++;
    final StreamSubscription<void>? subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await _inFlight;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _samples.close();
  }
}
