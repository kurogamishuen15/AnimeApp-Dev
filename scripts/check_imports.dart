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
    var uriIndex = index + 1;
    if (tokens[uriIndex].value == 'deferred') uriIndex++;
    if (uriIndex < tokens.length && tokens[uriIndex].kind == 'string') {
      imports.add(tokens[uriIndex].value);
    }
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

String? _violation(String uri, String packageName) {
  if (uri == 'dart:ui' || uri.startsWith('package:flutter/')) {
    return 'dominio no puede depender de Flutter/UI';
  }
  final normalized = uri.replaceAll('\\', '/').toLowerCase();
  final packagePrefix = 'package:${packageName.toLowerCase()}/';
  final relativeOrPackage = normalized.startsWith(packagePrefix)
      ? normalized.substring(packagePrefix.length)
      : normalized;
  final segments = relativeOrPackage.split('/');
  const forbiddenSegments = {
    'presentation',
    'ui',
    'data',
    'providers',
    'adapters',
    'infrastructure',
    'platform',
    'downloads',
    'sync',
  };
  if (segments.any(forbiddenSegments.contains)) {
    return 'dominio no puede depender de presentación o infraestructura';
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
  final domain = Directory('${root.path}/app/lib/domain');
  if (!domain.existsSync()) {
    stdout.writeln('Sin violaciones: todavía no existe app/lib/domain.');
    return;
  }
  final packageName = _packageName(root);
  var violationCount = 0;
  await for (final entity in domain.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = await entity.readAsString(encoding: utf8);
    for (final uri in _importUris(source)) {
      final reason = _violation(uri, packageName);
      if (reason == null) continue;
      stderr.writeln('${entity.path}: import "$uri" prohibido: $reason');
      violationCount++;
    }
  }
  if (violationCount > 0) {
    stderr.writeln('Se encontraron $violationCount violaciones de imports.');
    exit(1);
  }
  stdout.writeln('Imports de dominio válidos.');
}
