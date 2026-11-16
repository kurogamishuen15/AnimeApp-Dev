import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_app/app/player/spike_player_module.dart';
import 'package:anime_app/application/player/external_subtitles/external_subtitle_service.dart';
import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/application/player/source_switching/playback_source_switch_service.dart';
import 'package:anime_app/application/player/spike_player_coordinator.dart';
import 'package:anime_app/data/opensubtitles/opensubtitles_client.dart';
import 'package:anime_app/data/player/engine/active_player_lease.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/data/player/providers/mock/mock_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_style.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_track_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'player_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final File fixture = resolveF2_2Fixture();
  final bool useRealDemo =
      Platform.environment['KONGROO_TEST_REAL_DEMO'] == '1';
  final String demoDirectory =
      '${fixture.parent.parent.parent.path}/player-demo/real';
  final File stressMedia = useRealDemo
      ? File('$demoDirectory/episode-1.mkv')
      : fixture;

  test(
    'Morevna selects published Spanish and English tracks in libmpv',
    () async {
      final engine = MediaKitSpikeEngine();
      final coordinator = SpikePlayerCoordinator(engine);
      try {
        await coordinator.initialize();
        final available = coordinator.states
            .firstWhere(
              (state) =>
                  state.subtitleTracks.any(
                    (track) => track.language == 'spa',
                  ) &&
                  state.subtitleTracks.any((track) => track.language == 'eng'),
            )
            .timeout(const Duration(seconds: 10));
        await coordinator.open(stressMedia.uri);
        await available;
        await coordinator.play();
        await coordinator.states
            .firstWhere((s) => s.observedPosition >= const Duration(seconds: 1))
            .timeout(const Duration(seconds: 10));
        await coordinator.pause();
        for (final language in ['spa', 'eng']) {
          final track = coordinator.state.subtitleTracks.singleWhere(
            (track) => track.language == language,
          );
          await coordinator.selectSubtitleTrack(track.id);
          expect(engine.currentSnapshot.selectedSubtitleId, track.id);
        }
        await coordinator.selectSubtitleTrack('no');
        expect(engine.currentSnapshot.selectedSubtitleId, 'no');
        await coordinator.applySubtitleStyle(SubtitleStyle(fontSize: 44));
        await coordinator.setSubtitleDelay(const Duration(milliseconds: 250));
        await coordinator.setSubtitleDelay(const Duration(milliseconds: -250));
        final Uri next = File('$demoDirectory/episode-2.mkv').uri;
        final moved = await coordinator.switchSource(
          next,
          referencePosition: Duration.zero,
          resumePlayback: false,
        );
        expect(moved.succeeded, isTrue, reason: moved.error);
        expect(coordinator.state.sourceUri, next);
        expect(
          coordinator.state.duration,
          greaterThan(const Duration(seconds: 625)),
        );
        expect(
          coordinator.state.playback.audioTracks.any(
            (track) => track.language == 'rus',
          ),
          isTrue,
        );
        final back = await coordinator.switchSource(
          stressMedia.uri,
          referencePosition: const Duration(seconds: 2),
          resumePlayback: false,
        );
        expect(back.succeeded, isTrue, reason: back.error);
        expect(coordinator.state.sourceUri, stressMedia.uri);
        expect(
          coordinator.state.playback.audioTracks.any(
            (track) => track.language == 'eng',
          ),
          isTrue,
        );
        final File sintel = File('$demoDirectory/sintel-trailer.ogv');
        if (Platform.environment['KONGROO_TEST_SINTEL'] == '1') {
          final changed = await coordinator.switchSource(
            sintel.uri,
            referencePosition: const Duration(seconds: 3),
            resumePlayback: false,
          );
          expect(changed.succeeded, isTrue, reason: changed.error);
          expect(
            coordinator.state.duration,
            greaterThan(const Duration(seconds: 50)),
          );
        }
      } finally {
        await coordinator.dispose();
      }
    },
    skip: !useRealDemo,
  );

  test('real libmpv completes twenty opens and releases the lease', () async {
    final int before = ProcessInfo.currentRss;
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    int peak = before;
    try {
      await engine.initialize();
      for (int generation = 1; generation <= 20; generation++) {
        final Future<PlaybackSpikeSnapshot> loaded = engine.snapshots
            .firstWhere(
              (snapshot) =>
                  snapshot.sourceGeneration == generation &&
                  snapshot.duration > Duration.zero,
            )
            .timeout(const Duration(seconds: 8));
        await engine.open(stressMedia.uri, sourceGeneration: generation);
        expect((await loaded).error, isNull);
        await engine.stop();
        expect(engine.currentSnapshot.stopped, isTrue);
        final int rss = ProcessInfo.currentRss;
        if (rss > peak) peak = rss;
      }
    } finally {
      await engine.dispose();
    }
    final MediaKitSpikeEngine next = MediaKitSpikeEngine();
    await next.dispose();
    stdout.writeln(
      '20 native opens: test process RSS bytes before=$before '
      'peak-after-stop=$peak after-dispose=${ProcessInfo.currentRss}',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'libmpv preserves a public Referer across open and replay after Stop',
    () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      var requestCount = 0;
      var validRefererSeen = false;
      var sensitiveHeaderSeen = false;
      final StreamSubscription<HttpRequest> requests = server.listen((
        HttpRequest request,
      ) async {
        requestCount++;
        validRefererSeen =
            validRefererSeen ||
            request.headers.value(HttpHeaders.refererHeader) ==
                'https://www.animegg.org/';
        sensitiveHeaderSeen =
            sensitiveHeaderSeen ||
            request.headers.value(HttpHeaders.cookieHeader) != null ||
            request.headers.value(HttpHeaders.authorizationHeader) != null;
        if (request.headers.value(HttpHeaders.refererHeader) !=
            'https://www.animegg.org/') {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          return;
        }
        final int fileLength = fixture.lengthSync();
        request.response.headers.set('accept-ranges', 'bytes');
        final String? range = request.headers.value(HttpHeaders.rangeHeader);
        if (range != null) {
          final RegExpMatch? match = RegExp(r'^bytes=(\d+)-(\d*)$')
              .firstMatch(range);
          final int? start = match == null
              ? null
              : int.tryParse(match.group(1)!);
          final int? requestedEnd = match == null || match.group(2)!.isEmpty
              ? fileLength - 1
              : int.tryParse(match.group(2)!);
          if (start == null ||
              requestedEnd == null ||
              start < 0 ||
              start >= fileLength ||
              requestedEnd < start) {
            request.response.statusCode =
                HttpStatus.requestedRangeNotSatisfiable;
            request.response.headers.set(
              'content-range',
              'bytes */$fileLength',
            );
            await request.response.close();
            return;
          }
          final int end = requestedEnd >= fileLength
              ? fileLength - 1
              : requestedEnd;
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set(
            'content-range',
            'bytes $start-$end/$fileLength',
          );
          request.response.headers.contentType = ContentType.binary;
          request.response.contentLength = end - start + 1;
          if (request.method != 'HEAD') {
            await request.response.addStream(fixture.openRead(start, end + 1));
          }
          await request.response.close();
          return;
        }
        request.response.headers.contentType = ContentType.binary;
        request.response.contentLength = fileLength;
        if (request.method != 'HEAD') {
          await request.response.addStream(fixture.openRead());
        }
        await request.response.close();
      });
      final Uri source = Uri.http('127.0.0.1:${server.port}', '/episode.mkv');
      final PlaybackRequestHeaders headers = PlaybackRequestHeaders({
        'Referer': 'https://www.animegg.org/',
      });
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine(
        demoSources: {source},
      );
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(
        engine,
        demoSources: {source},
      );
      try {
        await coordinator.initialize();
        await coordinator.open(source, httpHeaders: headers);
        stdout.writeln(
          'Referer media open completed; requests=$requestCount; '
          'expected_referer_seen=$validRefererSeen',
        );
        await coordinator.play();
        final PlaybackSessionSnapshot firstPlayback;
        try {
          firstPlayback = await coordinator.states
              .firstWhere(
                (snapshot) =>
                    snapshot.position > Duration.zero || snapshot.error != null,
              )
              .timeout(const Duration(seconds: 12));
        } on Object catch (error) {
          stdout.writeln(
            'Referer media failed=$error; requests=$requestCount; '
            'expected_referer_seen=$validRefererSeen; '
            'engine_error=${engine.currentSnapshot.error != null}',
          );
          rethrow;
        }
        stdout.writeln('Referer media error=${firstPlayback.error != null}');
        expect(firstPlayback.error, isNull);
        stdout.writeln(
          'Referer media advanced=${firstPlayback.position.inMilliseconds}ms; '
          'requests=$requestCount; expected_referer_seen=$validRefererSeen',
        );
        await coordinator.stop();
        await coordinator.play();
        await coordinator.states
            .firstWhere(
              (snapshot) =>
                  snapshot.position > Duration.zero || snapshot.error != null,
            )
            .timeout(const Duration(seconds: 12));
        expect(validRefererSeen, isTrue);
        expect(sensitiveHeaderSeen, isFalse);
        expect(requestCount, greaterThanOrEqualTo(2));
      } finally {
        await coordinator.dispose();
        await requests.cancel();
        await server.close(force: true);
      }
    },
    skip: Platform.environment['KONGROO_TEST_HTTP_REFERER'] != '1',
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test('real libmpv uses DEMO HTTP ranges and rolls back a 503', () async {
    final Directory root = fixture.parent.parent.parent.parent;
    final Process server = await Process.start('python3', [
      '-u',
      '-c',
      """
import sys
sys.path.insert(0, 'tools/player')
import os
from run_player_demo import generate, mirror, prepare_real_demo
directory = prepare_real_demo() if os.environ.get('KONGROO_TEST_REAL_DEMO') == '1' else generate()
with mirror(directory) as a, mirror(directory) as b, mirror(directory, True) as c:
    print(a, b, c, flush=True)
    sys.stdin.readline()
""",
    ], workingDirectory: root.path);
    final errors = StringBuffer();
    final stderr = server.stderr.transform(utf8.decoder).listen(errors.write);
    try {
      final line = await server.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 30));
      final List<Uri> sources = [
        for (final String port in line.split(' '))
          Uri.http('127.0.0.1:$port', '/episode-1.mkv'),
      ];
      final ProcessResult rangeCheck = await Process.run('python3', [
        '-c',
        """
import sys, urllib.request
for url in sys.argv[1:]:
    request = urllib.request.Request(url, headers={'Range': 'bytes=0-31'})
    with urllib.request.urlopen(request, timeout=3) as response:
        assert response.status == 206 and len(response.read()) == 32
""",
        ...sources.take(2).map((uri) => uri.toString()),
      ]);
      expect(rangeCheck.exitCode, 0, reason: '${rangeCheck.stderr}');
      final engine = MediaKitSpikeEngine(demoSources: sources.toSet());
      final coordinator = SpikePlayerCoordinator(
        engine,
        demoSources: sources.toSet(),
      );
      try {
        await coordinator.initialize();
        await coordinator.open(sources.first);
        await coordinator.play();
        await coordinator.states
            .firstWhere(
              (snapshot) =>
                  snapshot.observedPosition > const Duration(seconds: 2),
            )
            .timeout(const Duration(seconds: 12));
        // Reproduce the owner-reported position in Morevna episode 3, then
        // exercise the complete command path on each source transition.
        final Duration reportedPosition = Duration(
          seconds: useRealDemo ? 40 : 12,
        );
        await coordinator.seek(reportedPosition);
        await coordinator.states
            .firstWhere(
              (snapshot) =>
                  snapshot.sourceGeneration ==
                      coordinator.state.sourceGeneration &&
                  snapshot.observedPosition >= reportedPosition,
            )
            .timeout(const Duration(seconds: 12));
        String? subtitleLanguage() => coordinator.state.subtitleTracks
            .where((track) => track.id == coordinator.state.selectedSubtitleId)
            .firstOrNull
            ?.language;
        String? audioLanguage() => coordinator.state.playback.audioTracks
            .where(
              (track) => track.id == coordinator.state.playback.selectedAudioId,
            )
            .firstOrNull
            ?.language;
        if (useRealDemo) {
          final subtitle = coordinator.state.subtitleTracks.singleWhere(
            (track) => track.language == 'spa',
          );
          final audio = coordinator.state.playback.audioTracks.singleWhere(
            (track) => track.language == 'eng',
          );
          await coordinator.selectSubtitleTrack(subtitle.id);
          await coordinator.selectAudioTrack(
            audio.id,
            generation: coordinator.state.sourceGeneration,
          );
        }
        final moved = await coordinator.switchSource(
          sources[1],
          preserveTracks: useRealDemo,
        );
        expect(moved.succeeded, isTrue, reason: moved.error);
        expect(moved.referencePosition, greaterThanOrEqualTo(reportedPosition));
        expect(
          moved.positionDelta,
          lessThanOrEqualTo(const Duration(seconds: 2)),
        );
        expect(coordinator.state.playing, isTrue);
        expect(coordinator.state.error, isNull);
        final movedBack = await coordinator.switchSource(
          sources.first,
          preserveTracks: useRealDemo,
        );
        expect(movedBack.succeeded, isTrue, reason: movedBack.error);
        expect(
          movedBack.positionDelta,
          lessThanOrEqualTo(const Duration(seconds: 2)),
        );
        expect(coordinator.state.playing, isTrue);
        await coordinator.pause();
        final Duration pausedPosition = coordinator.state.observedPosition;
        final pausedMove = await coordinator.switchSource(
          sources[1],
          resumePlayback: false,
          preserveTracks: useRealDemo,
        );
        expect(pausedMove.succeeded, isTrue, reason: pausedMove.error);
        expect(coordinator.state.playing, isFalse);
        expect(
          pausedMove.positionDelta,
          lessThanOrEqualTo(const Duration(seconds: 2)),
        );
        expect(
          (pausedMove.observedPosition! - pausedPosition).abs(),
          lessThanOrEqualTo(const Duration(seconds: 2)),
        );
        await coordinator.play();
        expect(coordinator.state.playing, isTrue);
        final beforeRelativeSeeks = coordinator.state.observedPosition;
        await coordinator.seekBy(const Duration(seconds: -10));
        final Duration expectedBack =
            beforeRelativeSeeks - const Duration(seconds: 10);
        final backSnapshot = await coordinator.states
            .firstWhere(
              (snapshot) =>
                  (snapshot.observedPosition - expectedBack).abs() <=
                  const Duration(seconds: 2),
            )
            .timeout(const Duration(seconds: 12));
        expect(backSnapshot.observedPosition, lessThan(beforeRelativeSeeks));
        await coordinator.seekBy(const Duration(seconds: 10));
        await coordinator.states
            .firstWhere(
              (snapshot) =>
                  snapshot.observedPosition >=
                  beforeRelativeSeeks - const Duration(seconds: 2),
            )
            .timeout(const Duration(seconds: 12));
        expect(coordinator.state.error, isNull);
        if (useRealDemo) {
          expect(subtitleLanguage(), 'spa');
          expect(audioLanguage(), 'eng');
        }
        for (final Uri target in [sources.first, sources[1], sources.first]) {
          final repeated = await coordinator.switchSource(
            target,
            preserveTracks: useRealDemo,
          );
          expect(repeated.succeeded, isTrue, reason: repeated.error);
          expect(
            repeated.positionDelta,
            lessThanOrEqualTo(const Duration(seconds: 2)),
          );
          expect(coordinator.state.sourceUri, target);
          expect(coordinator.state.playing, isTrue);
          expect(coordinator.state.error, isNull);
        }
        final failed = await coordinator.switchSource(
          sources.last,
          preserveTracks: useRealDemo,
        );
        expect(
          failed.disposition,
          PlaybackSourceSwitchDisposition.targetFailedPreviousRestored,
        );
        expect(coordinator.state.sourceUri, sources.first);
        expect(coordinator.state.playing, isTrue);
        expect(coordinator.state.error, isNull);
        if (useRealDemo) {
          expect(subtitleLanguage(), 'spa');
          expect(audioLanguage(), 'eng');
        }
      } finally {
        await coordinator.dispose();
      }
    } finally {
      await server.stdin.close();
      expect(
        await server.exitCode.timeout(const Duration(seconds: 15)),
        0,
        reason: errors.toString(),
      );
      await stderr.cancel();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'real libmpv selects three embedded audio languages without reopen',
    () async {
      final Directory root = fixture.parent.parent.parent.parent;
      final ProcessResult generated = await Process.run('python3', [
        'tools/player/generate_player_demo.py',
      ], workingDirectory: root.path);
      expect(generated.exitCode, 0, reason: '${generated.stderr}');
      final File media = File(
        '${root.path}/.ai-local/player-demo/episode-1.mkv',
      );
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      try {
        await coordinator.initialize();
        final Future<PlaybackSpikeSnapshot> discovered = engine.snapshots
            .firstWhere(
              (snapshot) =>
                  snapshot.audioTracks.any((track) => track.language == 'jpn'),
            )
            .timeout(const Duration(seconds: 10));
        await coordinator.open(media.uri);
        await discovered;
        await coordinator.play();
        await coordinator.states
            .firstWhere((s) => s.observedPosition > const Duration(seconds: 2))
            .timeout(const Duration(seconds: 10));
        final int generation = coordinator.state.sourceGeneration;
        final Duration position = coordinator.state.observedPosition;
        for (final language in ['spa', 'jpn', 'eng']) {
          if (language == 'jpn') await coordinator.pause();
          final track = engine.currentSnapshot.audioTracks.singleWhere(
            (track) => track.language == language,
          );
          await coordinator.selectAudioTrack(track.id, generation: generation);
          expect(engine.currentSnapshot.selectedAudioId, track.id);
          expect(
            engine.currentSnapshot.position,
            greaterThan(position - const Duration(seconds: 1)),
          );
          expect(coordinator.state.sourceGeneration, generation);
        }
        await expectLater(
          coordinator.selectAudioTrack('missing', generation: generation),
          throwsArgumentError,
        );
      } finally {
        await coordinator.dispose();
      }
    },
  );

  test(
    'real libmpv opens, advances, pauses, seeks, stops and disposes',
    () async {
      expect(await fixture.exists(), isTrue, reason: fixture.path);
      // Native playback is real; compositor presentation is verified by the
      // separately launched Linux spike window.
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final List<String> errors = [];
      final Completer<void> advanced = Completer<void>();
      final Completer<void> seekObserved = Completer<void>();
      bool seekRequested = false;
      Duration seekBaseline = Duration.zero;
      Duration? observedSeekPosition;
      final StreamSubscription<dynamic> sub = engine.snapshots.listen((s) {
        if (s.error != null) errors.add(s.error!);
        if (s.position > const Duration(milliseconds: 700) &&
            !advanced.isCompleted) {
          advanced.complete();
        }
        if (seekRequested &&
            s.position >= const Duration(milliseconds: 5500) &&
            s.position <= const Duration(seconds: 7) &&
            s.position - seekBaseline > const Duration(seconds: 3) &&
            !seekObserved.isCompleted) {
          observedSeekPosition = s.position;
          seekObserved.complete();
        }
      });
      try {
        expect(
          () => MediaKitSpikeEngine(),
          throwsStateError,
          reason: 'A second native Player must not become active concurrently.',
        );
        await engine.initialize();
        await expectLater(
          engine.open(Uri.parse('https://example.invalid/video.mp4')),
          throwsArgumentError,
        );
        await _awaitNative(
          engine.open(fixture.uri),
          const Duration(seconds: 8),
        );
        await _awaitNative(engine.play(), const Duration(seconds: 3));
        await advanced.future.timeout(const Duration(seconds: 6));
        expect(engine.currentSnapshot.playing, isTrue);
        expect(
          engine.currentSnapshot.position,
          lessThan(const Duration(seconds: 2)),
        );
        await _awaitNative(engine.pause(), const Duration(seconds: 3));
        final Duration pausedAt = engine.currentSnapshot.position;
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(
          engine.currentSnapshot.position.inMilliseconds -
              pausedAt.inMilliseconds,
          lessThan(350),
        );
        seekBaseline = engine.currentSnapshot.position;
        seekRequested = true;
        await _awaitNative(
          engine.seek(const Duration(seconds: 6)),
          const Duration(seconds: 3),
        );
        await seekObserved.future.timeout(const Duration(seconds: 3));
        expect(observedSeekPosition, isNotNull);
        expect(
          observedSeekPosition,
          greaterThan(seekBaseline + const Duration(seconds: 3)),
        );
        expect(
          observedSeekPosition,
          greaterThanOrEqualTo(const Duration(milliseconds: 5500)),
        );
        expect(
          observedSeekPosition,
          lessThanOrEqualTo(const Duration(seconds: 7)),
        );
        expect(errors, isEmpty);
        await _awaitNative(engine.stop(), const Duration(seconds: 3));
        expect(engine.currentSnapshot.playing, isFalse);
      } finally {
        await sub.cancel();
        await _awaitNative(engine.dispose(), const Duration(seconds: 8));
        await engine.dispose();
      }
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test(
    'real libmpv accepts player-local volume and emits the observed value',
    () async {
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final Completer<void> volumeObserved = Completer<void>();
      final StreamSubscription<dynamic> subscription = engine.snapshots.listen((
        s,
      ) {
        if ((s.volume - 42).abs() < 0.01 && !volumeObserved.isCompleted) {
          volumeObserved.complete();
        }
      });
      try {
        await engine.initialize();
        await _awaitNative(engine.setVolume(42), const Duration(seconds: 3));
        await volumeObserved.future.timeout(const Duration(seconds: 3));
        expect(engine.currentSnapshot.volume, 42);
        await expectLater(
          engine.setVolume(101),
          throwsRangeError,
          reason: 'The media adapter rejects values beyond 0–100.',
        );
      } finally {
        await subscription.cancel();
        await _awaitNative(engine.dispose(), const Duration(seconds: 8));
      }
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'real libmpv discovers and selects internal subtitles and applies style',
    () async {
      final File subtitleFixture = resolveF2_6SubtitleFixture();
      final File movTextFixture = resolveF2_6MovTextFixture();
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final Completer<void> tracksReady = Completer<void>();
      final Completer<void> movTextReady = Completer<void>();
      final StreamSubscription<dynamic> subscription = engine.snapshots.listen((
        PlaybackSpikeSnapshot snapshot,
      ) {
        if (snapshot.subtitleTracks
                    .where(
                      (SubtitleTrackInfo track) =>
                          track.kind == SubtitleTrackKind.embedded,
                    )
                    .length >=
                2 &&
            !tracksReady.isCompleted) {
          tracksReady.complete();
        }
        if (snapshot.subtitleTracks.any(
              (SubtitleTrackInfo track) => track.codec == 'mov_text',
            ) &&
            !movTextReady.isCompleted) {
          movTextReady.complete();
        }
      });
      try {
        await engine.initialize();
        await _awaitNative(
          engine.open(subtitleFixture.uri),
          const Duration(seconds: 8),
        );
        await tracksReady.future.timeout(const Duration(seconds: 5));
        final List<SubtitleTrackInfo> tracks =
            engine.currentSnapshot.subtitleTracks;
        final List<SubtitleTrackInfo> embedded = tracks
            .where(
              (SubtitleTrackInfo track) =>
                  track.kind == SubtitleTrackKind.embedded,
            )
            .toList();
        expect(embedded, hasLength(3));
        expect(
          embedded.map((SubtitleTrackInfo track) => track.codec),
          containsAll(<String?>['subrip', 'ass']),
        );
        expect(
          embedded.map((SubtitleTrackInfo track) => track.language),
          containsAll(<String?>['eng', 'jpn', null]),
        );
        expect(
          embedded
              .firstWhere((SubtitleTrackInfo track) => track.language == null)
              .label,
          isNotEmpty,
        );

        final SubtitleTrackInfo english = embedded.firstWhere(
          (SubtitleTrackInfo track) => track.language == 'eng',
        );
        await engine.selectSubtitleTrack(english.id);
        expect(engine.currentSnapshot.selectedSubtitleId, english.id);
        await engine.selectSubtitleTrack('no');
        expect(engine.currentSnapshot.selectedSubtitleId, 'no');
        final SubtitleTrackInfo japanese = embedded.firstWhere(
          (SubtitleTrackInfo track) => track.language == 'jpn',
        );
        await engine.selectSubtitleTrack(japanese.id);
        expect(engine.currentSnapshot.selectedSubtitleId, japanese.id);

        await engine.applySubtitleStyle(
          SubtitleStyle(
            fontFamily: 'Noto Sans',
            fontSize: 42,
            color: '#FFF2F2F2',
            outlineColor: '#FF101010',
            outlineSize: 2.25,
            bold: true,
            position: 90,
            overrideAssStyles: true,
          ),
        );
        expect(
          double.parse(
            await engine.subtitlePropertyForTesting('sub-font-size'),
          ),
          42,
        );
        expect(
          (await engine.subtitlePropertyForTesting('sub-color')).toUpperCase(),
          '#FFF2F2F2',
        );
        expect(
          await engine.subtitlePropertyForTesting('sub-ass-override'),
          'force',
        );
        await engine.setSubtitleDelay(const Duration(milliseconds: 750));
        expect(
          double.parse(await engine.subtitlePropertyForTesting('sub-delay')),
          closeTo(0.75, 0.000001),
        );
        await engine.setSubtitleDelay(const Duration(milliseconds: -500));
        expect(
          double.parse(await engine.subtitlePropertyForTesting('sub-delay')),
          closeTo(-0.5, 0.000001),
        );
        await expectLater(
          engine.setSubtitleDelay(const Duration(seconds: 31)),
          throwsRangeError,
        );

        final File external = File(
          '${subtitleFixture.parent.path}/local-external-subtitle-$pid.srt',
        );
        await external.writeAsString(
          '1\n00:00:00,500 --> 00:00:02,500\nExternal SRT\n',
        );
        try {
          await expectLater(
            engine.loadExternalSubtitle(
              Uri.file('${subtitleFixture.parent.path}/unsupported.idx'),
              hardsubStatus: HardsubStatus.unknown,
            ),
            throwsArgumentError,
          );
          await expectLater(
            engine.loadExternalSubtitle(
              external.uri,
              hardsubStatus: HardsubStatus.confirmedPresent,
            ),
            throwsStateError,
          );
          expect(
            await engine.loadExternalSubtitle(
              external.uri,
              hardsubStatus: HardsubStatus.unknown,
              language: 'en',
            ),
            ExternalSubtitleDecision.allowedWithUncertainty,
          );
          expect(
            engine.currentSnapshot.subtitleTracks.any(
              (SubtitleTrackInfo track) =>
                  track.kind == SubtitleTrackKind.external,
            ),
            isTrue,
          );
        } finally {
          await external.delete();
        }

        await _awaitNative(
          engine.open(movTextFixture.uri),
          const Duration(seconds: 8),
        );
        await movTextReady.future.timeout(const Duration(seconds: 5));
        expect(
          engine.currentSnapshot.subtitleTracks.any(
            (SubtitleTrackInfo track) =>
                track.kind == SubtitleTrackKind.embedded &&
                track.codec == 'mov_text',
          ),
          isTrue,
        );
      } finally {
        await subscription.cancel();
        await _awaitNative(engine.dispose(), const Duration(seconds: 8));
      }
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

  test(
    'real libmpv loads an OpenSubtitles fixture downloaded to local storage',
    () async {
      final Directory storage = await Directory.systemTemp.createTemp(
        'kongroo-external-subtitle-integration-',
      );
      final _OpenSubtitlesFixtureAdapter adapter =
          _OpenSubtitlesFixtureAdapter();
      final Dio dio = Dio()..httpClientAdapter = adapter;
      final OpenSubtitlesClient catalog = OpenSubtitlesClient(
        apiKey: () async => 'test-only-placeholder',
        dio: dio,
        storageDirectory: storage,
      );
      final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
      final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
      try {
        await coordinator.initialize();
        await _awaitNative(
          coordinator.open(resolveF2_6SubtitleFixture().uri),
          const Duration(seconds: 8),
        );
        var rollbackDisposals = 0;
        await expectLater(
          SpikePlayerModule.open(
            resolveF2_2Fixture(),
            externalSubtitleCatalog: catalog,
            disposeExternalSubtitleCatalog: () => rollbackDisposals++,
          ),
          throwsA(isA<ActivePlayerLeaseInUse>()),
        );
        expect(rollbackDisposals, 1);
        final ExternalSubtitleService service = ExternalSubtitleService(
          catalog: catalog,
          loader: coordinator,
        );
        final ExternalSubtitleResult<List<ExternalSubtitleCandidate>> search =
            await service.search(ExternalSubtitleQuery(query: 'episode 1'));
        expect(
          search,
          isA<ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>>(),
        );
        final ExternalSubtitleCandidate candidate =
            (search as ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>)
                .value
                .single;
        final ExternalSubtitleResult<ExternalSubtitleLoadResult> loaded =
            await service.downloadAndLoad(
              candidate,
              hardsubStatus: HardsubStatus.unknown,
            );
        expect(
          loaded,
          isA<ExternalSubtitleSuccess<ExternalSubtitleLoadResult>>(),
        );
        final List<SubtitleTrackInfo> externalTracks = coordinator
            .state
            .subtitleTracks
            .where(
              (SubtitleTrackInfo track) =>
                  track.kind == SubtitleTrackKind.external,
            )
            .toList();
        expect(externalTracks, hasLength(1));
        expect(coordinator.state.selectedSubtitleId, externalTracks.single.id);
        final ExternalSubtitleDownload download =
            (loaded as ExternalSubtitleSuccess<ExternalSubtitleLoadResult>)
                .value
                .download;
        expect(download.uri.scheme, 'file');
        expect(
          await File.fromUri(download.uri).readAsString(),
          contains('Fixture OpenSubtitles SRT'),
        );
        expect(
          adapter.requests.map((RequestOptions request) => request.method),
          ['GET', 'POST', 'GET'],
        );
      } finally {
        await _awaitNative(coordinator.dispose(), const Duration(seconds: 8));
        dio.close(force: true);
        await storage.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test('coordinator source generations reach real libmpv snapshots', () async {
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    final Completer<void> advanced = Completer<void>();
    final StreamSubscription<dynamic> subscription = coordinator.states.listen((
      state,
    ) {
      if (state.position > const Duration(milliseconds: 500) &&
          !advanced.isCompleted) {
        advanced.complete();
      }
    });
    try {
      await coordinator.initialize();
      await _awaitNative(
        coordinator.open(fixture.uri),
        const Duration(seconds: 8),
      );
      final int firstGeneration = coordinator.state.sourceGeneration;
      await _awaitNative(
        coordinator.open(fixture.uri),
        const Duration(seconds: 8),
      );
      final int secondGeneration = coordinator.state.sourceGeneration;
      expect(secondGeneration, firstGeneration + 1);

      await _awaitNative(coordinator.play(), const Duration(seconds: 3));
      await advanced.future.timeout(const Duration(seconds: 6));
      expect(coordinator.state.sourceGeneration, secondGeneration);
      expect(
        coordinator.state.position,
        greaterThan(const Duration(milliseconds: 500)),
      );
    } finally {
      await subscription.cancel();
      await _awaitNative(coordinator.dispose(), const Duration(seconds: 8));
    }
  }, timeout: const Timeout(Duration(seconds: 35)));

  test('real libmpv restores position across an equivalent local source switch', () async {
    expect(await fixture.exists(), isTrue, reason: fixture.path);
    final Directory base = Directory('../.ai-local/f2.7/integration');
    await base.create(recursive: true);
    final Directory temporary = await base.createTemp('source-switch-');
    final File alternate = await fixture.copy(
      '${temporary.path}/alternate.mp4',
    );
    final PlaybackProviderId providerId = PlaybackProviderId('fixture');
    final MockPlaybackProvider provider = MockPlaybackProvider(
      id: providerId,
      scenario: MockPlaybackScenario.alternatives,
      serverEndpoints: {
        'primary-server': fixture.uri,
        'backup-server': alternate.absolute.uri,
        'english-server': alternate.absolute.uri,
      },
    );
    final PlaybackProviderManager manager = PlaybackProviderManager(
      providers: [PlaybackProviderRegistration(provider: provider)],
      videoHostResolvers: [
        PlaybackVideoHostResolverRegistration(resolver: provider),
      ],
      clock: () => DateTime.utc(2026),
    );
    final PlaybackEpisode episode = PlaybackEpisode(
      animeId: AnimeId('fixture-anime'),
      episodeNumber: 1,
    );
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(engine);
    PlaybackSourceSwitchService? service;
    try {
      await coordinator.initialize();
      await _awaitNative(
        coordinator.open(fixture.uri),
        const Duration(seconds: 8),
      );
      await _awaitNative(coordinator.play(), const Duration(seconds: 3));
      await _waitForCoordinatorPosition(
        coordinator,
        const Duration(milliseconds: 800),
      );
      final Duration reference = coordinator.state.position;
      service = PlaybackSourceSwitchService(
        manager: manager,
        episode: episode,
        coordinator: coordinator,
        initialSource: ResolvedPlaybackStream(
          providerId: providerId,
          sourceId: 'source-japanese-1080p',
          serverId: 'primary-server',
          uri: fixture.uri,
        ),
      );

      final PlaybackSourceSwitchAttempt result = await service.switchToNext();

      expect(
        result.status,
        PlaybackSourceSwitchAttemptStatus.switched,
        reason:
            'switch=${result.status}, service=${service.state.error}, '
            'attempted=${provider.attemptedServers}, calls=${provider.resolveCalls}, '
            'diagnostics=${manager.diagnostics.map((d) => d.resolutionLastFailure).toList()}, '
            'session=${coordinator.state.status}/${coordinator.state.error}, '
            'uri=${coordinator.state.sourceUri}, duration=${coordinator.state.duration}, '
            'position=${coordinator.state.position}',
      );
      expect(result.selected?.serverId, 'backup-server');
      expect(result.positionDelta, isNotNull);
      expect(
        result.positionDelta!.abs(),
        lessThanOrEqualTo(const Duration(seconds: 2)),
      );
      expect(coordinator.state.sourceUri, alternate.absolute.uri);
      expect(coordinator.state.playing, isTrue);
      expect(
        (coordinator.state.position - reference).abs(),
        lessThanOrEqualTo(const Duration(seconds: 2)),
      );
      final Duration afterSwitch = coordinator.state.position;
      await _waitForCoordinatorPosition(
        coordinator,
        afterSwitch + const Duration(milliseconds: 300),
      );
      expect(coordinator.state.playing, isTrue);
    } finally {
      await service?.dispose();
      await _awaitNative(coordinator.dispose(), const Duration(seconds: 8));
      await temporary.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('play after pause resumes the loaded media position', () async {
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    try {
      await engine.initialize();
      await _awaitNative(engine.open(fixture.uri), const Duration(seconds: 8));
      await _awaitNative(engine.play(), const Duration(seconds: 3));
      await _waitForPosition(engine, const Duration(milliseconds: 700));
      await _awaitNative(engine.pause(), const Duration(seconds: 3));
      final Duration pausedAt = engine.currentSnapshot.position;
      expect(engine.currentSnapshot.stopped, isFalse);
      await _awaitNative(engine.play(), const Duration(seconds: 3));
      await _waitForPosition(
        engine,
        pausedAt + const Duration(milliseconds: 300),
      );
      expect(engine.currentSnapshot.position, greaterThan(pausedAt));
      expect(engine.currentSnapshot.stopped, isFalse);
    } finally {
      await _awaitNative(engine.dispose(), const Duration(seconds: 8));
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('stop can reopen and play the same real fixture', () async {
    expect(await fixture.exists(), isTrue, reason: fixture.path);
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    final Completer<void> advancedAfterReopen = Completer<void>();
    final Completer<void> stopped = Completer<void>();
    Duration reopenBaseline = Duration.zero;
    bool waitingForReopenedPlayback = false;
    bool stopping = false;
    final StreamSubscription<dynamic> sub = engine.snapshots.listen((snapshot) {
      if (stopping && !snapshot.playing && !stopped.isCompleted) {
        stopped.complete();
      }
      if (waitingForReopenedPlayback &&
          snapshot.playing &&
          snapshot.position >
              reopenBaseline + const Duration(milliseconds: 500)) {
        if (!advancedAfterReopen.isCompleted) advancedAfterReopen.complete();
      }
    });
    try {
      await engine.initialize();
      await _awaitNative(engine.open(fixture.uri), const Duration(seconds: 8));
      await _awaitNative(engine.play(), const Duration(seconds: 3));
      await _waitForPosition(engine, const Duration(milliseconds: 500));
      stopping = true;
      await _awaitNative(engine.stop(), const Duration(seconds: 3));
      await stopped.future.timeout(const Duration(seconds: 3));
      expect(engine.currentSnapshot.playing, isFalse);

      await _awaitNative(engine.open(fixture.uri), const Duration(seconds: 8));
      reopenBaseline = engine.currentSnapshot.position;
      waitingForReopenedPlayback = true;
      await _awaitNative(engine.play(), const Duration(seconds: 3));
      await advancedAfterReopen.future.timeout(const Duration(seconds: 6));
      expect(engine.currentSnapshot.playing, isTrue);
      expect(engine.currentSnapshot.error, isNull);
    } finally {
      await sub.cancel();
      await _awaitNative(engine.dispose(), const Duration(seconds: 8));
    }
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('stop then play reloads the retained real source repeatedly', () async {
    expect(await fixture.exists(), isTrue, reason: fixture.path);
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    Completer<Duration>? restartedAt;
    bool observeRestart = false;
    final StreamSubscription<dynamic> subscription = engine.snapshots.listen((
      s,
    ) {
      final Completer<Duration>? signal = restartedAt;
      if (observeRestart &&
          s.playing &&
          signal != null &&
          !signal.isCompleted) {
        signal.complete(s.position);
      }
    });
    try {
      await engine.initialize();
      await _awaitNative(engine.open(fixture.uri), const Duration(seconds: 8));
      await _awaitNative(engine.play(), const Duration(seconds: 3));
      await _waitForPosition(engine, const Duration(milliseconds: 500));
      for (int cycle = 0; cycle < 2; cycle++) {
        await _awaitNative(engine.stop(), const Duration(seconds: 3));
        expect(engine.currentSnapshot.playing, isFalse);
        expect(engine.currentSnapshot.stopped, isTrue);
        expect(engine.currentSnapshot.position, Duration.zero);
        // Repeated Stop remains idempotent and must retain the logical source.
        await _awaitNative(engine.stop(), const Duration(seconds: 3));
        expect(engine.currentSnapshot.stopped, isTrue);
        expect(engine.currentSnapshot.position, Duration.zero);

        final Completer<Duration> restartSignal = Completer<Duration>();
        restartedAt = restartSignal;
        observeRestart = true;
        await _awaitNative(engine.play(), const Duration(seconds: 8));
        final Duration startPosition = await restartSignal.future.timeout(
          const Duration(seconds: 3),
        );
        observeRestart = false;
        expect(
          startPosition,
          lessThan(const Duration(seconds: 1)),
          reason: 'Each Stop → Play must restart near media time zero.',
        );
        await _waitForPosition(engine, const Duration(milliseconds: 500));
        expect(engine.currentSnapshot.playing, isTrue);
        expect(engine.currentSnapshot.stopped, isFalse);
        expect(
          engine.currentSnapshot.position,
          greaterThan(const Duration(milliseconds: 500)),
        );
      }
      expect(engine.currentSnapshot.error, isNull);
    } finally {
      await subscription.cancel();
      await _awaitNative(engine.dispose(), const Duration(seconds: 8));
    }
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('missing retained source after Stop fails visibly and can recover', () async {
    final File retained = File(
      '${fixture.parent.path}/stop-play-recovery-$pid-${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    await fixture.copy(retained.path);
    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    try {
      await engine.initialize();
      await _awaitNative(engine.open(retained.uri), const Duration(seconds: 8));
      await _awaitNative(engine.play(), const Duration(seconds: 3));
      await _waitForPosition(engine, const Duration(milliseconds: 400));
      await _awaitNative(engine.stop(), const Duration(seconds: 3));
      await retained.delete();

      await expectLater(engine.play(), throwsStateError);
      expect(engine.currentSnapshot.stopped, isTrue);
      expect(engine.currentSnapshot.playing, isFalse);

      await fixture.copy(retained.path);
      await _awaitNative(engine.play(), const Duration(seconds: 8));
      await _waitForPosition(engine, const Duration(milliseconds: 500));
      expect(engine.currentSnapshot.playing, isTrue);
      expect(engine.currentSnapshot.stopped, isFalse);
      expect(engine.currentSnapshot.error, isNull);
    } finally {
      await _awaitNative(engine.dispose(), const Duration(seconds: 8));
      if (await retained.exists()) await retained.delete();
    }
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('invalid local media reports an error and valid media recovers', () async {
    expect(await fixture.exists(), isTrue, reason: fixture.path);
    final Directory fixtureDirectory = fixture.parent;
    final File invalid = File(
      '${fixtureDirectory.path}/invalid-$pid-${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    await invalid.writeAsBytes('not an mp4'.codeUnits, flush: true);

    final MediaKitSpikeEngine engine = MediaKitSpikeEngine();
    final Completer<void> nativeError = Completer<void>();
    final Completer<void> recoveredPlayback = Completer<void>();
    final StreamSubscription<dynamic> sub = engine.snapshots.listen((snapshot) {
      if (snapshot.error != null && !nativeError.isCompleted) {
        nativeError.complete();
      }
      if (snapshot.playing &&
          snapshot.position > const Duration(milliseconds: 500) &&
          !recoveredPlayback.isCompleted) {
        recoveredPlayback.complete();
      }
    });
    try {
      await engine.initialize();
      final File missing = File(
        '${fixtureDirectory.path}/missing-$pid-${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      await expectLater(engine.open(missing.uri), throwsStateError);
      await expectLater(
        engine.open(Uri.parse('https://example.invalid/not-local.mp4')),
        throwsArgumentError,
      );
      expect(engine.currentSnapshot.error, isNull);

      final Future<void> openingInvalid = engine.open(invalid.uri);
      bool nativeOpenFailed = false;
      try {
        await _awaitNative(openingInvalid, const Duration(seconds: 8));
      } on Object {
        // libmpv may report decode failure either as a Future error or a stream
        // event. The state assertion below requires an observable failure.
        nativeOpenFailed = true;
      }
      if (engine.currentSnapshot.error == null) {
        if (!nativeOpenFailed) {
          await nativeError.future.timeout(const Duration(seconds: 8));
        }
      }
      expect(nativeOpenFailed || engine.currentSnapshot.error != null, isTrue);

      await _awaitNative(engine.open(fixture.uri), const Duration(seconds: 8));
      expect(engine.currentSnapshot.error, isNull);
      await _awaitNative(engine.play(), const Duration(seconds: 3));
      await recoveredPlayback.future.timeout(const Duration(seconds: 6));
      expect(engine.currentSnapshot.playing, isTrue);
      expect(engine.currentSnapshot.error, isNull);
    } finally {
      await sub.cancel();
      await _awaitNative(engine.dispose(), const Duration(seconds: 8));
      await invalid.delete();
    }
  }, timeout: const Timeout(Duration(seconds: 45)));
}

Future<void> _waitForPosition(
  MediaKitSpikeEngine engine,
  Duration minimum,
) async {
  if (engine.currentSnapshot.position > minimum) return;
  final Completer<void> reached = Completer<void>();
  final StreamSubscription<dynamic> subscription = engine.snapshots.listen((s) {
    if (s.position > minimum && !reached.isCompleted) reached.complete();
  });
  try {
    await reached.future.timeout(const Duration(seconds: 6));
  } finally {
    await subscription.cancel();
  }
}

Future<void> _waitForCoordinatorPosition(
  SpikePlayerCoordinator coordinator,
  Duration minimum,
) async {
  if (coordinator.state.position >= minimum) return;
  final Completer<void> reached = Completer<void>();
  final StreamSubscription<PlaybackSessionSnapshot> subscription = coordinator
      .states
      .listen((PlaybackSessionSnapshot state) {
        if (state.position >= minimum && !reached.isCompleted) {
          reached.complete();
        }
      });
  try {
    await reached.future.timeout(const Duration(seconds: 10));
  } finally {
    await subscription.cancel();
  }
}

/// A watchdog does not cancel the native command. On timeout, wait for the
/// original Future before returning so callers can safely dispose afterwards.
Future<void> _awaitNative(Future<void> operation, Duration watchdog) async {
  try {
    await operation.timeout(watchdog);
  } on TimeoutException catch (timeout) {
    await operation;
    Error.throwWithStackTrace(timeout, StackTrace.current);
  }
}

final class _OpenSubtitlesFixtureAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.method == 'GET' && options.uri.path.endsWith('/subtitles')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': [
            {
              'id': 'fixture-subtitle',
              'attributes': {
                'language': 'en',
                'release': 'fixture release',
                'files': [
                  {'file_id': 1701, 'file_name': 'fixture.srt'},
                ],
              },
            },
          ],
        }),
        HttpStatus.ok,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.method == 'POST' && options.uri.path.endsWith('/download')) {
      return ResponseBody.fromString(
        jsonEncode({
          'link': 'https://www.opensubtitles.com/download/fixture/subfile/fixture.srt',
          'remaining': 8,
          'reset_time_utc': '2026-11-11T00:00:00Z',
        }),
        HttpStatus.ok,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromBytes(
      utf8.encode(
        '1\n00:00:00,500 --> 00:00:02,500\nFixture OpenSubtitles SRT\n',
      ),
      HttpStatus.ok,
    );
  }

  @override
  void close({bool force = false}) {}
}
