import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/player/diagnostics/playback_performance.dart';
import '../../application/player/external_subtitles/external_subtitle_service.dart';
import '../../application/player/playback_spike_contract.dart';
import '../../application/player/skips/skip_segment_service.dart';
import '../../application/player/source_switching/playback_source_switch_service.dart';
import '../../application/player/spike_player_coordinator.dart';
import 'audio_track_selector.dart';
import 'player_frame_timing_probe.dart';
import 'player_nerd_panel.dart';
import 'player_quality_panel.dart';
import 'player_subtitle_panel.dart';
import 'player_video_display.dart';
import 'player_video_display_panel.dart';
import 'player_video_layout.dart';
import 'player_window_controller.dart';
import 'skip_segment_panel.dart';
import 'source_switch_panel.dart';
import 'spike_player_page_options.dart';

/// Central F2.3 keyboard increments, available to move to settings later.
const int spikePlayerKeyboardSeekSeconds = 10;
const double spikePlayerKeyboardVolumeStep = 5;

/// Basic playback controls and scoped keyboard shortcuts for the F2.3 spike.
final class SpikePlayerPage extends StatefulWidget {
  const SpikePlayerPage({
    required this.coordinator,
    required this.videoSurface,
    required this.windowController,
    this.externalSubtitleService,
    this.sourceSwitchService,
    this.skipSegmentService,
    this.demoControls,
    this.performance,
    this.display,
    this.options = const SpikePlayerPageOptions(),
    super.key,
  });

  final SpikePlayerCoordinator coordinator;
  final Widget videoSurface;
  final PlayerWindowController windowController;
  final ExternalSubtitleService? externalSubtitleService;
  final PlaybackSourceSwitchService? sourceSwitchService;
  final SkipSegmentService? skipSegmentService;
  final Widget? demoControls;
  final PlaybackPerformanceCollector? performance;
  final PlayerVideoDisplayController? display;
  final SpikePlayerPageOptions options;

  @override
  State<SpikePlayerPage> createState() => _SpikePlayerPageState();
}

final class _SpikePlayerPageState extends State<SpikePlayerPage> {
  late PlaybackSessionSnapshot _snapshot = widget.coordinator.state;
  late PlayerWindowSnapshot _windowSnapshot = widget.windowController.state;
  StreamSubscription<PlaybackSessionSnapshot>? _subscription;
  StreamSubscription<PlayerWindowSnapshot>? _windowSubscription;
  String? _commandError;
  double? _scrubPositionMs;
  (Duration, int)? _queuedSeek;
  int? _scrubGeneration;
  Future<void>? _seekDrain;
  Future<void>? _stopOperation;
  PlayerFrameTimingProbe? _frameTimingProbe;
  StreamSubscription<PlaybackPerformanceSample>? _performanceLogSubscription;
  late bool _nerdVisible;
  late final PlayerVideoDisplayController _display =
      widget.display ?? PlayerVideoDisplayController();
  int _scrubRevision = 0;
  bool _stopping = false;
  final PlayerSubtitlePreferences _subtitlePreferences =
      PlayerSubtitlePreferences();
  double _unmutedVolume = 100;
  late final FocusNode _shortcutFocusNode = FocusNode(
    debugLabel: 'Kongroo player keyboard controls',
  );
  late final _PlayerShortcutManager _shortcutManager = _PlayerShortcutManager(
    _shouldIgnoreShortcuts,
  );

  @override
  void initState() {
    super.initState();
    _nerdVisible = widget.options.showNerdPanel;
    if (widget.options.initialFit case final PlayerVideoFit fit) {
      _display.setFit(fit);
    }
    if (widget.options.initialAspect case final PlayerVideoAspect aspect) {
      _display.setAspect(aspect);
    }
    if (widget.options.performanceDiagnosticsEnabled) {
      _frameTimingProbe = PlayerFrameTimingProbe();
      if (widget.performance
          case final PlaybackPerformanceCollector collector) {
        collector.start();
        _performanceLogSubscription = collector.samples.listen((sample) {
          debugPrint(
            'KONGROO_PERF_NATIVE nominal_fps=${sample.nominalFps} '
            'decoded_fps=${sample.decodedFps} '
            'position_events_per_s=${sample.positionEventsPerSecond} '
            'vo_drops=${sample.framesDropped} '
            'decoder_drops=${sample.decoderFramesDropped} '
            'avsync_s=${sample.avSyncSeconds} cache_s=${sample.cacheSeconds} '
            'hwdec=${sample.hardwareDecoder} vo=${sample.videoOutput} '
            'rss_bytes=${sample.rssBytes}',
          );
        });
      }
    }
    if (_nerdVisible) widget.performance?.start();
    _subscription = widget.coordinator.states.listen((
      PlaybackSessionSnapshot s,
    ) {
      if (mounted) setState(() => _snapshot = s);
    });
    _windowSubscription = widget.windowController.states.listen((
      PlayerWindowSnapshot state,
    ) {
      if (mounted) {
        _windowSnapshot = state;
        _shortcutManager.shortcuts = _playerShortcuts;
        setState(() {});
      }
    });
    _shortcutManager.shortcuts = _playerShortcuts;
    unawaited(widget.windowController.initialize().catchError((Object _) {}));
  }

  @override
  void dispose() {
    _display.dispose();
    _frameTimingProbe?.dispose();
    unawaited(_performanceLogSubscription?.cancel());
    unawaited(widget.performance?.stop());
    unawaited(_subscription?.cancel());
    unawaited(_windowSubscription?.cancel());
    _shortcutManager.dispose();
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  bool _shouldIgnoreShortcuts() {
    final BuildContext? focusedContext =
        FocusManager.instance.primaryFocus?.context;
    return focusedContext == null ||
        !_contextIsInsidePage(focusedContext) ||
        _contextIsTextEditing(focusedContext);
  }

  bool _contextIsInsidePage(BuildContext focusedContext) {
    if (identical(focusedContext, context)) return true;
    bool found = false;
    focusedContext.visitAncestorElements((Element element) {
      if (identical(element, context)) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  bool _contextIsTextEditing(BuildContext focusedContext) {
    if (focusedContext.widget is EditableText) return true;
    bool found = false;
    focusedContext.visitAncestorElements((Element element) {
      if (element.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  Map<ShortcutActivator, Intent> get _playerShortcuts {
    final Map<ShortcutActivator, Intent> shortcuts =
        <ShortcutActivator, Intent>{
          const SingleActivator(
            LogicalKeyboardKey.space,
            includeRepeats: false,
          ): const _TogglePlaybackIntent(),
          const SingleActivator(LogicalKeyboardKey.keyK, includeRepeats: false):
              const _TogglePlaybackIntent(),
          const SingleActivator(
            LogicalKeyboardKey.arrowLeft,
          ): const _SeekPlaybackIntent(
            Duration(seconds: -spikePlayerKeyboardSeekSeconds),
          ),
          const SingleActivator(
            LogicalKeyboardKey.arrowRight,
          ): const _SeekPlaybackIntent(
            Duration(seconds: spikePlayerKeyboardSeekSeconds),
          ),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _VolumePlaybackIntent(spikePlayerKeyboardVolumeStep),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _VolumePlaybackIntent(-spikePlayerKeyboardVolumeStep),
          const SingleActivator(LogicalKeyboardKey.keyF, includeRepeats: false):
              const _ToggleFullscreenIntent(),
        };
    if (_windowSnapshot.fullscreen) {
      shortcuts[const SingleActivator(
            LogicalKeyboardKey.escape,
            includeRepeats: false,
          )] =
          const _ExitFullscreenIntent();
    }
    return shortcuts;
  }

  Map<Type, Action<Intent>> get _playerActions => <Type, Action<Intent>>{
    _TogglePlaybackIntent: CallbackAction<_TogglePlaybackIntent>(
      onInvoke: (_) {
        unawaited(_command(widget.coordinator.togglePlayback));
        return null;
      },
    ),
    _SeekPlaybackIntent: CallbackAction<_SeekPlaybackIntent>(
      onInvoke: (_SeekPlaybackIntent intent) {
        _seekStep(intent.delta.inSeconds);
        return null;
      },
    ),
    _VolumePlaybackIntent: CallbackAction<_VolumePlaybackIntent>(
      onInvoke: (_VolumePlaybackIntent intent) {
        unawaited(
          _command(() => widget.coordinator.adjustVolumeBy(intent.delta)),
        );
        return null;
      },
    ),
    _ToggleFullscreenIntent: CallbackAction<_ToggleFullscreenIntent>(
      onInvoke: (_) {
        unawaited(_command(_toggleFullscreen));
        return null;
      },
    ),
    _ExitFullscreenIntent: CallbackAction<_ExitFullscreenIntent>(
      onInvoke: (_) {
        unawaited(_command(_exitFullscreen));
        return null;
      },
    ),
  };

  Future<void> _toggleFullscreen() {
    if (_windowSnapshot.requestPending) return Future<void>.value();
    return widget.windowController.requestFullscreen(
      !_windowSnapshot.fullscreen,
    );
  }

  Future<void> _exitFullscreen() {
    if (!_windowSnapshot.fullscreen || _windowSnapshot.requestPending) {
      return Future<void>.value();
    }
    return widget.windowController.requestFullscreen(false);
  }

  Future<void> _command(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => _commandError = null);
    } catch (_) {
      if (mounted) setState(() => _commandError = 'Playback command failed.');
    }
  }

  Future<void> _requestSeek(Duration position, int generation) {
    if (_stopping) return Future<void>.value();
    _queuedSeek = (position, generation);
    final Future<void>? running = _seekDrain;
    if (running != null) return running;

    final Completer<void> completion = Completer<void>();
    _seekDrain = completion.future;
    unawaited(_drainSeekQueue(completion));
    return completion.future;
  }

  Future<void> _drainSeekQueue(Completer<void> completion) async {
    Object? lastError;
    StackTrace? lastStack;
    try {
      while (true) {
        final (Duration, int)? target = _queuedSeek;
        if (target == null) break;
        _queuedSeek = null;
        try {
          await widget.coordinator.seek(target.$1, generation: target.$2);
          lastError = null;
          lastStack = null;
        } catch (error, stack) {
          lastError = error;
          lastStack = stack;
        }
      }
      if (lastError != null) Error.throwWithStackTrace(lastError, lastStack!);
      completion.complete();
    } catch (error, stack) {
      completion.completeError(error, stack);
    } finally {
      if (identical(_seekDrain, completion.future)) _seekDrain = null;
    }
  }

  void _beginScrub(double value) {
    if (_stopping) return;
    _scrubRevision++;
    _scrubGeneration = widget.coordinator.state.sourceGeneration;
    setState(() => _scrubPositionMs = value);
  }

  void _updateScrub(double value) {
    if (_stopping) return;
    setState(() => _scrubPositionMs = value);
  }

  void _endScrub(double value) {
    if (_stopping) return;
    final int revision = _scrubRevision;
    setState(() => _scrubPositionMs = value);
    unawaited(
      _finishScrub(
        Duration(milliseconds: value.round()),
        revision,
        _scrubGeneration ?? widget.coordinator.state.sourceGeneration,
      ),
    );
    _scrubGeneration = null;
  }

  Future<void> _stopPlayback() {
    final Future<void>? pending = _stopOperation;
    if (pending != null) return pending;

    _stopping = true;
    _queuedSeek = null;
    _scrubRevision++;
    setState(() => _scrubPositionMs = null);
    final Future<void> operation = _stopAfterSeek(_seekDrain);
    _stopOperation = operation;
    return operation;
  }

  Future<void> _stopAfterSeek(Future<void>? seekDrain) async {
    try {
      if (seekDrain != null) {
        try {
          await seekDrain;
        } catch (_) {
          // Stop still needs to reach the engine after a failed seek.
        }
      }
      await widget.coordinator.stop();
    } finally {
      _stopOperation = null;
      _stopping = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _finishScrub(
    Duration position,
    int revision,
    int generation,
  ) async {
    await _command(() => _requestSeek(position, generation));
    if (mounted && revision == _scrubRevision) {
      setState(() => _scrubPositionMs = null);
    }
  }

  bool get _canSeek =>
      !_stopping &&
      !_snapshot.stopped &&
      _snapshot.duration > Duration.zero &&
      _snapshot.status != PlaybackSessionStatus.switchingSource;

  void _seekStep(int seconds) {
    unawaited(
      _command(() => widget.coordinator.seekBy(Duration(seconds: seconds))),
    );
  }

  void _toggleMute() {
    final double volume = _snapshot.volume;
    if (volume > 0) _unmutedVolume = volume;
    unawaited(
      _command(
        () => widget.coordinator.setVolume(volume > 0 ? 0 : _unmutedVolume),
      ),
    );
  }

  Future<void> _showVolume() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Volumen'),
        content: StreamBuilder<PlaybackSessionSnapshot>(
          stream: widget.coordinator.states,
          initialData: widget.coordinator.state,
          builder: (_, state) => Slider(
            value: state.data!.volume,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${state.data!.volume.round()}%',
            onChanged: (value) =>
                unawaited(_command(() => widget.coordinator.setVolume(value))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (mounted) _shortcutFocusNode.requestFocus();
  }

  Future<void> _showSubtitles() async {
    await showDialog<void>(
      context: context,
      builder: (_) => PlayerSubtitlePanel(
        coordinator: widget.coordinator,
        preferences: _subtitlePreferences,
        externalService: widget.externalSubtitleService,
      ),
    );
    if (mounted) _shortcutFocusNode.requestFocus();
  }

  void _toggleNerd() {
    setState(() => _nerdVisible = !_nerdVisible);
    if (_nerdVisible) {
      widget.performance?.start();
    } else if (!widget.options.performanceDiagnosticsEnabled) {
      unawaited(widget.performance?.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    // A PopupMenuButton may outlive the source snapshot that built it. Bind the
    // native track action to that generation, then discard a stale menu choice
    // instead of applying its old track ID to the newly opened media.
    final int trackGeneration = _snapshot.sourceGeneration;
    final int trackMediaContextRevision =
        widget.coordinator.mediaContextRevision;
    final int maxMs = _snapshot.duration.inMilliseconds.clamp(1, 1 << 31);
    final double valueMs =
        (_scrubPositionMs ?? _snapshot.position.inMilliseconds.toDouble())
            .clamp(0, maxMs.toDouble());
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffa995ff),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Actions(
        actions: _playerActions,
        child: Shortcuts.manager(
          manager: _shortcutManager,
          child: Focus(
            focusNode: _shortcutFocusNode,
            autofocus: true,
            child: Scaffold(
              appBar: _windowSnapshot.fullscreen
                  ? null
                  : AppBar(title: Text('Kongroo')),
              body: PlayerVideoLayout(
                fullscreen: _windowSnapshot.fullscreen,
                video: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _shortcutFocusNode.requestFocus,
                        child: widget.videoSurface,
                      ),
                    ),
                    if (_snapshot.stopped)
                      const IgnorePointer(
                        child: ColoredBox(
                          color: Color(0x99000000),
                          child: Center(
                            child: Text(
                              'Playback stopped · press Play to restart',
                              style: TextStyle(color: Color(0xffffffff)),
                            ),
                          ),
                        ),
                      ),
                    if (_nerdVisible)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: PlayerNerdPanel(
                            coordinator: widget.coordinator,
                            samples: widget.performance?.samples,
                            onClose: _toggleNerd,
                          ),
                        ),
                      ),
                  ],
                ),
                controls: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xaa090910), Color(0xff0b0b12)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatPlaybackTime(_snapshot.position)} / ${_formatPlaybackTime(_snapshot.duration)}',
                        ),
                        if (_windowSnapshot.fullscreen &&
                            !_windowSnapshot.requestPending)
                          const Text(
                            'Fullscreen active · F or Escape to restore',
                          ),
                        if (_snapshot.buffering)
                          const LinearProgressIndicator(),
                        if (_snapshot.error != null)
                          Text(
                            _snapshot.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        if (_commandError != null)
                          Text(
                            _commandError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        if (widget.demoControls case final Widget controls)
                          controls,
                        if (widget.sourceSwitchService
                            case final PlaybackSourceSwitchService service)
                          SourceSwitchPanel(service: service),
                        if (widget.skipSegmentService
                            case final SkipSegmentService service)
                          SkipSegmentPanel(service: service),
                        if (_windowSnapshot.error != null)
                          Text(
                            _windowSnapshot.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        Slider(
                          min: 0,
                          max: maxMs.toDouble(),
                          value: valueMs,
                          label: _formatPlaybackTime(
                            Duration(milliseconds: valueMs.round()),
                          ),
                          semanticFormatterCallback: (double value) =>
                              _formatPlaybackTime(
                                Duration(milliseconds: value.round()),
                              ),
                          onChanged: _canSeek ? _updateScrub : null,
                          onChangeStart: _canSeek ? _beginScrub : null,
                          onChangeEnd: _canSeek ? _endScrub : null,
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            IconButton(
                              key: const ValueKey('rewind-10'),
                              tooltip: 'Retroceder 10 segundos',
                              onPressed: _canSeek
                                  ? () => _seekStep(
                                      -spikePlayerKeyboardSeekSeconds,
                                    )
                                  : null,
                              icon: const Icon(Icons.replay_10),
                            ),
                            FilledButton.icon(
                              key: const ValueKey<String>('playback-toggle'),
                              onPressed: _stopping
                                  ? null
                                  : () {
                                      _shortcutFocusNode.requestFocus();
                                      unawaited(
                                        _command(
                                          widget.coordinator.togglePlayback,
                                        ),
                                      );
                                    },
                              icon: Icon(
                                _snapshot.playing
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(_snapshot.playing ? 'Pause' : 'Play'),
                            ),
                            IconButton(
                              key: const ValueKey('forward-10'),
                              tooltip: 'Avanzar 10 segundos',
                              onPressed: _canSeek
                                  ? () => _seekStep(
                                      spikePlayerKeyboardSeekSeconds,
                                    )
                                  : null,
                              icon: const Icon(Icons.forward_10),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('player-stop'),
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                              onPressed: _stopping
                                  ? null
                                  : () => _command(_stopPlayback),
                            ),
                            IconButton(
                              key: const ValueKey('player-mute'),
                              tooltip: _snapshot.volume == 0
                                  ? 'Restaurar volumen'
                                  : 'Silenciar',
                              onPressed: _toggleMute,
                              icon: Icon(
                                _snapshot.volume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                              ),
                            ),
                            TextButton(
                              onPressed: _showVolume,
                              child: Text(
                                'Volume: ${_snapshot.volume.round()}%',
                              ),
                            ),
                            if (!_snapshot.stopped &&
                                _snapshot.status !=
                                    PlaybackSessionStatus.switchingSource)
                              AudioTrackSelector(
                                tracks: _snapshot.playback.audioTracks,
                                selectedId: _snapshot.playback.selectedAudioId,
                                generation: trackGeneration,
                                mediaContextRevision: trackMediaContextRevision,
                                onSelected:
                                    (
                                      String id,
                                      int generation,
                                      int mediaContextRevision,
                                    ) {
                                      if (generation !=
                                              widget
                                                  .coordinator
                                                  .state
                                                  .sourceGeneration ||
                                          mediaContextRevision !=
                                              widget
                                                  .coordinator
                                                  .mediaContextRevision ||
                                          widget.coordinator.state.stopped) {
                                        return;
                                      }
                                      unawaited(
                                        _command(
                                          () => widget.coordinator
                                              .selectAudioTrack(
                                                id,
                                                generation: generation,
                                              ),
                                        ),
                                      );
                                    },
                              ),
                            if (!_snapshot.stopped &&
                                _snapshot.status !=
                                    PlaybackSessionStatus.switchingSource)
                              PlayerQualityPanel(
                                tracks: _snapshot.playback.videoTracks,
                                selectedId: _snapshot.playback.selectedVideoId,
                                generation: trackGeneration,
                                mediaContextRevision: trackMediaContextRevision,
                                onSelected:
                                    (
                                      String id,
                                      int generation,
                                      int mediaContextRevision,
                                    ) {
                                      if (generation !=
                                              widget
                                                  .coordinator
                                                  .state
                                                  .sourceGeneration ||
                                          mediaContextRevision !=
                                              widget
                                                  .coordinator
                                                  .mediaContextRevision ||
                                          widget.coordinator.state.stopped) {
                                        return;
                                      }
                                      unawaited(
                                        _command(
                                          () => widget.coordinator
                                              .selectVideoTrack(
                                                id,
                                                generation: generation,
                                              ),
                                        ),
                                      );
                                    },
                              ),

                            IconButton(
                              key: const ValueKey('player-subtitles'),
                              tooltip: 'Subtítulos',
                              onPressed: _showSubtitles,
                              icon: const Icon(Icons.closed_caption_outlined),
                            ),
                            IconButton(
                              key: const ValueKey('player-nerd'),
                              tooltip: _nerdVisible
                                  ? 'Cerrar Modo Nerd'
                                  : 'Modo Nerd',
                              onPressed: _toggleNerd,
                              icon: Icon(
                                _nerdVisible
                                    ? Icons.analytics
                                    : Icons.analytics_outlined,
                              ),
                            ),
                            PlayerVideoDisplayButton(display: _display),
                            IconButton(
                              key: const ValueKey<String>('fullscreen-toggle'),
                              tooltip: _windowSnapshot.fullscreen
                                  ? 'Exit fullscreen'
                                  : 'Enter fullscreen',
                              onPressed: _windowSnapshot.requestPending
                                  ? null
                                  : () {
                                      _shortcutFocusNode.requestFocus();
                                      unawaited(_command(_toggleFullscreen));
                                    },
                              icon: Icon(
                                _windowSnapshot.fullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _PlayerShortcutManager extends ShortcutManager {
  _PlayerShortcutManager(this.shouldIgnore);

  final bool Function() shouldIgnore;

  @override
  KeyEventResult handleKeypress(BuildContext context, KeyEvent event) {
    if (shouldIgnore()) return KeyEventResult.ignored;
    return super.handleKeypress(context, event);
  }
}

final class _TogglePlaybackIntent extends Intent {
  const _TogglePlaybackIntent();
}

final class _SeekPlaybackIntent extends Intent {
  const _SeekPlaybackIntent(this.delta);
  final Duration delta;
}

final class _VolumePlaybackIntent extends Intent {
  const _VolumePlaybackIntent(this.delta);
  final double delta;
}

final class _ToggleFullscreenIntent extends Intent {
  const _ToggleFullscreenIntent();
}

final class _ExitFullscreenIntent extends Intent {
  const _ExitFullscreenIntent();
}

String _formatPlaybackTime(Duration duration) {
  final int totalSeconds = duration.inSeconds.clamp(0, 1 << 31);
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  final String minutePart = minutes.toString().padLeft(2, '0');
  final String secondPart = seconds.toString().padLeft(2, '0');
  if (hours == 0) return '$minutePart:$secondPart';
  return '$hours:$minutePart:$secondPart';
}
