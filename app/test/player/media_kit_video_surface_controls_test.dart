import 'package:anime_app/app/player/media_kit_video_surface.dart';
import 'package:anime_app/app/player/player_video_display.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  test('F2.2 media_kit surface disables the package control overlay', () {
    final Video video = mediaKitVideoWidgetWithoutControls(
      _UnconfiguredVideoController(),
    );

    expect(video.controls, isNull);
  });

  test('fit and aspect choices remain independent on the sole Video', () {
    final display = PlayerVideoDisplayController();
    addTearDown(display.dispose);
    display.setFit(PlayerVideoFit.cover);
    display.setAspect(PlayerVideoAspect.classic);
    final Video video = mediaKitVideoWidgetWithoutControls(
      _UnconfiguredVideoController(),
      fit: display.value.boxFit,
      aspectRatio: display.value.aspectRatio,
    );
    expect(video.fit, BoxFit.cover);
    expect(video.aspectRatio, 4 / 3);
    expect(video.controls, isNull);
    display.setFit(PlayerVideoFit.originalSize);
    expect(display.value.boxFit, BoxFit.scaleDown);
    expect(display.value.aspectRatio, 4 / 3);
    display.reset();
    expect(display.value.boxFit, BoxFit.contain);
    expect(display.value.aspectRatio, isNull);
  });
}

final class _UnconfiguredVideoController implements VideoController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
