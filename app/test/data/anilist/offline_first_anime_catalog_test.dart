import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/anilist/anilist_client.dart';
import 'package:anime_app/data/anilist/offline_first_anime_catalog.dart';
import 'package:anime_app/data/local_db/app_database.dart';
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
  test('persists only the latest user search and returns it after a remote outage', () async {
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
          final String title = requestCount == 1 ? 'Test Anime' : 'Other Anime';
          request.response.write(
            '{"data":{"Page":{"media":[{"id":$animeId,"title":{"romaji":"$title","english":null,"native":"試験"}}]}}}',
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
      repository = OfflineFirstAnimeCatalog(remote: client, database: database);
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
      expect(requestCount, 3);
    } finally {
      await database.close();
      dio.close(force: true);
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });

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
