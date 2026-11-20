import 'dart:async';
import 'dart:io';

import 'package:anime_app/app/player/spike_player_module.dart';
import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:material_ui/material_ui.dart';

/// Opt-in visual smoke runner for the reviewed Commons movie. Uses the product
/// composition, resolver and player module without taking a user URL.
Future<void> main() async {
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
  final providers = PlaybackProvidersModule.open(enableWikimedia: true);
  try {
    final episode = PlaybackEpisode(
      animeId: AnimeId('commons-visual-smoke'),
      episodeNumber: 1,
      externalAnimeId: ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '6654',
      ),
    );
    final result = await providers.manager.resolveCandidates(
      episode,
      cancellation: PlaybackCancellationToken(),
    );
    if (result case PlaybackProviderFailed(:final failure)) {
      stderr.writeln(
        'Discovery failed: ${failure.kind.name} ${failure.httpStatus}',
      );
      throw StateError('Commons discovery failed.');
    }
    final List<ResolvedPlaybackStream> streams =
        (result as PlaybackProviderSuccess<List<ResolvedPlaybackStream>>).value;
    final ResolvedPlaybackStream source = streams.firstWhere(
      (stream) => stream.serverId.contains('480p'),
    );
    stdout.writeln('Resolved Wikimedia 480p');
    final module = await SpikePlayerModule.open(
      null,
      sourceProviderManager: providers.manager,
      sourceEpisode: episode,
      initialResolvedSource: source,
      trustedExternalSources: {for (final stream in streams) stream.uri},
      authorizedAlternatives: streams,
    );
    display.value = module.build();
    try {
      final player = module.coordinator;
      await player.restoreStartPosition(
        const Duration(seconds: 20),
        cancellation: PlaybackCancellationToken(),
      );
      stdout.writeln(
        'Seek confirmed: ${player.state.observedPosition.inMilliseconds} ms',
      );
      await player.play();
      await module.engine.videoController.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 15),
      );
      stdout.writeln('Remote frame rendered');
      final advanced = await player.states
          .firstWhere(
            (state) =>
                state.observedPosition > const Duration(seconds: 22) ||
                state.error != null,
          )
          .timeout(const Duration(seconds: 15));
      if (advanced.error != null) throw StateError('Remote playback failed.');
      stdout.writeln(
        'Remote playback advanced: ${advanced.observedPosition.inMilliseconds} ms '
        'duration=${advanced.duration.inMilliseconds} ms',
      );
      await Future<void>.delayed(const Duration(seconds: 12));
      await player.stop();
      final resumed = player.states
          .firstWhere(
            (state) =>
                state.observedPosition > const Duration(milliseconds: 250) ||
                state.error != null,
          )
          .timeout(const Duration(seconds: 15));
      await player.play();
      final reopened = await resumed;
      if (reopened.error != null) throw StateError('Remote reopen failed.');
      stdout.writeln(
        'Remote source reopened: ${reopened.observedPosition.inMilliseconds} ms',
      );
      await Future<void>.delayed(const Duration(seconds: 8));
    } finally {
      await module.close();
    }
  } on Object catch (error) {
    stderr.writeln('Commons playback smoke failed: ${error.runtimeType}');
    exitCode = 1;
  } finally {
    providers.close();
  }
  exit(exitCode);
}
