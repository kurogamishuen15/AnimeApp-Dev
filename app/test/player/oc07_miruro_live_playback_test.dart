// OC-07 real-playback check: resolves Tokyo Ghoul:re episode 9 through the
// Miruro backend and plays it in the real engine (media_kit + libmpv) with the
// headers the backend declares. Verifies duration, audio, seek and position.
//
// Run from app/:
//   KONGROO_TEST_REAL_MIRURO=1 flutter test test/player/oc07_miruro_live_playback_test.dart
import 'dart:io';

import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_api.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_playback_provider.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/audio_track_info.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bool enabled =
      Platform.environment['KONGROO_TEST_REAL_MIRURO'] == '1';

  test(
    'Miruro backend plays Tokyo Ghoul:re 9 in libmpv with seek',
    () async {
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
          );
      final PlaybackCancellationToken cancellation =
          PlaybackCancellationToken();
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
        cancellation: cancellation,
      );
      expect(sources, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      final List<PlaybackSource> resolved =
          (sources as PlaybackProviderSuccess<List<PlaybackSource>>).value;
      final List<SourceCandidate> candidates = <SourceCandidate>[
        for (final PlaybackSource source in resolved) ...source.servers,
      ];
      expect(candidates, isNotEmpty);

      MediaKitSpikeEngine? engine;
      SourceCandidate? opened;
      Object? lastError;
      for (final SourceCandidate candidate in candidates) {
        final MediaKitSpikeEngine attempt = MediaKitSpikeEngine(
          trustedExternalSources: <Uri>{candidate.endpoint},
        );
        try {
          await attempt.initialize();
          await attempt.open(
            candidate.endpoint,
            httpHeaders: candidate.requestHeaders,
          );
          await _waitUntil(
            () => attempt.currentSnapshot.duration > Duration.zero,
            const Duration(seconds: 20),
          );
          engine = attempt;
          opened = candidate;
          break;
        } on Object catch (error) {
          lastError = error;
          await attempt.dispose();
        }
      }
      expect(engine, isNotNull, reason: 'no candidate opened: $lastError');
      final MediaKitSpikeEngine live = engine!;
      try {
        final PlaybackSpikeSnapshot opened0 = live.currentSnapshot;
        stdout.writeln(
          'OPENED server=${opened!.id} host=${opened.hostId} '
          'duration=${opened0.duration} audio=${opened0.audioTracks.length}',
        );
        expect(opened0.duration, greaterThan(const Duration(minutes: 5)));
        expect(opened0.audioTracks, isNotEmpty);

        await live.play();
        await _waitUntil(
          () => live.currentSnapshot.position > const Duration(seconds: 3),
          const Duration(seconds: 30),
        );
        final Duration advanced = live.currentSnapshot.position;
        stdout.writeln('PLAYING position=$advanced');
        expect(advanced, greaterThan(const Duration(seconds: 2)));

        await live.seek(const Duration(seconds: 40));
        await _waitUntil(
          () =>
              live.currentSnapshot.position >= const Duration(seconds: 30),
          const Duration(seconds: 20),
        );
        final Duration seeked = live.currentSnapshot.position;
        stdout.writeln('SEEK position=$seeked');
        expect(seeked, greaterThanOrEqualTo(const Duration(seconds: 30)));

        final PlaybackSpikeSnapshot after = live.currentSnapshot;
        expect(after.playing, isTrue);
        expect(after.audioTracks, isNotEmpty);
        stdout.writeln(
          'AUDIO tracks=${after.audioTracks.map((AudioTrackInfo t) => t.id).toList()}',
        );
      } finally {
        await live.dispose();
        client.close(force: true);
      }
    },
    skip: enabled ? false : 'set KONGROO_TEST_REAL_MIRURO=1 to run',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _waitUntil(
  bool Function() predicate,
  Duration limit,
) async {
  final DateTime deadline = DateTime.now().add(limit);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw StateError('Condition not met within $limit');
}
