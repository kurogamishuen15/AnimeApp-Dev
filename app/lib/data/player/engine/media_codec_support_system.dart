import 'media_codec_support_model.dart';

/// Fallback for platforms without a dedicated adapter (macOS, iOS, BSD, ...).
///
/// Nothing is inferred about their codec stack: the report delegates to the
/// system policy instead of claiming playback support.
final class SystemMediaCodecSupport {
  const SystemMediaCodecSupport();

  MediaCodecReport prepare(String platform) => MediaCodecReport(
    platform: platform,
    strategy: MediaCodecStrategy.system,
    detail: 'Sin adaptador de códecs para esta plataforma.',
  );
}
