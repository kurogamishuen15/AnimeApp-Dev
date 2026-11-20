import 'dart:ffi';
import 'dart:io';

import 'media_codec_support_model.dart';

/// File name of the Cisco OpenH264 build prepared by
/// `tools/player/run_kongroo_linux.sh --download-codec`.
const String linuxOpenH264FileName = 'libopenh264.so.8';

/// Environment variable that points to an explicit codec build.
const String linuxOpenH264PathVariable = 'KONGROO_OPENH264_PATH';

/// Keeps a runtime-loaded decoder alive for the process lifetime.
DynamicLibrary? _loadedLibrary;

/// Whether a decoder was loaded into this process at runtime.
bool get linuxDecoderPreloaded => _loadedLibrary != null;

/// Linux H.264 policy.
///
/// Fedora ships `noopenh264`: an ABI-compatible stub without a decoder, and
/// `libavcodec` declares `libopenh264.so.8` as `DT_NEEDED`. The supported fix
/// is the bundled decoder installed by `app/linux/local_codec.cmake`, which
/// also gives the executable a transitive `DT_RPATH`; this adapter reports
/// that case.
///
/// An explicitly configured decoder outside the bundle is loaded at runtime
/// as a best effort. The app does not search cwd or ancestor directories for
/// native libraries. Preloading cannot replace a library the dynamic linker
/// already mapped for a `DT_NEEDED` entry.
final class LinuxMediaCodecSupport {
  LinuxMediaCodecSupport({
    Map<String, String>? environment,
    String? resolvedExecutable,
    bool Function(String path)? isRegularFile,
    DynamicLibrary Function(String path)? openLibrary,
  }) : _environment = environment ?? Platform.environment,
       _resolvedExecutable = resolvedExecutable ?? Platform.resolvedExecutable,
       _isRegularFile = isRegularFile ?? _isRegularFileWithElfHeader,
       _openLibrary = openLibrary ?? DynamicLibrary.open;

  final Map<String, String> _environment;
  final String _resolvedExecutable;
  final bool Function(String path) _isRegularFile;
  final DynamicLibrary Function(String path) _openLibrary;

  MediaCodecReport prepare() {
    final LinuxCodecLocator locator = LinuxCodecLocator(
      environment: _environment,
      resolvedExecutable: _resolvedExecutable,
      isRegularFile: _isRegularFile,
    );
    final String? path = locator.resolve();
    if (path == null) {
      return const MediaCodecReport(
        platform: 'linux',
        strategy: MediaCodecStrategy.system,
        detail:
            'Sin decodificador empaquetado ni ruta explícita; se aplica la '
            'política del sistema (noopenh264 no decodifica H.264).',
      );
    }
    if (_isBundled(path)) {
      // The loader already resolves this copy through the executable RPATH;
      // loading it again would be redundant.
      return MediaCodecReport(
        platform: 'linux',
        strategy: MediaCodecStrategy.bundled,
        decoderPath: path,
        detail: 'Decodificador verificado empaquetado junto a la aplicación.',
      );
    }
    try {
      _loadedLibrary = _openLibrary(path);
      return MediaCodecReport(
        platform: 'linux',
        strategy: MediaCodecStrategy.preloaded,
        decoderPath: path,
        detail: 'Decodificador cargado desde la ruta explícita configurada.',
      );
    } on Object catch (error) {
      return MediaCodecReport(
        platform: 'linux',
        strategy: MediaCodecStrategy.system,
        detail: 'No se pudo precargar el decodificador: $error',
      );
    }
  }

  bool _isBundled(String path) =>
      path == '${_directoryOf(_resolvedExecutable)}/lib/$linuxOpenH264FileName';
}

/// Ordered, deduplicated decoder candidates for the current process.
///
/// Resolution is pure so every branch is unit-testable. It considers only an
/// explicit [linuxOpenH264PathVariable] override and the library adjacent to
/// the executable; it never walks cwd or executable ancestors.
final class LinuxCodecLocator {
  const LinuxCodecLocator({
    this.environment = const {},
    required this.resolvedExecutable,
    required this.isRegularFile,
  });

  final Map<String, String> environment;
  final String resolvedExecutable;
  final bool Function(String path) isRegularFile;

  List<String> candidates() {
    final List<String> result = <String>[];
    void add(String? path) {
      if (path == null) return;
      final String trimmed = path.trim();
      if (trimmed.isEmpty || result.contains(trimmed)) return;
      result.add(trimmed);
    }

    add(environment[linuxOpenH264PathVariable]);
    final String executableDirectory = _directoryOf(resolvedExecutable);
    add('$executableDirectory/lib/$linuxOpenH264FileName');
    return result;
  }

  String? resolve() {
    for (final String candidate in candidates()) {
      if (isRegularFile(candidate)) return candidate;
    }
    return null;
  }
}

String _directoryOf(String path) {
  final String normalized = path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  final int separator = normalized.lastIndexOf('/');
  if (separator < 0) return normalized;
  if (separator == 0) return '/';
  return normalized.substring(0, separator);
}

/// Rejects symlinks and non-ELF files: only a plain executable object may be
/// loaded into the process.
bool _isRegularFileWithElfHeader(String path) {
  if (FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.file) {
    return false;
  }
  RandomAccessFile? file;
  try {
    file = File(path).openSync();
    if (file.lengthSync() < 4) return false;
    final List<int> header = file.readSync(4);
    return header.length == 4 &&
        header[0] == 0x7f &&
        header[1] == 0x45 && // E
        header[2] == 0x4c && // L
        header[3] == 0x46; // F
  } on Object {
    return false;
  } finally {
    try {
      file?.closeSync();
    } on Object {
      // Read-only inspection; a close failure cannot invalidate the check.
    }
  }
}
