import 'anime_detail_metadata.dart';
import 'external_anime_id.dart';
import 'metadata_provenance.dart';

enum AnimeFormat { tv, movie, ova, ona, special, manga, unknown }

enum AnimeAiringStatus {
  finished,
  releasing,
  notYetReleased,
  cancelled,
  unknown,
}

/// Normalized adapter output; provider JSON/DTOs must stop at the adapter.
/// Optional image references stay as HTTPS URLs. Image bytes and retention
/// policy remain outside this domain model.
final class ProviderAnimeMetadata {
  ProviderAnimeMetadata({
    required this.externalId,
    required this.preferredTitle,
    required this.provenance,
    this.romajiTitle,
    Iterable<String> alternativeTitles = const [],
    this.format = AnimeFormat.unknown,
    this.season,
    this.seasonYear,
    this.releaseYear,
    this.endYear,
    this.episodeCount,
    this.synopsis,
    this.coverImageUrl,
    this.bannerImageUrl,
    Iterable<String> genres = const [],
    this.airingStatus = AnimeAiringStatus.unknown,
    this.averageScore,
    this.popularity,
    this.detail,
  }) : genres = List.unmodifiable(genres),
       alternativeTitles = List.unmodifiable(
         alternativeTitles
             .map((String title) => title.trim())
             .where((String title) => title.isNotEmpty),
       ) {
    if (preferredTitle.trim().isEmpty ||
        !RegExp(r'^\d{4}$').hasMatch(releaseYear?.toString() ?? '') &&
            releaseYear != null ||
        !RegExp(r'^\d{4}$').hasMatch(endYear?.toString() ?? '') &&
            endYear != null ||
        (episodeCount != null && episodeCount! < 0) ||
        (averageScore != null && (averageScore! < 0 || averageScore! > 100)) ||
        (seasonYear != null && seasonYear! < 1900) ||
        (popularity != null && popularity! < 0) ||
        !_validImageUrl(coverImageUrl) ||
        !_validImageUrl(bannerImageUrl) ||
        provenance.externalId != externalId) {
      throw ArgumentError('Provider anime metadata is invalid.');
    }
  }

  final ExternalAnimeId externalId;
  final String preferredTitle;
  final String? romajiTitle;
  final List<String> alternativeTitles;
  final AnimeFormat format;
  final String? season;
  final int? seasonYear;
  final int? releaseYear;
  final int? endYear;
  final int? episodeCount;
  final String? synopsis;
  final String? coverImageUrl;
  final String? bannerImageUrl;
  final List<String> genres;
  final AnimeAiringStatus airingStatus;
  final int? averageScore;
  final int? popularity;
  final AnimeDetailMetadata? detail;
  final MetadataProvenance provenance;
}

bool _validImageUrl(String? value) =>
    value == null ||
    (Uri.tryParse(value)?.scheme == 'https' &&
        Uri.tryParse(value)?.host.isNotEmpty == true);

/// Episode numbering is provider-scoped and must not be treated as a
/// cross-provider episode identity.
final class ProviderEpisodeMetadata {
  ProviderEpisodeMetadata({
    required this.animeId,
    required this.externalEpisodeId,
    required this.episodeNumber,
    required this.provenance,
    this.seasonNumber,
    this.title,
    this.thumbnailUrl,
    this.site,
  }) {
    final Uri? thumbnail = thumbnailUrl == null
        ? null
        : Uri.tryParse(thumbnailUrl!);
    if (externalEpisodeId.trim().isEmpty ||
        episodeNumber < 1 ||
        (seasonNumber != null && seasonNumber! < 1) ||
        (thumbnailUrl != null &&
            (thumbnail == null ||
                thumbnail.scheme != 'https' ||
                thumbnail.host.isEmpty ||
                thumbnail.userInfo.isNotEmpty)) ||
        provenance.externalId != animeId) {
      throw ArgumentError('Provider episode metadata is invalid.');
    }
  }

  final ExternalAnimeId animeId;
  final String externalEpisodeId;
  final int episodeNumber;
  final int? seasonNumber;
  final String? title;
  final String? thumbnailUrl;
  final String? site;
  final MetadataProvenance provenance;
}
