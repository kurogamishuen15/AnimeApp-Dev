import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/data/player/providers/wikimedia/wikimedia_anime_provider.dart';
import 'package:anime_app/data/player/providers/wikimedia/wikimedia_identity.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Wikimedia keeps exact-ID remote playback regression coverage',
    () async {
      final _Pages pages = _Pages({
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
      final Dio client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: [
          PlaybackProviderRegistration(
            provider: WikimediaAnimeProvider(client),
            cacheTtl: const Duration(minutes: 5),
          ),
        ],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(),
          ),
        ],
        clock: DateTime.now,
      );
      final PlaybackEpisode episode = PlaybackEpisode(
        animeId: AnimeId('namakura-gatana'),
        episodeNumber: 1,
        externalAnimeId: ExternalAnimeId(
          providerId: MetadataProviderId('anilist'),
          value: '6654',
        ),
      );

      final result = await manager.resolveCandidates(
        episode,
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        result,
        isA<PlaybackProviderSuccess<List<ResolvedPlaybackStream>>>(),
      );
      final List<ResolvedPlaybackStream> streams =
          (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
              .value;
      expect(
        streams.map((stream) => stream.uri.host),
        everyElement('upload.wikimedia.org'),
      );
      expect(
        streams.map((stream) => stream.format),
        everyElement(PlaybackMediaFormat.webm),
      );
      expect(
        streams.map((stream) => stream.httpHeaders.values['User-Agent']),
        everyElement(wikimediaUserAgent),
      );
      final repeated = await manager.resolveCandidates(
        episode,
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        repeated,
        isA<PlaybackProviderSuccess<List<ResolvedPlaybackStream>>>(),
      );
      expect(pages.paths, ['/w/api.php']);
      expect(pages.referers, [null]);

      final unrelated = await manager.resolveCandidates(
        PlaybackEpisode(animeId: AnimeId('unrelated'), episodeNumber: 1),
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        unrelated,
        isA<PlaybackProviderEmpty<List<ResolvedPlaybackStream>>>(),
      );
    },
  );

  test(
    'public transport honors Retry-After without storing response bodies',
    () async {
      final _Pages pages = _Pages(
        const <String, (int, String)>{
          '/public': (429, 'private response content'),
        },
        headers: {
          'server': ['fixture-server'],
          'retry-after': ['19'],
        },
      );
      final Dio client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final PublicPlaybackHttp transport = PublicPlaybackHttp(client, const {
        'public.example.org',
      }, enforceCooldown: true);
      final Uri uri = Uri.https('public.example.org', '/public');

      for (int attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          transport.read(uri, PlaybackCancellationToken()),
          throwsA(
            isA<PublicPlaybackFailure>()
                .having(
                  (error) => error.kind,
                  'kind',
                  PlaybackProviderFailureKind.rateLimited,
                )
                .having(
                  (error) => error.status,
                  'status',
                  attempt == 0 ? 429 : isNull,
                )
                .having((error) => error.retryAfter, 'Retry-After', isNotNull),
          ),
        );
      }
      expect(pages.paths, ['/public']);
    },
  );
}

final class _Pages implements HttpClientAdapter {
  _Pages(
    this.pages, {
    this.headers = const <String, List<String>>{
      'content-type': <String>['application/json'],
      'server': <String>['test-origin'],
    },
  });

  final Map<String, (int, String)> pages;
  final Map<String, List<String>> headers;
  final List<String> paths = <String>[];
  final List<String?> referers = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.path);
    referers.add(options.headers['Referer'] as String?);
    final (int status, String body) = pages[options.uri.path] ?? (404, '');
    return ResponseBody.fromString(body, status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}
