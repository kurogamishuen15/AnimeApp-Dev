import 'dart:async';

import '../../domain/progress/checkpoint_coordinator.dart';
import '../../domain/progress/content_identity.dart';
import 'playback_spike_contract.dart';
import 'spike_player_coordinator.dart';

/// Records engine-observed progress for one local episode.
final class PlaybackProgressSession {
  PlaybackProgressSession(
    SpikePlayerCoordinator player,
    this._checkpoints,
    this._key,
  ) {
    _subscription = player.states.listen(_observe);
  }

  final CheckpointCoordinator _checkpoints;
  final ProgressKey _key;
  late final StreamSubscription<PlaybackSessionSnapshot> _subscription;
  final Stopwatch _sinceTick = Stopwatch()..start();
  PlaybackSessionSnapshot? _last;
  Future<void>? _closing;

  void _observe(PlaybackSessionSnapshot state) {
    if (state.error != null ||
        state.stopped ||
        state.status == PlaybackSessionStatus.switchingSource) {
      // Keep the last valid position through Stop or a failed source change.
      return;
    }
    if (state.seeking ||
        state.observedPosition <= Duration.zero ||
        state.duration <= Duration.zero ||
        state.observedPosition > state.duration) {
      return;
    }
    final PlaybackSessionSnapshot? previous = _last;
    if (previous == null &&
        !state.playing &&
        state.status != PlaybackSessionStatus.completed) {
      return;
    }

    _last = state;
    if (state.status == PlaybackSessionStatus.completed &&
        previous?.status != PlaybackSessionStatus.completed) {
      unawaited(_save(state, PlaybackEventKind.completed));
    } else if (!state.playing && previous?.playing == true) {
      unawaited(_save(state, PlaybackEventKind.paused));
    } else if (state.playing &&
        (previous == null || _sinceTick.elapsed >= _checkpoints.interval)) {
      _sinceTick.reset();
      unawaited(_save(state, PlaybackEventKind.playing));
    }
  }

  Future<void> close() => _closing ??= _finish();

  Future<void> _finish() async {
    await _subscription.cancel();
    if (_last case final PlaybackSessionSnapshot last) {
      await _save(
        last,
        last.status == PlaybackSessionStatus.completed
            ? PlaybackEventKind.completed
            : PlaybackEventKind.closing,
      );
    }
  }

  Future<void> _save(
    PlaybackSessionSnapshot state,
    PlaybackEventKind event,
  ) async {
    await _checkpoints.handle(
      event: event,
      key: _key,
      positionMs: state.observedPosition.inMilliseconds,
      durationMs: state.duration.inMilliseconds,
    );
  }
}
