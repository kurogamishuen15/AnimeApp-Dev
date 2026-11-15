import '../../application/catalog/catalog_service.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_id.dart';
import '../../domain/catalog/external_anime_id.dart';
import '../../domain/catalog/library_entry.dart';
import '../../domain/catalog/provider_anime_metadata.dart';

typedef HomeLoader = Future<Result<HomeContent>> Function();

final class HomeTitle {
  const HomeTitle({
    required this.title,
    this.externalId,
    this.animeId,
    this.libraryStatus,
    this.synopsis,
    this.coverUrl,
    this.bannerUrl,
    this.formatLabel,
    this.seasonLabel,
    this.score,
    this.genres = const [],
    this.airing = false,
    this.metadata,
  });

  final String title;
  final ExternalAnimeId? externalId;
  final AnimeId? animeId;
  final String? synopsis;
  final String? coverUrl;
  final String? bannerUrl;
  final String? formatLabel;
  final String? seasonLabel;
  final int? score;
  final List<String> genres;
  final bool airing;
  final LibraryStatus? libraryStatus;
  final ProviderAnimeMetadata? metadata;
}

final class HomeEpisode {
  const HomeEpisode(this.anime, this.label, this.positionMs, this.durationMs);

  final HomeTitle anime;
  final String label;
  final int positionMs;
  final int? durationMs;

  double? get fraction => durationMs == null ? null : positionMs / durationMs!;
}

typedef HomeShelf = ({String label, List<HomeTitle> titles});

final class HomeContent {
  const HomeContent({
    this.featured,
    this.highlights = const [],
    this.episodes = const [],
    this.watching = const [],
    this.shelves = const [],
    this.offline = false,
  });

  final HomeTitle? featured;
  final List<HomeTitle> highlights;
  final List<HomeEpisode> episodes;
  final List<HomeTitle> watching;
  final List<HomeShelf> shelves;
  final bool offline;

  bool get isEmpty =>
      featured == null &&
      episodes.isEmpty &&
      watching.isEmpty &&
      shelves.isEmpty;
}

/// Joins the existing local catalog and episode-one progress contract for Home.
final class CatalogHomeSource {
  const CatalogHomeSource(this.service);
  final CatalogService service;

  Future<Result<HomeContent>> load() async {
    final catalogFuture = service.browsePopular(limit: 20);
    final trendingFuture = service.browseTrending(limit: 20);
    final libraryFuture = service.loadLibrary();
    final (catalog, trending, library) = await (
      catalogFuture,
      trendingFuture,
      libraryFuture,
    ).wait;
    if (library case Failure<List<CatalogLibraryItem>>(:final error)) {
      return Failure(error);
    }
    final offline =
        catalog is Failure<List<ProviderAnimeMetadata>> &&
        catalog.error is NetworkError;
    if (catalog case Failure<List<ProviderAnimeMetadata>>(:final error)
        when !offline) {
      return Failure(error);
    }
    final libraryItems = (library as Success<List<CatalogLibraryItem>>).value;
    final byExternalId = <String, CatalogLibraryItem>{
      for (final item in libraryItems)
        if (item.metadata case final metadata?)
          metadata.externalId.canonicalKey: item,
    };
    final titles = catalog.fold(
      (items) => items
          .map(
            (item) => _title(item, byExternalId[item.externalId.canonicalKey]),
          )
          .toList(),
      (_) => <HomeTitle>[],
    );
    final trendingTitles = trending.fold(
      (items) => items
          .map(
            (item) => _title(item, byExternalId[item.externalId.canonicalKey]),
          )
          .toList(),
      (_) => <HomeTitle>[],
    );
    final watching = <HomeTitle>[];
    final episodes = <HomeEpisode>[];
    for (final item in libraryItems) {
      final anime = item.metadata == null
          ? HomeTitle(
              title: item.title,
              animeId: item.entry.animeId,
              libraryStatus: item.entry.status,
            )
          : _title(item.metadata!, item);
      if (item.entry.status == LibraryStatus.watching ||
          item.entry.status == LibraryStatus.rewatching) {
        watching.add(anime);
      }
    }
    return Success(
      HomeContent(
        featured: titles.where((item) => item.bannerUrl != null).firstOrNull,
        highlights: titles
            .where((item) => item.bannerUrl != null)
            .take(5)
            .toList(growable: false),

        episodes: episodes,
        watching: watching,
        shelves: [
          (
            label: 'En emisión',
            titles: titles.where((item) => item.airing).toList(),
          ),
          (label: 'Populares', titles: titles),
          (label: 'Tendencias', titles: trendingTitles),
        ],
        offline: offline,
      ),
    );
  }

  HomeTitle _title(
    ProviderAnimeMetadata item, [
    CatalogLibraryItem? libraryItem,
  ]) => HomeTitle(
    title: item.preferredTitle,
    externalId: item.externalId,
    animeId: libraryItem?.entry.animeId,
    libraryStatus: libraryItem?.entry.status,
    synopsis: item.synopsis,
    coverUrl: item.coverImageUrl,
    bannerUrl: item.bannerImageUrl,
    formatLabel: item.format.name == 'unknown'
        ? null
        : item.format.name.toUpperCase(),
    seasonLabel: _seasonLabel(item.season, item.seasonYear),
    score: item.averageScore,
    genres: item.genres,
    airing: item.airingStatus == AnimeAiringStatus.releasing,
    metadata: item,
  );

  String? _seasonLabel(String? season, int? year) {
    if (season == null) return null;
    final label = switch (season.toUpperCase()) {
      'WINTER' => 'Winter',
      'SPRING' => 'Spring',
      'SUMMER' => 'Summer',
      'FALL' => 'Fall',
      _ => season,
    };
    return year == null ? label : '$label $year';
  }
}
