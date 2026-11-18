import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/animegg/animegg_playback_provider.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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

const String _hlsEmbedPage = '''
<script>
  const src = "https://cdn.animegg.org/series/master.m3u8?token=fixture";
</script>
''';

void main() {
  test(
    'sub mirror resolves progressive MP4 candidates through the manager',
    () async {
      final pages = _Pages(
        searchBody: _searchPage,
        seriesBody: _seriesPage,
        watchBody: _watchPage,
        embedBody: _embedPage,
      );
      final Dio client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final provider = AnimeGgPlaybackProvider(client);
      final manager = PlaybackProviderManager(
        providers: [PlaybackProviderRegistration(provider: provider)],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(),
          ),
        ],
        clock: DateTime.now,
      );
      final result = await manager.resolveCandidates(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      final streams =
          (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
              .value;
      expect(
        streams.map((ResolvedPlaybackStream stream) => stream.uri.toString()),
        unorderedEquals(<String>[
          'https://www.animegg.org/play/227251/video.mp4?for=101794971615946',
          'https://www.animegg.org/play/227255/video.mp4?for=101794971615946',
        ]),
      );
      expect(
        streams.every(
          (ResolvedPlaybackStream stream) =>
              stream.format == PlaybackMediaFormat.mp4,
        ),
        isTrue,
      );
      expect(pages.requests.map((RequestOptions request) => request.uri.path), [
        '/search/',
        '/series/tokyo-ghoulre',
        '/tokyo-ghoulre-episode-9',
        '/embed/91335',
      ]);
      expect(
        pages.requests.last.headers['Referer'],
        'https://www.animegg.org/',
      );
      expect(
        streams.first.httpHeaders.values['User-Agent'],
        contains('Chrome/124'),
      );
    },
  );

  test('dub variant uses the dubbed tab id', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      seriesBody: _seriesPage,
      watchBody: _watchPage,
      embedBody: _embedPage,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AnimeGgPlaybackProvider(
      client,
      variant: AnimeGgAudioVariant.dub,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    final source =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value.single;
    expect(source.providerId.value, 'animegg-dub');
    expect(source.providerAnnouncedLanguage, 'dub');
    expect(pages.requests.last.uri.path, '/embed/92519');
  });

  test('HLS playlists inside the embed become HLS candidates', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      seriesBody: _seriesPage,
      watchBody: _watchPage,
      embedBody: _hlsEmbedPage,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AnimeGgPlaybackProvider(client);
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    final source =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value.single;
    expect(
      source.servers.single.mediaFormat == PlaybackMediaFormat.hls,
      isTrue,
    );
    expect(
      source.servers.single.endpoint.toString(),
      'https://cdn.animegg.org/series/master.m3u8?token=fixture',
    );
  });

  test('missing episode row is noEpisodes without an embed request', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      seriesBody: _seriesPage,
      watchBody: _watchPage,
      embedBody: _embedPage,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AnimeGgPlaybackProvider(client);
    final result = await provider.findSources(
      PlaybackEpisode(
        animeId: AnimeId('test'),
        episodeNumber: 99,
        externalAnimeIds: [
          ExternalAnimeId(
            providerId: MetadataProviderId('anilist'),
            value: '100240',
          ),
        ],
        animeTitles: const ['Tokyo Ghoul:re'],
      ),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.noEpisodes,
    );
    expect(pages.requests, hasLength(2));
  });

  test('a non-matching title never becomes a match', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      seriesBody: _seriesPage,
      watchBody: _watchPage,
      embedBody: _embedPage,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AnimeGgPlaybackProvider(client);
    final result = await provider.findSources(
      _episode(title: 'Nonexistent Show'),
      cancellation: PlaybackCancellationToken(),
    );
    expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    expect(pages.requests.map((RequestOptions r) => r.uri.path), ['/search/']);
  });

  test('embed without media is noSources', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      seriesBody: _seriesPage,
      watchBody: _watchPage,
      embedBody: '<html><body>nothing here</body></html>',
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AnimeGgPlaybackProvider(client);
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.noSources,
    );
  });

  test('HTTP 403 on the watch page stops as forbidden', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      seriesBody: _seriesPage,
      watchBody: _watchPage,
      watchStatus: 403,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AnimeGgPlaybackProvider(client);
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.forbidden,
    );
  });

  test('cancellation makes no requests', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      seriesBody: _seriesPage,
      watchBody: _watchPage,
      embedBody: _embedPage,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AnimeGgPlaybackProvider(client);
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken()..cancel(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.cancelled,
    );
    expect(pages.requests, isEmpty);
  });
}

final class _Pages implements HttpClientAdapter {
  _Pages({
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
