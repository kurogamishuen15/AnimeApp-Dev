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
      PlaybackProviderFailureKind.unavailable
          when failure.stage == PlaybackHttpStage.media &&
              failure.httpStatus != null =>
        'El servidor del vídeo respondió HTTP ${failure.httpStatus}. Intenta otra fuente o vuelve más tarde.',
      PlaybackProviderFailureKind.unavailable =>
        'No hay episodio o servidor disponible para esta fuente.',
      PlaybackProviderFailureKind.network => 'No se pudo conectar con los proveedores. Comprueba la conexión e inténtalo de nuevo.',
      PlaybackProviderFailureKind.timeout =>
        'La consulta a los proveedores tardó demasiado. Inténtalo de nuevo.',
      PlaybackProviderFailureKind.rateLimited => switch (failure.retryAfter) {
        final Duration delay =>
          'El proveedor limitó las consultas. Vuelve a intentar en ${(delay.inMilliseconds / 1000).ceil()} s.',
        null => 'Un proveedor limitó las consultas. Espera un momento e inténtalo de nuevo.',
      },
      PlaybackProviderFailureKind.invalidResponse => 'Un proveedor devolvió una respuesta que la aplicación no pudo validar.',
      PlaybackProviderFailureKind.unauthorized =>
        'Un proveedor rechazó la solicitud del episodio.',
      PlaybackProviderFailureKind.unsupported =>
        'Los proveedores disponibles no admiten esta reproducción.',
      PlaybackProviderFailureKind.cancelled =>
        'La consulta se canceló. Inténtalo de nuevo.',
      PlaybackProviderFailureKind.circuitOpen => 'Los proveedores están temporalmente en pausa tras varios fallos. Inténtalo más tarde.',
      PlaybackProviderFailureKind.missingId =>
        'No se pudo identificar este anime en el proveedor.',
      PlaybackProviderFailureKind.noEpisodes =>
        'El proveedor no encontró el episodio solicitado.',
      PlaybackProviderFailureKind.noSources =>
        'El episodio no tiene una fuente de reproducción disponible.',
      PlaybackProviderFailureKind.challenge =>
        'El servidor exige una verificación de navegador.',
      PlaybackProviderFailureKind.policyBlocked =>
        'Una regla de seguridad del servidor rechazó la solicitud.',
      PlaybackProviderFailureKind.ipBlocked =>
        'El servidor bloqueó el acceso desde esta conexión.',
      PlaybackProviderFailureKind.iframeDenied =>
        'El servidor restringe el acceso desde reproductores incrustados.',
      PlaybackProviderFailureKind.geoRestricted =>
        'El servidor restringe la reproducción en esta región.',
      PlaybackProviderFailureKind.drm => 'Esta fuente requiere DRM.',
      PlaybackProviderFailureKind.forbidden
          when failure.stage == PlaybackHttpStage.media =>
        'El servidor del vídeo denegó el acceso (HTTP 403).',
      PlaybackProviderFailureKind.forbidden =>
        'El proveedor denegó la solicitud (HTTP ${failure.httpStatus ?? 403}). Kongroo no la repetirá; consulta los enlaces externos de la ficha si están disponibles.',
      PlaybackProviderFailureKind.blocked =>
        'El proveedor no permite acceder a esta fuente.',
      PlaybackProviderFailureKind.notFound =>
        'La fuente solicitada ya no está disponible.',
      PlaybackProviderFailureKind.unsupportedEmbed =>
        'Esta alternativa solo ofrece un reproductor web incompatible.',
      PlaybackProviderFailureKind.expired =>
        'La fuente de reproducción venció. Vuelve a cargar las alternativas.',
      PlaybackProviderFailureKind.invalidManifest =>
        'El manifiesto multimedia no pasó la validación.',
      PlaybackProviderFailureKind.decoderFailure =>
        'El motor no pudo decodificar el contenido multimedia.',
      PlaybackProviderFailureKind.unknown =>
        'No se pudo clasificar el error de reproducción.',
    },
};
