import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Counts artwork failures by kind and host. Never stores or prints the full
/// URL, query string, cookies or signatures.
final class HomeArtworkDiagnostics {
  HomeArtworkDiagnostics._();

  static final HomeArtworkDiagnostics instance = HomeArtworkDiagnostics._();

  final Map<String, int> _counts = {};

  @visibleForTesting
  void Function(String line) sink = _defaultSink;

  Map<String, int> get counts => Map.unmodifiable(_counts);

  void reportFailure(String? url, Object error) {
    final String kind = classify(error);
    final String host = safeHost(url);
    final String key = '$kind@$host';
    _counts.update(key, (int value) => value + 1, ifAbsent: () => 1);
    sink('home_artwork_failed kind=$kind host=$host');
  }

  @visibleForTesting
  static String classify(Object error) {
    if (error is NetworkImageLoadException) {
      return 'http_${error.statusCode}';
    }
    if (error is HandshakeException || error is TlsException) return 'tls';
    if (error is SocketException) return 'socket';
    if (error is TimeoutException) return 'timeout';
    if (error is HttpException) return 'http';
    final String text = error.toString();
    if (text.contains('Invalid image data')) return 'decode';
    return 'unknown_${error.runtimeType}';
  }

  @visibleForTesting
  static String safeHost(String? url) {
    final Uri? uri = url == null ? null : Uri.tryParse(url);
    return uri == null || uri.host.isEmpty ? 'invalid' : uri.host;
  }

  static void _defaultSink(String line) => debugPrint(line);
}
