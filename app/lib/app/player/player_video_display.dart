import 'package:flutter/widgets.dart';

/// Presentation-only scaling. It does not alter the decoded stream or Player.
enum PlayerVideoFit { contain, cover, fill, originalSize }

enum PlayerVideoAspect { automatic, widescreen, classic, cinema }

@immutable
final class PlayerVideoDisplaySettings {
  const PlayerVideoDisplaySettings({
    this.fit = PlayerVideoFit.contain,
    this.aspect = PlayerVideoAspect.automatic,
  });

  final PlayerVideoFit fit;
  final PlayerVideoAspect aspect;

  BoxFit get boxFit => switch (fit) {
    PlayerVideoFit.contain => BoxFit.contain,
    PlayerVideoFit.cover => BoxFit.cover,
    PlayerVideoFit.fill => BoxFit.fill,
    // No enlargement; scale down to fit a viewport smaller than the source.
    PlayerVideoFit.originalSize => BoxFit.scaleDown,
  };

  double? get aspectRatio => switch (aspect) {
    PlayerVideoAspect.automatic => null,
    PlayerVideoAspect.widescreen => 16 / 9,
    PlayerVideoAspect.classic => 4 / 3,
    PlayerVideoAspect.cinema => 21 / 9,
  };
}

/// Shared by the menu and the one existing Video widget.
final class PlayerVideoDisplayController
    extends ValueNotifier<PlayerVideoDisplaySettings> {
  PlayerVideoDisplayController() : super(const PlayerVideoDisplaySettings());

  void setFit(PlayerVideoFit fit) =>
      value = PlayerVideoDisplaySettings(fit: fit, aspect: value.aspect);

  void setAspect(PlayerVideoAspect aspect) =>
      value = PlayerVideoDisplaySettings(fit: value.fit, aspect: aspect);

  void reset() => value = const PlayerVideoDisplaySettings();
}
