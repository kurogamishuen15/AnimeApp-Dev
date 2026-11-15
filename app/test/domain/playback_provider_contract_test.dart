import 'package:anime_app/data/player/providers/mock/mock_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void playbackSourceProviderContractTests(
  String implementationName,
  PlaybackSourceProvider Function() createProvider,
) {
  group('$implementationName playback provider contract', () {
    test('exposes stable identity and declared capabilities', () {
      final PlaybackSourceProvider provider = createProvider();
      expect(provider.id.value, isNotEmpty);
      expect(
        provider.capabilities,
        contains(PlaybackProviderCapability.episodeSources),
      );
      expect(
        provider.capabilities,
        contains(PlaybackProviderCapability.resolveServer),
      );
    });

    test('returns normalized source and server alternatives', () async {
      final PlaybackSourceProvider provider = createProvider();
      final PlaybackProviderResult<List<PlaybackSource>> result = await provider
          .findSources(
            PlaybackEpisode(animeId: AnimeId('kongroo-test'), episodeNumber: 3),
            cancellation: PlaybackCancellationToken(),
          );
      expect(result, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      final List<PlaybackSource> sources =
          (result as PlaybackProviderSuccess<List<PlaybackSource>>).value;
      expect(sources, isNotEmpty);
      expect(
        sources.every((PlaybackSource item) => item.providerId == provider.id),
        isTrue,
      );
      expect(
        sources.every((PlaybackSource item) => item.servers.isNotEmpty),
        isTrue,
      );
      expect(() => sources.add(sources.first), throwsUnsupportedError);
    });

    test('can resolve a server without owning a playback engine', () async {
      final MockPlaybackProvider provider =
          createProvider() as MockPlaybackProvider;
      final PlaybackProviderSuccess<List<PlaybackSource>> sources =
          await provider.findSources(
            PlaybackEpisode(animeId: AnimeId('kongroo-test'), episodeNumber: 1),
            cancellation: PlaybackCancellationToken(),
          ) as PlaybackProviderSuccess<List<PlaybackSource>>;
      final PlaybackSource source = sources.value.first;
      final PlaybackServer server = source.servers.first;
      final PlaybackProviderResult<ResolvedPlaybackStream> result =
          await provider.resolveServer(
            source,
            server,
            cancellation: PlaybackCancellationToken(),
          );
      expect(result, isA<PlaybackProviderSuccess<ResolvedPlaybackStream>>());
      final ResolvedPlaybackStream stream =
          (result as PlaybackProviderSuccess<ResolvedPlaybackStream>).value;
      expect(stream.providerId, provider.id);
      expect(stream.sourceId, source.id);
      expect(stream.serverId, server.id);
      expect(stream.uri, server.endpoint);
    });
  });
}

void main() {
  playbackSourceProviderContractTests(
    'MockPlaybackProvider',
    () => MockPlaybackProvider(id: PlaybackProviderId('contract-mock')),
  );

  test(
    'typed empty, timeout, provider error, malformed and cancellation results',
    () async {
      final PlaybackEpisode episode = PlaybackEpisode(
        animeId: AnimeId('contract-case'),
        episodeNumber: 1,
      );
      Future<PlaybackProviderResult<List<PlaybackSource>>> query(
        MockPlaybackScenario scenario, {
        PlaybackCancellationToken? cancellation,
      }) =>
          MockPlaybackProvider(
            id: PlaybackProviderId('case-${scenario.name}'),
            scenario: scenario,
          ).findSources(
            episode,
            cancellation: cancellation ?? PlaybackCancellationToken(),
          );

      expect(
        await query(MockPlaybackScenario.empty),
        isA<PlaybackProviderEmpty<List<PlaybackSource>>>(),
      );
      final PlaybackProviderFailed<List<PlaybackSource>> timeout = await query(
        MockPlaybackScenario.timeout,
      ) as PlaybackProviderFailed<List<PlaybackSource>>;
      expect(timeout.failure.kind, PlaybackProviderFailureKind.timeout);
      final PlaybackProviderFailed<List<PlaybackSource>> providerError =
          await query(MockPlaybackScenario.providerError)
              as PlaybackProviderFailed<List<PlaybackSource>>;
      expect(providerError.failure.kind, PlaybackProviderFailureKind.network);
      expect(
        await query(MockPlaybackScenario.malformed),
        isA<PlaybackProviderSuccess<List<PlaybackSource>>>(),
        reason:
            'The manager, not raw provider DTO parsing, validates ownership.',
      );

      final PlaybackCancellationToken cancelled = PlaybackCancellationToken()
        ..cancel();
      final PlaybackProviderFailed<List<PlaybackSource>> cancellation =
          await query(MockPlaybackScenario.valid, cancellation: cancelled)
              as PlaybackProviderFailed<List<PlaybackSource>>;
      expect(cancellation.failure.kind, PlaybackProviderFailureKind.cancelled);
    },
  );

  test('provider identifiers reject invalid values', () {
    expect(() => PlaybackProviderId('../external'), throwsArgumentError);
    expect(PlaybackProviderId(' MOCK ').value, 'mock');
  });
}
