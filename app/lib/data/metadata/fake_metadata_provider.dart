import '../../domain/catalog/external_anime_id.dart';
import '../../domain/catalog/metadata_provenance.dart';
import '../../domain/catalog/metadata_provider.dart';
import '../../domain/catalog/provider_anime_metadata.dart';
import '../../domain/catalog/provider_result.dart';

/// Deterministic, synthetic catalog for local development and tests.
///
/// This provider performs no I/O and contains no data from AniList, TMDB, or
/// Kitsu. Replace it only after a real provider is approved for the product.
final class FakeMetadataProvider
    implements MetadataProvider, PublicAnimeBrowseProvider {
  FakeMetadataProvider({DateTime Function()? clock})
    : _clock = clock ?? _fixedClock;

  static final MetadataProviderId providerId = MetadataProviderId('demo');

  final DateTime Function() _clock;
  int searchRequestCount = 0;
  int detailsRequestCount = 0;

  static DateTime _fixedClock() => DateTime.utc(2026, 1, 1);

  static final List<({String id, String title, String synopsis, int year})>
  _seed = [
    (
      id: 'winter-lanterns',
      title: 'Faroles de invierno',
      synopsis: 'Una restauradora encuentra cartas en una estación nevada.',
      year: 2024,
    ),
    (
      id: 'orbital-garden',
      title: 'Jardín orbital',
      synopsis: 'La tripulación de una estación cultiva el último jardín.',
      year: 2023,
    ),
    (
      id: 'copper-leaves',
      title: 'Hojas de cobre',
      synopsis: 'Dos amigos reconstruyen un cine en su barrio.',
      year: 2022,
    ),
  ];

  List<ProviderAnimeMetadata> get _records => List.unmodifiable(
    _seed.map((record) {
      final ExternalAnimeId id = ExternalAnimeId(
        providerId: providerId,
        value: record.id,
      );
      return ProviderAnimeMetadata(
        externalId: id,
        preferredTitle: record.title,
        synopsis: record.synopsis,
        format: AnimeFormat.tv,
        releaseYear: record.year,
        episodeCount: 12,
        provenance: MetadataProvenance(
          externalId: id,
          retrievedAtUtc: _clock().toUtc(),
        ),
      );
    }),
  );

  @override
  MetadataProviderId get id => providerId;

  @override
  Set<MetadataCapability> get capabilities => const {
    MetadataCapability.publicSearch,
    MetadataCapability.animeDetails,
  };

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> searchAnime(
    String query, {
    int limit = 20,
  }) async {
    searchRequestCount++;
    if (limit <= 0) return const ProviderNoResults();
    final String normalized = query.trim().toLowerCase();
    final Iterable<ProviderAnimeMetadata> results = _records.where(
      (ProviderAnimeMetadata item) =>
          normalized.isEmpty ||
          item.preferredTitle.toLowerCase().contains(normalized) ||
          (item.synopsis ?? '').toLowerCase().contains(normalized),
    );
    final List<ProviderAnimeMetadata> limited = results.take(limit).toList();
    return limited.isEmpty
        ? const ProviderNoResults()
        : ProviderSuccess(List.unmodifiable(limited));
  }

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browsePopular({
    int limit = 20,
  }) async => ProviderSuccess(_records.take(limit).toList(growable: false));

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browseTrending({
    int limit = 20,
  }) async =>
      ProviderSuccess(_records.reversed.take(limit).toList(growable: false));

  @override
  Future<ProviderResult<ProviderAnimeMetadata>> getAnimeByExternalId(
    ExternalAnimeId id,
  ) async {
    detailsRequestCount++;
    if (id.providerId != providerId) return const ProviderNoResults();
    for (final ProviderAnimeMetadata record in _records) {
      if (record.externalId == id) return ProviderSuccess(record);
    }
    return const ProviderNoResults();
  }

  @override
  Future<ProviderResult<List<ProviderEpisodeMetadata>>> getEpisodes(
    ExternalAnimeId animeId,
  ) async => const ProviderUnsupported('episodeMetadata');

  @override
  Future<ProviderResult<ProviderHealth>> checkHealth() async =>
      const ProviderSuccess(ProviderHealth.healthy);
}
