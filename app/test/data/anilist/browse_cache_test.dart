import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/anilist/offline_first_anime_catalog.dart';
import 'package:anime_app/data/local_db/app_database.dart';
import 'package:anime_app/domain/catalog/anime_catalog_repository.dart';
import 'package:anime_app/domain/catalog/anime_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Future<File> _databaseFile(String name) async {
  final Directory directory = Directory(
    '${Directory.current.parent.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}browse'
    '${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return File('${directory.path}/$name.sqlite');
}

void main() {
  test(
    'serves a fresh browse feed from disk without asking AniList again',
    () async {
      final AppDatabase database = AppDatabase.atFile(
        await _databaseFile('fresh'),
      );
      final _BrowseRemote remote = _BrowseRemote([Success(_feed(1))]);
      var now = DateTime.utc(2026, 11, 16, 10);
      final OfflineFirstAnimeCatalog catalog = OfflineFirstAnimeCatalog(
        remote: remote,
        database: database,
        clock: () => now,
      );
      try {
        final first = await catalog.browseAnime();
        now = now.add(const Duration(minutes: 5));
        final second = await catalog.browseAnime();

        expect(first, isA<Success<AnimeSearchResult>>());
        expect(
          (second as Success<AnimeSearchResult>).value.source,
          AnimeSearchSource.localCache,
        );
        expect(second.value.items.single.id, 1);
        expect(remote.requests, 1);
      } finally {
        await database.close();
      }
    },
  );

  test(
    'refreshes after the TTL and keeps the stale copy when the network fails',
    () async {
      final AppDatabase database = AppDatabase.atFile(
        await _databaseFile('stale'),
      );
      final _BrowseRemote remote = _BrowseRemote([
        Success(_feed(2)),
        const Failure(NetworkError()),
      ]);
      var now = DateTime.utc(2026, 11, 16, 10);
      final OfflineFirstAnimeCatalog catalog = OfflineFirstAnimeCatalog(
        remote: remote,
        database: database,
        clock: () => now,
      );
      try {
        await catalog.browseAnime();
        now = now.add(OfflineFirstAnimeCatalog.browseTtl);
        final Result<AnimeSearchResult> stale = await catalog.browseAnime();

        expect(remote.requests, 2);
        final AnimeSearchResult value =
            (stale as Success<AnimeSearchResult>).value;
        expect(value.source, AnimeSearchSource.localCache);
        expect(value.items.single.id, 2);
        expect(value.refreshError, isA<NetworkError>());
      } finally {
        await database.close();
      }
    },
  );

  test('without any cached feed a network failure stays visible', () async {
    final AppDatabase database = AppDatabase.atFile(
      await _databaseFile('empty'),
    );
    final OfflineFirstAnimeCatalog catalog = OfflineFirstAnimeCatalog(
      remote: _BrowseRemote([const Failure(NetworkError())]),
      database: database,
      clock: () => DateTime.utc(2026, 11, 16),
    );
    try {
      final Result<AnimeSearchResult> result = await catalog.browseAnime(
        sort: AnimeBrowseSort.trending,
      );
      expect(result, isA<Failure<AnimeSearchResult>>());
    } finally {
      await database.close();
    }
  });

  test('an empty remote page never overwrites a useful cached feed', () async {
    final AppDatabase database = AppDatabase.atFile(
      await _databaseFile('empty-page'),
    );
    var now = DateTime.utc(2026, 11, 16, 10);
    final _BrowseRemote remote = _BrowseRemote([
      Success(_feed(3)),
      const Success(
        AnimeSearchResult(items: [], source: AnimeSearchSource.anilist),
      ),
      const Failure(NetworkError()),
    ]);
    final OfflineFirstAnimeCatalog catalog = OfflineFirstAnimeCatalog(
      remote: remote,
      database: database,
      clock: () => now,
    );
    try {
      await catalog.browseAnime();
      now = now.add(OfflineFirstAnimeCatalog.browseTtl);
      await catalog.browseAnime();
      now = now.add(OfflineFirstAnimeCatalog.browseTtl);
      final Result<AnimeSearchResult> last = await catalog.browseAnime();

      expect((last as Success<AnimeSearchResult>).value.items.single.id, 3);
    } finally {
      await database.close();
    }
  });
}

AnimeSearchResult _feed(int id) => AnimeSearchResult(
  items: [AnimeSummary(id: id, romajiTitle: 'Feed $id')],
  source: AnimeSearchSource.anilist,
);

final class _BrowseRemote implements AnimeCatalogRepository {
  _BrowseRemote(this._responses);

  final List<Result<AnimeSearchResult>> _responses;
  int requests = 0;

  @override
  Future<Result<AnimeSearchResult>> browseAnime({
    AnimeBrowseSort sort = AnimeBrowseSort.popular,
    int page = 1,
    int perPage = 20,
  }) async {
    final Result<AnimeSearchResult> response =
        _responses[requests < _responses.length
            ? requests
            : _responses.length - 1];
    requests++;
    return response;
  }

  @override
  Future<Result<AnimeSearchResult>> searchAnime(
    String search, {
    int page = 1,
    int perPage = 20,
  }) => throw UnimplementedError();

  @override
  Future<Result<AnimeSearchResult>> searchAnimeById(int id) =>
      throw UnimplementedError();
}
