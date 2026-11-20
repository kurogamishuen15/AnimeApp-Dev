import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/megaplay/megaplay_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

import '../../refactor/source_snapshot.dart';

PlaybackEpisode _episode({bool withId = true}) => PlaybackEpisode(
  animeId: AnimeId('test'),
  episodeNumber: 9,
  externalAnimeIds: [
    if (withId)
      ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '100240',
      ),
  ],
);

final class FixturePages implements HttpClientAdapter {
  FixturePages({
    this.answer = '{}',
    this.embedStatus = 200,
    this.fallbackAnswer,
    this.aniMissing = false,
  });
  final String answer;
  final String? fallbackAnswer;
  final int embedStatus;
  final bool aniMissing;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.uri.path;
    final bool aniMiss = aniMissing && path.startsWith('/stream/ani/');
    return ResponseBody.fromString(
      switch (path) {
        '/stream/ani/100240/9/sub' ||
        '/stream/ani/100240/9/dub' => '<div data-id="File09"></div>',
        '/stream/mal/36511/9/sub' => '<div data-id="MalFile09"></div>',
        '/lib/newclient.min.js' =>
          '"stream/getSourcesNew" "stream/getSources/evil"',
        '/stream/getSources' => fallbackAnswer ?? answer,
        _ => answer,
      },
      aniMiss
          ? 404
          : path == '/stream/ani/100240/9/sub'
          ? embedStatus
          : 200,
      headers: {
        'content-type': ['application/json'],
        if (embedStatus == 429) 'retry-after': ['60'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, Object?>> snapshot() async {
  final pages = FixturePages(
    answer: jsonEncode({
      'sources': {
        'file': 'https://fetch.nexabloom.top/a/master.m3u8?token=fixture',
      },
    }),
  );
  final client = Dio()..httpClientAdapter = pages;
  try {
    final provider = MegaPlayPlaybackProvider(client);
    final result = await provider.findSources(
      _episode(),
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
