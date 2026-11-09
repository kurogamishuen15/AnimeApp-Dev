import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/anilist/anilist_client.dart';
import 'package:anime_app/data/anilist/offline_first_anime_catalog.dart';
import 'package:anime_app/data/local_db/app_database.dart';
import 'package:anime_app/domain/catalog/anime_summary.dart';
import 'package:anime_app/settings/registry/setting_definition.dart';
import 'package:anime_app/settings/registry/settings_registry.dart';
import 'package:anime_app/settings/store/settings_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<Directory> _temporaryDirectory() async {
  final Directory appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app') ||
      !File('${appDirectory.path}/pubspec.yaml').existsSync()) {
    throw StateError('Integration test must run from app/.');
  }
  final Directory projectDirectory = appDirectory.parent;
  if (!File('${projectDirectory.path}/AGENTS.md').existsSync() ||
      !Directory('${projectDirectory.path}/.git').existsSync()) {
    throw StateError('Could not verify project root for test cleanup.');
  }
  final Directory directory = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}f1_12'
    '${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

Future<HttpServer> _server(Future<void> Function(HttpRequest) handler) async {
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  server.listen((request) => unawaited(handler(request)));
  return server;
}

Future<void> _respond(HttpRequest request, int id) async {
  await utf8.decoder.bind(request).join();
  request.response.statusCode = HttpStatus.ok;
  request.response.headers.contentType = ContentType.json;
  request.response.headers.set('X-RateLimit-Limit', '60000');
  request.response.write(
    jsonEncode({
      'data': {
        'Page': {
          'media': [
            {
              'id': id,
              'title': {'romaji': 'Real loopback $id'},
            },
          ],
        },
      },
    }),
  );
  await request.response.close();
}

SettingDefinition<String> _themeSetting() => SettingDefinition<String>(
  key: 'test.integration.theme',
  owner: 'F1.12 integration fixture',
  defaultValue: 'system',
  encode: (value) => value,
  decode: (value) => value! as String,
  isValid: (value) => const {'system', 'dark', 'light'}.contains(value),
);

void main() {
  test(
    'runs settings, SQLite, HTTP, cache, offline, restart and recovery',
    () async {
      final Directory directory = await _temporaryDirectory();
      final File file = File('${directory.path}/anime_app.sqlite');
      var database = AppDatabase.atFile(file);
      final SettingDefinition<String> theme = _themeSetting();
      final SettingsRegistry registry = SettingsRegistry()..register(theme);
      var settings = SettingsStore(database: database, registry: registry);
      HttpServer? server;
      Dio? dio;
      AniListClient? client;
      var closedDatabase = false;

      try {
        expect(await settings.set(theme, 'dark'), isA<Success<void>>());
        expect((await settings.get(theme) as Success<String>).value, 'dark');

        server = await _server((request) => _respond(request, 1401));
        dio = Dio(
          BaseOptions(
            baseUrl: 'http://${server.address.address}:${server.port}',
          ),
        );
        client = AniListClient(dio: dio, rateLimiter: AniListRateLimiter());
        var catalog = OfflineFirstAnimeCatalog(
          remote: client,
          database: database,
          clock: () => DateTime.utc(2026, 11, 9),
        );
        final Result<AnimeSearchResult> online = await catalog.searchAnime(
          'integration anime',
        );
        expect(online, isA<Success<AnimeSearchResult>>());
        final AnimeSearchResult onlineResult =
            (online as Success<AnimeSearchResult>).value;
        expect(onlineResult.source, AnimeSearchSource.anilist);
        expect(onlineResult.items.single.id, 1401);

        await server.close(force: true);
        server = null;
        await database.close();
        closedDatabase = true;

        database = AppDatabase.atFile(file);
        closedDatabase = false;
        settings = SettingsStore(database: database, registry: registry);
        expect((await settings.get(theme) as Success<String>).value, 'dark');
        catalog = OfflineFirstAnimeCatalog(remote: client, database: database);

        final Result<AnimeSearchResult> offline = await catalog.searchAnime(
          'integration anime',
        );
        expect(offline, isA<Success<AnimeSearchResult>>());
        final AnimeSearchResult offlineResult =
            (offline as Success<AnimeSearchResult>).value;
        expect(offlineResult.source, AnimeSearchSource.localCache);
        expect(offlineResult.refreshError, isA<NetworkError>());
        expect(offlineResult.items.single.id, 1401);

        server = await _server((request) => _respond(request, 1402));
        dio.close(force: true);
        dio = Dio(
          BaseOptions(
            baseUrl: 'http://${server.address.address}:${server.port}',
          ),
        );
        client = AniListClient(dio: dio, rateLimiter: AniListRateLimiter());
        catalog = OfflineFirstAnimeCatalog(remote: client, database: database);
        final Result<AnimeSearchResult> recovered = await catalog.searchAnime(
          'integration anime',
        );
        expect(recovered, isA<Success<AnimeSearchResult>>());
        final AnimeSearchResult recoveredResult =
            (recovered as Success<AnimeSearchResult>).value;
        expect(recoveredResult.source, AnimeSearchSource.anilist);
        expect(recoveredResult.items.single.id, 1402);

        await database.close();
        closedDatabase = true;
        final sqlite.Database verification = sqlite.sqlite3.open(file.path);
        try {
          expect(
            verification.select('PRAGMA integrity_check').single.values.first,
            'ok',
          );
          expect(
            verification
                .select('SELECT count(*) FROM latest_anime_search')
                .single
                .values
                .single,
            1,
          );
        } finally {
          verification.close();
        }
      } finally {
        client?.close();
        dio?.close(force: true);
        await server?.close(force: true);
        if (!closedDatabase) await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
