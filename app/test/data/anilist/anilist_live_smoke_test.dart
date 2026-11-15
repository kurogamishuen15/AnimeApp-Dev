import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/anilist/anilist_client.dart';
import 'package:anime_app/domain/catalog/anime_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const enabled = bool.fromEnvironment('KONGROO_TEST_ANILIST_LIVE');
  test(
    'public exact ID returns characters, voice actors and relations',
    () async {
      final client = AniListClient();
      try {
        final result = await client.searchAnimeById(151807);
        expect(result, isA<Success<AnimeSearchResult>>());
        final item = (result as Success<AnimeSearchResult>).value.items.single;
        expect(item.id, 151807);
        expect(item.englishTitle, 'Solo Leveling');
        expect(item.detail!.studios, isNotEmpty);
        expect(item.detail!.trailer, isNotNull);
        expect(
          item.detail!.characters.expand((item) => item.voiceActors),
          isNotEmpty,
        );
        expect(item.detail!.relations, isNotEmpty);
      } finally {
        client.close();
      }
    },
    skip: !enabled,
  );
  test('public AniList returns real title, cover and banner', () async {
    final client = AniListClient();
    try {
      final result = await client.searchAnime('Solo Leveling', perPage: 5);
      expect(result, isA<Success<AnimeSearchResult>>());
      final items = (result as Success<AnimeSearchResult>).value.items;
      expect(items, isNotEmpty);
      final solo = items.firstWhere(
        (item) => item.englishTitle == 'Solo Leveling',
      );
      expect(solo.coverImageUrl, startsWith('https://'));
      expect(solo.bannerImageUrl, startsWith('https://'));
      expect(solo.genres, isNotEmpty);
      expect(solo.id, 151807);
    } finally {
      client.close();
    }
  }, skip: !enabled);

  test('public AniList returns real episode metadata without OAuth', () async {
    final client = AniListClient();
    try {
      final result = await client.searchAnimeById(16498);
      expect(result, isA<Success<AnimeSearchResult>>());
      final item = (result as Success<AnimeSearchResult>).value.items.single;
      expect(item.englishTitle, 'Attack on Titan');
      expect(item.detail?.episodeCount, 25);
      expect(item.detail?.episodeMetadataFetched, isTrue);
      expect(item.detail?.episodes, isNotEmpty);
      expect(item.detail?.episodes.first.number, 1);
      expect(item.detail?.episodes.first.thumbnailUrl, startsWith('https://'));
    } finally {
      client.close();
    }
  }, skip: !enabled);
}
