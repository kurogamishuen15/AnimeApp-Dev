import 'dart:io';

import 'package:anime_app/data/local_db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<Directory> _temporaryDatabaseDirectory() async {
  final appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app')) {
    throw StateError(
      'F1.6 tests must run from app/ to keep fixtures in project scope.',
    );
  }
  final projectDirectory = appDirectory.parent;
  if (!File('${appDirectory.path}/pubspec.yaml').existsSync() ||
      !File('${projectDirectory.path}/AGENTS.md').existsSync() ||
      !Directory('${projectDirectory.path}/.git').existsSync()) {
    throw StateError(
      'Could not verify the project root for F1.6 test cleanup.',
    );
  }
  final root = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}f1_6',
  );
  final directory = Directory(
    '${root.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'creates schema, stores typed rows, and reopens the real SQLite file',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final file = File('${directory.path}/anime_app.sqlite');
      final database = AppDatabase.atFile(file);
      final savedAt = DateTime.utc(2026, 11, 9);
      var databaseClosed = false;

      try {
        await database
            .into(database.settingsEntries)
            .insert(
              SettingsEntriesCompanion.insert(
                settingKey: 'theme.mode',
                valueJson: '"system"',
                updatedAt: savedAt,
              ),
            );
        await database
            .into(database.progressDocuments)
            .insert(
              ProgressDocumentsCompanion.insert(
                documentKey: 'opaque-example',
                payloadJson: '{"opaque":true}',
                updatedAt: savedAt,
              ),
            );
        expect(file.existsSync(), isTrue);
        expect(
          await database.select(database.settingsEntries).getSingle(),
          isA<SettingsEntry>(),
        );
        expect(
          await database.select(database.progressDocuments).getSingle(),
          isA<ProgressDocument>(),
        );
        await database.close();
        databaseClosed = true;

        final reopened = AppDatabase.atFile(file);
        expect(
          await reopened.select(reopened.settingsEntries).getSingle(),
          isA<SettingsEntry>(),
        );
        expect(
          await reopened.select(reopened.progressDocuments).getSingle(),
          isA<ProgressDocument>(),
        );
        await reopened.close();
      } finally {
        if (!databaseClosed) {
          await database.close();
        }
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'migrates v1 settings data to the current schema without losing it',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final file = File('${directory.path}/anime_app.sqlite');
      final oldDatabase = sqlite.sqlite3.open(file.path);
      final historicalSchema = File(
        '${Directory.current.path}/drift_schemas/schema_v1.sql',
      );
      oldDatabase.execute(historicalSchema.readAsStringSync());
      oldDatabase.execute('INSERT INTO settings_entries VALUES (?, ?, ?)', [
        'theme.mode',
        '"system"',
        DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
      ]);
      oldDatabase.execute('PRAGMA user_version = 1');
      oldDatabase.close();

      final database = AppDatabase.atFile(file);
      try {
        final setting = await database
            .select(database.settingsEntries)
            .getSingle();
        expect(setting.settingKey, 'theme.mode');
        expect(setting.valueJson, '"system"');
        expect(
          await database.select(database.progressDocuments).get(),
          isEmpty,
        );
        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), 8);
        expect(
          await database.select(database.animeIdentityEntries).get(),
          isEmpty,
        );
        expect(
          await database.select(database.localLibraryEntries).get(),
          isEmpty,
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'migrates v2 to current schema and creates the bounded search-cache table',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final file = File('${directory.path}/anime_app.sqlite');
      final oldDatabase = sqlite.sqlite3.open(file.path);
      final snapshot = File(
        '${Directory.current.path}/drift_schemas/schema_v2.sql',
      );
      for (final String statement in snapshot.readAsStringSync().split(';')) {
        if (statement.trim().isNotEmpty) {
          oldDatabase.execute(statement);
        }
      }
      oldDatabase.execute('INSERT INTO settings_entries VALUES (?, ?, ?)', [
        'theme.mode',
        '"system"',
        DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
      ]);
      oldDatabase.execute('PRAGMA user_version = 2');
      oldDatabase.close();

      final database = AppDatabase.atFile(file);
      try {
        final setting = await database
            .select(database.settingsEntries)
            .getSingle();
        expect(setting.settingKey, 'theme.mode');
        expect(
          await database.select(database.latestAnimeSearch).get(),
          isEmpty,
        );
        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), 8);
        expect(
          await database.select(database.animeIdentityEntries).get(),
          isEmpty,
        );
        expect(
          await database.select(database.localLibraryEntries).get(),
          isEmpty,
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('rolls back a failed multi-write transaction', () async {
    final directory = await _temporaryDatabaseDirectory();
    final file = File('${directory.path}/anime_app.sqlite');
    final database = AppDatabase.atFile(file);

    try {
      await expectLater(
        database.transaction(() async {
          await database
              .into(database.settingsEntries)
              .insert(
                SettingsEntriesCompanion.insert(
                  settingKey: 'temporary',
                  valueJson: 'true',
                  updatedAt: DateTime.utc(2026, 11, 9),
                ),
              );
          throw StateError('rollback fixture');
        }),
        throwsA(isA<StateError>()),
      );
      expect(await database.select(database.settingsEntries).get(), isEmpty);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'migrates v3 to v7 while preserving cache and progress documents',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final file = File('${directory.path}/anime_app.sqlite');
      final oldDatabase = sqlite.sqlite3.open(file.path);
      final snapshot = File(
        '${Directory.current.path}/drift_schemas/schema_v3.sql',
      );
      for (final String statement in snapshot.readAsStringSync().split(';')) {
        if (statement.trim().isNotEmpty) oldDatabase.execute(statement);
      }
      oldDatabase.execute('INSERT INTO settings_entries VALUES (?, ?, ?)', [
        'theme.mode',
        '"system"',
        DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
      ]);
      oldDatabase.execute('INSERT INTO progress_documents VALUES (?, ?, ?)', [
        'legacy',
        '{"keep":true}',
        DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
      ]);
      oldDatabase.execute(
        'INSERT INTO latest_anime_search VALUES (?, ?, ?, ?, ?, ?)',
        ['latest_user_search', 'series', 1, 20, '[]', 1794182400000],
      );
      oldDatabase.execute('PRAGMA user_version = 3');
      oldDatabase.close();

      final database = AppDatabase.atFile(file);
      try {
        expect(
          (await database.select(database.settingsEntries).getSingle())
              .valueJson,
          '"system"',
        );
        expect(
          (await database.select(database.progressDocuments).getSingle())
              .payloadJson,
          '{"keep":true}',
        );
        expect(
          (await database.select(database.latestAnimeSearch).getSingle())
              .searchQuery,
          'series',
        );
        expect(
          await database.select(database.playbackProgressEntries).get(),
          isEmpty,
        );
        expect(
          await database.select(database.animeIdentityEntries).get(),
          isEmpty,
        );
        expect(
          (await database.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          8,
        );
        expect(
          (await database.customSelect('PRAGMA integrity_check').getSingle())
              .read<String>('integrity_check'),
          'ok',
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('migrates v5 library data to v7 with all supported statuses', () async {
    final directory = await _temporaryDatabaseDirectory();
    final file = File('${directory.path}/anime_app.sqlite');
    final oldDatabase = sqlite.sqlite3.open(file.path);
    final snapshot = File(
      '${Directory.current.path}/drift_schemas/schema_v5.sql',
    );
    for (final String statement in snapshot.readAsStringSync().split(';')) {
      if (statement.trim().isNotEmpty) oldDatabase.execute(statement);
    }
    final int timestamp = DateTime.utc(2026, 11, 9).millisecondsSinceEpoch;
    oldDatabase.execute('INSERT INTO settings_entries VALUES (?, ?, ?)', [
      'theme.mode',
      '"system"',
      timestamp,
    ]);
    oldDatabase.execute('INSERT INTO progress_documents VALUES (?, ?, ?)', [
      'legacy',
      '{"keep":true}',
      timestamp,
    ]);
    oldDatabase.execute(
      'INSERT INTO latest_anime_search VALUES (?, ?, ?, ?, ?, ?)',
      ['latest_user_search', 'demo', 1, 20, '[]', timestamp],
    );
    oldDatabase.execute(
      'INSERT INTO playback_progress_entries '
      '(content_id, episode_id, position_ms, duration_ms, updated_at_utc, completion, revision) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      ['anime:demo', 'episode:1', 45000, null, timestamp, 'inProgress', 0],
    );
    oldDatabase.execute('INSERT INTO anime_identity_entries VALUES (?, ?)', [
      'anime:demo',
      timestamp,
    ]);
    oldDatabase.execute(
      'INSERT INTO external_anime_identifiers VALUES (?, ?, ?, ?, ?)',
      ['demo', 'winter-lanterns', 'anime:demo', 'userConfirmed', timestamp],
    );
    oldDatabase.execute('INSERT INTO library_entries VALUES (?, ?)', [
      'anime:demo',
      timestamp,
    ]);
    oldDatabase.execute('PRAGMA user_version = 5');
    oldDatabase.close();

    final database = AppDatabase.atFile(file);
    try {
      final libraryEntry = await database
          .select(database.localLibraryEntries)
          .getSingle();
      expect(libraryEntry.animeId, 'anime:demo');
      expect(libraryEntry.status, 'planned');
      expect(
        (await database.select(database.externalAnimeIdentifiers).getSingle())
            .externalId,
        'winter-lanterns',
      );
      expect(
        (await database.select(database.playbackProgressEntries).getSingle())
            .positionMs,
        45000,
      );
      expect(
        (await database.select(database.progressDocuments).getSingle())
            .payloadJson,
        '{"keep":true}',
      );
      expect(
        (await database.select(database.latestAnimeSearch).getSingle())
            .searchQuery,
        'demo',
      );
      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        8,
      );
      await expectLater(
        database.customStatement(
          "UPDATE library_entries SET status = 'invalid' WHERE anime_id = 'anime:demo'",
        ),
        throwsA(anything),
      );
      for (final status in [
        'planned',
        'watching',
        'rewatching',
        'paused',
        'completed',
        'abandoned',
      ]) {
        await database.customStatement(
          'UPDATE library_entries SET status = ? WHERE anime_id = ?',
          [status, 'anime:demo'],
        );
        expect(
          (await database.select(database.localLibraryEntries).getSingle())
              .status,
          status,
        );
      }
      expect(
        (await database.customSelect('PRAGMA integrity_check').getSingle())
            .read<String>('integrity_check'),
        'ok',
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'migrates schema v6 status constraints without losing membership',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final file = File('${directory.path}/anime_app.sqlite');
      final oldDatabase = sqlite.sqlite3.open(file.path);
      final snapshot = File(
        '${Directory.current.path}/drift_schemas/schema_v5.sql',
      );
      for (final String statement in snapshot.readAsStringSync().split(';')) {
        if (statement.trim().isNotEmpty) oldDatabase.execute(statement);
      }
      final int timestamp = DateTime.utc(2026, 11, 9).millisecondsSinceEpoch;
      oldDatabase.execute('INSERT INTO anime_identity_entries VALUES (?, ?)', [
        'anime:from-v6',
        timestamp,
      ]);
      oldDatabase.execute('INSERT INTO library_entries VALUES (?, ?)', [
        'anime:from-v6',
        timestamp,
      ]);
      oldDatabase.execute('''
      ALTER TABLE library_entries ADD COLUMN status TEXT NOT NULL
        DEFAULT 'planned'
        CHECK (status IN ('planned', 'watching', 'completed'))
    ''');
      oldDatabase.execute(
        "UPDATE library_entries SET status = 'completed' WHERE anime_id = ?",
        ['anime:from-v6'],
      );
      oldDatabase.execute('PRAGMA user_version = 6');
      oldDatabase.close();

      final database = AppDatabase.atFile(file);
      try {
        final entry = await database
            .select(database.localLibraryEntries)
            .getSingle();
        expect(entry.animeId, 'anime:from-v6');
        expect(entry.status, 'completed');
        expect(
          (await database.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          8,
        );
        expect(
          (await database.customSelect('PRAGMA integrity_check').getSingle())
              .read<String>('integrity_check'),
          'ok',
        );
        expect(
          await database.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
