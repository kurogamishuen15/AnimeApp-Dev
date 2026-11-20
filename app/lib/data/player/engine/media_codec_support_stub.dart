import 'media_codec_support_model.dart';

/// Environments without `dart:io` (web) have no native media_kit backend, so
/// there is nothing to prepare.
MediaCodecReport prepareMediaCodecSupport() => const MediaCodecReport(
  platform: 'web',
  strategy: MediaCodecStrategy.system,
  detail: 'Sin backend nativo media_kit en esta plataforma.',
);
