import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';

/// Provider-independent identity of an episode requested for playback.
final class PlaybackEpisode {
  PlaybackEpisode({
    required this.animeId,
    required this.episodeNumber,
    this.externalAnimeId,
    Iterable<String> animeTitles = const [],
  }) : animeTitles = List.unmodifiable(
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

  final AnimeId animeId;
  final int episodeNumber;
  final ExternalAnimeId? externalAnimeId;
  final List<String> animeTitles;

  String get requestKey {
    if (externalAnimeId == null && animeTitles.isEmpty) {
      return '${animeId.value}:$episodeNumber';
    }
    final String titles = animeTitles
        .map((String title) => title.toLowerCase())
        .toList()
        .join('|');
    return '${animeId.value}:$episodeNumber:${externalAnimeId?.canonicalKey ?? ''}:$titles';
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

/// A provider's server/endpoint alternative for one playback source.
final class PlaybackServer {
  PlaybackServer({
    required this.id,
    required this.endpoint,
    this.priority = 0,
    this.requestHeaders = const PlaybackRequestHeaders.empty(),
  }) {
    if (id.trim().isEmpty ||
        !const {'http', 'https', 'file'}.contains(endpoint.scheme) ||
        (endpoint.scheme != 'file' && endpoint.host.isEmpty)) {
      throw ArgumentError('Playback server is invalid.');
    }
  }

  final String id;
  final Uri endpoint;
  final int priority;
  final PlaybackRequestHeaders requestHeaders;
}

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
          !_isPublicHttpsOrigin(uri)) {
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

  static bool _isPublicHttpsOrigin(Uri uri) {
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
        (uri.path.isEmpty || uri.path == '/') &&
        host.contains('.') &&
        !host.startsWith('.') &&
        !host.endsWith('.') &&
        !host.contains('_') &&
        !looksLikeIpLiteral &&
        !specialUseHost;
  }
}

/// Resolved data ready to pass to a playback coordinator; never owns a Player.
final class ResolvedPlaybackStream {
  ResolvedPlaybackStream({
    required this.providerId,
    required this.sourceId,
    required this.serverId,
    required this.uri,
    this.httpHeaders = const PlaybackRequestHeaders.empty(),
  }) {
    if (sourceId.trim().isEmpty ||
        serverId.trim().isEmpty ||
        !const {'http', 'https', 'file'}.contains(uri.scheme) ||
        (uri.scheme != 'file' && uri.host.isEmpty)) {
      throw ArgumentError('Resolved playback stream is invalid.');
    }
  }

  final PlaybackProviderId providerId;
  final String sourceId;
  final String serverId;
  final Uri uri;
  final PlaybackRequestHeaders httpHeaders;
}
