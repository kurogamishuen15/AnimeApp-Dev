import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../data/local_db/app_database.dart';
import '../registry/setting_definition.dart';
import '../registry/settings_registry.dart';

/// Local-first settings persistence. Secrets must use a secure-store adapter.
class SettingsStore {
  SettingsStore({
    required this.database,
    required this.registry,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final SettingsRegistry registry;
  final DateTime Function() _clock;

  Future<Result<T>> get<T>(SettingDefinition<T> definition) async {
    final Result<SettingDefinition<T>> resolved = registry.resolve(definition);
    if (resolved case Failure<SettingDefinition<T>>(:final error)) {
      return Failure(error);
    }

    try {
      final SettingsEntry? entry =
          await (database.select(database.settingsEntries)
                ..where((table) => table.settingKey.equals(definition.key)))
              .getSingleOrNull();
      if (entry == null) {
        return Success(definition.defaultValue);
      }
      return Success(definition.decodeJson(entry.valueJson));
    } on Object {
      return const Failure(StorageError('Could not read the setting.'));
    }
  }

  Future<Result<void>> set<T>(SettingDefinition<T> definition, T value) async {
    final Result<SettingDefinition<T>> resolved = registry.resolve(definition);
    if (resolved case Failure<SettingDefinition<T>>(:final error)) {
      return Failure(error);
    }
    if (!definition.isValid(value)) {
      return const Failure(ValidationAppError('Setting value is invalid.'));
    }

    try {
      await database
          .into(database.settingsEntries)
          .insertOnConflictUpdate(
            SettingsEntriesCompanion.insert(
              settingKey: definition.key,
              valueJson: definition.encodeJson(value),
              updatedAt: _clock().toUtc(),
            ),
          );
      return const Success<void>(null);
    } on FormatException {
      return const Failure(ValidationAppError('Setting value is invalid.'));
    } on Object {
      return const Failure(StorageError('Could not write the setting.'));
    }
  }

  Stream<Result<T>> watch<T>(SettingDefinition<T> definition) {
    final Result<SettingDefinition<T>> resolved = registry.resolve(definition);
    if (resolved case Failure<SettingDefinition<T>>(:final error)) {
      return Stream.value(Failure(error));
    }

    return _watchRegistered(definition);
  }

  Stream<Result<T>> _watchRegistered<T>(
    SettingDefinition<T> definition,
  ) async* {
    try {
      final query = database.select(database.settingsEntries)
        ..where((table) => table.settingKey.equals(definition.key));
      await for (final rows in query.watch()) {
        if (rows.isEmpty) {
          yield Success(definition.defaultValue);
          continue;
        }
        try {
          yield Success(definition.decodeJson(rows.single.valueJson));
        } on Object {
          yield const Failure(StorageError('Could not decode the setting.'));
        }
      }
    } on Object {
      yield const Failure(StorageError('Could not watch the setting.'));
    }
  }
}
