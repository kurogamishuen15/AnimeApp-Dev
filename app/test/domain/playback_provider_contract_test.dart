import 'package:anime_app/data/player/providers/mock/mock_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
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
        isNot(contains(PlaybackProviderCapability.resolveServer)),
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
          await provider.resolve(
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
  test(
    'provider captions reject private, active and non-HTTPS destinations',
    () {
      for (final value in [
        'https://127.0.0.1/es.vtt',
        'http://captions.anime.org/es.vtt',
        'https://user:password@captions.anime.org/es.vtt',
        'https://captions.anime.org/es.html',
        'https://captions.local/es.vtt',
      ]) {
        expect(
          () => ProviderSubtitle(
            id: 'es',
            uri: Uri.parse(value),
            label: 'Spanish',
          ),
          throwsArgumentError,
        );
      }
    },
  );

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

  test('playback bridge preserves all namespaced external anime IDs', () {
    final ExternalAnimeId anilistId = ExternalAnimeId(
      providerId: MetadataProviderId('anilist'),
      value: '21',
    );
    final ExternalAnimeId malId = ExternalAnimeId(
      providerId: MetadataProviderId('myanimelist'),
      value: '123',
    );
    final AnimeIdentity identity = AnimeIdentity(
      localId: AnimeId('multi-crosswalk'),
      externalIds: [anilistId, malId],
      titles: ['One Piece'],
    );

    final PlaybackEpisode fromIdentity = PlaybackEpisode.fromIdentity(
      identity,
      episodeNumber: 7,
    );
    final PlaybackEpisode reversed = PlaybackEpisode(
      animeId: identity.localId,
      episodeNumber: 7,
      externalAnimeIds: [malId, anilistId],
      animeTitles: identity.titles,
    );

    expect(fromIdentity.identity.externalIds, [anilistId, malId]);
    expect(fromIdentity.externalAnimeId, anilistId);
    expect(fromIdentity.requestKey, reversed.requestKey);
  });

  test('playback request context permits public Referer and User-Agent', () {
    final PlaybackRequestHeaders headers = PlaybackRequestHeaders({
      'referer': 'https://www.animegg.org/watch/episode-1',
    });
    expect(headers.values, {
      'Referer': 'https://www.animegg.org/watch/episode-1',
    });
    expect(PlaybackRequestHeaders({'user-agent': 'Kongroo/1.0'}).values, {
      'User-Agent': 'Kongroo/1.0',
    });
    // Fetch-metadata context: a closed, non-credential set.
    expect(
      PlaybackRequestHeaders({'sec-fetch-site': 'same-origin'}).values,
      {'Sec-Fetch-Site': 'same-origin'},
    );
    for (final String invalid in <String>[
      'same-origin; Bearer x',
      'unknown',
      'SAME-ORIGIN',
      '',
    ]) {
      expect(
        () => PlaybackRequestHeaders({'Sec-Fetch-Site': invalid}),
        throwsArgumentError,
      );
    }
    expect(
      () =>
          PlaybackRequestHeaders({'user-agent': 'Kongroo\r\nCookie: private'}),
      throwsArgumentError,
    );
    expect(
      () => PlaybackRequestHeaders({'Cookie': 'session=private'}),
      throwsArgumentError,
    );
    expect(
      () => PlaybackRequestHeaders({'Authorization': 'Bearer private'}),
      throwsArgumentError,
    );
    expect(
      () => PlaybackRequestHeaders({'Referer': 'http://example.org/'}),
      throwsArgumentError,
    );
    for (final String nonPublicOrigin in [
      'https://localhost/',
      'https://provider.local/',
      'https://provider.localhost/',
      'https://provider.onion/',
      'https://127.0.0.1/',
      'https://[::1]/',
      'https://provider.example:8443/',
    ]) {
      expect(
        () => PlaybackRequestHeaders({'Referer': nonPublicOrigin}),
        throwsArgumentError,
        reason: 'Rejected non-public or non-origin Referer: $nonPublicOrigin',
      );
    }
    expect(
      () => PlaybackRequestHeaders({
        'Referer': 'https://provider.example/episode/1?token=private',
      }),
      throwsArgumentError,
    );
    expect(
      () =>
          PlaybackRequestHeaders({'Referer': 'https://example.org/?key=value'}),
      throwsArgumentError,
    );
    expect(
      () =>
          PlaybackRequestHeaders({'Referer': 'https://user:pass@example.org/'}),
      throwsArgumentError,
    );
    expect(
      () => PlaybackRequestHeaders({
        'Referer': 'https://example.org/\r\nCookie: x',
      }),
      throwsArgumentError,
    );
  });

  test('Origin carries a public HTTPS origin without request data', () {
    expect(
      PlaybackRequestHeaders({'origin': 'https://megaplay.buzz/'}).values,
      {'Origin': 'https://megaplay.buzz'},
    );
    for (final value in [
      'http://example.org',
      'https://example.org/episode',
      'https://example.org/?secret=x',
      'https://example.org/#fragment',
      'https://user:password@example.org',
      'https://127.0.0.1',
      'https://example.org:8443',
      'https://example.org/\r\nCookie: private',
    ]) {
      expect(
        () => PlaybackRequestHeaders({'Origin': value}),
        throwsArgumentError,
        reason: value,
      );
    }
    expect(
      () => PlaybackRequestHeaders({
        'Origin': 'https://example.org',
        'origin': 'https://example.net',
      }),
      throwsArgumentError,
    );
  });
}
