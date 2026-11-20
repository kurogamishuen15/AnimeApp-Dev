import 'media_codec_support_model.dart';

/// Windows H.264 policy.
///
/// media_kit ships its own libmpv/ffmpeg build for Windows, including the
/// H.264 decoder, so the application ships no extra decoder and nothing is
/// prepared. Windows was not executed in this project yet: the report states
/// the expected strategy, not a verified desktop run.
final class WindowsMediaCodecSupport {
  const WindowsMediaCodecSupport();

  MediaCodecReport prepare() => const MediaCodecReport(
    platform: 'windows',
    strategy: MediaCodecStrategy.platform,
    detail:
        'H.264 por el ffmpeg de media_kit (D3D11VA/MF disponible); sin códec '
        'del proyecto. Sin verificación en Windows.',
  );
}
