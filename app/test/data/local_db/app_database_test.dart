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

  test('migrates v1 settings data to v2 without losing it', () async {
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
      expect(await database.select(database.progressDocuments).get(), isEmpty);
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 2);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

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
}
