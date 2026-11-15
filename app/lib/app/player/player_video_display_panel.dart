import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'player_video_display.dart';

/// Changes only presentation scaling on the existing video texture.
final class PlayerVideoDisplayButton extends StatelessWidget {
  const PlayerVideoDisplayButton({required this.display, super.key});

  final PlayerVideoDisplayController display;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('player-display-settings'),
    tooltip: 'Ajuste de imagen',
    icon: const Icon(Icons.aspect_ratio_outlined),
    onPressed: () => unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajuste de imagen'),
          content: SizedBox(
            width: 450,
            child: ValueListenableBuilder<PlayerVideoDisplaySettings>(
              valueListenable: display,
              builder: (context, settings, _) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ajuste'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final fit in PlayerVideoFit.values)
                          ChoiceChip(
                            key: ValueKey('video-fit-${fit.name}'),
                            label: Text(_fitLabel(fit)),
                            selected: settings.fit == fit,
                            onSelected: (_) => display.setFit(fit),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Relación de aspecto'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final aspect in PlayerVideoAspect.values)
                          ChoiceChip(
                            key: ValueKey('video-aspect-${aspect.name}'),
                            label: Text(_aspectLabel(aspect)),
                            selected: settings.aspect == aspect,
                            onSelected: (_) => display.setAspect(aspect),
                          ),
                      ],
                    ),
                    if (settings.fit == PlayerVideoFit.fill)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('Estirar puede deformar la imagen.'),
                      ),
                    if (settings.fit == PlayerVideoFit.originalSize)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Tamaño original no amplía el video; lo reduce si la ventana es menor.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: display.reset,
              child: const Text('Restablecer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _fitLabel(PlayerVideoFit fit) => switch (fit) {
  PlayerVideoFit.contain => 'Ajustar',
  PlayerVideoFit.cover => 'Rellenar',
  PlayerVideoFit.fill => 'Estirar',
  PlayerVideoFit.originalSize => 'Tamaño original',
};

String _aspectLabel(PlayerVideoAspect aspect) => switch (aspect) {
  PlayerVideoAspect.automatic => 'Original',
  PlayerVideoAspect.widescreen => '16:9',
  PlayerVideoAspect.classic => '4:3',
  PlayerVideoAspect.cinema => '21:9',
};
