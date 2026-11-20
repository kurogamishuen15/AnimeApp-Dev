// OC-07 acceptance (f): with the Miruro backend down, the manager keeps working
// and resolves the episode through another provider instead of blocking.
import 'dart:io';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_api.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_playback_provider.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_http2_client.dart';
import 'package:anime_app/data/player/providers/mock/mock_playback_provider.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a dead Miruro backend does not block the manager or the other provider',
    () async {
      final Dio client = Dio();
      addTearDown(() => client.close(force: true));
      final MiruroCatalogPlaybackProvider miruro =
          MiruroCatalogPlaybackProvider(
            MiruroCatalogApi(
              PublicPlaybackHttp(
                client,
                miruroCatalogOrigins.toSet(),
                enforceCooldown: false,
                maxConcurrent: 2,
              ),
              transport: _DownTransport(),
            ),
          );
      final MockPlaybackProvider fallback = MockPlaybackProvider(
        id: PlaybackProviderId('local-fallback'),
      );
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: <PlaybackProviderRegistration>[
          PlaybackProviderRegistration(provider: miruro, priority: 100),
          PlaybackProviderRegistration(provider: fallback, priority: 10),
        ],
        videoHostResolvers: <PlaybackVideoHostResolverRegistration>[
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(),
          ),
          PlaybackVideoHostResolverRegistration(resolver: fallback),
        ],
        clock: DateTime.now,
      );

      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await manager.resolveCandidates(
            PlaybackEpisode(
              animeId: AnimeId('oc07-failover'),
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

      expect(
        result,
        isA<PlaybackProviderSuccess<List<ResolvedPlaybackStream>>>(),
        reason: 'the manager must survive the backend outage',
      );
      final List<ResolvedPlaybackStream> streams =
          (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>).value;
      expect(streams, isNotEmpty);
      expect(
        streams.every(
          (ResolvedPlaybackStream stream) =>
              stream.providerId != PlaybackProviderId('miruro-catalog'),
        ),
        isTrue,
        reason: 'no stream may come from the dead backend',
      );
      expect(
        manager.diagnostics.any(
          (PlaybackProviderDiagnostic entry) =>
              entry.id == PlaybackProviderId('miruro-catalog') &&
              entry.lastFailure != null,
        ),
        isTrue,
        reason: 'the dead backend must be recorded, not hidden',
      );
    },
  );
}

/// Simulates a backend that is down: every catalog request fails before a
/// connection is established.
final class _DownTransport implements MiruroCatalogTransport {
  @override
  Future<MiruroHttp2Response> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
    required int maxBytes,
  }) async {
    throw const SocketException('backend down (simulated)');
  }
}
