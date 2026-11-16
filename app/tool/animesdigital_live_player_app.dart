import 'dart:async';
import 'dart:io';

import 'package:anime_app/app/player/media_kit_video_surface.dart';
import 'package:anime_app/app/player/player_video_display.dart';
import 'package:anime_app/app/player/player_window_controller.dart';
import 'package:anime_app/app/player/spike_player_page.dart';
import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/application/player/spike_player_coordinator.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/data/player/providers/animesdigital/animesdigital_playback_provider.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the existing player page from a live source. This diagnostic mounts
/// the existing engine/UI before starting the network open, so native state
/// remains observable even if `Player.open` never completes.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String rawEpisode =
      Platform.environment['KONGROO_LIVE_PLAYER_EPISODE'] ?? '1180';
  final int episodeNumber = int.tryParse(rawEpisode) ?? 0;
  if (episodeNumber < 1) {
    stderr.writeln('KONGROO_LIVE_PLAYER_EPISODE must be a positive integer.');
    exitCode = 64;
    return;
  }

  final AnimesDigitalPlaybackProvider provider =
      AnimesDigitalPlaybackProvider();
  final PlaybackProviderManager manager = PlaybackProviderManager(
    providers: <PlaybackProviderRegistration>[
      PlaybackProviderRegistration(
        provider: provider,
        priority: 100,
        cacheTtl: Duration.zero,
        version: provider.adapterVersion,
      ),
    ],
    videoHostResolvers: <PlaybackVideoHostResolverRegistration>[
      PlaybackVideoHostResolverRegistration(
        resolver: DirectMediaHostResolver(),
        version: '1.0.0',
      ),
    ],
    clock: DateTime.now,
  );
  final PlaybackEpisode episode = PlaybackEpisode(
    animeId: AnimeId('animesdigital-live-one-piece'),
    episodeNumber: episodeNumber,
    animeTitles: const <String>['One Piece'],
  );
  final PlaybackProviderResult<PlayableSource> result = await manager
      .resolveBestStream(episode, cancellation: PlaybackCancellationToken());
  if (result is! PlaybackProviderSuccess<PlayableSource>) {
    final String kind = result is PlaybackProviderFailed<PlayableSource>
        ? result.failure.kind.name
        : result.runtimeType.toString();
    stderr.writeln('source_resolution=failed kind=$kind');
    provider.close();
    exitCode = 1;
    return;
  }

  final PlayableSource source = result.value;
  final MediaKitSpikeEngine engine = MediaKitSpikeEngine(
    trustedExternalSources: <Uri>{source.uri},
  );
  engine.attachVideoSurface();
  final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(
    engine,
    trustedExternalSources: <Uri>{source.uri},
  );
  final GtkPlayerWindowController windowController =
      GtkPlayerWindowController();
  final PlayerVideoDisplayController display = PlayerVideoDisplayController();
  try {
    await coordinator.initialize();
  } on Object catch (error) {
    await coordinator.dispose();
    provider.close();
    stderr.writeln('player_initialize=failed error_type=${error.runtimeType}');
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'source_resolution=ok provider=animesdigital episode=$episodeNumber '
    'host=${source.uri.host} format=${source.format.name} '
    'media_url_redacted=true',
  );
  await stdout.flush();
  PlaybackSessionSnapshot? lastState;
  int lastPositionBucket = -1;
  // The app state owns and cancels this subscription from dispose().
  // ignore: cancel_subscriptions
  final stateSubscription = coordinator.states.listen((
    PlaybackSessionSnapshot state,
  ) {
    final PlaybackSessionSnapshot? previous = lastState;
    final int positionBucket = state.position.inSeconds ~/ 5;
    if (previous != null &&
        previous.status == state.status &&
        previous.buffering == state.buffering &&
        previous.duration == state.duration &&
        previous.videoTracks.length == state.videoTracks.length &&
        previous.playback.audioTracks.length ==
            state.playback.audioTracks.length &&
        (previous.error == null) == (state.error == null) &&
        lastPositionBucket == positionBucket) {
      return;
    }
    lastState = state;
    lastPositionBucket = positionBucket;
    stdout.writeln(
      'native_state status=${state.status.name} '
      'buffering=${state.buffering} '
      'durationMs=${state.duration.inMilliseconds} '
      'positionMs=${state.position.inMilliseconds} '
      'videoTracks=${state.videoTracks.map((track) => '${track.width}x${track.height}:${track.codec}').join(',')} '
      'audioTracks=${state.playback.audioTracks.length} '
      'error=${state.error == null ? 'none' : 'present'}',
    );
  });

  runApp(
    _LivePlayerApp(
      coordinator: coordinator,
      engine: engine,
      windowController: windowController,
      display: display,
      provider: provider,
      stateSubscription: stateSubscription,
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_observeFirstFrame(engine));
    unawaited(_openAndPlay(coordinator, source, episodeNumber));
  });
}

Future<void> _observeFirstFrame(MediaKitSpikeEngine engine) async {
  try {
    await engine.videoController.waitUntilFirstFrameRendered.timeout(
      const Duration(seconds: 45),
    );
    stdout.writeln('native_first_frame=rendered');
  } on TimeoutException {
    stdout.writeln('native_first_frame=not_observed_within_seconds_45');
  } on Object catch (error) {
    stdout.writeln('native_first_frame=failed error_type=${error.runtimeType}');
  }
}

Future<void> _openAndPlay(
  SpikePlayerCoordinator coordinator,
  PlayableSource source,
  int episodeNumber,
) async {
  var opened = false;
  final Timer pendingTimer = Timer(const Duration(seconds: 45), () {
    if (!opened) {
      stdout.writeln(
        'native_open=pending_after_seconds_45 episode=$episodeNumber '
        'media_url_redacted=true',
      );
    }
  });
  try {
    await coordinator.open(source.uri, httpHeaders: source.httpHeaders);
    pendingTimer.cancel();
    opened = true;
    stdout.writeln('native_open=completed episode=$episodeNumber');
    await coordinator.play();
    stdout.writeln('native_play=started episode=$episodeNumber');
  } on Object catch (error) {
    pendingTimer.cancel();
    opened = true;
    stdout.writeln(
      'native_open=failed episode=$episodeNumber '
      'error_type=${error.runtimeType}',
    );
  }
}

final class _LivePlayerApp extends StatefulWidget {
  const _LivePlayerApp({
    required this.coordinator,
    required this.engine,
    required this.windowController,
    required this.display,
    required this.provider,
    required this.stateSubscription,
  });

  final SpikePlayerCoordinator coordinator;
  final MediaKitSpikeEngine engine;
  final GtkPlayerWindowController windowController;
  final PlayerVideoDisplayController display;
  final AnimesDigitalPlaybackProvider provider;
  final StreamSubscription<PlaybackSessionSnapshot> stateSubscription;

  @override
  State<_LivePlayerApp> createState() => _LivePlayerAppState();
}

final class _LivePlayerAppState extends State<_LivePlayerApp> {
  @override
  void dispose() {
    unawaited(_close());
    super.dispose();
  }

  Future<void> _close() async {
    try {
      await widget.stateSubscription.cancel();
      await widget.coordinator.dispose();
    } finally {
      await widget.windowController.dispose();
      widget.provider.close();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kongroo AnimesDigital live check',
    home: SpikePlayerPage(
      coordinator: widget.coordinator,
      videoSurface: MediaKitVideoSurface(
        controller: widget.engine.videoController,
        display: widget.display,
      ),
      windowController: widget.windowController,
      display: widget.display,
    ),
  );
}
