import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../public_playback_http.dart';

/// Public Miruro catalog origins listed by the supplied Anilili source.
/// Mirrors are retried only for transport/5xx failures, never for a 4xx or a
/// challenge response.
const List<String> miruroCatalogOrigins = <String>[
  'www.miruro.to',
  'www.miruro.tv',
  'www.miruro.bz',
  'www.miruro.ru',
  'www.miruro.cx',
];

/// Small HTTP adapter for the public Miruro REST catalog.
///
/// This uses ordinary HTTPS GETs through [PublicPlaybackHttp]. It does not send
/// cookies, browser fingerprints, challenge answers, or authentication.
final class MiruroCatalogApi {
  MiruroCatalogApi(
    this._http, {
    Iterable<String> origins = miruroCatalogOrigins,
    this.maxOriginAttempts = 3,
  }) : _origins = List<String>.unmodifiable(origins) {
    if (_origins.isEmpty ||
        _origins.any((String host) => !_validHost(host)) ||
        maxOriginAttempts < 1 ||
        maxOriginAttempts > _origins.length) {
      throw ArgumentError('Miruro catalog origins are invalid.');
    }
  }

  static const int maxDecodedBytes = 8 * 1024 * 1024;
  static const List<int> _catalogKey = <int>[
    0x6d,
    0x69,
    0x72,
    0x75,
    0x72,
    0x6f,
    0x2f,
    0x63,
    0x61,
    0x74,
    0x61,
    0x6c,
    0x6f,
    0x67,
  ];

  final PublicPlaybackHttp _http;
  final List<String> _origins;
  final int maxOriginAttempts;
  String? _preferredOrigin;

  Future<String> get(
    String path, {
    Map<String, String> query = const <String, String>{},
    required PlaybackCancellationToken cancellation,
    required PlaybackHttpStage stage,
    int maxResponseBytes = PublicPlaybackHttp.defaultMaxResponseBytes,
  }) async {
    if (!_validPath(path)) {
      throw const FormatException('Invalid Miruro catalog path.');
    }
    if (cancellation.isCancelled) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.cancelled);
    }

    final List<String> ordered = <String>[
      if (_preferredOrigin case final String preferred) preferred,
      ..._origins.where((String host) => host != _preferredOrigin),
    ].take(maxOriginAttempts).toList(growable: false);
    PublicPlaybackFailure? lastFailure;
    for (final String host in ordered) {
      if (cancellation.isCancelled) {
        throw const PublicPlaybackFailure(
          PlaybackProviderFailureKind.cancelled,
        );
      }
      final Uri uri = Uri.https(host, '/api/$path', query);
      try {
        final Uint8List bytes = await _http.readBytes(
          uri,
          cancellation,
          stage: stage,
          maxResponseBytes: maxResponseBytes,
          headers: PlaybackRequestHeaders({'Referer': 'https://$host/'}),
        );
        _preferredOrigin = host;
        return decodePayload(bytes);
      } on PublicPlaybackFailure catch (failure) {
        final bool retryable =
            failure.kind == PlaybackProviderFailureKind.network ||
            (failure.kind == PlaybackProviderFailureKind.unavailable &&
                (failure.status ?? 0) >= 500);
        if (!retryable || cancellation.isCancelled) rethrow;
        lastFailure = failure;
      }
    }
    if (lastFailure case final PublicPlaybackFailure failure) throw failure;
    throw const PublicPlaybackFailure(PlaybackProviderFailureKind.unavailable);
  }

  /// Decodes the upstream JSON or its documented XOR-then-gzip catalog body.
  /// Decompression is bounded to prevent a small response from expanding into
  /// an unbounded allocation on modest devices.
  static String decodePayload(Uint8List bytes) {
    if (bytes.isEmpty ||
        bytes.length > PublicPlaybackHttp.maxAllowedResponseBytes) {
      throw const FormatException('Miruro payload size is invalid.');
    }
    final String plain = utf8.decode(bytes, allowMalformed: true).trimLeft();
    if (plain.startsWith('{') || plain.startsWith('[')) {
      return utf8.decode(bytes, allowMalformed: false);
    }

    final Uint8List unmasked = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      unmasked[i] = bytes[i] ^ _catalogKey[i % _catalogKey.length];
    }
    final BytesBuilder expanded = BytesBuilder(copy: false);
    final _BoundedOutputSink output = _BoundedOutputSink(
      expanded,
      maxDecodedBytes,
    );
    final Sink<List<int>> decoder = gzip.decoder.startChunkedConversion(output);
    decoder.add(unmasked);
    decoder.close();
    return utf8.decode(expanded.takeBytes(), allowMalformed: false);
  }

  static bool _validPath(String path) =>
      path.isNotEmpty &&
      path.length <= 256 &&
      !path.startsWith('/') &&
      !path.contains('..') &&
      RegExp(r'^[a-zA-Z0-9/_-]+$').hasMatch(path);

  static bool _validHost(String host) => miruroCatalogOrigins.contains(host);
}

final class _BoundedOutputSink implements Sink<List<int>> {
  _BoundedOutputSink(this._builder, this._maxBytes);

  final BytesBuilder _builder;
  final int _maxBytes;
  int _length = 0;

  @override
  void add(List<int> chunk) {
    _length += chunk.length;
    if (_length > _maxBytes) {
      throw const FormatException('Miruro decompressed payload is too large.');
    }
    _builder.add(chunk);
  }

  @override
  void close() {}
}
