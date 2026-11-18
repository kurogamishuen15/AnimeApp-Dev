import 'package:dio/dio.dart';

import '../../../../domain/player/providers/anime_identity.dart';
import '../../../../domain/player/providers/episode_source.dart';
import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../episode_source_support.dart';
import '../hosts/direct_media_host_resolver.dart';
import '../html_playback_parsers.dart';
import '../public_playback_http.dart';

enum AnimeGgAudioVariant { sub, dub }

/// AnimeGG public site adapter, adapted from Anilili's `AnivexaClient.animegg`
/// (project Anilili, MIT-0) to the site's current markup: search anchors carry
/// the title in an `h2`, episode lists use `anm_det_pop` links, and watch pages
/// expose `data-toggle="tab"` mirrors whose `/embed/{id}` documents publish
/// HLS playlists and jwplayer progressive MP4s. Embed-only mirrors are never
/// returned as playable; no cookies, sessions, or JavaScript execution.
final class AnimeGgPlaybackProvider extends EpisodeSourceAdapter {
  AnimeGgPlaybackProvider(
    Dio client, {
    Uri? origin,
    this.variant = AnimeGgAudioVariant.sub,
    PublicPlaybackHttp? transport,
  }) : origin = origin ?? Uri.https('www.animegg.org') {
    if (!DirectMediaHostResolver.isSyntacticallyPublicHttps(this.origin) ||
        !const {'', '/'}.contains(this.origin.path) ||
        this.origin.hasQuery) {
      throw ArgumentError.value(this.origin, 'origin');
    }
    _http = transport ?? PublicPlaybackHttp(client, {this.origin.host});
  }

  final Uri origin;
  final AnimeGgAudioVariant variant;
  late final PublicPlaybackHttp _http;

  static final RegExp _slug = RegExp(r'^[a-z0-9][a-z0-9-]{0,180}$');
  static final RegExp _searchAnchor = RegExp(
    r'''<a\b([^>]*\bclass=["'][^"']*\bmse\b[^"']*["'][^>]*)>([\s\S]*?)</a>''',
    caseSensitive: false,
  );
  static final RegExp _h2 = RegExp(
    r'<h2[^>]*>([\s\S]*?)</h2>',
    caseSensitive: false,
  );
  static final RegExp _li = RegExp(
    r'<li\b[^>]*>([\s\S]*?)</li>',
    caseSensitive: false,
  );
  static final RegExp _strong = RegExp(
    r'<strong[^>]*>([\s\S]*?)</strong>',
    caseSensitive: false,
  );
  static final RegExp _popAnchor = RegExp(
    r'''<a\b[^>]*\bclass=["'][^"']*\banm_det_pop\b[^"']*["'][^>]*>''',
    caseSensitive: false,
  );
  static final RegExp _tabAnchor = RegExp(
    r'''<a\b[^>]*\bdata-toggle=["']tab["'][^>]*>''',
    caseSensitive: false,
  );
  static final RegExp _jwFile = RegExp(
    r'''file:\s*["']([^"']+\.mp4[^"']*)["']''',
    caseSensitive: false,
  );

  @override
  PlaybackProviderId get id => PlaybackProviderId(
    variant == AnimeGgAudioVariant.sub ? 'animegg' : 'animegg-dub',
  );

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    PlaybackProviderCapability.sourceAlternatives,
  };

  PlaybackRequestHeaders get _referer =>
      PlaybackRequestHeaders({'Referer': origin.resolve('/').toString()});

  /// Media candidates carry a browser User-Agent: the vidcache CDN serves
  /// library clients at unusable rates (verified live, ~28 KB/s vs ~176 KB/s).
  PlaybackRequestHeaders get _mediaHeaders => PlaybackRequestHeaders({
    'Referer': origin.resolve('/').toString(),
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  });

  bool _validMatch(SourceAnimeMatch match) =>
      match.providerId == id &&
      match.adapterVersion == adapterVersion &&
      _slug.hasMatch(match.sourceAnimeId) &&
      match.evidence == AnimeMatchEvidence.exactTitle &&
      match.isConservativeMatch();

  EpisodeRef _episode(SourceAnimeMatch match, int number) => EpisodeRef(
    anime: match,
    episodeId: 'animegg:${match.sourceAnimeId}:$number:${variant.name}',
    episodeNumber: number,
    declaredLanguage: variant.name,
    mappingEvidence:
        'AnimeGG series slug from exact-title search and episode link '
        'whose row number matches the request',
  );

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  }) => EpisodeSourceSupport.read(() async {
    EpisodeSourceSupport.check(cancellation);
    if (identity.titles.isEmpty) return null;
    final List<String> requested = identity.titles
        .map(EpisodeSourceSupport.contractTitle)
        .where((String title) => title.isNotEmpty)
        .toList();
    final seen = <String>{};
    for (final String title in identity.titles.take(3)) {
      EpisodeSourceSupport.check(cancellation);
      final String text = await _http.read(
        origin.resolve('/search/').replace(queryParameters: {'q': title}),
        cancellation,
        stage: PlaybackHttpStage.catalog,
      );
      for (final RegExpMatch anchor
          in _searchAnchor.allMatches(text).take(40)) {
        final String href = HtmlPlaybackParsers.attr(anchor.group(1)!, 'href');
        final RegExpMatch? slugMatch = RegExp(
          r'^/series/([a-z0-9][a-z0-9-]{0,180})',
        ).firstMatch(href);
        if (slugMatch == null) continue;
        final String slug = slugMatch.group(1)!;
        if (!seen.add(slug)) continue;
        final String body = anchor.group(2)!;
        final RegExpMatch? h2 = _h2.firstMatch(body);
        final String name = h2 == null
            ? slug.replaceAll('-', ' ')
            : HtmlPlaybackParsers.stripTags(h2.group(1)!);
        if (name.trim().isEmpty || name.length > 256) continue;
        if (requested.contains(EpisodeSourceSupport.contractTitle(name))) {
          return [
            SourceAnimeMatch(
              providerId: id,
              sourceAnimeId: slug,
              title: name,
              requestedIdentity: identity,
              evidence: AnimeMatchEvidence.exactTitle,
              adapterVersion: adapterVersion,
            ),
          ];
        }
      }
    }
    return null;
  });

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) async => cancellation.isCancelled
      ? const PlaybackProviderFailed<List<EpisodeRef>>(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        )
      : const PlaybackProviderUnsupported<List<EpisodeRef>>(
          PlaybackProviderCapability.episodeSources,
        );

  @override
  Future<PlaybackProviderResult<EpisodeRef>> findEpisode(
    SourceAnimeMatch match, {
    required int episodeNumber,
    required PlaybackCancellationToken cancellation,
  }) => EpisodeSourceSupport.read(() async {
    EpisodeSourceSupport.check(cancellation);
    if (!_validMatch(match) || episodeNumber < 1) return null;
    return _episode(match, episodeNumber);
  });

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) => EpisodeSourceSupport.read(() async {
    EpisodeSourceSupport.check(cancellation);
    if (!_validMatch(episode.anime) ||
        episode.episodeId !=
            _episode(episode.anime, episode.episodeNumber).episodeId) {
      throw const FormatException('Invalid episode identity');
    }
    final String? watchPath = await _episodePath(episode, cancellation);
    if (watchPath == null) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.noEpisodes);
    }
    final String watch = await _http.read(
      origin.resolve('/$watchPath'),
      cancellation,
      stage: PlaybackHttpStage.episode,
      headers: _referer,
    );
    final List<({String id, String mirror})> tabs = _tabs(watch);
    if (tabs.isEmpty) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.noSources);
    }
    final servers = <SourceCandidate>[];
    final seen = <String>{};
    for (final (:String id, :String mirror) in tabs.take(4)) {
      EpisodeSourceSupport.check(cancellation);
      final String embed = await _http.read(
        origin.resolve('/embed/$id'),
        cancellation,
        stage: PlaybackHttpStage.embed,
        headers: _referer,
      );
      for (final String hls in HtmlPlaybackParsers.hlsUrls(embed).take(4)) {
        _add(
          servers,
          seen,
          HtmlPlaybackParsers.absoluteUrl(origin.toString(), hls),
          PlaybackMediaFormat.hls,
          mirror,
          episode,
        );
      }
      for (final RegExpMatch file in _jwFile.allMatches(embed).take(4)) {
        _add(
          servers,
          seen,
          HtmlPlaybackParsers.absoluteUrl(
            origin.toString(),
            HtmlPlaybackParsers.decodeEntities(file.group(1)!),
          ),
          PlaybackMediaFormat.mp4,
          mirror,
          episode,
        );
      }
    }
    if (servers.isEmpty) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.noSources);
    }
    return [
      PlaybackSource(
        id: episode.episodeId,
        providerId: id,
        episode: PlaybackEpisode.fromIdentity(
          episode.anime.requestedIdentity,
          episodeNumber: episode.episodeNumber,
        ),
        language: variant.name,
        quality: 'Auto',
        providerAnnouncedLanguage: variant.name,
        displayName: variant == AnimeGgAudioVariant.sub
            ? 'AnimeGG · Original (sub)'
            : 'AnimeGG · Doblaje (dub)',
        servers: servers,
      ),
    ];
  });

  /// Episode row whose trailing number equals the request, as in Anilili.
  Future<String?> _episodePath(
    EpisodeRef episode,
    PlaybackCancellationToken cancellation,
  ) async {
    final String series = await _http.read(
      origin.resolve('/series/${episode.sourceAnimeId}'),
      cancellation,
      stage: PlaybackHttpStage.anime,
      headers: _referer,
    );
    for (final RegExpMatch item in _li.allMatches(series).take(400)) {
      final String block = item.group(1)!;
      if (!block.contains('anm_det_pop')) continue;
      final RegExpMatch? strong = _strong.firstMatch(block);
      if (strong == null) continue;
      final String text = HtmlPlaybackParsers.stripTags(strong.group(1)!);
      final RegExpMatch? number = RegExp(r'(\d+)\s*$').firstMatch(text);
      if (number == null ||
          int.tryParse(number.group(1)!) != episode.episodeNumber) {
        continue;
      }
      final RegExpMatch? anchor = _popAnchor.firstMatch(block);
      if (anchor == null) continue;
      final String href = HtmlPlaybackParsers.attr(anchor.group(0)!, 'href');
      if (href.isEmpty || href.length > 512) continue;
      return href.replaceFirst(RegExp(r'^/'), '').split('#').first;
    }
    return null;
  }

  List<({String id, String mirror})> _tabs(String watch) {
    final result = <({String id, String mirror})>[];
    final seen = <String>{};
    for (final RegExpMatch anchor in _tabAnchor.allMatches(watch).take(24)) {
      final String tag = anchor.group(0)!;
      final String dataId = HtmlPlaybackParsers.attr(tag, 'data-id');
      final String version = HtmlPlaybackParsers.attr(tag, 'data-version');
      if (dataId.isEmpty || !RegExp(r'^[0-9]{1,32}$').hasMatch(dataId)) {
        continue;
      }
      final bool dubbed = version.toLowerCase().startsWith('dub');
      if ((variant == AnimeGgAudioVariant.dub) != dubbed) continue;
      if (!seen.add(dataId)) continue;
      final String mirror = HtmlPlaybackParsers.attr(tag, 'data-mirror');
      result.add((
        id: dataId,
        mirror: mirror.isEmpty || mirror.length > 64 ? 'AnimeGG' : mirror,
      ));
    }
    return result;
  }

  void _add(
    List<SourceCandidate> servers,
    Set<String> seen,
    String raw,
    PlaybackMediaFormat format,
    String mirror,
    EpisodeRef episode,
  ) {
    if (servers.length >= 8 ||
        raw.isEmpty ||
        raw.length > 8192 ||
        !seen.add(raw)) {
      return;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null ||
        !DirectMediaHostResolver.isSyntacticallyPublicHttps(uri)) {
      return;
    }
    servers.add(
      SourceCandidate(
        id: 'animegg-${servers.length}',
        endpoint: uri,
        hostId: DirectMediaHostResolver.stableHostId,
        kind: PlaybackCandidateKind.media,
        mediaFormat: format,
        quality: 'Auto',
        displayName: 'AnimeGG $mirror',
        sourceEpisodeId: episode.episodeId,
        requestHeaders: _mediaHeaders,
        provenance: 'AnimeGG embed media (Anilili MIT-0, forma live)',
      ),
    );
  }
}
