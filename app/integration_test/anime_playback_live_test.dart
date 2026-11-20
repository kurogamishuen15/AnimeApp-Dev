import 'dart:io';

import 'package:anime_app/app/player/media_kit_video_surface.dart';
import 'package:anime_app/app/player/provider_playback_route.dart';
import 'package:anime_app/app/player/spike_player_page.dart';
import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/core/bootstrap/anime_app.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/player/engine/mpv_subtitle_properties.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:anime_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// Explicit network/device test using main(), the real catalog and the player.
/// Run with a project-local KONGROO_DATABASE_PATH to isolate user progress.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final animeId = Platform.environment['KONGROO_TEST_ANILIST_ID'] ?? '100240';
  final animeTitle =
      Platform.environment['KONGROO_TEST_ANIME_TITLE'] ?? 'Tokyo Ghoul:re';
  final episodeNumber = int.parse(
    Platform.environment['KONGROO_TEST_EPISODE'] ?? '9',
  );
  final providerId =
      Platform.environment['KONGROO_TEST_PROVIDER'] ?? 'megaplay';
  final captionLanguage = Platform.environment['KONGROO_TEST_CAPTION_LANGUAGE'];
  testWidgets(
    'real anime episode renders video with published language variant',
    (tester) async {
      expect(Platform.environment['KONGROO_DATABASE_PATH'], isNotEmpty);
      await app.main();
      await _wait(tester, () => find.byTooltip('Buscar').evaluate().isNotEmpty);
      await tester.tap(find.byTooltip('Buscar').first);
      await _wait(
        tester,
        () => find
            .byKey(const ValueKey('catalog-search-field'))
            .evaluate()
            .isNotEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('catalog-search-field')),
        animeTitle,
      );
      await tester.tap(find.byKey(const ValueKey('catalog-search-button')));
      final anime = find.byKey(ValueKey('catalog-item-$animeId'));
      await _wait(tester, () => anime.evaluate().isNotEmpty);
      await tester.ensureVisible(anime);
      await tester.tap(anime);
      final add = find.byKey(const ValueKey('add-to-library'));
      await _wait(
        tester,
        () =>
            add.evaluate().isNotEmpty ||
            find
                .byKey(const ValueKey('detail-library-status'))
                .evaluate()
                .isNotEmpty,
      );
      if (add.evaluate().isNotEmpty) {
        await tester.ensureVisible(add);
        await tester.tap(add);
        await _wait(
          tester,
          () => find
              .byKey(const ValueKey('detail-library-status'))
              .evaluate()
              .isNotEmpty,
        );
      }
      final episode = find.byKey(ValueKey('episode-card-$episodeNumber'));
      await _wait(
        tester,
        () =>
            find.byKey(const ValueKey('episode-card-1')).evaluate().isNotEmpty,
      );
      await tester.scrollUntilVisible(
        episode,
        350,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('detail-episodes-scroll'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 12,
      );
      await tester.ensureVisible(episode);
      await tester.tap(
        find.descendant(
          of: episode,
          matching: find.byTooltip('Buscar fuentes del episodio'),
        ),
      );
      final source = find.byKey(ValueKey('source-$providerId-megaplay-hls'));
      await _wait(tester, () => source.hitTestable().evaluate().isNotEmpty);
      debugPrint(
        'LIVE_SOURCE provider=$providerId anilist=$animeId episode=$episodeNumber',
      );
      await tester.tap(source);
      await _wait(
        tester,
        () => find.byType(SpikePlayerPage).evaluate().isNotEmpty,
      );
      final route = tester.widget<ProviderPlaybackRoute>(
        find.byType(ProviderPlaybackRoute),
      );
      expect(route.initialStream.providerId.value, providerId);
      expect(route.episode.episodeNumber, episodeNumber);
      final player = tester
          .widget<SpikePlayerPage>(find.byType(SpikePlayerPage))
          .coordinator;
      await _wait(
        tester,
        () => find
            .byKey(const ValueKey('playback-toggle'))
            .hitTestable()
            .evaluate()
            .isNotEmpty,
      );
      if (captionLanguage != null) {
        await _wait(
          tester,
          () => player.state.subtitleTracks.any(
            (track) => track.language == captionLanguage,
          ),
        );
        final captionIds = player.state.subtitleTracks
            .where((track) => track.language == captionLanguage)
            .map((track) => track.id)
            .toSet();
        await tester.tap(find.byKey(const ValueKey('player-subtitles')));
        final selector = find.byKey(const ValueKey('subtitle-track-selector'));
        await _wait(tester, () => selector.hitTestable().evaluate().isNotEmpty);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        final option = find
            .text(captionLanguage == 'es' ? 'Español' : 'Inglés')
            .last;
        await tester.ensureVisible(option);
        await tester.tap(option);
        await _wait(
          tester,
          () =>
              captionIds.contains(player.state.selectedSubtitleId) ||
              player.state.error != null,
        );
        expect(player.state.error, isNull);
        await tester.tap(find.widgetWithText(TextButton, 'Cerrar'));
        await _wait(
          tester,
          () => find
              .byKey(const ValueKey('playback-toggle'))
              .hitTestable()
              .evaluate()
              .isNotEmpty,
        );
        debugPrint('LIVE_CAPTION_SELECTED language=$captionLanguage');
      }
      await tester.tap(find.byKey(const ValueKey('playback-toggle')));
      await _wait(
        tester,
        () =>
            player.state.error != null ||
            player.state.observedPosition >
                route.startPosition + const Duration(seconds: 3),
      );
      expect(player.state.error, isNull);
      if (route.startPosition > Duration.zero) {
        expect(
          player.state.observedPosition,
          greaterThanOrEqualTo(route.startPosition),
        );
        debugPrint(
          'LIVE_RESUME_CONFIRMED start_ms='
          '${route.startPosition.inMilliseconds}',
        );
      }
      final surface = tester.widget<MediaKitVideoSurface>(
        find.byType(MediaKitVideoSurface),
      );
      await surface.controller.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 20),
      );
      expect(player.state.duration, greaterThan(const Duration(minutes: 20)));
      debugPrint(
        'LIVE_FRAME_RENDERED position_ms='
        '${player.state.observedPosition.inMilliseconds} '
        'duration_ms=${player.state.duration.inMilliseconds}',
      );

      await tester.tap(find.byKey(const ValueKey('playback-toggle')));
      await _wait(tester, () => !player.state.playing);
      final before = player.state.observedPosition;
      await tester.tap(find.byKey(const ValueKey('forward-10')));
      await _wait(
        tester,
        () =>
            player.state.error != null ||
            player.state.observedPosition >=
                before + const Duration(seconds: 9),
      );
      expect(player.state.error, isNull);
      expect(player.state.playing, isFalse);
      debugPrint(
        'LIVE_SEEK_CONFIRMED position_ms='
        '${player.state.observedPosition.inMilliseconds}',
      );
      if (captionLanguage == 'es') {
        await player.seek(const Duration(seconds: 43));
        await _wait(
          tester,
          () =>
              player.state.observedPosition >= const Duration(seconds: 42) &&
              player.state.observedPosition <= const Duration(seconds: 44),
        );
        debugPrint(
          'LIVE_SPANISH_CUE_POSITION position_ms=${player.state.observedPosition.inMilliseconds} sid=${await readMpvSubtitleProperty(surface.controller.player, 'sid')} visible=${await readMpvSubtitleProperty(surface.controller.player, 'sub-visibility')}',
        );
      }
      await tester.tap(find.byKey(const ValueKey('playback-toggle')));
      await _wait(tester, () => player.state.playing);
      if (captionLanguage == 'es') {
        var textPresent = false;
        for (var tries = 0; tries < 100 && !textPresent; tries++) {
          textPresent = (await readMpvSubtitleProperty(
            surface.controller.player,
            'sub-text',
          )).trim().isNotEmpty;
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(
          textPresent,
          isTrue,
          reason:
              'Selected VTT must produce timed subtitle text in native mpv.',
        );
        debugPrint(
          'LIVE_CAPTION_RENDERED language=es native_text_present=true',
        );
      }
      // Keep the real native texture on screen for compositor inspection.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 10)),
      );
      final closeCheckpointMs = player.state.observedPosition.inMilliseconds;
      await tester.tap(find.byTooltip('Volver a la ficha'));
      await _wait(
        tester,
        () => find.byType(ProviderPlaybackRoute).evaluate().isEmpty,
      );
      expect(episode, findsOneWidget);
      final service = tester
          .widget<AnimeApp>(find.byType(AnimeApp))
          .catalogService;
      final saved = await service.progress.get(
        CatalogService.episodeProgressKey(route.episode.animeId, episodeNumber),
      );
      expect(saved, isA<Success<PlaybackProgress?>>());
      final progress = (saved as Success<PlaybackProgress?>).value;
      expect(progress, isNotNull);
      expect(progress!.positionMs, greaterThan(0));
      expect(
        (progress.positionMs - closeCheckpointMs).abs(),
        lessThanOrEqualTo(2000),
      );
      debugPrint('LIVE_PROGRESS_SAVED position_ms=${progress.positionMs}');
      debugPrint('LIVE_RETURNED_TO_DETAIL');
    },
    skip: Platform.environment['KONGROO_LIVE_ANIME_TEST'] != '1',
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _wait(WidgetTester tester, bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 45)) {
      throw StateError('The live application did not reach its next UI state.');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pump();
}
