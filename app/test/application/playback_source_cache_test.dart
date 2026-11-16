import 'package:anime_app/application/player/providers/playback_source_cache.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 11, 16);

  test(
    'candidate expiry shortens cache TTL and expired entries are removed',
    () {
      final PlaybackSourceCache cache = PlaybackSourceCache(capacity: 2);
      final List<PlaybackSource> sources = [
        _source(expiresAt: now.add(const Duration(seconds: 5))),
      ];
      cache.write(
        'episode',
        sources,
        now: now,
        ttl: const Duration(minutes: 1),
        validUntil: sources.single.servers.single.expiresAt,
      );

      expect(
        cache.read('episode', now.add(const Duration(seconds: 4))),
        isNotNull,
      );
      expect(
        cache.read('episode', now.add(const Duration(seconds: 5))),
        isNull,
      );
      expect(cache.length, 0);
    },
  );

  test('LRU bounds memory and zero TTL does not retain signed candidates', () {
    final PlaybackSourceCache cache = PlaybackSourceCache(capacity: 2);
    cache.write('one', [_source()], now: now, ttl: const Duration(seconds: 30));
    cache.write('two', [_source()], now: now, ttl: const Duration(seconds: 30));
    expect(cache.read('one', now), isNotNull); // promote one to most recent
    cache.write(
      'three',
      [_source()],
      now: now,
      ttl: const Duration(seconds: 30),
    );

    expect(cache.read('two', now), isNull);
    expect(cache.read('one', now), isNotNull);
    expect(cache.read('three', now), isNotNull);
    cache.write('zero', [_source()], now: now, ttl: Duration.zero);
    expect(cache.read('zero', now), isNull);
    expect(cache.length, 2);
  });
}

PlaybackSource _source({DateTime? expiresAt}) => PlaybackSource(
  id: 'source',
  providerId: PlaybackProviderId('cache-test'),
  episode: PlaybackEpisode(animeId: AnimeId('cache-anime'), episodeNumber: 1),
  language: 'unknown',
  quality: 'unknown',
  servers: [
    SourceCandidate(
      id: 'candidate',
      endpoint: Uri.https('media.example', '/episode.mp4'),
      expiresAt: expiresAt,
    ),
  ],
);
