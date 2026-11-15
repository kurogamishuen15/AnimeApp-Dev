import '../../domain/player/providers/playback_provider_contract.dart';
import '../../domain/player/providers/playback_source.dart';

/// User-safe explanation for a playback lookup that produced no candidates.
///
/// Provider URLs, response bodies and transport exceptions stay in the data
/// boundary and are never copied into UI messages.
String? playbackResolutionMessage(
  PlaybackProviderResult<List<ResolvedPlaybackStream>> result,
) => switch (result) {
  PlaybackProviderSuccess<List<ResolvedPlaybackStream>>(:final value)
      when value.isNotEmpty =>
    null,
  PlaybackProviderSuccess<List<ResolvedPlaybackStream>>() ||
  PlaybackProviderEmpty<List<ResolvedPlaybackStream>>() =>
    'No se encontraron fuentes para este episodio.',
  PlaybackProviderUnsupported<List<ResolvedPlaybackStream>>() =>
    'Los proveedores disponibles no admiten esta reproducción.',
  PlaybackProviderFailed<List<ResolvedPlaybackStream>>(:final failure) =>
    switch (failure.kind) {
      PlaybackProviderFailureKind.unavailable =>
        'No hay episodio o servidor disponible para esta fuente.',
      PlaybackProviderFailureKind.network => 'No se pudo conectar con los proveedores. Comprueba la conexión e inténtalo de nuevo.',
      PlaybackProviderFailureKind.timeout =>
        'La consulta a los proveedores tardó demasiado. Inténtalo de nuevo.',
      PlaybackProviderFailureKind.rateLimited => 'Un proveedor limitó las consultas. Espera un momento e inténtalo de nuevo.',
      PlaybackProviderFailureKind.invalidResponse => 'Un proveedor devolvió una respuesta que la aplicación no pudo validar.',
      PlaybackProviderFailureKind.unauthorized =>
        'Un proveedor rechazó la solicitud del episodio.',
      PlaybackProviderFailureKind.unsupported =>
        'Los proveedores disponibles no admiten esta reproducción.',
      PlaybackProviderFailureKind.cancelled =>
        'La consulta se canceló. Inténtalo de nuevo.',
      PlaybackProviderFailureKind.circuitOpen => 'Los proveedores están temporalmente en pausa tras varios fallos. Inténtalo más tarde.',
    },
};
