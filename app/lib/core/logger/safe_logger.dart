import 'dart:collection';

import '../errors/app_error.dart';

enum LogLevel { debug, info, warning, error }

final class LogRecord {
  const LogRecord({
    required this.level,
    required this.code,
    required this.timestamp,
    required this.correlationId,
    required this.fields,
  });

  final LogLevel level;
  final String code;
  final DateTime timestamp;
  final String? correlationId;
  final Map<String, Object?> fields;
}

typedef LogSink = void Function(LogRecord record);

final class SafeLogger {
  SafeLogger({required LogSink sink, DateTime Function()? clock})
    : _sinks = [sink],
      _clock = clock ?? DateTime.now;

  final List<LogSink> _sinks;
  final DateTime Function() _clock;
  bool _disposed = false;

  void addSink(LogSink sink) {
    _ensureOpen();
    _sinks.add(sink);
  }

  void log(
    LogLevel level,
    String code, {
    Map<String, Object?> fields = const {},
    String? correlationId,
  }) {
    if (_disposed) return;
    final record = LogRecord(
      level: level,
      code: _safeText(code),
      timestamp: _clock().toUtc(),
      correlationId: correlationId == null ? null : _safeText(correlationId),
      fields: _sanitizeMap(fields),
    );
    for (final sink in List<LogSink>.of(_sinks)) {
      sink(record);
    }
  }

  void logError(AppError error, {String? correlationId}) {
    log(
      LogLevel.error,
      error.code,
      fields: {'error_type': error.runtimeType.toString()},
      correlationId: correlationId,
    );
  }

  void dispose() {
    _disposed = true;
    _sinks.clear();
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Logger is disposed');
  }
}

final class MemoryLogSink {
  final List<LogRecord> _records = [];
  bool _disposed = false;

  List<LogRecord> get records => UnmodifiableListView(_records);

  void call(LogRecord record) {
    if (!_disposed) _records.add(record);
  }

  void dispose() {
    _disposed = true;
    _records.clear();
  }
}

const _sensitiveNames = {
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'authheader',
  'cookie',
  'setcookie',
  'clientsecret',
  'secret',
  'password',
  'passwd',
  'pin',
  'credential',
  'callback',
  'redirecturi',
  'code',
  'state',
  'nonce',
  'apikey',
  'privatekey',
  'signature',
  'verifier',
};

Map<String, Object?> _sanitizeMap(Map<String, Object?> source) {
  final output = <String, Object?>{};
  for (final entry in source.entries) {
    final key = entry.key;
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    if (_sensitiveNames.any(normalized.contains)) {
      output[key] = '[REDACTED]';
    } else {
      output[key] = _sanitizeValue(entry.value);
    }
  }
  return Map.unmodifiable(output);
}

Object? _sanitizeValue(Object? value) => switch (value) {
  null => null,
  String text => _safeText(text),
  num _ || bool _ => value,
  Map<Object?, Object?> map => _sanitizeMap(
    map.map((key, value) => MapEntry(key?.toString() ?? 'null', value)),
  ),
  Iterable<Object?> items => items.map(_sanitizeValue).toList(growable: false),
  Uri uri => _safeUri(uri),
  AppError error => '[AppError:${error.code}]',
  Object object => '[${object.runtimeType}]',
};

String _safeUri(Uri uri) {
  final authority = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  return '${uri.scheme}://$authority/[PATH REDACTED]';
}

String _safeText(String value) {
  var result = value;
  result = result.replaceAll(
    RegExp(r'\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
    r'$1 [REDACTED]',
  );
  result = result.replaceAll(
    RegExp(
      r'''(["']?(?:authorization|proxy-authorization|cookie|set-cookie|access[_-]?token|refresh[_-]?token|client[_-]?secret|password|passwd|pin|token|code|state|nonce|api[_-]?key|private[_-]?key|signature|verifier)["']?\s*[:=]\s*).*''',
      caseSensitive: false,
    ),
    r'$1[REDACTED]',
  );
  result = result.replaceAllMapped(
    RegExp(r'[a-z][a-z0-9+.-]*://[^\s]+', caseSensitive: false),
    (match) => _safeUri(Uri.parse(match.group(0)!)),
  );
  return result;
}
