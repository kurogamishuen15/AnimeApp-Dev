import 'package:anime_app/data/player/providers/animeheaven/animeheaven_playback_provider.dart';
import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers the modular AnimeHeaven provider', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open(
      clock: () => DateTime.utc(2026, 11, 15),
    );
    addTearDown(module.close);

    expect(module.manager.diagnostics, hasLength(1));
    expect(
      module.manager.provider(PlaybackProviderId('animeheaven')),
      isA<AnimeHeavenPlaybackProvider>(),
    );
  });

  test('retains an idempotent application lifecycle hook', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open();

    expect(module.close, returnsNormally);
    expect(module.close, returnsNormally);
  });
}
