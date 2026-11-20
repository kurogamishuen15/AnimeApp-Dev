import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/animeav1/animeav1_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

import '../../refactor/source_snapshot.dart';

PlaybackEpisode _request({bool mal = true, int number = 1}) => PlaybackEpisode(
  animeId: AnimeId('naruto'),
  episodeNumber: number,
  animeTitles: ['Naruto'],
  externalAnimeIds: [
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '20'),
    if (mal)
      ExternalAnimeId(
        providerId: MetadataProviderId('myanimelist'),
        value: '20',
      ),
  ],
);

Map<String, Object?> _media({int mal = 20}) => {
  'malId': mal,
  'episodes': [
    {'number': 1},
    {'number': 2},
    {'number': 1.5},
    {'number': 1},
  ],
};

Map<String, Object?> _episode({int number = 1, bool dub = true}) => {
  'media': _media(),
  'episode': {
    'number': number,
    'variants': {'SUB': 1, if (dub) 'DUB': 1},
  },
  'embeds': {
    'SUB': [
      {'server': 'Voe', 'url': 'https://voe.sx/e/subfixture'},
    ],
    'DUB': [
      {
        'server': 'YourUpload',
        'url': 'https://www.yourupload.com/embed/dubfixture',
      },
      {
        'server': 'MP4Upload',
        'url': 'https://www.mp4upload.com/embed-dubfixture.html',
      },
      {'server': 'Voe', 'url': 'https://voe.sx/e/dubfixture'},
      {'server': 'Voe', 'url': 'https://127.0.0.1/private'},
      {'server': 'Voe', 'url': 'https://voe.sx/e/dubfixture'},
      {'server': 'UPNShare', 'url': 'https://other.anime.org/unknown'},
    ],
  },
};

// Minimal fixtures model the public SvelteKit/devalue payload, without signed media.
String _page(Object root) {
  final flat = <Object?>[];
  int add(Object? value) {
    final index = flat.length;
    flat.add(null);
    flat[index] = switch (value) {
      final Map<String, Object?> value => value.map(
        (key, child) => MapEntry(key, add(child)),
      ),
      final List<Object?> value => value.map(add).toList(),
      _ => value,
    };
    return index;
  }

  add(root);
  return jsonEncode({
    'nodes': [
      null,
      {'type': 'data', 'data': flat},
    ],
  });
}

final class FixturePages implements HttpClientAdapter {
  int detailMal = 20;
  int status = 200;
  Map<String, Object?> episode = _episode();
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final root = switch (options.uri.path) {
      '/catalogo/__data.json' => {
        'results': [
          {'slug': 'naruto', 'title': 'Naruto'},
        ],
      },
      '/media/naruto/__data.json' => {'media': _media(mal: detailMal)},
      _ => episode,
    };
    return ResponseBody.fromString(
      _page(root),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, Object?>> snapshot() async {
  final pages = FixturePages();
  final client = Dio()..httpClientAdapter = pages;
  try {
    final provider = AnimeAv1PlaybackProvider(client);
    final result = await provider.findSources(
      _request(),
      cancellation: PlaybackCancellationToken(),
    );
    if (result is! PlaybackProviderSuccess<List<PlaybackSource>> ||
        result.value.isEmpty) {
      throw StateError('Fixture did not resolve nonempty sources: $result');
    }
    return {
      'sources': result.value.map(snapshotSource).toList(),
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
