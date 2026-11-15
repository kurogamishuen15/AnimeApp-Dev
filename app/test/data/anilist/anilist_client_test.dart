import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/anilist/anilist_client.dart';
import 'package:anime_app/domain/catalog/anime_catalog_repository.dart';
import 'package:anime_app/domain/catalog/anime_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

typedef RequestHandler = Future<void> Function(HttpRequest request);

final class LoopbackServer {
  LoopbackServer(this.server);

  final HttpServer server;

  String get baseUrl => 'http://${server.address.address}:${server.port}';

  Future<void> close() => server.close(force: true);
}

Future<LoopbackServer> _startServer(RequestHandler handler) async {
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  server.listen((request) => unawaited(handler(request)));
  return LoopbackServer(server);
}

Future<void> _respond(
  HttpRequest request, {
  int status = HttpStatus.ok,
  required String body,
  Map<String, String> headers = const {},
}) async {
  request.response.statusCode = status;
  request.response.headers.contentType = ContentType.json;
  for (final MapEntry<String, String> header in headers.entries) {
    request.response.headers.set(header.key, header.value);
  }
  request.response.write(body);
  await request.response.close();
}

Map<String, Object?> _map(Object? value) =>
    Map<String, Object?>.from(value! as Map<Object?, Object?>);

AniListClient _createClient(Dio dio) =>
    AniListClient(dio: dio, rateLimiter: AniListRateLimiter());

void main() {
  test(
    'looks up a public anime by exact AniList ID without authentication',
    () async {
      Map<String, Object?>? requestBody;
      String? authorizationHeader;
      final LoopbackServer server = await _startServer((request) async {
        requestBody = _map(jsonDecode(await utf8.decoder.bind(request).join()));
        authorizationHeader = request.headers.value(
          HttpHeaders.authorizationHeader,
        );
        await _respond(
          request,
          body: jsonEncode({
            'data': {
              'Page': {
                'media': [
                  {
                    'id': 21,
                    'title': {'romaji': 'Koe no Katachi', 'english': null},
                    'coverImage': {'extraLarge': 'https://img.test/cover.jpg'},
                    'bannerImage': 'https://img.test/banner.jpg',
                    'episodes': 2,
                    'streamingEpisodes': [
                      {
                        'title': 'Episode 1 - A real title',
                        'thumbnail': 'http://img.test/episode-1.jpg',
                        'site': 'Fixture Stream',
                      },
                    ],
                    'characters': {'edges': <Object?>[]},
                    'relations': {'edges': <Object?>[]},
                  },
                ],
              },
            },
          }),
        );
      });
      final client = _createClient(Dio(BaseOptions(baseUrl: server.baseUrl)));
      try {
        final result = await client.searchAnimeById(21);
        expect(result, isA<Success<AnimeSearchResult>>());
        expect(
          (result as Success<AnimeSearchResult>).value.items.single.id,
          21,
        );
        expect(requestBody?['query'], contains(r'media(id: $id'));
        expect(requestBody?['query'], contains('streamingEpisodes'));
        expect(_map(requestBody?['variables']), {'id': 21});
        expect(authorizationHeader, isNull);
        final item = result.value.items.single;
        expect(item.detail?.episodeCount, 2);
        expect(item.detail?.episodes.single.number, 1);
        expect(item.detail?.episodes.single.title, 'Episode 1 - A real title');
        expect(
          item.detail?.episodes.single.thumbnailUrl,
          'https://img.test/episode-1.jpg',
        );
      } finally {
        client.close();
        await server.close();
      }
    },
  );

  test(
    'POSTs one bounded read query and maps a valid result to domain types',
    () async {
      var requestCount = 0;
      String? requestMethod;
      String? authorizationHeader;
      Map<String, Object?>? requestBody;
      final LoopbackServer server = await _startServer((request) async {
        requestCount++;
        requestMethod = request.method;
        authorizationHeader = request.headers.value(
          HttpHeaders.authorizationHeader,
        );
        requestBody = _map(jsonDecode(await utf8.decoder.bind(request).join()));
        await _respond(
          request,
          body: jsonEncode({
            'data': {
              'Page': {
                'media': [
                  {
                    'id': 21,
                    'title': {
                      'romaji': 'Koe no Katachi',
                      'english': 'A Silent Voice',
                      'native': null,
                    },
                    'coverImage': {
                      'extraLarge': 'https://s4.anilist.co/file/cover.jpg',
                    },
                    'bannerImage': 'https://s4.anilist.co/file/banner.jpg',
                    'description': 'A story about communication.',
                    'genres': ['Drama', 'Romance'],
                    'status': 'FINISHED',
                    'format': 'MOVIE',
                    'season': 'FALL',
                    'seasonYear': 2016,
                    'startDate': {'year': 2016, 'month': 9, 'day': 17},
                    'endDate': {'year': 2016, 'month': 9, 'day': 17},
                    'averageScore': 85,
                    'popularity': 1200,
                  },
                  {'id': 22, 'title': null},
                ],
              },
            },
          }),
        );
      });
      final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
      final AniListClient client = _createClient(dio);

      try {
        final Result<AnimeSearchResult> result = await client.searchAnime(
          '  koe  ',
        );
        expect(result, isA<Success<AnimeSearchResult>>());
        final AnimeSearchResult searchResult =
            (result as Success<AnimeSearchResult>).value;
        final List<AnimeSummary> anime = searchResult.items;
        expect(searchResult.source, AnimeSearchSource.anilist);
        expect(anime, hasLength(2));
        expect(anime.first.id, 21);
        expect(anime.first.englishTitle, 'A Silent Voice');
        expect(anime.first.nativeTitle, isNull);
        expect(
          anime.first.coverImageUrl,
          'https://s4.anilist.co/file/cover.jpg',
        );
        expect(
          anime.first.bannerImageUrl,
          'https://s4.anilist.co/file/banner.jpg',
        );
        expect(anime.first.description, 'A story about communication.');
        expect(anime.first.genres, ['Drama', 'Romance']);
        expect(anime.first.status, 'FINISHED');
        expect(anime.first.format, 'MOVIE');
        expect(anime.first.season, 'FALL');
        expect(anime.first.seasonYear, 2016);
        expect(anime.first.startDate?.year, 2016);
        expect(anime.first.startDate?.month, 9);
        expect(anime.first.score, 85);
        expect(anime.first.popularity, 1200);
        expect(anime.last.id, 22);
        expect(requestCount, 1);
        expect(requestMethod, 'POST');
        expect(authorizationHeader, isNull);
        expect(requestBody?['query'], contains('query SearchAnime'));
        expect(requestBody?['query'], isNot(contains('mutation')));
        expect(_map(requestBody?['variables']), {
          'search': 'koe',
          'page': 1,
          'perPage': 20,
        });
      } finally {
        dio.close(force: true);
        await server.close();
      }
    },
  );

  test(
    'browse requests public popular or trending pages without search text',
    () async {
      final List<Map<String, Object?>> bodies = [];
      final LoopbackServer server = await _startServer((request) async {
        bodies.add(_map(jsonDecode(await utf8.decoder.bind(request).join())));
        await _respond(request, body: '{"data":{"Page":{"media":[]}}}');
      });
      final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
      final AniListClient client = _createClient(dio);

      try {
        final Result<AnimeSearchResult> popular = await client.browseAnime(
          page: 3,
          perPage: 12,
        );
        final Result<AnimeSearchResult> trending = await client.browseAnime(
          sort: AnimeBrowseSort.trending,
        );
        final Result<AnimeSearchResult> invalidPage = await client.browseAnime(
          page: 0,
        );
        expect(popular, isA<Success<AnimeSearchResult>>());
        expect(trending, isA<Success<AnimeSearchResult>>());
        expect(invalidPage, isA<Failure<AnimeSearchResult>>());
        expect(
          (invalidPage as Failure<AnimeSearchResult>).error,
          isA<ValidationAppError>(),
        );
        expect(bodies, hasLength(2));
        expect(bodies.first['query'], contains('query BrowseAnime'));
        expect(bodies.first['query'], contains(r'sort: $sort'));
        expect(_map(bodies.first['variables']), {
          'sort': ['POPULARITY_DESC'],
          'page': 3,
          'perPage': 12,
        });
        expect(_map(bodies.last['variables'])['sort'], ['TRENDING_DESC']);
        expect(bodies.first['query'], isNot(contains('Authorization')));
      } finally {
        dio.close(force: true);
        await server.close();
      }
    },
  );

  test(
    'rejects invalid optional metadata instead of accepting corrupt values',
    () async {
      final LoopbackServer server = await _startServer(
        (request) => _respond(
          request,
          body: '{"data":{"Page":{"media":[{"id":1,"averageScore":101}]}}}',
        ),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
      final AniListClient client = _createClient(dio);
      try {
        final Result<AnimeSearchResult> result = await client.searchAnime(
          'invalid',
        );
        expect(result, isA<Failure<AnimeSearchResult>>());
        expect(
          (result as Failure<AnimeSearchResult>).error,
          isA<UnknownAppError>(),
        );
      } finally {
        dio.close(force: true);
        await server.close();
      }
    },
  );

  test('returns successful empty search results', () async {
    final LoopbackServer server = await _startServer(
      (request) => _respond(request, body: '{"data":{"Page":{"media":[]}}}'),
    );
    final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
    final AniListClient client = _createClient(dio);

    try {
      final Result<AnimeSearchResult> result = await client.searchAnime(
        'missing',
      );
      expect(result, isA<Success<AnimeSearchResult>>());
      expect((result as Success<AnimeSearchResult>).value.items, isEmpty);
    } finally {
      dio.close(force: true);
      await server.close();
    }
  });

  test('rejects invalid parameters without sending a request', () async {
    var requestCount = 0;
    final LoopbackServer server = await _startServer((request) async {
      requestCount++;
      await _respond(request, body: '{}');
    });
    final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
    final AniListClient client = _createClient(dio);

    try {
      final Result<AnimeSearchResult> result = await client.searchAnime('  ');
      expect(result, isA<Failure<AnimeSearchResult>>());
      expect(
        (result as Failure<AnimeSearchResult>).error,
        isA<ValidationAppError>(),
      );
      expect(requestCount, 0);
    } finally {
      dio.close(force: true);
      await server.close();
    }
  });

  test('maps HTTP status classes without retrying', () async {
    const cases = <(int, Type)>[
      (HttpStatus.badRequest, NetworkError),
      (HttpStatus.unauthorized, AuthAppError),
      (HttpStatus.forbidden, UnavailableError),
      (HttpStatus.internalServerError, UnavailableError),
      (HttpStatus.serviceUnavailable, UnavailableError),
    ];
    for (final (int status, Type expectedType) in cases) {
      var requestCount = 0;
      final LoopbackServer server = await _startServer((request) async {
        requestCount++;
        await _respond(request, status: status, body: '{"errors":[]}');
      });
      final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
      final AniListClient client = _createClient(dio);

      try {
        final Result<AnimeSearchResult> result = await client.searchAnime(
          'status fixture',
        );
        expect(result, isA<Failure<AnimeSearchResult>>());
        expect(
          (result as Failure<AnimeSearchResult>).error.runtimeType,
          expectedType,
        );
        expect(requestCount, 1, reason: 'status $status must not retry');
      } finally {
        dio.close(force: true);
        await server.close();
      }
    }
  });

  test('maps GraphQL HTTP 200 authentication errors to AuthAppError', () async {
    final LoopbackServer server = await _startServer(
      (request) => _respond(
        request,
        body: '{"errors":[{"status":401}],"data":{"Page":{"media":[]}}}',
      ),
    );
    final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
    final AniListClient client = _createClient(dio);

    try {
      final Result<AnimeSearchResult> result = await client.searchAnime('auth');
      expect(result, isA<Failure<AnimeSearchResult>>());
      expect((result as Failure<AnimeSearchResult>).error, isA<AuthAppError>());
    } finally {
      dio.close(force: true);
      await server.close();
    }
  });

  test('does not forward search POSTs across a redirect', () async {
    var redirectedRequests = 0;
    final LoopbackServer destination = await _startServer((request) async {
      redirectedRequests++;
      await _respond(request, body: '{"data":{"Page":{"media":[]}}}');
    });
    final LoopbackServer redirect = await _startServer(
      (request) => _respond(
        request,
        status: HttpStatus.temporaryRedirect,
        headers: {'Location': '${destination.baseUrl}/capture'},
        body: '{}',
      ),
    );
    final Dio dio = Dio(BaseOptions(baseUrl: redirect.baseUrl));
    final AniListClient client = _createClient(dio);

    try {
      final Result<AnimeSearchResult> result = await client.searchAnime(
        'redirect fixture',
      );
      expect(result, isA<Failure<AnimeSearchResult>>());
      expect((result as Failure<AnimeSearchResult>).error, isA<NetworkError>());
      expect(redirectedRequests, 0);
    } finally {
      dio.close(force: true);
      await redirect.close();
      await destination.close();
    }
  });

  test(
    'uses injected clock and delay for dynamic 90 and 30 per minute limits',
    () async {
      var now = DateTime.utc(2026, 11, 9);
      final List<Duration> waits = [];
      final limiter = AniListRateLimiter(
        clock: () => now,
        delay: (duration) async {
          waits.add(duration);
          now = now.add(duration);
        },
      );

      await limiter.waitForRequestSlot();
      limiter.updateRateLimit(
        Headers.fromMap({
          'x-ratelimit-limit': ['90'],
        }),
      );
      await limiter.waitForRequestSlot();
      await limiter.waitForRequestSlot();
      expect(waits, [
        const Duration(seconds: 2),
        const Duration(milliseconds: 667),
      ]);

      waits.clear();
      limiter.updateRateLimit(
        Headers.fromMap({
          'x-ratelimit-limit': ['30'],
        }),
      );
      await limiter.waitForRequestSlot();
      await limiter.waitForRequestSlot();
      expect(waits, [
        const Duration(milliseconds: 667),
        const Duration(seconds: 2),
      ]);

      limiter.updateRateLimit(
        Headers.fromMap({
          'retry-after': ['30'],
        }),
      );
      await limiter.waitForRequestSlot();
      expect(waits.last, const Duration(seconds: 30));
    },
  );

  test('maps service rate limiting and retry hint to a typed error', () async {
    final LoopbackServer server = await _startServer(
      (request) => _respond(
        request,
        status: HttpStatus.tooManyRequests,
        headers: const {'Retry-After': '30'},
        body: '{"errors":[{"status":429}]}',
      ),
    );
    final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
    final AniListClient client = _createClient(dio);

    try {
      final Result<AnimeSearchResult> result = await client.searchAnime(
        'anime',
      );
      expect(result, isA<Failure<AnimeSearchResult>>());
      final AppError error = (result as Failure<AnimeSearchResult>).error;
      expect(error, isA<RateLimitError>());
      expect((error as RateLimitError).retryAfter, const Duration(seconds: 30));
    } finally {
      dio.close(force: true);
      await server.close();
    }
  });

  test(
    'serializes requests and adapts spacing to the rate-limit header',
    () async {
      final List<DateTime> arrivals = [];
      final LoopbackServer server = await _startServer((request) async {
        arrivals.add(DateTime.now());
        await _respond(
          request,
          headers: const {'X-RateLimit-Limit': '120'},
          body: '{"data":{"Page":{"media":[]}}}',
        );
      });
      final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
      final AniListRateLimiter limiter = AniListRateLimiter();
      final AniListClient firstClient = AniListClient(
        dio: dio,
        rateLimiter: limiter,
      );
      final AniListClient secondClient = AniListClient(
        dio: dio,
        rateLimiter: limiter,
      );

      try {
        await firstClient.searchAnime('one');
        await secondClient.searchAnime('two');
        expect(arrivals, hasLength(2));
        expect(
          arrivals[1].difference(arrivals[0]),
          greaterThanOrEqualTo(const Duration(milliseconds: 450)),
        );
      } finally {
        dio.close(force: true);
        await server.close();
      }
    },
  );

  test(
    'rejects malformed GraphQL data rather than returning empty success',
    () async {
      final LoopbackServer server = await _startServer(
        (request) => _respond(
          request,
          body: '{"data":{"Page":{"media":[{"id":"invalid"}]}}}',
        ),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
      final AniListClient client = _createClient(dio);

      try {
        final Result<AnimeSearchResult> result = await client.searchAnime(
          'anime',
        );
        expect(result, isA<Failure<AnimeSearchResult>>());
        expect(
          (result as Failure<AnimeSearchResult>).error,
          isA<UnknownAppError>(),
        );
      } finally {
        dio.close(force: true);
        await server.close();
      }
    },
  );

  test(
    'rejects malformed GraphQL errors even when partial data exists',
    () async {
      final LoopbackServer server = await _startServer(
        (request) => _respond(
          request,
          body: '{"errors":"invalid","data":{"Page":{"media":[]}}}',
        ),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: server.baseUrl));
      final AniListClient client = _createClient(dio);

      try {
        final Result<AnimeSearchResult> result = await client.searchAnime(
          'anime',
        );
        expect(result, isA<Failure<AnimeSearchResult>>());
        expect(
          (result as Failure<AnimeSearchResult>).error,
          isA<UnknownAppError>(),
        );
      } finally {
        dio.close(force: true);
        await server.close();
      }
    },
  );

  test('maps a local transport timeout to a typed timeout error', () async {
    final LoopbackServer server = await _startServer((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        await _respond(request, body: '{"data":{"Page":{"media":[]}}}');
      } on Object {
        // The test client intentionally times out before this fixture responds.
      }
    });
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: server.baseUrl,
        receiveTimeout: const Duration(milliseconds: 40),
      ),
    );
    final AniListClient client = _createClient(dio);

    try {
      final Result<AnimeSearchResult> result = await client.searchAnime(
        'anime',
      );
      expect(result, isA<Failure<AnimeSearchResult>>());
      expect(
        (result as Failure<AnimeSearchResult>).error,
        isA<TimeoutAppError>(),
      );
    } finally {
      dio.close(force: true);
      await server.close();
    }
  });
}
