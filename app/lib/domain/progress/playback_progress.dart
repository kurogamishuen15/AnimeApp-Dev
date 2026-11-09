import 'content_identity.dart';

enum CompletionState { inProgress, completed }

/// Position and duration are integer milliseconds; updatedAtUtc is the local
/// persistence instant and is not a cross-device ordering authority.
final class PlaybackProgress {
  const PlaybackProgress({
    required this.key,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAtUtc,
    this.completion = CompletionState.inProgress,
    this.revision = 0,
  });
  final ProgressKey key;
  final int positionMs;
  final int? durationMs;
  final DateTime updatedAtUtc;
  final CompletionState completion;
  final int revision;

  String? validate() {
    if (key.contentId.value.isEmpty || key.episodeId.value.isEmpty) {
      return 'Progress identity is empty.';
    }
    if (positionMs < 0 || positionMs > 0x7fffffffffffffff) {
      return 'Position is invalid.';
    }
    if (durationMs != null && (durationMs! <= 0 || positionMs > durationMs!)) {
      return 'Duration is invalid.';
    }
    if (!updatedAtUtc.isUtc) return 'Timestamp must be UTC.';
    if (revision < 0) return 'Revision is invalid.';
    return null;
  }

  int get resumePositionMs => validate() == null ? positionMs : 0;
}
