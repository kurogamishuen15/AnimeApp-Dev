import '../../core/result/result.dart';
import 'anime_summary.dart';

enum AnimeBrowseSort { popular, trending }

/// Domain port for user-requested, read-only anime search.
abstract interface class AnimeCatalogRepository {
  Future<Result<AnimeSearchResult>> searchAnimeById(int id);

  Future<Result<AnimeSearchResult>> searchAnime(
    String search, {
    int page = 1,
    int perPage = 20,
  });

  /// Returns a public catalogue page without requiring a search phrase.
  Future<Result<AnimeSearchResult>> browseAnime({
    AnimeBrowseSort sort = AnimeBrowseSort.popular,
    int page = 1,
    int perPage = 20,
  });
}

/// Local snapshots are optional for repositories backed by a persistent cache.
abstract interface class CachedAnimeCatalog {
  Future<AnimeSummary?> readCachedAnime(int id);
}
