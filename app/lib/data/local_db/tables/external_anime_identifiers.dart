import 'package:drift/drift.dart';

import 'anime_identity_entries.dart';

/// Namespaced crosswalk; each provider ID can point to at most one local ID.
@TableIndex(name: 'external_anime_identifiers_by_anime', columns: {#animeId})
class ExternalAnimeIdentifiers extends Table {
  TextColumn get providerId => text().named('provider_id')();

  TextColumn get externalId => text().named('external_id')();

  TextColumn get animeId => text()
      .named('anime_id')
      .references(
        AnimeIdentityEntries,
        #animeId,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get evidence => text().named('evidence')();

  DateTimeColumn get linkedAtUtc => dateTime().named('linked_at_utc')();

  @override
  Set<Column<Object>> get primaryKey => {providerId, externalId};

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(provider_id)) > 0)',
    'CHECK (length(trim(external_id)) > 0)',
    "CHECK (evidence IN ('trustedProviderCrossReference', "
        "'verifiedOfficialReference', 'userConfirmed'))",
  ];
}
