import 'dart:io';
import 'dart:typed_data';

import 'package:anime_app/data/aniskip/aniskip_client.dart';
import 'package:anime_app/data/aniskip/aniskip_response_cache.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/skips/skip_segment.dart';
import 'package:anime_app/domain/player/skips/skip_segment_catalog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

final class _MemoryCache implements AniSkipResponseCache {
  final Map<String, CachedAniSkipResponse> values = {};
  final List<String> invalidations = [];

  @override
  Future<CachedAniSkipResponse?> read(String key) async => values[key];

  @override
  Future<void> write(String key, CachedAniSkipResponse response) async {
    values[key] = response;
  }

  @override
  Future<void> invalidate(String key) async {
    invalidations.add(key);
    values.remove(key);
  }
}

const String _validBody = '''
{"found":true,"results":[
 {"skipType":"op","interval":{"startTime":82.25,"endTime":101.5},"skipId":"opening-a","votes":8},
 {"skipType":"ed","interval":{"startTime":1300,"endTime":1320},"skipId":"ending-a","timesToConfirm":3},
 {"skipType":"recap","interval":{"startTime":40,"endTime":60},"skipId":"future-type"},
 {"skipType":"op","interval":{"startTime":82.25,"endTime":101.5},"skipId":"duplicate"}
]}
''';

void main() {
  final PlaybackEpisode episode = PlaybackEpisode(
    animeId: AnimeId('skip-test-anime'),
    episodeNumber: 4,
  );

  test(
    'uses explicit MAL identity, maps only OP/ED, and deduplicates ranges',
    () async {
      final _FakeAdapter adapter = _FakeAdapter(
        (_) => ResponseBody.fromString(_validBody, HttpStatus.ok),
      );
      final Dio dio = Dio()..httpClientAdapter = adapter;
      final _MemoryCache cache = _MemoryCache();
      final AniSkipClient client = AniSkipClient(
        dio: dio,
        cache: cache,
        clock: () => DateTime.utc(2026, 11, 11),
      );

      final SkipCatalogResult result = await client.lookup(
        episode: episode,
        malAnimeId: MyAnimeListAnimeId(5114),
      );

      expect(result, isA<SkipCatalogSuccess>());
      final List<SkipSegment> segments =
          (result as SkipCatalogSuccess).segments;
      expect(segments.map((SkipSegment item) => item.kind), [
        SkipSegmentKind.opening,
        SkipSegmentKind.ending,
      ]);
      expect(segments.first.start, const Duration(milliseconds: 82250));
      expect(segments.first.votes, 8);
      expect(segments.last.confirmations, 3);
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.uri.path, '/v1/skip-times/5114/4');
      expect(cache.values.keys, {'v1-5114-4'});
      dio.close(force: true);
    },
  );

  test(
    'success and empty responses cache for seven days; errors do not',
    () async {
      DateTime now = DateTime.utc(2026, 11, 11);
      var requestCount = 0;
      final _FakeAdapter adapter = _FakeAdapter((_) {
        requestCount++;
        return ResponseBody.fromString(
          requestCount == 1 ? _validBody : '{"found":false,"results":[]}',
          HttpStatus.ok,
        );
      });
      final Dio dio = Dio()..httpClientAdapter = adapter;
      final _MemoryCache cache = _MemoryCache();
      final AniSkipClient client = AniSkipClient(
        dio: dio,
        cache: cache,
        clock: () => now,
      );

      await client.lookup(episode: episode, malAnimeId: MyAnimeListAnimeId(1));
      now = now.add(const Duration(days: 6, hours: 23));
      await client.lookup(episode: episode, malAnimeId: MyAnimeListAnimeId(1));
      expect(requestCount, 1);
      now = DateTime.utc(2026, 11, 19);
      final SkipCatalogResult empty = await client.lookup(
        episode: episode,
        malAnimeId: MyAnimeListAnimeId(1),
      );
      expect(empty, isA<SkipCatalogSuccess>());
      expect((empty as SkipCatalogSuccess).segments, isEmpty);
      expect(requestCount, 2);
      await client.lookup(episode: episode, malAnimeId: MyAnimeListAnimeId(1));
      expect(requestCount, 2);
      dio.close(force: true);
    },
  );

  test(
    'rejects malformed intervals and negative confidence metadata',
    () async {
      Future<SkipCatalogResult> query(String body) async {
        final Dio dio = Dio()
          ..httpClientAdapter = _FakeAdapter(
            (_) => ResponseBody.fromString(body, HttpStatus.ok),
          );
        final SkipCatalogResult result = await AniSkipClient(
          dio: dio,
          cache: _MemoryCache(),
        ).lookup(episode: episode, malAnimeId: MyAnimeListAnimeId(2));
        dio.close(force: true);
        return result;
      }

      expect(
        await query(
          '{"found":true,"results":[{"skipType":"op","interval":{"startTime":4,"endTime":4}}]}',
        ),
        isA<SkipCatalogFailure>(),
      );
      expect(
        await query(
          '{"found":true,"results":[{"skipType":"ed","interval":{"startTime":3,"endTime":4},"votes":-1}]}',
        ),
        isA<SkipCatalogFailure>(),
      );
      expect(await query('[]'), isA<SkipCatalogFailure>());
    },
  );

  test(
    'file cache round trips, expires by caller policy, and rejects paths',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'aniskip-cache-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final FileAniSkipResponseCache cache = FileAniSkipResponseCache(
        directory: directory,
      );
      final CachedAniSkipResponse response = CachedAniSkipResponse(
        body: '{"found":false,"results":[]}',
        retrievedAt: DateTime.utc(2026, 11, 11),
        expiresAt: DateTime.utc(2026, 11, 18),
      );
      await cache.write('v1-123-4', response);
      final CachedAniSkipResponse? cached = await cache.read('v1-123-4');
      expect(cached?.body, response.body);
      expect(cached?.retrievedAt, response.retrievedAt);
      expect(cached?.expiresAt, response.expiresAt);
      await cache.invalidate('v1-123-4');
      expect(await cache.read('v1-123-4'), isNull);
      await expectLater(cache.read('../private'), throwsArgumentError);
    },
  );
}
