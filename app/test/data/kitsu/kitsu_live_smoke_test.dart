import 'package:anime_app/data/kitsu/kitsu_episode_index.dart';
import 'package:anime_app/domain/catalog/episode_index_provider.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/provider_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opt-in: run with KONGROO_TEST_KITSU_LIVE=1. Reads public Kitsu metadata only.
void main() {
  const bool runLive = bool.fromEnvironment('KONGROO_TEST_KITSU_LIVE');

  test(
    'live Kitsu index lists numbered episodes for AniList 21 (One Piece)',
    () async {
      final KitsuEpisodeIndex index = KitsuEpisodeIndex.public();
      final ProviderResult<EpisodeIndexPage> result = await index.listEpisodes(
        ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '21'),
        limit: 5,
      );

      expect(result, isA<ProviderSuccess<EpisodeIndexPage>>());
      final EpisodeIndexPage page =
          (result as ProviderSuccess<EpisodeIndexPage>).value;
      expect(page.episodes, isNotEmpty);
      expect(page.episodes.first.episodeNumber, 1);
      expect(page.totalCount, greaterThan(0));
    },
    skip: runLive ? false : 'Set KONGROO_TEST_KITSU_LIVE=1 to run live.',
  );
}
