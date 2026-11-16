import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';

/// Stable local identity plus optional provider crosswalks and display aliases.
/// It is safe to construct without a signed-in AniList account.
final class AnimeIdentity {
  AnimeIdentity({
    required this.localId,
    Iterable<ExternalAnimeId> externalIds = const [],
    Iterable<String> titles = const [],
  }) : externalIds = List.unmodifiable(externalIds.toSet()),
       titles = List.unmodifiable(
         titles
             .map((String title) => title.trim())
             .where((String title) => title.isNotEmpty)
             .toSet(),
       ) {
    if (this.externalIds.length > 20 || this.titles.length > 20) {
      throw ArgumentError('Anime identity has too many crosswalks or titles.');
    }
    if (this.titles.any((String title) => title.length > 256)) {
      throw ArgumentError('Anime identity title is too long.');
    }
  }

  final AnimeId localId;
  final List<ExternalAnimeId> externalIds;
  final List<String> titles;

  /// Deterministic key for bounded caches; contains no credentials or URLs.
  String get cacheKey {
    final List<String> external =
        externalIds.map((ExternalAnimeId id) => id.canonicalKey).toList()
          ..sort();
    final List<String> names =
        titles
            .map(_normalizeTitle)
            .where((String title) => title.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return '${localId.value}|${external.join('|')}|${names.join('|')}';
  }

  static String _normalizeTitle(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}
