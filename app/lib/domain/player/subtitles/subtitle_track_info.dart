/// Normalized subtitle-track metadata exposed to application and presentation.
final class SubtitleTrackInfo {
  const SubtitleTrackInfo({
    required this.id,
    required this.label,
    required this.kind,
    this.language,
    this.codec,
    this.isDefault = false,
    this.isSelected = false,
  });

  final String id;
  final String label;
  final SubtitleTrackKind kind;
  final String? language;
  final String? codec;
  final bool isDefault;
  final bool isSelected;
}

enum SubtitleTrackKind { automatic, disabled, embedded, external }
