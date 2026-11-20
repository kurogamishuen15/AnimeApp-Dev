import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_app/data/kitsu/kitsu_episode_index.dart';
import 'package:anime_app/domain/catalog/episode_index_provider.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/provider_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Server {
  _Server(this.server);
  final HttpServer server;
  final List<Uri> requests = <Uri>[];
  String get baseUrl => 'http://${server.address.address}:${server.port}';
  Future<void> close() => server.close(force: true);
}

Future<_Server> _start(
  Future<void> Function(HttpRequest request, _Server server) handler,
) async {
  final HttpServer raw = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final _Server server = _Server(raw);
  raw.listen((request) {
    server.requests.add(request.uri);
    unawaited(handler(request, server));
  });
  return server;
}

Future<void> _json(HttpRequest request, Object body, {int status = 200}) async {
  request.response.statusCode = status;
  request.response.headers.contentType = ContentType(
    'application',
    'vnd.api+json',
  );
  request.response.write(jsonEncode(body));
  await request.response.close();
}

Map<String, Object?> _mapping(String kitsuId) => {
  'data': [
    {
      'id': '254544',
      'type': 'mappings',
      'relationships': {
        'item': {
          'data': {'id': kitsuId, 'type': 'anime'},
        },
      },
    },
  ],
};

Map<String, Object?> _episode(String id, Object number, Object? thumb) => {
  'id': id,
  'type': 'episodes',
  'attributes': {
    'number': number,
    'canonicalTitle': 'Title $id',
    'thumbnail': thumb == null ? null : {'original': thumb},
  },
};

ExternalAnimeId _anilist(int id) =>
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '$id');

KitsuEpisodeIndex _index(_Server server, {DateTime Function()? clock}) =>
    KitsuEpisodeIndex(
      dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
      clock: clock,
    );

void main() {
  test(
    'maps an AniList ID to Kitsu and reads an honest numbered episode index',
    () async {
      final _Server server = await _start((request, server) async {
        if (request.uri.path == '/mappings') {
          await _json(request, _mapping('12'));
          return;
        }
        await _json(request, {
          'data': [
            _episode('901', 1, 'https://img.test/1.jpg'),
            _episode('902', 2, 'http://img.test/2.jpg'),
            _episode('903', 0, null),
            _episode('904', 3, null),
          ],
          'meta': {'count': 26},
          'links': {'next': 'https://kitsu.io/next'},
        });
      });
      final KitsuEpisodeIndex index = _index(server);
      try {
        final ProviderResult<EpisodeIndexPage> result = await index
            .listEpisodes(_anilist(21), limit: 20);

        expect(result, isA<ProviderSuccess<EpisodeIndexPage>>());
        final EpisodeIndexPage page =
            (result as ProviderSuccess<EpisodeIndexPage>).value;
        expect(page.episodes.map((e) => e.episodeNumber), [1, 2, 3]);
        expect(page.episodes.first.thumbnailUrl, 'https://img.test/1.jpg');
        expect(page.episodes[1].thumbnailUrl, isNull);
        expect(page.totalCount, 26);
        expect(page.hasMore, isTrue);

        final Uri mapping = server.requests.first;
        expect(
          mapping.queryParameters['filter[externalSite]'],
          'anilist/anime',
        );
        expect(mapping.queryParameters['filter[externalId]'], '21');
        final Uri episodes = server.requests.last;
        expect(episodes.path, '/anime/12/episodes');
        expect(episodes.queryParameters['page[limit]'], '20');
        expect(episodes.queryParameters['page[offset]'], '0');
      } finally {
        await server.close();
      }
    },
  );

  test('no Kitsu mapping is an empty result, not an episode list', () async {
    final _Server server = await _start((request, server) async {
      await _json(request, <String, Object?>{'data': <Object?>[]});
    });
    final KitsuEpisodeIndex index = _index(server);
    try {
      final ProviderResult<EpisodeIndexPage> result = await index.listEpisodes(
        _anilist(999999),
      );
      expect(result, isA<ProviderNoResults<EpisodeIndexPage>>());
      expect(server.requests, hasLength(1));
    } finally {
      await server.close();
    }
  });

  test('rate limiting is reported as a typed failure', () async {
    final _Server server = await _start((request, server) async {
      await _json(request, <String, Object?>{
        'errors': <Object?>[],
      }, status: 429);
    });
    final KitsuEpisodeIndex index = _index(server);
    try {
      final ProviderResult<EpisodeIndexPage> result = await index.listEpisodes(
        _anilist(21),
      );
      expect(
        (result as ProviderFailure<EpisodeIndexPage>).kind,
        ProviderFailureKind.rateLimited,
      );
    } finally {
      await server.close();
    }
  });

  test('a repeated page is served from the bounded cache', () async {
    final _Server server = await _start((request, server) async {
      if (request.uri.path == '/mappings') {
        await _json(request, _mapping('12'));
        return;
      }
      await _json(request, {
        'data': [_episode('901', 1, null)],
        'meta': {'count': 1},
      });
    });
    var now = DateTime.utc(2026, 11, 16, 10);
    final KitsuEpisodeIndex index = _index(server, clock: () => now);
    try {
      await index.listEpisodes(_anilist(21));
      now = now.add(const Duration(hours: 1));
      await index.listEpisodes(_anilist(21));
      expect(server.requests, hasLength(2));

      now = now.add(const Duration(hours: 6));
      await index.listEpisodes(_anilist(21));
      expect(server.requests, hasLength(4));
    } finally {
      await server.close();
    }
  });

  test('non-AniList identifiers never reach the network', () async {
    final _Server server = await _start((request, server) async {
      await _json(request, <String, Object?>{'data': <Object?>[]});
    });
    final KitsuEpisodeIndex index = _index(server);
    try {
      final ProviderResult<EpisodeIndexPage> result = await index.listEpisodes(
        ExternalAnimeId(providerId: MetadataProviderId('demo'), value: '21'),
      );
      expect(result, isA<ProviderNoResults<EpisodeIndexPage>>());
      expect(server.requests, isEmpty);
    } finally {
      await server.close();
    }
  });
}
