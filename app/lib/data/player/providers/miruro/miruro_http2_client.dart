import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http2/transport.dart';

/// One bounded HTTP/2 response, already decoded from the framing layer.
final class MiruroHttp2Response {
  const MiruroHttp2Response({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Uint8List body;
}

/// The narrow slice of HTTP the catalog needs, so a test can substitute it.
abstract interface class MiruroCatalogTransport {
  Future<MiruroHttp2Response> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
    required int maxBytes,
  });
}

/// Minimal HTTP/2 GET transport for the public Miruro backend.
///
/// Why this exists: the backend's catalog route is only served over HTTP/2.
/// The same host answers `/health` over HTTP/1.1, so this is not a network,
/// address, or client block; it is a route rule that the site's own browser
/// satisfies by negotiating `h2` through ALPN. Dart's `dart:io` HTTP client is
/// HTTP/1.1 only, so the catalog is read through this narrow client instead.
///
/// It sends exactly the request the site's own bundle sends: `GET`, no body, no
/// cookies, no authorization, and the standard fetch-metadata context. Keep it
/// that way: this class is not a general-purpose evasion layer.
final class MiruroHttp2Client implements MiruroCatalogTransport {
  MiruroHttp2Client({
    this.connectTimeout = const Duration(seconds: 8),
    this.maxIdleLifetime = const Duration(seconds: 90),
  });

  /// Bound for the TLS + ALPN handshake of a new connection.
  final Duration connectTimeout;

  /// A pooled connection older than this is replaced instead of reused.
  final Duration maxIdleLifetime;

  _MiruroConnection? _connection;

  /// Sends one `GET` to [uri] and returns the decoded response.
  @override
  Future<MiruroHttp2Response> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
    required int maxBytes,
  }) async {
    if (uri.scheme != 'https' || (uri.hasPort && uri.port != 443)) {
      throw ArgumentError.value(uri, 'uri', 'Only public HTTPS on 443');
    }
    final _MiruroConnection connection = await _connectionFor(uri);
    try {
      return await connection.get(
        uri,
        headers: headers,
        timeout: timeout,
        maxBytes: maxBytes,
      );
    } on Object {
      // A pooled connection may have been closed by the peer between requests.
      await _discard();
      rethrow;
    }
  }

  Future<_MiruroConnection> _connectionFor(Uri uri) async {
    final _MiruroConnection? existing = _connection;
    if (existing != null &&
        existing.host == uri.host &&
        !existing.isClosed &&
        existing.age < maxIdleLifetime) {
      return existing;
    }
    await _discard();
    final _MiruroConnection created = await _MiruroConnection.open(
      uri.host,
      connectTimeout: connectTimeout,
    );
    _connection = created;
    return created;
  }

  Future<void> _discard() async {
    final _MiruroConnection? connection = _connection;
    _connection = null;
    await connection?.close();
  }

  Future<void> close() => _discard();
}

final class _MiruroConnection {
  _MiruroConnection(this._socket, this._transport, this.host)
    : _openedAt = DateTime.now();

  static Future<_MiruroConnection> open(
    String host, {
    required Duration connectTimeout,
  }) async {
    final SecureSocket socket = await SecureSocket.connect(
      host,
      443,
      supportedProtocols: const <String>['h2'],
      timeout: connectTimeout,
    );
    if (socket.selectedProtocol != 'h2') {
      socket.destroy();
      throw const SocketException('The origin did not negotiate HTTP/2.');
    }
    return _MiruroConnection(
      socket,
      ClientTransportConnection.viaSocket(socket),
      host,
    );
  }

  final SecureSocket _socket;
  final ClientTransportConnection _transport;
  final String host;
  final DateTime _openedAt;

  Duration get age => DateTime.now().difference(_openedAt);

  bool get isClosed => !_transport.isOpen;

  Future<MiruroHttp2Response> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
    required int maxBytes,
  }) {
    final TransportStream stream = _transport.makeRequest(
      <Header>[
        Header.ascii(':method', 'GET'),
        Header.ascii(':scheme', 'https'),
        Header.ascii(':authority', uri.authority),
        Header.ascii(
          ':path',
          uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path,
        ),
        for (final MapEntry<String, String> entry in headers.entries)
          Header.ascii(entry.key.toLowerCase(), entry.value),
      ],
      endStream: true,
    );

    final Completer<MiruroHttp2Response> result =
        Completer<MiruroHttp2Response>();
    final BytesBuilder body = BytesBuilder(copy: false);
    final Map<String, String> responseHeaders = <String, String>{};
    int length = 0;
    int statusCode = 0;
    Timer? guard;

    void fail(Object error) {
      if (result.isCompleted) return;
      guard?.cancel();
      stream.terminate();
      result.completeError(error);
    }

    guard = Timer(timeout, () => fail(TimeoutException('Miruro HTTP/2 GET')));

    stream.incomingMessages.listen(
      (StreamMessage message) {
        switch (message) {
          case HeadersStreamMessage(:final List<Header> headers):
            for (final Header header in headers) {
              final String name = latin1.decode(header.name);
              final String value = latin1.decode(header.value);
              if (name == ':status') {
                statusCode = int.tryParse(value) ?? 0;
              } else if (!name.startsWith(':')) {
                responseHeaders[name] = value;
              }
            }
          case DataStreamMessage(:final List<int> bytes):
            length += bytes.length;
            if (length > maxBytes) {
              fail(
                const FormatException('Miruro HTTP/2 body exceeds its bound.'),
              );
              return;
            }
            body.add(bytes);
        }
      },
      onError: fail,
      onDone: () {
        if (result.isCompleted) return;
        guard?.cancel();
        if (statusCode == 0) {
          result.completeError(
            const FormatException('Miruro HTTP/2 status is missing.'),
          );
          return;
        }
        result.complete(
          MiruroHttp2Response(
            statusCode: statusCode,
            headers: Map<String, String>.unmodifiable(responseHeaders),
            body: body.takeBytes(),
          ),
        );
      },
      cancelOnError: true,
    );

    return result.future;
  }

  Future<void> close() async {
    try {
      await _transport.finish().timeout(const Duration(seconds: 2));
    } on Object {
      // A dead connection needs no graceful finish.
    }
    _socket.destroy();
  }
}
