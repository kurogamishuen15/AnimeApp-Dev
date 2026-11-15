import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

final class CachedAniSkipResponse {
  const CachedAniSkipResponse({
    required this.body,
    required this.retrievedAt,
    required this.expiresAt,
  });
  final String body;
  final DateTime retrievedAt;
  final DateTime expiresAt;
}

abstract interface class AniSkipResponseCache {
  Future<CachedAniSkipResponse?> read(String key);
  Future<void> write(String key, CachedAniSkipResponse response);
  Future<void> invalidate(String key);
}

typedef AniSkipCacheDirectory = Future<Directory> Function();

/// Small atomic file cache; cache filenames are derived only from numeric IDs.
final class FileAniSkipResponseCache implements AniSkipResponseCache {
  factory FileAniSkipResponseCache({
    Directory? directory,
    AniSkipCacheDirectory? directoryProvider,
  }) => FileAniSkipResponseCache._(
    directory,
    directoryProvider ?? getApplicationSupportDirectory,
  );

  FileAniSkipResponseCache._(this._directory, this._directoryProvider);

  static const int maxEntryBytes = 512 * 1024;
  static const int contractVersion = 1;
  final Directory? _directory;
  final AniSkipCacheDirectory _directoryProvider;

  @override
  Future<CachedAniSkipResponse?> read(String key) async {
    final Directory directory = await _getDirectory(create: false);
    if (!await directory.exists()) return null;
    _ensureNotLink(directory);
    final File file = File(
      '${directory.path}${Platform.pathSeparator}${_fileName(key)}',
    );
    if (!await file.exists()) return null;
    _ensureNotLink(file);
    if (await file.length() > maxEntryBytes) {
      await file.delete();
      return null;
    }
    try {
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?> ||
          decoded['contractVersion'] != contractVersion ||
          decoded['body'] is! String ||
          decoded['retrievedAt'] is! String ||
          decoded['expiresAt'] is! String) {
        await file.delete();
        return null;
      }
      final DateTime? retrievedAt = DateTime.tryParse(
        decoded['retrievedAt']! as String,
      );
      final DateTime? expiresAt = DateTime.tryParse(
        decoded['expiresAt']! as String,
      );
      if (retrievedAt == null || expiresAt == null) {
        await file.delete();
        return null;
      }
      return CachedAniSkipResponse(
        body: decoded['body']! as String,
        retrievedAt: retrievedAt.toUtc(),
        expiresAt: expiresAt.toUtc(),
      );
    } on FormatException {
      await file.delete();
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedAniSkipResponse response) async {
    final Directory directory = await _getDirectory(create: true);
    _ensureNotLink(directory);
    final String contents = jsonEncode({
      'contractVersion': contractVersion,
      'retrievedAt': response.retrievedAt.toUtc().toIso8601String(),
      'expiresAt': response.expiresAt.toUtc().toIso8601String(),
      'body': response.body,
    });
    if (utf8.encode(contents).length > maxEntryBytes) {
      throw const FileSystemException(
        'AniSkip cache entry exceeds size limit.',
      );
    }
    final File destination = File(
      '${directory.path}${Platform.pathSeparator}${_fileName(key)}',
    );
    if (await destination.exists()) _ensureNotLink(destination);
    final File temporary = File('${destination.path}.tmp');
    if (await temporary.exists()) _ensureNotLink(temporary);
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(destination.path);
  }

  @override
  Future<void> invalidate(String key) async {
    final Directory directory = await _getDirectory(create: false);
    if (!await directory.exists()) return;
    _ensureNotLink(directory);
    final File file = File(
      '${directory.path}${Platform.pathSeparator}${_fileName(key)}',
    );
    if (await file.exists()) {
      _ensureNotLink(file);
      await file.delete();
    }
  }

  Future<Directory> _getDirectory({required bool create}) async {
    final Directory directory =
        _directory ??
        Directory(
          '${(await _directoryProvider()).path}${Platform.pathSeparator}aniskip-v1',
        );
    if (create && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _fileName(String key) {
    if (!RegExp(r'^v1-[1-9][0-9]*-[1-9][0-9]*$').hasMatch(key)) {
      throw ArgumentError.value(key, 'key', 'Invalid AniSkip cache key.');
    }
    return '$key.json';
  }

  void _ensureNotLink(FileSystemEntity entity) {
    if (FileSystemEntity.typeSync(entity.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw FileSystemException('Symlinked AniSkip cache path is rejected.');
    }
  }
}
