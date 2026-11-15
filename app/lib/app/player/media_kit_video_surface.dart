import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'player_video_display.dart';

/// Draws the engine-owned texture without a second set of controls.
final class MediaKitVideoSurface extends StatelessWidget {
  const MediaKitVideoSurface({
    required this.controller,
    required this.display,
    super.key,
  });

  final VideoController controller;
  final PlayerVideoDisplayController display;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<PlayerVideoDisplaySettings>(
        valueListenable: display,
        builder: (context, settings, _) => mediaKitVideoWidgetWithoutControls(
          controller,
          fit: settings.boxFit,
          aspectRatio: settings.aspectRatio,
        ),
      );
}

/// Builds the texture-only media_kit surface used by the F2.2 spike.
///
/// The package defaults to AdaptiveVideoControls. Kongroo owns the only
/// playback controls in this spike, so this must remain null.
@visibleForTesting
Video mediaKitVideoWidgetWithoutControls(
  VideoController controller, {
  BoxFit fit = BoxFit.contain,
  double? aspectRatio,
}) => Video(
  controller: controller,
  fit: fit,
  aspectRatio: aspectRatio,
  controls: NoVideoControls as VideoControlsBuilder?,
);

@visibleForTesting
String mediaKitVideoSurfaceStatusLabel({
  required bool controllerInitialized,
  required bool controllerFailed,
  required int? textureId,
  required bool firstFrameRendered,
  required bool firstFrameFailed,
}) {
  final String controller = controllerFailed
      ? 'failed'
      : controllerInitialized
      ? 'ready'
      : 'initializing';
  final String texture = textureId == null ? 'pending' : 'registered';
  final String frame = firstFrameRendered
      ? 'processed'
      : firstFrameFailed
      ? 'failed'
      : 'pending';
  return 'Controller: $controller · Texture: $texture · First frame: $frame';
}
