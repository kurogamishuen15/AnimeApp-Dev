import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/anime_identity_entries.dart';
import 'tables/anime_identity_relationships.dart';
import 'tables/external_anime_identifiers.dart';
import 'tables/latest_anime_search.dart';
import 'tables/library_entries.dart';
import 'tables/playback_progress_entries.dart';
import 'tables/progress_documents.dart';
import 'tables/settings_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SettingsEntries,
    ProgressDocuments,
    LatestAnimeSearch,
    PlaybackProgressEntries,
    AnimeIdentityEntries,
    ExternalAnimeIdentifiers,
    AnimeIdentityRelationships,
    LocalLibraryEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the app database in the user's application support directory.
  factory AppDatabase.open() => AppDatabase(_openConnection());

  /// Opens an explicit file, primarily for isolated integration tests.
  factory AppDatabase.atFile(File file) => AppDatabase(NativeDatabase(file));

  @override
  int get schemaVersion => 8;

  Future<void> _createDetailCache() => customStatement('''
    CREATE TABLE anilist_detail_cache (
      media_id INTEGER PRIMARY KEY,
      payload TEXT NOT NULL,
      fetched_at INTEGER NOT NULL
    )
  ''');

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createDetailCache();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(progressDocuments);
      }
      if (from < 3) {
        await migrator.createTable(latestAnimeSearch);
      }
      if (from < 4) {
        await migrator.createTable(playbackProgressEntries);
      }
      if (from < 5) {
        await migrator.createTable(animeIdentityEntries);
        await migrator.createTable(externalAnimeIdentifiers);
        await migrator.createTable(animeIdentityRelationships);
        await migrator.createTable(localLibraryEntries);
      }
      if (from == 5) {
        await customStatement("""
          ALTER TABLE library_entries ADD COLUMN status TEXT NOT NULL
            DEFAULT 'planned'
            CHECK (status IN ('planned', 'watching', 'completed'))
          """);
      }
      if (from >= 5 && from < 7) {
        await customStatement('''
          CREATE TABLE library_entries_new (
            anime_id TEXT NOT NULL PRIMARY KEY
              REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE,
            added_at_utc INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'planned'
              CHECK (status IN ('planned', 'watching', 'rewatching', 'paused', 'completed', 'abandoned')),
            CHECK (length(trim(anime_id)) > 0)
          )
        ''');
        await customStatement('''
          INSERT INTO library_entries_new (anime_id, added_at_utc, status)
          SELECT anime_id, added_at_utc, status FROM library_entries
        ''');
        await customStatement('DROP TABLE library_entries');
        await customStatement(
          'ALTER TABLE library_entries_new RENAME TO library_entries',
        );
        await customStatement(
          'CREATE INDEX library_entries_by_added_at ON library_entries (added_at_utc)',
        );
      }
      if (from < 8) await _createDetailCache();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}anime_app',
  );
  await databaseDirectory.create(recursive: true);
  final file = File(
    '${databaseDirectory.path}${Platform.pathSeparator}anime_app.sqlite',
  );
  return NativeDatabase.createInBackground(file);
});
