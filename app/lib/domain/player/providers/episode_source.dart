import 'package:anime_app/domain/catalog/external_anime_id.dart';

import 'anime_identity.dart';
import 'playback_source.dart';

enum AnimeMatchEvidence { externalId, exactTitle, fuzzy, unknown }

/// A provider-local anime record matched against one requested identity.
final class SourceAnimeMatch {
  SourceAnimeMatch({
    required this.providerId,
    required this.sourceAnimeId,
    required this.title,
    required this.requestedIdentity,
    required this.evidence,
    Iterable<ExternalAnimeId> externalIds = const [],
    this.adapterVersion = '1.0.0',
  }) : externalIds = List.unmodifiable(externalIds.toSet()) {
    if (sourceAnimeId.trim().isEmpty ||
        sourceAnimeId.length > 256 ||
        title.trim().isEmpty ||
        title.length > 256 ||
        adapterVersion.trim().isEmpty) {
      throw ArgumentError('Source anime match is invalid.');
    }
  }

  final PlaybackProviderId providerId;
  final String sourceAnimeId;
  final String title;
  final AnimeIdentity requestedIdentity;
  final AnimeMatchEvidence evidence;
  final List<ExternalAnimeId> externalIds;
  final String adapterVersion;

  /// Accept only exact provider-ID crosswalks or exact normalized titles.
  /// Fuzzy matches are surfaced to the adapter for diagnostics but cannot
  /// silently select a different series for playback.
  bool isConservativeMatch() {
    if (evidence == AnimeMatchEvidence.externalId &&
        requestedIdentity.externalIds.any(externalIds.contains)) {
      return true;
    }
    if (evidence != AnimeMatchEvidence.exactTitle) return false;
    final String sourceTitle = _normalizeTitle(title);
    return sourceTitle.isNotEmpty &&
        requestedIdentity.titles.any(
          (String candidate) => _normalizeTitle(candidate) == sourceTitle,
        );
  }

  static String _normalizeTitle(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Provider-specific episode record; distinct from the app's playback request.
final class EpisodeRef {
  EpisodeRef({
    required this.anime,
    required this.episodeId,
    required this.episodeNumber,
    this.declaredLanguage = 'unknown',
    this.mappingEvidence = 'provider episode index',
  }) {
    if (episodeId.trim().isEmpty ||
        episodeId.length > 256 ||
        episodeNumber < 1 ||
        declaredLanguage.trim().isEmpty ||
        mappingEvidence.trim().isEmpty ||
        mappingEvidence.length > 512) {
      throw ArgumentError('Provider episode reference is invalid.');
    }
  }

  final SourceAnimeMatch anime;
  final String episodeId;
  final int episodeNumber;
  final String declaredLanguage;
  final String mappingEvidence;

  PlaybackProviderId get providerId => anime.providerId;
  String get sourceAnimeId => anime.sourceAnimeId;

  String get cacheKey =>
      '${providerId.value}:${sourceAnimeId.length}:$sourceAnimeId:'
      '$episodeNumber:${episodeId.length}:$episodeId';
}
