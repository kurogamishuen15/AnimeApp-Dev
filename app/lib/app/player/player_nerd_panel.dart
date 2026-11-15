import 'package:material_ui/material_ui.dart';

import '../../application/player/diagnostics/playback_performance.dart';
import '../../application/player/spike_player_coordinator.dart';

/// Top-of-video diagnostics. Sampling belongs to PlaybackPerformanceCollector.
final class PlayerNerdPanel extends StatelessWidget {
  const PlayerNerdPanel({
    required this.coordinator,
    required this.onClose,
    this.samples,
    super.key,
  });

  final SpikePlayerCoordinator coordinator;
  final Stream<PlaybackPerformanceSample>? samples;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720, maxHeight: 270),
    child: Material(
      key: const ValueKey('player-nerd-overlay'),
      color: const Color(0xe6111119),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Estadísticas técnicas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(onPressed: onClose, child: const Text('Cerrar')),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: StreamBuilder<PlaybackPerformanceSample>(
                  stream: samples,
                  builder: (context, snapshot) {
                    final PlaybackPerformanceSample? sample = snapshot.data;
                    final playback = coordinator.state;
                    final selectedAudio = playback.playback.audioTracks
                        .where(
                          (track) =>
                              track.id == playback.playback.selectedAudioId,
                        )
                        .firstOrNull;
                    final uri = playback.sourceUri;
                    final source = uri == null
                        ? 'N/D'
                        : uri.scheme == 'file'
                        ? 'Archivo local'
                        : uri.host == '127.0.0.1'
                        ? 'HTTP local'
                        : uri.scheme.toUpperCase();
                    return SelectableText(
                      [
                        'VIDEO  ${_resolution(sample)} · ${sample?.videoCodec ?? 'N/D'} · ${sample?.pixelFormat ?? 'N/D'}',
                        'FPS fuente: ${_number(sample?.nominalFps)} · salida decoder/filtros: ${_number(sample?.decodedFps)}',
                        'Frames perdidos VO: ${sample?.framesDropped ?? 'N/D'} · decoder: ${sample?.decoderFramesDropped ?? 'N/D'}',
                        'Decodificación: ${sample?.hardwareDecoder ?? 'N/D'} · salida: ${sample?.videoOutput ?? 'N/D'}',
                        'AUDIO  ${sample?.audioCodec ?? selectedAudio?.codec ?? 'N/D'} · ${selectedAudio?.label ?? 'N/D'} · ${sample?.audioChannels ?? 'N/D'} · ${sample?.audioSampleRate ?? 'N/D'} Hz',
                        'Desviación A/V: ${_number(sample?.avSyncSeconds, digits: 3)} s',
                        'RED  $source · caché: ${_number(sample?.cacheSeconds)} s · cargando: ${playback.buffering}',
                        'SISTEMA  RSS: ${sample?.rssBytes == null ? 'N/D' : '${(sample!.rssBytes! / 1048576).toStringAsFixed(1)} MiB'} · CPU: N/D',
                        'Estado: ${playback.status.name} · posición: ${playback.observedPosition.inSeconds} s',
                        if (playback.error != null) 'Error: ${playback.error}',
                        if (sample?.sampleFailed == true)
                          'Lectura nativa no disponible',
                      ].join('\n'),
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _resolution(PlaybackPerformanceSample? sample) {
  final width = sample?.videoWidth;
  final height = sample?.videoHeight;
  return width == null || height == null ? 'N/D' : '$width×$height';
}

String _number(double? value, {int digits = 1}) =>
    value == null ? 'N/D' : value.toStringAsFixed(digits);
