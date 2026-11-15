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
}

/// Resolved data ready to pass to a playback coordinator; never owns a Player.
final class ResolvedPlaybackStream {
  ResolvedPlaybackStream({
    required this.providerId,
    required this.sourceId,
    required this.serverId,
    required this.uri,
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
}
