import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_catalog_repository.dart';
import '../../domain/catalog/anime_summary.dart';

import 'anilist_detail_fields.dart';

const _graphqlEndpoint = 'https://graphql.anilist.co';
const _searchAnimeQuery = r'''
query SearchAnime($search: String!, $page: Int!, $perPage: Int!) {
  Page(page: $page, perPage: $perPage) {
    media(search: $search, type: ANIME) {
      ...AnimeSummaryFields
    }
  }
}
fragment AnimeSummaryFields on Media {
  id
  idMal
  title { romaji english native }
  coverImage { extraLarge }
  bannerImage
  description(asHtml: false)
  genres
  status
  format
  season
  seasonYear
  startDate { year month day }
  endDate { year month day }
  averageScore
  popularity
}
''';

const _browseAnimeQuery = r'''
query BrowseAnime($sort: [MediaSort!]!, $page: Int!, $perPage: Int!) {
  Page(page: $page, perPage: $perPage) {
    media(sort: $sort, type: ANIME) {
      ...AnimeSummaryFields
    }
  }
}
fragment AnimeSummaryFields on Media {
  id
  idMal
  title { romaji english native }
  coverImage { extraLarge }
  bannerImage
  description(asHtml: false)
  genres
  status
  format
  season
  seasonYear
  startDate { year month day }
  endDate { year month day }
  averageScore
  popularity
}
''';

const _animeByIdQuery = r'''
query AnimeById($id: Int!) {
  Page(page: 1, perPage: 1) {
    media(id: $id, type: ANIME) {
      ...AnimeSummaryFields
    }
  }
}
fragment AnimeSummaryFields on Media {
  id
  idMal
  title { romaji english native }
  coverImage { extraLarge }
  bannerImage
  description(asHtml: false)
  genres
  status
  format
  season
  seasonYear
  startDate { year month day }
  endDate { year month day }
  averageScore
  popularity
  episodes
  studios(isMain: true) { nodes { name } }
  trailer { site id }
  streamingEpisodes { title thumbnail site url }
  characters(perPage: 12, sort: [ROLE, RELEVANCE]) {
    edges {
      role
      node { id name { full } image { medium } }
      voiceActors(language: JAPANESE) { id name { full } languageV2 }
    }
  }
  relations { edges { relationType(version: 2) node { id type title { english romaji native } } } }
}
''';

/// Read-only AniList adapter. Mutations and authenticated requests are absent.
class AniListClient implements AnimeCatalogRepository {
  static final AniListRateLimiter _sharedRateLimiter = AniListRateLimiter();

  AniListClient({
    Dio? dio,
    Duration? requestTimeout,
    AniListRateLimiter? rateLimiter,
  }) : _ownsDio = dio == null,
       _dio = dio ?? _createDio(requestTimeout ?? const Duration(seconds: 10)),
       _rateLimiter = rateLimiter ?? _sharedRateLimiter;

  final bool _ownsDio;
  final Dio _dio;
  final AniListRateLimiter _rateLimiter;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  @override
  Future<Result<AnimeSearchResult>> searchAnimeById(int id) async {
    if (id < 1) {
      return const Failure(
        ValidationAppError('Anime ID must be a positive integer.'),
      );
    }
    try {
      await _rateLimiter.waitForRequestSlot();
      final Response<Object?> response = await _dio.post<Object?>(
        '',
        data: {
          'query': _animeByIdQuery,
          'variables': {'id': id},
        },
        options: Options(
          contentType: Headers.jsonContentType,
          followRedirects: false,
          validateStatus: (status) => status != null,
        ),
      );
      _rateLimiter.updateRateLimit(response.headers);
      return _mapResponse(response);
    } on DioException catch (error) {
      if (_isTimeout(error.type)) return const Failure(TimeoutAppError());
      return const Failure(NetworkError());
    } on Object {
      return const Failure(
        UnknownAppError('AniList response could not be read.'),
      );
    }
  }

  @override
  Future<Result<AnimeSearchResult>> searchAnime(
    String search, {
    int page = 1,
    int perPage = 20,
  }) async {
    final String normalizedSearch = search.trim();
    if (normalizedSearch.isEmpty || !_validPage(page, perPage)) {
      return const Failure(
        ValidationAppError('Anime search parameters are invalid.'),
      );
    }

    try {
      await _rateLimiter.waitForRequestSlot();
      final Response<Object?> response = await _dio.post<Object?>(
        '',
        data: {
          'query': _searchAnimeQuery,
          'variables': {
            'search': normalizedSearch,
            'page': page,
            'perPage': perPage,
          },
        },
        options: Options(
          contentType: Headers.jsonContentType,
          followRedirects: false,
          validateStatus: (status) => status != null,
        ),
      );
      _rateLimiter.updateRateLimit(response.headers);
      return _mapResponse(response);
    } on DioException catch (error) {
      if (_isTimeout(error.type)) {
        return const Failure(TimeoutAppError());
      }
      return const Failure(NetworkError());
    } on Object {
      return const Failure(
        UnknownAppError('AniList response could not be read.'),
      );
    }
  }

  @override
  Future<Result<AnimeSearchResult>> browseAnime({
    AnimeBrowseSort sort = AnimeBrowseSort.popular,
    int page = 1,
    int perPage = 20,
  }) async {
    if (!_validPage(page, perPage)) {
      return const Failure(
        ValidationAppError('Anime browse parameters are invalid.'),
      );
    }
    try {
      await _rateLimiter.waitForRequestSlot();
      final Response<Object?> response = await _dio.post<Object?>(
        '',
        data: {
          'query': _browseAnimeQuery,
          'variables': {
            'sort': [
              sort == AnimeBrowseSort.popular
                  ? 'POPULARITY_DESC'
                  : 'TRENDING_DESC',
            ],
            'page': page,
            'perPage': perPage,
          },
        },
        options: Options(
          contentType: Headers.jsonContentType,
          followRedirects: false,
          validateStatus: (status) => status != null,
        ),
      );
      _rateLimiter.updateRateLimit(response.headers);
      return _mapResponse(response);
    } on DioException catch (error) {
      if (_isTimeout(error.type)) return const Failure(TimeoutAppError());
      return const Failure(NetworkError());
    } on Object {
      return const Failure(
        UnknownAppError('AniList response could not be read.'),
      );
    }
  }

  static bool _validPage(int page, int perPage) =>
      page > 0 && perPage > 0 && perPage <= 50;

  static Dio _createDio(Duration timeout) => Dio(
    BaseOptions(
      baseUrl: _graphqlEndpoint,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  static bool _isTimeout(DioExceptionType type) =>
      type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.sendTimeout;

  Result<AnimeSearchResult> _mapResponse(Response<Object?> response) {
    final int? statusCode = response.statusCode;
    if (statusCode == 429) {
      return Failure(_rateLimiter.rateLimitError(response.headers));
    }
    if (statusCode != null && statusCode >= 500) {
      return const Failure(UnavailableError());
    }
    if (statusCode == 403) {
      return const Failure(UnavailableError());
    }
    if (statusCode == 401) {
      return const Failure(AuthAppError());
    }
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      return const Failure(NetworkError());
    }

    final Map<String, Object?>? body = _asStringMap(response.data);
    if (body == null) {
      return const Failure(
        UnknownAppError('AniList response shape is invalid.'),
      );
    }
    if (body.containsKey('errors')) {
      final List<Object?>? errors = _asObjectList(body['errors']);
      if (errors == null) {
        return const Failure(
          UnknownAppError('AniList error response shape is invalid.'),
        );
      }
      if (errors.isNotEmpty) {
        final int? graphQlStatus = _firstErrorStatus(errors);
        if (graphQlStatus == 429) {
          return Failure(_rateLimiter.rateLimitError(response.headers));
        }
        if (graphQlStatus == 403) {
          return const Failure(UnavailableError());
        }
        if (graphQlStatus == 401) {
          return const Failure(AuthAppError());
        }
        return const Failure(
          UnknownAppError('AniList returned a GraphQL error.'),
        );
      }
    }

    final Map<String, Object?>? data = _asStringMap(body['data']);
    final Map<String, Object?>? page = _asStringMap(data?['Page']);
    final List<Object?>? media = _asObjectList(page?['media']);
    if (media == null) {
      return const Failure(
        UnknownAppError('AniList response shape is invalid.'),
      );
    }

    final List<AnimeSummary> items = [];
    for (final Object? entry in media) {
      try {
        items.add(_mapAnime(entry));
      } on Object {
        continue;
      }
    }
    if (items.isEmpty && media.isNotEmpty) {
      return const Failure(
        UnknownAppError('AniList result could not be mapped.'),
      );
    }
    return Success(
      AnimeSearchResult(
        items: List.unmodifiable(items),
        source: AnimeSearchSource.anilist,
      ),
    );
  }

  /// Optional AniList fields that fail validation are dropped, not the anime.
  static T? _lenient<T>(T? Function() read) {
    try {
      return read();
    } on FormatException {
      return null;
    }
  }

  AnimeSummary _mapAnime(Object? value) {
    final Map<String, Object?>? media = _asStringMap(value);
    final int? id = media?['id'] is int ? media!['id'] as int : null;
    final Map<String, Object?>? title = _asStringMap(media?['title']);
    if (id == null || id < 1) {
      throw const FormatException('AniList media id is invalid.');
    }
    return AnimeSummary(
      id: id,
      romajiTitle: _optionalString(title?['romaji']),
      englishTitle: _optionalString(title?['english']),
      nativeTitle: _optionalString(title?['native']),
      coverImageUrl: _lenient(() => _coverImageUrl(media?['coverImage'])),
      bannerImageUrl: _lenient(() => _optionalUrl(media?['bannerImage'])),
      description: _lenient(() => _strictOptionalString(media?['description'])),
      genres: _lenient(() => _stringList(media?['genres'])) ?? const [],
      status: _lenient(() => _strictOptionalString(media?['status'])),
      format: _lenient(() => _strictOptionalString(media?['format'])),
      season: _lenient(() => _strictOptionalString(media?['season'])),
      seasonYear: _lenient(() => _optionalPositiveInt(media?['seasonYear'])),
      startDate: _lenient(() => _releaseDate(media?['startDate'])),
      endDate: _lenient(() => _releaseDate(media?['endDate'])),
      score: _lenient(() => _optionalScore(media?['averageScore'])),
      popularity: _lenient(() => _optionalNonNegativeInt(media?['popularity'])),
      detail: media!.containsKey('characters')
          ? _lenient(() => decodeAniListDetails(media))
          : null,
    );
  }

  AnimeReleaseDate? _releaseDate(Object? value) {
    if (value == null) return null;
    final Map<String, Object?>? date = _asStringMap(value);
    if (date == null) throw const FormatException('AniList date is invalid.');
    final int? year = _optionalPositiveInt(date['year']);
    final int? month = _optionalPositiveInt(date['month']);
    final int? day = _optionalPositiveInt(date['day']);
    if (!_optionalIntIsValid(date['year']) ||
        !_optionalIntIsValid(date['month']) ||
        !_optionalIntIsValid(date['day']) ||
        (month != null && month > 12) ||
        (day != null && day > 31)) {
      throw const FormatException('AniList date parts are invalid.');
    }
    return AnimeReleaseDate(year: year, month: month, day: day);
  }

  static List<String> _stringList(Object? value) {
    if (value == null) return const [];
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      throw const FormatException('AniList genres are invalid.');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  static String? _optionalUrl(Object? value) {
    if (value != null && value is! String) {
      throw const FormatException('AniList image URL is invalid.');
    }
    final String? text = value as String?;
    if (text == null) return null;
    final Uri? uri = Uri.tryParse(text);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('AniList image URL is invalid.');
    }
    return text;
  }

  static String? _strictOptionalString(Object? value) {
    if (value != null && value is! String) {
      throw const FormatException('AniList text metadata is invalid.');
    }
    return _optionalString(value);
  }

  static String? _coverImageUrl(Object? value) {
    if (value == null) return null;
    final Map<String, Object?>? image = _asStringMap(value);
    if (image == null) {
      throw const FormatException('AniList cover image is invalid.');
    }
    return _optionalUrl(image['extraLarge']);
  }

  static double? _optionalScore(Object? value) {
    if (value == null) return null;
    if (value is! num || value < 0 || value > 100) {
      throw const FormatException('AniList score is invalid.');
    }
    return value.toDouble();
  }

  static int? _optionalNonNegativeInt(Object? value) {
    if (value == null) return null;
    if (value is! int || value < 0) {
      throw const FormatException('AniList popularity is invalid.');
    }
    return value;
  }

  static int? _optionalPositiveInt(Object? value) => value == null
      ? null
      : value is int && value > 0
      ? value
      : null;

  static bool _optionalIntIsValid(Object? value) =>
      value == null || value is int && value > 0;

  static Map<String, Object?>? _asStringMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    final Map<String, Object?> result = {};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      if (entry.key is! String) {
        return null;
      }
      result[entry.key! as String] = entry.value;
    }
    return result;
  }

  static List<Object?>? _asObjectList(Object? value) =>
      value is List<Object?> ? value : null;

  static String? _optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static int? _firstErrorStatus(List<Object?> errors) {
    for (final Object? error in errors) {
      final Map<String, Object?>? map = _asStringMap(error);
      final Object? status = map?['status'];
      if (status is int) {
        return status;
      }
    }
    return null;
  }

  static Duration? _retryAfter(Headers headers) {
    final String? retryAfter = headers.value('retry-after');
    final int? seconds = retryAfter == null ? null : int.tryParse(retryAfter);
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }
}

/// Shared per-process request gate. Separate adapters should share this gate.
class AniListRateLimiter {
  AniListRateLimiter({
    DateTime Function()? clock,
    Future<void> Function(Duration duration)? delay,
  }) : _clock = clock ?? DateTime.now,
       _delay = delay ?? _defaultDelay;

  final DateTime Function() _clock;
  final Future<void> Function(Duration duration) _delay;
  Future<void> _queue = Future<void>.value();
  DateTime _nextRequestAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  DateTime? _retryUntil;
  Duration _minimumRequestInterval = const Duration(seconds: 2);

  Future<void> waitForRequestSlot() {
    final Future<void> previous = _queue;
    final Completer<void> release = Completer<void>();
    _queue = release.future;
    return _waitAndRelease(previous, release);
  }

  Future<void> _waitAndRelease(
    Future<void> previous,
    Completer<void> release,
  ) async {
    try {
      await previous;
      final DateTime now = _clock().toUtc();
      DateTime target = _nextRequestAt;
      final DateTime? retryUntil = _retryUntil;
      if (retryUntil != null && retryUntil.isAfter(target)) {
        target = retryUntil;
      }
      final Duration wait = target.difference(now);
      if (wait > Duration.zero) {
        await _delay(wait);
      }
      _nextRequestAt = _clock().toUtc().add(_minimumRequestInterval);
    } finally {
      release.complete();
    }
  }

  void updateRateLimit(Headers headers) {
    final String? limitHeader = headers.value('x-ratelimit-limit');
    final int? requestsPerMinute = limitHeader == null
        ? null
        : int.tryParse(limitHeader);
    if (requestsPerMinute != null && requestsPerMinute > 0) {
      _minimumRequestInterval = Duration(
        milliseconds: (Duration.secondsPerMinute * 1000 / requestsPerMinute)
            .ceil(),
      );
    }

    final Duration? retryAfter = AniListClient._retryAfter(headers);
    if (retryAfter != null) {
      _retryUntil = _clock().toUtc().add(retryAfter);
    }
  }

  RateLimitError rateLimitError(Headers headers) {
    final Duration retryAfter =
        AniListClient._retryAfter(headers) ?? const Duration(minutes: 1);
    _retryUntil = _clock().toUtc().add(retryAfter);
    return RateLimitError(retryAfter: retryAfter);
  }

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);
}
