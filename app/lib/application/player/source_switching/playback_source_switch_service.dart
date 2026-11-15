import 'dart:async';

import '../../../domain/player/providers/playback_provider_contract.dart';
import '../../../domain/player/providers/playback_source.dart';
import '../playback_spike_contract.dart';
import '../providers/playback_provider_manager.dart';
import '../spike_player_coordinator.dart';

enum PlaybackSourceSwitchActivity {
  idle,
  resolving,
  switching,
  fallback,
  failed,
}

final class PlaybackSourceSwitchSnapshot {
  const PlaybackSourceSwitchSnapshot({
    this.activity = PlaybackSourceSwitchActivity.idle,
    this.current,
    this.pending,
    this.error,
    this.lastPositionDelta,
    this.failedCandidateCount = 0,
  });

  final PlaybackSourceSwitchActivity activity;
  final ResolvedPlaybackStream? current;
  final ResolvedPlaybackStream? pending;
  final String? error;
  final Duration? lastPositionDelta;
  final int failedCandidateCount;
}

enum PlaybackSourceSwitchAttemptStatus {
  switched,
  busy,
  noAlternative,
  failed,
  superseded,
}

final class PlaybackSourceSwitchAttempt {
  const PlaybackSourceSwitchAttempt({
    required this.status,
    this.selected,
    this.positionDelta,
    this.failedCandidateCount = 0,
  });

  final PlaybackSourceSwitchAttemptStatus status;
  final ResolvedPlaybackStream? selected;
  final Duration? positionDelta;
  final int failedCandidateCount;
}

/// Resolves provider alternatives and asks the existing coordinator to switch.
/// It never owns or calls a native Player.
final class PlaybackSourceSwitchService {
  factory PlaybackSourceSwitchService({
    required PlaybackProviderManager manager,
    required PlaybackEpisode episode,
    required SpikePlayerCoordinator coordinator,
    required ResolvedPlaybackStream initialSource,
  }) => PlaybackSourceSwitchService._(
    manager: manager,
    episode: episode,
    coordinator: coordinator,
    initialSource: initialSource,
  );

  PlaybackSourceSwitchService._({
    required this._manager,
    required this._episode,
    required this._coordinator,
    required ResolvedPlaybackStream initialSource,
  }) : _state = PlaybackSourceSwitchSnapshot(current: initialSource),
       _checkpointUri = _coordinator.state.sourceUri,
       _checkpointPosition = _coordinator.state.position,
       _checkpointPlaying = _coordinator.state.playing;

  final PlaybackProviderManager _manager;
  final PlaybackEpisode _episode;
  final SpikePlayerCoordinator _coordinator;
  final StreamController<PlaybackSourceSwitchSnapshot> _states =
      StreamController<PlaybackSourceSwitchSnapshot>.broadcast();
  PlaybackSourceSwitchSnapshot _state;
  PlaybackCancellationToken? _requestCancellation;
  ResolvedPlaybackStream? _pendingCandidate;
  Uri? _checkpointUri;
  Duration _checkpointPosition;
  bool _checkpointPlaying;
  int _requestGeneration = 0;
  bool _disposed = false;

  PlaybackSourceSwitchSnapshot get state => _state;
  Stream<PlaybackSourceSwitchSnapshot> get states => _states.stream;

  Future<PlaybackSourceSwitchAttempt> switchToNext() async {
    _ensureOpen();
    if (_isBusy) {
      return const PlaybackSourceSwitchAttempt(
        status: PlaybackSourceSwitchAttemptStatus.busy,
      );
    }
    if (_state.current == null || _checkpointUri == null) {
      _publish(
        const PlaybackSourceSwitchSnapshot(
          activity: PlaybackSourceSwitchActivity.failed,
          error: 'There is no active source to switch from.',
        ),
      );
      return const PlaybackSourceSwitchAttempt(
        status: PlaybackSourceSwitchAttemptStatus.failed,
      );
    }
    if (_coordinator.state.sourceUri != null) {
      _checkpointUri = _coordinator.state.sourceUri;
      _checkpointPosition = _coordinator.state.position;
      _checkpointPlaying = _coordinator.state.playing;
    }
    final ResolvedPlaybackStream initialSource = _state.current!;
    final Uri initialUri = _checkpointUri!;
    final Duration referencePosition = _checkpointPosition;
    final bool resumePlayback = _checkpointPlaying;
    final int generation = ++_requestGeneration;
    _requestCancellation?.cancel();
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();
    _requestCancellation = cancellation;
    final Set<String> excluded = <String>{
      if (_state.current case final ResolvedPlaybackStream current)
        _key(current),
      if (_pendingCandidate case final ResolvedPlaybackStream pending)
        _key(pending),
    };
    _publish(
      PlaybackSourceSwitchSnapshot(
        activity: PlaybackSourceSwitchActivity.resolving,
        current: _state.current,
        failedCandidateCount: _state.failedCandidateCount,
      ),
    );

    final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
        await _manager.resolveCandidates(_episode, cancellation: cancellation);
    if (!_isCurrent(generation)) {
      return const PlaybackSourceSwitchAttempt(
        status: PlaybackSourceSwitchAttemptStatus.superseded,
      );
    }
    if (result case PlaybackProviderFailed<List<ResolvedPlaybackStream>>()) {
      _publish(
        PlaybackSourceSwitchSnapshot(
          activity: PlaybackSourceSwitchActivity.failed,
          current: _state.current,
          error: 'Playback source lookup failed.',
        ),
      );
      return const PlaybackSourceSwitchAttempt(
        status: PlaybackSourceSwitchAttemptStatus.failed,
      );
    }
    if (result is! PlaybackProviderSuccess<List<ResolvedPlaybackStream>>) {
      _publish(
        PlaybackSourceSwitchSnapshot(
          activity: PlaybackSourceSwitchActivity.failed,
          current: _state.current,
          error: 'No alternative playback source is available.',
        ),
      );
      return const PlaybackSourceSwitchAttempt(
        status: PlaybackSourceSwitchAttemptStatus.noAlternative,
      );
    }

    final List<ResolvedPlaybackStream> candidates = result.value
        .where((ResolvedPlaybackStream value) => !_isExcluded(value, excluded))
        .toList(growable: false);
    if (candidates.isEmpty) {
      _publish(
        PlaybackSourceSwitchSnapshot(
          current: _state.current,
          error: 'No alternative playback source is available.',
        ),
      );
      return const PlaybackSourceSwitchAttempt(
        status: PlaybackSourceSwitchAttemptStatus.noAlternative,
      );
    }

    int failedCount = 0;
    Duration? lastDelta;
    bool previousSourceRestored = false;
    bool attemptedCandidate = false;
    for (final ResolvedPlaybackStream candidate in candidates) {
      if (!_isCurrent(generation) || cancellation.isCancelled) {
        return const PlaybackSourceSwitchAttempt(
          status: PlaybackSourceSwitchAttemptStatus.superseded,
        );
      }
      _pendingCandidate = candidate;
      attemptedCandidate = true;
      _publish(
        PlaybackSourceSwitchSnapshot(
          activity: failedCount == 0
              ? PlaybackSourceSwitchActivity.switching
              : PlaybackSourceSwitchActivity.fallback,
          current: _state.current,
          pending: candidate,
          failedCandidateCount: failedCount,
        ),
      );
      final PlaybackSourceSwitchResult attempt;
      try {
        attempt = await _coordinator.switchSource(
          candidate.uri,
          referencePosition: referencePosition,
          resumePlayback: resumePlayback,
        );
      } catch (_) {
        failedCount++;
        continue;
      }
      if (!_isCurrent(generation)) {
        return const PlaybackSourceSwitchAttempt(
          status: PlaybackSourceSwitchAttemptStatus.superseded,
        );
      }
      lastDelta = attempt.positionDelta;
      if (attempt.succeeded) {
        _pendingCandidate = null;
        _checkpointUri = candidate.uri;
        _checkpointPosition = attempt.observedPosition ?? referencePosition;
        _checkpointPlaying = resumePlayback;
        _publish(
          PlaybackSourceSwitchSnapshot(
            current: candidate,
            lastPositionDelta: lastDelta,
            failedCandidateCount: failedCount,
          ),
        );
        return PlaybackSourceSwitchAttempt(
          status: PlaybackSourceSwitchAttemptStatus.switched,
          selected: candidate,
          positionDelta: lastDelta,
          failedCandidateCount: failedCount,
        );
      }
      if (attempt.disposition ==
          PlaybackSourceSwitchDisposition.targetAndPreviousFailed) {
        previousSourceRestored = false;
      } else {
        previousSourceRestored = true;
      }
      failedCount++;
    }
    _pendingCandidate = null;
    if (attemptedCandidate && !previousSourceRestored) {
      try {
        final PlaybackSourceSwitchResult restore = await _coordinator
            .switchSource(
              initialUri,
              referencePosition: referencePosition,
              resumePlayback: resumePlayback,
            );
        if (restore.succeeded) {
          _publish(
            PlaybackSourceSwitchSnapshot(
              activity: PlaybackSourceSwitchActivity.failed,
              current: initialSource,
              error: 'Alternatives failed; the previous source was restored.',
              failedCandidateCount: failedCount,
            ),
          );
          return PlaybackSourceSwitchAttempt(
            status: PlaybackSourceSwitchAttemptStatus.failed,
            selected: initialSource,
            positionDelta: restore.positionDelta,
            failedCandidateCount: failedCount,
          );
        }
      } catch (_) {
        // The stable error state below records that no source was restored.
      }
    }
    _publish(
      PlaybackSourceSwitchSnapshot(
        activity: PlaybackSourceSwitchActivity.failed,
        current: previousSourceRestored ? initialSource : null,
        error: previousSourceRestored
            ? 'All playback source alternatives failed; the previous source remains active.'
            : 'All playback source alternatives failed, and the previous source could not be restored.',
        failedCandidateCount: failedCount,
      ),
    );
    return PlaybackSourceSwitchAttempt(
      status: PlaybackSourceSwitchAttemptStatus.failed,
      failedCandidateCount: failedCount,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _requestGeneration++;
    _requestCancellation?.cancel();
    _pendingCandidate = null;
    await _states.close();
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _requestGeneration;

  bool get _isBusy => switch (_state.activity) {
    PlaybackSourceSwitchActivity.resolving ||
    PlaybackSourceSwitchActivity.switching ||
    PlaybackSourceSwitchActivity.fallback => true,
    PlaybackSourceSwitchActivity.idle ||
    PlaybackSourceSwitchActivity.failed => false,
  };

  bool _isExcluded(ResolvedPlaybackStream value, Set<String> excluded) =>
      excluded.contains(_key(value));

  String _key(ResolvedPlaybackStream value) =>
      '${value.providerId.value}:${value.sourceId}:${value.serverId}';

  void _publish(PlaybackSourceSwitchSnapshot snapshot) {
    if (_disposed) return;
    _state = snapshot;
    if (!_states.isClosed) _states.add(snapshot);
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Source switch service is disposed.');
  }
}
