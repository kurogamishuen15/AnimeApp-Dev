import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/data/player/providers/allanime/allanime_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

import '../../refactor/source_snapshot.dart';

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

final class FixtureApi implements HttpClientAdapter {
  FixtureApi({
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

Future<Map<String, Object?>> snapshot() async {
  final pages = FixtureApi(
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
      'data': {
        'tobeparsed': await _encryptTobeparsed({
          'episode': {
            'sourceUrls': [
              {
                'sourceUrl': 'https://tools.fast4speed.rsvp/media/sub/9',
                'type': 'player',
                'sourceName': 'Yt-mp4',
                'fileExtenstion': 'mp4',
              },
            ],
          },
        }),
      },
    }),
  );
  final client = Dio()..httpClientAdapter = pages;
  try {
    final provider = AllAnimePlaybackProvider(
      client,
      materials: _testMaterials,
    );
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
