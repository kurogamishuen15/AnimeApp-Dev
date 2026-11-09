import 'dart:async';

import '../../core/result/result.dart';
import 'content_identity.dart';
import 'playback_progress.dart';

enum PlaybackEventKind { playing, paused, seeked, closing, completed }

/// Event-driven policy: caller supplies active playback ticks; no timer/task is
/// owned here. A checkpoint is considered saved only after writer success.
final class CheckpointCoordinator {
  CheckpointCoordinator({
    required this.write,
    DateTime Function()? clock,
    this.interval = const Duration(seconds: 10),
    this.seekThresholdMs = 30000,
  }) : _clock = clock ?? DateTime.now;

  final Future<Result<void>> Function(PlaybackProgress progress) write;
  final DateTime Function() _clock;
  final Duration interval;
  final int seekThresholdMs;
  final Map<ProgressKey, DateTime> _lastConfirmedAt = {};
  final Map<ProgressKey, int> _previousPosition = {};
  Future<void> _writeQueue = Future<void>.value();

  Future<bool> handle({
    required PlaybackEventKind event,
    required ProgressKey key,
    required int positionMs,
    required int? durationMs,
    int revision = 0,
  }) async {
    if (positionMs < 0 ||
        durationMs != null && (durationMs <= 0 || positionMs > durationMs)) {
      return false;
    }
    final now = _clock().toUtc();
    final oldPosition = _previousPosition[key];
    final lastConfirmedAt = _lastConfirmedAt[key];
    final due = switch (event) {
      PlaybackEventKind.paused ||
      PlaybackEventKind.closing ||
      PlaybackEventKind.completed => true,
      PlaybackEventKind.seeked =>
        oldPosition != null &&
            (positionMs - oldPosition).abs() > seekThresholdMs,
      PlaybackEventKind.playing =>
        lastConfirmedAt == null || now.difference(lastConfirmedAt) >= interval,
    };
    _previousPosition[key] = positionMs;
    if (!due) return false;
    final progress = PlaybackProgress(
      key: key,
      positionMs: positionMs,
      durationMs: durationMs,
      updatedAtUtc: now,
      completion: event == PlaybackEventKind.completed
          ? CompletionState.completed
          : CompletionState.inProgress,
      revision: revision,
    );
    final result = Completer<bool>();
    final previous = _writeQueue;
    _writeQueue = () async {
      await previous;
      try {
        result.complete(await _persist(progress, now));
      } on Object {
        result.complete(false);
      }
    }();
    return result.future;
  }

  Future<bool> _persist(PlaybackProgress progress, DateTime savedAt) async {
    final result = await write(progress);
    if (result case Success<void>()) {
      _lastConfirmedAt[progress.key] = savedAt;
      return true;
    }
    return false;
  }
}
