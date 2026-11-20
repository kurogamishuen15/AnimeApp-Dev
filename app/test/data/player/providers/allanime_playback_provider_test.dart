import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/allanime/allanime_playback_provider.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

PlaybackEpisode _episode({bool withMal = true}) => PlaybackEpisode(
  animeId: AnimeId('test'),
  episodeNumber: 9,
  externalAnimeIds: [
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '100240'),
    if (withMal)
      ExternalAnimeId(
        providerId: MetadataProviderId('myanimelist'),
        value: '21199',
      ),
  ],
  animeTitles: const ['Tokyo Ghoul:re'],
);

/// Test materials: the provider pins a mask; the fixture bootstraps with a
/// matching partB so key = partB XOR mask, and encrypts tobeparsed with that
/// key. Everything the adapter verifies is self-consistent.
const AllAnimeBootMaterials _testMaterials = AllAnimeBootMaterials(
  buildId: '190',
  maskHex: '0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f',
  bootPrefix: 'rEVwtVi:190',
  joinPrefix: 'mkissa.to~k7~190~mkissa~',
  queryHash: '670bbf38d0868f446e2346c1e956ca2c40c416e733ca248fd54e04f1c8b99145',
);

/// partB that XORs with the mask into the key a1a1..a1 (32 bytes).
final String _testPartB = base64.encode(
  Uint8List.fromList(List<int>.generate(32, (int i) => 0x0f ^ 0xa1)),
);

final Uint8List _testKey = Uint8List.fromList(
  List<int>.generate(32, (int i) => 0xa1),
);

Future<String> _encryptTobeparsed(Map<String, Object?> payload) async {
  final iv = Uint8List.fromList(List<int>.generate(12, (int i) => i));
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(jsonEncode(payload)),
    secretKey: SecretKey(_testKey),
    nonce: iv,
  );
  final wire = Uint8List(13 + box.cipherText.length + box.mac.bytes.length);
  wire[0] = 1;
  wire.setRange(1, 13, iv);
  wire.setRange(13, 13 + box.cipherText.length, box.cipherText);
  wire.setRange(13 + box.cipherText.length, wire.length, box.mac.bytes);
  return base64.encode(wire);
}

void main() {
  test(
    'MAL crosswalk resolves client-crypto sources through the manager',
    () async {
      final String tobeparsed = await _encryptTobeparsed({
        'episode': {
          'sourceUrls': [
            {
              'sourceUrl': 'https://tools.fast4speed.rsvp/media/sub/9',
              'type': 'player',
              'sourceName': 'Yt-mp4',
              'fileExtenstion': 'mp4',
            },
            {
              'sourceUrl': 'https://ok.ru/videoembed/1',
              'type': 'iframe',
              'sourceName': 'Ok',
            },
          ],
        },
      });
      final api = _Api(
        searchBody: {
          'data': {
            'shows': {
              'edges': [
                {
                  '_id': 'show-1',
                  'name': 'Tokyo Ghoul:re',
                  'malId': '21199',
                  'englishName': 'Tokyo Ghoul:re',
                },
                {'_id': 'show-9', 'name': 'Unrelated Series'},
              ],
            },
          },
        },
        bootstrapBody: {
          'epoch': 2967,
          'epochMs': 604800000,
          'graceMs': 86400000,
          'switchAt': 1795132800000,
          'partB': _testPartB,
          'k': 'k7',
        },
        sourcesBody: jsonEncode({
          'data': {'tobeparsed': tobeparsed},
        }),
      );
      final Dio client = Dio()..httpClientAdapter = api;
      addTearDown(() => client.close(force: true));
      final provider = AllAnimePlaybackProvider(
        client,
        materials: _testMaterials,
      );
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
      expect(streams, hasLength(1));
      expect(
        streams.single.uri.toString(),
        'https://tools.fast4speed.rsvp/media/sub/9',
      );
      expect(streams.single.format, PlaybackMediaFormat.mp4);
      expect(
        streams.single.httpHeaders.values['Referer'],
        'https://mkissa.to/',
      );
      expect(
        streams.single.httpHeaders.values['User-Agent'],
        'Kongroo/0.1 (public anime catalog client)',
      );
      // Bootstrap carries the signed boot token and build id.
      final RequestOptions bootstrap = api.requests.firstWhere(
        (RequestOptions r) => r.uri.path == '/client-crypto/v1/bootstrap',
      );
      expect(
        bootstrap.headers['User-Agent'],
        'Kongroo/0.1 (public anime catalog client)',
      );
      expect(bootstrap.headers['x-build-id'], '190');
      expect(
        RegExp(r'^[0-9a-f]{64}$')
            .hasMatch(bootstrap.headers['x-aa-boot'] as String),
        isTrue,
      );
      // The sources query carries the lane and the aaReq token.
      final RequestOptions sources = api.requests.firstWhere(
        (RequestOptions r) => r.uri.path == '/api' && r.method == 'GET',
      );
      expect(
        sources.headers['User-Agent'],
        'Kongroo/0.1 (public anime catalog client)',
      );
      expect(sources.headers['x-build-id'], '190');
      final Map<String, Object?> extensions = (jsonDecode(
        sources.uri.queryParameters['extensions']!,
      ) as Map<dynamic, dynamic>).cast<String, Object?>();
      expect(extensions['k'], 'k7');
      expect(
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(extensions['aaReq'] as String),
        isTrue,
      );
    },
  );

  test('dub variant uses its own identity and translation type', () async {
    final String tobeparsed = await _encryptTobeparsed({
      'episode': {
        'sourceUrls': [
          {
            'sourceUrl': 'https://tools.fast4speed.rsvp/media/dub/9',
            'type': 'player',
            'sourceName': 'Yt-mp4',
          },
        ],
      },
    });
    final api = _Api(
      searchBody: {
        'data': {
          'shows': {
            'edges': [
              {'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199'},
            ],
          },
        },
      },
      bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
      sourcesBody: jsonEncode({
        'data': {'tobeparsed': tobeparsed},
      }),
    );
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      variant: AllAnimeAudioVariant.dub,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    final source =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value.single;
    expect(source.providerId.value, 'allanime-dub');
    expect(source.providerAnnouncedLanguage, 'dub');
    expect(source.displayName, 'AllAnime · Doblaje (dub)');
    expect(
      api.requests
          .where(
            (RequestOptions r) => r.uri.path == '/api' && r.method == 'GET',
          )
          .map((RequestOptions r) => r.uri.queryParameters['variables'])
          .any(
            (String? v) => v != null && v.contains('"translationType":"dub"'),
          ),
      isTrue,
    );
  });

  test('exact title match works when no MAL crosswalk exists', () async {
    final String tobeparsed = await _encryptTobeparsed({
      'episode': {
        'sourceUrls': [
          {
            'sourceUrl': 'https://tools.fast4speed.rsvp/media/sub/9',
            'type': 'player',
          },
        ],
      },
    });
    final api = _Api(
      searchBody: {
        'data': {
          'shows': {
            'edges': [
              {'_id': 'show-7', 'name': 'Tokyo Ghoul:re'},
              {'_id': 'show-8', 'name': 'Tokyo Ghoul'},
            ],
          },
        },
      },
      bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
      sourcesBody: jsonEncode({
        'data': {'tobeparsed': tobeparsed},
      }),
    );
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(withMal: false),
      cancellation: PlaybackCancellationToken(),
    );
    final source =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value.single;
    expect(source.id, 'allanime:show-7:9:sub');
    expect(source.servers.single.endpoint.host, 'tools.fast4speed.rsvp');
  });

  test('a different title never becomes a match', () async {
    final api = _Api(
      searchBody: {
        'data': {
          'shows': {
            'edges': [
              {'_id': 'show-8', 'name': 'Tokyo Ghoul'},
            ],
          },
        },
      },
      bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
      sourcesBody: '{}',
    );
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(withMal: false),
      cancellation: PlaybackCancellationToken(),
    );
    expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    expect(api.requests, hasLength(1)); // search only
  });

  test('invalid boot token surfaces unavailable (build rotation)', () async {
    final api = _Api(
      searchBody: {
        'data': {
          'shows': {
            'edges': [
              {'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199'},
            ],
          },
        },
      },
      bootstrapBody: {'error': 'invalid_boot_token'},
      sourcesBody: '{}',
    );
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.unavailable,
    );
  });

  test('aaReq rejection shape degrades to noSources for fallback', () async {
    final api = _Api(
      searchBody: {
        'data': {
          'shows': {
            'edges': [
              {'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199'},
            ],
          },
        },
      },
      bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
      sourcesBody: jsonEncode({
        'errors': [
          {
            'message': 'AA_CRYPTO_STALE',
            'extensions': {'code': 'AA_CRYPTO_STALE'},
          },
        ],
        'data': <String, Object?>{},
      }),
    );
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.noSources,
    );
  });

  test(
    'a captcha demand is classified as challenge, never solved or evaded',
    () async {
      // Live shape (2026-11-18): after sustained probing the API answers
      // NEED_CAPTCHA (Cloudflare Turnstile). Kongroo surfaces the honest
      // `challenge` failure so the manager falls back to other providers.
      final api = _Api(
        searchBody: {
          'data': {
            'shows': {
              'edges': [
                {'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199'},
              ],
            },
          },
        },
        bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
        sourcesBody: jsonEncode({
          'errors': [
            {
              'message': 'NEED_CAPTCHA',
              'extensions': {'code': 'INTERNAL_SERVER_ERROR'},
            },
          ],
          'data': <String, Object?>{'episode': null},
        }),
      );
      final Dio client = Dio()..httpClientAdapter = api;
      addTearDown(() => client.close(force: true));
      final provider = AllAnimePlaybackProvider(
        client,
        materials: _testMaterials,
      );
      final result = await provider.findSources(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        PlaybackProviderFailureKind.challenge,
      );
    },
  );

  test('captcha variants the site itself detects stay challenge', () async {
    // The site's own client matches NEED_CAPTCHA as a substring and also reads
    // `extensions.exception.code`; the API has used both shapes. A variant
    // that only matched strictly would silently degrade to noSources and stop
    // the manager from reporting the honest access condition.
    final api = _Api(
      searchBody: {
        'data': {
          'shows': {
            'edges': [
              {'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199'},
            ],
          },
        },
      },
      bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
      sourcesBody: jsonEncode({
        'errors': [
          {
            'message': 'Request rejected: NEED_CAPTCHA required',
            'extensions': {
              'exception': {'code': 'NEED_CAPTCHA'},
            },
          },
        ],
        'data': <String, Object?>{'episode': null},
      }),
    );
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.challenge,
    );
  });

  test('no direct player sources is noSources', () async {
    final String tobeparsed = await _encryptTobeparsed({
      'episode': {
        'sourceUrls': [
          {'sourceUrl': 'https://ok.ru/videoembed/1', 'type': 'iframe'},
        ],
      },
    });
    final api = _Api(
      searchBody: {
        'data': {
          'shows': {
            'edges': [
              {'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199'},
            ],
          },
        },
      },
      bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
      sourcesBody: jsonEncode({
        'data': {'tobeparsed': tobeparsed},
      }),
    );
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.noSources,
    );
  });

  for (final int status in [403, 404]) {
    test('sources HTTP $status stops without retries', () async {
      final api = _Api(
        searchBody: {
          'data': {
            'shows': {
              'edges': [
                {'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199'},
              ],
            },
          },
        },
        bootstrapBody: {'epoch': 2967, 'partB': _testPartB, 'k': 'k7'},
        sourcesBody: '{}',
        sourcesStatus: status,
      );
      final Dio client = Dio()..httpClientAdapter = api;
      addTearDown(() => client.close(force: true));
      final provider = AllAnimePlaybackProvider(
        client,
        materials: _testMaterials,
      );
      final result = await provider.findSources(
        _episode(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        status == 403
            ? PlaybackProviderFailureKind.forbidden
            : PlaybackProviderFailureKind.notFound,
      );
    });
  }

  test('cancellation makes no requests', () async {
    final api = _Api(searchBody: {}, bootstrapBody: {}, sourcesBody: '{}');
    final Dio client = Dio()..httpClientAdapter = api;
    addTearDown(() => client.close(force: true));
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
    final result = await provider.findSources(
      _episode(),
      cancellation: PlaybackCancellationToken()..cancel(),
    );
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.cancelled,
    );
    expect(api.requests, isEmpty);
  });

  test('x-build-id and x-aa-boot headers are validated contracts', () {
    expect(
      () => PlaybackRequestHeaders({'x-build-id': '19; DROP'}),
      throwsArgumentError,
    );
    expect(
      () => PlaybackRequestHeaders({'x-aa-boot': 'not-hex'}),
      throwsArgumentError,
    );
    expect(
      PlaybackRequestHeaders({
        'x-build-id': '190',
        'x-aa-boot':
            'c53c5a10c827b603983e8e5c6a156b11dd4050741ab18b5fdc8b56d14298cac0',
      }).values['x-build-id'],
      '190',
    );
  });
}

final class _Api implements HttpClientAdapter {
  _Api({
    required this.searchBody,
    required this.bootstrapBody,
    required this.sourcesBody,
    this.sourcesStatus = 200,
  });

  final Object searchBody;
  final Object bootstrapBody;
  final String sourcesBody;
  final int sourcesStatus;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final String path = options.uri.path;
    if (options.method == 'POST' && path == '/api') {
      return ResponseBody.fromString(
        searchBody is String ? searchBody as String : jsonEncode(searchBody),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (path == '/client-crypto/v1/bootstrap') {
      return ResponseBody.fromString(
        jsonEncode(bootstrapBody),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (options.method == 'GET' && path == '/api') {
      return ResponseBody.fromString(
        sourcesBody,
        sourcesStatus,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    return ResponseBody.fromString('{}', 404);
  }

  @override
  void close({bool force = false}) {}
}
