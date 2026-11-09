import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/latest_anime_search.dart';
import 'tables/progress_documents.dart';
import 'tables/settings_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SettingsEntries, ProgressDocuments, LatestAnimeSearch])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the app database in the user's application support directory.
  factory AppDatabase.open() => AppDatabase(_openConnection());

  /// Opens an explicit file, primarily for isolated integration tests.
  factory AppDatabase.atFile(File file) => AppDatabase(NativeDatabase(file));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(progressDocuments);
      }
      if (from < 3) {
        await migrator.createTable(latestAnimeSearch);
      }
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
