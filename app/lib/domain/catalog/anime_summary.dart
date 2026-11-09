import '../../core/errors/app_error.dart';

/// Domain model for a small, public catalogue search result.
class AnimeSummary {
  const AnimeSummary({
    required this.id,
    this.romajiTitle,
    this.englishTitle,
    this.nativeTitle,
  });

  final int id;
  final String? romajiTitle;
  final String? englishTitle;
  final String? nativeTitle;
}

enum AnimeSearchSource { anilist, localCache }

/// Search data plus its source, so an offline fallback is visible to callers.
class AnimeSearchResult {
  const AnimeSearchResult({
    required this.items,
    required this.source,
    this.refreshError,
  });

  final List<AnimeSummary> items;
  final AnimeSearchSource source;
  final AppError? refreshError;
}
