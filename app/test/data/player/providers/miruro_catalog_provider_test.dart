import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_api.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_parser.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_playback_provider.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_http2_client.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Miruro catalog decoder', () {
    test('accepts plain JSON and the upstream XOR plus gzip format', () {
      const String json = '{"streaming":{},"providerOrder":[]}';
      expect(
        MiruroCatalogApi.decodePayload(Uint8List.fromList(utf8.encode(json))),
        json,
      );

      final List<int> compressed = gzip.encode(utf8.encode(json));
      final Uint8List masked = Uint8List(compressed.length);
      for (int i = 0; i < compressed.length; i++) {
        masked[i] = compressed[i] ^ _catalogKey[i % _catalogKey.length];
      }
      expect(MiruroCatalogApi.decodePayload(masked), json);
    });

    test('rejects oversized decompressed catalog data', () {
      final List<int> expanded = gzip.encode(
        List<int>.filled(MiruroCatalogApi.maxDecodedBytes + 1, 0x20),
      );
      final Uint8List masked = Uint8List(expanded.length);
      for (int i = 0; i < expanded.length; i++) {
        masked[i] = expanded[i] ^ _catalogKey[i % _catalogKey.length];
      }
      expect(
        () => MiruroCatalogApi.decodePayload(masked),
        throwsFormatException,
      );
    });
  });

  test('config ordering, labels and language are data-driven', () {
    const MiruroCatalogParser parser = MiruroCatalogParser();
    final List<MiruroProviderConfig> config = parser.parseConfig(
      jsonEncode({
        'providerOrder': ['anikoto', 'custom', 'hidden'],
        'streaming': {
          'custom': {'label': 'Community', 'visible': true},
          'anikoto': {'label': 'bee', 'visible': true, 'language': 'es-419'},
          'hidden': {'label': 'Hidden', 'visible': false},
        },
      }),
    );

    expect(config.map((item) => item.key), ['anikoto', 'custom', 'hidden']);
    expect(config.first.label, 'bee');
    expect(config.first.announcedLanguage, 'es-419');
    expect(config[1].announcedLanguage, 'unknown');
  });

  test('exact AniList mapping and regular whole-number episodes only', () {
    const MiruroCatalogParser parser = MiruroCatalogParser();
    expect(
      parser
          .parseTitle(
            jsonEncode({
              'data': [
                {'id': 'wrong', 'anilist_id': 4},
                {'id': 'right', 'anilist_id': 100240},
              ],
            }),
            anilistId: 100240,
          )
          ?.id,
      'right',
    );
    expect(
      parser.parseTitle(
        jsonEncode({
          'data': [
            {'id': 'wrong', 'anilist_id': 4},
          ],
        }),
        anilistId: 100240,
      ),
      isNull,
    );
    expect(
      parser.parseTitle(
        jsonEncode({
          'data': [
            {'id': 'ambiguous'},
            {'id': 'also-ambiguous'},
          ],
        }),
        anilistId: 100240,
      ),
      isNull,
    );

    final result = parser.parseEpisodes(
      jsonEncode({
        'data': [
          {'episode_number': 1, 'kind': 'regular'},
          {'episode_number': 2, 'kind': 'special'},
          {'episode_number': 2.5, 'kind': 'regular'},
          {'episode_number': 3},
          {'episode_number': 3, 'kind': 'regular'},
        ],
        'has_more': true,
        'next_cursor': 'cursor-2',
      }),
    );
    expect(result.episodes.map((item) => item.number), [1, 3]);
    expect(result.nextCursor, 'cursor-2');
    expect(
      () => parser.parseEpisodes('{"data":[],"has_more":true}'),
      throwsFormatException,
    );
  });

  test('one Miruro server groups quality variants and excludes embeds', () {
    const MiruroCatalogParser parser = MiruroCatalogParser();
    final EpisodeRef episode = _episodeRef();
    final List<MiruroProviderConfig> config = parser.parseConfig(
      jsonEncode({
        'providerOrder': ['anikoto', 'bee-embed'],
        'streaming': {
          'anikoto': {'label': 'bee', 'visible': true},
          'bee-embed': {
            'label': 'bee embed',
            'visible': true,
            'parent': 'anikoto',
            'relationship': 'embed',
          },
        },
      }),
    );
    final List<PlaybackSource> sources = parser.parsePlaybackSources(
      body: jsonEncode({
        'tracks': [
          {
            'track': 'sub',
            'providers': [
              {
                'provider': 'anikoto',
                'audio_language': 'ja',
                'subtitle_language': 'es',
                'servers': [
                  {
                    'server': 'primary',
                    'headers': {'Referer': 'https://www.miruro.cx/'},
                    'streams': [
                      {
                        'url': 'https://cdn.example.org/720.m3u8?sig=a',
                        'format': 'hls',
                        'quality': '720p',
                      },
                      {
                        'url': 'https://cdn.example.org/1080.m3u8?sig=b',
                        'format': 'hls',
                        'quality': '1080p',
                      },
                    ],
                  },
                  {
                    'server': 'backup',
                    'streams': [
                      {
                        'url': 'https://backup.example.net/video.m3u8',
                        'format': 'hls',
                        'quality': '480p',
                      },
                    ],
                  },
                ],
              },
              {
                'provider': 'bee-embed',
                'servers': [
                  {
                    'server': 'iframe-only',
                    'streams': [
                      {
                        'url': 'https://embed.example.net/player',
                        'format': 'embed',
                      },
                    ],
                  },
                ],
              },
            ],
          },
          {
            'track': 'dub',
            'providers': [
              {
                'provider': 'anikoto',
                'dubbing_type': 'latin',
                'servers': [
                  {
                    'server': 'dub-server',
                    'streams': [
                      {
                        'url': 'https://dub.example.org/episode.mp4',
                        'format': 'mp4',
                        'quality': '480p',
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }),
      config: config,
      episode: episode,
    );

    expect(sources, hasLength(2));
    final PlaybackSource sub = sources.first;
    expect(sub.displayName, 'bee · sub');
    expect(sub.audioLanguage, 'ja');
    expect(sub.subtitleLanguage, 'es');
    expect(sub.providerAnnouncedLanguage, 'unknown');
    expect(sub.dubbingType, PlaybackDubbingType.unknown);
    expect(sub.servers, hasLength(2));
    expect(sub.servers.first.displayName, 'primary · 1080p');
    expect(sub.servers.first.quality, '1080p');
    expect(sub.servers.first.mediaFormat, PlaybackMediaFormat.hls);
    expect(sub.servers.first.availability, PlaybackAvailability.listed);
    expect(
      sub.servers.first.requestHeaders.values['Referer'],
      'https://www.miruro.cx/',
    );
    expect(sub.servers.last.displayName, 'backup · 480p');
    expect(sources.last.language, 'dub');
    expect(sources.last.dubbingType, PlaybackDubbingType.latinSpanish);
    expect(sources.last.priority, lessThan(sub.priority));
  });

  test(
    'registered adapter reaches source and shared resolver via manager',
    () async {
      final _Pages pages = _Pages({
        '/api/v1/anime': (
          200,
          jsonEncode({
            'data': [
              {
                'id': 'tokyo-ghoul-re',
                'anilist_id': 100240,
                'title': {'english': 'Tokyo Ghoul:re'},
              },
            ],
          }),
        ),
        '/api/config': (
          200,
          jsonEncode({
            'providerOrder': ['anikoto'],
            'streaming': {
              'anikoto': {'label': 'bee', 'visible': true},
            },
          }),
        ),
        '/api/v1/anime/tokyo-ghoul-re/episodes/9/play': (
          200,
          jsonEncode({
            'tracks': [
              {
                'track': 'sub',
                'providers': [
                  {
                    'provider': 'anikoto',
                    'servers': [
                      {
                        'server': 'master',
                        'streams': [
                          {
                            'url': 'https://media.example.org/master',
                            'format': 'hls',
                            'quality': '720p',
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          }),
        ),
      }, encodeCatalog: true);
      final Dio client = Dio()..httpClientAdapter = pages;
      addTearDown(() => client.close(force: true));
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: [
          PlaybackProviderRegistration(
            provider: MiruroCatalogPlaybackProvider(
              MiruroCatalogApi(
                PublicPlaybackHttp(
                  client,
                  miruroCatalogOrigins.toSet(),
                  enforceCooldown: false,
                  maxConcurrent: 2,
                ),
                transport: pages,
              ),
            ),
            cacheTtl: Duration.zero,
            version: '1.0.0',
          ),
        ],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(),
          ),
        ],
        clock: DateTime.now,
      );

      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await manager.resolveCandidates(
            _requestedEpisode(),
            cancellation: PlaybackCancellationToken(),
          );
      expect(
        result,
        isA<PlaybackProviderSuccess<List<ResolvedPlaybackStream>>>(),
      );
      final ResolvedPlaybackStream stream =
          (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
              .value
              .single;
      expect(stream.providerId.value, 'miruro-catalog');
      expect(stream.uri, Uri.parse('https://media.example.org/master'));
      expect(stream.format, PlaybackMediaFormat.hls);
      expect(stream.sourceLabel, 'bee · sub');
      expect(stream.displayName, 'master · 720p');
      expect(stream.availability, PlaybackAvailability.listed);
      expect(pages.paths, [
        '/api/v1/anime',
        '/api/config',
        '/api/v1/anime/tokyo-ghoul-re/episodes/9/play',
      ]);
      expect(pages.userAgents.every((String? value) => value != null), isTrue);
      expect(
        pages.userAgents.any((String? value) => value!.contains('Mozilla')),
        isFalse,
      );
      expect(pages.referers, everyElement('https://www.miruro.cx/'));
    },
  );

  test('without an exact AniList identity it makes no request', () async {
    final _Pages pages = _Pages(const {});
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final provider = MiruroCatalogPlaybackProvider(
      MiruroCatalogApi(
        PublicPlaybackHttp(client, miruroCatalogOrigins.toSet()),
        transport: pages,
      ),
    );
    final result = await provider.findSources(
      PlaybackEpisode(animeId: AnimeId('local-only'), episodeNumber: 1),
      cancellation: PlaybackCancellationToken(),
    );
    expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    expect(pages.paths, isEmpty);
  });

  test('a 403 is surfaced without trying retired Miruro domains', () async {
    final _Pages pages = _Pages(const {'/api/config': (403, 'denied')});
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final MiruroCatalogApi api = MiruroCatalogApi(
      PublicPlaybackHttp(client, miruroCatalogOrigins.toSet()),
      transport: pages,
    );
    await expectLater(
      api.get(
        'config',
        cancellation: PlaybackCancellationToken(),
        stage: PlaybackHttpStage.catalog,
      ),
      throwsA(
        isA<PublicPlaybackFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              PlaybackProviderFailureKind.forbidden,
            )
            .having((failure) => failure.status, 'HTTP status', 403),
      ),
    );
    expect(pages.paths, ['/api/config']);
    expect(pages.hosts, ['www.miruro.cx']);
  });

  test('a 5xx does not retry retired Miruro domains', () async {
    final _Pages pages = _Pages(
      {'/api/config': (200, '{"streaming":{"anikoto":{"label":"bee"}}}')},
      statusesByHost: {'www.miruro.cx': 503},
    );
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final MiruroCatalogApi api = MiruroCatalogApi(
      PublicPlaybackHttp(
        client,
        miruroCatalogOrigins.toSet(),
        enforceCooldown: false,
      ),
      transport: pages,
    );
    await expectLater(
      api.get(
        'config',
        cancellation: PlaybackCancellationToken(),
        stage: PlaybackHttpStage.catalog,
      ),
      throwsA(
        isA<PublicPlaybackFailure>().having(
          (failure) => failure.kind,
          'failure kind',
          PlaybackProviderFailureKind.unavailable,
        ),
      ),
    );
    expect(pages.hosts, ['www.miruro.cx']);
    expect(pages.referers, ['https://www.miruro.cx/']);
  });

  test('cancellation is honored before making a request', () async {
    final _Pages pages = _Pages(const {});
    final Dio client = Dio()..httpClientAdapter = pages;
    addTearDown(() => client.close(force: true));
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken()
      ..cancel();
    final result = await MiruroCatalogPlaybackProvider(
      MiruroCatalogApi(
        PublicPlaybackHttp(client, miruroCatalogOrigins.toSet()),
        transport: pages,
      ),
    ).findSources(_requestedEpisode(), cancellation: cancellation);
    expect(
      result,
      isA<PlaybackProviderFailed<List<PlaybackSource>>>().having(
        (failure) => failure.failure.kind,
        'kind',
        PlaybackProviderFailureKind.cancelled,
      ),
    );
    expect(pages.paths, isEmpty);
  });
}

const List<int> _catalogKey = <int>[
  0x6d,
  0x69,
  0x72,
  0x75,
  0x72,
  0x6f,
  0x2f,
  0x63,
  0x61,
  0x74,
  0x61,
  0x6c,
  0x6f,
  0x67,
];

PlaybackEpisode _requestedEpisode() => PlaybackEpisode(
  animeId: AnimeId('tokyo-ghoul-re'),
  episodeNumber: 9,
  externalAnimeId: ExternalAnimeId(
    providerId: MetadataProviderId('anilist'),
    value: '100240',
  ),
  animeTitles: const ['Tokyo Ghoul:re'],
);

EpisodeRef _episodeRef() {
  final AnimeIdentity identity = AnimeIdentity(
    localId: AnimeId('tokyo-ghoul-re'),
    externalIds: [
      ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '100240',
      ),
    ],
    titles: const ['Tokyo Ghoul:re'],
  );
  return EpisodeRef(
    anime: SourceAnimeMatch(
      providerId: PlaybackProviderId('miruro-catalog'),
      sourceAnimeId: 'tokyo-ghoul-re',
      title: 'Tokyo Ghoul:re',
      requestedIdentity: identity,
      evidence: AnimeMatchEvidence.externalId,
      externalIds: identity.externalIds,
    ),
    episodeId: 'miruro:tokyo-ghoul-re:9',
    episodeNumber: 9,
  );
}

final class _Pages implements HttpClientAdapter, MiruroCatalogTransport {
  _Pages(
    this.pages, {
    this.statusesByHost = const <String, int>{},
    this.encodeCatalog = false,
  });

  final Map<String, (int, String)> pages;
  final Map<String, int> statusesByHost;
  final bool encodeCatalog;
  final List<String> paths = <String>[];
  final List<String> hosts = <String>[];
  final List<String?> userAgents = <String?>[];
  final List<String?> referers = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.path);
    hosts.add(options.uri.host);
    userAgents.add(options.headers['User-Agent'] as String?);
    referers.add(options.headers['Referer'] as String?);
    expect(options.method, 'GET');
    expect(options.followRedirects, isFalse);
    final (int defaultStatus, String body) =
        pages[options.uri.path] ?? (404, '');
    final int status = statusesByHost[options.uri.host] ?? defaultStatus;
    if (encodeCatalog && status == 200) {
      final List<int> compressed = gzip.encode(utf8.encode(body));
      final Uint8List masked = Uint8List(compressed.length);
      for (int i = 0; i < compressed.length; i++) {
        masked[i] = compressed[i] ^ _catalogKey[i % _catalogKey.length];
      }
      return ResponseBody.fromBytes(
        masked,
        status,
        headers: const {
          'content-type': ['application/octet-stream'],
        },
      );
    }
    return ResponseBody.fromString(
      body,
      status,
      headers: const <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  /// Serves the same fixtures to the HTTP/2 catalog transport, so the adapter
  /// tests never touch the network and still assert the real header set.
  @override
  Future<MiruroHttp2Response> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
    required int maxBytes,
  }) async {
    paths.add(uri.path);
    hosts.add(uri.host);
    userAgents.add(headers['user-agent']);
    referers.add(headers['referer']);
    expect(headers['sec-fetch-site'], 'same-origin');
    expect(headers['origin'], 'https://${uri.host}');
    final (int defaultStatus, String body) = pages[uri.path] ?? (404, '');
    final int status = statusesByHost[uri.host] ?? defaultStatus;
    if (encodeCatalog && status == 200) {
      final List<int> compressed = gzip.encode(utf8.encode(body));
      final Uint8List masked = Uint8List(compressed.length);
      for (int i = 0; i < compressed.length; i++) {
        masked[i] = compressed[i] ^ _catalogKey[i % _catalogKey.length];
      }
      return MiruroHttp2Response(
        statusCode: status,
        headers: const <String, String>{
          'content-type': 'application/octet-stream',
        },
        body: masked,
      );
    }
    return MiruroHttp2Response(
      statusCode: status,
      headers: const <String, String>{'content-type': 'application/json'},
      body: Uint8List.fromList(utf8.encode(body)),
    );
  }

  @override
  void close({bool force = false}) {}
}
