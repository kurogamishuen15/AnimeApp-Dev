import 'package:drift/drift.dart';

import 'anime_identity_entries.dart';

/// Directed, typed franchise relationships. No title-based relationships are
/// generated automatically.
class AnimeIdentityRelationships extends Table {
  @ReferenceName('outgoingRelationships')
  TextColumn get sourceAnimeId => text()
      .named('source_anime_id')
      .references(
        AnimeIdentityEntries,
        #animeId,
        onDelete: KeyAction.cascade,
      )();

  @ReferenceName('incomingRelationships')
  TextColumn get targetAnimeId => text()
      .named('target_anime_id')
      .references(
        AnimeIdentityEntries,
        #animeId,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get relationshipKind => text().named('relationship_kind')();

  TextColumn get evidence => text().named('evidence')();

  DateTimeColumn get linkedAtUtc => dateTime().named('linked_at_utc')();

  @override
  Set<Column<Object>> get primaryKey => {
    sourceAnimeId,
    targetAnimeId,
    relationshipKind,
  };

  @override
  List<String> get customConstraints => [
    'CHECK (source_anime_id <> target_anime_id)',
    "CHECK (relationship_kind IN ('season', 'sequel', 'prequel', 'movie', "
        "'special', 'ova', 'alternateVersion'))",
    "CHECK (evidence IN ('trustedProviderCrossReference', "
        "'verifiedOfficialReference', 'userConfirmed'))",
  ];
}
