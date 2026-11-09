import '../../core/result/result.dart';
import 'anime_summary.dart';

/// Domain port for user-requested, read-only anime search.
abstract interface class AnimeCatalogRepository {
  Future<Result<AnimeSearchResult>> searchAnime(
    String search, {
    int page = 1,
    int perPage = 20,
  });
}
