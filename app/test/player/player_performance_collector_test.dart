import 'dart:async';

import 'package:anime_app/application/player/diagnostics/playback_performance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('samples only while enabled and never overlaps native reads', () async {
    final StreamController<void> ticks = StreamController<void>.broadcast();
    final _DelayedSource source = _DelayedSource();
    final PlaybackPerformanceCollector collector = PlaybackPerformanceCollector(
      source,
      ticks: ticks.stream,
    );
    final List<PlaybackPerformanceSample> observed = [];
    final subscription = collector.samples.listen(observed.add);
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(source.calls, 0);

    collector.start();
    expect(source.calls, 1);
    collector.start(); // No second timer or immediate read.
    ticks.add(null);
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(source.calls, 1);

    source.complete();
    await Future<void>.delayed(Duration.zero);
    expect(observed, hasLength(1));
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(source.calls, 2);

    final Future<void> stopping = collector.stop();
    source.complete();
    await stopping;
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(source.calls, 2);
    expect(observed, hasLength(1), reason: 'Late sample after stop is stale');

    await collector.dispose();
    await subscription.cancel();
    await ticks.close();
  });

  test('missing metrics stay missing and a true zero remains zero', () async {
    final StreamController<void> ticks = StreamController<void>.broadcast();
    final _ImmediateSource source = _ImmediateSource();
    final PlaybackPerformanceCollector collector = PlaybackPerformanceCollector(
      source,
      ticks: ticks.stream,
    );
    final Future<PlaybackPerformanceSample> next = collector.samples.first;
    collector.start();
    final PlaybackPerformanceSample sample = await next;
    expect(sample.decodedFps, isNull);
    expect(sample.framesDropped, 0);
    expect(sample.avSyncSeconds, isNull);
    expect(sample.sampleFailed, isFalse);
    await collector.dispose();
    await ticks.close();
  });

  test('source failure is a marked sample and polling can recover', () async {
    final StreamController<void> ticks = StreamController<void>.broadcast();
    final _FailureThenSuccessSource source = _FailureThenSuccessSource();
    final PlaybackPerformanceCollector collector = PlaybackPerformanceCollector(
      source,
      ticks: ticks.stream,
    );
    final List<PlaybackPerformanceSample> observed = [];
    final subscription = collector.samples.listen(observed.add);
    collector.start();
    await Future<void>.delayed(Duration.zero);
    expect(observed.single.sampleFailed, isTrue);
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(observed, hasLength(2));
    expect(observed.last.sampleFailed, isFalse);
    await collector.dispose();
    await subscription.cancel();
    await ticks.close();
  });

  test('interval below one second is refused', () {
    expect(
      () => PlaybackPerformanceCollector(
        _ImmediateSource(),
        interval: const Duration(milliseconds: 500),
      ),
      throwsArgumentError,
    );
  });
}

final class _DelayedSource implements PlaybackPerformanceSource {
  final List<Completer<PlaybackPerformanceSample>> _pending = [];
  int calls = 0;

  @override
  Future<PlaybackPerformanceSample> samplePerformance() {
    calls++;
    final completer = Completer<PlaybackPerformanceSample>();
    _pending.add(completer);
    return completer.future;
  }

  void complete() => _pending
      .removeAt(0)
      .complete(PlaybackPerformanceSample(collectedAt: DateTime.now()));
}

final class _ImmediateSource implements PlaybackPerformanceSource {
  @override
  Future<PlaybackPerformanceSample> samplePerformance() async =>
      PlaybackPerformanceSample(collectedAt: DateTime.now(), framesDropped: 0);
}

final class _FailureThenSuccessSource implements PlaybackPerformanceSource {
  int calls = 0;

  @override
  Future<PlaybackPerformanceSample> samplePerformance() async {
    if (calls++ == 0) throw StateError('transient');
    return PlaybackPerformanceSample(collectedAt: DateTime.now());
  }
}
