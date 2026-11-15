import 'dart:io';

import 'package:anime_app/app/player/player_quality_panel.dart';
import 'package:anime_app/application/player/spike_player_coordinator.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/domain/player/video_track_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'player_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quality menu shows only real tracks and retains media context', (
    tester,
  ) async {
    (String, int, int)? selected;
    Future<void> pump(List<VideoTrackInfo> tracks) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerQualityPanel(
              tracks: tracks,
              selectedId: '2',
              generation: 7,
              mediaContextRevision: 11,
              onSelected: (id, generation, revision) {
                selected = (id, generation, revision);
              },
            ),
          ),
        ),
      );
    }

    await pump(const [
      VideoTrackInfo(id: '1', width: 320, height: 180, codec: 'mpeg4'),
      VideoTrackInfo(id: '2', width: 160, height: 90, codec: 'mpeg4'),
    ]);
    await tester.tap(find.byKey(const ValueKey('player-quality')));
    await tester.pumpAndSettle();
    expect(find.textContaining('320×180'), findsOneWidget);
    expect(find.text('Automático · selección del motor'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('video-track-auto')));
    await tester.pumpAndSettle();
    expect(selected, ('auto', 7, 11));
    selected = null;
    await tester.tap(find.byKey(const ValueKey('player-quality')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('video-track-1')));
    await tester.pumpAndSettle();
    expect(selected, ('1', 7, 11));

    selected = null;
    await pump(const [VideoTrackInfo(id: '1', width: 320, height: 180)]);
    expect(find.byTooltip('Calidad fija · 320×180'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('player-quality')));
    await tester.pumpAndSettle();
    expect(find.text('Calidad fija · 320×180'), findsOneWidget);
    expect(find.byKey(const ValueKey('video-track-auto')), findsNothing);
    expect(find.textContaining('720p'), findsNothing);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });

  test(
    'real libmpv selects second video stream without reopening media',
    () async {
      final File baseline = resolveF2_2Fixture();
      final Directory root = baseline.parent.parent.parent.parent;
      final Directory fixtureDirectory = Directory(
        '${root.path}/.ai-local/player-quality',
      );
      final FileSystemEntityType fixtureDirectoryType =
          FileSystemEntity.typeSync(fixtureDirectory.path, followLinks: false);
      if (fixtureDirectoryType == FileSystemEntityType.link ||
          (fixtureDirectoryType != FileSystemEntityType.notFound &&
              fixtureDirectoryType != FileSystemEntityType.directory)) {
        throw StateError('The project-local quality fixture path is invalid.');
      }
      fixtureDirectory.createSync(recursive: true);
      final File fixture = File(
        '${fixtureDirectory.path}/two-video-audio-subtitle.mkv',
      );
      const String subtitleContent =
          '1\n00:00:00,000 --> 00:00:04,000\nQuality selector fixture\n';
      final File subtitle = File('${fixtureDirectory.path}/caption.srt');
      final FileSystemEntityType subtitleType = FileSystemEntity.typeSync(
        subtitle.path,
        followLinks: false,
      );
      if (subtitleType == FileSystemEntityType.link ||
          (subtitleType != FileSystemEntityType.notFound &&
              subtitleType != FileSystemEntityType.file)) {
        throw StateError('The project-local test subtitle is invalid.');
      }
      if (subtitleType == FileSystemEntityType.notFound) {
        subtitle.writeAsStringSync(subtitleContent);
      } else if (subtitle.readAsStringSync() != subtitleContent) {
        throw StateError('Refusing to overwrite an existing test subtitle.');
      }
      final FileSystemEntityType fixtureType = FileSystemEntity.typeSync(
        fixture.path,
        followLinks: false,
      );
      if (fixtureType == FileSystemEntityType.link ||
          (fixtureType != FileSystemEntityType.notFound &&
              fixtureType != FileSystemEntityType.file)) {
        throw StateError('The project-local quality fixture is invalid.');
      }
      if (fixtureType == FileSystemEntityType.notFound) {
        final ProcessResult generated = Process.runSync('ffmpeg', [
          '-y',
          '-hide_banner',
          '-loglevel',
          'error',
          '-f',
          'lavfi',
          '-i',
          'testsrc2=size=320x180:rate=20:duration=5',
          '-f',
          'lavfi',
          '-i',
          'anullsrc=channel_layout=stereo:sample_rate=48000',
          '-f',
          'srt',
          '-i',
          subtitle.path,
          '-filter_complex',
          '[0:v]split=2[large][small0];[small0]scale=160:90[small]',
          '-map',
          '[large]',
          '-map',
          '[small]',
          '-map',
          '1:a:0',
          '-map',
          '2:s:0',
          '-t',
          '5',
          '-c:v',
          'mpeg4',
          '-q:v',
          '8',
          '-c:a',
          'aac',
          '-metadata:s:a:0',
          'language=eng',
          '-c:s',
          'srt',
          '-metadata:s:s:0',
          'language=eng',
          fixture.path,
        ], workingDirectory: root.path);
        expect(generated.exitCode, 0, reason: '${generated.stderr}');
      }

      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      try {
        await coordinator.initialize();
        await coordinator.open(fixture.uri);
        await coordinator.play();
        await coordinator.states
            .firstWhere(
              (s) =>
                  s.videoTracks.length == 2 &&
                  s.playback.audioTracks.isNotEmpty &&
                  s.subtitleTracks.any(
                    (track) => track.id != 'auto' && track.id != 'no',
                  ),
            )
            .timeout(const Duration(seconds: 10));
        expect(
          coordinator.state.videoTracks,
          hasLength(2),
          reason: 'libmpv should expose both video streams after open',
        );
        final int generation = coordinator.state.sourceGeneration;
        expect(
          coordinator.state.videoTracks.map((t) => (t.width, t.height)),
          containsAll([(320, 180), (160, 90)]),
        );
        final String second = coordinator.state.videoTracks
            .singleWhere((track) => track.width == 160)
            .id;
        final String audioId = coordinator.state.playback.audioTracks
            .singleWhere((track) => track.id != 'auto' && track.id != 'no')
            .id;
        final String subtitleId = coordinator.state.subtitleTracks
            .singleWhere((track) => track.id != 'auto' && track.id != 'no')
            .id;
        await coordinator.selectAudioTrack(audioId, generation: generation);
        await coordinator.selectSubtitleTrack(subtitleId);
        await coordinator.states
            .firstWhere((s) => s.position > const Duration(milliseconds: 300))
            .timeout(const Duration(seconds: 10));
        await coordinator.pause();
        final Duration before = coordinator.state.observedPosition;
        final String audioBefore = coordinator.state.playback.selectedAudioId;
        final String subtitleBefore =
            coordinator.state.playback.selectedSubtitleId;
        await coordinator.selectVideoTrack(second, generation: generation);
        expect(engine.currentSnapshot.selectedVideoId, second);
        expect(
          coordinator.state.videoTracks
              .singleWhere((t) => t.id == second)
              .width,
          160,
        );
        expect(coordinator.state.sourceGeneration, generation);
        expect(coordinator.state.playing, isFalse);
        expect(coordinator.state.playback.selectedAudioId, audioBefore);
        expect(coordinator.state.playback.selectedSubtitleId, subtitleBefore);
        expect(
          (coordinator.state.observedPosition - before).abs(),
          lessThanOrEqualTo(const Duration(seconds: 1)),
        );
        await coordinator.selectVideoTrack('auto', generation: generation);
        expect(engine.currentSnapshot.selectedVideoId, 'auto');
        await expectLater(
          coordinator.selectVideoTrack('absent', generation: generation),
          throwsArgumentError,
        );
        await expectLater(
          coordinator.selectVideoTrack(second, generation: generation - 1),
          throwsStateError,
        );
        await coordinator.stop();
        expect(coordinator.state.videoTracks, isEmpty);
      } finally {
        await coordinator.dispose();
      }
    },
  );

  test(
    'Morevna reports its single source resolution as fixed quality',
    () async {
      final File baseline = resolveF2_2Fixture();
      final Directory root = baseline.parent.parent.parent.parent;
      final File media = File(
        '${root.path}/.ai-local/player-demo/real/episode-1.mkv',
      );
      expect(media.existsSync(), isTrue);
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      try {
        await coordinator.initialize();
        await coordinator.open(media.uri);
        final state = await coordinator.states
            .firstWhere((s) => s.videoTracks.isNotEmpty)
            .timeout(const Duration(seconds: 15));
        expect(state.videoTracks, hasLength(1));
        expect(
          (state.videoTracks.single.width, state.videoTracks.single.height),
          (534, 300),
        );
        await expectLater(
          coordinator.selectVideoTrack(
            'auto',
            generation: state.sourceGeneration,
          ),
          throwsArgumentError,
        );
      } finally {
        await coordinator.dispose();
      }
    },
    skip: Platform.environment['KONGROO_TEST_REAL_DEMO'] != '1'
        ? 'Set KONGROO_TEST_REAL_DEMO=1 after preparing the local Morevna DEMO.'
        : false,
  );
}
