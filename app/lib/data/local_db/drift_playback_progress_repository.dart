import 'package:drift/drift.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/progress/content_identity.dart';
import '../../domain/progress/playback_progress.dart';
import '../../domain/progress/playback_progress_repository.dart';
import 'app_database.dart';

final class DriftPlaybackProgressRepository
    implements PlaybackProgressRepository {
  const DriftPlaybackProgressRepository(this.database);
  final AppDatabase database;

  @override
  Future<Result<void>> upsert(PlaybackProgress progress) async {
    final invalid = progress.validate();
    if (invalid != null) return Failure(ValidationAppError(invalid));
    try {
      await database
          .into(database.playbackProgressEntries)
          .insertOnConflictUpdate(
            PlaybackProgressEntriesCompanion.insert(
              contentId: progress.key.contentId.value,
              episodeId: progress.key.episodeId.value,
              positionMs: progress.positionMs,
              durationMs: Value(progress.durationMs),
              updatedAtUtc: progress.updatedAtUtc,
              completion: progress.completion.name,
              revision: Value(progress.revision),
            ),
          );
      return const Success(null);
    } on Object {
      return const Failure(
        StorageError('Could not persist playback progress.'),
      );
    }
  }

  @override
  Future<Result<PlaybackProgress?>> get(ProgressKey identity) async {
    try {
      final row =
          await (database.select(database.playbackProgressEntries)..where(
                (t) =>
                    t.contentId.equals(identity.contentId.value) &
                    t.episodeId.equals(identity.episodeId.value),
              ))
              .getSingleOrNull();
      if (row == null) return const Success(null);
      final state = CompletionState.values
          .where((v) => v.name == row.completion)
          .firstOrNull;
      if (state == null) {
        return const Failure(StorageError('Stored progress is corrupt.'));
      }
      final value = PlaybackProgress(
        key: ProgressKey(
          contentId: ContentId(row.contentId),
          episodeId: EpisodeId(row.episodeId),
        ),
        positionMs: row.positionMs,
        durationMs: row.durationMs,
        updatedAtUtc: row.updatedAtUtc.toUtc(),
        completion: state,
        revision: row.revision,
      );
      if (value.validate() != null) {
        return const Failure(StorageError('Stored progress is corrupt.'));
      }
      return Success(value);
    } on Object {
      return const Failure(StorageError('Could not read playback progress.'));
    }
  }

  @override
  Future<Result<List<PlaybackProgress>>> list(ContentIdFilter filter) async {
    try {
      final query = database.select(database.playbackProgressEntries);
      if (filter.value != null) {
        query.where((t) => t.contentId.equals(filter.value!));
      }
      final rows = await query.get();
      final results = <PlaybackProgress>[];
      for (final row in rows) {
        final state = CompletionState.values
            .where((v) => v.name == row.completion)
            .firstOrNull;
        if (state == null) {
          return const Failure(StorageError('Stored progress is corrupt.'));
        }
        final item = PlaybackProgress(
          key: ProgressKey(
            contentId: ContentId(row.contentId),
            episodeId: EpisodeId(row.episodeId),
          ),
          positionMs: row.positionMs,
          durationMs: row.durationMs,
          updatedAtUtc: row.updatedAtUtc.toUtc(),
          completion: state,
          revision: row.revision,
        );
        if (item.validate() != null) {
          return const Failure(StorageError('Stored progress is corrupt.'));
        }
        results.add(item);
      }
      return Success(List.unmodifiable(results));
    } on Object {
      return const Failure(StorageError('Could not list playback progress.'));
    }
  }

  @override
  Future<Result<void>> delete(ProgressKey key) async {
    try {
      await (database.delete(database.playbackProgressEntries)..where(
            (t) =>
                t.contentId.equals(key.contentId.value) &
                t.episodeId.equals(key.episodeId.value),
          ))
          .go();
      return const Success(null);
    } on Object {
      return const Failure(StorageError('Could not delete playback progress.'));
    }
  }
}
