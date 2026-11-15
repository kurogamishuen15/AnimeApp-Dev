import 'package:drift/drift.dart';

import 'anime_identity_entries.dart';

/// User-owned local library membership, independent from metadata retention.
@TableIndex(name: 'library_entries_by_added_at', columns: {#addedAtUtc})
class LocalLibraryEntries extends Table {
  TextColumn get animeId => text()
      .named('anime_id')
      .references(
        AnimeIdentityEntries,
        #animeId,
        onDelete: KeyAction.cascade,
      )();

  DateTimeColumn get addedAtUtc => dateTime().named('added_at_utc')();

  TextColumn get status =>
      text().named('status').withDefault(const Constant('planned'))();

  @override
  Set<Column<Object>> get primaryKey => {animeId};

  @override
  String get tableName => 'library_entries';

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(anime_id)) > 0)',
    "CHECK (status IN ('planned', 'watching', 'rewatching', 'paused', 'completed', 'abandoned'))",
  ];
}
