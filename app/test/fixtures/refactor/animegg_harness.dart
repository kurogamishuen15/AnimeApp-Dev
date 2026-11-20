import 'dart:typed_data';

import 'package:anime_app/data/player/providers/animegg/animegg_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

import '../../refactor/source_snapshot.dart';

PlaybackEpisode _episode({String title = 'Tokyo Ghoul:re'}) => PlaybackEpisode(
  animeId: AnimeId('test'),
  episodeNumber: 9,
  externalAnimeIds: [
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '100240'),
  ],
  animeTitles: [title],
);

/// Live-shaped AnimeGG search (2026-11-17): `mse` anchors carry the title in
/// an `h2` inside the media body.
const String _searchPage = '''
<div class="media searchre">
  <a href="/series/tokyo-kushu" class="mse">
    <div class="media-body"><div class="first"><h2>Tokyo Ghoul</h2></div></div>
  </a>
  <a href="/series/tokyo-ghoulre" class="mse">
    <div class="media-body"><div class="first"><h2>Tokyo Ghoul:re</h2></div></div>
  </a>
  <a href="/series/tokyo-ghoulre-2nd-season" class="mse">
    <div class="media-body"><div class="first"><h2>Tokyo Ghoul:re 2nd Season</h2></div></div>
  </a>
</div>
''';

/// Live-shaped series page: `anm_det_pop` rows with the episode number inside
/// the strong text.
const String _seriesPage = '''
<ul>
  <li><div><a href="/tokyo-ghoulre-episode-1" class="anm_det_pop"><strong>Tokyo Ghoul:re 1</strong></a><i class="anititle">Episode 1</i></div></li>
  <li><div><a href="/tokyo-ghoulre-episode-9" class="anm_det_pop"><strong>Tokyo Ghoul:re 9</strong></a><i class="anititle">Episode 9</i></div></li>
  <li><div><a href="/tokyo-ghoulre-episode-12" class="anm_det_pop"><strong>Tokyo Ghoul:re 12</strong></a></div></li>
</ul>
''';

/// Live-shaped watch page: sub/dub tab mirrors. Note the single-quoted
/// `data-id`, exactly as the site emits it.
const String _watchPage = '''
<ul class="nav nav-tabs">
  <li><a href="#subbed-Animegg" data-toggle="tab" data-id='91335' data-mirror="Animegg" data-version="subbed"></a></li>
  <li><a href="#dubbed-Animegg" data-toggle="tab" data-id='92519' data-mirror="Animegg" data-version="dubbed"></a></li>
</ul>
''';

/// Live-shaped embed: jwplayer progressive MP4s with relative /play paths.
const String _embedPage = '''
<script src="/scripts/jwplayer/7.12.13/jwplayer.js"></script>
<script>
  jwplayer("video").setup({
    sources: [
      { file: "/play/227251/video.mp4?for=101794971615946", label: "HD" },
      { file: "/play/227255/video.mp4?for=101794971615946", label: "SD" },
    ],
  });
</script>
''';

const String hlsEmbedPage = '''
<script>
  const src = "https://cdn.animegg.org/series/master.m3u8?token=fixture";
</script>
''';

final class FixturePages implements HttpClientAdapter {
  FixturePages({
    required this.searchBody,
    required this.seriesBody,
    required this.watchBody,
    this.embedBody = '{}',
    this.watchStatus = 200,
  });

  final String searchBody;
  final String seriesBody;
  final String watchBody;
  final String embedBody;
  final int watchStatus;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final String path = options.uri.path;
    final String body = switch (path) {
      '/search/' => searchBody,
      _ when path.startsWith('/series/') => seriesBody,
      _ when path.startsWith('/embed/') => embedBody,
      _ => watchBody,
    };
    final int status = path.startsWith('/tokyo-ghoulre-episode-')
        ? watchStatus
        : 200;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        'content-type': ['text/html'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, Object?>> snapshot() async {
  final pages = FixturePages(
    searchBody: _searchPage,
    seriesBody: _seriesPage,
    watchBody: _watchPage,
    embedBody: _embedPage,
  );
  final client = Dio()..httpClientAdapter = pages;
  try {
    final provider = AnimeGgPlaybackProvider(client);
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
