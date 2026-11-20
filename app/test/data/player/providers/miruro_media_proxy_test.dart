import 'dart:convert';
import 'dart:io';

import 'package:anime_app/data/player/providers/miruro/miruro_media_proxy.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local stand-in for a Miruro CDN: it records the headers it received and
/// serves either a playlist that points at absolute upstream URLs or a byte
/// range, so the proxy can be exercised without the public network.
void main() {
  late HttpServer upstream;
  late MiruroMediaProxy proxy;
  final List<HttpHeaders> received = <HttpHeaders>[];
  final List<String?> ranges = <String?>[];

  setUp(() async {
    received.clear();
    ranges.clear();
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    upstream.listen((HttpRequest request) async {
      received.add(request.headers);
      ranges.add(request.headers.value(HttpHeaders.rangeHeader));
      final String path = request.uri.path;
      if (path.endsWith('.m3u8')) {
        request.response.headers.contentType = ContentType(
          'application',
          'vnd.apple.mpegurl',
        );
        request.response.write(
          '#EXTM3U\n'
          '#EXT-X-KEY:METHOD=AES-128,URI="key.bin"\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=1000\n'
          'variant.m3u8\n',
        );
      } else if (ranges.last != null) {
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes 0-1023/4096',
        );
        request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
        request.response.add(List<int>.filled(1024, 7));
      } else {
        request.response.headers.contentType = ContentType.binary;
        request.response.add(List<int>.filled(2048, 3));
      }
      await request.response.close();
    });
    proxy = await MiruroMediaProxy.start();
  });

  tearDown(() async {
    await proxy.close();
    await upstream.close(force: true);
  });

  Uri upstreamUri(String path) => Uri.parse(
    'http://127.0.0.1:${upstream.port}$path',
  );

  test('publishes a loopback URI and never exposes the upstream host', () {
    final Uri published = proxy.expose(upstreamUri('/segment.bin'));
    expect(published.host, '127.0.0.1');
    expect(published.port, isNot(upstream.port));
    expect(published.pathSegments.first, 'media');
    expect(published.toString(), isNot(contains('${upstream.port}')));
  });

  test('forwards the declared context headers and the range', () async {
    final Uri published = proxy.expose(
      upstreamUri('/segment.bin'),
      headers: PlaybackRequestHeaders(<String, String>{
        'Referer': 'https://megaplay.buzz/',
        'Origin': 'https://megaplay.buzz',
      }),
    );
    final HttpClient client = HttpClient();
    addTearDown(() => client.close(force: true));
    final HttpClientRequest request = await client.getUrl(published);
    request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-1023');
    final HttpClientResponse response = await request.close();
    expect(response.statusCode, HttpStatus.partialContent);
    expect(response.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 0-1023/4096');
    expect(response.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');
    await response.drain<void>();
    expect(received.single.value('referer'), 'https://megaplay.buzz/');
    expect(received.single.value('origin'), 'https://megaplay.buzz');
    expect(ranges.single, 'bytes=0-1023');
  });

  test('rewrites playlists into loopback child addresses', () async {
    final Uri published = proxy.expose(upstreamUri('/master.m3u8'));
    final HttpClient client = HttpClient();
    addTearDown(() => client.close(force: true));
    final HttpClientResponse response = await (await client.getUrl(
      published,
    )).close();
    expect(response.statusCode, HttpStatus.ok);
    final String body = await utf8.decoder.bind(response).join();
    final String origin = 'http://127.0.0.1:${proxy.origin.split(':').last}';
    expect(body, contains('$origin/media/'));
    expect(body, isNot(contains('127.0.0.1:${upstream.port}')));
    expect(body, isNot(contains('variant.m3u8\n')));
  });

  test('rejects an unknown entry and a child outside the host family', () async {
    final HttpClient client = HttpClient()..connectionTimeout =
        const Duration(seconds: 5);
    addTearDown(() => client.close(force: true));
    final HttpClientResponse missing = await (await client.getUrl(
      Uri.parse('${proxy.origin}/media/999'),
    )).close();
    expect(missing.statusCode, HttpStatus.notFound);
    await missing.drain<void>();

    proxy.expose(Uri.parse('https://cdn.example.org/master.m3u8'));
    final String foreign = base64Url
        .encode(utf8.encode('https://evil.example.net/x.bin'))
        .replaceAll('=', '');
    final HttpClientResponse rejected = await (await client.getUrl(
      Uri.parse('${proxy.origin}/media/1/$foreign'),
    )).close();
    expect(rejected.statusCode, HttpStatus.badGateway);
    await rejected.drain<void>();
  });
}
