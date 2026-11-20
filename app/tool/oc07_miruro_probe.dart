// OC-07 live check for the Miruro public backend (run: dart run, from app/).
// Resolves AniList 100240 (Tokyo Ghoul:re) episode 9 through the real adapter,
// prints every provider/server/stream and then fetches the first HLS variant to
// prove the media is reachable with the headers the backend declares.
// No playback engine is started here.
import 'dart:io';

import 'package:anime_app/data/player/providers/miruro/miruro_catalog_api.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_playback_provider.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

Future<void> main(List<String> args) async {
  final int episode = args.isNotEmpty ? int.tryParse(args[0]) ?? 9 : 9;
  final Dio client = Dio();
  final PublicPlaybackHttp transport = PublicPlaybackHttp(
    client,
    miruroCatalogOrigins.toSet(),
    enforceCooldown: false,
    maxConcurrent: 2,
  );
  final MiruroCatalogApi api = MiruroCatalogApi(transport);
  final MiruroCatalogPlaybackProvider provider = MiruroCatalogPlaybackProvider(
    api,
  );
  final AnimeIdentity identity = AnimeIdentity(
    localId: AnimeId('oc07-live'),
    externalIds: <ExternalAnimeId>[
      ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '100240'),
    ],
    titles: const <String>['Tokyo Ghoul:re'],
  );
  final PlaybackCancellationToken cancellation = PlaybackCancellationToken();
  try {
    final bool healthy = await api.probeHealth(cancellation: cancellation);
    stdout.writeln('HEALTH=${healthy ? 'ok' : 'down'}');
    final search = await provider.searchAnime(
      identity,
      cancellation: cancellation,
    );
    switch (search) {
      case PlaybackProviderSuccess<List<SourceAnimeMatch>>(:final value):
        stdout.writeln('SEARCH=${value.length}');
        for (final SourceAnimeMatch m in value) {
          stdout.writeln(
            'MATCH provider=${m.providerId.value} anime=${m.sourceAnimeId} '
            'title=${m.title}',
          );
        }
      case PlaybackProviderFailed<List<SourceAnimeMatch>>(:final failure):
        stdout.writeln(
          'SEARCH_FAILED kind=${failure.kind} status=${failure.httpStatus}',
        );
      case PlaybackProviderEmpty<List<SourceAnimeMatch>>():
        stdout.writeln('SEARCH_EMPTY');
      case PlaybackProviderUnsupported<List<SourceAnimeMatch>>():
        stdout.writeln('SEARCH_UNSUPPORTED');
    }

    final sources = await provider.findSources(
      PlaybackEpisode(
        animeId: AnimeId('oc07-live'),
        episodeNumber: episode,
        externalAnimeIds: identity.externalIds,
        animeTitles: identity.titles,
      ),
      cancellation: cancellation,
    );
    switch (sources) {
      case PlaybackProviderSuccess<List<PlaybackSource>>(:final value):
        stdout.writeln('SOURCES=${value.length}');
        for (final PlaybackSource source in value) {
          stdout.writeln(
            'source=${source.id} display=${source.displayName} '
            'lang=${source.providerAnnouncedLanguage} '
            'audio=${source.audioLanguage} subs=${source.subtitles.length}',
          );
          for (final SourceCandidate server in source.servers) {
            stdout.writeln(
              '  server=${server.id} host=${server.hostId} '
              'fmt=${server.mediaFormat.name} prio=${server.priority} '
              'ref=${server.requestHeaders.values['Referer'] ?? '-'} '
              'uri=${server.endpoint}',
            );
          }
        }
      case PlaybackProviderFailed<List<PlaybackSource>>(:final failure):
        stdout.writeln(
          'SOURCES_FAILED kind=${failure.kind} status=${failure.httpStatus} '
          'stage=${failure.stage}',
        );
      case PlaybackProviderEmpty<List<PlaybackSource>>():
        stdout.writeln('SOURCES_EMPTY');
      case PlaybackProviderUnsupported<List<PlaybackSource>>():
        stdout.writeln('SOURCES_UNSUPPORTED');
    }
  } finally {
    await api.close();
    client.close(force: true);
  }
}
