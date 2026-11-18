import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

import '../../../../domain/catalog/external_anime_id.dart';
import '../../../../domain/player/providers/anime_identity.dart';
import '../../../../domain/player/providers/episode_source.dart';
import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../hosts/direct_media_host_resolver.dart';
import '../public_playback_http.dart';

enum MegaPlayAudioVariant { sub, dub }

/// Exact AniList/episode MegaPlay endpoint with a MyAnimeList fallback,
/// adapted from Anilili (MIT-0): the `ani` route first, then the `mal` route
/// that 2Dhive itself embeds. No title search, inferred episode index,
/// cookies, or JavaScript execution.
final class MegaPlayPlaybackProvider extends EpisodeSourceAdapter {
  MegaPlayPlaybackProvider(
    Dio client, {
    Uri? origin,
    this.variant = MegaPlayAudioVariant.sub,
    PublicPlaybackHttp? transport,
  }) : origin = origin ?? defaultOrigin {
    if (!DirectMediaHostResolver.isSyntacticallyPublicHttps(this.origin) ||
        !const {'', '/'}.contains(this.origin.path) ||
        this.origin.hasQuery) {
      throw ArgumentError.value(this.origin, 'origin');
    }
    _http = transport ?? PublicPlaybackHttp(client, {this.origin.host});
  }

  static final Uri defaultOrigin = Uri.https('megaplay.buzz');

  final Uri origin;
  final MegaPlayAudioVariant variant;
  late final PublicPlaybackHttp _http;
  static const String _fallback = 'stream/getSources';
  static final RegExp _number = RegExp(r'^[1-9][0-9]{0,9}$');
  static final RegExp _fileId = RegExp(r'^[A-Za-z0-9]{1,128}$');
  static final RegExp _route = RegExp(
    r'^stream/getSources[A-Za-z0-9_-]{0,64}$',
  );

  @override
  PlaybackProviderId get id => PlaybackProviderId(
    variant == MegaPlayAudioVariant.sub ? 'megaplay' : 'megaplay-dub',
  );

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
  };

  String? _anilistId(AnimeIdentity identity) {
    final ids = identity.externalIds
        .where((value) => value.providerId.value == 'anilist')
        .toList();
    if (ids.length != 1 || !_number.hasMatch(ids.single.value)) return null;
    final int? parsed = int.tryParse(ids.single.value);
    return parsed != null && parsed <= 0x7fffffff ? ids.single.value : null;
  }

  SourceAnimeMatch _match(AnimeIdentity identity, String anilistId) =>
      SourceAnimeMatch(
        providerId: id,
        sourceAnimeId: anilistId,
        title: identity.titles.firstOrNull ?? 'AniList $anilistId',
        requestedIdentity: identity,
        evidence: AnimeMatchEvidence.externalId,
        externalIds: [
          ExternalAnimeId(
            providerId: MetadataProviderId('anilist'),
            value: anilistId,
          ),
        ],
        adapterVersion: adapterVersion,
      );

  bool _validMatch(SourceAnimeMatch match) =>
      match.providerId == id &&
      match.adapterVersion == adapterVersion &&
      match.evidence == AnimeMatchEvidence.externalId &&
      _anilistId(match.requestedIdentity) == match.sourceAnimeId &&
      match.externalIds.length == 1 &&
      match.externalIds.single.providerId.value == 'anilist' &&
      match.externalIds.single.value == match.sourceAnimeId &&
      match.isConservativeMatch();

  EpisodeRef _episode(SourceAnimeMatch match, int number) => EpisodeRef(
    anime: match,
    episodeId: 'megaplay:${match.sourceAnimeId}:$number:${variant.name}',
    episodeNumber: number,
    declaredLanguage: variant.name,
    mappingEvidence:
        'Exact AniList ID and episode in MegaPlay public endpoint; '
        'no provider episode index is inferred',
  );

  Uri _embed(EpisodeRef episode) => origin.resolve(
    '/stream/ani/${episode.sourceAnimeId}/${episode.episodeNumber}/${variant.name}',
  );

  /// MegaPlay's MyAnimeList-keyed route, as used by Anilili's `anikoto`
  /// fallback and by 2Dhive's own embeds (verified live 2026-11-17).
  Uri _embedMal(int malId, int number) => origin.resolve(
    '/stream/mal/$malId/$number/${variant.name}',
  );

  int? _mal(AnimeIdentity identity) {
    final ids = identity.externalIds
        .where((value) => value.providerId.value == 'myanimelist')
        .toList();
    if (ids.length != 1 ||
        !RegExp(r'^[1-9][0-9]{0,9}$').hasMatch(ids.single.value)) {
      return null;
    }
    final int? parsed = int.tryParse(ids.single.value);
    return parsed != null && parsed <= 0x7fffffff ? parsed : null;
  }

  /// File id from the AniList embed, falling back to the MyAnimeList embed
  /// when the first route misses (empty page, 404, or 403 on that one show).
  /// Origin-wide policy failures (cooldowns, challenges) still propagate.
  Future<String?> _loadFileIdFor(
    EpisodeRef episode,
    PlaybackCancellationToken cancellation,
  ) async {
    PublicPlaybackFailure? missed;
    try {
      final String? direct = await _loadFileId(
        _embed(episode),
        cancellation,
      );
      if (direct != null) return direct;
    } on PublicPlaybackFailure catch (error) {
      if (error.kind != PlaybackProviderFailureKind.notFound &&
          error.kind != PlaybackProviderFailureKind.forbidden) {
        rethrow;
      }
      missed = error;
    }
    final int? mal = _mal(episode.anime.requestedIdentity);
    if (mal != null) {
      final String? viaMal = await _loadFileId(
        _embedMal(mal, episode.episodeNumber),
        cancellation,
      );
      if (viaMal != null) return viaMal;
    }
    if (missed != null) throw missed;
    return null;
  }

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    final String? value = _anilistId(identity);
    if (value == null) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.missingId);
    }
    // This is an exact endpoint mapping, not an assertion of catalog presence.
    return [_match(identity, value)];
  });

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) async => cancellation.isCancelled
      ? const PlaybackProviderFailed(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        )
      : const PlaybackProviderUnsupported(
          PlaybackProviderCapability.episodeSources,
        );

  @override
  Future<PlaybackProviderResult<EpisodeRef>> findEpisode(
    SourceAnimeMatch match, {
    required int episodeNumber,
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    if (!_validMatch(match) || episodeNumber < 1) return null;
    final EpisodeRef episode = _episode(match, episodeNumber);
    return await _loadFileIdFor(episode, cancellation) == null
        ? null
        : episode;
  });

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode requested, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    final String? value = _anilistId(requested.identity);
    if (value == null) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.missingId);
    }
    return _sources(
      _episode(_match(requested.identity, value), requested.episodeNumber),
      cancellation,
    );
  });

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    if (!_validMatch(episode.anime) ||
        episode.episodeId !=
            _episode(episode.anime, episode.episodeNumber).episodeId) {
      return null;
    }
    return _sources(episode, cancellation);
  });

  static String? _dataId(String page) {
    for (final tag in RegExp(
      r'<(?:div|span)\b[^>]{0,4096}>',
      caseSensitive: false,
    ).allMatches(page)) {
      final value = RegExp(
        r'''\bdata-id\s*=\s*["']([A-Za-z0-9]{1,128})["']''',
        caseSensitive: false,
      ).firstMatch(tag.group(0)!)?.group(1);
      if (value != null && _fileId.hasMatch(value)) return value;
    }
    return null;
  }

  Future<String?> _loadFileId(
    Uri embed,
    PlaybackCancellationToken cancellation,
  ) async {
    final headers = PlaybackRequestHeaders({'Referer': 'https://hianimes.re/'});
    final String page = await _http.read(
      embed,
      cancellation,
      headers: headers,
      stage: PlaybackHttpStage.embed,
    );
    final String? found = _dataId(page);
    if (found != null) return found;
    final String? frame = RegExp(
      r'''<iframe\b[^>]{0,4096}\bsrc\s*=\s*["']([^"'<>]{1,2048})["']''',
      caseSensitive: false,
    ).firstMatch(page)?.group(1);
    if (frame == null) return null;
    final Uri nested = embed.resolve(frame);
    // Only the same embed family, at most one nested document.
    if (nested.origin != origin.origin ||
        nested.hasQuery ||
        nested.hasFragment ||
        nested.userInfo.isNotEmpty ||
        !RegExp(r'^/stream/[A-Za-z0-9/_-]{1,200}$').hasMatch(nested.path) ||
        nested == embed) {
      return null;
    }
    return _dataId(
      await _http.read(
        nested,
        cancellation,
        headers: headers,
        stage: PlaybackHttpStage.embed,
      ),
    );
  }

  Future<List<String>> _routes(
    Uri embed,
    PlaybackCancellationToken cancellation,
  ) async {
    String script;
    try {
      script = await _http.read(
        origin.resolve('/lib/newclient.min.js'),
        cancellation,
        headers: PlaybackRequestHeaders({'Referer': embed.toString()}),
        stage: PlaybackHttpStage.embed,
      );
    } on PublicPlaybackFailure catch (error) {
      if (error.kind == PlaybackProviderFailureKind.notFound) {
        return [_fallback];
      }
      rethrow;
    }
    final List<String> found =
        RegExp(r'stream/getSources[A-Za-z0-9_/-]*')
            .allMatches(script)
            .map((match) => match.group(0)!)
            .where(_route.hasMatch)
            .toSet()
            .toList()
          ..sort((a, b) {
            final order = b.length.compareTo(a.length);
            return order == 0 ? a.compareTo(b) : order;
          });
    return [...found.where((value) => value != _fallback).take(2), _fallback];
  }

  Future<String?> _sourceFile(Map<String, dynamic> answer) async {
    final Object? sources = answer['sources'];
    final Object? source = sources is List && sources.isNotEmpty
        ? sources.first
        : sources;
    if (source is Map &&
        source['file'] is String &&
        (source['file'] as String).isNotEmpty) {
      return source['file'] as String;
    }
    final Object? enc = answer['enc'];
    if (enc == null) return null;
    if (enc is! String ||
        enc.isEmpty ||
        enc.length > 32768 ||
        !RegExp(r'^[A-Za-z0-9_+/=-]+$').hasMatch(enc)) {
      throw const FormatException('Invalid encrypted source');
    }
    try {
      final bytes = base64.decode(base64.normalize(enc));
      if (bytes.isEmpty || bytes.length % 16 != 0) {
        throw const FormatException('Invalid cipher length');
      }
      final key = List<int>.filled(32, 0);
      key.setRange(0, 16, utf8.encode('i?LMTAx0Q6,:}50U'));
      final clear = await AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty)
          .decrypt(
            SecretBox(
              bytes,
              nonce: utf8.encode("W0;27ToaUpl_P%'c"),
              mac: Mac.empty,
            ),
            secretKey: SecretKey(key),
          );
      final Object? decoded = jsonDecode(utf8.decode(clear));
      if (decoded is! Map || decoded['file'] is! String) {
        throw const FormatException('Invalid decrypted source');
      }
      return decoded['file'] as String;
    } on Exception {
      // Invalid CBC padding and malformed JSON are untrusted response data.
      throw const FormatException('Invalid encrypted source');
    } on ArgumentError {
      throw const FormatException('Invalid encrypted source');
    }
  }

  // Same-episode tracks published by the source API; never borrow another cut.
  static List<ProviderSubtitle> _subtitles(Map<String, dynamic> answer) {
    final tracks = answer['tracks'];
    if (tracks is! List) return const [];
    final result = <ProviderSubtitle>[];
    final seen = <Uri>{};
    for (final value in tracks.take(64)) {
      if (result.length == 32) break;
      if (value is! Map ||
          !const {'captions', 'subtitles'}.contains(value['kind']) ||
          value['file'] is! String ||
          value['label'] is! String) {
        continue;
      }
      final uri = Uri.tryParse(value['file'] as String);
      if (uri == null || seen.contains(uri)) continue;
      final label = value['label'] as String;
      final lower = label.toLowerCase();
      final language = lower.contains('spanish')
          ? 'es'
          : lower.contains('english')
          ? 'en'
          : lower.contains('japanese')
          ? 'ja'
          : lower.contains('portuguese')
          ? 'pt'
          : 'unknown';
      try {
        result.add(
          ProviderSubtitle(
            id: 'caption-${result.length}',
            uri: uri,
            label: label,
            language: language,
            isDefault: value['default'] == true,
          ),
        );
        seen.add(uri);
      } on ArgumentError {
        // Invalid optional captions must never discard a playable video.
      }
    }
    return result;
  }

  Future<List<PlaybackSource>?> _sources(
    EpisodeRef episode,
    PlaybackCancellationToken cancellation,
  ) async {
    final String? fileId = await _loadFileIdFor(episode, cancellation);
    if (fileId == null) return null;
    final routes = await _routes(_embed(episode), cancellation);
    final headers = PlaybackRequestHeaders({
      'Referer': origin.resolve('/').toString(),
      'Origin': origin.origin,
      'User-Agent': _http.userAgent,
    });
    for (final route in routes) {
      _check(cancellation);
      String body;
      try {
        body = await _http.read(
          origin.resolve('/$route').replace(query: 'id=$fileId&id=$fileId'),
          cancellation,
          headers: PlaybackRequestHeaders({
            'Referer': origin.resolve('/').toString(),
          }),
          ajax: true,
          stage: PlaybackHttpStage.episode,
        );
      } on PublicPlaybackFailure catch (error) {
        if (error.kind == PlaybackProviderFailureKind.notFound) continue;
        rethrow;
      }
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid source answer');
      }
      final String? file = await _sourceFile(decoded);
      _check(cancellation);
      if (file == null || file.isEmpty) continue;
      final Uri? uri = Uri.tryParse(file);
      if (file.length > 8192 ||
          uri == null ||
          !DirectMediaHostResolver.isSyntacticallyPublicHttps(uri) ||
          DirectMediaHostResolver.formatFor(
                uri,
                declared: PlaybackMediaFormat.hls,
              ) !=
              PlaybackMediaFormat.hls) {
        throw const FormatException('Invalid direct HLS URI');
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
          displayName: variant == MegaPlayAudioVariant.sub
              ? 'MegaPlay · Original (sub)'
              : 'MegaPlay · Doblaje (dub)',
          providerAnnouncedLanguage: variant.name,
          subtitles: _subtitles(decoded),
          servers: [
            SourceCandidate(
              id: 'megaplay-hls',
              endpoint: uri,
              hostId: DirectMediaHostResolver.stableHostId,
              kind: PlaybackCandidateKind.media,
              mediaFormat: PlaybackMediaFormat.hls,
              sourceEpisodeId: episode.episodeId,
              requestHeaders: headers,
              provenance:
                  'MegaPlay exact AniList/episode endpoint (Anilili MIT-0)',
            ),
          ],
        ),
      ];
    }
    throw const PublicPlaybackFailure(PlaybackProviderFailureKind.noSources);
  }

  static void _check(PlaybackCancellationToken cancellation) {
    if (cancellation.isCancelled) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.cancelled);
    }
  }

  Future<PlaybackProviderResult<T>> _read<T>(Future<T?> Function() load) async {
    try {
      final T? value = await load();
      return value == null
          ? PlaybackProviderEmpty<T>()
          : PlaybackProviderSuccess<T>(value);
    } on PublicPlaybackFailure catch (error) {
      return error.result<T>();
    } on FormatException {
      return PlaybackProviderFailed<T>(
        const PlaybackProviderFailure(
          PlaybackProviderFailureKind.invalidResponse,
        ),
      );
    }
  }
}
