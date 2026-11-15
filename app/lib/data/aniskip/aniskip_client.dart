import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/player/providers/playback_source.dart';
import '../../domain/player/skips/skip_segment.dart';
import '../../domain/player/skips/skip_segment_catalog.dart';
import 'aniskip_response_cache.dart';

typedef AniSkipClock = DateTime Function();

/// Read-only AniSkip v1 adapter. Unknown API types are ignored; only `op` and
/// `ed` are mapped because the official contract documents opening/endings.
final class AniSkipClient implements SkipSegmentCatalog {
  factory AniSkipClient({
    Dio? dio,
    required AniSkipResponseCache cache,
    AniSkipClock? clock,
  }) => AniSkipClient._(dio, cache, clock ?? DateTime.now);

  AniSkipClient._(Dio? dio, this._cache, this._clock)
    : _dio = dio ?? _createDio(),
      _ownsDio = dio == null;

  static const String _baseUrl = 'https://api.aniskip.com/v1';
  static const String _contractVersion = 'v1';
  static const Duration cacheTtl = Duration(days: 7);
  final Dio _dio;
  final bool _ownsDio;
  final AniSkipResponseCache _cache;
  final AniSkipClock _clock;

  static Dio _createDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      followRedirects: false,
      validateStatus: (int? status) => status != null,
      headers: const {'User-Agent': 'Kongroo/0.1'},
    ),
  );

  void close() {
    if (_ownsDio) _dio.close(force: true);
  }

  String cacheKey(MyAnimeListAnimeId id, PlaybackEpisode episode) =>
      '$_contractVersion-${id.value}-${episode.episodeNumber}';

  @override
  Future<SkipCatalogResult> lookup({
    required PlaybackEpisode episode,
    required MyAnimeListAnimeId malAnimeId,
  }) async {
    final String key = cacheKey(malAnimeId, episode);
    CachedAniSkipResponse? cached;
    try {
      cached = await _cache.read(key);
    } on Object {
      return const SkipCatalogFailure(SkipCatalogFailureKind.cache);
    }
    final DateTime now = _clock().toUtc();
    if (cached != null) {
      final Duration age = now.difference(cached.retrievedAt);
      if (!age.isNegative && now.isBefore(cached.expiresAt)) {
        return _parse(cached.body, episode);
      }
      try {
        await _cache.invalidate(key);
      } on Object {
        return const SkipCatalogFailure(SkipCatalogFailureKind.cache);
      }
    }

    try {
      final Response<Object?> response = await _dio.get<Object?>(
        '$_baseUrl/skip-times/${malAnimeId.value}/${episode.episodeNumber}',
        options: Options(
          followRedirects: false,
          validateStatus: (int? status) => status != null,
        ),
      );
      if (response.statusCode == HttpStatus.tooManyRequests) {
        return const SkipCatalogFailure(SkipCatalogFailureKind.rateLimited);
      }
      if (response.statusCode != HttpStatus.ok) {
        return const SkipCatalogFailure(SkipCatalogFailureKind.server);
      }
      final String body = response.data is String
          ? response.data! as String
          : jsonEncode(response.data);
      final SkipCatalogResult parsed = _parse(body, episode);
      if (parsed is SkipCatalogSuccess) {
        try {
          await _cache.write(
            key,
            CachedAniSkipResponse(
              body: body,
              retrievedAt: _clock().toUtc(),
              expiresAt: _clock().toUtc().add(cacheTtl),
            ),
          );
        } on Object {
          return const SkipCatalogFailure(SkipCatalogFailureKind.cache);
        }
      }
      return parsed;
    } on DioException catch (error) {
      return SkipCatalogFailure(
        error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.connectionError
            ? SkipCatalogFailureKind.network
            : SkipCatalogFailureKind.server,
      );
    } on Object {
      return const SkipCatalogFailure(SkipCatalogFailureKind.network);
    }
  }

  SkipCatalogResult _parse(String body, PlaybackEpisode episode) {
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> ||
          decoded['found'] is! bool ||
          decoded['results'] is! List<Object?>) {
        return const SkipCatalogFailure(
          SkipCatalogFailureKind.malformedResponse,
        );
      }
      final List<SkipSegment> segments = [];
      final Set<String> seen = {};
      for (final Object? raw in decoded['results']! as List<Object?>) {
        if (raw is! Map<String, Object?> ||
            raw['skipType'] is! String ||
            raw['interval'] is! Map<String, Object?>) {
          return const SkipCatalogFailure(
            SkipCatalogFailureKind.malformedResponse,
          );
        }
        final String skipType = raw['skipType']! as String;
        final SkipSegmentKind? kind = switch (skipType) {
          'op' => SkipSegmentKind.opening,
          'ed' => SkipSegmentKind.ending,
          _ => null,
        };
        if (kind == null) continue;
        final Map<String, Object?> interval =
            raw['interval']! as Map<String, Object?>;
        final double? start = _number(interval['startTime']);
        final double? end = _number(interval['endTime']);
        if (start == null || end == null || start < 0 || end <= start) {
          return const SkipCatalogFailure(
            SkipCatalogFailureKind.malformedResponse,
          );
        }
        final Duration startTime = Duration(
          microseconds: (start * 1000000).round(),
        );
        final Duration endTime = Duration(
          microseconds: (end * 1000000).round(),
        );
        final String id = raw['skipId'] is String
            ? (raw['skipId']! as String)
            : '$skipType-${startTime.inMilliseconds}-${endTime.inMilliseconds}';
        final String duplicateKey =
            '$skipType:${startTime.inMilliseconds}:${endTime.inMilliseconds}';
        if (!seen.add(duplicateKey)) continue;
        final int? votes = raw['votes'] is int ? raw['votes']! as int : null;
        final int? confirmations = raw['timesToConfirm'] is int
            ? raw['timesToConfirm']! as int
            : null;
        if ((votes != null && votes < 0) ||
            (confirmations != null && confirmations < 0)) {
          return const SkipCatalogFailure(
            SkipCatalogFailureKind.malformedResponse,
          );
        }
        segments.add(
          SkipSegment(
            episode: episode,
            kind: kind,
            start: startTime,
            end: endTime,
            source: SkipSegmentSource.aniskip,
            sourceId: id,
            votes: votes,
            confirmations: confirmations,
          ),
        );
      }
      segments.sort(
        (SkipSegment a, SkipSegment b) => a.start.compareTo(b.start),
      );
      return SkipCatalogSuccess(List.unmodifiable(segments));
    } on FormatException {
      return const SkipCatalogFailure(SkipCatalogFailureKind.malformedResponse);
    } on ArgumentError {
      return const SkipCatalogFailure(SkipCatalogFailureKind.malformedResponse);
    }
  }

  double? _number(Object? value) {
    if (value is num && value.isFinite) return value.toDouble();
    return null;
  }
}
