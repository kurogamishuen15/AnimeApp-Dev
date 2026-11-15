import 'package:drift/drift.dart';

/// AnimeApp-owned identities; external provider IDs are stored separately.
class AnimeIdentityEntries extends Table {
  TextColumn get animeId => text().named('anime_id')();

  DateTimeColumn get createdAtUtc => dateTime().named('created_at_utc')();

  @override
  Set<Column<Object>> get primaryKey => {animeId};

  @override
  List<String> get customConstraints => ['CHECK (length(trim(anime_id)) > 0)'];
}
