import 'dart:convert';
import 'dart:io';

import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_api.dart';
import 'package:anime_app/data/player/providers/user_sources/user_defined_playback_provider.dart';

Map<String, Object?> transportSnapshots() => {
  'plain': MiruroCatalogApi.decodePayload(
    File('test/fixtures/refactor/miruro_payload.json').readAsBytesSync(),
  ),
  'xorGzip': MiruroCatalogApi.decodePayload(
    File('test/fixtures/refactor/miruro_payload_xor_gzip.bin')
        .readAsBytesSync(),
  ),
  'direct': [
    for (final value in [
      'https://cdn.example.org/a.m3u8',
      'https://cdn.example.org/a.mp4',
      'https://cdn.example.org/a.mpd',
      'https://cdn.example.org/a.webm',
      'https://127.0.0.1/a.mp4',
      'http://cdn.example.org/a.mp4',
      'https://cdn.example.test/a.mp4',
    ])
      {
        'uri': value,
        'allowed': DirectMediaHostResolver.isSyntacticallyPublicHttps(
          Uri.parse(value),
        ),
        'format': DirectMediaHostResolver.formatFor(Uri.parse(value)).name,
      },
  ],
  'userSources':
      UserDefinedSourceEntry.parseJson(
            '{"sources":[{"anime":"anilist:21","episode":1,"url":"https://cdn.example.org/a.m3u8","language":"ja","quality":"1080p"}]}',
          )
          .map(
            (s) => {
              'anime': s.anime,
              'episode': s.episodeNumber,
              'url': s.url.toString(),
              'language': s.language,
              'quality': s.quality,
            },
          )
          .toList(),
};

void main() {
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(transportSnapshots()),
  );
}
