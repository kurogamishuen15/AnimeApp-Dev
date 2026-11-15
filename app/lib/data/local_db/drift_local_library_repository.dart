import 'package:drift/drift.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_id.dart';
import '../../domain/catalog/library_entry.dart';
import '../../domain/catalog/library_repository.dart';
import 'app_database.dart';

final class DriftLocalLibraryRepository implements LocalLibraryRepository {
  DriftLocalLibraryRepository({
    required this.database,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final DateTime Function() _clock;

  @override
  Future<Result<List<LibraryEntry>>> list() async {
    try {
      final List<LocalLibraryEntry> rows = await (database.select(
        database.localLibraryEntries,
      )..orderBy([(table) => OrderingTerm.desc(table.addedAtUtc)])).get();
      return Success(List.unmodifiable(rows.map(_mapRow)));
    } on Object {
      return const Failure(StorageError('Could not read local library.'));
    }
  }

  @override
  Future<Result<LibraryEntry?>> get(AnimeId animeId) async {
    try {
      final LocalLibraryEntry? row =
          await (database.select(database.localLibraryEntries)
                ..where((table) => table.animeId.equals(animeId.value)))
              .getSingleOrNull();
      return Success(row == null ? null : _mapRow(row));
    } on Object {
      return const Failure(StorageError('Could not read library entry.'));
    }
  }

  @override
  Future<Result<LibraryEntry>> add(AnimeId animeId) async {
    try {
      return await database.transaction(() async {
        final LocalLibraryEntry? existing =
            await (database.select(database.localLibraryEntries)
                  ..where((table) => table.animeId.equals(animeId.value)))
                .getSingleOrNull();
        if (existing != null) {
          return Success(_mapRow(existing));
        }
        final AnimeIdentityEntry? identity =
            await (database.select(database.animeIdentityEntries)
                  ..where((table) => table.animeId.equals(animeId.value)))
                .getSingleOrNull();
        if (identity == null) {
          return const Failure(NotFoundAppError('Anime identity not found.'));
        }
        final DateTime addedAtUtc = _clock().toUtc();
        await database
            .into(database.localLibraryEntries)
            .insert(
              LocalLibraryEntriesCompanion.insert(
                animeId: animeId.value,
                addedAtUtc: addedAtUtc,
              ),
            );
        return Success(LibraryEntry(animeId: animeId, addedAtUtc: addedAtUtc));
      });
    } on Object {
      return const Failure(StorageError('Could not add anime to library.'));
    }
  }

  @override
  Future<Result<LibraryEntry>> setStatus(
    AnimeId animeId,
    LibraryStatus status,
  ) async {
    try {
      return await database.transaction(() async {
        final int changed =
            await (database.update(
              database.localLibraryEntries,
            )..where((table) => table.animeId.equals(animeId.value))).write(
              LocalLibraryEntriesCompanion(status: Value(status.name)),
            );
        if (changed == 0) {
          return const Failure(
            NotFoundAppError('Anime is not in the local library.'),
          );
        }
        final LocalLibraryEntry row = await (database.select(
          database.localLibraryEntries,
        )..where((table) => table.animeId.equals(animeId.value))).getSingle();
        return Success(_mapRow(row));
      });
    } on Object {
      return const Failure(StorageError('Could not update library status.'));
    }
  }

  @override
  Future<Result<void>> remove(AnimeId animeId) async {
    try {
      await (database.delete(
        database.localLibraryEntries,
      )..where((table) => table.animeId.equals(animeId.value))).go();
      return const Success(null);
    } on Object {
      return const Failure(StorageError('Could not remove library entry.'));
    }
  }

  LibraryEntry _mapRow(LocalLibraryEntry row) => LibraryEntry(
    animeId: AnimeId(row.animeId),
    addedAtUtc: row.addedAtUtc.toUtc(),
    status: LibraryStatus.values.byName(row.status),
  );
}
