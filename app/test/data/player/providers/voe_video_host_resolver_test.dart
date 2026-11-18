import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/hosts/voe_video_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

String _rot13(String value) => String.fromCharCodes(
  value.codeUnits.map((c) {
    if (c >= 65 && c <= 90) return 65 + (c - 65 + 13) % 26;
    if (c >= 97 && c <= 122) return 97 + (c - 97 + 13) % 26;
    return c;
  }),
);
String _config(String uri) {
  final first = base64.encode(utf8.encode(jsonEncode({'source': uri})));
  final second = base64.encode(
    first.codeUnits.reversed.map((c) => c + 3).toList(),
  );
  return '<script type="application/json">${jsonEncode([_rot13('@\$$second!!')])}</script>';
}

SourceCandidate _candidate({DateTime? expiry}) => SourceCandidate(
  id: 'voe-dub-0',
  hostId: 'voe',
  kind: PlaybackCandidateKind.embed,
  endpoint: Uri.https('voe.sx', '/e/File09'),
  expiresAt: expiry,
  requestHeaders: PlaybackRequestHeaders({'Referer': 'https://animeav1.com/'}),
);
PlaybackSource _source(SourceCandidate candidate) => PlaybackSource(
  id: 'episode:dub',
  providerId: PlaybackProviderId('animeav1'),
  episode: PlaybackEpisode(animeId: AnimeId('test'), episodeNumber: 1),
  language: 'es',
  quality: 'Auto',
  displayName: 'AnimeAV1 · Latino',
  servers: [candidate],
);

void main() {
  test(
    'published redirect, maintained config decoder, HLS and media identity',
    () async {
      final pages = _Pages();
      final client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final candidate = _candidate();
      final result = await VoeVideoHostResolver(client).resolve(
        _source(candidate),
        candidate,
        cancellation: PlaybackCancellationToken(),
      );
      final stream = (result as PlaybackProviderSuccess<PlayableSource>).value;
      expect(stream.format, PlaybackMediaFormat.hls);
      expect(stream.uri.host, 'cdn.anime.org');
      expect(stream.httpHeaders.values, {
        'User-Agent': 'Kongroo/0.1 (public anime catalog client)',
      });
      expect(pages.requests.map((r) => r.uri.host), [
        'voe.sx',
        'player.anime.org',
        'cdn.anime.org',
      ]);
      expect(pages.requests[1].headers['Referer'], 'https://animeav1.com/');
      expect(pages.requests.last.headers['Referer'], isNull);
      expect(pages.requests.map((r) => r.method), everyElement('GET'));
      expect(
        pages.requests.map((r) => r.headers['User-Agent']),
        everyElement(stream.httpHeaders.values['User-Agent']),
      );
    },
  );
  test('a denial stops without routes or browser impersonation', () async {
    final pages = _Pages(playerStatus: 403);
    final client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final candidate = _candidate();
    final result = await VoeVideoHostResolver(client).resolve(
      _source(candidate),
      candidate,
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.forbidden,
    );
    expect(pages.requests, hasLength(2));
  });
  test('player-origin Retry-After survives another resolve', () async {
    final pages = _Pages(playerStatus: 429);
    final client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final candidate = _candidate();
    final resolver = VoeVideoHostResolver(client);
    for (var i = 0; i < 2; i++) {
      final result = await resolver.resolve(
        _source(candidate),
        candidate,
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        PlaybackProviderFailureKind.rateLimited,
      );
    }
    expect(
      pages.requests.where((r) => r.uri.host == 'player.anime.org'),
      hasLength(1),
    );
  });
  test('redirect for a different episode file is rejected', () async {
    final pages = _Pages(redirectFile: 'Different');
    final client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final candidate = _candidate();
    final result = await VoeVideoHostResolver(client).resolve(
      _source(candidate),
      candidate,
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.invalidResponse,
    );
    expect(pages.requests, hasLength(1));
  });
  test('private media and non-HLS bodies never become playable', () async {
    for (final private in [false, true]) {
      final pages = _Pages(
        media: private
            ? 'https://127.0.0.1/master.m3u8'
            : 'https://cdn.anime.org/master.m3u8',
        manifest: '<html>not HLS</html>',
      );
      final client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final candidate = _candidate();
      final result = await VoeVideoHostResolver(client).resolve(
        _source(candidate),
        candidate,
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        PlaybackProviderFailureKind.invalidResponse,
      );
      if (private) expect(pages.requests, hasLength(2));
    }
  });
  test('cancelled and expired candidates do not contact the host', () async {
    final pages = _Pages();
    final client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final resolver = VoeVideoHostResolver(client);
    var candidate = _candidate();
    final cancelled = await resolver.resolve(
      _source(candidate),
      candidate,
      cancellation: PlaybackCancellationToken()..cancel(),
    );
    expect(
      (cancelled as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.cancelled,
    );
    candidate = _candidate(expiry: DateTime.utc(2000));
    final expired = await resolver.resolve(
      _source(candidate),
      candidate,
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (expired as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.expired,
    );
    expect(pages.requests, isEmpty);
  });
}

final class _Pages implements HttpClientAdapter {
  _Pages({
    this.playerStatus = 200,
    this.redirectFile = 'File09',
    this.media = 'https://cdn.anime.org/master.m3u8',
    this.manifest = '#EXTM3U\n#EXT-X-ENDLIST',
  });
  final int playerStatus;
  final String redirectFile;
  final String media;
  final String manifest;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      switch (options.uri.host) {
        'voe.sx' =>
          "const url = new URL(window.location.href); window.location.href = 'https://player.anime.org/e/$redirectFile';",
        'player.anime.org' => _config(media),
        _ => manifest,
      },
      options.uri.host == 'player.anime.org' ? playerStatus : 200,
      headers: {
        'content-type': ['text/plain'],
        if (playerStatus == 429) 'retry-after': ['60'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
