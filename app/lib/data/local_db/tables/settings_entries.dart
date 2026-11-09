import 'package:drift/drift.dart';

/// Persisted value envelope. Domain code owns serialization and validation.
class SettingsEntries extends Table {
  TextColumn get settingKey => text().named('setting_key')();

  TextColumn get valueJson => text().named('value_json')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}
