import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/hosts/voe_video_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

String _rot13(String value) => String.fromCharCodes(
  value.codeUnits.map((c) {
    if (c >= 65 && c <= 90) return 65 + (c - 65 + 13) % 26;
    if (c >= 97 && c <= 122) return 97 + (c - 97 + 13) % 26;
    return c;
  }),
);
String _config(String uri, {List<Map<String, Object?>> captions = const []}) {
  final first = base64.encode(
    utf8.encode(jsonEncode({'source': uri, 'captions': captions})),
  );
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
PlaybackSource _source(
  SourceCandidate candidate, {
  List<ProviderSubtitle> subtitles = const [],
}) => PlaybackSource(
  id: 'episode:dub',
  providerId: PlaybackProviderId('animeav1'),
  episode: PlaybackEpisode(animeId: AnimeId('test'), episodeNumber: 1),
  language: 'es',
  quality: 'Auto',
  displayName: 'AnimeAV1 · Latino',
  servers: [candidate],
  subtitles: subtitles,
);

final class FixturePages implements HttpClientAdapter {
  FixturePages({
    this.playerStatus = 200,
    this.redirectFile = 'File09',
    this.media = 'https://cdn.anime.org/master.m3u8',
    this.manifest = '#EXTM3U\n#EXT-X-ENDLIST',
    this.captions = const [],
  });
  final int playerStatus;
  final String redirectFile;
  final String media;
  final String manifest;
  final List<Map<String, Object?>> captions;
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
        'player.anime.org' => _config(media, captions: captions),
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

Future<Map<String, Object?>> snapshot() async {
  final pages = FixturePages(
    captions: [
      {
        'file': 'https://cdn.anime.org/sub.vtt',
        'label': 'English',
        'kind': 'captions',
      },
    ],
  );
  final client = Dio()..httpClientAdapter = pages;
  try {
    final candidate = _candidate();
    final result = await VoeVideoHostResolver(client).resolve(
      _source(candidate),
      candidate,
      cancellation: PlaybackCancellationToken(),
    );
    if (result is! PlaybackProviderSuccess<PlayableSource>) {
      throw StateError('VOE fixture failed: $result');
    }
    final s = result.value;
    return {
      'stream': {
        'provider': s.providerId.value,
        'source': s.sourceId,
        'server': s.serverId,
        'uri': s.uri.toString(),
        'format': s.format.name,
        'sourceLabel': s.sourceLabel,
        'displayName': s.displayName,
        'availability': s.availability.name,
        'expires': s.expiresAt?.toIso8601String(),
        'validated': s.validatedAt?.toIso8601String(),
        'provenance': s.provenance,
        'headers': s.httpHeaders.values,
        'subtitles': s.subtitles
            .map(
              (t) => {
                'id': t.id,
                'uri': t.uri.toString(),
                'label': t.label,
                'language': t.language,
                'default': t.isDefault,
              },
            )
            .toList(),
      },
      'requests': pages.requests
          .map(
            (r) => {
              'method': r.method,
              'uri': r.uri.toString(),
              'headers': r.headers,
              'data': r.data,
            },
          )
          .toList(),
    };
  } finally {
    client.close(force: true);
  }
}
