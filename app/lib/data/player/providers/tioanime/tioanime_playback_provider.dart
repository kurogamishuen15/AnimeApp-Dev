import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../public_site_http.dart';

final PlaybackProviderId tioAnimeProviderId = PlaybackProviderId('tioanime');

/// Public-page adapter for TioAnime.
///
/// It uses ordinary HTTPS page requests and only returns media URLs that are
/// already direct or explicitly exposed by an embed page. It does not execute
/// JavaScript, solve challenges, or pass credentials.
final class TioAnimePlaybackProvider implements PlaybackSourceProvider {
  TioAnimePlaybackProvider({required Dio dio})
    : _http = PublicSiteHttp(
        dio: dio,
        allowedHosts: const {
          'tioanime.com',
          'yourupload.com',
          'embedsb.com',
          'ok.ru',
          'mega.nz',
          'hqq.tv',
        },
      );

  final PublicSiteHttp _http;
  static final Uri _base = Uri.https('tioanime.com');

  @override
  PlaybackProviderId get id => tioAnimeProviderId;

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
      final _TioAnimeMatch? anime = await _findAnime(episode, cancellation);
      if (anime == null) return const PlaybackProviderEmpty();
      if (cancellation.isCancelled) return _cancelled();

      final String animeHtml = await _http.getText(
        _base.resolve('/anime/${anime.slug}'),
        cancellation: cancellation,
      );
      final List<int> episodeNumbers = _episodeNumbers(animeHtml);
      if (!episodeNumbers.contains(episode.episodeNumber)) {
        return const PlaybackProviderEmpty();
      }
      final Uri episodePage = _base.resolve(
        '/ver/${anime.slug}-${episode.episodeNumber}',
      );
      final String episodeHtml = await _http.getText(
        episodePage,
        cancellation: cancellation,
      );
      final List<(String, Uri)> servers = _videoServers(episodeHtml);
      if (servers.isEmpty) return const PlaybackProviderEmpty();

      final PlaybackSource source = PlaybackSource(
        id: '${anime.slug}:${episode.episodeNumber}',
        providerId: id,
        episode: episode,
        language: 'es',
        quality: 'auto',
        servers: [
          for (final (String label, Uri endpoint) in servers)
            PlaybackServer(id: _serverId(label, endpoint), endpoint: endpoint),
        ],
      );
      return PlaybackProviderSuccess(List.unmodifiable([source]));
    } on PublicSiteException catch (error) {
      return PlaybackProviderFailed(PlaybackProviderFailure(error.kind));
    } on FormatException {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
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
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
    if (cancellation.isCancelled) return _cancelled();
    try {
      Uri direct = server.endpoint;
      if (!_isMediaUri(direct)) {
        final String embed = await _http.getText(
          server.endpoint,
          cancellation: cancellation,
        );
        final Uri? extracted = _extractDirectMedia(embed, server.endpoint);
        if (extracted == null) {
          return const PlaybackProviderUnsupported(
            PlaybackProviderCapability.resolveServer,
          );
        }
        direct = extracted;
      }
      if (!await _http.isPublicHttpsTarget(direct)) {
        return const PlaybackProviderFailed(
          PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
        );
      }
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

  Future<_TioAnimeMatch?> _findAnime(
    PlaybackEpisode episode,
    PlaybackCancellationToken cancellation,
  ) async {
    for (final String title in episode.animeTitles) {
      final Uri search = _base.replace(
        path: '/directorio',
        queryParameters: {'q': title, 'p': '1'},
      );
      final String html = await _http.getText(
        search,
        cancellation: cancellation,
      );
      final List<_TioAnimeMatch> matches = _searchCards(html)
          .where(
            (item) => _normalizeTitle(item.title) == _normalizeTitle(title),
          )
          .toList();
      if (matches.length == 1) return matches.single;
      if (matches.length > 1) {
        throw const PublicSiteException(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }
    }
    return null;
  }

  static List<_TioAnimeMatch> _searchCards(String html) {
    final List<_TioAnimeMatch> results = [];
    final RegExp cards = RegExp(
      r'''<article\b[^>]*class=["'][^"']*\banime\b[^"']*["'][^>]*>(.*?)</article>''',
      caseSensitive: false,
      dotAll: true,
    );
    final RegExp link = RegExp(
      r'''<a\b[^>]*href=["'](/anime/([a-z0-9-]+))["'][^>]*>(.*?)</a>''',
      caseSensitive: false,
      dotAll: true,
    );
    final RegExp title = RegExp(
      r'''<h[1-6]\b[^>]*class=["'][^"']*\btitle\b[^"']*["'][^>]*>(.*?)</h[1-6]>''',
      caseSensitive: false,
      dotAll: true,
    );
    for (final RegExpMatch card in cards.allMatches(html)) {
      final String body = card.group(1)!;
      final RegExpMatch? item = link.firstMatch(body);
      final RegExpMatch? titleMatch = title.firstMatch(body);
      if (item == null || titleMatch == null) continue;
      results.add(
        _TioAnimeMatch(
          slug: item.group(2)!,
          title: _plainText(titleMatch.group(1)!),
        ),
      );
    }
    return results;
  }

  static List<int> _episodeNumbers(String html) {
    final RegExpMatch? slugMatch = RegExp(
      r'''var\s+anime_info\s*=\s*\[\s*["'][^"']+["']\s*,\s*["']([a-z0-9-]+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    final String? slug = slugMatch?.group(1);
    if (slug == null) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    final RegExpMatch? episodes = RegExp(
      r'var\s+episodes\s*=\s*(\[[^;]*\])\s*;',
    ).firstMatch(html);
    if (episodes == null) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    final Object? decoded = jsonDecode(episodes.group(1)!);
    if (decoded is! List) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    return decoded
        .whereType<num>()
        .where((num n) => n == n.round())
        .map((num n) => n.toInt())
        .toList();
  }

  static List<(String, Uri)> _videoServers(String html) {
    final RegExpMatch? videos = RegExp(
      r'\bvideos\s*=\s*(\[\[.*?\]\])\s*;',
      dotAll: true,
    ).firstMatch(html);
    if (videos == null) return const [];
    final Object? decoded = jsonDecode(videos.group(1)!);
    if (decoded is! List) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    final List<(String, Uri)> result = [];
    for (final Object? row in decoded) {
      if (row is! List ||
          row.length < 2 ||
          row[0] is! String ||
          row[1] is! String) {
        continue;
      }
      final Uri? endpoint = Uri.tryParse(row[1] as String);
      if (endpoint == null ||
          endpoint.scheme != 'https' ||
          endpoint.host.isEmpty ||
          endpoint.userInfo.isNotEmpty ||
          endpoint.hasFragment) {
        continue;
      }
      result.add((row[0] as String, endpoint));
    }
    return List.unmodifiable(result);
  }

  static Uri? _extractDirectMedia(String html, Uri base) {
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
        if (_isMediaUri(resolved)) return resolved;
      }
    }
    return null;
  }

  static bool _isMediaUri(Uri uri) {
    final String path = uri.path.toLowerCase();
    return uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasFragment &&
        (path.endsWith('.m3u8') || path.endsWith('.mp4'));
  }

  static String _serverId(String label, Uri uri) {
    final String safe = label.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return '${safe.isEmpty ? 'server' : safe}-${uri.host}';
  }

  static String _normalizeTitle(String value) => value.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );

  static String _plainText(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static PlaybackProviderFailed<T> _cancelled<T>() =>
      const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );
}

final class _TioAnimeMatch {
  const _TioAnimeMatch({required this.slug, required this.title});
  final String slug;
  final String title;
}
