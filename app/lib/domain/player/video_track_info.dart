/// Native video-track metadata valid only for the currently opened source.
/// The dimensions and bitrate are demuxer hints; they are not an ABR ladder.
final class VideoTrackInfo {
  const VideoTrackInfo({
    required this.id,
    this.title,
    this.codec,
    this.width,
    this.height,
    this.fps,
    this.bitrate,
    this.isDefault,
  });

  final String id;
  final String? title;
  final String? codec;
  final int? width;
  final int? height;
  final double? fps;
  final int? bitrate;
  final bool? isDefault;

  String get label {
    final String size = _resolutionLabel;
    final String? titleText = title?.trim();
    return [
      size,
      if (bitrate case final int value when value > 0) _formatBitrate(value),
      if (codec case final String value when value.trim().isNotEmpty) value,
      if (titleText != null && titleText.isNotEmpty) titleText,
    ].join(' · ');
  }

  String _formatBitrate(int bitsPerSecond) => bitsPerSecond >= 1000000
      ? '${(bitsPerSecond / 1000000).toStringAsFixed(1)} Mbps'
      : '${(bitsPerSecond / 1000).round()} kbps';

  String get _resolutionLabel {
    final int? w = width;
    final int? h = height;
    if (w == null || h == null || w <= 0 || h <= 0) {
      return 'Resolución no informada';
    }
    final String? standard = switch (h) {
      >= 4320 => '8K',
      2160 => '4K',
      1440 => '1440p',
      1080 => '1080p',
      720 => '720p',
      480 => '480p',
      360 => '360p',
      _ => null,
    };
    return standard == null ? '$w×$h' : '$standard · $w×$h';
  }
}
