import 'dart:convert';

import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';

/// One episode video the user explicitly registered for playback.
final class UserDefinedSourceEntry {
  UserDefinedSourceEntry({
    required this.anime,
    required this.episodeNumber,
    required this.url,
    this.language = 'unknown',
    this.quality,
  }) {
    if (anime.trim().isEmpty || episodeNumber < 1) {
      throw const FormatException(
        'User source needs an anime key and episode.',
      );
    }
    if (url.scheme != 'https' || url.host.isEmpty || url.hasFragment) {
      throw const FormatException('User source URL must be an https URL.');
    }
  }

  /// Local anime ID, or `<provider>:<id>` such as `anilist:21`.
  final String anime;
  final int episodeNumber;
  final Uri url;
  final String language;
  final String? quality;

  /// Parses `{"sources":[{"anime":..,"episode":..,"url":..}]}`.
  /// Throws [FormatException] on any malformed entry instead of skipping it.
  static List<UserDefinedSourceEntry> parseJson(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> || decoded['sources'] is! List) {
      throw const FormatException('Expected an object with a "sources" list.');
    }
    return <UserDefinedSourceEntry>[
      for (final Object? item in decoded['sources'] as List<Object?>)
        if (item is Map<String, Object?>)
          UserDefinedSourceEntry(
            anime: _string(item, 'anime'),
            episodeNumber: _int(item, 'episode'),
            url: Uri.parse(_string(item, 'url')),
            language: item['language'] is String
                ? item['language']! as String
                : 'unknown',
            quality: item['quality'] is String
                ? item['quality']! as String
                : null,
          )
        else
          throw const FormatException('Each user source must be an object.'),
    ];
  }

  static String _string(Map<String, Object?> item, String key) {
    final Object? value = item[key];
    if (value is! String) throw FormatException('Missing "$key".');
    return value;
  }

  static int _int(Map<String, Object?> item, String key) {
    final Object? value = item[key];
    if (value is! int) throw FormatException('Missing integer "$key".');
    return value;
  }
}

/// Serves only the episodes listed by the user. It never discovers anime,
/// never scrapes pages, and leaves hosts to the shared direct-media resolver.
final class UserDefinedPlaybackProvider implements PlaybackSourceProvider {
  UserDefinedPlaybackProvider(Iterable<UserDefinedSourceEntry> entries)
    : _entries = List<UserDefinedSourceEntry>.unmodifiable(entries);

  static final PlaybackProviderId providerId = PlaybackProviderId(
    'user-defined',
  );
  static const String adapterVersion = '1.0.0';

  final List<UserDefinedSourceEntry> _entries;

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
    if (cancellation.isCancelled) {
      return PlaybackProviderFailed<List<PlaybackSource>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );
    }
    final Set<String> keys = <String>{
      episode.animeId.value,
      for (final ExternalAnimeId externalId in episode.externalAnimeIds)
        '${externalId.providerId.value}:${externalId.value}',
    };
    final List<PlaybackSource> sources = <PlaybackSource>[
      for (final (int index, UserDefinedSourceEntry entry) in _entries.indexed)
        if (entry.episodeNumber == episode.episodeNumber &&
            keys.contains(entry.anime))
          PlaybackSource(
            id: 'user-defined-${episode.episodeNumber}-$index',
            providerId: id,
            episode: episode,
            language: entry.language,
            quality: entry.quality ?? 'Auto',
            priority: 50,
            servers: <SourceCandidate>[
              SourceCandidate(
                id: 'user-defined-$index',
                endpoint: entry.url,
                hostId: DirectMediaHostResolver.stableHostId,
                priority: 50,
                kind: PlaybackCandidateKind.media,
                declaredLanguage: entry.language,
                quality: entry.quality,
                sourceEpisodeId: '${episode.episodeNumber}',
                provenance: 'User-registered source list',
              ),
            ],
          ),
    ];
    if (sources.isEmpty) return PlaybackProviderEmpty<List<PlaybackSource>>();
    return PlaybackProviderSuccess<List<PlaybackSource>>(
      List<PlaybackSource>.unmodifiable(sources),
    );
  }
}
