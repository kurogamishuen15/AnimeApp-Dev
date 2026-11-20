import 'external_anime_id.dart';
import 'provider_anime_metadata.dart';
import 'provider_result.dart';

/// One page of the episode index for a title.
///
/// The index answers "which episodes exist" only. It never returns playable
/// URLs, so a listed episode is not a source and must not be shown as playable.
final class EpisodeIndexPage {
  EpisodeIndexPage({
    required Iterable<ProviderEpisodeMetadata> episodes,
    required this.totalCount,
    required this.hasMore,
    this.nextOffset,
  }) : episodes = List.unmodifiable(episodes) {
    if (totalCount != null && totalCount! < 0) {
      throw ArgumentError('Episode index total must not be negative.');
    }
  }

  final List<ProviderEpisodeMetadata> episodes;
  final int? totalCount;
  final bool hasMore;
  final int? nextOffset;
}

/// Port for public episode indexes (for example Kitsu) that are reached
/// without an AniList account. Source providers and host resolvers stay apart.
abstract interface class EpisodeIndexProvider {
  MetadataProviderId get id;

  Future<ProviderResult<EpisodeIndexPage>> listEpisodes(
    ExternalAnimeId anime, {
    int offset = 0,
    int limit = 20,
  });
}
