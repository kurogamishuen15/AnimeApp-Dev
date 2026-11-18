import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/anizone/anizone_playback_provider.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

PlaybackEpisode _episode({bool withTitle = true}) => PlaybackEpisode(
  animeId: AnimeId('test'),
  episodeNumber: 9,
  externalAnimeIds: [
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '100240'),
  ],
  animeTitles: withTitle ? const ['Tokyo Ghoul:re'] : const ['Nonexistent Show'],
);

// Escapes observed in the live AniZone markup (2026-11-17). The search page
// embeds results in an Alpine `x-data` JSON.parse level where a quote is
// `\u0022` (one backslash) and a slash `\\\/` (three); the episode page's
// `kPlayer(JSON.parse('...'))` uses two-backslash quotes.
const String _q1 = r'\u0022';
const String _q2 = r'\\u0022';
const String _s = r'\\\/';

String _searchEntry(String slug, String title) =>
    '{$_q1'
    'slug$_q1:$_q1'
    '$slug$_q1,'
    '$_q1'
    'url$_q1:$_q1'
    'http:$_s$_s'
    'anizone.to$_s'
    'anime$_s'
    '$slug$_q1,'
    '$_q1'
    'cover$_q1:$_q1'
    'https:$_s$_s'
    'anizone.to$_s'
    'images$_s'
    'anime$_s'
    'x.jpg$_q1,'
    '$_q1'
    'main_title$_q1:$_q1'
    '$title$_q1,'
    '$_q1'
    'title_list$_q1:{$_q1'
    '5$_q1:$_q1'
    '$title$_q1}}';

String get _searchPage => '''
<div x-data="items: JSON.parse('[${_searchEntry('pokofpdc', 'Tokyo Ghoul')},${_searchEntry('djivt6wx', 'Tokyo Ghoul:re')},${_searchEntry('hzckwj7v', 'Tokyo Ghoul Root A')}]')"></div>
''';

String _playerJson({required List<String> subtitles}) =>
    '<script>kPlayer(JSON.parse('
    "'{$_q2"
    'src$_q2:$_q2'
    'https:$_s$_s'
    'seiryuu.vid-cdn.xyz$_s'
    '15052d20$_s'
    'master.m3u8$_q2,'
    '$_q2'
    'storage$_q2:$_q2'
    'v-15052d20$_q2,'
    '$_q2'
    "subtitles$_q2:[${subtitles.join(',')}]$_q2}'));"
    '</script>';

String _subtitle(
  String title,
  String format,
  String language,
  String file, {
  bool isDefault = false,
}) =>
    '{$_q2'
    'title$_q2:$_q2'
    '$title$_q2,'
    '$_q2'
    'format$_q2:$_q2'
    '$format$_q2,'
    '$_q2'
    'language$_q2:$_q2'
    '$language$_q2,'
    '$_q2'
    'default$_q2:$isDefault,'
    '$_q2'
    'forced$_q2:$_q2'
    'no$_q2,'
    '$_q2'
    'file$_q2:$_q2'
    'https:$_s$_s'
    'seiryuu.vid-cdn.xyz$_s'
    '15052d20$_s'
    'subtitles$_s'
    '$file$_q2}';

/// Live shape: AniZone publishes ASS captions; the VTT-only contract must
/// skip them without discarding the playable manifest.
final String _assEpisodePage = _playerJson(
  subtitles: [_subtitle('English [UDF]', 'ass', 'en', '0_en.ass', isDefault: true)],
);

final String _vttEpisodePage = _playerJson(
  subtitles: [
    _subtitle('Español', 'vtt', 'es', '1_es.vtt', isDefault: true),
    _subtitle('English', 'vtt', 'en', '2_en.vtt'),
  ],
);

void main() {
  test('exact title search resolves the live-shaped snapshot', () async {
    final pages = _Pages(searchBody: _searchPage, episodeBody: _assEpisodePage);
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AniZonePlaybackProvider(client);
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
        (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>).value;
    expect(streams, hasLength(1));
    expect(
      streams.single.uri.toString(),
      'https://seiryuu.vid-cdn.xyz/15052d20/master.m3u8',
    );
    expect(streams.single.format, PlaybackMediaFormat.hls);
    expect(streams.single.subtitles, isEmpty); // ASS tracks are skipped.
    expect(
      pages.requests.map((RequestOptions request) => request.uri.path),
      ['/anime', '/anime/djivt6wx/9'],
    );
    expect(
      pages.requests.last.headers['Referer'],
      'https://anizone.to/anime/djivt6wx',
    );
  });

  test('a non-matching title never becomes a match', () async {
    final pages = _Pages(searchBody: _searchPage, episodeBody: _assEpisodePage);
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AniZonePlaybackProvider(client);
    final result = await provider.findSources(
      _episode(withTitle: false),
      cancellation: PlaybackCancellationToken(),
    );
    expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    expect(
      pages.requests.map((RequestOptions r) => r.uri.path),
      ['/anime'],
    );
  });

  test('episode page without a manifest is noSources without retries',
      () async {
    final pages = _Pages(
      searchBody: _searchPage,
      episodeBody: '<html><body>No player here</body></html>',
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AniZonePlaybackProvider(client);
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.noSources,
    );
    expect(pages.requests, hasLength(2));
  });

  test('VTT captions published by the player are preserved', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      episodeBody: _vttEpisodePage,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AniZonePlaybackProvider(client);
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    final source =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value.single;
    expect(source.subtitles.map((track) => track.language), ['es', 'en']);
    expect(source.subtitles.first.uri.path, endsWith('/subtitles/1_es.vtt'));
  });

  test('HTTP 403 on the episode page stops as forbidden', () async {
    final pages = _Pages(
      searchBody: _searchPage,
      episodeBody: _assEpisodePage,
      episodeStatus: 403,
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AniZonePlaybackProvider(client);
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
    final pages = _Pages(searchBody: _searchPage, episodeBody: _assEpisodePage);
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = AniZonePlaybackProvider(client);
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
    required this.episodeBody,
    this.episodeStatus = 200,
  });

  final String searchBody;
  final String episodeBody;
  final int episodeStatus;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final String path = options.uri.path;
    if (path == '/anime') {
      return ResponseBody.fromString(
        searchBody,
        200,
        headers: {'content-type': ['text/html']},
      );
    }
    return ResponseBody.fromString(
      episodeBody,
      episodeStatus,
      headers: {'content-type': ['text/html']},
    );
  }

  @override
  void close({bool force = false}) {}
}
