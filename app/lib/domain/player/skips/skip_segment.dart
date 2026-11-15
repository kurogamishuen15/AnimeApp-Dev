import '../providers/playback_source.dart';

enum SkipSegmentKind { opening, ending, recap, filler }

enum SkipSegmentSource { aniskip, curated }

/// A community or curated time range tied to one exact episode identity.
final class SkipSegment {
  SkipSegment({
    required this.episode,
    required this.kind,
    required this.start,
    required this.end,
    required this.source,
    required this.sourceId,
    this.votes,
    this.confirmations,
  }) {
    if (sourceId.trim().isEmpty ||
        start < Duration.zero ||
        end <= start ||
        (votes != null && votes! < 0) ||
        (confirmations != null && confirmations! < 0)) {
      throw ArgumentError('Skip segment is invalid.');
    }
  }

  final PlaybackEpisode episode;
  final SkipSegmentKind kind;
  final Duration start;
  final Duration end;
  final SkipSegmentSource source;
  final String sourceId;
  final int? votes;
  final int? confirmations;

  bool isValidFor(PlaybackEpisode currentEpisode, Duration duration) =>
      episode.requestKey == currentEpisode.requestKey &&
      duration > Duration.zero &&
      start >= Duration.zero &&
      end > start &&
      end <= duration;

  bool contains(Duration position) => position >= start && position < end;

  String get stableKey =>
      '${episode.requestKey}:${kind.name}:${start.inMilliseconds}:'
      '${end.inMilliseconds}:$sourceId';
}
