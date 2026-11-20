import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

import 'media_codec_support_android.dart';
import 'media_codec_support_linux.dart';
import 'media_codec_support_model.dart';
import 'media_codec_support_system.dart';
import 'media_codec_support_windows.dart';

/// Prepares H.264 support once per process and reports the strategy used.
///
/// The result is cached: the first call decides for the process lifetime,
/// because a decoder mapped by the dynamic linker cannot be replaced later.
MediaCodecReport prepareMediaCodecSupport() {
  final MediaCodecReport report = _registry.prepare();
  if (!_logged) {
    _logged = true;
    debugPrint(
      'KONGROO_CODEC ${report.strategy.name} ${report.decoderPath ?? report.platform}',
    );
  }
  return report;
}

final MediaCodecSupportRegistry _registry = MediaCodecSupportRegistry();
bool _logged = false;

/// Selects the platform adapter. Injectable so tests can exercise every
/// platform branch without leaving Linux.
final class MediaCodecSupportRegistry {
  MediaCodecSupportRegistry({
    String? operatingSystem,
    LinuxMediaCodecSupport? linux,
    AndroidMediaCodecSupport? android,
    WindowsMediaCodecSupport? windows,
    SystemMediaCodecSupport? other,
  }) : _operatingSystem = operatingSystem ?? Platform.operatingSystem,
       _linux = linux ?? LinuxMediaCodecSupport(),
       _android = android ?? const AndroidMediaCodecSupport(),
       _windows = windows ?? const WindowsMediaCodecSupport(),
       _other = other ?? const SystemMediaCodecSupport();

  final String _operatingSystem;
  final LinuxMediaCodecSupport _linux;
  final AndroidMediaCodecSupport _android;
  final WindowsMediaCodecSupport _windows;
  final SystemMediaCodecSupport _other;

  MediaCodecReport prepare() => switch (_operatingSystem) {
    'linux' => _linux.prepare(),
    'android' => _android.prepare(),
    'windows' => _windows.prepare(),
    _ => _other.prepare(_operatingSystem),
  };
}
