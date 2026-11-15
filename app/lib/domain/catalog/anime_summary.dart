import '../../core/errors/app_error.dart';

import 'anime_detail_metadata.dart';

/// Domain model for a small, public catalogue search result.
class AnimeSummary {
  const AnimeSummary({
    required this.id,
    this.romajiTitle,
    this.englishTitle,
    this.nativeTitle,
    this.coverImageUrl,
    this.bannerImageUrl,
    this.description,
    this.genres = const [],
    this.status,
    this.format,
    this.season,
    this.seasonYear,
    this.startDate,
    this.endDate,
    this.score,
    this.popularity,
    this.detail,
  });

  final int id;
  final String? romajiTitle;
  final String? englishTitle;
  final String? nativeTitle;
  final String? coverImageUrl;
  final String? bannerImageUrl;
  final String? description;
  final List<String> genres;
  final String? status;
  final String? format;
  final String? season;
  final int? seasonYear;
  final AnimeReleaseDate? startDate;
  final AnimeReleaseDate? endDate;
  final double? score;
  final int? popularity;
  final AnimeDetailMetadata? detail;
}

/// AniList dates may contain a year, month, and/or day.
class AnimeReleaseDate {
  const AnimeReleaseDate({this.year, this.month, this.day});

  final int? year;
  final int? month;
  final int? day;
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
