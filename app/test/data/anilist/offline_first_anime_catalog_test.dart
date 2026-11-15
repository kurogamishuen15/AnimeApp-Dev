import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/anilist/anilist_client.dart';
import 'package:anime_app/data/anilist/offline_first_anime_catalog.dart';
import 'package:anime_app/data/local_db/app_database.dart';
import 'package:anime_app/data/local_db/drift_anilist_detail_cache.dart';
import 'package:anime_app/domain/catalog/anime_catalog_repository.dart';
import 'package:anime_app/domain/catalog/anime_detail_metadata.dart';
import 'package:anime_app/domain/catalog/anime_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Directory> _temporaryDatabaseDirectory() async {
  final Directory appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app')) {
    throw StateError('F1.8 tests must run from app/.');
  }
  final Directory projectDirectory = appDirectory.parent;
  if (!File('${appDirectory.path}/pubspec.yaml').existsSync() ||
      !File('${projectDirectory.path}/AGENTS.md').existsSync() ||
      !Directory('${projectDirectory.path}/.git').existsSync()) {
    throw StateError('Could not verify the project root for F1.8 cleanup.');
  }
  final Directory directory = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}f1_8'
    '${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

AniListClient _createClient(Dio dio) =>
    AniListClient(dio: dio, rateLimiter: AniListRateLimiter());

void main() {
  test(
    'legacy detail cache refreshes once to obtain episode metadata',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final database = AppDatabase.atFile(
        File('${directory.path}/legacy-detail.sqlite'),
      );
      final now = DateTime.utc(2026, 11, 14);
      final remote = _EpisodeCatalog();
      final repository = OfflineFirstAnimeCatalog(
        remote: remote,
        database: database,
        clock: () => now,
      );
      try {
        await DriftAniListDetailCache(database).write(
          7,
          jsonEncode([
            {
              'id': 7,
              'romajiTitle': 'Legacy fixture',
              'detail': {'episodes': 1},
            },
          ]),
          now,
        );

        final refreshed = await repository.searchAnimeById(7);
        expect(refreshed, isA<Success<AnimeSearchResult>>());
        final item =
            (refreshed as Success<AnimeSearchResult>).value.items.single;
        expect(item.detail?.episodes.single.title, 'Episode 1 - Refreshed');
        expect(remote.requests, 1);

        await repository.searchAnimeById(7);
        expect(remote.requests, 1);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('detail cache survives reopen and a stale refresh outage', () async {
    final directory = await _temporaryDatabaseDirectory();
    final file = File('${directory.path}/detail.sqlite');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}'));
    final client = _createClient(dio);
    var database = AppDatabase.atFile(file);
    var now = DateTime.utc(2026, 11, 14);
    var requests = 0;
    String? authorization;
    server.listen((request) async {
      requests++;
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      if (requests == 1) {
        request.response.write('''
          {"data":{"Page":{"media":[{"id":42,"title":{"romaji":"Fixture"},
          "episodes":2,"streamingEpisodes":[{"title":"Episode 1 - Cached",
          "thumbnail":"https://img.test/episode.jpg","site":"Fixture"}],
          "characters":{"edges":[{"node":{"id":1,"name":{"full":"Character"}},
          "voiceActors":[{"id":2,"name":{"full":"Actor"}}]}]},
          "relations":{"edges":[{"relationType":"SEQUEL","node":{"id":43,
          "type":"ANIME","title":{"romaji":"Sequel"}}}]}}]}}}
        ''');
      } else {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        request.response.write('{}');
      }
      await request.response.close();
    });
    OfflineFirstAnimeCatalog catalog() => OfflineFirstAnimeCatalog(
      remote: client,
      database: database,
      clock: () => now,
    );
    try {
      final first = catalog();
      expect(await first.readCachedAnime(42), isNull);
      final results = await Future.wait([
        first.searchAnimeById(42),
        first.searchAnimeById(42),
      ]);
      expect(results, everyElement(isA<Success<AnimeSearchResult>>()));
      expect(requests, 1);
      expect(authorization, isNull);
      await database.close();
      database = AppDatabase.atFile(file);

      final reopened = catalog();
      final cached = (await reopened.readCachedAnime(42))!;
      expect(cached.detail!.characters.single.voiceActors.single.name, 'Actor');
      expect(cached.detail!.relations.single.id, 43);
      expect(cached.detail!.episodeCount, 2);
      expect(cached.detail!.episodeMetadataFetched, isTrue);
      expect(cached.detail!.episodes.single.title, 'Episode 1 - Cached');
      expect(
        cached.detail!.episodes.single.thumbnailUrl,
        'https://img.test/episode.jpg',
      );
      await reopened.searchAnimeById(42);
      expect(requests, 1);

      now = now.add(const Duration(days: 2));
      final result = (await reopened.searchAnimeById(
        42,
      ) as Success<AnimeSearchResult>).value;
      expect(result.source, AnimeSearchSource.localCache);
      expect(result.refreshError, isA<UnavailableError>());
      expect(result.items.single.id, 42);
      expect(requests, 2);
      await server.close(force: true);
      final offlineSearch = (await reopened.searchAnime(
        'Fixture',
      ) as Success<AnimeSearchResult>).value;
      expect(offlineSearch.items.single.id, 42);

      expect(
        await reopened.searchAnimeById(42),
        isA<Success<AnimeSearchResult>>(),
      );
      expect(
        await reopened.searchAnimeById(99),
        isA<Failure<AnimeSearchResult>>(),
      );
    } finally {
      dio.close(force: true);
      await server.close(force: true);
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'persists only the latest user search and returns it after a remote outage',
    () async {
      var requestCount = 0;
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      server.listen((request) {
        unawaited(() async {
          requestCount++;
          await utf8.decoder.bind(request).join();
          if (requestCount <= 2) {
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.headers.set('X-RateLimit-Limit', '60000');
            final int animeId = 320 + requestCount;
            final String title = requestCount == 1
                ? 'Test Anime'
                : 'Other Anime';
            request.response.write(
              jsonEncode({
                'data': {
                  'Page': {
                    'media': [
                      {
                        'id': animeId,
                        'title': {
                          'romaji': title,
                          'english': null,
                          'native': '試験',
                        },
                        'coverImage': {
                          'extraLarge': 'https://img.test/cover.jpg',
                        },
                        'bannerImage': 'https://img.test/banner.jpg',
                        'description': 'Test description',
                        'genres': ['Action', 'Drama'],
                        'status': 'FINISHED',
                        'format': 'TV',
                        'season': 'SPRING',
                        'seasonYear': 2020,
                        'startDate': {'year': 2020, 'month': 4},
                        'endDate': null,
                        'averageScore': 88,
                        'popularity': 450,
                      },
                    ],
                  },
                },
              }),
            );
          } else {
            request.response.statusCode = HttpStatus.serviceUnavailable;
            request.response.headers.contentType = ContentType.json;
            request.response.write('{"errors":[{"status":503}]}');
          }
          await request.response.close();
        }());
      });
      final Dio dio = Dio(
        BaseOptions(baseUrl: 'http://${server.address.address}:${server.port}'),
      );
      final AniListClient client = _createClient(dio);
      final Directory directory = await _temporaryDatabaseDirectory();
      final File file = File('${directory.path}/anime.sqlite');
      var database = AppDatabase.atFile(file);
      var repository = OfflineFirstAnimeCatalog(
        remote: client,
        database: database,
        clock: () => DateTime.utc(2026, 11, 9),
      );

      try {
        final Result<AnimeSearchResult> networkResult = await repository
            .searchAnime('test anime');
        expect(networkResult, isA<Success<AnimeSearchResult>>());
        final AnimeSearchResult networkSearch =
            (networkResult as Success<AnimeSearchResult>).value;
        expect(networkSearch.source, AnimeSearchSource.anilist);
        expect(networkSearch.items.single.id, 321);
        final Result<AnimeSearchResult> replaced = await repository.searchAnime(
          'other anime',
        );
        expect(replaced, isA<Success<AnimeSearchResult>>());
        expect(
          (replaced as Success<AnimeSearchResult>).value.items.single.id,
          322,
        );
        expect(
          await database.select(database.latestAnimeSearch).get(),
          hasLength(1),
        );
        await database.close();

        database = AppDatabase.atFile(file);
        repository = OfflineFirstAnimeCatalog(
          remote: client,
          database: database,
        );
        final Result<AnimeSearchResult> fallback = await repository.searchAnime(
          'other anime',
        );
        expect(fallback, isA<Success<AnimeSearchResult>>());
        final AnimeSearchResult cachedSearch =
            (fallback as Success<AnimeSearchResult>).value;
        expect(cachedSearch.source, AnimeSearchSource.localCache);
        expect(cachedSearch.refreshError, isA<UnavailableError>());
        expect(cachedSearch.items.single.id, 322);
        expect(cachedSearch.items.single.englishTitle, isNull);
        expect(cachedSearch.items.single.nativeTitle, '試験');
        expect(
          cachedSearch.items.single.coverImageUrl,
          'https://img.test/cover.jpg',
        );
        expect(
          cachedSearch.items.single.bannerImageUrl,
          'https://img.test/banner.jpg',
        );
        expect(cachedSearch.items.single.description, 'Test description');
        expect(cachedSearch.items.single.genres, ['Action', 'Drama']);
        expect(cachedSearch.items.single.status, 'FINISHED');
        expect(cachedSearch.items.single.format, 'TV');
        expect(cachedSearch.items.single.season, 'SPRING');
        expect(cachedSearch.items.single.seasonYear, 2020);
        expect(cachedSearch.items.single.startDate?.year, 2020);
        expect(cachedSearch.items.single.startDate?.month, 4);
        expect(cachedSearch.items.single.score, 88);
        expect(cachedSearch.items.single.popularity, 450);
        expect(requestCount, 3);
      } finally {
        await database.close();
        dio.close(force: true);
        await server.close(force: true);
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'does not return cached results for a different search or page',
    () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      server.listen((request) {
        unawaited(() async {
          await utf8.decoder.bind(request).join();
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.headers.set('X-RateLimit-Limit', '60000');
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"errors":[{"status":503}]}');
          await request.response.close();
        }());
      });
      final Dio dio = Dio(
        BaseOptions(baseUrl: 'http://${server.address.address}:${server.port}'),
      );
      final Directory directory = await _temporaryDatabaseDirectory();
      final AppDatabase database = AppDatabase.atFile(
        File('${directory.path}/anime.sqlite'),
      );
      final OfflineFirstAnimeCatalog repository = OfflineFirstAnimeCatalog(
        remote: _createClient(dio),
        database: database,
      );

      try {
        await database
            .into(database.latestAnimeSearch)
            .insert(
              LatestAnimeSearchCompanion.insert(
                slot: 'latest_user_search',
                searchQuery: 'saved query',
                page: 1,
                perPage: 20,
                resultJson: jsonEncode([
                  {
                    'id': 5,
                    'romajiTitle': 'Saved',
                    'englishTitle': null,
                    'nativeTitle': null,
                  },
                ]),
                cachedAt: DateTime.utc(2026, 11, 9),
              ),
            );
        final Result<AnimeSearchResult> differentSearch = await repository
            .searchAnime('other query');
        expect(differentSearch, isA<Failure<AnimeSearchResult>>());
        expect(
          (differentSearch as Failure<AnimeSearchResult>).error,
          isA<UnavailableError>(),
        );
        final Result<AnimeSearchResult> legacy = await repository.searchAnime(
          'saved query',
        );
        expect(legacy, isA<Success<AnimeSearchResult>>());
        final AnimeSummary legacyItem =
            (legacy as Success<AnimeSearchResult>).value.items.single;
        expect(legacyItem.id, 5);
        expect(legacyItem.romajiTitle, 'Saved');
        expect(legacyItem.genres, isEmpty);
        expect(legacyItem.coverImageUrl, isNull);
        final Result<AnimeSearchResult> differentPage = await repository
            .searchAnime('saved query', page: 2);
        expect(differentPage, isA<Failure<AnimeSearchResult>>());
        expect(
          (differentPage as Failure<AnimeSearchResult>).error,
          isA<UnavailableError>(),
        );
      } finally {
        await database.close();
        dio.close(force: true);
        await server.close(force: true);
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'reports corrupt persistent cache instead of presenting empty success',
    () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      server.listen((request) {
        unawaited(() async {
          await utf8.decoder.bind(request).join();
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.headers.set('X-RateLimit-Limit', '60000');
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"errors":[{"status":503}]}');
          await request.response.close();
        }());
      });
      final Dio dio = Dio(
        BaseOptions(baseUrl: 'http://${server.address.address}:${server.port}'),
      );
      final Directory directory = await _temporaryDatabaseDirectory();
      final AppDatabase database = AppDatabase.atFile(
        File('${directory.path}/anime.sqlite'),
      );
      final OfflineFirstAnimeCatalog repository = OfflineFirstAnimeCatalog(
        remote: _createClient(dio),
        database: database,
      );

      try {
        await database
            .into(database.latestAnimeSearch)
            .insert(
              LatestAnimeSearchCompanion.insert(
                slot: 'latest_user_search',
                searchQuery: 'corrupt query',
                page: 1,
                perPage: 20,
                resultJson: '{not json',
                cachedAt: DateTime.utc(2026, 11, 9),
              ),
            );
        final Result<AnimeSearchResult> result = await repository.searchAnime(
          'corrupt query',
        );
        expect(result, isA<Failure<AnimeSearchResult>>());
        expect(
          (result as Failure<AnimeSearchResult>).error,
          isA<StorageError>(),
        );
      } finally {
        await database.close();
        dio.close(force: true);
        await server.close(force: true);
        await directory.delete(recursive: true);
      }
    },
  );
}

final class _EpisodeCatalog implements AnimeCatalogRepository {
  int requests = 0;

  AnimeSearchResult _result() => AnimeSearchResult(
    items: [
      AnimeSummary(
        id: 7,
        romajiTitle: 'Legacy fixture',
        detail: AnimeDetailMetadata(
          episodeCount: 1,
          episodeMetadataFetched: true,
          episodes: [
            AnimeEpisodeMetadata(
              number: 1,
              title: 'Episode 1 - Refreshed',
              thumbnailUrl: 'https://img.test/refreshed.jpg',
            ),
          ],
        ),
      ),
    ],
    source: AnimeSearchSource.anilist,
  );

  @override
  Future<Result<AnimeSearchResult>> searchAnimeById(int id) async {
    requests++;
    return Success(_result());
  }

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
}
