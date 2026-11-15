import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../public_site_http.dart';

final PlaybackProviderId animeAv1ProviderId = PlaybackProviderId('animeav1');

/// Adapter for AnimeAV1's public catalog and episode pages.
///
/// The current site returns SvelteKit's public `__data.json` page payload.
/// This adapter decodes that response format and follows only the public iframe
/// URL already present in an episode page. It never executes site scripts or
/// attempts to overcome an HTTP denial.
final class AnimeAv1PlaybackProvider implements PlaybackSourceProvider {
  AnimeAv1PlaybackProvider({required Dio dio})
    : _http = PublicSiteHttp(
        dio: dio,
        allowedHosts: const {'animeav1.com', 'player.zilla-networks.com'},
      );

  final PublicSiteHttp _http;
  static final Uri _base = Uri.https('animeav1.com');

  @override
  PlaybackProviderId get id => animeAv1ProviderId;

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    PlaybackProviderCapability.resolveServer,
  };

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (episode.animeTitles.isEmpty) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.unsupported),
      );
    }
    try {
      final _AnimeAv1Match? anime = await _findAnime(episode, cancellation);
      if (anime == null) return const PlaybackProviderEmpty();
      final Uri detailUri = _base.resolve('/media/${anime.slug}/__data.json');
      final Map<String, Object?> detail = await _getPayload(
        detailUri,
        cancellation,
      );
      final Object? episodesValue = detail['episodes'];
      if (episodesValue is! List) return _invalid();
      final bool hasEpisode = episodesValue.any((Object? value) {
        if (value is! Map) return false;
        final Object? number = value['number'];
        return number is num && number.toInt() == episode.episodeNumber;
      });
      if (!hasEpisode) return const PlaybackProviderEmpty();

      final Uri episodePage = _base.resolve(
        '/media/${anime.slug}/${episode.episodeNumber}',
      );
      final String html = await _http.getText(
        episodePage,
        cancellation: cancellation,
      );
      final Uri? embed = _iframeUrl(html, episodePage);
      if (embed == null) return _invalid();
      final PlaybackSource source = PlaybackSource(
        id: '${anime.slug}:${episode.episodeNumber}',
        providerId: id,
        episode: episode,
        language: 'ja',
        quality: 'auto',
        servers: [
          PlaybackServer(id: 'public-embed-${embed.host}', endpoint: embed),
        ],
      );
      return PlaybackProviderSuccess(List.unmodifiable([source]));
    } on PublicSiteException catch (error) {
      return PlaybackProviderFailed(PlaybackProviderFailure(error.kind));
    } on FormatException {
      return _invalid();
    } on Object {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.unavailable),
      );
    }
  }

  @override
  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolveServer(
    PlaybackSource source,
    PlaybackServer server, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (source.providerId != id || !source.servers.contains(server)) {
      return _invalid();
    }
    try {
      Uri? direct = _directUri(server.endpoint);
      if (direct == null) {
        final String html = await _http.getText(
          server.endpoint,
          cancellation: cancellation,
        );
        direct = _directMedia(html, server.endpoint);
      }
      if (direct == null) {
        return const PlaybackProviderUnsupported(
          PlaybackProviderCapability.resolveServer,
        );
      }
      if (!await _http.isPublicHttpsTarget(direct)) return _invalid();
      return PlaybackProviderSuccess(
        ResolvedPlaybackStream(
          providerId: id,
          sourceId: source.id,
          serverId: server.id,
          uri: direct,
        ),
      );
    } on PublicSiteException catch (error) {
      return PlaybackProviderFailed(PlaybackProviderFailure(error.kind));
    } on Object {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.unavailable),
      );
    }
  }

  Future<_AnimeAv1Match?> _findAnime(
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation,
  ) async {
    for (final String title in episode.animeTitles) {
      final Uri search = _base.replace(
        path: '/catalogo/__data.json',
        queryParameters: {'search': title},
      );
      final Map<String, Object?> payload = await _getPayload(
        search,
        cancellation,
      );
      final Object? results = payload['results'];
      if (results is! List) return null;
      final List<_AnimeAv1Match> exact = results
          .whereType<Map<Object?, Object?>>()
          .where(
            (Map<Object?, Object?> item) =>
                item['title'] is String &&
                _normalizeTitle(item['title'] as String) ==
                    _normalizeTitle(title),
          )
          .map(
            (Map<Object?, Object?> item) => _AnimeAv1Match(
              id: '${item['id']}',
              slug: '${item['slug']}',
              title: item['title'] as String,
            ),
          )
          .where((item) => item.slug.isNotEmpty && item.id.isNotEmpty)
          .toList();
      if (exact.length == 1) return exact.single;
      if (exact.length > 1) {
        throw const PublicSiteException(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }
    }
    return null;
  }

  Future<Map<String, Object?>> _getPayload(
    Uri uri,
    PlaybackCancellationToken cancellation,
  ) async {
    final String body = await _http.getText(uri, cancellation: cancellation);
    final Object? json = jsonDecode(body);
    if (json is! Map<Object?, Object?> || json['nodes'] is! List) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    final List<Object?> nodes = (json['nodes'] as List).cast<Object?>();
    final Map<Object?, Object?>? dataNode = nodes
        .whereType<Map<Object?, Object?>>()
        .lastOrNull;
    final Object? encoded = dataNode?['data'];
    if (encoded is! List) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    final List<Object?> table = encoded.cast<Object?>();
    final Object? decoded = _decode(table, 0, <int>{});
    if (decoded is! Map<Object?, Object?>) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    final Object? result =
        decoded['media'] ?? decoded['results'] ?? decoded['page'];
    return (result is Map<Object?, Object?> ? result : decoded)
        .cast<String, Object?>();
  }

  static Object? _decode(List<Object?> table, int index, Set<int> active) {
    if (index < 0 || index >= table.length || !active.add(index)) return null;
    final Object? value = table[index];
    Object? result;
    if (value is Map<Object?, Object?>) {
      result = <String, Object?>{
        for (final MapEntry<Object?, Object?> entry in value.entries)
          '${entry.key}': entry.value is int
              ? _decode(table, entry.value! as int, active)
              : entry.value,
      };
    } else if (value is List) {
      result = [
        for (final Object? item in value)
          if (item is int) _decode(table, item, active) else item,
      ];
    } else {
      result = value;
    }
    active.remove(index);
    return result;
  }

  static Uri? _iframeUrl(String html, Uri base) {
    final RegExpMatch? match = RegExp(
      r'''<iframe\b[^>]*\bsrc=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (match == null) return null;
    final Uri? parsed = Uri.tryParse(match.group(1)!);
    if (parsed == null) return null;
    final Uri uri = base.resolveUri(parsed);
    return uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty
        ? uri
        : null;
  }

  static Uri? _directMedia(String html, Uri base) {
    final List<RegExp> patterns = [
      RegExp(r'''<source\b[^>]*src=["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''<video\b[^>]*src=["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''\bfile\s*:\s*["']([^"']+)["']''', caseSensitive: false),
    ];
    for (final RegExp pattern in patterns) {
      for (final RegExpMatch match in pattern.allMatches(html)) {
        final String raw = match
            .group(1)!
            .replaceAll(r'\/', '/')
            .replaceAll(r'\u0026', '&')
            .replaceAll('&amp;', '&');
        final Uri? candidate = Uri.tryParse(raw);
        if (candidate == null) continue;
        final Uri resolved = base.resolveUri(candidate);
        if (_directUri(resolved) != null) return resolved;
      }
    }
    return null;
  }

  static Uri? _directUri(Uri uri) {
    final String path = uri.path.toLowerCase();
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !(path.endsWith('.m3u8') || path.endsWith('.mp4'))) {
      return null;
    }
    return uri;
  }

  static String _normalizeTitle(String value) => value.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );

  static PlaybackProviderFailed<T> _invalid<T>() =>
      const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
}

final class _AnimeAv1Match {
  const _AnimeAv1Match({
    required this.id,
    required this.slug,
    required this.title,
  });
  final String id;
  final String slug;
  final String title;
}
