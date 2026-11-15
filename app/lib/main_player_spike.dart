import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app/player/player_demo_panel.dart';
import 'app/player/spike_player_module.dart';
import 'app/player/spike_window_close_gate.dart';
import 'application/player/playback_spike_contract.dart';
import 'application/player/player_demo_session.dart';
import 'data/opensubtitles/opensubtitles_client.dart';
import 'data/player/engine/media_kit_spike_engine.dart';

const MethodChannel _windowChannel = MethodChannel('kongroo/f2.2/window');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.environment['KONGROO_F2_2_SPIKE'] != '1') {
    throw StateError(
      'Launch the F2.2 window with tools/player/run_f2_2_spike.sh.',
    );
  }
  final String? rootPath = Platform.environment['KONGROO_PROJECT_ROOT'];
  if (rootPath == null || rootPath.isEmpty) {
    throw StateError(
      'Set KONGROO_PROJECT_ROOT with tools/player/run_f2_2_spike.sh.',
    );
  }
  final Directory root = Directory(rootPath).absolute;
  final String canonicalRoot = root.resolveSymbolicLinksSync();
  if (!File('$canonicalRoot/AGENTS.md').existsSync() ||
      !File('$canonicalRoot/app/pubspec.yaml').existsSync()) {
    throw StateError('KONGROO_PROJECT_ROOT is not the project root.');
  }
  final bool useSubtitleFixture =
      Platform.environment['KONGROO_F2_6_SUBTITLE_FIXTURE'] == '1';
  final String? demoPorts = Platform.environment['KONGROO_DEMO_PORTS'];
  final bool realMedia = Platform.environment['KONGROO_DEMO_REAL_MEDIA'] == '1';
  final PlayerDemoCatalog? demo = demoPorts == null
      ? null
      : PlayerDemoCatalog(
          '$canonicalRoot/.ai-local/player-demo${realMedia ? '/real' : ''}',
          demoPorts.split(',').map(int.parse),
          realMedia: realMedia,
        );
  final List<String> fixtureDirectories = [
    if (demo != null) '.ai-local/player-demo',
    if (demo != null && realMedia) '.ai-local/player-demo/real',
    '.ai-local',
    if (demo == null) '.ai-local/f2.2',
    if (demo == null) '.ai-local/f2.2/fixtures',
    if (demo == null && useSubtitleFixture) '.ai-local/f2.6',
    if (demo == null && useSubtitleFixture) '.ai-local/f2.6/fixtures',
  ];
  for (final String relativePath in fixtureDirectories) {
    final String directoryPath = '$canonicalRoot/$relativePath';
    if (FileSystemEntity.typeSync(directoryPath, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw StateError('The project-local F2.2 fixture directory is invalid.');
    }
  }
  final File fixture = demo != null
      ? File.fromUri(demo.source(1, 0))
      : File(
          useSubtitleFixture
              ? '$canonicalRoot/.ai-local/f2.6/fixtures/subtitles-v2.mkv'
              : '$canonicalRoot/.ai-local/f2.2/fixtures/spike.mp4',
        );
  if (FileSystemEntity.typeSync(fixture.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw StateError('The project-local F2.2 fixture is not a regular file.');
  }
  final OpenSubtitlesClient subtitleCatalog = OpenSubtitlesClient(
    apiKey: () async => Platform.environment['OPENSUBTITLES_API_KEY'],
  );
  runApp(
    SpikePlayerApp(
      demo: demo,
      moduleFuture:
          SpikePlayerModule.open(
            fixture,
            demoSources: demo?.loopbackSources ?? const {},
            externalSubtitleCatalog: subtitleCatalog,
            disposeExternalSubtitleCatalog: subtitleCatalog.close,
          ).then((module) async {
            if (demo != null) {
              try {
                final coordinator = module.coordinator;
                final String? language =
                    Platform.environment['KONGROO_DEMO_SUBTITLES'];
                final int start =
                    int.tryParse(
                      Platform.environment['KONGROO_DEMO_START'] ?? '',
                    ) ??
                    0;
                if (language != null && language.isNotEmpty || start > 0) {
                  bool ready(PlaybackSessionSnapshot state) =>
                      state.duration > Duration.zero &&
                      (language == null ||
                          language.isEmpty ||
                          state.subtitleTracks.any(
                            (track) => track.language == language,
                          ));
                  if (!ready(coordinator.state)) {
                    await coordinator.states
                        .firstWhere(ready)
                        .timeout(const Duration(seconds: 12));
                  }
                  if (start > 0) {
                    await coordinator.seek(Duration(seconds: start));
                  }
                  if (language != null && language.isNotEmpty) {
                    final track = coordinator.state.subtitleTracks.firstWhere(
                      (track) => track.language == language,
                    );
                    await coordinator.selectSubtitleTrack(track.id);
                  }
                }
                if (Platform.environment['KONGROO_DEMO_AUTOPLAY'] == '1') {
                  await coordinator.play();
                }
              } on Object {
                await module.close();
                rethrow;
              }
            }
            return module;
          }),
      retryPendingCleanup: MediaKitSpikeEngine.retryPendingDispose,
    ),
  );
}

final class SpikePlayerApp extends StatefulWidget {
  const SpikePlayerApp({
    required this.moduleFuture,
    this.demo,
    this.retryPendingCleanup = MediaKitSpikeEngine.retryPendingDispose,
    this.closeWatchdog = const Duration(seconds: 15),
    super.key,
  });

  final Future<SpikePlayerModule> moduleFuture;
  final PlayerDemoCatalog? demo;
  final Future<void> Function() retryPendingCleanup;
  @visibleForTesting
  final Duration closeWatchdog;

  @override
  State<SpikePlayerApp> createState() => _SpikePlayerAppState();
}

final class _SpikePlayerAppState extends State<SpikePlayerApp> {
  late final Future<SpikePlayerModule> _moduleFuture = widget.moduleFuture;
  late final SpikeWindowCloseGate _closeGate = SpikeWindowCloseGate(
    () async {
      await (await _moduleFuture).close();
      debugPrint('KONGROO_F2_2_CLEANUP_COMPLETED');
    },
    widget.retryPendingCleanup,
    () {
      if (mounted) {
        setState(() {
          _closeError = 'Playback cleanup failed. The window will stay open; retry closing after checking the player.';
        });
      }
    },
    closeWatchdog: widget.closeWatchdog,
    onCleanupPending: () {
      if (mounted) {
        setState(() {
          _closeError = 'Playback cleanup is still running. No native operation was cancelled; the window will stay open. Retry closing after cleanup finishes.';
        });
      }
    },
  );
  String? _closeError;

  @override
  void initState() {
    super.initState();
    _windowChannel.setMethodCallHandler(_handleWindowMethod);
  }

  Future<Object?> _handleWindowMethod(MethodCall call) {
    if (call.method != 'requestClose') {
      return Future<Object?>.error(
        MissingPluginException('Unsupported window method.'),
      );
    }
    // The gate may reply false after its watchdog so GTK keeps the window.
    // The original cleanup Future remains active; no native operation is
    // cancelled and a repeated close request shares that same Future.
    return _closeGate.requestClose();
  }

  @override
  void dispose() {
    _windowChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: FutureBuilder<SpikePlayerModule>(
      future: _moduleFuture,
      builder: (BuildContext context, AsyncSnapshot<SpikePlayerModule> state) {
        final SpikePlayerModule? module = state.data;
        if (module == null) {
          return _buildSpikeStartupStatus(
            message: state.hasError
                ? 'The F2.2 player could not be opened.'
                : 'Opening the F2.2 player…',
            closeError: _closeError,
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            module.build(
              demoControls: widget.demo == null
                  ? null
                  : PlayerDemoPanel(
                      catalog: widget.demo!,
                      coordinator: module.coordinator,
                    ),
            ),
            if (_closeError case final String message) _closeNotice(message),
          ],
        );
      },
    ),
  );
}

Widget _buildSpikeStartupStatus({
  required String message,
  String? closeError,
}) => Stack(
  fit: StackFit.expand,
  children: [
    Scaffold(body: Center(child: Text(message))),
    if (closeError case final String value) _closeNotice(value),
  ],
);

Widget _closeNotice(String message) => Positioned(
  left: 16,
  right: 16,
  top: 16,
  child: Material(
    color: Colors.red.shade900,
    child: Padding(padding: const EdgeInsets.all(12), child: Text(message)),
  ),
);
