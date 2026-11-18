// Live N2 check for the AniZone provider (run: dart run, from app/).
// Searches the public site and prints the resolved HLS candidates for the
// requested episode. No playback engine is started.
import 'dart:io';

import 'package:anime_app/data/player/providers/anizone/anizone_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

Future<void> main(List<String> args) async {
  final int episode = args.isNotEmpty ? int.tryParse(args[0]) ?? 9 : 9;
  final Dio client = Dio();
  try {
    final provider = AniZonePlaybackProvider(client);
    final identity = AnimeIdentity(
      localId: AnimeId('live-check'),
      externalIds: [
        ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '100240'),
      ],
      titles: const ['Tokyo Ghoul:re'],
    );
    final search = await provider.searchAnime(
      identity,
      cancellation: PlaybackCancellationToken(),
    );
    switch (search) {
      case PlaybackProviderSuccess<List<dynamic>>(:final value):
        stdout.writeln('SEARCH=${value.length}');
      case PlaybackProviderFailed<List<dynamic>>(:final failure):
        stdout.writeln(
          'SEARCH FAILED kind=${failure.kind} status=${failure.httpStatus}',
        );
      case PlaybackProviderEmpty<List<dynamic>>():
        stdout.writeln('SEARCH EMPTY');
      case PlaybackProviderUnsupported<List<dynamic>>(:final capability):
        stdout.writeln('SEARCH UNSUPPORTED $capability');
    }
    final result = await provider.findSources(
      PlaybackEpisode(
        animeId: AnimeId('live-check'),
        episodeNumber: episode,
        externalAnimeIds: identity.externalIds,
        animeTitles: identity.titles,
      ),
      cancellation: PlaybackCancellationToken(),
    );
    switch (result) {
      case PlaybackProviderSuccess<List<PlaybackSource>>(:final value):
        stdout.writeln('SOURCES=${value.length}');
        for (final PlaybackSource source in value) {
          stdout.writeln(
            'source=${source.id} display=${source.displayName} '
            'subs=${source.subtitles.length}',
          );
          for (final SourceCandidate server in source.servers) {
            stdout.writeln(
              '  server=${server.id} fmt=${server.mediaFormat.name} '
              'uri=${server.endpoint}',
            );
          }
        }
      case PlaybackProviderFailed<List<PlaybackSource>>(:final failure):
        stdout.writeln(
          'FAILED kind=${failure.kind} status=${failure.httpStatus} '
          'stage=${failure.stage}',
        );
      case PlaybackProviderEmpty<List<PlaybackSource>>():
        stdout.writeln('EMPTY');
      case PlaybackProviderUnsupported<List<PlaybackSource>>(:final capability):
        stdout.writeln('UNSUPPORTED $capability');
    }
  } finally {
    client.close(force: true);
  }
}
