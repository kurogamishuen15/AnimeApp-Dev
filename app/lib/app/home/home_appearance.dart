import 'package:material_ui/material_ui.dart';

final class HomeAppearance extends ThemeExtension<HomeAppearance> {
  const HomeAppearance({
    this.lite = false,
    this.surface = const Color(0xff15151b),
    this.accent = const Color(0xffb7adff),
    this.cardActionOverlay = const Color(0xb822222a),
    this.cardActionRadius = 18,
    this.fontFamily,
    this.typeScale = 1,
    this.bannerAutoSlideInterval = const Duration(seconds: 6),
  });

  static const background = Color(0xff000000);
  final bool lite;
  final Color surface;
  final Color accent;
  final Color cardActionOverlay;
  final double cardActionRadius;

  /// Null follows the platform's installed system UI sans-serif.
  final String? fontFamily;
  final double typeScale;
  final Duration bannerAutoSlideInterval;

  static HomeAppearance of(BuildContext context) =>
      Theme.of(context).extension<HomeAppearance>() ?? const HomeAppearance();

  @override
  HomeAppearance copyWith({
    bool? lite,
    Color? surface,
    Color? accent,
    Color? cardActionOverlay,
    double? cardActionRadius,
    String? fontFamily,
    double? typeScale,
    Duration? bannerAutoSlideInterval,
  }) => HomeAppearance(
    lite: lite ?? this.lite,
    surface: surface ?? this.surface,
    accent: accent ?? this.accent,
    cardActionOverlay: cardActionOverlay ?? this.cardActionOverlay,
    cardActionRadius: cardActionRadius ?? this.cardActionRadius,
    fontFamily: fontFamily ?? this.fontFamily,
    typeScale: typeScale ?? this.typeScale,
    bannerAutoSlideInterval:
        bannerAutoSlideInterval ?? this.bannerAutoSlideInterval,
  );

  @override
  HomeAppearance lerp(HomeAppearance? other, double t) => other == null
      ? this
      : HomeAppearance(
          lite: t < .5 ? lite : other.lite,
          surface: Color.lerp(surface, other.surface, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
          cardActionOverlay: Color.lerp(
            cardActionOverlay,
            other.cardActionOverlay,
            t,
          )!,
          cardActionRadius:
              cardActionRadius +
              (other.cardActionRadius - cardActionRadius) * t,
          fontFamily: t < .5 ? fontFamily : other.fontFamily,
          typeScale: typeScale + (other.typeScale - typeScale) * t,
          bannerAutoSlideInterval: t < .5
              ? bannerAutoSlideInterval
              : other.bannerAutoSlideInterval,
        );
}
