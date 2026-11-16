import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';

import 'anime_identity.dart';

/// Provider-independent identity of an episode requested for playback.
final class PlaybackEpisode {
  PlaybackEpisode({
    required this.animeId,
    required this.episodeNumber,
    ExternalAnimeId? externalAnimeId,
    Iterable<ExternalAnimeId> externalAnimeIds = const [],
    Iterable<String> animeTitles = const [],
  }) : externalAnimeIds = List.unmodifiable(<ExternalAnimeId>{
         ...externalAnimeIds,
         ?externalAnimeId,
       }),
       animeTitles = List.unmodifiable(
         animeTitles
             .map((String title) => title.trim())
             .where((String title) => title.isNotEmpty)
             .toSet(),
       ) {
    if (episodeNumber < 1) {
      throw ArgumentError.value(episodeNumber, 'episodeNumber');
    }
    if (this.animeTitles.any((String title) => title.length > 256)) {
      throw ArgumentError('Playback anime titles are too long.');
    }
  }

  factory PlaybackEpisode.fromIdentity(
    AnimeIdentity identity, {
    required int episodeNumber,
  }) => PlaybackEpisode(
    animeId: identity.localId,
    episodeNumber: episodeNumber,
    externalAnimeIds: identity.externalIds,
    animeTitles: identity.titles,
  );

  final AnimeId animeId;
  final int episodeNumber;
  final List<ExternalAnimeId> externalAnimeIds;
  ExternalAnimeId? get externalAnimeId =>
      externalAnimeIds.isEmpty ? null : externalAnimeIds.first;
  final List<String> animeTitles;

  AnimeIdentity get identity => AnimeIdentity(
    localId: animeId,
    externalIds: externalAnimeIds,
    titles: animeTitles,
  );

  String get requestKey {
    if (externalAnimeIds.isEmpty && animeTitles.isEmpty) {
      return '${animeId.value}:$episodeNumber';
    }
    final List<String> external =
        externalAnimeIds.map((ExternalAnimeId id) => id.canonicalKey).toList()
          ..sort();
    final List<String> titles =
        animeTitles.map((String title) => title.toLowerCase()).toSet().toList()
          ..sort();
    String frame(List<String> values) =>
        '${values.length}[${values.map((String value) => '${value.length}:$value').join()}]';

    final String localId = animeId.value;
    return '${localId.length}:$localId;$episodeNumber;'
        '${frame(external)}${frame(titles)}';
  }
}

/// Stable provider identifier, independent from a provider's JSON format.
final class PlaybackProviderId {
  factory PlaybackProviderId(String value) {
    final String normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(normalized)) {
      throw ArgumentError.value(
        value,
        'value',
        'Invalid playback provider ID.',
      );
    }
    return PlaybackProviderId._(normalized);
  }

  const PlaybackProviderId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is PlaybackProviderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// A concrete episode source returned by one provider.
final class PlaybackSource {
  PlaybackSource({
    required this.id,
    required this.providerId,
    required this.episode,
    required this.language,
    required this.quality,
    required Iterable<PlaybackServer> servers,
    this.priority = 0,
  }) : servers = List.unmodifiable(servers) {
    if (id.trim().isEmpty ||
        language.trim().isEmpty ||
        quality.trim().isEmpty ||
        this.servers.isEmpty ||
        this.servers.map((PlaybackServer item) => item.id).toSet().length !=
            this.servers.length) {
      throw ArgumentError('Playback source is invalid.');
    }
  }

  final String id;
  final PlaybackProviderId providerId;
  final PlaybackEpisode episode;
  final String language;
  final String quality;
  final int priority;
  final List<PlaybackServer> servers;
}

enum PlaybackCandidateKind { media, embed, redirect }

enum PlaybackMediaFormat { unknown, mp4, hls, dash }

/// One provider-published endpoint candidate, including its host identity and
/// presentation modality. `PlaybackServer` remains a source-compatible alias.
final class SourceCandidate {
  SourceCandidate({
    required this.id,
    required this.endpoint,
    String? hostId,
    this.priority = 0,
    this.kind = PlaybackCandidateKind.media,
    this.declaredLanguage = 'unknown',
    this.quality,
    this.sourceEpisodeId,
    this.expiresAt,
    this.provenance = 'provider candidate',
    this.requestHeaders = const PlaybackRequestHeaders.empty(),
  }) : hostId = (hostId ?? _hostIdFor(endpoint)).trim().toLowerCase() {
    if (id.trim().isEmpty ||
        !RegExp(r'^[a-z0-9][a-z0-9._-]{0,127}$').hasMatch(this.hostId) ||
        !const {'http', 'https', 'file'}.contains(endpoint.scheme) ||
        (endpoint.scheme != 'file' && endpoint.host.isEmpty) ||
        declaredLanguage.trim().isEmpty ||
        (quality != null && quality!.length > 64) ||
        (sourceEpisodeId != null &&
            (sourceEpisodeId!.trim().isEmpty ||
                sourceEpisodeId!.length > 256)) ||
        provenance.trim().isEmpty ||
        provenance.length > 512) {
      throw ArgumentError('Playback server is invalid.');
    }
  }

  final String id;
  final Uri endpoint;
  final String hostId;
  final int priority;
  final PlaybackCandidateKind kind;
  final String declaredLanguage;
  final String? quality;
  final String? sourceEpisodeId;
  final DateTime? expiresAt;
  final String provenance;
  final PlaybackRequestHeaders requestHeaders;

  /// Circuit key bound to the actual destination origin, not provider input.
  String get hostKey => _hostIdFor(endpoint);

  static String _hostIdFor(Uri uri) =>
      uri.scheme == 'file' ? 'local' : uri.host.toLowerCase();
}

typedef PlaybackServer = SourceCandidate;

/// Public, non-authentication HTTP context required by a media endpoint.
///
/// Only a `Referer` is currently supported. Cookies, authorization
/// credentials, and arbitrary caller-supplied headers are rejected.
final class PlaybackRequestHeaders {
  factory PlaybackRequestHeaders(Map<String, String> values) {
    final Map<String, String> validated = <String, String>{};
    for (final MapEntry<String, String> entry in values.entries) {
      if (entry.key.trim().toLowerCase() != 'referer' ||
          validated.containsKey('Referer')) {
        throw ArgumentError('Only one public Referer header is supported.');
      }
      final String value = entry.value.trim();
      final Uri? uri = Uri.tryParse(value);
      if (value.length > 2048 ||
          value.contains('\r') ||
          value.contains('\n') ||
          uri == null ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          !_isPublicHttpsReferer(uri)) {
        throw ArgumentError('The public Referer header is invalid.');
      }
      validated['Referer'] = uri.toString();
    }
    return PlaybackRequestHeaders._(Map.unmodifiable(validated));
  }

  const PlaybackRequestHeaders.empty() : values = const {};

  const PlaybackRequestHeaders._(this.values);

  final Map<String, String> values;

  bool get isEmpty => values.isEmpty;

  static bool _isPublicHttpsReferer(Uri uri) {
    final String host = uri.host.toLowerCase();
    const Set<String> specialUseSuffixes = {
      'localhost',
      'local',
      'internal',
      'test',
      'invalid',
      'example',
      'onion',
    };
    final bool looksLikeIpLiteral =
        host.contains(':') || RegExp(r'^[0-9.]+$').hasMatch(host);
    final bool specialUseHost = specialUseSuffixes.any(
      (String suffix) => host == suffix || host.endsWith('.$suffix'),
    );
    return uri.scheme == 'https' &&
        uri.port == 443 &&
        host.contains('.') &&
        !host.startsWith('.') &&
        !host.endsWith('.') &&
        !host.contains('_') &&
        !looksLikeIpLiteral &&
        !specialUseHost;
  }
}

/// Normalized media ready for the existing playback coordinator; never owns a
/// Player. Embeds and redirects are not valid playable sources.
final class PlayableSource {
  PlayableSource({
    required this.providerId,
    required this.sourceId,
    required this.serverId,
    required this.uri,
    this.format = PlaybackMediaFormat.unknown,
    this.expiresAt,
    this.validatedAt,
    this.provenance = 'host resolver',
    this.httpHeaders = const PlaybackRequestHeaders.empty(),
  }) {
    if (sourceId.trim().isEmpty ||
        serverId.trim().isEmpty ||
        provenance.trim().isEmpty ||
        provenance.length > 512 ||
        !const {'http', 'https', 'file'}.contains(uri.scheme) ||
        (uri.scheme != 'file' && uri.host.isEmpty)) {
      throw ArgumentError('Resolved playback stream is invalid.');
    }
  }

  final PlaybackProviderId providerId;
  final String sourceId;
  final String serverId;
  final Uri uri;
  final PlaybackMediaFormat format;
  final DateTime? expiresAt;
  final DateTime? validatedAt;
  final String provenance;
  final PlaybackRequestHeaders httpHeaders;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);
}

typedef ResolvedPlaybackStream = PlayableSource;
