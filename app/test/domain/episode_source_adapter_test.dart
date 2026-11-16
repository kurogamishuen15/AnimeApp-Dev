import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AnimeIdentity identity = AnimeIdentity(
    localId: AnimeId('frieren'),
    externalIds: [
      ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '20987',
      ),
    ],
    titles: const ['Frieren: Beyond Journey’s End', 'Sousou no Frieren'],
  );

  test(
    'adapter orchestration keeps identity, episode and source phases apart',
    () async {
      final _FixtureEpisodeAdapter adapter = _FixtureEpisodeAdapter(identity);
      final PlaybackProviderResult<List<PlaybackSource>> result = await adapter
          .findSources(
            PlaybackEpisode.fromIdentity(identity, episodeNumber: 2),
            cancellation: PlaybackCancellationToken(),
          );

      expect(adapter.calls, ['search', 'episodes', 'sources:2']);
      expect(result, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      final List<PlaybackSource> sources =
          (result as PlaybackProviderSuccess<List<PlaybackSource>>).value;
      expect(sources.single.episode.episodeNumber, 2);
      expect(sources.single.servers.single.hostId, 'cdn.example');
      expect(sources.single.servers.single.kind, PlaybackCandidateKind.media);
    },
  );

  test(
    'fuzzy or conflicting identity matches never reach episode lookup',
    () async {
      final _FixtureEpisodeAdapter adapter = _FixtureEpisodeAdapter(
        identity,
        evidence: AnimeMatchEvidence.fuzzy,
        externalIds: [
          ExternalAnimeId(
            providerId: MetadataProviderId('anilist'),
            value: '99999',
          ),
        ],
        title: 'Frieren: Beyond Journey’s End (Movie)',
      );
      final PlaybackProviderResult<List<PlaybackSource>> result = await adapter
          .findSources(
            PlaybackEpisode.fromIdentity(identity, episodeNumber: 1),
            cancellation: PlaybackCancellationToken(),
          );

      expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
      expect(adapter.calls, ['search']);
    },
  );

  test('cancellation before lookup avoids provider work', () async {
    final _FixtureEpisodeAdapter adapter = _FixtureEpisodeAdapter(identity);
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken()
      ..cancel();

    final PlaybackProviderResult<List<PlaybackSource>> result = await adapter
        .findSources(
          PlaybackEpisode.fromIdentity(identity, episodeNumber: 1),
          cancellation: cancellation,
        );

    expect(result, isA<PlaybackProviderFailed<List<PlaybackSource>>>());
    expect(adapter.calls, isEmpty);
  });
}

final class _FixtureEpisodeAdapter extends EpisodeSourceAdapter {
  _FixtureEpisodeAdapter(
    this.identity, {
    this.evidence = AnimeMatchEvidence.externalId,
    List<ExternalAnimeId>? externalIds,
    this.title = 'Frieren: Beyond Journey’s End',
  }) : externalIds = externalIds ?? identity.externalIds;

  final AnimeIdentity identity;
  final AnimeMatchEvidence evidence;
  final List<ExternalAnimeId> externalIds;
  final String title;
  final List<String> calls = [];

  @override
  final PlaybackProviderId id = PlaybackProviderId('fixture-adapter');

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
  };

  SourceAnimeMatch _match(AnimeIdentity requestedIdentity) => SourceAnimeMatch(
    providerId: id,
    sourceAnimeId: 'frieren-series',
    title: title,
    requestedIdentity: requestedIdentity,
    evidence: evidence,
    externalIds: externalIds,
    adapterVersion: '0.1.0',
  );

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity requestedIdentity, {
    required PlaybackCancellationToken cancellation,
  }) async {
    calls.add('search');
    return PlaybackProviderSuccess([_match(requestedIdentity)]);
  }

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) async {
    calls.add('episodes');
    return PlaybackProviderSuccess([
      EpisodeRef(anime: match, episodeId: 'episode-one', episodeNumber: 1),
      EpisodeRef(anime: match, episodeId: 'episode-two', episodeNumber: 2),
    ]);
  }

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) async {
    calls.add('sources:${episode.episodeNumber}');
    return PlaybackProviderSuccess([
      PlaybackSource(
        id: 'source-${episode.episodeNumber}',
        providerId: id,
        episode: PlaybackEpisode.fromIdentity(
          episode.anime.requestedIdentity,
          episodeNumber: episode.episodeNumber,
        ),
        language: 'unknown',
        quality: 'unknown',
        servers: [
          SourceCandidate(
            id: 'cdn-${episode.episodeNumber}',
            hostId: 'cdn.example',
            endpoint: Uri.https('cdn.example', '/video.mp4'),
            kind: PlaybackCandidateKind.media,
            provenance: 'fixture: static contract test',
          ),
        ],
      ),
    ]);
  }
}
