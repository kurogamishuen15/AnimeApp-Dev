import '../../../domain/player/providers/anime_identity.dart';
import '../../../domain/player/providers/episode_source.dart';
import '../../../domain/player/providers/playback_provider_contract.dart';
import '../../../domain/player/providers/playback_source.dart';
import 'hosts/direct_media_host_resolver.dart';
import 'public_playback_http.dart';

/// Shared mapping for public episode indexes identified by a unique exact title.
abstract base class PublicEpisodeProvider extends EpisodeSourceAdapter {
  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    PlaybackProviderCapability.sourceAlternatives,
  };

  Future<PlaybackProviderResult<T>> read<T>(Future<T?> Function() load) async {
    try {
      final T? value = await load();
      if (value == null) return PlaybackProviderEmpty<T>();
      return PlaybackProviderSuccess<T>(value);
    } on PublicPlaybackFailure catch (failure) {
      return failure.result();
    } on FormatException {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
  }

  List<SourceAnimeMatch>? exactMatches(
    AnimeIdentity identity,
    Map<String, String> titlesBySlug,
  ) {
    final matches = [
      for (final MapEntry(key: slug, value: title) in titlesBySlug.entries)
        if (validSlug(slug) && title.trim().isNotEmpty && title.length <= 256)
          SourceAnimeMatch(
            providerId: id,
            sourceAnimeId: slug,
            title: title,
            requestedIdentity: identity,
            evidence: AnimeMatchEvidence.exactTitle,
            adapterVersion: adapterVersion,
          ),
    ].where((match) => match.isConservativeMatch()).toList();
    if (matches.length > 1) throw const FormatException('Ambiguous title');
    return matches.isEmpty ? null : matches;
  }

  List<EpisodeRef> episodes(SourceAnimeMatch match, Iterable<int> numbers) => [
    for (final int number in numbers.where((number) => number > 0).toSet())
      EpisodeRef(
        anime: match,
        episodeId: episodePath(match.sourceAnimeId, number),
        episodeNumber: number,
      ),
  ];

  String episodePath(String slug, int number);

  bool validSlug(String slug) => RegExp(r'^[a-z0-9-]{1,160}$').hasMatch(slug);

  bool allowsDirectMedia(Uri uri) => false;

  List<PlaybackSource>? sources(
    EpisodeRef episode,
    Iterable<(String, Uri)> alternatives, {
    PlaybackRequestHeaders mediaHeaders = const PlaybackRequestHeaders.empty(),
  }) {
    final Set<Uri> seen = {};
    final List<SourceCandidate> servers = [];
    for (final (String label, Uri uri) in alternatives) {
      if (servers.length >= 16) break;
      if (uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.port != 443 ||
          uri.userInfo.isNotEmpty ||
          uri.hasFragment ||
          !RegExp(r'^[a-z0-9.-]{1,128}$').hasMatch(uri.host) ||
          label.trim().isEmpty ||
          label.length > 64 ||
          !seen.add(uri)) {
        continue;
      }
      final bool direct =
          allowsDirectMedia(uri) &&
          DirectMediaHostResolver.formatFor(uri) != PlaybackMediaFormat.unknown;
      servers.add(
        SourceCandidate(
          id: '$label (${servers.length + 1})',
          priority: -servers.length,
          endpoint: uri,
          hostId: direct ? DirectMediaHostResolver.stableHostId : uri.host,
          kind: direct
              ? PlaybackCandidateKind.media
              : PlaybackCandidateKind.embed,
          sourceEpisodeId: episode.episodeId,
          requestHeaders: direct
              ? mediaHeaders
              : const PlaybackRequestHeaders.empty(),
          provenance: '${id.value} public episode alternatives',
        ),
      );
    }
    if (servers.isEmpty) return null;
    return [
      PlaybackSource(
        id: episode.episodeId,
        providerId: id,
        episode: PlaybackEpisode.fromIdentity(
          episode.anime.requestedIdentity,
          episodeNumber: episode.episodeNumber,
        ),
        language: 'unknown',
        quality: 'Auto',
        servers: servers,
      ),
    ];
  }
}
