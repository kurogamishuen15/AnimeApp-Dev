import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/anilist/anilist_detail_fields.dart';
import 'package:anime_app/data/anilist/anilist_metadata_provider.dart';
import 'package:anime_app/domain/catalog/anime_catalog_repository.dart';
import 'package:anime_app/domain/catalog/anime_detail_metadata.dart';
import 'package:anime_app/domain/catalog/anime_summary.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/metadata_provenance.dart';
import 'package:anime_app/domain/catalog/metadata_provider.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:anime_app/domain/catalog/provider_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail cache codec preserves an incomplete episode marker', () {
    const detail = AnimeDetailMetadata(
      episodeCount: 12,
      episodeMetadataFetched: false,
    );
    final decoded = decodeAniListDetails(encodeAniListDetails(detail));
    expect(decoded.episodeMetadataFetched, isFalse);
    expect(decoded.episodeCount, 12);
  });

  test('episode contracts reject malformed thumbnail URLs', () {
    expect(
      () => AnimeEpisodeMetadata(
        number: 1,
        title: 'Episode 1',
        thumbnailUrl: 'not a valid URI %',
      ),
      throwsArgumentError,
    );
    final id = ExternalAnimeId(
      providerId: AniListMetadataProvider.providerId,
      value: '21',
    );
    expect(
      () => ProviderEpisodeMetadata(
        animeId: id,
        externalEpisodeId: '21:1',
        episodeNumber: 1,
        thumbnailUrl: 'not a valid URI %',
        provenance: MetadataProvenance(
          externalId: id,
          retrievedAtUtc: DateTime.utc(2026),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('provider preserves existing romaji and end-year fields', () async {
    final AniListMetadataProvider provider = AniListMetadataProvider(
      _SummaryCatalog(),
      clock: () => DateTime.utc(2026),
    );
    final result = await provider.getAnimeByExternalId(
      ExternalAnimeId(
        providerId: AniListMetadataProvider.providerId,
        value: '21',
      ),
    );
    expect(result, isA<ProviderSuccess<ProviderAnimeMetadata>>());
    final ProviderAnimeMetadata metadata =
        (result as ProviderSuccess<ProviderAnimeMetadata>).value;
    expect(metadata.preferredTitle, 'A Silent Voice');
    expect(metadata.romajiTitle, 'Koe no Katachi');
    expect(metadata.releaseYear, 2016);
    expect(metadata.endYear, 2017);
  });

  test(
    'provider exposes public episode metadata without authentication',
    () async {
      final AniListMetadataProvider provider = AniListMetadataProvider(
        _SummaryCatalog(),
        clock: () => DateTime.utc(2026),
      );
      final id = ExternalAnimeId(
        providerId: AniListMetadataProvider.providerId,
        value: '21',
      );
      expect(
        provider.capabilities,
        contains(MetadataCapability.episodeMetadata),
      );
      final result = await provider.getEpisodes(id);
      expect(result, isA<ProviderSuccess<List<ProviderEpisodeMetadata>>>());
      final episode = (result as ProviderSuccess<List<ProviderEpisodeMetadata>>)
          .value
          .single;
      expect(episode.animeId, id);
      expect(episode.episodeNumber, 1);
      expect(episode.title, 'Episode 1 - A real title');
      expect(episode.thumbnailUrl, 'https://img.test/episode.jpg');
    },
  );
}

final class _SummaryCatalog implements AnimeCatalogRepository {
  @override
  Future<Result<AnimeSearchResult>> searchAnimeById(int id) async =>
      Success(_result());

  @override
  Future<Result<AnimeSearchResult>> searchAnime(
    String search, {
    int page = 1,
    int perPage = 20,
  }) async => Success(_result());

  @override
  Future<Result<AnimeSearchResult>> browseAnime({
    AnimeBrowseSort sort = AnimeBrowseSort.popular,
    int page = 1,
    int perPage = 20,
  }) async => Success(_result());

  AnimeSearchResult _result() => AnimeSearchResult(
    items: [
      AnimeSummary(
        id: 21,
        englishTitle: 'A Silent Voice',
        romajiTitle: 'Koe no Katachi',
        startDate: AnimeReleaseDate(year: 2016),
        endDate: AnimeReleaseDate(year: 2017),
        detail: AnimeDetailMetadata(
          episodeCount: 1,
          episodes: [
            AnimeEpisodeMetadata(
              number: 1,
              title: 'Episode 1 - A real title',
              thumbnailUrl: 'https://img.test/episode.jpg',
              site: 'Fixture',
            ),
          ],
        ),
      ),
    ],
    source: AnimeSearchSource.anilist,
  );
}
