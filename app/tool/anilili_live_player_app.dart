import 'dart:async';
import 'dart:io';

import 'package:anime_app/app/player/spike_player_module.dart';
import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:material_ui/material_ui.dart';

/// Opt-in live engine verification for the Anilili-derived providers.
///
/// Usage (entrypoint target): with arguments
/// `providerId|-, anilistId, malId|-, episode, holdSeconds`.
/// Resolves candidates through the real product composition (manager +
/// resolvers), picks the first stream whose provider matches, and plays it
/// with the production media_kit engine: seek, first frame, position advance,
/// stop, reopen, automatic close. Prints every gate to stdout.
Future<void> main(List<String> args) async {
  if (args.length < 4) {
    stderr.writeln(
      'usage: anilili_live_player_app <providerId|-> <anilistId> <malId|-> '
      '<episode> [holdSeconds]',
    );
    exit(64);
  }
  final String providerFilter = args[0].trim().toLowerCase();
  final String anilistId = args[1].trim();
  final String malArg = args[2].trim();
  final int episode = int.tryParse(args[3].trim()) ?? 0;
  final int holdSeconds = args.length > 4
      ? int.tryParse(args[4].trim()) ?? 10
      : 10;
  final String title = args.length > 5 ? args[5].trim() : 'Tokyo Ghoul:re';
  if (anilistId.isEmpty || episode < 1 || title.isEmpty) {
    stderr.writeln('invalid anilist id, episode, or title');
    exit(64);
  }

  WidgetsFlutterBinding.ensureInitialized();
  final display = ValueNotifier<Widget>(
    const Scaffold(body: Center(child: CircularProgressIndicator())),
  );
  runApp(
    MaterialApp(
      home: ValueListenableBuilder(
        valueListenable: display,
        builder: (context, child, _) => child,
      ),
    ),
  );
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  final providers = PlaybackProvidersModule.open();
  try {
    final episode_ = PlaybackEpisode(
      animeId: AnimeId('anilili-live-$anilistId'),
      episodeNumber: episode,
      externalAnimeIds: [
        ExternalAnimeId(providerId: MetadataProviderId('anilist'), value: anilistId),
        if (malArg.isNotEmpty && malArg != '-')
          ExternalAnimeId(providerId: MetadataProviderId('myanimelist'), value: malArg),
      ],
      animeTitles: [title],
    );
    final result = await providers.manager.resolveCandidates(
      episode_,
      cancellation: PlaybackCancellationToken(),
    );
    if (result case PlaybackProviderFailed(:final failure)) {
      stderr.writeln(
        'Discovery failed: ${failure.kind.name} '
        '${failure.httpStatus ?? ''} ${failure.stage?.name ?? ''}',
      );
      throw StateError('Discovery failed.');
    }
    final List<ResolvedPlaybackStream> streams =
        (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>).value;
    stdout.writeln(
      'RESOLVED ${streams.length} stream(s): '
      '${streams.map((s) => s.providerId.value).join(', ')}',
    );
    for (final diagnostic in providers.manager.diagnostics) {
      stdout.writeln(
        'DIAG provider=${diagnostic.id.value} '
        'circuit=${diagnostic.circuit.name} '
        'failures=${diagnostic.consecutiveFailures} '
        'last=${diagnostic.lastFailure?.name ?? 'none'}',
      );
    }
    final ResolvedPlaybackStream source = providerFilter == '-'
        ? streams.first
        : streams.firstWhere((stream) => stream.providerId.value == providerFilter);
    stdout.writeln(
      'PLAY provider=${source.providerId.value} server=${source.serverId} '
      'fmt=${source.format.name} uri=${source.uri}',
    );
    final module = await SpikePlayerModule.open(
      null,
      sourceProviderManager: providers.manager,
      sourceEpisode: episode_,
      initialResolvedSource: source,
      trustedExternalSources: {for (final stream in streams) stream.uri},
      authorizedAlternatives: streams,
    );
    display.value = module.build();
    try {
      final player = module.coordinator;
      final String? seekEnv = Platform.environment['KONGROO_LIVE_SEEK'];
      final int seekSeconds = seekEnv == null || seekEnv.trim().isEmpty
          ? 0
          : int.tryParse(seekEnv.trim()) ?? 0;
      if (seekSeconds > 0) {
        await player.restoreStartPosition(
          Duration(seconds: seekSeconds),
          cancellation: PlaybackCancellationToken(),
        );
        stdout.writeln(
          'SEEK-RESTORE confirmed: ${player.state.observedPosition.inMilliseconds} ms',
        );
      }
      await player.play();
      await module.engine.videoController.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 20),
      );
      stdout.writeln('FRAME first remote frame rendered');
      final advanced = await player.states
          .firstWhere(
            (state) =>
                state.observedPosition > const Duration(seconds: 2) ||
                state.error != null,
          )
          .timeout(const Duration(seconds: 20));
      if (advanced.error != null) throw StateError('Playback failed.');
      stdout.writeln(
        'ADVANCE position=${advanced.observedPosition.inMilliseconds} ms '
        'duration=${advanced.duration.inMilliseconds} ms',
      );
      if (seekSeconds > 0) {
        // The pre-play restore already parked the stream at the seek point.
        stdout.writeln('SEEK already applied before playback');
      } else {
        await player.seek(const Duration(seconds: 20));
        final seeked = await player.states
            .firstWhere(
              (state) =>
                  (state.observedPosition >= const Duration(seconds: 19) &&
                      state.observedPosition != advanced.observedPosition) ||
                  state.error != null,
            )
            .timeout(const Duration(seconds: 20));
        if (seeked.error != null) throw StateError('Seek failed.');
        stdout.writeln(
          'SEEK-IN-PLAY confirmed: ${seeked.observedPosition.inMilliseconds} ms',
        );
      }
      await Future<void>.delayed(const Duration(seconds: 5));
      final String? shot = Platform.environment['KONGROO_LIVE_SHOT'];
      if (shot != null && shot.trim().isNotEmpty) {
        try {
          final ProcessResult result = await Process.run('spectacle', [
            '-b',
            '-n',
            '-o',
            shot.trim(),
          ]);
          stdout.writeln('SHOT exit=${result.exitCode} path=${shot.trim()}');
        } on Object {
          stdout.writeln('SHOT unavailable');
        }
      }
      await Future<void>.delayed(Duration(seconds: holdSeconds - 5));
      await player.stop();
      // Stop parks the observed position at zero; resume first, then wait for
      // the reopened stream to actually advance.
      await player.play();
      final reopened = await player.states
          .firstWhere(
            (state) =>
                state.observedPosition > const Duration(milliseconds: 250) ||
                state.error != null,
          )
          .timeout(const Duration(seconds: 20));
      if (reopened.error != null) throw StateError('Reopen failed.');
      stdout.writeln(
        'REOPEN position=${reopened.observedPosition.inMilliseconds} ms',
      );
      await Future<void>.delayed(const Duration(seconds: 5));
      stdout.writeln('LIVE-ENGINE-OK provider=${source.providerId.value}');
    } finally {
      await module.close();
    }
  } on Object catch (error) {
    stderr.writeln('Live engine check failed: ${error.runtimeType}: $error');
    exitCode = 1;
  } finally {
    providers.close();
  }
  exit(exitCode);
}
