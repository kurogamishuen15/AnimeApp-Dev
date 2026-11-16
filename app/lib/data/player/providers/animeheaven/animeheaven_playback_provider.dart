import 'package:dio/dio.dart';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import 'animeheaven_html_parser.dart';
import 'animeheaven_http.dart';

/// Finds an AniList episode by exact title and obtains AnimeHeaven's public
/// episode gate result. It never owns a player or resolves video-host policy.
final class AnimeHeavenPlaybackProvider implements PlaybackSourceProvider {
  AnimeHeavenPlaybackProvider({required Dio client, Uri? baseUri})
    : _http = AnimeHeavenHttp(client),
      _baseUri = baseUri ?? Uri.https('animeheaven.me', '');

  static final PlaybackProviderId providerId = PlaybackProviderId(
    'animeheaven',
  );

  final AnimeHeavenHttp _http;
  final Uri _baseUri;

  @override
  PlaybackProviderId get id => providerId;

  @override
  Set<PlaybackProviderCapability> get capabilities =>
      const <PlaybackProviderCapability>{
        PlaybackProviderCapability.episodeSources,
        PlaybackProviderCapability.sourceAlternatives,
      };

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) return _cancelled();
    final Uri? base = _validatedBaseUri();
    if (base == null) return _failed(PlaybackProviderFailureKind.unsupported);

    try {
      final AnimeHeavenCatalog? catalog = await _findCatalog(
        episode,
        base,
        cancellation,
      );
      if (cancellation.isCancelled) return _cancelled();
      if (catalog == null) return const PlaybackProviderEmpty();
      AnimeHeavenEpisodeEntry? requested;
      for (final AnimeHeavenEpisodeEntry value in catalog.episodes) {
        if (value.number == episode.episodeNumber) {
          requested = value;
          break;
        }
      }
      if (requested == null) return const PlaybackProviderEmpty();

      // This public key is issued for the selected episode by its own page.
      // It is sent only to gate.php and is never passed to the media host.
      final AnimeHeavenHttpResponse gate = await _http.getHtml(
        base.resolve('gate.php'),
        headers: <String, String>{
          'Accept': 'text/html,application/xhtml+xml',
          'Referer': catalog.page.toString(),
          'Cookie': 'key=${requested.gateKey}',
        },
        cancellation: cancellation,
      );
      final PlaybackProviderFailure? gateFailure =
          animeHeavenHttpFailureForStatus(gate.statusCode);
      if (gateFailure != null) {
        return PlaybackProviderFailed<List<PlaybackSource>>(gateFailure);
      }
      if (!_isHtml(gate.contentType)) {
        return _failed(PlaybackProviderFailureKind.invalidResponse);
      }
      final List<Uri> mirrors = AnimeHeavenHtmlParser.parseMp4Mirrors(
        gate.text,
        gateKey: requested.gateKey,
      );
      if (mirrors.isEmpty) return const PlaybackProviderEmpty();

      final List<PlaybackServer> servers = <PlaybackServer>[];
      for (var index = 0; index < mirrors.length; index++) {
        final Uri mirror = mirrors[index];
        final String hostLabel = mirror.host.split('.').first;
        servers.add(
          PlaybackServer(
            id: 'mirror-$hostLabel',
            endpoint: mirror,
            priority: mirrors.length - index,
          ),
        );
      }
      return PlaybackProviderSuccess<List<PlaybackSource>>(<PlaybackSource>[
        PlaybackSource(
          id: 'animeheaven-${episode.episodeNumber}',
          providerId: id,
          episode: episode,
            language: 'Subtitulado (idioma no validado)',
            quality: 'Única (MP4 progresivo)',
          servers: servers,
        ),
      ]);
    } on AnimeHeavenHttpFailure catch (error) {
      return _failed(error.kind);
    } on DioException catch (error) {
      if (cancellation.isCancelled || error.type == DioExceptionType.cancel) {
        return _cancelled();
      }
      return _failed(
        error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout
            ? PlaybackProviderFailureKind.timeout
            : PlaybackProviderFailureKind.network,
      );
    } on Object {
      return cancellation.isCancelled
          ? _cancelled()
          : _failed(PlaybackProviderFailureKind.invalidResponse);
    }
  }

  Future<AnimeHeavenCatalog?> _findCatalog(
    PlaybackEpisode episode,
    Uri base,
    PlaybackCancellationToken cancellation,
  ) async {
    final List<String> titles = <String>[];
    final Set<String> normalized = <String>{};
    for (final String title in episode.animeTitles) {
      final String key = _normalizeTitle(title);
      if (key.length < 3 || !normalized.add(key)) continue;
      titles.add(title.trim());
      if (titles.length == 3) break;
    }
    if (titles.isEmpty) return null;

    for (final String query in titles) {
      if (cancellation.isCancelled) {
        throw const AnimeHeavenHttpFailure(
          PlaybackProviderFailureKind.cancelled,
        );
      }
      final Uri searchUri = base.replace(
        path: '/search.php',
        queryParameters: <String, String>{'s': query},
      );
      final AnimeHeavenHttpResponse search = await _http.getHtml(
        searchUri,
        headers: <String, String>{
          'Accept': 'text/html,application/xhtml+xml',
          'Referer': '${base.origin}/',
        },
        cancellation: cancellation,
      );
      final PlaybackProviderFailure? searchFailure =
          animeHeavenHttpFailureForStatus(search.statusCode);
      if (searchFailure != null) {
        throw AnimeHeavenHttpFailure(searchFailure.kind);
      }
      if (!_isHtml(search.contentType)) {
        throw const AnimeHeavenHttpFailure(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }
      final String wanted = _normalizeTitle(query);
      final List<AnimeHeavenSearchEntry> exact =
          AnimeHeavenHtmlParser.parseSearch(search.text)
              .where(
                (AnimeHeavenSearchEntry entry) =>
                    _normalizeTitle(entry.title) == wanted,
              )
              .take(3)
              .toList(growable: false);

      for (final AnimeHeavenSearchEntry entry in exact) {
        if (cancellation.isCancelled) {
          throw const AnimeHeavenHttpFailure(
            PlaybackProviderFailureKind.cancelled,
          );
        }
        final Uri? page = _catalogPageUri(base, entry.path);
        if (page == null) continue;
        final AnimeHeavenHttpResponse detail = await _http.getHtml(
          page,
          headers: <String, String>{
            'Accept': 'text/html,application/xhtml+xml',
            'Referer': '${base.origin}/',
          },
          cancellation: cancellation,
        );
        final PlaybackProviderFailure? detailFailure =
            animeHeavenHttpFailureForStatus(detail.statusCode);
        if (detailFailure != null) {
          throw AnimeHeavenHttpFailure(detailFailure.kind);
        }
        if (!_isHtml(detail.contentType)) {
          throw const AnimeHeavenHttpFailure(
            PlaybackProviderFailureKind.invalidResponse,
          );
        }
        final List<AnimeHeavenEpisodeEntry> episodes =
            AnimeHeavenHtmlParser.parseEpisodes(detail.text);
        if (episodes.isNotEmpty) {
          return AnimeHeavenCatalog(page: page, episodes: episodes);
        }
      }
    }
    return null;
  }

  Uri? _catalogPageUri(Uri base, String relativePath) {
    final Uri? parsed = Uri.tryParse(relativePath);
    if (parsed == null ||
        parsed.isAbsolute ||
        (parsed.path != 'anime.php' && parsed.path != '/anime.php') ||
        !parsed.hasQuery ||
        parsed.hasFragment ||
        parsed.userInfo.isNotEmpty) {
      return null;
    }
    final Uri page = base.resolveUri(parsed);
    return page.origin == base.origin && page.path == '/anime.php'
        ? page
        : null;
  }

  Uri? _validatedBaseUri() {
    if (_baseUri.scheme != 'https' ||
        _baseUri.host != 'animeheaven.me' ||
        _baseUri.port != 443 ||
        _baseUri.userInfo.isNotEmpty ||
        _baseUri.hasQuery ||
        _baseUri.hasFragment) {
      return null;
    }
    return Uri.https(_baseUri.host, '/');
  }

  static bool _isHtml(String? contentType) =>
      contentType == null ||
      contentType.toLowerCase().contains('text/html') ||
      contentType.toLowerCase().contains('application/xhtml+xml');

  static String _normalizeTitle(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  PlaybackProviderResult<List<PlaybackSource>> _cancelled() =>
      const PlaybackProviderFailed<List<PlaybackSource>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );

  PlaybackProviderResult<List<PlaybackSource>> _failed(
    PlaybackProviderFailureKind kind,
  ) => PlaybackProviderFailed<List<PlaybackSource>>(
    PlaybackProviderFailure(kind),
  );
}

final class AnimeHeavenCatalog {
  const AnimeHeavenCatalog({required this.page, required this.episodes});

  final Uri page;
  final List<AnimeHeavenEpisodeEntry> episodes;
}
