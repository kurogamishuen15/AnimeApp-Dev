import 'dart:convert';
import 'dart:io';

class _Token {
  const _Token(this.kind, this.value);

  final String kind;
  final String value;
}

List<_Token> _tokens(String source) {
  final result = <_Token>[];
  var index = 0;
  while (index < source.length) {
    final code = source.codeUnitAt(index);
    if (_isWhitespace(code)) {
      index++;
      continue;
    }
    if (source.startsWith('//', index)) {
      index = source.indexOf('\n', index);
      if (index < 0) break;
      continue;
    }
    if (source.startsWith('/*', index)) {
      index += 2;
      var depth = 1;
      while (index < source.length && depth > 0) {
        if (source.startsWith('/*', index)) {
          depth++;
          index += 2;
        } else if (source.startsWith('*/', index)) {
          depth--;
          index += 2;
        } else {
          index++;
        }
      }
      continue;
    }

    var quoteIndex = index;
    var raw = false;
    if ((code == 0x72 || code == 0x52) &&
        index + 1 < source.length &&
        _isQuote(source.codeUnitAt(index + 1))) {
      raw = true;
      quoteIndex++;
    }
    final quote = source.codeUnitAt(quoteIndex);
    if (_isQuote(quote)) {
      final triple =
          quoteIndex + 2 < source.length &&
          source.codeUnitAt(quoteIndex + 1) == quote &&
          source.codeUnitAt(quoteIndex + 2) == quote;
      final delimiter = String.fromCharCodes(
        triple ? [quote, quote, quote] : [quote],
      );
      var cursor = quoteIndex + (triple ? 3 : 1);
      final contentStart = cursor;
      while (cursor < source.length) {
        if (!raw && source.codeUnitAt(cursor) == 0x5c) {
          cursor += 2;
          if (cursor > source.length) cursor = source.length;
          continue;
        }
        if (source.startsWith(delimiter, cursor)) break;
        cursor++;
      }
      final content = source.substring(contentStart, cursor);
      result.add(_Token('string', content));
      if (cursor < source.length) cursor += delimiter.length;
      index = cursor;
      continue;
    }

    if (_isIdentifierStart(code)) {
      final start = index++;
      while (index < source.length &&
          _isIdentifierPart(source.codeUnitAt(index))) {
        index++;
      }
      result.add(_Token('identifier', source.substring(start, index)));
      continue;
    }
    result.add(_Token('symbol', String.fromCharCode(code)));
    index++;
  }
  return result;
}

bool _isWhitespace(int code) =>
    code == 0x20 || code == 0x09 || code == 0x0a || code == 0x0d;

bool _isQuote(int code) => code == 0x22 || code == 0x27;

bool _isIdentifierStart(int code) =>
    (code >= 0x41 && code <= 0x5a) ||
    (code >= 0x61 && code <= 0x7a) ||
    code == 0x5f ||
    code == 0x24;

bool _isIdentifierPart(int code) =>
    _isIdentifierStart(code) || (code >= 0x30 && code <= 0x39);

List<String> _importUris(String source) {
  final tokens = _tokens(source);
  final imports = <String>[];
  for (var index = 0; index < tokens.length - 1; index++) {
    final token = tokens[index];
    if (token.kind != 'identifier' ||
        (token.value != 'import' && token.value != 'export')) {
      continue;
    }
    var cursor = index + 1;
    while (cursor < tokens.length && tokens[cursor].value != ';') {
      final candidate = tokens[cursor];
      if (candidate.kind == 'string' &&
          !candidate.value.startsWith('dart.library.')) {
        imports.add(candidate.value);
      }
      cursor++;
    }
    index = cursor;
  }
  return imports;
}

String _packageName(Directory root) {
  final pubspec = File('${root.path}/app/pubspec.yaml');
  if (!pubspec.existsSync()) return 'anime_app';
  final match = RegExp(
    r'^name:\s*([a-zA-Z0-9_]+)',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  return match?.group(1) ?? 'anime_app';
}

const _forbiddenLayerSegments = {
  'presentation',
  'ui',
  'widgets',
  'screens',
  'data',
  'adapters',
  'infrastructure',
  'integrations',
  'platform',
  'downloads',
  'sync',
};

const _platformPackages = {
  'connectivity_plus',
  'cupertino_icons',
  'device_info_plus',
  'dio',
  'drift',
  'firebase_core',
  'file_picker',
  'flutter_localizations',
  'flutter_riverpod',
  'flutter_secure_storage',
  'flutter_svg',
  'google_fonts',
  'graphql',
  'go_router',
  'http',
  'image_picker',
  'media_kit',
  'media_kit_video',
  'mobile_scanner',
  'path_provider',
  'permission_handler',
  'qr_flutter',
  'riverpod',
  'shared_preferences',
  'sqlite3',
  'sqlite3_flutter_libs',
  'sqflite',
  'supabase',
  'supabase_flutter',
  'url_launcher',
  'window_manager',
};

String _normalizedPath(String path) =>
    Uri.file(path).normalizePath().toFilePath();

String? _relativePath(String path, Directory root) {
  final normalizedPath = _normalizedPath(path);
  final normalizedRoot = _normalizedPath(root.absolute.path)
      .replaceFirst(RegExp(r'[/\\]+$'), '');
  final prefix = '$normalizedRoot${Platform.pathSeparator}';
  final comparablePath = Platform.isWindows
      ? normalizedPath.toLowerCase()
      : normalizedPath;
  final comparableRoot = Platform.isWindows
      ? normalizedRoot.toLowerCase()
      : normalizedRoot;
  final comparablePrefix = Platform.isWindows ? prefix.toLowerCase() : prefix;
  if (comparablePath == comparableRoot) return '';
  if (!comparablePath.startsWith(comparablePrefix)) return null;
  return normalizedPath.substring(prefix.length);
}

bool _isDomainSource(File source, Directory libRoot) {
  final relative = _relativePath(source.path, libRoot);
  if (relative == null) return false;
  final segments = relative.replaceAll('\\', '/').split('/');
  return segments.length > 1 &&
      segments.sublist(0, segments.length - 1).contains('domain');
}

String? _localTargetPath(
  String uri,
  File source,
  Directory libRoot,
  String packageName,
) {
  if (uri.startsWith('package:')) {
    final packageUri = uri.substring('package:'.length);
    final separator = packageUri.indexOf('/');
    final targetPackage = separator < 0
        ? packageUri
        : packageUri.substring(0, separator);
    if (targetPackage != packageName) return null;
    final targetPath = separator < 0 ? '' : packageUri.substring(separator + 1);
    return libRoot.uri.resolve(targetPath).toFilePath();
  }
  if (uri.startsWith('dart:') || uri.startsWith('dart.library.')) return null;
  final parsed = Uri.tryParse(uri);
  if (parsed == null) return null;
  if (parsed.scheme == 'file') return parsed.toFilePath();
  if (parsed.hasScheme) return null;
  return source.absolute.uri.resolveUri(parsed).toFilePath();
}

String? _violation(
  String uri,
  File source,
  Directory libRoot,
  String packageName,
) {
  if (uri == 'dart:ui' || uri == 'dart:io' || uri == 'dart:ffi') {
    return 'dominio no puede depender de APIs de UI o sistema operativo';
  }
  if (uri.startsWith('package:flutter/')) {
    return 'dominio no puede depender de Flutter/UI';
  }
  if (uri.startsWith('package:')) {
    final packageUri = uri.substring('package:'.length);
    final separator = packageUri.indexOf('/');
    final importedPackage =
        (separator < 0 ? packageUri : packageUri.substring(0, separator))
            .toLowerCase();
    if (_platformPackages.contains(importedPackage) ||
        importedPackage.endsWith('_linux') ||
        importedPackage.endsWith('_android') ||
        importedPackage.endsWith('_windows') ||
        importedPackage.endsWith('_macos') ||
        importedPackage.endsWith('_platform_interface')) {
      return 'dominio no puede depender de plugins, infraestructura o paquetes de plataforma';
    }
  }

  final targetPath = _localTargetPath(uri, source, libRoot, packageName);
  if (targetPath == null) return null;
  final relativeTarget = _relativePath(targetPath, libRoot);
  if (relativeTarget == null) {
    return 'dominio no puede importar archivos fuera de app/lib';
  }
  final segments = relativeTarget
      .replaceAll('\\', '/')
      .toLowerCase()
      .split('/');
  if (segments.contains('app') ||
      segments.any(_forbiddenLayerSegments.contains)) {
    return 'dominio no puede depender de composición, presentación o infraestructura';
  }
  return null;
}

String? _playerViolation(
  String relative,
  String uri,
  File source,
  Directory libRoot,
  String packageName,
) {
  final bool presentation = relative.startsWith('app/player/');
  final bool application = relative.startsWith('application/player/');
  if (!presentation && !application) return null;
  final bool composition = relative == 'app/player/spike_player_module.dart';
  final bool surface = relative == 'app/player/media_kit_video_surface.dart';
  final String? target = _localTargetPath(uri, source, libRoot, packageName);
  final String? local = target == null
      ? null
      : _relativePath(target, libRoot)?.replaceAll('\\', '/');
  if (application &&
      (local?.startsWith('data/') == true ||
          local?.startsWith('app/') == true ||
          uri.startsWith('package:flutter/') ||
          uri.startsWith('package:material_ui/') ||
          const {'dart:io', 'dart:ui', 'dart:ffi'}.contains(uri))) {
    return 'aplicación player no puede depender de presentación o infraestructura';
  }
  if (!composition && local?.startsWith('data/') == true) {
    return 'los paneles player no acceden a adaptadores';
  }
  if (uri.startsWith('package:dio/') ||
      uri.startsWith('package:http/') ||
      uri == 'dart:ffi' ||
      (uri.startsWith('package:media_kit/') && !composition) ||
      (uri.startsWith('package:media_kit_video/') && !surface) ||
      (uri == 'dart:io' &&
          presentation &&
          !composition &&
          relative != 'app/player/player_nerd_panel.dart')) {
    return 'red y motor nativo deben pasar por los contratos de player';
  }
  return null;
}

Future<void> main(List<String> args) async {
  var rootPath = Directory.current.path;
  for (var index = 0; index < args.length; index++) {
    if (args[index] == '--root' && index + 1 < args.length) {
      rootPath = args[++index];
    } else {
      stderr.writeln('Uso: dart scripts/check_imports.dart [--root RUTA]');
      exit(2);
    }
  }
  final root = Directory(rootPath).absolute;
  final appRoot = Directory('${root.path}/app');
  final libRoot = Directory('${root.path}/app/lib');
  for (final directory in [appRoot, libRoot]) {
    if (FileSystemEntity.typeSync(directory.path, followLinks: false) ==
        FileSystemEntityType.link) {
      stderr.writeln(
        '${directory.path}: directorio raíz no puede ser un enlace simbólico',
      );
      exit(1);
    }
  }
  if (!libRoot.existsSync()) {
    stdout.writeln('Sin violaciones: todavía no existe app/lib.');
    return;
  }
  final packageName = _packageName(root);
  var violationCount = 0;
  var domainFileCount = 0;
  var playerFileCount = 0;
  await for (final entity in libRoot.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is Link) {
      stderr.writeln(
        '${entity.path}: enlace simbólico bajo app/lib no permitido; se rechaza para no omitir código de dominio',
      );
      violationCount++;
      continue;
    }
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bool domain = _isDomainSource(entity, libRoot);
    final String relative = _relativePath(
      entity.path,
      libRoot,
    )!.replaceAll('\\', '/');
    final bool player =
        relative.startsWith('app/player/') ||
        relative.startsWith('application/player/');
    if (!domain && !player) continue;
    if (domain) domainFileCount++;
    if (player) playerFileCount++;
    final source = await entity.readAsString(encoding: utf8);
    for (final uri in _importUris(source)) {
      final reason = domain
          ? _violation(uri, entity, libRoot, packageName)
          : _playerViolation(relative, uri, entity, libRoot, packageName);
      if (reason == null) continue;
      stderr.writeln('${entity.path}: import "$uri" prohibido: $reason');
      violationCount++;
    }
  }
  stdout.writeln('Límites player revisados ($playerFileCount archivos).');
  if (violationCount > 0) {
    stderr.writeln('Se encontraron $violationCount violaciones de imports.');
    exit(1);
  }
  stdout.writeln(
    'Imports de dominio válidos ($domainFileCount archivos en todos los módulos domain de app/lib).',
  );
}
