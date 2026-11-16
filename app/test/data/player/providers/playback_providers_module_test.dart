import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers the first source adapter and one shared host resolver', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open(
      clock: () => DateTime.utc(2026, 11, 15),
    );
    addTearDown(module.close);

    expect(module.manager.diagnostics, hasLength(1));
    expect(module.manager.diagnostics.single.id.value, 'animesdigital');
    expect(module.manager.diagnostics.single.version, '1.0.0');
    expect(module.manager.resolverRegistrations, hasLength(1));
    expect(
      module.manager.resolverRegistrations.single.resolver.resolverId,
      'direct-media',
    );
    expect(
      module.manager.provider(PlaybackProviderId('animesdigital')),
      isNotNull,
    );
    expect(
      module.manager.providerRegistrations.single.cacheTtl,
      Duration.zero,
      reason: 'direct public manifests may expire between source lookups',
    );
  });

  test('retains an idempotent application lifecycle hook without a player', () {
    final PlaybackProvidersModule module = PlaybackProvidersModule.open();

    expect(module.close, returnsNormally);
    expect(module.close, returnsNormally);
  });
}
