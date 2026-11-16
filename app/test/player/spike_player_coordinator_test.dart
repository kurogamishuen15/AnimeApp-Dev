import 'dart:async';

import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/application/player/skips/automatic_skip_controller.dart';
import 'package:anime_app/application/player/skips/skip_segment_service.dart';
import 'package:anime_app/application/player/source_switching/playback_source_switch_service.dart';
import 'package:anime_app/application/player/spike_player_coordinator.dart';
import 'package:anime_app/data/player/providers/mock/mock_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/skips/skip_automation_policy.dart';
import 'package:anime_app/domain/player/skips/skip_segment.dart';
import 'package:anime_app/domain/player/skips/skip_segment_catalog.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manual skip appears only in a valid segment and confirms observed seek',
    () async {
      final Uri source = Uri.file('/skip.mp4');
      final PlaybackEpisode episode = PlaybackEpisode(
        animeId: AnimeId('skip-service-anime'),
        episodeNumber: 1,
      );
      final _FakeEngine engine = _FakeEngine()..emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(source);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 15),
          duration: Duration(seconds: 120),
        ),
      );
      final SkipSegmentService service = SkipSegmentService(
        episode: episode,
        coordinator: coordinator,
        catalog: _FakeSkipCatalog([
          SkipSegment(
            episode: episode,
            kind: SkipSegmentKind.opening,
            start: const Duration(seconds: 10),
            end: const Duration(seconds: 20),
            source: SkipSegmentSource.aniskip,
            sourceId: 'skip-1',
          ),
          SkipSegment(
            episode: episode,
            kind: SkipSegmentKind.ending,
            start: const Duration(seconds: 110),
            end: const Duration(seconds: 130),
            source: SkipSegmentSource.aniskip,
            sourceId: 'outside-duration',
          ),
        ]),
        malAnimeId: MyAnimeListAnimeId(1),
      );
      await service.load();

      expect(service.state.activeSegment?.kind, SkipSegmentKind.opening);
      expect(await service.skipCurrent(), isTrue);
      expect(engine.seeks, [const Duration(seconds: 20)]);
      expect(coordinator.state.observedPosition, const Duration(seconds: 20));
      expect(service.state.lastSkipConfirmed, isTrue);
      expect(service.state.activeSegment, isNull);

      await service.dispose();
      await coordinator.dispose();
    },
  );

  test(
    'automatic skip stays off by default and manual seek suppresses a segment',
    () async {
      final Uri source = Uri.file('/automatic-skip.mp4');
      final PlaybackEpisode episode = PlaybackEpisode(
        animeId: AnimeId('automatic-skip-anime'),
        episodeNumber: 1,
      );
      final _FakeEngine engine = _FakeEngine()..emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(source);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 1),
          duration: Duration(seconds: 120),
        ),
      );
      final SkipSegmentService service = SkipSegmentService(
        episode: episode,
        coordinator: coordinator,
        catalog: _FakeSkipCatalog([
          SkipSegment(
            episode: episode,
            kind: SkipSegmentKind.opening,
            start: const Duration(seconds: 10),
            end: const Duration(seconds: 20),
            source: SkipSegmentSource.aniskip,
            sourceId: 'opening-1',
          ),
        ]),
        malAnimeId: MyAnimeListAnimeId(1),
      );
      await service.load();
      final AutomaticSkipController automation = AutomaticSkipController(
        coordinator: coordinator,
        segments: service,
        settings: const SkipAutomationSettings(),
      );

      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 12),
          duration: Duration(seconds: 120),
        ),
      );
      expect(engine.seeks, isEmpty);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 1),
          duration: Duration(seconds: 120),
        ),
      );
      expect(coordinator.state.position, const Duration(seconds: 1));
      automation.update(settings: const SkipAutomationSettings(opening: true));
      expect(engine.seeks, isEmpty);

      await coordinator.seek(const Duration(seconds: 15));
      expect(engine.seeks, [const Duration(seconds: 15)]);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 30),
          duration: Duration(seconds: 120),
        ),
      );
      final Completer<void> autoSeekObserved = Completer<void>();
      final StreamSubscription<PlaybackSessionSnapshot> confirmation =
          coordinator.states.listen((PlaybackSessionSnapshot snapshot) {
            if (snapshot.observedPosition == const Duration(seconds: 20) &&
                !autoSeekObserved.isCompleted) {
              autoSeekObserved.complete();
            }
          });
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 12),
          duration: Duration(seconds: 120),
        ),
      );
      await autoSeekObserved.future.timeout(const Duration(seconds: 2));
      expect(engine.seeks, [
        const Duration(seconds: 15),
        const Duration(seconds: 20),
      ]);

      await confirmation.cancel();
      await automation.dispose();
      await service.dispose();
      await coordinator.dispose();
    },
  );

  test(
    'typed session snapshot tracks lifecycle and orthogonal seeking',
    () async {
      final _FakeEngine engine = _FakeEngine();
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      expect(coordinator.state.status, PlaybackSessionStatus.idle);
      await coordinator.initialize();
      final Completer<void> openStarted = Completer<void>();
      final Completer<void> openGate = Completer<void>();
      engine.openStarted = openStarted;
      engine.openGate = openGate;
      final Future<void> opening = coordinator.open(Uri.file('/clip.mp4'));
      await openStarted.future;
      expect(coordinator.state.status, PlaybackSessionStatus.opening);
      openGate.complete();
      await opening;
      expect(coordinator.state.status, PlaybackSessionStatus.ready);

      engine.emit(
        const PlaybackSpikeSnapshot(
          buffering: true,
          duration: Duration(seconds: 10),
        ),
      );
      expect(coordinator.state.status, PlaybackSessionStatus.buffering);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          duration: Duration(seconds: 10),
        ),
      );
      expect(coordinator.state.status, PlaybackSessionStatus.playing);
      await coordinator.pause();
      expect(coordinator.state.status, PlaybackSessionStatus.paused);

      final Completer<void> seekStarted = Completer<void>();
      final Completer<void> seekGate = Completer<void>();
      engine.seekStarted = seekStarted;
      engine.seekGate = seekGate;
      final Future<void> seeking = coordinator.seek(const Duration(seconds: 4));
      await seekStarted.future;
      expect(coordinator.state.status, PlaybackSessionStatus.paused);
      expect(coordinator.state.seeking, isTrue);
      seekGate.complete();
      await seeking;
      expect(coordinator.state.status, PlaybackSessionStatus.paused);
      expect(coordinator.state.seeking, isFalse);

      engine.emit(
        const PlaybackSpikeSnapshot(
          duration: Duration(seconds: 10),
          position: Duration(seconds: 10),
        ),
      );
      expect(coordinator.state.status, PlaybackSessionStatus.completed);
      await coordinator.stop();
      expect(coordinator.state.status, PlaybackSessionStatus.stopped);
      expect(coordinator.state.position, Duration.zero);
      await coordinator.play();
      expect(coordinator.state.status, PlaybackSessionStatus.playing);
      await coordinator.dispose();
      expect(coordinator.state.status, PlaybackSessionStatus.disposed);
    },
  );

  test('open failure is visible and a later valid open recovers', () async {
    final _FakeEngine engine = _FakeEngine()..openFailuresRemaining = 1;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();

    await expectLater(
      coordinator.open(Uri.file('/missing.mp4')),
      throwsStateError,
    );
    expect(coordinator.state.status, PlaybackSessionStatus.error);
    expect(
      coordinator.state.error,
      'Could not open the selected media source.',
    );

    await coordinator.open(Uri.file('/valid.mp4'));
    expect(coordinator.state.status, PlaybackSessionStatus.ready);
    expect(coordinator.state.error, isNull);

    engine.emit(
      const PlaybackSpikeSnapshot(
        error: 'Native source error: sanitized test fixture.',
      ),
    );
    expect(coordinator.state.status, PlaybackSessionStatus.error);
    expect(coordinator.state.error, contains('Native source error'));
    await coordinator.open(Uri.file('/recovered.mp4'));
    expect(coordinator.state.status, PlaybackSessionStatus.ready);
    expect(coordinator.state.error, isNull);
    await coordinator.dispose();
  });

  test(
    'initialization and stop failures are observable and recoverable',
    () async {
      final _FakeEngine engine = _FakeEngine()
        ..initializeFailuresRemaining = 1
        ..stopFailuresRemaining = 1;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);

      await expectLater(coordinator.initialize(), throwsStateError);
      expect(coordinator.state.status, PlaybackSessionStatus.error);
      expect(coordinator.state.error, 'Playback engine initialization failed.');

      await coordinator.initialize();
      expect(coordinator.state.status, PlaybackSessionStatus.idle);
      expect(coordinator.state.error, isNull);
      await coordinator.open(Uri.file('/clip.mp4'));
      await expectLater(coordinator.stop(), throwsStateError);
      expect(coordinator.state.status, PlaybackSessionStatus.error);
      expect(coordinator.state.error, 'Stop failed.');

      await coordinator.stop();
      expect(coordinator.state.status, PlaybackSessionStatus.stopped);
      expect(coordinator.state.stopped, isTrue);
      await coordinator.dispose();
    },
  );

  test('late snapshot from an older source generation is ignored', () async {
    final _FakeEngine engine = _FakeEngine();
    final Completer<void> openStarted = Completer<void>();
    final Completer<void> openGate = Completer<void>();
    engine.openStarted = openStarted;
    engine.openGate = openGate;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();

    final Future<void> firstOpen = coordinator.open(Uri.file('/a.mp4'));
    await openStarted.future;
    final int firstGeneration = coordinator.state.sourceGeneration;
    final Future<void> secondOpen = coordinator.open(Uri.file('/b.mp4'));
    openGate.complete();
    await Future.wait([firstOpen, secondOpen]);
    final int secondGeneration = coordinator.state.sourceGeneration;
    expect(secondGeneration, firstGeneration + 1);

    engine.emit(
      PlaybackSpikeSnapshot(
        sourceGeneration: firstGeneration,
        position: const Duration(seconds: 9),
        duration: const Duration(seconds: 10),
        playing: true,
      ),
    );
    expect(coordinator.state.sourceGeneration, secondGeneration);
    expect(coordinator.state.position, Duration.zero);
    expect(coordinator.state.status, PlaybackSessionStatus.ready);
    await coordinator.dispose();
  });

  test(
    'Stop queued during Seek runs after it and owns the final state',
    () async {
      final _FakeEngine engine = _FakeEngine();
      final Completer<void> seekStarted = Completer<void>();
      final Completer<void> seekGate = Completer<void>();
      engine.seekStarted = seekStarted;
      engine.seekGate = seekGate;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(Uri.file('/clip.mp4'));
      engine.emit(
        const PlaybackSpikeSnapshot(
          position: Duration(seconds: 1),
          duration: Duration(seconds: 20),
          playing: true,
        ),
      );

      final Future<void> seeking = coordinator.seek(const Duration(seconds: 8));
      await seekStarted.future;
      final Future<void> stopping = coordinator.stop();
      expect(engine.calls, ['initialize', 'open', 'seek']);

      seekGate.complete();
      await Future.wait([seeking, stopping]);
      expect(engine.calls, ['initialize', 'open', 'seek', 'stop']);
      expect(coordinator.state.status, PlaybackSessionStatus.stopped);
      expect(coordinator.state.position, Duration.zero);
      await coordinator.dispose();
    },
  );

  test('Play queued during Stop waits and starts only after Stop', () async {
    final _FakeEngine engine = _FakeEngine();
    final Completer<void> stopStarted = Completer<void>();
    final Completer<void> stopGate = Completer<void>();
    engine.stopStarted = stopStarted;
    engine.stopGate = stopGate;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    await coordinator.open(Uri.file('/clip.mp4'));

    final Future<void> stopping = coordinator.stop();
    await stopStarted.future;
    final Future<void> playing = coordinator.play();
    expect(engine.calls, ['initialize', 'open', 'stop']);
    stopGate.complete();
    await Future.wait([stopping, playing]);
    expect(engine.calls, ['initialize', 'open', 'stop', 'play']);
    expect(coordinator.state.status, PlaybackSessionStatus.playing);
    expect(coordinator.state.stopped, isFalse);
    await coordinator.dispose();
  });

  test('initializes once and serializes commands in order', () async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    await coordinator.initialize();
    await coordinator.open(Uri.file('/tmp/clip.mp4'));
    await coordinator.play();
    await coordinator.pause();
    await coordinator.seek(const Duration(seconds: 2));
    await coordinator.stop();
    expect(engine.calls, [
      'initialize',
      'open',
      'play',
      'pause',
      'seek',
      'stop',
    ]);
    await coordinator.dispose();
    expect(engine.calls.last, 'dispose');
  });

  test('rejects non-local URI and seek beyond known duration', () async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    await coordinator.open(Uri.file('/clip.mp4'));
    await expectLater(
      coordinator.open(Uri.parse('https://example.invalid/a.mp4')),
      throwsArgumentError,
    );
    engine.emit(const PlaybackSpikeSnapshot(duration: Duration(seconds: 8)));
    await expectLater(
      coordinator.seek(const Duration(seconds: 9)),
      throwsRangeError,
    );
    await coordinator.dispose();
  });

  test('commands after dispose fail and repeated dispose is safe', () async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    await coordinator.dispose();
    await coordinator.dispose();
    await expectLater(coordinator.play(), throwsStateError);
  });

  test(
    'relative seek accumulates on queued targets and respects bounds',
    () async {
      final _FakeEngine engine = _FakeEngine();
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(Uri.file('/clip.mp4'));
      engine.emit(
        const PlaybackSpikeSnapshot(
          position: Duration(seconds: 5),
          duration: Duration(seconds: 25),
        ),
      );

      await Future.wait([
        coordinator.seekBy(const Duration(seconds: 10)),
        coordinator.seekBy(const Duration(seconds: 10)),
        coordinator.seekBy(const Duration(seconds: 10)),
      ]);
      expect(engine.seeks, [
        const Duration(seconds: 15),
        const Duration(seconds: 25),
        const Duration(seconds: 25),
      ]);
      await coordinator.seekBy(const Duration(seconds: -40));
      expect(engine.seeks.last, Duration.zero);
      await coordinator.dispose();
    },
  );

  test(
    'source switch restores observed position and playback intent',
    () async {
      final _FakeEngine engine = _FakeEngine();
      engine.emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      final Uri sourceA = Uri.file('/a.mp4');
      final Uri sourceB = Uri.file('/b.mp4');
      await coordinator.open(sourceA);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 23),
          duration: Duration(seconds: 120),
        ),
      );

      final PlaybackSourceSwitchResult result = await coordinator.switchSource(
        sourceB,
      );

      expect(result.disposition, PlaybackSourceSwitchDisposition.changed);
      expect(result.previousSource, sourceA);
      expect(result.selectedSource, sourceB);
      expect(result.referencePosition, const Duration(seconds: 23));
      expect(result.observedPosition, const Duration(seconds: 23));
      expect(result.positionDelta, Duration.zero);
      expect(coordinator.state.sourceUri, sourceB);
      expect(coordinator.state.playing, isTrue);
      expect(coordinator.state.status, PlaybackSessionStatus.playing);
      expect(engine.openedSources, [sourceA, sourceB]);
      expect(engine.seeks, [const Duration(seconds: 23)]);
      await coordinator.dispose();
    },
  );

  test(
    'failed target restores previous source position and pause state',
    () async {
      final _FakeEngine engine = _FakeEngine();
      engine.emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      final Uri sourceA = Uri.file('/a.mp4');
      final Uri sourceB = Uri.file('/bad.mp4');
      final PlaybackRequestHeaders headersA = PlaybackRequestHeaders({
        'Referer': 'https://provider.example.com/',
      });
      final PlaybackRequestHeaders headersB = PlaybackRequestHeaders({
        'Referer': 'https://mirror.example.com/',
      });
      await coordinator.open(sourceA, httpHeaders: headersA);
      engine.emit(
        const PlaybackSpikeSnapshot(
          position: Duration(seconds: 19),
          duration: Duration(seconds: 120),
        ),
      );
      engine.openFailuresRemaining = 1;

      final PlaybackSourceSwitchResult result = await coordinator.switchSource(
        sourceB,
        httpHeaders: headersB,
      );

      expect(
        result.disposition,
        PlaybackSourceSwitchDisposition.targetFailedPreviousRestored,
      );
      expect(coordinator.state.sourceUri, sourceA);
      expect(coordinator.state.position, const Duration(seconds: 19));
      expect(coordinator.state.playing, isFalse);
      expect(coordinator.state.status, PlaybackSessionStatus.paused);
      expect(engine.openedSources, [sourceA, sourceB, sourceA]);
      expect(
        engine.openedHttpHeaders.map(
          (PlaybackRequestHeaders value) => value.values,
        ),
        [headersA.values, headersB.values, headersA.values],
      );
      expect(engine.seeks, [const Duration(seconds: 19)]);
      await coordinator.dispose();
    },
  );

  test(
    'a late source switch is serialized before a newer requested source',
    () async {
      final _FakeEngine engine = _FakeEngine();
      engine.emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      final Uri sourceA = Uri.file('/a.mp4');
      final Uri sourceB = Uri.file('/b.mp4');
      final Uri sourceC = Uri.file('/c.mp4');
      await coordinator.open(sourceA);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 12),
          duration: Duration(seconds: 120),
        ),
      );
      final Completer<void> openStarted = Completer<void>();
      final Completer<void> openGate = Completer<void>();
      engine.openStarted = openStarted;
      engine.openGate = openGate;

      final Future<PlaybackSourceSwitchResult> switchingB = coordinator
          .switchSource(sourceB);
      await openStarted.future;
      final Future<PlaybackSourceSwitchResult> switchingC = coordinator
          .switchSource(sourceC);
      openGate.complete();
      final List<PlaybackSourceSwitchResult> results = await Future.wait([
        switchingB,
        switchingC,
      ]);

      expect(results.every((result) => result.succeeded), isTrue);
      expect(coordinator.state.sourceUri, sourceC);
      expect(coordinator.state.status, PlaybackSessionStatus.playing);
      expect(engine.openedSources, [sourceA, sourceB, sourceC]);
      expect(engine.seeks, [
        const Duration(seconds: 12),
        const Duration(seconds: 12),
      ]);
      await coordinator.dispose();
    },
  );

  test('Stop queued during source switch owns the final state', () async {
    final _FakeEngine engine = _FakeEngine()..emitSourceEvents = true;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    await coordinator.open(Uri.file('/a.mp4'));
    engine.emit(
      const PlaybackSpikeSnapshot(
        playing: true,
        position: Duration(seconds: 18),
        duration: Duration(seconds: 120),
      ),
    );
    final Completer<void> openStarted = Completer<void>();
    final Completer<void> openGate = Completer<void>();
    engine.openStarted = openStarted;
    engine.openGate = openGate;

    final Future<PlaybackSourceSwitchResult> switching = coordinator
        .switchSource(Uri.file('/b.mp4'));
    await openStarted.future;
    final Future<void> stopping = coordinator.stop();
    openGate.complete();
    await Future.wait([switching, stopping]);

    expect(
      engine.calls.indexOf('open'),
      lessThan(engine.calls.lastIndexOf('stop')),
    );
    expect(coordinator.state.status, PlaybackSessionStatus.stopped);
    expect(coordinator.state.stopped, isTrue);
    expect(coordinator.state.sourceUri, Uri.file('/b.mp4'));
    await coordinator.dispose();
  });

  test('dispose waits for a pending source switch and closes once', () async {
    final _FakeEngine engine = _FakeEngine()..emitSourceEvents = true;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    await coordinator.open(Uri.file('/a.mp4'));
    engine.emit(
      const PlaybackSpikeSnapshot(
        playing: true,
        position: Duration(seconds: 7),
        duration: Duration(seconds: 120),
      ),
    );
    final Completer<void> openStarted = Completer<void>();
    final Completer<void> openGate = Completer<void>();
    engine.openStarted = openStarted;
    engine.openGate = openGate;

    final Future<PlaybackSourceSwitchResult> switching = coordinator
        .switchSource(Uri.file('/b.mp4'));
    await openStarted.future;
    final Future<void> closing = coordinator.dispose();
    openGate.complete();
    await Future.wait([switching, closing]);

    expect(coordinator.state.status, PlaybackSessionStatus.disposed);
    expect(engine.disposeCalls, 1);
    expect(engine.calls.last, 'dispose');
  });

  test(
    'provider fallback keeps position and state on the working candidate',
    () async {
      final Uri sourceA = Uri.file('/a.mp4');
      final Uri sourceB = Uri.file('/b.mp4');
      final Uri sourceC = Uri.file('/c.mp4');
      final PlaybackProviderId providerId = PlaybackProviderId('mock');
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: providerId,
        scenario: MockPlaybackScenario.alternatives,
        serverEndpoints: {
          'primary-server': sourceA,
          'backup-server': sourceB,
          'english-server': sourceC,
        },
      );
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: [PlaybackProviderRegistration(provider: provider)],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(resolver: provider),
        ],
        clock: () => DateTime.utc(2026),
      );
      final _FakeEngine engine = _FakeEngine()..emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(sourceA);
      engine.openFailuresRemaining = 1;
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 29),
          duration: Duration(seconds: 120),
        ),
      );
      final PlaybackSourceSwitchService service = PlaybackSourceSwitchService(
        manager: manager,
        episode: PlaybackEpisode(
          animeId: AnimeId('local-test-anime'),
          episodeNumber: 1,
        ),
        coordinator: coordinator,
        initialSource: ResolvedPlaybackStream(
          providerId: providerId,
          sourceId: 'source-japanese-1080p',
          serverId: 'primary-server',
          uri: sourceA,
        ),
      );

      final PlaybackSourceSwitchAttempt result = await service.switchToNext();

      expect(result.status, PlaybackSourceSwitchAttemptStatus.switched);
      expect(result.selected?.serverId, 'english-server');
      expect(result.failedCandidateCount, 1);
      expect(result.positionDelta, Duration.zero);
      expect(coordinator.state.sourceUri, sourceC);
      expect(coordinator.state.position, const Duration(seconds: 29));
      expect(coordinator.state.playing, isTrue);
      expect(service.state.current?.serverId, 'english-server');
      expect(engine.openedSources, [sourceA, sourceB, sourceA, sourceC]);
      await service.dispose();
      await coordinator.dispose();
    },
  );

  test(
    'a concurrent provider switch cannot desynchronize the active source',
    () async {
      final Uri sourceA = Uri.file('/a.mp4');
      final Uri sourceB = Uri.file('/b.mp4');
      final Uri sourceC = Uri.file('/c.mp4');
      final PlaybackProviderId providerId = PlaybackProviderId('mock');
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: providerId,
        scenario: MockPlaybackScenario.alternatives,
        unavailableServerIds: {'english-server'},
        serverEndpoints: {
          'primary-server': sourceA,
          'backup-server': sourceB,
          'english-server': sourceC,
        },
      );
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: [PlaybackProviderRegistration(provider: provider)],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(resolver: provider),
        ],
        clock: () => DateTime.utc(2026),
      );
      final _FakeEngine engine = _FakeEngine()..emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(sourceA);
      engine.emit(
        const PlaybackSpikeSnapshot(
          playing: true,
          position: Duration(seconds: 16),
          duration: Duration(seconds: 120),
        ),
      );
      final PlaybackSourceSwitchService service = PlaybackSourceSwitchService(
        manager: manager,
        episode: PlaybackEpisode(
          animeId: AnimeId('local-test-anime'),
          episodeNumber: 1,
        ),
        coordinator: coordinator,
        initialSource: ResolvedPlaybackStream(
          providerId: providerId,
          sourceId: 'source-japanese-1080p',
          serverId: 'primary-server',
          uri: sourceA,
        ),
      );
      final Completer<void> openStarted = Completer<void>();
      final Completer<void> openGate = Completer<void>();
      engine.openStarted = openStarted;
      engine.openGate = openGate;

      final Future<PlaybackSourceSwitchAttempt> first = service.switchToNext();
      await openStarted.future;
      final Future<PlaybackSourceSwitchAttempt> second = service.switchToNext();
      openGate.complete();
      final List<PlaybackSourceSwitchAttempt> results = await Future.wait([
        first,
        second,
      ]);

      expect(results.first.status, PlaybackSourceSwitchAttemptStatus.switched);
      expect(results.last.status, PlaybackSourceSwitchAttemptStatus.busy);
      expect(results.first.selected?.serverId, 'backup-server');
      expect(coordinator.state.sourceUri, sourceB);
      expect(coordinator.state.status, PlaybackSessionStatus.playing);
      expect(service.state.current?.serverId, 'backup-server');
      expect(engine.openedSources, [sourceA, sourceB]);
      await service.dispose();
      await coordinator.dispose();
    },
  );

  test(
    'all provider alternatives can fail while the previous session recovers',
    () async {
      final Uri sourceA = Uri.file('/a.mp4');
      final Uri sourceB = Uri.file('/b.mp4');
      final Uri sourceC = Uri.file('/c.mp4');
      final PlaybackProviderId providerId = PlaybackProviderId('mock');
      final MockPlaybackProvider provider = MockPlaybackProvider(
        id: providerId,
        scenario: MockPlaybackScenario.alternatives,
        serverEndpoints: {
          'primary-server': sourceA,
          'backup-server': sourceB,
          'english-server': sourceC,
        },
      );
      final PlaybackProviderManager manager = PlaybackProviderManager(
        providers: [PlaybackProviderRegistration(provider: provider)],
        videoHostResolvers: [
          PlaybackVideoHostResolverRegistration(resolver: provider),
        ],
        clock: () => DateTime.utc(2026),
      );
      final _FakeEngine engine = _FakeEngine()..emitSourceEvents = true;
      engine.openFailureUris.addAll([sourceB, sourceC]);
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(sourceA);
      engine.emit(
        const PlaybackSpikeSnapshot(
          position: Duration(seconds: 14),
          duration: Duration(seconds: 120),
        ),
      );
      final PlaybackSourceSwitchService service = PlaybackSourceSwitchService(
        manager: manager,
        episode: PlaybackEpisode(
          animeId: AnimeId('local-test-anime'),
          episodeNumber: 1,
        ),
        coordinator: coordinator,
        initialSource: ResolvedPlaybackStream(
          providerId: providerId,
          sourceId: 'source-japanese-1080p',
          serverId: 'primary-server',
          uri: sourceA,
        ),
      );

      final PlaybackSourceSwitchAttempt result = await service.switchToNext();

      expect(result.status, PlaybackSourceSwitchAttemptStatus.failed);
      expect(result.failedCandidateCount, 2);
      expect(coordinator.state.sourceUri, sourceA);
      expect(coordinator.state.position, const Duration(seconds: 14));
      expect(coordinator.state.status, PlaybackSessionStatus.paused);
      expect(service.state.current?.serverId, 'primary-server');
      expect(service.state.error, contains('previous source remains active'));
      await service.dispose();
      await coordinator.dispose();
    },
  );

  test(
    'failed target and failed rollback leave explicit stable error',
    () async {
      final _FakeEngine engine = _FakeEngine();
      engine.emitSourceEvents = true;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(Uri.file('/a.mp4'));
      engine.openFailuresRemaining = 2;

      final PlaybackSourceSwitchResult result = await coordinator.switchSource(
        Uri.file('/bad.mp4'),
      );

      expect(
        result.disposition,
        PlaybackSourceSwitchDisposition.targetAndPreviousFailed,
      );
      expect(coordinator.state.status, PlaybackSessionStatus.error);
      expect(coordinator.state.sourceUri, isNull);
      expect(coordinator.state.error, contains('previous source'));
      await coordinator.dispose();
    },
  );

  test(
    'volume steps are serialized, player-local, and clamped to 0–100',
    () async {
      final _FakeEngine engine = _FakeEngine();
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      engine.emit(const PlaybackSpikeSnapshot(volume: 90));
      await Future.wait([
        coordinator.adjustVolumeBy(5),
        coordinator.adjustVolumeBy(5),
        coordinator.adjustVolumeBy(5),
      ]);
      expect(engine.volumes, [95, 100, 100]);
      expect(coordinator.state.volume, 100);
      await coordinator.adjustVolumeBy(-200);
      expect(engine.volumes.last, 0);
      expect(coordinator.state.volume, 0);
      await coordinator.dispose();
    },
  );

  test('seek is rejected for stopped media', () async {
    final _FakeEngine engine = _FakeEngine();
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    await coordinator.open(Uri.file('/clip.mp4'));
    engine.emit(const PlaybackSpikeSnapshot(stopped: true));
    await expectLater(
      coordinator.seekBy(const Duration(seconds: 10)),
      throwsStateError,
    );
    await expectLater(
      coordinator.seek(const Duration(seconds: 10)),
      throwsStateError,
    );
    expect(engine.seeks, isEmpty);
    await coordinator.stop();
    await expectLater(coordinator.pause(), throwsStateError);
    expect(coordinator.state.status, PlaybackSessionStatus.stopped);
    expect(coordinator.state.stopped, isTrue);
    await coordinator.dispose();
  });

  test(
    'failed seek and volume commands roll back optimistic snapshots',
    () async {
      final _FakeEngine engine = _FakeEngine()
        ..seekFailuresRemaining = 1
        ..volumeFailuresRemaining = 1;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();
      await coordinator.open(Uri.file('/clip.mp4'));
      engine.emit(
        const PlaybackSpikeSnapshot(
          position: Duration(seconds: 5),
          duration: Duration(seconds: 60),
          volume: 50,
        ),
      );

      await expectLater(
        coordinator.seekBy(const Duration(seconds: 10)),
        throwsStateError,
      );
      expect(coordinator.state.position, const Duration(seconds: 5));
      await coordinator.seekBy(const Duration(seconds: 10));
      expect(engine.seeks.last, const Duration(seconds: 15));

      await expectLater(coordinator.adjustVolumeBy(5), throwsStateError);
      expect(coordinator.state.volume, 50);
      await coordinator.adjustVolumeBy(5);
      expect(engine.volumes.last, 55);
      await coordinator.dispose();
    },
  );

  test('dispose failure closes public stream and can be retried', () async {
    final _FakeEngine engine = _FakeEngine()..disposeFailuresRemaining = 1;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();
    final Completer<void> statesClosed = Completer<void>();
    final List<PlaybackSessionStatus> statuses = [];
    coordinator.states.listen(
      (PlaybackSessionSnapshot state) => statuses.add(state.status),
      onDone: statesClosed.complete,
    );

    await expectLater(coordinator.dispose(), throwsStateError);
    await statesClosed.future;
    expect(statuses, contains(PlaybackSessionStatus.error));
    expect(coordinator.state.status, PlaybackSessionStatus.error);
    expect(engine.disposeCalls, 1);
    await expectLater(coordinator.play(), throwsStateError);

    await coordinator.dispose();
    expect(engine.disposeCalls, 2);
    await coordinator.dispose();
    expect(engine.disposeCalls, 2);
  });

  test('concurrent dispose callers wait for the same engine cleanup', () async {
    final _FakeEngine engine = _FakeEngine();
    final Completer<void> release = Completer<void>();
    engine.disposeGate = release;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    await coordinator.initialize();

    final Future<void> first = coordinator.dispose();
    final Future<void> second = coordinator.dispose();
    bool firstCompleted = false;
    unawaited(first.then((_) => firstCompleted = true));
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(engine.disposeCalls, 1);
    expect(firstCompleted, isFalse);

    release.complete();
    await Future.wait([first, second]);
    expect(engine.disposeCalls, 1);
  });

  test(
    'dispose waits for an in-flight command and rejects later commands',
    () async {
      final _FakeEngine engine = _FakeEngine();
      final Completer<void> openGate = Completer<void>();
      engine.openGate = openGate;
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      await coordinator.initialize();

      final Future<void> opening = coordinator.open(Uri.file('/clip.mp4'));
      await Future<void>.delayed(Duration.zero);
      expect(engine.calls, ['initialize', 'open']);

      final Future<void> closing = coordinator.dispose();
      final Future<void> commandAfterDispose = coordinator.play();
      await Future<void>.delayed(Duration.zero);
      expect(engine.disposeCalls, 0);
      expect(engine.calls, ['initialize', 'open']);

      openGate.complete();
      await opening;
      await closing;
      await expectLater(commandAfterDispose, throwsStateError);
      expect(engine.calls, ['initialize', 'open', 'dispose']);
      expect(engine.disposeCalls, 1);
    },
  );

  test('dispose cleans up an engine after initialization fails', () async {
    final _FakeEngine engine = _FakeEngine()..initializeFailuresRemaining = 1;
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);

    await expectLater(coordinator.initialize(), throwsStateError);
    await coordinator.dispose();

    expect(engine.calls, ['initialize', 'dispose']);
    expect(engine.disposeCalls, 1);
  });
}

final class _FakeSkipCatalog implements SkipSegmentCatalog {
  _FakeSkipCatalog(this.segments);
  final List<SkipSegment> segments;

  @override
  Future<SkipCatalogResult> lookup({
    required PlaybackEpisode episode,
    required MyAnimeListAnimeId malAnimeId,
  }) async => SkipCatalogSuccess(segments);
}

final class _FakeEngine implements PlaybackSpikeEngine {
  final StreamController<PlaybackSpikeSnapshot> _controller =
      StreamController<PlaybackSpikeSnapshot>.broadcast(sync: true);
  final List<String> calls = [];
  final List<Duration> seeks = [];
  final List<double> volumes = [];
  final List<Uri> openedSources = [];
  final List<PlaybackRequestHeaders> openedHttpHeaders = [];
  final Set<Uri> openFailureUris = {};
  bool emitSourceEvents = false;
  int disposeFailuresRemaining = 0;
  int initializeFailuresRemaining = 0;
  int openFailuresRemaining = 0;
  int seekFailuresRemaining = 0;
  int stopFailuresRemaining = 0;
  int volumeFailuresRemaining = 0;
  int disposeCalls = 0;
  int sourceGeneration = 0;
  Completer<void>? disposeGate;
  Completer<void>? openGate;
  Completer<void>? openStarted;
  Completer<void>? seekGate;
  Completer<void>? seekStarted;
  Completer<void>? stopGate;
  Completer<void>? stopStarted;

  @override
  Stream<PlaybackSpikeSnapshot> get snapshots => _controller.stream;
  void emit(PlaybackSpikeSnapshot state) => _controller.add(
    state.sourceGeneration == 0
        ? state.copyWith(sourceGeneration: sourceGeneration)
        : state,
  );

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    if (initializeFailuresRemaining > 0) {
      initializeFailuresRemaining--;
      throw StateError('injected initialization failure');
    }
  }

  @override
  Future<void> open(
    Uri source, {
    int sourceGeneration = 0,
    PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(),
  }) async {
    calls.add('open');
    openedSources.add(source);
    openedHttpHeaders.add(httpHeaders);
    this.sourceGeneration = sourceGeneration;
    if (openStarted case final Completer<void> started
        when !started.isCompleted) {
      started.complete();
    }
    await openGate?.future;
    if (openFailuresRemaining > 0) {
      openFailuresRemaining--;
      throw StateError('injected open failure');
    }
    if (openFailureUris.contains(source)) {
      throw StateError('injected open failure');
    }
    if (emitSourceEvents) {
      emit(
        PlaybackSpikeSnapshot(
          duration: const Duration(seconds: 120),
          sourceGeneration: sourceGeneration,
        ),
      );
    }
  }

  @override
  Future<void> play() async => calls.add('play');
  @override
  Future<void> pause() async => calls.add('pause');
  @override
  Future<void> seek(Duration position) async {
    calls.add('seek');
    seeks.add(position);
    if (seekStarted case final Completer<void> started
        when !started.isCompleted) {
      started.complete();
    }
    await seekGate?.future;
    if (seekFailuresRemaining > 0) {
      seekFailuresRemaining--;
      throw StateError('injected seek failure');
    }
    if (emitSourceEvents) {
      emit(
        PlaybackSpikeSnapshot(
          position: position,
          duration: const Duration(seconds: 120),
          sourceGeneration: sourceGeneration,
        ),
      );
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('volume');
    volumes.add(volume);
    if (volumeFailuresRemaining > 0) {
      volumeFailuresRemaining--;
      throw StateError('injected volume failure');
    }
  }

  @override
  Future<void> selectSubtitleTrack(String id) async =>
      calls.add('subtitle:$id');

  @override
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
  }) async => externalSubtitleDecision(hardsubStatus);

  @override
  Future<void> applySubtitleStyle(SubtitleStyle style) async =>
      calls.add('subtitle-style');

  @override
  Future<void> setSubtitleDelay(Duration delay) async =>
      calls.add('subtitle-delay');

  @override
  Future<void> stop() async {
    calls.add('stop');
    if (stopStarted case final Completer<void> started
        when !started.isCompleted) {
      started.complete();
    }
    await stopGate?.future;
    if (stopFailuresRemaining > 0) {
      stopFailuresRemaining--;
      throw StateError('injected stop failure');
    }
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    disposeCalls++;
    await disposeGate?.future;
    if (disposeFailuresRemaining > 0) {
      disposeFailuresRemaining--;
      throw StateError('injected dispose failure');
    }
    await _controller.close();
  }
}
