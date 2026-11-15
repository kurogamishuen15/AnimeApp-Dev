import 'dart:async';

import '../../../domain/player/skips/skip_automation_policy.dart';
import '../../../domain/player/skips/skip_segment.dart';
import '../playback_spike_contract.dart';
import '../spike_player_coordinator.dart';
import 'skip_segment_service.dart';

/// Opt-in automatic skip evaluator. It never invents a segment and only seeks
/// through the same coordinator used by manual playback controls.
final class AutomaticSkipController {
  AutomaticSkipController({
    required this.coordinator,
    required this.segments,
    required this.settings,
    this.fillerEvidence,
    this.policy = const SkipAutomationPolicy(),
  }) {
    _playbackSubscription = coordinator.states.listen(_evaluate);
    _segmentsSubscription = segments.states.listen(
      (_) => _evaluate(coordinator.state),
    );
  }

  final SpikePlayerCoordinator coordinator;
  final SkipSegmentService segments;
  final SkipAutomationPolicy policy;
  EpisodeFillerEvidence? fillerEvidence;
  SkipAutomationSettings settings;
  late final StreamSubscription<PlaybackSessionSnapshot> _playbackSubscription;
  late final StreamSubscription<SkipSegmentServiceSnapshot>
  _segmentsSubscription;
  final Set<String> _consumed = {};
  final Set<String> _suppressedAfterManualSeek = {};
  int _sourceGeneration = -1;
  bool _automaticSeekInFlight = false;
  bool _disposed = false;

  void update({
    required SkipAutomationSettings settings,
    EpisodeFillerEvidence? fillerEvidence,
  }) {
    this.settings = settings;
    this.fillerEvidence = fillerEvidence;
    _evaluate(coordinator.state);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _playbackSubscription.cancel();
    await _segmentsSubscription.cancel();
  }

  void _evaluate(PlaybackSessionSnapshot snapshot) {
    if (_disposed) return;
    if (_sourceGeneration != snapshot.sourceGeneration) {
      _sourceGeneration = snapshot.sourceGeneration;
      _consumed.clear();
      _suppressedAfterManualSeek.clear();
    }
    final List<SkipSegment> candidates = segments.state.segments;
    if (snapshot.seeking && !_automaticSeekInFlight) {
      for (final SkipSegment segment in candidates) {
        if (segment.isValidFor(segments.episode, snapshot.duration) &&
            segment.contains(snapshot.position)) {
          _suppressedAfterManualSeek.add(segment.stableKey);
        }
      }
    }
    _suppressedAfterManualSeek.removeWhere((String key) {
      final SkipSegment? segment = candidates
          .where((SkipSegment value) => value.stableKey == key)
          .firstOrNull;
      return segment == null || !segment.contains(snapshot.position);
    });
    if (!identical(snapshot, coordinator.state) ||
        snapshot.status != PlaybackSessionStatus.playing ||
        !snapshot.playing ||
        snapshot.seeking ||
        snapshot.duration <= Duration.zero ||
        _automaticSeekInFlight) {
      return;
    }
    for (final SkipSegment segment in candidates) {
      if (!segment.contains(snapshot.position) ||
          !policy.allows(
            settings: settings,
            segment: segment,
            episode: segments.episode,
            duration: snapshot.duration,
            fillerEvidence: fillerEvidence,
          )) {
        continue;
      }
      final String key = '${snapshot.sourceGeneration}:${segment.stableKey}';
      if (_consumed.contains(key) ||
          _suppressedAfterManualSeek.contains(segment.stableKey)) {
        return;
      }
      _consumed.add(key);
      unawaited(_perform(segment, snapshot.sourceGeneration));
      return;
    }
  }

  Future<void> _perform(SkipSegment segment, int generation) async {
    _automaticSeekInFlight = true;
    try {
      await coordinator.seek(segment.end, generation: generation);
    } on Object {
      // A failed seek is consumed for this source generation to avoid a loop.
    } finally {
      _automaticSeekInFlight = false;
    }
  }
}
