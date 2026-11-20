// OC-07 real-playback check through the loopback proxy: resolves
// Tokyo Ghoul:re episode 9 through the Miruro backend, publishes every stream as
// http://127.0.0.1:<port>/media/<id>, and plays it in libmpv. Proves the player
// never holds a backend CDN URL and that seek still works through the proxy.
//
// Run from app/:
//   KONGROO_TEST_REAL_MIRURO_PROXY=1 flutter test test/player/oc07_miruro_proxy_playback_test.dart
import 'dart:io';

import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_api.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_parser.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_playback_provider.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_media_proxy.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding installs a mock HttpClient that answers 400 to every
  // request. The proxy must reach the real CDN, so the override is removed for
  // this live check only; offline suites keep the mock.
  HttpOverrides.global = null;
  final bool enabled =
      Platform.environment['KONGROO_TEST_REAL_MIRURO_PROXY'] == '1';

  test(
    'Miruro backend plays through the loopback proxy in libmpv with seek',
    () async {
      final MiruroMediaProxy proxy = await MiruroMediaProxy.start();
      final Dio client = Dio();
      final MiruroCatalogPlaybackProvider provider =
          MiruroCatalogPlaybackProvider(
            MiruroCatalogApi(
              PublicPlaybackHttp(
                client,
                miruroCatalogOrigins.toSet(),
                enforceCooldown: false,
                maxConcurrent: 2,
              ),
            ),
            parser: MiruroCatalogParser(proxy: proxy),
          );
      try {
        final sources = await provider.findSources(
          PlaybackEpisode(
            animeId: AnimeId('oc07-live'),
            episodeNumber: 9,
            externalAnimeIds: <ExternalAnimeId>[
              ExternalAnimeId(
                providerId: MetadataProviderId('anilist'),
                value: '100240',
              ),
            ],
            animeTitles: const <String>['Tokyo Ghoul:re'],
          ),
          cancellation: PlaybackCancellationToken(),
        );
        expect(sources, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
        final List<SourceCandidate> candidates = <SourceCandidate>[
          for (final PlaybackSource source
              in (sources as PlaybackProviderSuccess<List<PlaybackSource>>)
                  .value)
            ...source.servers,
        ];
        expect(candidates, isNotEmpty);
        // Try the HLS servers that answered on 2026-11-20 first; the proxy test
        // is about the loopback path, not about which CDN is up today.
        candidates.sort((SourceCandidate a, SourceCandidate b) {
          int rank(SourceCandidate c) => c.id.startsWith('anikoto') ? 0 : 1;
          return rank(a).compareTo(rank(b));
        });
        // Every published endpoint is loopback, and none carries context
        // headers: the proxy owns them now.
        for (final SourceCandidate candidate in candidates.take(6)) {
          expect(candidate.endpoint.host, '127.0.0.1');
          expect(candidate.endpoint.port, isNot(443));
          expect(candidate.requestHeaders.values, isEmpty);
        }
        stdout.writeln(
          'PUBLISHED origin=${proxy.origin} servers=${candidates.length} '
          'first=${candidates.first.endpoint}',
        );

        MediaKitSpikeEngine? engine;
        SourceCandidate? opened;
        Object? lastError;
        for (final SourceCandidate candidate in candidates.take(6)) {
          final MediaKitSpikeEngine attempt = MediaKitSpikeEngine(
            trustedExternalSources: <Uri>{candidate.endpoint},
          );
          try {
            stdout.writeln('TRY_PROXIED server=${candidate.id}');
            await attempt.initialize();
            await attempt.open(candidate.endpoint);
            await _waitUntil(
              () => attempt.currentSnapshot.duration > Duration.zero,
              const Duration(seconds: 20),
            );
            engine = attempt;
            opened = candidate;
            break;
          } on Object catch (error) {
            lastError = error;
            stdout.writeln('TRY_PROXIED_FAILED server=${candidate.id} $error');
            await attempt.dispose();
          }
        }
        expect(engine, isNotNull, reason: 'no candidate opened: $lastError');
        final MediaKitSpikeEngine live = engine!;
        try {
          final PlaybackSpikeSnapshot started = live.currentSnapshot;
          stdout.writeln(
            'OPENED_PROXIED server=${opened!.id} duration=${started.duration} '
            'audio=${started.audioTracks.length}',
          );
          expect(started.duration, greaterThan(const Duration(minutes: 5)));
          expect(started.audioTracks, isNotEmpty);

          await live.play();
          await _waitUntil(
            () => live.currentSnapshot.position > const Duration(seconds: 3),
            const Duration(seconds: 30),
          );
          stdout.writeln('PLAYING_PROXIED position=${live.currentSnapshot.position}');

          await live.seek(const Duration(seconds: 40));
          await _waitUntil(
            () => live.currentSnapshot.position >= const Duration(seconds: 30),
            const Duration(seconds: 20),
          );
          stdout.writeln('SEEK_PROXIED position=${live.currentSnapshot.position}');
          expect(
            live.currentSnapshot.position,
            greaterThanOrEqualTo(const Duration(seconds: 30)),
          );
        } finally {
          await live.dispose();
        }
      } finally {
        await proxy.close();
        client.close(force: true);
      }
    },
    skip: enabled ? false : 'set KONGROO_TEST_REAL_MIRURO_PROXY=1 to run',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _waitUntil(bool Function() predicate, Duration limit) async {
  final DateTime deadline = DateTime.now().add(limit);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw StateError('Condition not met within $limit');
}
