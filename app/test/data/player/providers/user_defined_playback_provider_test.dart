import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/data/player/providers/user_sources/user_defined_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String json = '''
{"sources":[
  {"anime":"local-1","episode":2,"url":"https://media.example.org/a.m3u8","language":"ja","quality":"720p"},
  {"anime":"anilist:21","episode":1,"url":"https://media.example.org/b.m3u8"}
]}''';

  PlaybackEpisode episode({
    String local = 'local-1',
    int number = 2,
    bool withAniList = false,
  }) => PlaybackEpisode(
    animeId: AnimeId(local),
    episodeNumber: number,
    externalAnimeIds: withAniList
        ? [
            ExternalAnimeId(
              providerId: MetadataProviderId('anilist'),
              value: '21',
            ),
          ]
        : const [],
  );

  test('parses the user list and rejects malformed entries', () {
    final entries = UserDefinedSourceEntry.parseJson(json);
    expect(entries, hasLength(2));
    expect(entries.first.language, 'ja');
    expect(entries.last.language, 'unknown');
    expect(
      () => UserDefinedSourceEntry.parseJson('{"sources":[{"anime":"x"}]}'),
      throwsFormatException,
    );
    expect(
      () => UserDefinedSourceEntry.parseJson(
        '{"sources":[{"anime":"x","episode":1,"url":"http://insecure.example/a"}]}',
      ),
      throwsFormatException,
    );
    expect(() => UserDefinedSourceEntry.parseJson('[]'), throwsFormatException);
  });

  test(
    'matches by local anime ID and by provider:id, only same episode',
    () async {
      final provider = UserDefinedPlaybackProvider(
        UserDefinedSourceEntry.parseJson(json),
      );
      final cancellation = PlaybackCancellationToken();

      final local = await provider.findSources(
        episode(),
        cancellation: cancellation,
      );
      expect(local, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      final localSources =
          (local as PlaybackProviderSuccess<List<PlaybackSource>>).value;
      expect(
        localSources.single.servers.single.hostId,
        DirectMediaHostResolver.stableHostId,
      );
      expect(localSources.single.quality, '720p');

      final byExternal = await provider.findSources(
        episode(local: 'other', number: 1, withAniList: true),
        cancellation: cancellation,
      );
      expect(byExternal, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());

      final none = await provider.findSources(
        episode(local: 'other', number: 2),
        cancellation: cancellation,
      );
      expect(none, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    },
  );

  test('is not registered when the user supplies no entries', () {
    final module = PlaybackProvidersModule.open();
    addTearDown(module.close);
    expect(
      module.manager.diagnostics.map((diagnostic) => diagnostic.id.value),
      contains('miruro-catalog'),
    );
    expect(
      module.manager.diagnostics.map((diagnostic) => diagnostic.id.value),
      isNot(contains('user-defined')),
    );
  });

  test('registers the user provider only when entries exist', () {
    final module = PlaybackProvidersModule.open(
      enableMiruro: false,
      enableMegaPlay: false,
      enableAnimeAv1: false,
      enableAllAnime: false,
      enableAniZone: false,
      enableAnimeGg: false,
      userSources: UserDefinedSourceEntry.parseJson(json),
    );
    addTearDown(module.close);
    expect(module.manager.diagnostics.single.id.value, 'user-defined');
  });
}
