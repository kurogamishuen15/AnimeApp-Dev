/// User style mapped to mpv's documented `sub-*` options.
final class SubtitleStyle {
  SubtitleStyle({
    this.fontFamily = 'sans-serif',
    this.fontSize = 38,
    this.color = '#FFFFFFFF',
    this.outlineColor = '#FF000000',
    this.outlineSize = 1.65,
    this.bold = false,
    this.position = 95,
    this.overrideAssStyles = false,
  }) {
    if (fontFamily.trim().isEmpty ||
        fontFamily.length > 128 ||
        fontFamily.contains('\n') ||
        fontFamily.contains('\r')) {
      throw ArgumentError.value(fontFamily, 'fontFamily');
    }
    if (!fontSize.isFinite || fontSize < 12 || fontSize > 96) {
      throw RangeError.range(fontSize, 12, 96, 'fontSize');
    }
    if (!_mpvColor.hasMatch(color) || !_mpvColor.hasMatch(outlineColor)) {
      throw ArgumentError('Subtitle colors must use #RRGGBB or #AARRGGBB.');
    }
    if (!outlineSize.isFinite || outlineSize < 0 || outlineSize > 10) {
      throw RangeError.range(outlineSize, 0, 10, 'outlineSize');
    }
    if (position < 0 || position > 100) {
      throw RangeError.range(position, 0, 100, 'position');
    }
  }

  static final RegExp _mpvColor = RegExp(
    r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
  );

  final String fontFamily;
  final double fontSize;
  final String color;
  final String outlineColor;
  final double outlineSize;
  final bool bold;
  final int position;

  /// When enabled, mpv applies the global style to ASS/SSA scripts. This can
  /// alter authored signs and positioning, so it defaults to false.
  final bool overrideAssStyles;

  SubtitleStyle copyWith({
    String? fontFamily,
    double? fontSize,
    String? color,
    String? outlineColor,
    double? outlineSize,
    bool? bold,
    int? position,
    bool? overrideAssStyles,
  }) => SubtitleStyle(
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    outlineColor: outlineColor ?? this.outlineColor,
    outlineSize: outlineSize ?? this.outlineSize,
    bold: bold ?? this.bold,
    position: position ?? this.position,
    overrideAssStyles: overrideAssStyles ?? this.overrideAssStyles,
  );
}
