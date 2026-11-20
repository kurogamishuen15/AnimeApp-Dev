/// How the application provides H.264 decoding to media_kit/libmpv.
///
/// The enum is platform-agnostic so every adapter reports the same contract;
/// only the strategy differs per operating system.
enum MediaCodecStrategy {
  /// The operating system decodes H.264 (Android MediaCodec, Windows
  /// Media Foundation / ffmpeg bundled by media_kit).
  platform,

  /// A verified decoder was installed next to the application and the loader
  /// resolves it before the system copy (Linux `DT_RPATH`).
  bundled,

  /// A decoder was loaded into the process at runtime from the project tree.
  ///
  /// This only helps where the media stack resolves the codec lazily; it never
  /// replaces a library the dynamic linker already mapped.
  preloaded,

  /// Nothing was prepared; the system library policy decides.
  system,
}

/// Result of preparing the platform decoder stack once per process.
///
/// Adapters must never throw: a missing decoder is a reported state, not a
/// startup failure. Callers log the report and continue.
final class MediaCodecReport {
  const MediaCodecReport({
    required this.platform,
    required this.strategy,
    this.decoderPath,
    this.detail,
  });

  /// Operating system that produced the report (`linux`, `android`, ...).
  final String platform;

  final MediaCodecStrategy strategy;

  /// Absolute path of the decoder used or detected, when one exists.
  final String? decoderPath;

  /// Human-readable note for diagnostics; never contains media URLs.
  final String? detail;

  /// Whether a decoder path is known to exist for H.264 playback.
  ///
  /// `system` means the platform policy is unknown to the application, so it
  /// is reported as not prepared instead of assumed healthy.
  bool get prepared => strategy != MediaCodecStrategy.system;

  @override
  String toString() =>
      'platform=$platform strategy=${strategy.name} '
      'decoder=${decoderPath ?? 'system'}';
}
