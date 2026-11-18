// Live N2 check for the AllAnime provider (run: dart run, from app/).
// Requests the public API exactly as the adapter does and prints the
// resolved PlaybackSources. No playback engine is started.
import 'dart:io';

import 'package:anime_app/data/player/providers/allanime/allanime_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

Future<T> _guard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on Object catch (error, stack) {
    stderr.writeln('UNCAUGHT $error');
    stderr.writeln(stack.toString().split('\n').take(12).join('\n'));
    rethrow;
  }
}

Future<void> main(List<String> args) async {
  final int anilistId = args.isNotEmpty ? int.tryParse(args[0]) ?? 100240 : 100240;
  final int episode = args.length > 1 ? int.tryParse(args[1]) ?? 9 : 9;
  final String? malId = args.length > 2 ? args[2] : null;
  final Dio client = Dio();
  try {
    final provider = AllAnimePlaybackProvider(client);
    final identity = AnimeIdentity(
      localId: AnimeId('live-check'),
      externalIds: [
        ExternalAnimeId(
          providerId: MetadataProviderId('anilist'),
          value: '$anilistId',
        ),
        if (malId != null)
          ExternalAnimeId(
            providerId: MetadataProviderId('myanimelist'),
            value: malId,
          ),
      ],
      titles: const ['Tokyo Ghoul:re'],
    );
    final search = await provider.searchAnime(
      identity,
      cancellation: PlaybackCancellationToken(),
    );
    switch (search) {
      case PlaybackProviderSuccess<List<dynamic>>(:final value):
        stdout.writeln('SEARCH=${value.length} first=${value.first}');
      case PlaybackProviderFailed<List<dynamic>>(:final failure):
        stdout.writeln(
          'SEARCH FAILED kind=${failure.kind} status=${failure.httpStatus} '
          'host=${failure.host} stage=${failure.stage}',
        );
      case PlaybackProviderEmpty<List<dynamic>>():
        stdout.writeln('SEARCH EMPTY');
      case PlaybackProviderUnsupported<List<dynamic>>(:final capability):
        stdout.writeln('SEARCH UNSUPPORTED $capability');
    }
    final result = await _guard(
      () => provider.findSources(
        PlaybackEpisode(
          animeId: AnimeId('live-check'),
          episodeNumber: episode,
          externalAnimeIds: [
            ExternalAnimeId(
              providerId: MetadataProviderId('anilist'),
              value: '$anilistId',
            ),
            if (malId != null)
              ExternalAnimeId(
                providerId: MetadataProviderId('myanimelist'),
                value: malId,
              ),
          ],
          animeTitles: const ['Tokyo Ghoul:re'],
        ),
        cancellation: PlaybackCancellationToken(),
      ),
    );
    switch (result) {
      case PlaybackProviderSuccess<List<PlaybackSource>>(:final value):
        stdout.writeln('SOURCES=${value.length}');
        for (final PlaybackSource source in value) {
          stdout.writeln(
            'source=${source.id} lang=${source.language} '
            'display=${source.displayName} servers=${source.servers.length}',
          );
          for (final SourceCandidate server in source.servers) {
            stdout.writeln(
              '  server=${server.id} fmt=${server.mediaFormat.name} '
              'quality=${server.quality} uri=${server.endpoint}',
            );
          }
        }
      case PlaybackProviderFailed<List<PlaybackSource>>(:final failure):
        stdout.writeln('FAILED kind=${failure.kind} status=${failure.httpStatus}');
      case PlaybackProviderEmpty<List<PlaybackSource>>():
        stdout.writeln('EMPTY');
      case PlaybackProviderUnsupported<List<PlaybackSource>>(:final capability):
        stdout.writeln('UNSUPPORTED $capability');
    }
  } finally {
    client.close(force: true);
  }
}
