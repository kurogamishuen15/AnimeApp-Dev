import 'dart:async';

import 'package:anime_app/app/player/player_demo_panel.dart';
import 'package:anime_app/app/player/player_video_display.dart';
import 'package:anime_app/app/player/player_window_controller.dart';
import 'package:anime_app/app/player/spike_player_page.dart';
import 'package:anime_app/app/player/spike_player_page_options.dart';
import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/application/player/player_demo_session.dart';
import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/application/player/source_switching/playback_source_switch_service.dart';
import 'package:anime_app/application/player/spike_player_coordinator.dart';
import 'package:anime_app/data/player/providers/mock/mock_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/audio_track_info.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_style.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_track_info.dart';
import 'package:anime_app/domain/player/video_track_info.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('player page options parse composition inputs with safe defaults', () {
    expect(
      SpikePlayerPageOptions.fromEnvironment({}),
      const SpikePlayerPageOptions(),
    );
    expect(
      SpikePlayerPageOptions.fromEnvironment({
        'KONGROO_DEMO_SHOW_NERD': '1',
        'KONGROO_PERF_DIAGNOSTIC': '1',
        'KONGROO_DEMO_FIT': 'cover',
        'KONGROO_DEMO_ASPECT': '21:9',
      }),
      const SpikePlayerPageOptions(
        showNerdPanel: true,
        performanceDiagnosticsEnabled: true,
        initialFit: PlayerVideoFit.cover,
        initialAspect: PlayerVideoAspect.cinema,
      ),
    );
    expect(
      SpikePlayerPageOptions.fromEnvironment({
        'KONGROO_DEMO_FIT': 'unknown',
        'KONGROO_DEMO_ASPECT': 'unknown',
      }),
      const SpikePlayerPageOptions(),
    );
  });

  for (final size in [
    const Size(1280, 720),
    const Size(1366, 768),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'video layout and controls fit at ${size.width}×${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final engine = _FakeEngine();
        final coordinator = await _initializedCoordinator(engine);
        final window = _FakeWindowController();
        final catalog = PlayerDemoCatalog('/widget-demo', [
          18081,
          18082,
          18083,
        ]);
        const videoKey = ValueKey('video-test-surface');
        await _pumpPage(
          tester,
          coordinator,
          windowController: window,
          videoSurface: const SizedBox.expand(key: videoKey),
          demoControls: PlayerDemoPanel(
            catalog: catalog,
            coordinator: coordinator,
          ),
        );
        expect(
          tester.getSize(find.byKey(videoKey)).height,
          greaterThan(size.height * .65),
        );
        expect(find.byKey(const ValueKey('playback-toggle')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('fullscreen-toggle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('player-servers')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('demo-server-2')), findsOneWidget);
        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _disposePage(tester, coordinator);
      },
    );
  }

  testWidgets('media buttons seek, mute, select audio and open diagnostics', (
    tester,
  ) async {
    final engine = _FakeEngine();
    final coordinator = await _initializedCoordinator(engine);
    engine.emit(
      const PlaybackSpikeSnapshot(
        position: Duration(seconds: 20),
        duration: Duration(minutes: 2),
        audioTracks: [
          AudioTrackInfo(id: '1', language: 'eng'),
          AudioTrackInfo(id: '2', language: 'spa'),
        ],
        selectedAudioId: '1',
      ),
    );
    await _pumpPage(tester, coordinator);
    await tester.tap(find.byKey(const ValueKey('rewind-10')));
    await tester.pumpAndSettle();
    expect(coordinator.state.observedPosition, const Duration(seconds: 10));
    await tester.tap(find.byKey(const ValueKey('forward-10')));
    await tester.pumpAndSettle();
    expect(coordinator.state.observedPosition, const Duration(seconds: 20));
    await tester.tap(find.byKey(const ValueKey('player-mute')));
    await tester.pumpAndSettle();
    expect(engine.volumes.last, 0);
    await tester.tap(find.byKey(const ValueKey('player-mute')));
    await tester.pumpAndSettle();
    expect(engine.volumes.last, 100);
    await tester.tap(find.byKey(const ValueKey('player-audio')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<(String, int, int)>, 'Español'),
    );
    await tester.pumpAndSettle();
    expect(engine.audioSelections, ['2']);
    expect(coordinator.state.playback.selectedAudioId, '2');
    await tester.tap(find.byKey(const ValueKey('player-nerd')));
    await tester.pumpAndSettle();
    expect(find.text('Estadísticas técnicas'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('player-nerd-overlay'))).dy,
      lessThan(250),
    );
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Estadísticas técnicas'), findsNothing);
    expect(find.byKey(const ValueKey('playback-toggle')), findsOneWidget);
    await _disposePage(tester, coordinator);
  });

  testWidgets('quality control selects the actual listed video track', (
    tester,
  ) async {
    final engine = _FakeEngine();
    final coordinator = await _initializedCoordinator(engine);
    engine.emit(
      const PlaybackSpikeSnapshot(
        duration: Duration(minutes: 2),
        videoTracks: [
          VideoTrackInfo(id: '1', width: 640, height: 360),
          VideoTrackInfo(id: '2', width: 1280, height: 720),
        ],
        selectedVideoId: '1',
      ),
    );
    await _pumpPage(tester, coordinator);
    await tester.tap(find.byKey(const ValueKey('player-quality')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('video-track-2')));
    await tester.pumpAndSettle();
    expect(engine.videoSelections, ['2']);
    expect(coordinator.state.selectedVideoId, '2');
    expect(coordinator.state.sourceGeneration, engine.sourceGeneration);
    await _disposePage(tester, coordinator);
  });

  testWidgets('display menu applies independent fit and aspect choices', (
    tester,
  ) async {
    final engine = _FakeEngine();
    final coordinator = await _initializedCoordinator(engine);
    final display = PlayerVideoDisplayController();
    await _pumpPage(tester, coordinator, display: display);
    await tester.tap(find.byKey(const ValueKey('player-display-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('video-fit-cover')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('video-aspect-classic')));
    await tester.pumpAndSettle();
    expect(display.value.boxFit, BoxFit.cover);
    expect(display.value.aspectRatio, 4 / 3);
    await tester.tap(find.text('Restablecer'));
    await tester.pumpAndSettle();
    expect(display.value.boxFit, BoxFit.contain);
    expect(display.value.aspectRatio, isNull);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    await _disposePage(tester, coordinator);
  });

  testWidgets(
    'stale audio menu cannot send an old native track after source change',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = _FakeEngine();
      final coordinator = await _initializedCoordinator(engine);
      engine.emit(
        const PlaybackSpikeSnapshot(
          duration: Duration(minutes: 2),
          audioTracks: [AudioTrackInfo(id: 'old-en', language: 'eng')],
          selectedAudioId: 'old-en',
        ),
      );
      await _pumpPage(tester, coordinator);
      await tester.tap(find.byKey(const ValueKey('player-audio')));
      await tester.pumpAndSettle();
      expect(find.text('Inglés'), findsOneWidget);

      engine.firstSeekGate = Completer<void>();
      final Future<void> pendingSeek = coordinator.seek(
        const Duration(seconds: 5),
      );
      await tester.pump();
      expect(engine.seeks, [const Duration(seconds: 5)]);

      engine.emit(
        const PlaybackSpikeSnapshot(
          duration: Duration(minutes: 2),
          audioTracks: [AudioTrackInfo(id: 'new-es', language: 'spa')],
          selectedAudioId: 'new-es',
        ),
      );
      final int previousContext = coordinator.mediaContextRevision;
      final Future<PlaybackSourceSwitchResult> switching = coordinator
          .switchSource(
            Uri.file('/widget-next-source.mp4'),
            referencePosition: const Duration(seconds: 5),
            rollbackPosition: const Duration(seconds: 5),
          );
      expect(coordinator.mediaContextRevision, previousContext + 1);
      await tester.pump();

      // The popup route still contains the old source's menu entry. Selecting it
      // must not retarget that stale native ID to the new media.
      await tester.tap(find.byKey(const ValueKey('audio-track-old-en')));
      await tester.pumpAndSettle();
      expect(find.text('Inglés'), findsNothing);
      expect(engine.audioSelections, isEmpty);
      expect(coordinator.state.error, isNull);
      expect(find.text('Playback command failed.'), findsNothing);

      engine.firstSeekGate!.complete();
      await Future.wait([pendingSeek, switching]);
      expect(coordinator.state.sourceUri, Uri.file('/widget-next-source.mp4'));
      expect(coordinator.state.error, isNull);
      expect(find.text('Playback command failed.'), findsNothing);
      await _disposePage(tester, coordinator);
    },
  );

  testWidgets('queued Stop invalidates audio menu choices immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = _FakeEngine();
    final coordinator = await _initializedCoordinator(engine);
    engine.emit(
      const PlaybackSpikeSnapshot(
        duration: Duration(minutes: 2),
        audioTracks: [AudioTrackInfo(id: 'old-en', language: 'eng')],
        selectedAudioId: 'old-en',
      ),
    );
    await _pumpPage(tester, coordinator);
    await tester.tap(find.byKey(const ValueKey('player-audio')));
    await tester.pumpAndSettle();

    engine.firstSeekGate = Completer<void>();
    final Future<void> pendingSeek = coordinator.seek(
      const Duration(seconds: 5),
    );
    await tester.pump();
    expect(engine.seeks, [const Duration(seconds: 5)]);
    final int previousContext = coordinator.mediaContextRevision;
    final Future<void> stopping = coordinator.stop();
    expect(coordinator.mediaContextRevision, previousContext + 1);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('audio-track-old-en')));
    await tester.pumpAndSettle();
    expect(engine.audioSelections, isEmpty);
    expect(coordinator.state.error, isNull);
    expect(find.text('Playback command failed.'), findsNothing);

    engine.firstSeekGate!.complete();
    await Future.wait([pendingSeek, stopping]);
    expect(coordinator.state.stopped, isTrue);
    await _disposePage(tester, coordinator);
  });

  testWidgets(
    'demo buttons select episodes and servers, then recover a failed mirror',
    (tester) async {
      final engine = _FakeEngine();
      final catalog = PlayerDemoCatalog('/widget-demo', [18081, 18082, 18083]);
      final coordinator = SpikePlayerCoordinator(
        engine,
        demoSources: catalog.loopbackSources,
      );
      await coordinator.initialize();
      await coordinator.open(catalog.source(1, 0));
      await _pumpPage(
        tester,
        coordinator,
        demoControls: PlayerDemoPanel(
          catalog: catalog,
          coordinator: coordinator,
        ),
      );

      final previous = find.byKey(const ValueKey('episode-previous'));
      final next = find.byKey(const ValueKey('episode-next'));
      expect(tester.widget<IconButton>(previous).onPressed, isNull);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(coordinator.state.sourceUri, catalog.source(2, 0));
      expect(tester.widget<IconButton>(next).onPressed, isNull);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(coordinator.state.sourceUri, catalog.source(1, 0));

      final servers = find.byKey(const ValueKey('player-servers'));
      await tester.tap(servers);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-server-2')));
      await tester.pumpAndSettle();
      expect(coordinator.state.sourceUri, catalog.source(1, 2));
      engine.failingSource = catalog.source(1, 3);
      await tester.tap(servers);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-server-3')));
      await tester.pumpAndSettle();
      expect(coordinator.state.sourceUri, catalog.source(1, 2));
      expect(
        find.textContaining('previous source was restored'),
        findsOneWidget,
      );
      await _disposePage(tester, coordinator);
    },
  );

  testWidgets('source switch panel shows and invokes provider alternatives', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    engine.emit(
      const PlaybackSpikeSnapshot(
        playing: true,
        position: Duration(seconds: 22),
        duration: Duration(minutes: 2),
      ),
    );
    final PlaybackProviderId providerId = PlaybackProviderId('mock');
    final Uri initialUri = Uri.file('/widget-fixture.mp4');
    final Uri backupUri = Uri.file('/widget-backup.mp4');
    final MockPlaybackProvider provider = MockPlaybackProvider(
      id: providerId,
      scenario: MockPlaybackScenario.alternatives,
      serverEndpoints: {
        'primary-server': initialUri,
        'backup-server': backupUri,
        'english-server': Uri.file('/widget-english.mp4'),
      },
    );
    final PlaybackProviderManager manager = PlaybackProviderManager(
      providers: [PlaybackProviderRegistration(provider: provider)],
      clock: () => DateTime.utc(2026),
    );
    final PlaybackSourceSwitchService service = PlaybackSourceSwitchService(
      manager: manager,
      episode: PlaybackEpisode(
        animeId: AnimeId('widget-test-anime'),
        episodeNumber: 1,
      ),
      coordinator: coordinator,
      initialSource: ResolvedPlaybackStream(
        providerId: providerId,
        sourceId: 'source-japanese-1080p',
        serverId: 'primary-server',
        uri: initialUri,
      ),
    );
    await _pumpPage(tester, coordinator, sourceSwitchService: service);

    expect(find.text('Source: mock · primary-server'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('switch-source-button')));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 2),
    );

    expect(
      service.state.activity,
      PlaybackSourceSwitchActivity.idle,
      reason:
          'opens=${engine.sourceOpenCalls}, seeks=${engine.seeks}, '
          'coordinator=${coordinator.state.status}/${coordinator.state.position}, '
          'service=${service.state.error}',
    );
    expect(engine.sourceOpenCalls.last, backupUri);
    expect(find.text('Source: mock · backup-server'), findsOneWidget);
    expect(coordinator.state.position, const Duration(seconds: 22));
    expect(coordinator.state.playing, isTrue);
    await _disposePage(tester, coordinator);
    await service.dispose();
  });

  testWidgets('subtitle track and style controls invoke coordinator actions', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    engine.emit(
      const PlaybackSpikeSnapshot(
        duration: Duration(minutes: 2),
        subtitleTracks: [
          SubtitleTrackInfo(
            id: 'auto',
            label: 'Automatic subtitles',
            kind: SubtitleTrackKind.automatic,
          ),
          SubtitleTrackInfo(
            id: 'no',
            label: 'Subtitles off',
            kind: SubtitleTrackKind.disabled,
          ),
          SubtitleTrackInfo(
            id: '2',
            label: 'English',
            language: 'eng',
            kind: SubtitleTrackKind.embedded,
          ),
        ],
        selectedSubtitleId: 'auto',
      ),
    );
    await _pumpPage(tester, coordinator);

    await tester.tap(find.byKey(const ValueKey('player-subtitles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('subtitle-track-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inglés').last);
    await tester.pumpAndSettle();
    expect(engine.subtitleSelections, ['2']);

    await tester.tap(find.byKey(const ValueKey('subtitle-size-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Size 44').last);
    await tester.pumpAndSettle();
    expect(engine.appliedSubtitleStyles.last.fontSize, 44);

    await tester.tap(find.byKey(const ValueKey('subtitle-font-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('monospace').last);
    await tester.pumpAndSettle();
    expect(engine.appliedSubtitleStyles.last.fontFamily, 'monospace');

    await tester.tap(find.byKey(const ValueKey('subtitle-bold-toggle')));
    await tester.pumpAndSettle();
    expect(engine.appliedSubtitleStyles.last.bold, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('subtitle-ass-override-toggle')),
    );
    await tester.pumpAndSettle();
    expect(engine.appliedSubtitleStyles.last.overrideAssStyles, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('subtitle-outline-color-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('White outline').last);
    await tester.pumpAndSettle();
    expect(engine.appliedSubtitleStyles.last.outlineColor, '#FFFFFFFF');

    await tester.tap(find.byKey(const ValueKey('subtitle-delay-increase')));
    await tester.pumpAndSettle();
    expect(engine.subtitleDelays, [const Duration(milliseconds: 250)]);
    expect(find.text('Subtitle delay +0.25s'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('subtitle-delay-decrease')));
    await tester.pumpAndSettle();
    expect(engine.subtitleDelays.last, Duration.zero);
    await _disposePage(tester, coordinator);
  });

  testWidgets('slider drag sends one seek after onChangeEnd', (tester) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(tester, coordinator);

    final Slider slider = tester.widget(find.byType(Slider));
    slider.onChangeStart!(0);
    for (int i = 1; i <= 100; i++) {
      slider.onChanged!(i * 500);
    }

    expect(
      engine.seeks,
      isEmpty,
      reason: 'onChanged must only update the local thumb position.',
    );

    slider.onChangeEnd!(50000);
    await tester.pump();
    await tester.pump();
    expect(engine.seeks, [const Duration(seconds: 50)]);

    await _disposePage(tester, coordinator);
  });

  testWidgets('rapid completed drags keep only the latest pending seek', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine()..firstSeekGate = Completer<void>();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(tester, coordinator);

    Slider slider = tester.widget(find.byType(Slider));
    slider.onChangeStart!(0);
    slider.onChangeEnd!(10000);
    await tester.pump();
    expect(engine.seeks, [const Duration(seconds: 10)]);

    slider = tester.widget(find.byType(Slider));
    slider.onChangeStart!(10000);
    slider.onChangeEnd!(20000);
    slider.onChangeStart!(20000);
    slider.onChangeEnd!(30000);
    await tester.pump();
    expect(engine.seeks, [const Duration(seconds: 10)]);

    engine.firstSeekGate!.complete();
    await tester.pump();
    await tester.pump();
    expect(engine.seeks, [
      const Duration(seconds: 10),
      const Duration(seconds: 30),
    ]);
    expect(engine.maxConcurrentSeeks, 1);

    await _disposePage(tester, coordinator);
  });

  testWidgets('Stop discards a coalesced seek and waits for the active seek', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine()..firstSeekGate = Completer<void>();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(tester, coordinator);

    Slider slider = tester.widget(find.byType(Slider));
    slider.onChangeStart!(0);
    slider.onChangeEnd!(10000);
    await tester.pump();
    expect(engine.callOrder, ['seek']);

    slider = tester.widget(find.byType(Slider));
    slider.onChangeStart!(10000);
    slider.onChangeEnd!(20000);
    await tester.pump();
    expect(engine.seeks, [const Duration(seconds: 10)]);

    await tester.tap(find.byKey(const ValueKey('player-stop')));
    await tester.pump();
    expect(engine.stopCalls, 0);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('player-stop')))
          .onPressed,
      isNull,
      reason: 'Do not allow another stop while the active seek is draining.',
    );

    engine.firstSeekGate!.complete();
    await tester.pump();
    await tester.pump();

    expect(engine.callOrder, ['seek', 'stop']);
    expect(engine.seeks, [const Duration(seconds: 10)]);
    expect(engine.stopCalls, 1);
    expect(engine.maxConcurrentSeeks, 1);

    await _disposePage(tester, coordinator);
  });

  testWidgets('play and pause share one state-synchronized control', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(tester, coordinator);

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('playback-toggle')));
    await tester.pump();
    expect(engine.playCalls, 1);
    expect(engine.pauseCalls, 0);

    engine.emit(
      const PlaybackSpikeSnapshot(
        playing: true,
        position: Duration(seconds: 3),
        duration: Duration(minutes: 2),
      ),
    );
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.text('00:03 / 02:00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('playback-toggle')));
    await tester.pump();
    expect(engine.pauseCalls, 1);
    await _disposePage(tester, coordinator);
  });

  testWidgets('Stop is visibly distinct from Pause and exposes Play', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    engine.emit(
      const PlaybackSpikeSnapshot(
        stopped: true,
        duration: Duration(minutes: 2),
      ),
    );
    await _pumpPage(tester, coordinator);

    expect(
      find.text('Playback stopped · press Play to restart'),
      findsOneWidget,
    );
    expect(find.text('Play'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('playback-toggle')));
    await tester.pump();
    expect(engine.playCalls, 1);
    await _disposePage(tester, coordinator);
  });

  testWidgets('formats long media time and lays out on a narrow window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    engine.emit(
      const PlaybackSpikeSnapshot(
        position: Duration(hours: 1, seconds: 1),
        duration: Duration(hours: 1, minutes: 1),
      ),
    );
    await _pumpPage(tester, coordinator);

    expect(find.text('1:00:01 / 1:01:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposePage(tester, coordinator);
  });

  testWidgets('space and K use the same serialized Play/Pause action', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(
      tester,
      coordinator,
      videoSurface: const SizedBox(key: ValueKey<String>('video-surface')),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(engine.playCalls, 1);
    expect(engine.pauseCalls, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pump();
    expect(engine.playCalls, 1);
    expect(engine.pauseCalls, 1);

    await tester.tap(find.byKey(const ValueKey<String>('playback-toggle')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(engine.pauseCalls, 2);

    await _disposePage(tester, coordinator);
  });

  testWidgets('left/right keyboard seeks accumulate and clamp to duration', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    engine.emit(
      const PlaybackSpikeSnapshot(
        position: Duration(seconds: 5),
        duration: Duration(seconds: 25),
      ),
    );
    await _pumpPage(tester, coordinator);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(engine.seeks, [
      Duration.zero,
      const Duration(seconds: 10),
      const Duration(seconds: 20),
      const Duration(seconds: 25),
    ]);
    expect(coordinator.state.position, const Duration(seconds: 25));
    await _disposePage(tester, coordinator);
  });

  testWidgets('up/down adjusts local volume and clamps at 100 and zero', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    engine.emit(
      const PlaybackSpikeSnapshot(duration: Duration(minutes: 2), volume: 90),
    );
    await _pumpPage(tester, coordinator);

    for (int index = 0; index < 3; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    }
    await tester.pump();
    expect(engine.volumes, [95, 100, 100]);
    expect(coordinator.state.volume, 100);
    expect(find.text('Volume: 100%'), findsOneWidget);

    for (int index = 0; index < 21; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.pump();
    expect(engine.volumes.last, 0);
    expect(coordinator.state.volume, 0);
    expect(find.text('Volume: 0%'), findsOneWidget);
    await _disposePage(tester, coordinator);
  });

  testWidgets('Space restarts a stopped player through the coordinator', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(tester, coordinator);

    await tester.tap(find.byKey(const ValueKey('player-stop')));
    await tester.pump();
    expect(coordinator.state.stopped, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(engine.playCalls, 1);
    expect(coordinator.state.playing, isTrue);
    await _disposePage(tester, coordinator);
  });

  testWidgets('F toggles GTK request and Escape exits fullscreen', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    final _FakeWindowController window = _FakeWindowController();
    await _pumpPage(tester, coordinator, windowController: window);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(window.fullscreenRequests, [true]);
    expect(
      find.text('Fullscreen active · F or Escape to restore'),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(window.fullscreenRequests, [true, false]);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(window.fullscreenRequests, [true, false, true, false]);
    expect(
      find.text('Fullscreen active · F or Escape to restore'),
      findsNothing,
    );
    await _disposePage(tester, coordinator);
  });

  testWidgets('fullscreen button uses the same observed GTK action', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    final _FakeWindowController window = _FakeWindowController();
    await _pumpPage(tester, coordinator, windowController: window);

    expect(find.byTooltip('Enter fullscreen'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('fullscreen-toggle')));
    await tester.pump();
    expect(window.fullscreenRequests, [true]);
    expect(find.byTooltip('Exit fullscreen'), findsOneWidget);

    await _disposePage(tester, coordinator);
  });

  testWidgets('unknown and modified keys do not invoke player actions', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(tester, coordinator);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(engine.playCalls, 0);
    expect(engine.pauseCalls, 0);
    expect(engine.seeks, isEmpty);
    expect(engine.volumes, isEmpty);
    await _disposePage(tester, coordinator);
  });

  testWidgets('held Space ignores KeyRepeat while seek repeat is accepted', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(tester, coordinator);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(engine.playCalls, 1);
    expect(engine.pauseCalls, 0);
    expect(engine.seeks, [
      const Duration(seconds: 10),
      const Duration(seconds: 20),
    ]);
    await _disposePage(tester, coordinator);
  });

  testWidgets('TextField retains keyboard input instead of triggering player', (
    tester,
  ) async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = await _initializedCoordinator(
      engine,
    );
    await _pumpPage(
      tester,
      coordinator,
      videoSurface: const TextField(key: ValueKey<String>('focus-input')),
    );

    final FocusNode editorFocus = tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode;
    editorFocus.requestFocus();
    await tester.pump();
    expect(editorFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pump();
    expect(engine.playCalls, 0);
    expect(engine.pauseCalls, 0);
    await _disposePage(tester, coordinator);
  });
}

Future<SpikePlayerCoordinator> _initializedCoordinator(
  _FakeEngine engine,
) async {
  final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
  await coordinator.initialize();
  await coordinator.open(Uri.file('/widget-fixture.mp4'));
  engine.emit(const PlaybackSpikeSnapshot(duration: Duration(minutes: 2)));
  return coordinator;
}

Future<void> _pumpPage(
  WidgetTester tester,
  SpikePlayerCoordinator coordinator, {
  PlayerWindowController? windowController,
  PlaybackSourceSwitchService? sourceSwitchService,
  Widget videoSurface = const SizedBox.shrink(),
  Widget? demoControls,
  PlayerVideoDisplayController? display,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SpikePlayerPage(
        coordinator: coordinator,
        videoSurface: videoSurface,
        demoControls: demoControls,
        display: display,
        windowController: windowController ?? _FakeWindowController(),
        sourceSwitchService: sourceSwitchService,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _disposePage(
  WidgetTester tester,
  SpikePlayerCoordinator coordinator,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(coordinator.dispose);
}

final class _FakeEngine
    implements
        PlaybackSpikeEngine,
        PlaybackAudioSelection,
        PlaybackVideoSelection {
  final List<String> audioSelections = [];
  final List<String> videoSelections = [];
  Uri? failingSource;
  final StreamController<PlaybackSpikeSnapshot> _snapshots =
      StreamController<PlaybackSpikeSnapshot>.broadcast(sync: true);
  final List<Duration> seeks = [];
  final List<String> callOrder = [];
  final List<double> volumes = [];
  final List<String> subtitleSelections = [];
  final List<SubtitleStyle> appliedSubtitleStyles = [];
  final List<Duration> subtitleDelays = [];
  final List<Uri> sourceOpenCalls = [];
  Completer<void>? firstSeekGate;
  int _activeSeeks = 0;
  int maxConcurrentSeeks = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  int sourceGeneration = 0;
  PlaybackSpikeSnapshot _current = const PlaybackSpikeSnapshot();

  @override
  Stream<PlaybackSpikeSnapshot> get snapshots => _snapshots.stream;

  void emit(PlaybackSpikeSnapshot snapshot) {
    if (snapshot.sourceGeneration == 0) {
      snapshot = snapshot.copyWith(sourceGeneration: sourceGeneration);
    }
    _current = snapshot;
    _snapshots.add(snapshot);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> open(Uri source, {int sourceGeneration = 0}) async {
    this.sourceGeneration = sourceGeneration;
    sourceOpenCalls.add(source);
    if (source == failingSource) throw StateError('503');
    emit(
      _current.copyWith(
        sourceGeneration: sourceGeneration,
        playing: false,
        stopped: false,
        position: Duration.zero,
        duration: const Duration(minutes: 2),
        clearError: true,
      ),
    );
  }

  @override
  Future<void> play() async {
    playCalls++;
    emit(_current.copyWith(playing: true, stopped: false));
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    emit(_current.copyWith(playing: false));
  }

  @override
  Future<void> seek(Duration position) async {
    callOrder.add('seek');
    seeks.add(position);
    _activeSeeks++;
    if (_activeSeeks > maxConcurrentSeeks) {
      maxConcurrentSeeks = _activeSeeks;
    }
    try {
      if (seeks.length == 1) await firstSeekGate?.future;
      emit(_current.copyWith(position: position));
    } finally {
      _activeSeeks--;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
    emit(_current.copyWith(volume: volume));
  }

  @override
  Future<void> selectAudioTrack(String id) async {
    if (!_current.audioTracks.any((track) => track.id == id)) {
      throw StateError('Audio track is not available in the active source.');
    }
    audioSelections.add(id);
    emit(_current.copyWith(selectedAudioId: id));
  }

  @override
  Future<void> selectVideoTrack(String id) async {
    if (id != 'auto' && !_current.videoTracks.any((track) => track.id == id)) {
      throw StateError('Video track is not available in the active source.');
    }
    videoSelections.add(id);
    emit(_current.copyWith(selectedVideoId: id));
  }

  @override
  Future<void> selectSubtitleTrack(String id) async {
    subtitleSelections.add(id);
  }

  @override
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
  }) async => externalSubtitleDecision(hardsubStatus);

  @override
  Future<void> applySubtitleStyle(SubtitleStyle style) async {
    appliedSubtitleStyles.add(style);
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    subtitleDelays.add(delay);
  }

  @override
  Future<void> stop() async {
    callOrder.add('stop');
    stopCalls++;
    emit(
      _current.copyWith(playing: false, stopped: true, position: Duration.zero),
    );
  }

  @override
  Future<void> dispose() async {
    if (!_snapshots.isClosed) await _snapshots.close();
  }
}

final class _FakeWindowController implements PlayerWindowController {
  final List<bool> fullscreenRequests = [];
  final List<MultiStreamController<PlayerWindowSnapshot>> _listeners = [];
  PlayerWindowSnapshot _state = const PlayerWindowSnapshot(observed: true);

  @override
  PlayerWindowSnapshot get state => _state;

  @override
  Stream<PlayerWindowSnapshot> get states => Stream<PlayerWindowSnapshot>.multi(
    (MultiStreamController<PlayerWindowSnapshot> controller) {
      _listeners.add(controller);
      controller.add(_state);
      controller.onCancel = () => _listeners.remove(controller);
    },
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestFullscreen(bool fullscreen) async {
    fullscreenRequests.add(fullscreen);
    _state = _state.copyWith(fullscreen: fullscreen);
    for (final MultiStreamController<PlayerWindowSnapshot> listener
        in List<MultiStreamController<PlayerWindowSnapshot>>.of(_listeners)) {
      listener.add(_state);
    }
  }

  @override
  Future<void> dispose() async {}
}
