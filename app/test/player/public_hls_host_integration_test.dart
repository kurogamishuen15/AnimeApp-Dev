import 'dart:io';

import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/video_track_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opt-in transport smoke for a public HLS fixture. This is not an anime
/// provider and must not be counted as an external episode integration.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Uri sample = Uri.https('test-streams.mux.dev', '/x36xhzz/x36xhzz.m3u8');
  final bool enabled = Platform.environment['KONGROO_TEST_PUBLIC_HLS'] == '1';

  test(
    'public HLS fixture resolves and advances in the existing libmpv engine',
    () async {
      final PlaybackEpisode episode = PlaybackEpisode(
        animeId: AnimeId('public-hls-fixture'),
        episodeNumber: 1,
        animeTitles: const ['Public HLS fixture'],
      );
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: [
          PlaybackProviderRegistration(
            provider: _FixtureProvider(sample),
            cacheTtl: Duration.zero,
          ),
        ],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(),
          ),
        ],
        clock: DateTime.now,
      );
      final PlaybackProviderResult<PlayableSource> result = await manager
          .resolveBestStream(
            episode,
            cancellation: PlaybackCancellationToken(),
          );
      expect(result, isA<PlaybackProviderSuccess<PlayableSource>>());
      final PlayableSource playable =
          (result as PlaybackProviderSuccess<PlayableSource>).value;
      expect(playable.format, PlaybackMediaFormat.hls);
      expect(playable.uri.host, 'test-streams.mux.dev');

      final MediaKitSpikeEngine engine = MediaKitSpikeEngine(
        trustedExternalSources: {playable.uri},
      );
      var initialized = false;
      try {
        await engine.initialize();
        initialized = true;
        final Future<PlaybackSpikeSnapshot> loaded = engine.snapshots
            .firstWhere(
              (PlaybackSpikeSnapshot state) =>
                  state.duration > Duration.zero || state.error != null,
            )
            .timeout(const Duration(seconds: 25));
        await engine.open(
          playable.uri,
          sourceGeneration: 1,
          httpHeaders: playable.httpHeaders,
        );
        final PlaybackSpikeSnapshot metadata = await loaded;
        expect(metadata.error, isNull);
        expect(metadata.duration, greaterThan(Duration.zero));

        await engine.play();
        final PlaybackSpikeSnapshot advanced = await engine.snapshots
            .firstWhere(
              (PlaybackSpikeSnapshot state) =>
                  state.position >= const Duration(seconds: 2) ||
                  state.error != null,
            )
            .timeout(const Duration(seconds: 30));
        expect(advanced.error, isNull);
        expect(
          advanced.position,
          greaterThanOrEqualTo(const Duration(seconds: 2)),
        );

        final List<VideoTrackInfo> videoTracks = advanced.videoTracks;
        expect(
          videoTracks.any(
            (VideoTrackInfo track) => track.codec?.isNotEmpty ?? false,
          ),
          isTrue,
          reason: 'The sample should expose a video track to libmpv.',
        );
        stdout.writeln(
          'public HLS fixture: host=${playable.uri.host} '
          'format=${playable.format.name} '
          'durationMs=${advanced.duration.inMilliseconds} '
          'positionMs=${advanced.position.inMilliseconds} '
          'videoTracks=${videoTracks.map((VideoTrackInfo track) => '${track.width}x${track.height}:${track.codec}').join(',')} '
          'visibleWindow=false animeEpisode=false',
        );
      } finally {
        try {
          if (initialized) await engine.stop();
        } finally {
          await engine.dispose();
        }
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(seconds: 75)),
  );
}

final class _FixtureProvider implements PlaybackSourceProvider {
  _FixtureProvider(this.endpoint);

  final Uri endpoint;

  @override
  PlaybackProviderId get id => PlaybackProviderId('public-hls-fixture');

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
  };

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );
    }
    return PlaybackProviderSuccess([
      PlaybackSource(
        id: 'public-hls-sample',
        providerId: id,
        episode: episode,
        language: 'und',
        quality: 'test fixture',
        servers: [
          SourceCandidate(
            id: 'mux-public-hls',
            hostId: DirectMediaHostResolver.stableHostId,
            endpoint: endpoint,
            provenance: 'public technical HLS fixture',
          ),
        ],
      ),
    ]);
  }
}
