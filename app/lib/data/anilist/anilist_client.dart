import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_catalog_repository.dart';
import '../../domain/catalog/anime_summary.dart';

const _graphqlEndpoint = 'https://graphql.anilist.co';
const _searchAnimeQuery = r'''
query SearchAnime($search: String!, $page: Int!, $perPage: Int!) {
  Page(page: $page, perPage: $perPage) {
    media(search: $search, type: ANIME) {
      id
      title {
        romaji
        english
        native
      }
    }
  }
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
  Future<Result<AnimeSearchResult>> searchAnime(
    String search, {
    int page = 1,
    int perPage = 20,
  }) async {
    final String normalizedSearch = search.trim();
    if (normalizedSearch.isEmpty || page < 1 || perPage < 1 || perPage > 50) {
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

    try {
      return Success(
        AnimeSearchResult(
          items: List.unmodifiable(media.map(_mapAnime)),
          source: AnimeSearchSource.anilist,
        ),
      );
    } on Object {
      return const Failure(
        UnknownAppError('AniList result could not be mapped.'),
      );
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
    );
  }

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
