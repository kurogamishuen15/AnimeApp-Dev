import 'package:anime_app/app/player/media_kit_video_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform readiness does not imply a registered texture', () {
    expect(
      mediaKitVideoSurfaceStatusLabel(
        controllerInitialized: true,
        controllerFailed: false,
        textureId: null,
        firstFrameRendered: false,
        firstFrameFailed: false,
      ),
      'Controller: ready · Texture: pending · First frame: pending',
    );
  });

  test('a texture ID and processed first frame have distinct labels', () {
    expect(
      mediaKitVideoSurfaceStatusLabel(
        controllerInitialized: true,
        controllerFailed: false,
        textureId: 17,
        firstFrameRendered: true,
        firstFrameFailed: false,
      ),
      'Controller: ready · Texture: registered · First frame: processed',
    );
  });

  test('controller initialization failure is separate from frame failure', () {
    expect(
      mediaKitVideoSurfaceStatusLabel(
        controllerInitialized: false,
        controllerFailed: true,
        textureId: null,
        firstFrameRendered: false,
        firstFrameFailed: false,
      ),
      'Controller: failed · Texture: pending · First frame: pending',
    );
  });
}
