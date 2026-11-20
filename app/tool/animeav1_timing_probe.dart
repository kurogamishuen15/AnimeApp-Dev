// Opt-in timing probe for the AnimeAV1 (VOE) and MegaPlay resolution chains.
//
// Usage (from app/): dart run tool/animeav1_timing_probe.dart [episode]
//
// Prints one line per stage with elapsed milliseconds so the slow part of the
// startup can be identified without guessing. It performs ordinary public
// requests only: two provider chains plus one host resolution each.
import 'dart:io';

import 'package:anime_app/data/player/providers/animeav1/animeav1_playback_provider.dart';
import 'package:anime_app/data/player/providers/hosts/voe_video_host_resolver.dart';
import 'package:anime_app/data/player/providers/megaplay/megaplay_playback_provider.dart';
import 'package:anime_app/data/player/providers/playback_providers_module.dart';
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
    await _animeAv1(client, episode);
    await _megaPlay(client, episode);
    await _manager(episode);
  } finally {
    client.close(force: true);
  }
}

/// Measures the exact production entry point: the picker waits for every
/// registered provider, so this number is what the user perceives.
Future<void> _manager(int number) async {
  final PlaybackProvidersModule module = PlaybackProvidersModule.open();
  final Stopwatch total = Stopwatch()..start();
  try {
    final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
        await module.manager.resolveCandidates(
          _episode(number),
          cancellation: PlaybackCancellationToken(),
        );
    total.stop();
    stdout.writeln('manager.resolveCandidates ${total.elapsedMilliseconds} ms');
    if (result case PlaybackProviderSuccess<List<ResolvedPlaybackStream>>(
      :final value,
    )) {
      stdout.writeln('manager.streams=${value.length}');
      for (final ResolvedPlaybackStream stream in value) {
        stdout.writeln(
          'manager.stream=${stream.providerId.value} server=${stream.serverId} '
          'fmt=${stream.format.name}',
        );
      }
    } else {
      stdout.writeln('manager.failed');
    }
    for (final diagnostic in module.manager.diagnostics) {
      stdout.writeln(
        'manager.diag=${diagnostic.id.value} '
        'last=${diagnostic.lastFailure?.name ?? 'none'}',
      );
    }
  } finally {
    module.close();
  }
}

AnimeIdentity _identity() => AnimeIdentity(
  localId: AnimeId('timing-probe'),
  externalIds: [
    ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: '100240'),
    ExternalAnimeId(
      providerId: MetadataProviderId('myanimelist'),
      value: '36511',
    ),
  ],
  titles: const ['Tokyo Ghoul:re'],
);

PlaybackEpisode _episode(int number) => PlaybackEpisode(
  animeId: AnimeId('timing-probe'),
  episodeNumber: number,
  externalAnimeIds: _identity().externalIds,
  animeTitles: _identity().titles,
);

Future<void> _animeAv1(Dio client, int number) async {
  final Stopwatch total = Stopwatch()..start();
  final AnimeAv1PlaybackProvider provider = AnimeAv1PlaybackProvider(client);
  final PlaybackCancellationToken cancellation = PlaybackCancellationToken();

  final Stopwatch search = Stopwatch()..start();
  await provider.searchAnime(_identity(), cancellation: cancellation);
  search.stop();
  stdout.writeln('animeav1.search ${search.elapsedMilliseconds} ms');

  final Stopwatch sources = Stopwatch()..start();
  final PlaybackProviderResult<List<PlaybackSource>> result = await provider
      .findSources(_episode(number), cancellation: cancellation);
  sources.stop();
  stdout.writeln('animeav1.findSources ${sources.elapsedMilliseconds} ms');

  if (result case PlaybackProviderSuccess<List<PlaybackSource>>(:final value)) {
    stdout.writeln('animeav1.sources=${value.length}');
    final PlaybackSource source = value.first;
    final SourceCandidate candidate = source.servers.first;
    final Stopwatch resolve = Stopwatch()..start();
    final PlaybackProviderResult<PlayableSource> resolved =
        await VoeVideoHostResolver(client)
            .resolve(source, candidate, cancellation: cancellation);
    resolve.stop();
    stdout.writeln('animeav1.voe ${resolve.elapsedMilliseconds} ms');
    if (resolved case PlaybackProviderSuccess<PlayableSource>(:final value)) {
      stdout.writeln('animeav1.voe.uri=${value.uri.host}');
    } else {
      stdout.writeln('animeav1.voe.failed');
    }
  } else {
    stdout.writeln('animeav1.findSources.failed');
  }
  total.stop();
  stdout.writeln('animeav1.total ${total.elapsedMilliseconds} ms');
}

Future<void> _megaPlay(Dio client, int number) async {
  final Stopwatch total = Stopwatch()..start();
  final MegaPlayPlaybackProvider provider = MegaPlayPlaybackProvider(client);
  final PlaybackCancellationToken cancellation = PlaybackCancellationToken();

  final Stopwatch search = Stopwatch()..start();
  await provider.searchAnime(_identity(), cancellation: cancellation);
  search.stop();
  stdout.writeln('megaplay.search ${search.elapsedMilliseconds} ms');

  final Stopwatch sources = Stopwatch()..start();
  final PlaybackProviderResult<List<PlaybackSource>> result = await provider
      .findSources(_episode(number), cancellation: cancellation);
  sources.stop();
  stdout.writeln('megaplay.findSources ${sources.elapsedMilliseconds} ms');
  if (result case PlaybackProviderSuccess<List<PlaybackSource>>(:final value)) {
    stdout.writeln('megaplay.sources=${value.length}');
    final SourceCandidate candidate = value.first.servers.first;
    stdout.writeln(
      'megaplay.first=${candidate.hostId} kind=${candidate.kind.name}',
    );
  } else {
    stdout.writeln('megaplay.findSources.failed');
  }
  total.stop();
  stdout.writeln('megaplay.total ${total.elapsedMilliseconds} ms');
}
