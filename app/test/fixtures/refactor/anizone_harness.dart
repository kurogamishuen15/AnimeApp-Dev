import 'dart:typed_data';

import 'package:anime_app/data/player/providers/anizone/anizone_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

import '../../refactor/source_snapshot.dart';

PlaybackEpisode _episode({bool withTitle = true}) => PlaybackEpisode(
  animeId: AnimeId('test'),
  episodeNumber: 9,
  externalAnimeIds: [
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '100240'),
  ],
  animeTitles: withTitle
      ? const ['Tokyo Ghoul:re']
      : const ['Nonexistent Show'],
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

String get _searchPage =>
    '''
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
  subtitles: [
    _subtitle('English [UDF]', 'ass', 'en', '0_en.ass', isDefault: true),
  ],
);

final String vttEpisodePage = _playerJson(
  subtitles: [
    _subtitle('Español', 'vtt', 'es', '1_es.vtt', isDefault: true),
    _subtitle('English', 'vtt', 'en', '2_en.vtt'),
  ],
);

final class FixturePages implements HttpClientAdapter {
  FixturePages({
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
        headers: {
          'content-type': ['text/html'],
        },
      );
    }
    return ResponseBody.fromString(
      episodeBody,
      episodeStatus,
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
    episodeBody: _assEpisodePage,
  );
  final client = Dio()..httpClientAdapter = pages;
  try {
    final provider = AniZonePlaybackProvider(client);
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
