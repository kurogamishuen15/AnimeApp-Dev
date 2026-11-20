import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../application/player/diagnostics/playback_performance.dart';
import '../../application/player/external_subtitles/external_subtitle_service.dart';
import '../../application/player/playback_progress_session.dart';
import '../../application/player/providers/playback_provider_manager.dart';
import '../../application/player/skips/automatic_skip_controller.dart';
import '../../application/player/skips/skip_segment_service.dart';
import '../../application/player/source_switching/playback_source_switch_service.dart';
import '../../application/player/spike_player_coordinator.dart';
import '../../data/player/engine/active_player_lease.dart';
import '../../data/player/engine/media_kit_spike_engine.dart';
import '../../domain/player/providers/playback_provider_contract.dart';
import '../../domain/player/providers/playback_source.dart';
import '../../domain/player/skips/skip_automation_policy.dart';
import '../../domain/player/skips/skip_segment_catalog.dart';
import '../../domain/player/subtitles/external_subtitle_catalog.dart';
import 'media_kit_video_surface.dart';
import 'playback_route_session.dart';
import 'player_video_display.dart';
import 'player_window_controller.dart';
import 'spike_player_page.dart';
import 'spike_player_page_options.dart';

/// Composition root for the opt-in F2.2 desktop spike.
final class SpikePlayerModule implements PlaybackRouteSession {
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
    this.pageOptions,
    this._progressSession,
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
  final SpikePlayerPageOptions pageOptions;
  final PlaybackProgressSession? _progressSession;
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
    List<ResolvedPlaybackStream>? authorizedAlternatives,
    SkipSegmentCatalog? skipSegmentCatalog,
    PlaybackEpisode? skipEpisode,
    MyAnimeListAnimeId? skipMalAnimeId,
    SkipAutomationSettings skipAutomationSettings =
        const SkipAutomationSettings(),
    EpisodeFillerEvidence? fillerEvidence,
    FutureOr<void> Function()? disposeSkipSegmentCatalog,
    PlaybackRouteOpenCancellation? startupCancellation,
    Duration startPosition = Duration.zero,
    PlaybackProgressSession Function(SpikePlayerCoordinator)? trackProgress,
    @visibleForTesting MediaKitSpikeEngine Function()? engineFactory,
  }) async {
    // Ownership of supplied catalog disposers transfers only after argument
    // validation; callers retain ownership when validation rejects the call.
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
    final providerSubtitles = <Uri, List<ProviderSubtitle>>{};
    for (final stream in [?initialResolvedSource, ...?authorizedAlternatives]) {
      final previous = providerSubtitles[stream.uri];
      if (previous != null && !listEquals(previous, stream.subtitles)) {
        throw ArgumentError(
          'Conflicting caption catalogs for the same media URI.',
        );
      }
      providerSubtitles[stream.uri] = stream.subtitles;
    }
    var catalogDisposed = false;
    Future<void> disposeCatalog() async {
      if (catalogDisposed) return;
      await disposeExternalSubtitleCatalog?.call();
      catalogDisposed = true;
    }

    var skipCatalogDisposed = false;
    Future<void> disposeSkipCatalog() async {
      if (skipCatalogDisposed) return;
      await disposeSkipSegmentCatalog?.call();
      skipCatalogDisposed = true;
    }

    MediaKitSpikeEngine? engine;
    SpikePlayerCoordinator? coordinator;
    PlayerWindowController? resolvedWindowController;
    PlaybackSourceSwitchService? sourceSwitchService;
    SkipSegmentService? skipSegmentService;
    AutomaticSkipController? automaticSkipController;
    Object? cleanupError;
    StackTrace? cleanupStack;
    Future<void> attemptCleanup(FutureOr<void> Function() cleanup) async {
      try {
        await cleanup();
      } on Object catch (error, stack) {
        cleanupError ??= error;
        cleanupStack ??= stack;
      }
    }

    try {
      startupCancellation?.throwIfRequested();
      await MediaKitSpikeEngine.retryPendingDispose();
      startupCancellation?.throwIfRequested();
    } on Object catch (error, stack) {
      await attemptCleanup(disposeCatalog);
      await attemptCleanup(disposeSkipCatalog);
      if (cleanupError == null &&
          (error is ActivePlayerLeaseInUse ||
              error is PlaybackRouteOpenCancelled)) {
        Error.throwWithStackTrace(error, stack);
      }
      Error.throwWithStackTrace(
        SpikePlayerStartupCleanupFailure(
          startupError: error,
          cleanupError: cleanupError ?? error,
          nativePlayerStillOwned: MediaKitSpikeEngine.hasActivePlayerLease,
          nonNativeCleanupFailed: cleanupError != null,
        ),
        cleanupStack ?? stack,
      );
    }
    try {
      engine =
          engineFactory?.call() ??
          MediaKitSpikeEngine(
            demoSources: demoSources,
            trustedExternalSources: trustedExternalSources,
            providerSubtitles: providerSubtitles,
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
      startupCancellation?.throwIfRequested();
      await coordinator.open(
        initialUri,
        httpHeaders:
            initialResolvedSource?.httpHeaders ??
            const PlaybackRequestHeaders.empty(),
      );
      startupCancellation?.throwIfRequested();
      if (startPosition > Duration.zero) {
        try {
          await coordinator.restoreStartPosition(
            startPosition,
            cancellation:
                startupCancellation?.token ?? PlaybackCancellationToken(),
          );
        } finally {
          startupCancellation?.throwIfRequested();
        }
      }
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
          authorizedAlternatives: authorizedAlternatives,
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
        SpikePlayerPageOptions.fromEnvironment(Platform.environment),
        trackProgress?.call(coordinator),
      );
    } on Object catch (startupError, startupStack) {
      final PlaybackSourceSwitchService? sourceSwitch = sourceSwitchService;
      if (sourceSwitch != null) {
        await attemptCleanup(sourceSwitch.dispose);
      }
      final AutomaticSkipController? automaticSkip = automaticSkipController;
      if (automaticSkip != null) {
        await attemptCleanup(automaticSkip.dispose);
      }
      final SkipSegmentService? skipService = skipSegmentService;
      if (skipService != null) await attemptCleanup(skipService.dispose);
      final SpikePlayerCoordinator? createdCoordinator = coordinator;
      if (createdCoordinator != null) {
        await attemptCleanup(createdCoordinator.dispose);
      } else {
        final MediaKitSpikeEngine? createdEngine = engine;
        if (createdEngine != null) {
          await attemptCleanup(createdEngine.dispose);
        } else if (startupError is! ActivePlayerLeaseInUse) {
          // The engine factory can allocate a native Player, then fail before
          // returning it. Its synchronous rollback is registered on the
          // lease; await that rollback before classifying startup as safe.
          // ActivePlayerLeaseInUse from acquire() occurs before allocation, so
          // there is no resource from this attempt to retry-dispose.
          await attemptCleanup(MediaKitSpikeEngine.retryPendingDispose);
        }
      }
      final PlayerWindowController? createdWindow = resolvedWindowController;
      if (createdWindow != null) await attemptCleanup(createdWindow.dispose);
      await attemptCleanup(disposeCatalog);
      await attemptCleanup(disposeSkipCatalog);

      if (cleanupError case final Object error) {
        Error.throwWithStackTrace(
          SpikePlayerStartupCleanupFailure(
            startupError: startupError,
            cleanupError: error,
            nativePlayerStillOwned: MediaKitSpikeEngine.hasActivePlayerLease,
            nonNativeCleanupFailed: true,
          ),
          cleanupStack!,
        );
      }
      Error.throwWithStackTrace(startupError, startupStack);
    }
  }

  /// Opens the existing module for the provider route and translates the
  /// low-level exclusive-player conflict into a presentation-safe error.
  static Future<PlaybackRouteSession> openForRoute(
    Future<PlaybackRouteSession> Function() open,
  ) async {
    try {
      return await open();
    } on ActivePlayerLeaseInUse catch (error, stack) {
      Error.throwWithStackTrace(PlaybackRoutePlayerBusy(), stack);
    }
  }

  @override
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
    options: pageOptions,
  );

  @override
  Future<void> close() async {
    Object? cleanupError;
    StackTrace? cleanupStack;
    Future<bool> attemptCleanup(FutureOr<void> Function() cleanup) async {
      try {
        await cleanup();
        return true;
      } on Object catch (error, stack) {
        cleanupError ??= error;
        cleanupStack ??= stack;
        return false;
      }
    }

    await attemptCleanup(windowController.dispose);
    await attemptCleanup(performance.dispose);
    await attemptCleanup(() => sourceSwitchService?.dispose());
    await attemptCleanup(() => automaticSkipController?.dispose());
    await attemptCleanup(() => skipSegmentService?.dispose());
    final Future<bool> saveProgress = attemptCleanup(
      () => _progressSession?.close().timeout(const Duration(seconds: 2)),
    );
    await attemptCleanup(coordinator.dispose);
    await saveProgress;
    if (!_catalogDisposed) {
      _catalogDisposed = await attemptCleanup(
        () => _disposeExternalSubtitleCatalog?.call(),
      );
    }
    if (!_skipCatalogDisposed) {
      _skipCatalogDisposed = await attemptCleanup(
        () => _disposeSkipSegmentCatalog?.call(),
      );
    }

    if (cleanupError case final Object error) {
      Error.throwWithStackTrace(
        PlaybackRouteCleanupFailure(
          cause: error,
          nativePlayerStillOwned: MediaKitSpikeEngine.hasActivePlayerLease,
          nonNativeCleanupFailed: true,
        ),
        cleanupStack!,
      );
    }
  }
}

/// Indicates startup failed and at least one owned resource did not close.
///
/// The route must keep the user on the failure screen because the native
/// player lease may still be quarantined and require an application restart.
final class SpikePlayerStartupCleanupFailure implements Exception {
  const SpikePlayerStartupCleanupFailure({
    required this.startupError,
    required this.cleanupError,
    this.nativePlayerStillOwned = true,
    this.nonNativeCleanupFailed = true,
  });

  final Object startupError;
  final Object cleanupError;
  final bool nativePlayerStillOwned;
  final bool nonNativeCleanupFailed;
}
