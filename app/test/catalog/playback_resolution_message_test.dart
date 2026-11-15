import 'package:anime_app/app/catalog/playback_resolution_message.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const empty = PlaybackProviderEmpty<List<ResolvedPlaybackStream>>();

  test('distinguishes no results and unsupported lookup', () {
    expect(
      playbackResolutionMessage(empty),
      'No se encontraron fuentes para este episodio.',
    );
    expect(
      playbackResolutionMessage(
        const PlaybackProviderSuccess<List<ResolvedPlaybackStream>>([]),
      ),
      'No se encontraron fuentes para este episodio.',
    );
    expect(
      playbackResolutionMessage(
        const PlaybackProviderUnsupported<List<ResolvedPlaybackStream>>(
          PlaybackProviderCapability.resolveServer,
        ),
      ),
      'Los proveedores disponibles no admiten esta reproducción.',
    );
  });

  test('maps typed failures to safe messages without exposing transport data', () {
    const expected = {
      PlaybackProviderFailureKind.unavailable:
          'No hay episodio o servidor disponible para esta fuente.',
      PlaybackProviderFailureKind.network: 'No se pudo conectar con los proveedores. Comprueba la conexión e inténtalo de nuevo.',
      PlaybackProviderFailureKind.timeout:
          'La consulta a los proveedores tardó demasiado. Inténtalo de nuevo.',
      PlaybackProviderFailureKind.rateLimited: 'Un proveedor limitó las consultas. Espera un momento e inténtalo de nuevo.',
      PlaybackProviderFailureKind.invalidResponse: 'Un proveedor devolvió una respuesta que la aplicación no pudo validar.',
      PlaybackProviderFailureKind.unauthorized:
          'Un proveedor rechazó la solicitud del episodio.',
      PlaybackProviderFailureKind.unsupported:
          'Los proveedores disponibles no admiten esta reproducción.',
      PlaybackProviderFailureKind.cancelled:
          'La consulta se canceló. Inténtalo de nuevo.',
      PlaybackProviderFailureKind.circuitOpen: 'Los proveedores están temporalmente en pausa tras varios fallos. Inténtalo más tarde.',
    };

    for (final MapEntry<PlaybackProviderFailureKind, String> entry
        in expected.entries) {
      expect(
        playbackResolutionMessage(
          PlaybackProviderFailed<List<ResolvedPlaybackStream>>(
            PlaybackProviderFailure(entry.key),
          ),
        ),
        entry.value,
        reason: entry.key.name,
      );
    }
    expect(expected.values.join(' '), isNot(contains('https://')));
  });
}
