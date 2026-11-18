import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_catalog_repository.dart';
import '../../domain/catalog/anime_detail_metadata.dart';
import '../../domain/catalog/anime_summary.dart';
import '../../domain/catalog/external_anime_id.dart';
import '../../domain/catalog/metadata_provenance.dart';
import '../../domain/catalog/metadata_provider.dart';
import '../../domain/catalog/provider_anime_metadata.dart';
import '../../domain/catalog/provider_result.dart';

/// Provider-neutral mapping of the existing public AniList read client.
final class AniListMetadataProvider
    implements
        MetadataProvider,
        PublicAnimeBrowseProvider,
        CachedAnimeMetadataProvider {
  AniListMetadataProvider(this.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static final MetadataProviderId providerId = MetadataProviderId('anilist');
  final AnimeCatalogRepository repository;
  final DateTime Function() _clock;

  @override
  MetadataProviderId get id => providerId;
  @override
  Set<MetadataCapability> get capabilities => const {
    MetadataCapability.publicSearch,
    MetadataCapability.animeDetails,
    MetadataCapability.episodeMetadata,
  };

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> searchAnime(
    String query, {
    int limit = 20,
  }) async {
    final result = await repository.searchAnime(
      query,
      perPage: limit.clamp(1, 50),
    );
    return _map(result);
  }

  Future<ProviderResult<List<ProviderAnimeMetadata>>> browse({
    AnimeBrowseSort sort = AnimeBrowseSort.popular,
    int limit = 20,
  }) async => _map(
    await repository.browseAnime(sort: sort, perPage: limit.clamp(1, 50)),
  );

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browsePopular({
    int limit = 20,
  }) => browse(sort: AnimeBrowseSort.popular, limit: limit);

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browseTrending({
    int limit = 20,
  }) => browse(sort: AnimeBrowseSort.trending, limit: limit);

  @override
  Future<ProviderAnimeMetadata?> readCachedAnime(ExternalAnimeId id) async {
    final source = repository;
    final numericId = _numericId(id);
    if (source is! CachedAnimeCatalog || numericId == null) return null;
    final item = await (source as CachedAnimeCatalog).readCachedAnime(
      numericId,
    );
    return item == null ? null : _convert(item);
  }

  int? _numericId(ExternalAnimeId id) =>
      id.providerId == providerId ? int.tryParse(id.value) : null;

  @override
  Future<ProviderResult<ProviderAnimeMetadata>> getAnimeByExternalId(
    ExternalAnimeId id,
  ) async {
    final numericId = _numericId(id);
    if (numericId == null) {
      return const ProviderNoResults();
    }
    final result = await repository.searchAnimeById(numericId);
    return switch (result) {
      Success(:final value)
          when value.items.isNotEmpty &&
              value.items.first.id.toString() == id.value =>
        ProviderSuccess(_convert(value.items.first)),
      Success() => const ProviderNoResults(),
      Failure(:final error) => _failure(error),
    };
  }

  @override
  Future<ProviderResult<List<ProviderEpisodeMetadata>>> getEpisodes(
    ExternalAnimeId animeId,
  ) async {
    final numericId = _numericId(animeId);
    if (numericId == null) return const ProviderNoResults();
    return switch (await repository.searchAnimeById(numericId)) {
      Success(:final value)
          when value.items.isNotEmpty &&
              value.items.first.id.toString() == animeId.value =>
        ProviderSuccess(
          List.unmodifiable([
            for (final episode
                in value.items.first.detail?.episodes ??
                    const <AnimeEpisodeMetadata>[])
              ProviderEpisodeMetadata(
                animeId: animeId,
                externalEpisodeId: '${animeId.value}:${episode.number}',
                episodeNumber: episode.number,
                title: episode.title,
                thumbnailUrl: episode.thumbnailUrl,
                site: episode.site,
                provenance: MetadataProvenance(
                  externalId: animeId,
                  retrievedAtUtc: _clock().toUtc(),
                ),
              ),
          ]),
        ),
      Success() => const ProviderNoResults(),
      Failure(:final error) => _failure(error),
    };
  }

  @override
  Future<ProviderResult<ProviderHealth>> checkHealth() async =>
      const ProviderSuccess(ProviderHealth.unknown);

  ProviderResult<List<ProviderAnimeMetadata>> _map(
    Result<AnimeSearchResult> result,
  ) => switch (result) {
    Success(:final value) => ProviderSuccess(
      List.unmodifiable(_convertAll(value.items)),
    ),
    Failure(:final error) => _failure(error),
  };

  List<ProviderAnimeMetadata> _convertAll(List<AnimeSummary> items) {
    final List<ProviderAnimeMetadata> converted = [];
    for (final AnimeSummary item in items) {
      try {
        converted.add(_convert(item));
      } on ArgumentError {
        continue;
      }
    }
    return converted;
  }

  ProviderFailure<T> _failure<T>(AppError error) =>
      ProviderFailure(switch (error) {
        NetworkError() => ProviderFailureKind.network,
        TimeoutAppError() => ProviderFailureKind.timeout,
        RateLimitError() => ProviderFailureKind.rateLimited,
        AuthAppError() => ProviderFailureKind.authentication,
        ValidationAppError() ||
        UnknownAppError() => ProviderFailureKind.invalidResponse,
        _ => ProviderFailureKind.unavailable,
      }, retryAfter: error is RateLimitError ? error.retryAfter : null);

  ProviderAnimeMetadata _convert(AnimeSummary item) {
    final id = ExternalAnimeId(
      providerId: providerId,
      value: item.id.toString(),
    );
    final titles = [item.englishTitle, item.nativeTitle].whereType<String>();
    final data = item.startDate;
    return ProviderAnimeMetadata(
      externalId: id,
      preferredTitle:
          item.englishTitle ??
          item.romajiTitle ??
          item.nativeTitle ??
          'Anime ${item.id}',
      romajiTitle: item.romajiTitle,
      alternativeTitles: titles,
      synopsis: _plainDescription(item.description),
      coverImageUrl: _httpsImage(item.coverImageUrl),
      bannerImageUrl: _httpsImage(item.bannerImageUrl),
      genres: item.genres,
      releaseYear: _year(data?.year),
      endYear: _year(item.endDate?.year),
      episodeCount: item.detail?.episodeCount,
      detail: item.detail,
      averageScore: item.score?.round(),
      popularity: item.popularity,
      format: switch (item.format) {
        'TV' => AnimeFormat.tv,
        'MOVIE' => AnimeFormat.movie,
        'OVA' => AnimeFormat.ova,
        'ONA' => AnimeFormat.ona,
        'SPECIAL' => AnimeFormat.special,
        _ => AnimeFormat.unknown,
      },
      season: item.season,
      seasonYear: _year(item.seasonYear, minimum: 1900),
      airingStatus: switch (item.status) {
        'FINISHED' => AnimeAiringStatus.finished,
        'RELEASING' => AnimeAiringStatus.releasing,
        'NOT_YET_RELEASED' => AnimeAiringStatus.notYetReleased,
        'CANCELLED' => AnimeAiringStatus.cancelled,
        _ => AnimeAiringStatus.unknown,
      },
      provenance: MetadataProvenance(
        externalId: id,
        retrievedAtUtc: _clock().toUtc(),
      ),
    );
  }

  static int? _year(int? year, {int minimum = 1000}) =>
      year != null && year >= minimum && year <= 9999 ? year : null;

  static String? _httpsImage(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? value
        : null;
  }

  String? _plainDescription(String? value) {
    if (value == null) return null;
    final plain = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return plain.isEmpty ? null : plain;
  }
}
