import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../../domain/player/providers/playback_source.dart';
import '../hosts/direct_media_host_resolver.dart';

/// Loopback reverse proxy for Miruro media.
///
/// Every resolved stream is published as `http://127.0.0.1:<port>/media/<id>`,
/// so the player never holds a backend CDN URL. The proxy is the single place
/// that applies the `Referer`/`Origin`/`User-Agent` the backend declares,
/// forwards `Range`, and preserves `206` with `Content-Range`. That keeps seek
/// correct, hides mirror and token rotation from the engine, and lets the source
/// appear as an internal, labelled stream.
///
/// Scope: public `GET` only, loopback only, no request body, no cookies, no
/// authorization. Sub-resources are addressed by an opaque id plus the base64url
/// of their absolute upstream URL, which is validated against the registered
/// upstream host family before any request leaves the process.
final class MiruroMediaProxy {
  MiruroMediaProxy._(this._server);

  final HttpServer _server;
  final Map<String, _MiruroMediaEntry> _entries = <String, _MiruroMediaEntry>{};
  int _nextId = 1;
  bool _closed = false;

  static const Duration _upstreamTimeout = Duration(seconds: 20);
  static const int _maxPlaylistBytes = 4 * 1024 * 1024;

  /// Binds an ephemeral loopback port and starts serving.
  static Future<MiruroMediaProxy> start() async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
    final MiruroMediaProxy proxy = MiruroMediaProxy._(server);
    server.listen(proxy._handle, onError: (Object _) {});
    return proxy;
  }

  /// Origin the engine must allowlist, e.g. `http://127.0.0.1:45123`.
  String get origin => 'http://127.0.0.1:${_server.port}';

  /// Publishes [upstream] and returns the loopback URI to play.
  Uri expose(Uri upstream, {PlaybackRequestHeaders? headers}) {
    final String id = '${_nextId++}';
    _entries[id] = _MiruroMediaEntry(upstream, headers);
    return Uri.parse('$origin/media/$id');
  }

  /// Drops every published entry. Called when the provider is disposed.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _entries.clear();
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != 'GET') {
        await _reply(request, HttpStatus.methodNotAllowed, 'method');
        return;
      }
      final List<String> segments = request.uri.pathSegments;
      if (segments.length < 2 || segments[0] != 'media') {
        await _reply(request, HttpStatus.notFound, 'route');
        return;
      }
      final String id = segments[1];
      final _MiruroMediaEntry? entry = _entries[id];
      if (entry == null) {
        await _reply(request, HttpStatus.notFound, 'entry');
        return;
      }
      final Uri target = segments.length == 2
          ? entry.upstream
          : _decodeChild(entry, segments[2]);
      await _proxy(request, id, entry, target);
    } on Object {
      await _reply(request, HttpStatus.badGateway, 'upstream');
    } finally {
      await request.response.close().catchError((Object _) {});
    }
  }

  Future<void> _proxy(
    HttpRequest request,
    String id,
    _MiruroMediaEntry entry,
    Uri target,
  ) async {
    final HttpClient client = HttpClient()..connectionTimeout = _upstreamTimeout;
    try {
      final HttpClientRequest upstream = await client
          .getUrl(target)
          .timeout(_upstreamTimeout);
      final Map<String, String> headers =
          entry.headers?.values ?? const <String, String>{};
      headers.forEach(upstream.headers.set);
      upstream.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final String? range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null) upstream.headers.set(HttpHeaders.rangeHeader, range);
      final HttpClientResponse response = await upstream.close().timeout(
        _upstreamTimeout,
      );

      final String? contentType = response.headers.value(
        HttpHeaders.contentTypeHeader,
      );
      final bool playlist =
          target.path.toLowerCase().endsWith('.m3u8') ||
          (contentType?.toLowerCase().contains('mpegurl') ?? false);

      request.response.statusCode = response.statusCode;
      if (response.statusCode == HttpStatus.partialContent) {
        for (final String name in const <String>[
          HttpHeaders.contentRangeHeader,
          HttpHeaders.acceptRangesHeader,
          HttpHeaders.contentLengthHeader,
        ]) {
          final String? value = response.headers.value(name);
          if (value != null) request.response.headers.set(name, value);
        }
      }
      if (contentType != null) {
        request.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
      }
      request.response.headers.set(
        HttpHeaders.cacheControlHeader,
        'private, max-age=0, no-store',
      );

      if (playlist && response.statusCode == HttpStatus.ok) {
        final BytesBuilder raw = BytesBuilder(copy: false);
        int length = 0;
        await for (final List<int> chunk in response) {
          length += chunk.length;
          if (length > _maxPlaylistBytes) {
            request.response.statusCode = HttpStatus.badGateway;
            return;
          }
          raw.add(chunk);
        }
        final String text = utf8.decode(raw.takeBytes(), allowMalformed: true);
        request.response.headers.contentType = ContentType(
          'application',
          'vnd.apple.mpegurl',
        );
        request.response.write(_rewritePlaylist(text, id, entry, target));
        return;
      }

      await response.pipe(request.response);
    } finally {
      client.close(force: true);
    }
  }

  /// Rewrites every URI line of a playlist into a loopback child address.
  String _rewritePlaylist(
    String text,
    String id,
    _MiruroMediaEntry entry,
    Uri base,
  ) {
    return text.split('\n').map((String line) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty) return line;
      if (trimmed.startsWith('#')) {
        // `#EXT-X-KEY:...URI="https://..."` and `#EXT-X-MAP:URI="..."`
        return line.replaceAllMapped(
          RegExp(r'URI="([^"]+)"'),
          (Match match) =>
              'URI="${_child(id, entry, base, match.group(1)!)}"',
        );
      }
      return _child(id, entry, base, trimmed);
    }).join('\n');
  }

  String _child(String id, _MiruroMediaEntry entry, Uri base, String reference) {
    final Uri resolved = base.resolve(reference);
    // The provider's own playlist names its media hosts. Declaring them is how
    // a CDN that rotates to another domain stays playable; an undeclared host
    // is still rejected before any request leaves the process.
    entry.declare(resolved);
    final String encoded = base64Url
        .encode(utf8.encode(resolved.toString()))
        .replaceAll('=', '');
    return '$origin/media/$id/$encoded';
  }

  Uri _decodeChild(_MiruroMediaEntry entry, String encoded) {
    final String padded = encoded.padRight((encoded.length + 3) ~/ 4 * 4, '=');
    final Uri candidate;
    try {
      candidate = Uri.parse(utf8.decode(base64Url.decode(padded)));
    } on Object {
      throw const FormatException('miruro proxy child is invalid');
    }
    if (candidate.scheme != 'https' ||
        candidate.userInfo.isNotEmpty ||
        !entry.allows(candidate)) {
      throw const FormatException('miruro proxy child is not allowed');
    }
    return candidate;
  }

  Future<void> _reply(HttpRequest request, int status, String reason) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.text;
    request.response.write(reason);
  }
}

final class _MiruroMediaEntry {
  _MiruroMediaEntry(this.upstream, this.headers)
    : _declaredHosts = <String>{upstream.host};

  final Uri upstream;
  final PlaybackRequestHeaders? headers;
  final Set<String> _declaredHosts;

  /// A child is reachable when it is public HTTPS and either a host the
  /// provider's own playlist declared, or a sibling under the same registrable
  /// domain as the registered stream. Anything else is rejected.
  bool allows(Uri candidate) {
    if (candidate.scheme != 'https' ||
        candidate.userInfo.isNotEmpty ||
        (candidate.hasPort && candidate.port != 443)) {
      return false;
    }
    if (_declaredHosts.contains(candidate.host)) return true;
    final String family = _registrable(upstream.host);
    return family.isNotEmpty && _registrable(candidate.host) == family;
  }

  /// Records a media host named by the provider's playlist, but only when it is
  /// a syntactically public HTTPS origin (no IP literals, no special-use names).
  void declare(Uri candidate) {
    if (DirectMediaHostResolver.isSyntacticallyPublicHttps(candidate)) {
      _declaredHosts.add(candidate.host);
    }
  }

  static String _registrable(String host) {
    final List<String> labels = host.split('.');
    if (labels.length < 2) return '';
    return labels.sublist(labels.length - 2).join('.');
  }
}
