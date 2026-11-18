// Quick N2 timing probe for the AnimeGG provider (run: dart run, from app/).
import 'dart:io';

import 'package:anime_app/data/player/providers/animegg/animegg_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  for (int round = 1; round <= 3; round++) {
    final Stopwatch total = Stopwatch()..start();
    final Dio client = Dio();
    try {
      final provider = AnimeGgPlaybackProvider(client);
      final result = await provider.findSources(
        PlaybackEpisode(
          animeId: AnimeId('probe'),
          episodeNumber: 9,
          externalAnimeIds: [
            ExternalAnimeId(
              providerId: MetadataProviderId('anilist'),
              value: '100240',
            ),
          ],
          animeTitles: const ['Tokyo Ghoul:re'],
        ),
        cancellation: PlaybackCancellationToken(),
      );
      final Duration elapsed = total.elapsed;
      switch (result) {
        case PlaybackProviderSuccess<List<PlaybackSource>>(:final value):
          stdout.writeln(
            'round=$round OK ${elapsed.inMilliseconds}ms servers='
            '${value.single.servers.length} '
            '${value.single.servers.map((s) => s.endpoint.host).join('|')}',
          );
        case PlaybackProviderFailed<List<PlaybackSource>>(:final failure):
          stdout.writeln(
            'round=$round FAILED ${elapsed.inMilliseconds}ms '
            'kind=${failure.kind} stage=${failure.stage}',
          );
        default:
          stdout.writeln('round=$round EMPTY ${elapsed.inMilliseconds}ms');
      }
    } finally {
      client.close(force: true);
    }
  }
}
