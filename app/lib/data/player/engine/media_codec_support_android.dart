import 'media_codec_support_model.dart';

/// Android H.264 policy.
///
/// media_kit/libmpv on Android decodes H.264 through `MediaCodec` (hardware or
/// software), so the application ships no decoder and nothing is prepared.
/// Android was not executed in this project yet: the report states the
/// expected strategy, not a verified device run.
final class AndroidMediaCodecSupport {
  const AndroidMediaCodecSupport();

  MediaCodecReport prepare() => const MediaCodecReport(
    platform: 'android',
    strategy: MediaCodecStrategy.platform,
    detail:
        'H.264 por MediaCodec (hwdec/sw) a través de libmpv; el proyecto no '
        'empaqueta códecs. Sin verificación en dispositivo.',
  );
}
