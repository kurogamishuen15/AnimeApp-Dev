import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/data/player/providers/user_sources/user_defined_playback_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers automatic providers and one resolver per host family', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open(
      clock: () => DateTime.utc(2026, 11, 17),
    );
    addTearDown(module.close);

    expect(module.manager.providerRegistrations, hasLength(9));
    expect(
      module.manager.providerRegistrations.map(
        (entry) => entry.provider.id.value,
      ),
      [
        'megaplay',
        'megaplay-dub',
        'miruro-catalog',
        'animeav1',
        'allanime',
        'allanime-dub',
        'anizone',
        'animegg',
        'animegg-dub',
      ],
    );
    expect(
      module.manager.providerRegistrations.first.provider.id.value,
      'megaplay',
    );
    expect(module.manager.providerRegistrations.first.version, '1.0.0');
    expect(module.manager.providerRegistrations.first.cacheTtl, Duration.zero);
    expect(module.manager.resolverRegistrations, hasLength(2));
    expect(
      module.manager.resolverRegistrations
          .where((entry) => entry.resolver.resolverId == 'direct-media')
          .single
          .resolver
          .resolverId,
      'direct-media',
    );
  });

  test('Wikimedia is opt-in and manual sources remain optional', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open(
      enableWikimedia: true,
      userSources: [
        UserDefinedSourceEntry(
          anime: 'anilist:21',
          episodeNumber: 1,
          url: Uri.parse('https://media.example.org/episode.mp4'),
        ),
      ],
    );
    addTearDown(module.close);

    expect(
      module.manager.providerRegistrations.map(
        (item) => item.provider.id.value,
      ),
      [
        'megaplay',
        'megaplay-dub',
        'miruro-catalog',
        'animeav1',
        'allanime',
        'allanime-dub',
        'wikimedia-commons',
        'anizone',
        'animegg',
        'animegg-dub',
        'user-defined',
      ],
    );
  });

  test('can opt out of external network providers', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open(
      enableMiruro: false,
      enableMegaPlay: false,
      enableAnimeAv1: false,
      enableAllAnime: false,
      enableAniZone: false,
      enableAnimeGg: false,
    );
    addTearDown(module.close);

    expect(module.manager.providerRegistrations, isEmpty);
    expect(module.manager.resolverRegistrations, hasLength(1));
  });

  test('close remains idempotent', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open();
    expect(module.close, returnsNormally);
    expect(module.close, returnsNormally);
  });
}
