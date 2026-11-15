import 'package:material_ui/material_ui.dart';

import 'home_appearance.dart';

/// Platform-system typography with restrained weights and tracking.
/// Supplying a licensed family through HomeAppearance remains an extension.
abstract final class HomeTypography {
  static TextStyle heroTitle(TextStyle? base, HomeAppearance appearance) =>
      _style(base, appearance).copyWith(
        fontSize: _size(base?.fontSize ?? 36, appearance),
        fontWeight: FontWeight.w600,
        letterSpacing: -.65,
        height: 1.04,
      );

  static TextStyle sectionTitle(TextStyle? base, HomeAppearance appearance) =>
      _style(base, appearance).copyWith(
        fontSize: _size(base?.fontSize ?? 20, appearance),
        fontWeight: FontWeight.w600,
        letterSpacing: -.25,
      );

  static TextStyle cardTitle(HomeAppearance appearance) => TextStyle(
    fontFamily: appearance.fontFamily,
    fontSize: _size(14, appearance),
    fontWeight: FontWeight.w600,
    letterSpacing: -.1,
    height: 1.12,
  );

  static TextStyle _style(TextStyle? base, HomeAppearance appearance) =>
      (base ?? const TextStyle()).copyWith(fontFamily: appearance.fontFamily);

  static double _size(double size, HomeAppearance appearance) =>
      size * appearance.typeScale;
}
