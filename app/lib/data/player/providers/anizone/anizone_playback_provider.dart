import 'package:dio/dio.dart';

import '../../../../domain/player/providers/anime_identity.dart';
import '../../../../domain/player/providers/episode_source.dart';
import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../episode_source_support.dart';
import '../hosts/direct_media_host_resolver.dart';
import '../html_playback_parsers.dart';
import '../public_playback_http.dart';

/// AniZone public site adapter, adapted from Anilili's `AnivexaClient.anizone`
/// (project Anilili, MIT-0) to the site's current Livewire markup: search
/// results and the player manifest live in escaped JSON snapshots, so the
/// adapter decodes those escapes instead of the retired `anmTitles` markup.
/// No cookies, sessions, or JavaScript execution; the page's own published
/// player JSON is read as text.
final class AniZonePlaybackProvider extends EpisodeSourceAdapter {
  AniZonePlaybackProvider(
    Dio client, {
    Uri? origin,
    PublicPlaybackHttp? transport,
  }) : origin = origin ?? Uri.https('anizone.to') {
    if (!DirectMediaHostResolver.isSyntacticallyPublicHttps(this.origin) ||
        !const {'', '/'}.contains(this.origin.path) ||
        this.origin.hasQuery) {
      throw ArgumentError.value(this.origin, 'origin');
    }
    _http = transport ?? PublicPlaybackHttp(client, {this.origin.host});
  }

  final Uri origin;
  late final PublicPlaybackHttp _http;

  static final RegExp _slug = RegExp(r'^[a-z0-9][a-z0-9-]{0,180}$');
  static final RegExp _entry = RegExp(
    r'"url":"https?://anizone\.to/anime/([a-z0-9][a-z0-9-]{0,180})"'
    r',"cover":"[^"]*","main_title":"((?:[^"\\]|\\.)*)"',
  );
  static final RegExp _playerSrc = RegExp(
    r'"src":"(https://[^"\\]+?\.m3u8[^"\\]*)"',
    caseSensitive: false,
  );
  static final RegExp _mediaPlayerTag = RegExp(
    r'''<media-player[^>]+src=["']([^"']+\.m3u8[^"']*)["']''',
    caseSensitive: false,
  );
  static final RegExp _vttSubtitle = RegExp(
    r'\{"title":"((?:[^"\\]|\\.)*)"[^{}]*?"format":"vtt"[^{}]*?'
    r'"language":"([a-z-]{2,8})"[^{}]*?"file":"(https://[^"\\]+?\.vtt)"',
  );
  static final RegExp _vttSubtitleNoLanguage = RegExp(
    r'\{"title":"((?:[^"\\]|\\.)*)"[^{}]*?"format":"vtt"[^{}]*?'
    r'"file":"(https://[^"\\]+?\.vtt)"',
  );

  @override
  PlaybackProviderId get id => PlaybackProviderId('anizone');

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
  };

  bool _validMatch(SourceAnimeMatch match) =>
      match.providerId == id &&
      match.adapterVersion == adapterVersion &&
      _slug.hasMatch(match.sourceAnimeId) &&
      match.evidence == AnimeMatchEvidence.exactTitle &&
      match.isConservativeMatch();

  EpisodeRef _episode(SourceAnimeMatch match, int number) => EpisodeRef(
    anime: match,
    episodeId: 'anizone:${match.sourceAnimeId}:$number',
    episodeNumber: number,
    declaredLanguage: 'sub',
    mappingEvidence:
        'AniZone slug from exact-title search and explicit episode path',
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
        origin.resolve('/anime').replace(queryParameters: {'search': title}),
        cancellation,
        stage: PlaybackHttpStage.catalog,
      );
      final String decoded = HtmlPlaybackParsers.decodeJsonEscapes(text);
      for (final RegExpMatch entry in _entry.allMatches(decoded).take(40)) {
        final String slug = entry.group(1)!;
        final String name = HtmlPlaybackParsers.decodeEntities(entry.group(2)!);
        if (!_slug.hasMatch(slug) ||
            !seen.add(slug) ||
            name.trim().isEmpty ||
            name.length > 256) {
          continue;
        }
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
    final Uri page = origin.resolve(
      '/anime/${episode.sourceAnimeId}/${episode.episodeNumber}',
    );
    final String text = await _http.read(
      page,
      cancellation,
      stage: PlaybackHttpStage.episode,
      headers: PlaybackRequestHeaders({
        'Referer': origin.resolve('/anime/${episode.sourceAnimeId}').toString(),
      }),
    );
    final String decoded = HtmlPlaybackParsers.decodeJsonEscapes(text);
    final RegExpMatch? tagMatch = _mediaPlayerTag.firstMatch(decoded);
    final String? raw =
        _playerSrc.firstMatch(decoded)?.group(1) ??
        (tagMatch == null
            ? null
            : HtmlPlaybackParsers.decodeEntities(tagMatch.group(1)!)) ??
        HtmlPlaybackParsers.hlsUrls(decoded).firstOrNull;
    if (raw == null || raw.isEmpty || raw.length > 8192) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.noSources);
    }
    final String absolute = HtmlPlaybackParsers.absoluteUrl(
      origin.toString(),
      raw,
    );
    final Uri? uri = Uri.tryParse(absolute);
    if (uri == null ||
        !DirectMediaHostResolver.isSyntacticallyPublicHttps(uri)) {
      throw const FormatException('Invalid AniZone HLS URI');
    }
    return [
      PlaybackSource(
        id: episode.episodeId,
        providerId: id,
        episode: PlaybackEpisode.fromIdentity(
          episode.anime.requestedIdentity,
          episodeNumber: episode.episodeNumber,
        ),
        language: 'sub',
        quality: 'Auto',
        providerAnnouncedLanguage: 'sub; el manifiesto publica pistas de audio',
        displayName: 'AniZone',
        subtitles: _subtitles(decoded),
        servers: [
          SourceCandidate(
            id: 'anizone-hls',
            endpoint: uri,
            hostId: DirectMediaHostResolver.stableHostId,
            kind: PlaybackCandidateKind.media,
            mediaFormat: PlaybackMediaFormat.hls,
            sourceEpisodeId: episode.episodeId,
            requestHeaders: PlaybackRequestHeaders({
              'Referer': origin.resolve('/').toString(),
            }),
            provenance: 'AniZone player snapshot (Anilili MIT-0, forma live)',
          ),
        ],
      ),
    ];
  });

  /// Same-episode `.vtt` captions published by the player JSON. ASS tracks are
  /// outside the VTT-only subtitle contract and are skipped, not faked.
  static List<ProviderSubtitle> _subtitles(String decoded) {
    final List<ProviderSubtitle> result = <ProviderSubtitle>[];
    final Set<Uri> seen = <Uri>{};
    void add(Uri uri, String label, String language) {
      if (result.length >= 8 || seen.contains(uri)) return;
      if (!uri.path.toLowerCase().endsWith('.vtt')) return;
      try {
        result.add(
          ProviderSubtitle(
            id: 'anizone-sub-${result.length}',
            uri: uri,
            label: label.isEmpty || label.length > 128 ? 'Subtitle' : label,
            language:
                RegExp(r'^([a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*)$')
                    .hasMatch(language)
                ? language
                : 'unknown',
          ),
        );
        seen.add(uri);
      } on ArgumentError {
        // Optional captions must never discard a playable video.
      }
    }

    for (final RegExpMatch match in _vttSubtitle.allMatches(decoded).take(16)) {
      final Uri? uri = Uri.tryParse(match.group(3)!);
      if (uri != null) {
        add(
          uri,
          HtmlPlaybackParsers.decodeEntities(match.group(1)!),
          match.group(2)!,
        );
      }
    }
    if (result.isEmpty) {
      for (final RegExpMatch match
          in _vttSubtitleNoLanguage.allMatches(decoded).take(16)) {
        final Uri? uri = Uri.tryParse(match.group(2)!);
        if (uri != null) {
          add(
            uri,
            HtmlPlaybackParsers.decodeEntities(match.group(1)!),
            'unknown',
          );
        }
      }
    }
    return result;
  }
}
