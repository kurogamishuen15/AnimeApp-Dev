import '../providers/playback_source.dart';
import 'skip_segment.dart';

/// Manual prompts are enabled; automatic seeks stay opt-in.
final class SkipAutomationSettings {
  const SkipAutomationSettings({
    this.showManualPrompts = true,
    this.opening = false,
    this.ending = false,
    this.recap = false,
    this.filler = false,
  });

  final bool showManualPrompts;
  final bool opening;
  final bool ending;
  final bool recap;
  final bool filler;
}

enum FillerClassification { unknown, filler, canon }

/// Filler facts need an explicit trusted source and an exact episode match.
final class EpisodeFillerEvidence {
  EpisodeFillerEvidence({
    required this.episode,
    required this.classification,
    required this.sourceId,
    required this.verified,
  }) {
    if (sourceId.trim().isEmpty) {
      throw ArgumentError.value(sourceId, 'sourceId');
    }
  }

  final PlaybackEpisode episode;
  final FillerClassification classification;
  final String sourceId;
  final bool verified;
}

final class SkipAutomationPolicy {
  const SkipAutomationPolicy();

  bool allows({
    required SkipAutomationSettings settings,
    required SkipSegment segment,
    required PlaybackEpisode episode,
    required Duration duration,
    EpisodeFillerEvidence? fillerEvidence,
  }) {
    if (!segment.isValidFor(episode, duration)) return false;
    return switch (segment.kind) {
      SkipSegmentKind.opening => settings.opening,
      SkipSegmentKind.ending => settings.ending,
      SkipSegmentKind.recap =>
        settings.recap && segment.source == SkipSegmentSource.curated,
      SkipSegmentKind.filler =>
        settings.filler &&
            segment.source == SkipSegmentSource.curated &&
            fillerEvidence != null &&
            fillerEvidence.episode.requestKey == episode.requestKey &&
            fillerEvidence.classification == FillerClassification.filler &&
            fillerEvidence.verified,
    };
  }
}
