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

enum PlaybackDubbingType {
  unknown,
  originalAudio,
  latinSpanish,
  castilianSpanish,
  other,
}

/// `listed` is intentionally weaker than a transport check or a visible frame.
enum PlaybackAvailability { unknown, listed, transportResponded, playable }

/// A caption published alongside a specific provider episode, never a search result.
final class ProviderSubtitle {
  ProviderSubtitle({
    required this.id,
    required this.uri,
    required this.label,
    this.language = 'unknown',
    this.isDefault = false,
  }) {
    if (!RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(id) ||
        !PlaybackRequestHeaders._isPublicHttpsReferer(uri) ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.toString().length > 8192 ||
        !uri.path.toLowerCase().endsWith('.vtt') ||
        label.trim().isEmpty ||
        label.length > 128 ||
        label.contains(RegExp(r'[\x00-\x1f\x7f]')) ||
        !RegExp(r'^(unknown|[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*)$')
            .hasMatch(language)) {
      throw ArgumentError('Invalid provider subtitle.');
    }
  }
  final String id;
  final Uri uri;
  final String label;
  final String language;
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      other is ProviderSubtitle &&
      id == other.id &&
      uri == other.uri &&
      label == other.label &&
      language == other.language &&
      isDefault == other.isDefault;
  @override
  int get hashCode => Object.hash(id, uri, label, language, isDefault);
}

List<ProviderSubtitle> _validatedSubtitles(
  Iterable<ProviderSubtitle> subtitles,
) {
  final result = List<ProviderSubtitle>.unmodifiable(subtitles);
  if (result.length > 32 ||
      result.map((track) => track.id).toSet().length != result.length) {
    throw ArgumentError('Invalid provider subtitle list.');
  }
  return result;
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
    this.audioLanguage = 'unknown',
    this.subtitleLanguage,
    this.dubbingType = PlaybackDubbingType.unknown,
    this.providerAnnouncedLanguage = 'unknown',
    this.displayName,
    Iterable<ProviderSubtitle> subtitles = const [],
  }) : subtitles = _validatedSubtitles(subtitles),
       servers = List.unmodifiable(servers) {
    if (id.trim().isEmpty ||
        language.trim().isEmpty ||
        quality.trim().isEmpty ||
        audioLanguage.trim().isEmpty ||
        audioLanguage.length > 64 ||
        (subtitleLanguage != null &&
            (subtitleLanguage!.trim().isEmpty ||
                subtitleLanguage!.length > 64)) ||
        providerAnnouncedLanguage.trim().isEmpty ||
        providerAnnouncedLanguage.length > 128 ||
        (displayName != null &&
            (displayName!.trim().isEmpty || displayName!.length > 128)) ||
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

  /// ISO 639 language tag when the source declares it; otherwise `unknown`.
  final String audioLanguage;

  /// ISO 639 language tag when subtitles are explicitly identified.
  final String? subtitleLanguage;
  final PlaybackDubbingType dubbingType;

  /// Provider-declared label kept separate from normalized language fields.
  final String providerAnnouncedLanguage;
  final String? displayName;
  final List<PlaybackServer> servers;
  final List<ProviderSubtitle> subtitles;
}

enum PlaybackCandidateKind { media, embed, redirect }

enum PlaybackMediaFormat { unknown, mp4, hls, dash, webm }

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
    this.mediaFormat = PlaybackMediaFormat.unknown,
    this.quality,
    this.displayName,
    this.availability = PlaybackAvailability.listed,
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
        declaredLanguage.length > 128 ||
        (displayName != null &&
            (displayName!.trim().isEmpty || displayName!.length > 128)) ||
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
  final PlaybackMediaFormat mediaFormat;
  final String? quality;

  /// Human-readable host server name; `id` remains a stable machine key.
  final String? displayName;
  final PlaybackAvailability availability;
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
/// Supports public `Referer`/`Origin`, a per-media `User-Agent`, `Sec-Fetch-Site`
/// (the standard fetch-metadata header a browser sets on its own requests, with
/// no credential content), and two non-secret protocol headers used by public
/// catalog APIs (values are strictly validated; they never carry credentials or
/// cookies). Cookies, authorization credentials, and arbitrary caller-supplied
/// headers are rejected.
final class PlaybackRequestHeaders {
  factory PlaybackRequestHeaders(Map<String, String> values) {
    final Map<String, String> validated = <String, String>{};
    for (final MapEntry<String, String> entry in values.entries) {
      final String? name = switch (entry.key.trim().toLowerCase()) {
        'referer' => 'Referer',
        'origin' => 'Origin',
        'user-agent' => 'User-Agent',
        'sec-fetch-site' => 'Sec-Fetch-Site',
        'x-build-id' => 'x-build-id',
        'x-aa-boot' => 'x-aa-boot',
        _ => null,
      };
      if (name == null || validated.containsKey(name)) {
        throw ArgumentError('Unsupported or duplicate public media header.');
      }
      final String value = entry.value.trim();
      if (entry.value.contains(RegExp(r'[\x00-\x1f\x7f]')) || value.isEmpty) {
        throw ArgumentError('The public media header value is invalid.');
      }
      if (name == 'User-Agent') {
        if (value.length > 512 || value.contains(RegExp(r'[^\x20-\x7e]'))) {
          throw ArgumentError('The public media User-Agent is invalid.');
        }
        validated[name] = value;
        continue;
      }
      if (name == 'Sec-Fetch-Site') {
        // A closed set: the browser fetch-metadata values. It states the
        // relationship between initiator and target, never a permission.
        if (!const <String>{
          'same-origin',
          'same-site',
          'cross-site',
          'none',
        }.contains(value)) {
          throw ArgumentError('The public Sec-Fetch-Site header is invalid.');
        }
        validated[name] = value;
        continue;
      }
      if (name == 'x-build-id') {
        if (!RegExp(r'^[0-9]{1,8}$').hasMatch(value)) {
          throw ArgumentError('The public x-build-id header is invalid.');
        }
        validated[name] = value;
        continue;
      }
      if (name == 'x-aa-boot') {
        if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
          throw ArgumentError('The public x-aa-boot header is invalid.');
        }
        validated[name] = value;
        continue;
      }
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
      if (name == 'Origin' && uri.path.isNotEmpty && uri.path != '/') {
        throw ArgumentError('The public Origin must not contain a path.');
      }
      validated[name] = name == 'Origin' ? uri.origin : uri.toString();
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
    this.sourceLabel,
    this.displayName,
    this.availability = PlaybackAvailability.listed,
    this.expiresAt,
    this.validatedAt,
    this.provenance = 'host resolver',
    this.httpHeaders = const PlaybackRequestHeaders.empty(),
    Iterable<ProviderSubtitle> subtitles = const [],
  }) : subtitles = _validatedSubtitles(subtitles) {
    if (sourceId.trim().isEmpty ||
        serverId.trim().isEmpty ||
        (sourceLabel != null &&
            (sourceLabel!.trim().isEmpty || sourceLabel!.length > 128)) ||
        (displayName != null &&
            (displayName!.trim().isEmpty || displayName!.length > 128)) ||
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
  final String? sourceLabel;
  final String? displayName;
  final PlaybackAvailability availability;
  final DateTime? expiresAt;
  final DateTime? validatedAt;
  final String provenance;
  final PlaybackRequestHeaders httpHeaders;
  final List<ProviderSubtitle> subtitles;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);
}

typedef ResolvedPlaybackStream = PlayableSource;
