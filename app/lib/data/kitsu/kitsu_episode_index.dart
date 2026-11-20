import 'package:dio/dio.dart';

import '../../domain/catalog/episode_index_provider.dart';
import '../../domain/catalog/external_anime_id.dart';
import '../../domain/catalog/metadata_provenance.dart';
import '../../domain/catalog/provider_anime_metadata.dart';
import '../../domain/catalog/provider_result.dart';

/// Public Kitsu episode index, reached without an account. AniList IDs are
/// mapped through Kitsu's public `mappings` endpoint; only episode numbers,
/// titles and HTTPS thumbnails are read. No playable URL is requested.
final class KitsuEpisodeIndex implements EpisodeIndexProvider {
  KitsuEpisodeIndex({
    required this._dio,
    DateTime Function()? clock,
    this.cacheTtl = const Duration(hours: 6),
  }) : _clock = clock ?? DateTime.now;

  factory KitsuEpisodeIndex.public({DateTime Function()? clock}) =>
      KitsuEpisodeIndex(
        dio: Dio(
          BaseOptions(
            baseUrl: 'https://kitsu.io/api/edge',
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 10),
            headers: const {'Accept': 'application/vnd.api+json'},
          ),
        ),
        clock: clock,
      );

  static final MetadataProviderId providerId = MetadataProviderId('kitsu');
  static const int _maxCachedPages = 64;
  static const int _maxPageSize = 20;

  final Dio _dio;
  final DateTime Function() _clock;
  final Duration cacheTtl;
  final Map<int, _Cached<String?>> _mappings = {};
  final Map<String, _Cached<EpisodeIndexPage>> _pages = {};

  @override
  MetadataProviderId get id => providerId;

  @override
  Future<ProviderResult<EpisodeIndexPage>> listEpisodes(
    ExternalAnimeId anime, {
    int offset = 0,
    int limit = 20,
  }) async {
    final int? anilistId = anime.providerId.value == 'anilist'
        ? int.tryParse(anime.value)
        : null;
    if (anilistId == null || anilistId < 1 || offset < 0 || limit < 1) {
      return const ProviderNoResults();
    }
    final int pageSize = limit.clamp(1, _maxPageSize);
    try {
      final String? kitsuId = await _kitsuIdFor(anilistId);
      if (kitsuId == null) return const ProviderNoResults();
      final String pageKey = '$kitsuId:$offset:$pageSize';
      final _Cached<EpisodeIndexPage>? cached = _pages[pageKey];
      if (cached != null && _fresh(cached.at)) {
        return ProviderSuccess(cached.value);
      }
      final Response<Object?> response = await _dio.get<Object?>(
        '/anime/$kitsuId/episodes',
        queryParameters: {
          'page[limit]': pageSize,
          'page[offset]': offset,
          'sort': 'number',
        },
      );
      final EpisodeIndexPage? page = _parsePage(
        anime,
        response.data,
        _clock().toUtc(),
        offset,
      );
      if (page == null) {
        return const ProviderFailure(ProviderFailureKind.invalidResponse);
      }
      _remember(_pages, pageKey, page);
      return ProviderSuccess(page);
    } on DioException catch (error) {
      return _failure(error);
    }
  }

  Future<String?> _kitsuIdFor(int anilistId) async {
    final _Cached<String?>? cached = _mappings[anilistId];
    if (cached != null && _fresh(cached.at)) return cached.value;
    final Response<Object?> response = await _dio.get<Object?>(
      '/mappings',
      queryParameters: {
        'filter[externalSite]': 'anilist/anime',
        'filter[externalId]': anilistId,
        'include': 'item',
      },
    );
    final String? kitsuId = _mappedAnimeId(response.data);
    _remember(_mappings, anilistId, kitsuId);
    return kitsuId;
  }

  bool _fresh(DateTime at) => _clock().difference(at) < cacheTtl;

  void _remember<K, V>(Map<K, _Cached<V>> cache, K key, V value) {
    cache.remove(key);
    cache[key] = _Cached(value, _clock());
    while (cache.length > _maxCachedPages) {
      cache.remove(cache.keys.first);
    }
  }

  static String? _mappedAnimeId(Object? body) {
    final Map<String, Object?> root = _map(body);
    final List<Object?> data = _list(root['data']);
    if (data.length != 1) return null;
    final Map<String, Object?> item = _map(
      _map(_map(data.first)['relationships'])['item'],
    );
    final Map<String, Object?> target = _map(item['data']);
    if (target['type'] != 'anime') return null;
    final Object? id = target['id'];
    return id is String && RegExp(r'^\d{1,12}$').hasMatch(id) ? id : null;
  }

  static EpisodeIndexPage? _parsePage(
    ExternalAnimeId anime,
    Object? body,
    DateTime retrieved,
    int offset,
  ) {
    final Map<String, Object?> root = _map(body);
    final Object? data = root['data'];
    if (data is! List<Object?>) return null;
    final List<ProviderEpisodeMetadata> episodes = [];
    for (final Object? entry in data) {
      final ProviderEpisodeMetadata? episode = _episode(
        anime,
        entry,
        retrieved,
      );
      if (episode != null) episodes.add(episode);
    }
    final Object? count = _map(root['meta'])['count'];
    return EpisodeIndexPage(
      episodes: episodes,
      totalCount: count is int && count >= 0 ? count : null,
      hasMore: data.isNotEmpty && _map(root['links'])['next'] is String,
      nextOffset: offset + data.length,
    );
  }

  static ProviderEpisodeMetadata? _episode(
    ExternalAnimeId anime,
    Object? entry,
    DateTime retrieved,
  ) {
    try {
      final Map<String, Object?> record = _map(entry);
      final Object? id = record['id'];
      final Map<String, Object?> attributes = _map(record['attributes']);
      final Object? number = attributes['number'];
      if (id is! String || id.isEmpty || number is! int || number < 1) {
        return null;
      }
      final Object? title = attributes['canonicalTitle'];
      final Object? thumbnail = _map(attributes['thumbnail'])['original'];
      return ProviderEpisodeMetadata(
        animeId: anime,
        externalEpisodeId: id,
        episodeNumber: number,
        title: title is String && title.trim().isNotEmpty ? title.trim() : null,
        thumbnailUrl: thumbnail is String && thumbnail.startsWith('https://')
            ? thumbnail
            : null,
        site: 'kitsu',
        provenance: MetadataProvenance(
          externalId: anime,
          retrievedAtUtc: retrieved,
        ),
      );
    } on ArgumentError {
      return null;
    }
  }

  static ProviderFailure<EpisodeIndexPage> _failure(DioException error) {
    final int? status = error.response?.statusCode;
    if (status == 404) {
      return const ProviderFailure(ProviderFailureKind.unavailable);
    }
    if (status == 429) {
      return const ProviderFailure(ProviderFailureKind.rateLimited);
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => const ProviderFailure(
        ProviderFailureKind.timeout,
      ),
      DioExceptionType.connectionError => const ProviderFailure(
        ProviderFailureKind.network,
      ),
      _ => const ProviderFailure(ProviderFailureKind.unavailable),
    };
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is Map<String, dynamic>) return Map<String, Object?>.from(value);
    if (value is Map<Object?, Object?>) {
      return Map<String, Object?>.from(value.cast<String, Object?>());
    }
    return const {};
  }

  static List<Object?> _list(Object? value) =>
      value is List<Object?> ? value : const [];
}

final class _Cached<T> {
  const _Cached(this.value, this.at);
  final T value;
  final DateTime at;
}
