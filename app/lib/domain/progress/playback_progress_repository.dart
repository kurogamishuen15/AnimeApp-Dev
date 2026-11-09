import '../../core/result/result.dart';
import 'content_identity.dart';
import 'playback_progress.dart';

abstract interface class PlaybackProgressRepository {
  Future<Result<void>> upsert(PlaybackProgress progress);
  Future<Result<PlaybackProgress?>> get(ProgressKey key);
  Future<Result<List<PlaybackProgress>>> list(ContentIdFilter filter);
  Future<Result<void>> delete(ProgressKey key);
}

final class ContentIdFilter {
  const ContentIdFilter(this.value);
  final String? value;
}
