import 'dart:async';

import '../../../domain/player/providers/playback_source.dart';
import '../../../domain/player/skips/skip_segment.dart';
import '../../../domain/player/skips/skip_segment_catalog.dart';
import '../playback_spike_contract.dart';
import '../spike_player_coordinator.dart';

final class SkipSegmentServiceSnapshot {
  const SkipSegmentServiceSnapshot({
    this.loading = false,
    this.unavailable = false,
    this.skipping = false,
    this.segments = const [],
    this.activeSegment,
    this.error,
    this.lastSkipConfirmed = false,
  });

  final bool loading;
  final bool unavailable;
  final bool skipping;
  final List<SkipSegment> segments;
  final SkipSegment? activeSegment;
  final String? error;
  final bool lastSkipConfirmed;
}

/// Application bridge between AniSkip/domain segments and the serialized
/// coordinator. It owns neither network clients nor the media engine.
final class SkipSegmentService {
  SkipSegmentService({
    required this.episode,
    required this.coordinator,
    required this.catalog,
    this.malAnimeId,
  }) {
    _playbackSubscription = coordinator.states.listen(_onPlayback);
  }

  final PlaybackEpisode episode;
  final SpikePlayerCoordinator coordinator;
  final SkipSegmentCatalog catalog;
  final MyAnimeListAnimeId? malAnimeId;
  final StreamController<SkipSegmentServiceSnapshot> _states =
      StreamController<SkipSegmentServiceSnapshot>.broadcast();
  final Set<String> _consumed = {};
  late final StreamSubscription<PlaybackSessionSnapshot> _playbackSubscription;
  SkipSegmentServiceSnapshot _state = const SkipSegmentServiceSnapshot();
  int _sourceGeneration = -1;
  bool _disposed = false;

  SkipSegmentServiceSnapshot get state => _state;
  Stream<SkipSegmentServiceSnapshot> get states => _states.stream;

  Future<void> load() async {
    _ensureOpen();
    if (malAnimeId == null) {
      _publish(
        const SkipSegmentServiceSnapshot(
          unavailable: true,
          error: 'A verified MyAnimeList ID is required for skip lookup.',
        ),
      );
      return;
    }
    _publish(const SkipSegmentServiceSnapshot(loading: true));
    try {
      final SkipCatalogResult result = await catalog.lookup(
        episode: episode,
        malAnimeId: malAnimeId!,
      );
      if (_disposed) return;
      switch (result) {
        case SkipCatalogSuccess(:final segments):
          final List<SkipSegment> matching = segments
              .where(
                (SkipSegment segment) =>
                    segment.episode.requestKey == episode.requestKey,
              )
              .toList(growable: false);
          _publish(SkipSegmentServiceSnapshot(segments: matching));
          _refreshActive(coordinator.state);
        case SkipCatalogUnavailable(:final reason):
          _publish(
            SkipSegmentServiceSnapshot(unavailable: true, error: reason),
          );
        case SkipCatalogFailure(:final kind):
          _publish(
            SkipSegmentServiceSnapshot(
              error: 'Skip lookup failed: ${kind.name}.',
            ),
          );
      }
    } on Object {
      if (!_disposed) {
        _publish(
          const SkipSegmentServiceSnapshot(error: 'Skip lookup failed.'),
        );
      }
    }
  }

  Future<bool> skipCurrent() async {
    _ensureOpen();
    final SkipSegment? segment = _currentSegment(coordinator.state);
    final PlaybackSessionStatus status = coordinator.state.status;
    if (segment == null ||
        _state.skipping ||
        status == PlaybackSessionStatus.stopped ||
        status == PlaybackSessionStatus.switchingSource ||
        status == PlaybackSessionStatus.closing ||
        status == PlaybackSessionStatus.disposed) {
      return false;
    }
    _publish(
      SkipSegmentServiceSnapshot(
        segments: _state.segments,
        activeSegment: segment,
        skipping: true,
      ),
    );
    final int generation = coordinator.state.sourceGeneration;
    final Completer<Duration> observedResult = Completer<Duration>();
    void acceptObserved(PlaybackSessionSnapshot snapshot) {
      if (!observedResult.isCompleted &&
          snapshot.sourceGeneration == generation &&
          (snapshot.observedPosition - segment.end).abs() <=
              const Duration(seconds: 2)) {
        observedResult.complete(snapshot.observedPosition);
      }
    }

    final StreamSubscription<PlaybackSessionSnapshot> confirmation = coordinator
        .states
        .listen(acceptObserved);
    try {
      await coordinator.seek(segment.end, generation: generation);
      acceptObserved(coordinator.state);
      final Duration observed = await observedResult.future.timeout(
        const Duration(seconds: 12),
      );
      final bool confirmed =
          (observed - segment.end).abs() <= const Duration(seconds: 2);
      if (confirmed) _consumed.add(segment.stableKey);
      _publish(
        SkipSegmentServiceSnapshot(
          segments: _state.segments,
          activeSegment: _currentSegment(coordinator.state),
          lastSkipConfirmed: confirmed,
          error: confirmed ? null : 'Seek outcome was not confirmed.',
        ),
      );
      return confirmed;
    } on TimeoutException {
      _publish(
        SkipSegmentServiceSnapshot(
          segments: _state.segments,
          error: 'Seek outcome was not observed before the watchdog expired.',
        ),
      );
      return false;
    } on Object {
      _publish(
        SkipSegmentServiceSnapshot(
          segments: _state.segments,
          error: 'Could not seek to the end of this segment.',
        ),
      );
      return false;
    } finally {
      await confirmation.cancel();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _playbackSubscription.cancel();
    await _states.close();
  }

  void _onPlayback(PlaybackSessionSnapshot snapshot) {
    if (_disposed) return;
    if (snapshot.sourceGeneration != _sourceGeneration) {
      _sourceGeneration = snapshot.sourceGeneration;
      _consumed.clear();
    }
    _refreshActive(snapshot);
  }

  void _refreshActive(PlaybackSessionSnapshot snapshot) {
    if (_state.segments.isEmpty) return;
    final SkipSegment? active = _currentSegment(snapshot);
    if (active?.stableKey != _state.activeSegment?.stableKey ||
        _state.lastSkipConfirmed) {
      _publish(
        SkipSegmentServiceSnapshot(
          segments: _state.segments,
          activeSegment: active,
        ),
      );
    }
  }

  SkipSegment? _currentSegment(PlaybackSessionSnapshot snapshot) {
    if (snapshot.duration <= Duration.zero ||
        snapshot.status == PlaybackSessionStatus.stopped ||
        snapshot.status == PlaybackSessionStatus.switchingSource ||
        snapshot.status == PlaybackSessionStatus.closing ||
        snapshot.status == PlaybackSessionStatus.disposed) {
      return null;
    }
    for (final SkipSegment segment in _state.segments) {
      if (segment.isValidFor(episode, snapshot.duration) &&
          segment.contains(snapshot.position) &&
          !_consumed.contains(segment.stableKey)) {
        return segment;
      }
    }
    return null;
  }

  void _publish(SkipSegmentServiceSnapshot snapshot) {
    if (_disposed) return;
    _state = snapshot;
    if (!_states.isClosed) _states.add(snapshot);
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Skip segment service is disposed.');
  }
}
