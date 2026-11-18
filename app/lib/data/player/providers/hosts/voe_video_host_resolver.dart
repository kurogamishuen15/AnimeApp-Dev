import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../public_playback_http.dart';
import 'direct_media_host_resolver.dart';

/// VOE's published player config, adapted from Anilili AnimeAv1Parser (MIT-0).
/// Follows one literal public player redirect; never runs JavaScript.
final class VoeVideoHostResolver implements PlaybackVideoHostResolver {
  VoeVideoHostResolver(
    this._client, {
    Set<String> embedHosts = const {'voe.sx'},
  }) : _embedHosts = Set.unmodifiable(embedHosts),
       _http = PublicPlaybackHttp(_client, Set.of(embedHosts));

  final Dio _client;
  final Set<String> _embedHosts;
  final PublicPlaybackHttp _http;
  final Map<String, PublicPlaybackHttp> _transports = {};

  PublicPlaybackHttp _transportFor(Uri uri) {
    if (_http.allowedHosts.contains(uri.host)) return _http;
    final existing = _transports.remove(uri.host);
    if (existing != null) {
      _transports[uri.host] = existing;
      return existing;
    }
    if (_transports.length == 16) _transports.remove(_transports.keys.first);
    return _transports[uri.host] = PublicPlaybackHttp(_client, {
      uri.host,
    }, userAgent: _http.userAgent);
  }

  @override
  String get hostId => 'voe';
  @override
  String get resolverId => 'voe';

  @override
  bool supports(SourceCandidate candidate) =>
      candidate.hostId == hostId &&
      candidate.kind == PlaybackCandidateKind.embed &&
      _embedHosts.contains(candidate.endpoint.host) &&
      DirectMediaHostResolver.isSyntacticallyPublicHttps(candidate.endpoint);

  @override
  Future<PlaybackProviderResult<PlayableSource>> resolve(
    PlaybackSource source,
    SourceCandidate candidate, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (!supports(candidate)) {
      return const PlaybackProviderUnsupported(
        PlaybackProviderCapability.resolveServer,
      );
    }
    if (candidate.expiresAt case final expiry?
        when !expiry.isAfter(DateTime.now())) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.expired),
      );
    }
    try {
      final headers = candidate.requestHeaders;
      String page = await _http.read(
        candidate.endpoint,
        cancellation,
        headers: headers,
        stage: PlaybackHttpStage.embed,
        maxResponseBytes: 512 * 1024,
      );
      Uri? media = decodeSource(page);
      if (media == null) {
        final next = publishedRedirect(page);
        if (next == null ||
            next == candidate.endpoint ||
            next.pathSegments.lastOrNull !=
                candidate.endpoint.pathSegments.lastOrNull) {
          throw const FormatException('No published VOE player');
        }
        // The service publishes rotating player hostnames; accept only this
        // public HTTPS destination for the same file, one hop, no clearance.
        page = await _transportFor(next).read(
          next,
          cancellation,
          headers: headers,
          stage: PlaybackHttpStage.embed,
          maxResponseBytes: 512 * 1024,
        );
        media = decodeSource(page);
      }
      if (media == null ||
          !DirectMediaHostResolver.isSyntacticallyPublicHttps(media) ||
          DirectMediaHostResolver.formatFor(media) != PlaybackMediaFormat.hls) {
        throw const FormatException('Invalid published VOE HLS');
      }
      final mediaHeaders = PlaybackRequestHeaders({
        'User-Agent': _http.userAgent,
      });
      final manifest = await _transportFor(media).read(
        media,
        cancellation,
        headers: mediaHeaders,
        stage: PlaybackHttpStage.media,
        maxResponseBytes: 1024 * 1024,
      );
      if (!manifest.trimLeft().startsWith('#EXTM3U')) {
        throw const FormatException('VOE did not return HLS');
      }
      return PlaybackProviderSuccess(
        PlayableSource(
          providerId: source.providerId,
          sourceId: source.id,
          serverId: candidate.id,
          uri: media,
          format: PlaybackMediaFormat.hls,
          sourceLabel: source.displayName,
          displayName: candidate.displayName ?? 'VOE',
          availability: PlaybackAvailability.transportResponded,
          httpHeaders: mediaHeaders,
          subtitles: source.subtitles,
          provenance: 'VOE published player config; Anilili MIT-0',
        ),
      );
    } on PublicPlaybackFailure catch (error) {
      return error.result<PlayableSource>();
    } on FormatException {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
  }

  static Uri? publishedRedirect(String page) {
    final match = RegExp(
      r'''window\.location\.href\s*=\s*["'](https://[^"'<>]{1,2048})["']''',
    ).firstMatch(page);
    final uri = match == null ? null : Uri.tryParse(match.group(1)!);
    return uri != null &&
            !uri.hasQuery &&
            DirectMediaHostResolver.isSyntacticallyPublicHttps(uri)
        ? uri
        : null;
  }

  static Uri? decodeSource(String page) {
    const marker = '<script type="application/json">';
    final open = page.indexOf(marker);
    if (open < 0) return null;
    final end = page.indexOf('</script>', open + marker.length);
    if (end < 0 || end - open > 256 * 1024) return null;
    try {
      final value = jsonDecode(page.substring(open + marker.length, end));
      if (value is! List || value.isEmpty || value.first is! String) {
        return null;
      }
      String text = String.fromCharCodes(
        (value.first as String).codeUnits.map((c) {
          if (c >= 65 && c <= 90) return 65 + (c - 65 + 13) % 26;
          if (c >= 97 && c <= 122) return 97 + (c - 97 + 13) % 26;
          return c;
        }),
      );
      for (final junk in ['@\$', '^^', '~@', '%?', '*~', '!!', '#&']) {
        text = text.replaceAll(junk, '');
      }
      final shifted = base64.decode(base64.normalize(text));
      if (shifted.any((c) => c < 3)) return null;
      text = String.fromCharCodes(shifted.reversed.map((c) => c - 3));
      final config = jsonDecode(
        utf8.decode(base64.decode(base64.normalize(text))),
      );
      if (config is! Map ||
          config['source'] is! String ||
          (config['source'] as String).length > 8192) {
        return null;
      }
      final uri = Uri.tryParse(config['source'] as String);
      return uri != null &&
              DirectMediaHostResolver.isSyntacticallyPublicHttps(uri)
          ? uri
          : null;
    } on FormatException {
      return null;
    }
  }
}
