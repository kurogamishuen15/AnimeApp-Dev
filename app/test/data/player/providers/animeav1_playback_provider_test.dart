import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/animeav1/animeav1_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

PlaybackEpisode _request({bool mal = true, int number = 1}) => PlaybackEpisode(
  animeId: AnimeId('naruto'),
  episodeNumber: number,
  animeTitles: ['Naruto'],
  externalAnimeIds: [
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '20'),
    if (mal)
      ExternalAnimeId(
        providerId: MetadataProviderId('myanimelist'),
        value: '20',
      ),
  ],
);

Map<String, Object?> _media({int mal = 20}) => {
  'malId': mal,
  'episodes': [
    {'number': 1},
    {'number': 2},
    {'number': 1.5},
    {'number': 1},
  ],
};

Map<String, Object?> _episode({int number = 1, bool dub = true}) => {
  'media': _media(),
  'episode': {
    'number': number,
    'variants': {'SUB': 1, if (dub) 'DUB': 1},
  },
  'embeds': {
    'SUB': [
      {'server': 'Voe', 'url': 'https://voe.sx/e/subfixture'},
    ],
    'DUB': [
      {
        'server': 'YourUpload',
        'url': 'https://www.yourupload.com/embed/dubfixture',
      },
      {
        'server': 'MP4Upload',
        'url': 'https://www.mp4upload.com/embed-dubfixture.html',
      },
      {'server': 'Voe', 'url': 'https://voe.sx/e/dubfixture'},
      {'server': 'Voe', 'url': 'https://127.0.0.1/private'},
      {'server': 'Voe', 'url': 'https://voe.sx/e/dubfixture'},
      {'server': 'UPNShare', 'url': 'https://other.anime.org/unknown'},
    ],
  },
};

// Minimal fixtures model the public SvelteKit/devalue payload, without signed media.
String _page(Object root) {
  final flat = <Object?>[];
  int add(Object? value) {
    final index = flat.length;
    flat.add(null);
    flat[index] = switch (value) {
      Map<String, Object?> value => value.map(
        (key, child) => MapEntry(key, add(child)),
      ),
      List<Object?> value => value.map(add).toList(),
      _ => value,
    };
    return index;
  }

  add(root);
  return jsonEncode({
    'nodes': [
      null,
      {'type': 'data', 'data': flat},
    ],
  });
}

void main() {
  late _Pages pages;
  late Dio client;
  late AnimeAv1PlaybackProvider provider;
  setUp(() {
    pages = _Pages();
    client = Dio()..httpClientAdapter = pages;
    provider = AnimeAv1PlaybackProvider(client);
  });
  tearDown(() => client.close(force: true));

  test('MAL confirmed index resolves separate SUB and DUB embeds', () async {
    final result = await provider.findSources(
      _request(),
      cancellation: PlaybackCancellationToken(),
    );
    final sources =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value;
    expect(sources.length, 2);
    final serverIds = sources
        .expand((source) => source.servers)
        .map((s) => s.id)
        .toList();
    expect(serverIds.toSet().length, serverIds.length);
    final sub = sources.singleWhere((s) => s.audioLanguage == 'ja');
    final dub = sources.singleWhere((s) => s.audioLanguage == 'es');
    expect(sub.subtitleLanguage, 'es');
    expect(sub.dubbingType, PlaybackDubbingType.originalAudio);
    expect(dub.dubbingType, PlaybackDubbingType.latinSpanish);
    expect(dub.subtitleLanguage, isNull);
    expect(dub.servers.map((s) => s.hostId), [
      'yourupload',
      'mp4upload',
      'voe',
    ]);
    expect(
      dub.servers.every((s) => s.kind == PlaybackCandidateKind.embed),
      isTrue,
    );
    expect(
      dub.servers.every((s) => s.endpoint.path.contains('dubfixture')),
      isTrue,
    );
    expect(sub.servers.single.endpoint.path, '/e/subfixture');
    expect(sub.subtitles, isEmpty); // hardsub never becomes an external track
    for (final request in pages.requests) {
      expect(request.method, 'GET');
      expect(request.headers['Referer'], 'https://animeav1.com/');
      expect(
        request.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('cookie')),
      );
    }
    expect(pages.requests.first.uri.queryParameters['search'], 'Naruto');
  });

  test(
    'missing MAL refuses title-only and AniList-only identity without HTTP',
    () async {
      final result = await provider.findSources(
        _request(mal: false),
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        PlaybackProviderFailureKind.missingId,
      );
      expect(pages.requests, isEmpty);
    },
  );

  test('matching title with different MAL cannot become a source', () async {
    pages.detailMal = 999;
    final result = await provider.findSources(
      _request(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    expect(pages.requests.any((r) => r.uri.path.contains('/1/')), isFalse);
  });

  test(
    'index omits fractional episodes and deduplicates whole numbers',
    () async {
      final found = await provider.searchAnime(
        _request().identity,
        cancellation: PlaybackCancellationToken(),
      );
      final match = (found as PlaybackProviderSuccess<List<SourceAnimeMatch>>)
          .value
          .single;
      final result = await provider.listEpisodes(
        match,
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderSuccess<List<EpisodeRef>>).value.map(
          (e) => e.episodeNumber,
        ),
        [1, 2],
      );
    },
  );

  test('does not invent a requested episode absent from title index', () async {
    final result = await provider.findSources(
      _request(number: 9),
      cancellation: PlaybackCancellationToken(),
    );
    expect(result, isA<PlaybackProviderEmpty<List<PlaybackSource>>>());
    expect(
      pages.requests.any((r) => r.uri.path.endsWith('/9/__data.json')),
      isFalse,
    );
  });

  test('per-episode variants govern dub even when DUB embed exists', () async {
    pages.episode = _episode(dub: false);
    final result = await provider.findSources(
      _request(),
      cancellation: PlaybackCancellationToken(),
    );
    final sources =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value;
    expect(sources.single.audioLanguage, 'ja');
  });

  test(
    'episode payload cannot silently substitute another number or MAL',
    () async {
      pages.episode = _episode(number: 2);
      var result = await provider.findSources(
        _request(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        PlaybackProviderFailureKind.invalidResponse,
      );
      pages.episode = {..._episode(), 'media': _media(mal: 999)};
      result = await provider.findSources(
        _request(),
        cancellation: PlaybackCancellationToken(),
      );
      expect(
        (result as PlaybackProviderFailed).failure.kind,
        PlaybackProviderFailureKind.invalidResponse,
      );
    },
  );

  test(
    '403 stops the lookup without another title or endpoint attempt',
    () async {
      pages.status = 403;
      final result = await provider.findSources(
        _request(),
        cancellation: PlaybackCancellationToken(),
      );
      expect((result as PlaybackProviderFailed).failure.httpStatus, 403);
      expect(pages.requests.length, 1);
    },
  );

  test('cancelled lookup issues no request', () async {
    final token = PlaybackCancellationToken()..cancel();
    final result = await provider.findSources(_request(), cancellation: token);
    expect(
      (result as PlaybackProviderFailed).failure.kind,
      PlaybackProviderFailureKind.cancelled,
    );
    expect(pages.requests, isEmpty);
  });

  test('malformed devalue graph fails closed and cannot expand cycles', () {
    expect(
      () => AnimeAv1PageData.decode(
        '{"nodes":[{"type":"data","data":[{"self":0}]}]}',
      ),
      throwsFormatException,
    );
    expect(
      () => AnimeAv1PageData.decode(
        '{"nodes":[{"type":"data","data":[{"bad":999}]}]}',
      ),
      throwsFormatException,
    );
    expect(
      () => AnimeAv1PageData.decode('{"nodes":[]}'),
      throwsFormatException,
    );
  });

  test('configurable origin stays within exact HTTPS root', () async {
    provider = AnimeAv1PlaybackProvider(
      client,
      origin: Uri.parse('https://catalog.anime.org'),
    );
    await provider.findSources(
      _request(),
      cancellation: PlaybackCancellationToken(),
    );
    expect(
      pages.requests.every((r) => r.uri.host == 'catalog.anime.org'),
      isTrue,
    );
    expect(
      () => AnimeAv1PlaybackProvider(
        client,
        origin: Uri.parse('https://127.0.0.1'),
      ),
      throwsArgumentError,
    );
  });

  test(
    'multi-host sources pass the manager source validation and resolve',
    () async {
      // Regression (2026-11-18): a live episode offers several hosts (voe +
      // mp4upload), and the manager's `_validateSources` rejects multi-server
      // sources unless the provider declares `sourceAlternatives`. The
      // provider-level tests never surfaced it because they bypass manager
      // validation.
      final manager = PlaybackProviderManager(
        providers: [PlaybackProviderRegistration(provider: provider)],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(
            resolver: _PassThroughEmbedResolver(),
            version: '1.0.0',
          ),
        ],
        clock: DateTime.now,
      );
      final result = await manager.resolveCandidates(
        _request(),
        cancellation: PlaybackCancellationToken(),
      );
      final streams =
          (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>)
              .value;
      expect(streams.length, 4); // SUB voe + DUB yourupload/mp4upload/voe.
      expect(
        streams.map((stream) => stream.serverId).toSet().length,
        streams.length,
      );
    },
  );
}

/// Contract-faithful test resolver: accepts any embed candidate and returns
/// a resolved stream echoing the manager-validated identities.
final class _PassThroughEmbedResolver implements PlaybackVideoHostResolver {
  @override
  String get resolverId => 'test-embed-passthrough';

  @override
  String get hostId => 'embed-passthrough';

  @override
  bool supports(SourceCandidate candidate) =>
      candidate.kind == PlaybackCandidateKind.embed;

  @override
  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve(
    PlaybackSource source,
    SourceCandidate candidate, {
    required PlaybackCancellationToken cancellation,
  }) async => PlaybackProviderSuccess<ResolvedPlaybackStream>(
    PlayableSource(
      providerId: source.providerId,
      sourceId: source.id,
      serverId: candidate.id,
      uri: candidate.endpoint,
      format: PlaybackMediaFormat.unknown,
      provenance: 'test passthrough',
    ),
  );
}

final class _Pages implements HttpClientAdapter {
  int detailMal = 20;
  int status = 200;
  Map<String, Object?> episode = _episode();
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final root = switch (options.uri.path) {
      '/catalogo/__data.json' => {
        'results': [
          {'slug': 'naruto', 'title': 'Naruto'},
        ],
      },
      '/media/naruto/__data.json' => {'media': _media(mal: detailMal)},
      _ => episode,
    };
    return ResponseBody.fromString(
      _page(root),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
