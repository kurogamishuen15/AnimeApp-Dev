typedef AnimeVoiceActor = ({int id, String name, String? language});
typedef AnimeCharacter = ({
  int id,
  String name,
  String? imageUrl,
  String? role,
  List<AnimeVoiceActor> voiceActors,
});
typedef RelatedAnime = ({int id, String title, String? relation});
typedef AnimeTrailer = ({String site, String id});

/// Public episode metadata exposed by the catalogue provider.
///
/// This does not represent a playable source. The number and optional title,
/// thumbnail, and site are provider-scoped catalogue data only.
final class AnimeEpisodeMetadata {
  AnimeEpisodeMetadata({
    required this.number,
    required this.title,
    this.thumbnailUrl,
    this.site,
  }) {
    final Uri? thumbnail = thumbnailUrl == null
        ? null
        : Uri.tryParse(thumbnailUrl!);
    if (number < 1 ||
        title.trim().isEmpty ||
        (thumbnailUrl != null &&
            (thumbnail == null ||
                thumbnail.scheme != 'https' ||
                thumbnail.host.isEmpty ||
                thumbnail.userInfo.isNotEmpty))) {
      throw ArgumentError('Anime episode metadata is invalid.');
    }
  }

  final int number;
  final String title;
  final String? thumbnailUrl;
  final String? site;
}

/// Optional public fields fetched for a specific title, not for browse pages.
final class AnimeDetailMetadata {
  const AnimeDetailMetadata({
    this.studios = const [],
    this.trailer,
    this.characters = const [],
    this.relations = const [],
    this.episodes = const [],
    this.episodeMetadataFetched = false,
    this.episodeCount,
  });

  final List<String> studios;
  final AnimeTrailer? trailer;
  final List<AnimeCharacter> characters;
  final List<RelatedAnime> relations;
  final List<AnimeEpisodeMetadata> episodes;
  final bool episodeMetadataFetched;
  final int? episodeCount;
}
