import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../application/player/diagnostics/playback_performance.dart';
import '../../application/player/external_subtitles/external_subtitle_service.dart';
import '../../application/player/providers/playback_provider_manager.dart';
import '../../application/player/skips/automatic_skip_controller.dart';
import '../../application/player/skips/skip_segment_service.dart';
import '../../application/player/source_switching/playback_source_switch_service.dart';
import '../../application/player/spike_player_coordinator.dart';
import '../../data/player/engine/media_kit_spike_engine.dart';
import '../../domain/player/providers/playback_source.dart';
import '../../domain/player/skips/skip_automation_policy.dart';
import '../../domain/player/skips/skip_segment_catalog.dart';
import '../../domain/player/subtitles/external_subtitle_catalog.dart';
import 'media_kit_video_surface.dart';
import 'player_video_display.dart';
import 'player_window_controller.dart';
import 'spike_player_page.dart';

/// Composition root for the opt-in F2.2 desktop spike.
final class SpikePlayerModule {
  SpikePlayerModule._(
    this.engine,
    this.coordinator,
    this.performance,
    this.display,
    this.windowController,
    this.externalSubtitleService,
    this.sourceSwitchService,
    this.skipSegmentService,
    this.automaticSkipController,
    this._disposeExternalSubtitleCatalog,
    this._disposeSkipSegmentCatalog,
  );

  final MediaKitSpikeEngine engine;
  final SpikePlayerCoordinator coordinator;
  final PlaybackPerformanceCollector performance;
  final PlayerVideoDisplayController display;
  final PlayerWindowController windowController;
  final ExternalSubtitleService? externalSubtitleService;
  final PlaybackSourceSwitchService? sourceSwitchService;
  final SkipSegmentService? skipSegmentService;
  final AutomaticSkipController? automaticSkipController;
  final FutureOr<void> Function()? _disposeExternalSubtitleCatalog;
  final FutureOr<void> Function()? _disposeSkipSegmentCatalog;
  bool _catalogDisposed = false;
  bool _skipCatalogDisposed = false;

  static Future<SpikePlayerModule> open(
    File? fixture, {
    PlayerWindowController? windowController,
    Set<Uri> demoSources = const {},
    Set<Uri> trustedExternalSources = const {},
    ExternalSubtitleCatalog? externalSubtitleCatalog,
    FutureOr<void> Function()? disposeExternalSubtitleCatalog,
    PlaybackProviderManager? sourceProviderManager,
    PlaybackEpisode? sourceEpisode,
    ResolvedPlaybackStream? initialResolvedSource,
    SkipSegmentCatalog? skipSegmentCatalog,
    PlaybackEpisode? skipEpisode,
    MyAnimeListAnimeId? skipMalAnimeId,
    SkipAutomationSettings skipAutomationSettings =
        const SkipAutomationSettings(),
    EpisodeFillerEvidence? fillerEvidence,
    FutureOr<void> Function()? disposeSkipSegmentCatalog,
  }) async {
    final Uri? fixtureUri = fixture?.absolute.uri;
    final Uri? initialUri = fixtureUri ?? initialResolvedSource?.uri;
    if (initialUri == null ||
        (fixture == null &&
            (initialResolvedSource == null ||
                !trustedExternalSources.contains(initialResolvedSource.uri) ||
                sourceProviderManager == null ||
                sourceEpisode == null))) {
      throw ArgumentError(
        'Opening playback requires a local fixture or an allowlisted resolved source.',
      );
    }
    final bool hasSourceSwitchInput =
        sourceProviderManager != null ||
        sourceEpisode != null ||
        initialResolvedSource != null;
    if (hasSourceSwitchInput &&
        (sourceProviderManager == null ||
            sourceEpisode == null ||
            initialResolvedSource == null)) {
      throw ArgumentError(
        'Source switch requires a provider manager, episode and initial source.',
      );
    }
    if ((skipSegmentCatalog != null && skipEpisode == null) ||
        (skipEpisode != null && skipSegmentCatalog == null) ||
        (skipMalAnimeId != null && skipEpisode == null)) {
      throw ArgumentError(
        'Skip lookup requires a catalog and episode; a MAL ID must be explicitly mapped.',
      );
    }
    var catalogDisposed = false;
    Future<void> disposeCatalog() async {
      if (catalogDisposed) return;
      catalogDisposed = true;
      await disposeExternalSubtitleCatalog?.call();
    }

    var skipCatalogDisposed = false;
    Future<void> disposeSkipCatalog() async {
      if (skipCatalogDisposed) return;
      skipCatalogDisposed = true;
      await disposeSkipSegmentCatalog?.call();
    }

    MediaKitSpikeEngine? engine;
    SpikePlayerCoordinator? coordinator;
    PlayerWindowController? resolvedWindowController;
    PlaybackSourceSwitchService? sourceSwitchService;
    SkipSegmentService? skipSegmentService;
    AutomaticSkipController? automaticSkipController;
    try {
      await MediaKitSpikeEngine.retryPendingDispose();
      engine = MediaKitSpikeEngine(
        demoSources: demoSources,
        trustedExternalSources: trustedExternalSources,
      );
      coordinator = SpikePlayerCoordinator(
        engine,
        demoSources: demoSources,
        trustedExternalSources: trustedExternalSources,
      );
      resolvedWindowController =
          windowController ?? GtkPlayerWindowController();
      engine.attachVideoSurface();
      await coordinator.initialize();
      await coordinator.open(initialUri);
      if (sourceProviderManager case final PlaybackProviderManager manager) {
        final ResolvedPlaybackStream initial = initialResolvedSource!;
        if (fixtureUri != null && initial.uri != fixtureUri) {
          throw ArgumentError(
            'Initial resolved source must match the opened fixture URI.',
          );
        }
        sourceSwitchService = PlaybackSourceSwitchService(
          manager: manager,
          episode: sourceEpisode!,
          coordinator: coordinator,
          initialSource: initial,
        );
      }
      if (skipSegmentCatalog case final SkipSegmentCatalog catalog) {
        skipSegmentService = SkipSegmentService(
          episode: skipEpisode!,
          coordinator: coordinator,
          catalog: catalog,
          malAnimeId: skipMalAnimeId,
        );
        automaticSkipController = AutomaticSkipController(
          coordinator: coordinator,
          segments: skipSegmentService,
          settings: skipAutomationSettings,
          fillerEvidence: fillerEvidence,
        );
        unawaited(skipSegmentService.load());
      }
      return SpikePlayerModule._(
        engine,
        coordinator,
        PlaybackPerformanceCollector(engine),
        PlayerVideoDisplayController(),
        resolvedWindowController,
        externalSubtitleCatalog == null
            ? null
            : ExternalSubtitleService(
                catalog: externalSubtitleCatalog,
                loader: coordinator,
                sourceGeneration: () => coordinator!.state.sourceGeneration,
              ),
        sourceSwitchService,
        skipSegmentService,
        automaticSkipController,
        disposeCatalog,
        disposeSkipCatalog,
      );
    } catch (_) {
      try {
        try {
          await sourceSwitchService?.dispose();
        } finally {
          try {
            await automaticSkipController?.dispose();
          } finally {
            try {
              await skipSegmentService?.dispose();
            } finally {
              if (coordinator != null) {
                await coordinator.dispose();
              } else {
                await engine?.dispose();
              }
            }
          }
        }
      } finally {
        try {
          await resolvedWindowController?.dispose();
        } finally {
          try {
            await disposeCatalog();
          } finally {
            await disposeSkipCatalog();
          }
        }
      }
      rethrow;
    }
  }

  Widget build({Widget? demoControls}) => SpikePlayerPage(
    demoControls: demoControls,
    coordinator: coordinator,
    performance: performance,
    display: display,
    videoSurface: MediaKitVideoSurface(
      controller: engine.videoController,
      display: display,
    ),
    windowController: windowController,
    externalSubtitleService: externalSubtitleService,
    sourceSwitchService: sourceSwitchService,
    skipSegmentService: skipSegmentService,
  );

  Future<void> close() async {
    try {
      await windowController.dispose();
    } finally {
      try {
        try {
          await performance.dispose();
        } finally {
          try {
            await sourceSwitchService?.dispose();
          } finally {
            try {
              await automaticSkipController?.dispose();
            } finally {
              try {
                await skipSegmentService?.dispose();
              } finally {
                await coordinator.dispose();
              }
            }
          }
        }
      } finally {
        try {
          if (!_catalogDisposed) {
            _catalogDisposed = true;
            await _disposeExternalSubtitleCatalog?.call();
          }
        } finally {
          if (!_skipCatalogDisposed) {
            _skipCatalogDisposed = true;
            await _disposeSkipSegmentCatalog?.call();
          }
        }
      }
    }
  }
}
