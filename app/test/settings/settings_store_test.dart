import 'dart:async';
import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/local_db/app_database.dart';
import 'package:anime_app/settings/registry/setting_definition.dart';
import 'package:anime_app/settings/registry/settings_registry.dart';
import 'package:anime_app/settings/store/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

SettingDefinition<int> _integerSetting({String key = 'test.counter'}) =>
    SettingDefinition<int>(
      key: key,
      owner: 'F1.5 test fixture',
      defaultValue: 5,
      encode: (value) => value,
      decode: (value) {
        if (value is! int) {
          throw const FormatException('Expected an integer.');
        }
        return value;
      },
      isValid: (value) => value >= 0 && value <= 20,
    );

Future<Directory> _temporaryDatabaseDirectory() async {
  final appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app')) {
    throw StateError(
      'F1.5 tests must run from app/ to keep fixtures in project scope.',
    );
  }
  final projectDirectory = appDirectory.parent;
  if (!File('${appDirectory.path}/pubspec.yaml').existsSync() ||
      !File('${projectDirectory.path}/AGENTS.md').existsSync() ||
      !Directory('${projectDirectory.path}/.git').existsSync()) {
    throw StateError(
      'Could not verify the project root for F1.5 test cleanup.',
    );
  }
  final directory = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}f1_5'
    '${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

void main() {
  test('returns the typed default without a stored row', () async {
    final directory = await _temporaryDatabaseDirectory();
    final database = AppDatabase.atFile(
      File('${directory.path}/settings.sqlite'),
    );
    final definition = _integerSetting();
    final registry = SettingsRegistry()..register(definition);
    final store = SettingsStore(database: database, registry: registry);

    try {
      final Result<int> result = await store.get(definition);
      expect(result, isA<Success<int>>());
      expect((result as Success<int>).value, 5);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'sets, reads and watches a persisted value across database reopen',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final file = File('${directory.path}/settings.sqlite');
      final definition = _integerSetting();
      final registry = SettingsRegistry()..register(definition);
      final database = AppDatabase.atFile(file);
      final store = SettingsStore(
        database: database,
        registry: registry,
        clock: () => DateTime.utc(2026, 11, 9),
      );
      final values = StreamIterator(store.watch(definition));
      var databaseClosed = false;

      try {
        expect(await values.moveNext(), isTrue);
        expect(values.current, isA<Success<int>>());
        expect((values.current as Success<int>).value, 5);
        final changed = values.moveNext();
        expect(await store.set(definition, 12), isA<Success<void>>());
        expect(await changed, isTrue);
        expect(values.current, isA<Success<int>>());
        expect((values.current as Success<int>).value, 12);
        await values.cancel();
        await database.close();
        databaseClosed = true;

        final reopened = AppDatabase.atFile(file);
        try {
          final reopenedStore = SettingsStore(
            database: reopened,
            registry: registry,
          );
          final Result<int> persisted = await reopenedStore.get(definition);
          expect(persisted, isA<Success<int>>());
          expect((persisted as Success<int>).value, 12);
        } finally {
          await reopened.close();
        }
      } finally {
        await values.cancel();
        if (!databaseClosed) {
          await database.close();
        }
        await directory.delete(recursive: true);
      }
    },
  );

  test('does not emit a setting when a different key changes', () async {
    final directory = await _temporaryDatabaseDirectory();
    final database = AppDatabase.atFile(
      File('${directory.path}/settings.sqlite'),
    );
    final watched = _integerSetting(key: 'test.watched');
    final unrelated = _integerSetting(key: 'test.unrelated');
    final registry = SettingsRegistry()
      ..register(watched)
      ..register(unrelated);
    final store = SettingsStore(database: database, registry: registry);
    final values = StreamIterator(store.watch(watched));

    try {
      expect(await values.moveNext(), isTrue);
      expect((values.current as Success<int>).value, watched.defaultValue);
      final Future<bool> nextValue = values.moveNext();
      expect(await store.set(unrelated, 9), isA<Success<void>>());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      var emitted = false;
      unawaited(nextValue.then((_) => emitted = true));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emitted, isFalse);
      expect(
        await store.set(watched, watched.defaultValue),
        isA<Success<void>>(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emitted, isFalse);
      expect(await store.set(watched, 12), isA<Success<void>>());
      expect(await nextValue, isTrue);
      expect((values.current as Success<int>).value, 12);
    } finally {
      await values.cancel();
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'rejects invalid values, corrupt persisted types and unregistered keys',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final database = AppDatabase.atFile(
        File('${directory.path}/settings.sqlite'),
      );
      final definition = _integerSetting();
      final unregistered = _integerSetting(key: 'test.unregistered');
      final registry = SettingsRegistry()..register(definition);
      final store = SettingsStore(database: database, registry: registry);

      try {
        final Result<void> invalidWrite = await store.set(definition, 21);
        expect(invalidWrite, isA<Failure<void>>());
        expect(
          (invalidWrite as Failure<void>).error,
          isA<ValidationAppError>(),
        );
        expect(await store.get(unregistered), isA<Failure<int>>());

        await database
            .into(database.settingsEntries)
            .insert(
              SettingsEntriesCompanion.insert(
                settingKey: definition.key,
                valueJson: '"not-an-integer"',
                updatedAt: DateTime.utc(2026, 11, 9),
              ),
            );
        final Result<int> corrupt = await store.get(definition);
        expect(corrupt, isA<Failure<int>>());
        expect((corrupt as Failure<int>).error, isA<StorageError>());
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('rejects duplicate registry keys and invalid defaults', () {
    final first = _integerSetting();
    final duplicate = _integerSetting();
    final registry = SettingsRegistry()..register(first);

    expect(() => registry.register(duplicate), throwsArgumentError);
    expect(
      () => SettingDefinition<int>(
        key: 'test.invalid-default',
        owner: 'F1.5 test fixture',
        defaultValue: 21,
        encode: (value) => value,
        decode: (value) => value! as int,
        isValid: (value) => value >= 0 && value <= 20,
      ),
      throwsArgumentError,
    );
  });

  test(
    'returns typed storage failure when the watched database cannot open',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final database = AppDatabase.atFile(File(directory.path));
      final definition = _integerSetting();
      final registry = SettingsRegistry()..register(definition);
      final store = SettingsStore(database: database, registry: registry);

      try {
        final Result<int> result = await store.watch(definition).first;
        expect(result, isA<Failure<int>>());
        expect((result as Failure<int>).error, isA<StorageError>());
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
