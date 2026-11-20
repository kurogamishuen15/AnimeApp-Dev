import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../public_playback_http.dart';
import 'miruro_http2_client.dart';

/// Current public Miruro domain, as announced by the service on 2026-11-19.
/// Retired domains are intentionally excluded from automatic requests.
const List<String> miruroCatalogOrigins = <String>['www.miruro.cx'];

/// Small HTTP adapter for the public Miruro REST catalog.
///
/// This uses ordinary HTTPS GETs: the catalog route through [MiruroHttp2Client]
/// because the backend serves it only over HTTP/2, and `/health` through
/// [PublicPlaybackHttp], which is enough for the liveness probe. It does not send
/// cookies, browser fingerprints, challenge answers, or authentication.
final class MiruroCatalogApi {
  MiruroCatalogApi(this._http, {MiruroCatalogTransport? transport})
    : _http2 = transport ?? MiruroHttp2Client();

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
  final MiruroCatalogTransport _http2;

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

    final String host = miruroCatalogOrigins.single;
    final Uri uri = Uri.https(host, '/api/$path', query);
    // The catalog route is served only over HTTP/2 (see `MiruroHttp2Client`).
    // These are the same GETs the site's own bundle issues, with the standard
    // fetch-metadata context: no cookie, token, or authorization is sent.
    final MiruroHttp2Response response;
    try {
      response = await _http2.get(
        uri,
        headers: <String, String>{
          'user-agent': _http.userAgent,
          'accept': 'application/json',
          'accept-language': 'en-US,en;q=0.5',
          'referer': 'https://$host/',
          'origin': 'https://$host',
          'sec-fetch-site': 'same-origin',
          'sec-fetch-mode': 'cors',
          'sec-fetch-dest': 'empty',
        },
        timeout: const Duration(seconds: 25),
        maxBytes: maxResponseBytes,
      );
    } on TimeoutException {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.timeout,
        host: host,
        stage: stage,
      );
    } on SocketException catch (error) {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.network,
        host: host,
        stage: stage,
        server: error.message,
      );
    } on TlsException catch (error) {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.network,
        host: host,
        stage: stage,
        server: error.message,
      );
    }
    final int code = response.statusCode;
    if (code != 200) {
      throw PublicPlaybackFailure(
        switch (code) {
          401 || 403 => PlaybackProviderFailureKind.forbidden,
          404 => PlaybackProviderFailureKind.notFound,
          410 => PlaybackProviderFailureKind.expired,
          429 => PlaybackProviderFailureKind.rateLimited,
          >= 500 => PlaybackProviderFailureKind.unavailable,
          _ => PlaybackProviderFailureKind.invalidResponse,
        },
        status: code,
        host: host,
        stage: stage,
        contentType: response.headers['content-type'],
      );
    }
    return decodePayload(response.body);
  }

  /// Verifies the backend is alive with a hard 4 s bound.
  ///
  /// `/health` is served by the same host over HTTP/1.1, so it exercises the
  /// public liveness route without duplicating the HTTP/2 transport. It returns
  /// `false` instead of throwing so a caller can classify an outage without
  /// sharing its request cancellation.
  Future<bool> probeHealth({
    required PlaybackCancellationToken cancellation,
  }) async {
    final String host = miruroCatalogOrigins.single;
    final PlaybackCancellationToken probe = PlaybackCancellationToken();
    final void Function() unregister = cancellation.addCancelListener(
      probe.cancel,
    );
    try {
      await _http
          .read(
            Uri.https(host, '/health'),
            probe,
            stage: PlaybackHttpStage.catalog,
            maxResponseBytes: 16 * 1024,
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } on Object {
      return false;
    } finally {
      unregister();
      probe.cancel();
    }
  }

  /// Releases the pooled HTTP/2 connection, when the transport owns one.
  Future<void> close() async {
    final MiruroCatalogTransport transport = _http2;
    if (transport is MiruroHttp2Client) await transport.close();
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
