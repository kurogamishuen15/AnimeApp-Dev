import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/wikimedia/wikimedia_anime_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

import '../../refactor/source_snapshot.dart';

final class FixturePages implements HttpClientAdapter {
  FixturePages(
    this.pages, {
    this.headers = const <String, List<String>>{
      'content-type': <String>['application/json'],
      'server': <String>['test-origin'],
    },
  });

  final Map<String, (int, String)> pages;
  final Map<String, List<String>> headers;
  final requests = <RequestOptions>[];
  final List<String> paths = <String>[];
  final List<String?> referers = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    paths.add(options.uri.path);
    referers.add(options.headers['Referer'] as String?);
    final (int status, String body) = pages[options.uri.path] ?? (404, '');
    return ResponseBody.fromString(body, status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, Object?>> snapshot() async {
  final pages = FixturePages({
    '/w/api.php': (
      200,
      jsonEncode({
        'query': {
          'pages': [
            {
              'title': "File:Kouichi Jun'ichi - Namakura Gatana (1917) - 4-minute restored version.webm",
              'videoinfo': [
                {
                  'mime': 'video/webm',
                  'url': 'https://upload.wikimedia.org/wikipedia/commons/a/ab/original.webm',
                  'extmetadata': {
                    'LicenseShortName': {'value': 'Public domain'},
                    'Copyrighted': {'value': 'False'},
                  },
                  'derivatives': [
                    {
                      'transcodekey': '480p.vp9.webm',
                      'src': 'https://upload.wikimedia.org/wikipedia/commons/a/ab/480.webm',
                    },
                  ],
                },
              ],
            },
          ],
        },
      }),
    ),
  });
  final client = Dio()..httpClientAdapter = pages;
  try {
    final result = await WikimediaAnimeProvider(client).findSources(
      PlaybackEpisode(
        animeId: AnimeId('namakura-gatana'),
        episodeNumber: 1,
        externalAnimeId: ExternalAnimeId(
          providerId: MetadataProviderId('anilist'),
          value: '6654',
        ),
      ),
      cancellation: PlaybackCancellationToken(),
    );
    if (result is! PlaybackProviderSuccess<List<PlaybackSource>> ||
        result.value.isEmpty) {
      throw StateError('Wikimedia fixture failed: $result');
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
