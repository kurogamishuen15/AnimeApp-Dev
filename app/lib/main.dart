import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:anime_app/app/anime_app.dart';
import 'package:material_ui/material_ui.dart';

import 'app/catalog/catalog_module.dart';
import 'data/player/providers/miruro/miruro_catalog_api.dart';
import 'data/player/providers/miruro/miruro_http2_client.dart';
import 'data/player/providers/miruro/miruro_media_proxy.dart';
import 'data/player/providers/public_playback_http.dart';
import 'data/player/providers/playback_providers_module.dart';
import 'data/player/providers/user_sources/user_defined_playback_provider.dart';
import 'domain/player/providers/playback_provider_contract.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 120
    ..maximumSizeBytes = 48 * 1024 * 1024;
  final CatalogModule module = await CatalogModule.open(
    databaseFile: await _isolatedDatabaseOverride(),
  );
  // Flag: KONGROO_ENABLE_MIRURO_BACKEND on by default; =0 turns it off.
  // The old KONGROO_ENABLE_MIRURO is no longer required for backend activation.
  final bool miruroEnabled =
      Platform.environment['KONGROO_ENABLE_MIRURO_BACKEND'] != '0';
  // The Miruro backend publishes its media through a loopback proxy, so the
  // engine never holds a backend CDN URL. Starting it here keeps the module
  // composition (and every test) synchronous.
  final MiruroMediaProxy? miruroProxy = await _startMiruroProxy(miruroEnabled);
  final PlaybackProvidersModule playbackModule = PlaybackProvidersModule.open(
    enableMiruro: miruroEnabled,
    miruroProxy: miruroProxy,
    enableMegaPlay: Platform.environment['KONGROO_ENABLE_MEGAPLAY'] != '0',
    enableAnimeAv1: Platform.environment['KONGROO_ENABLE_ANIMEAV1'] != '0',
    enableAllAnime: Platform.environment['KONGROO_ENABLE_ALLANIME'] != '0',
    enableAniZone: Platform.environment['KONGROO_ENABLE_ANIZONE'] != '0',
    enableAnimeGg: Platform.environment['KONGROO_ENABLE_ANIMEGG'] != '0',
    enableWikimedia: Platform.environment['KONGROO_ENABLE_WIKIMEDIA'] == '1',
    userSources: await _userSourcesFromEnvironment(),
  );
  runApp(
    AnimeApp(catalogService: module.service, playbackModule: playbackModule),
  );

  // Start the Miruro health probe after the first frame so it never blocks
  // startup or the first paint. It runs in the background with a 4 s timeout
  // per probe and a 5 min interval between probes; errors are swallowed.
  final Set<String> miruroAllowedHosts = {'www.miruro.cx'};
  final MiruroCatalogApi miruroApi = MiruroCatalogApi(
    PublicPlaybackHttp(Dio(), miruroAllowedHosts),
    transport: MiruroHttp2Client(),
  );
  _startHealthProbe(miruroApi);

  // F0.6 opt-in marker: engine rasterization is not proof that the compositor
  // presented a visible window. Keep normal launches side-effect free.
  final markerPath = Platform.environment['ANIMEAPP_FIRST_FRAME_MARKER'];
  if (markerPath != null && markerPath.isNotEmpty) {
    unawaited(_writeFirstFrameMarker(markerPath));
  }
}

/// Starts the loopback media proxy, tolerating a host that forbids binding.
Future<MiruroMediaProxy?> _startMiruroProxy(bool enabled) async {
  if (!enabled) return null;
  try {
    return await MiruroMediaProxy.start();
  } on SocketException {
    return null;
  }
}

/// Asynchronous health probe for the Miruro catalog backend.
///
/// Runs after the first frame rasterization so it never blocks application
/// startup or the first paint. Uses a 4-second timeout and refreshes the
/// provider cache on success or failure (every 5 min TTL is handled by the
/// provider itself). Errors are caught and discarded so the probe never
/// reaches the UI.
Future<void> _startHealthProbe(MiruroCatalogApi api) async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  // Run forever with 5 min interval between probes.
  Future<void> probeLoop() async {
    while (true) {
      try {
        await api.probeHealth(
          cancellation: PlaybackCancellationToken(),
        ).timeout(const Duration(seconds: 4));
      } on Object {
        // Any error (timeout, network, etc.) is silently swallowed.
      }
      await Future.delayed(const Duration(minutes: 5), () {});
    }
  }
  // Fire-and-forget: spawn a separate isolate so the loop never blocks the
  // UI isolate. All errors are caught inside the isolate.
  _spawnHealthProbeIsolate(api);
}

/// Spawns a separate isolate to run the Miruro health probe loop.
void _spawnHealthProbeIsolate(MiruroCatalogApi api) {
  Isolate.spawn(_healthProbeIsolateEntrypoint, api);
}

/// Entrypoint for the health-probe isolate. Each iteration probes /health
/// with a 4 s hard timeout; any error is swallowed so the UI never sees it.
void _healthProbeIsolateEntrypoint(Object apiObj) {
  final MiruroCatalogApi api = apiObj as MiruroCatalogApi;
  // Run forever with 5 min interval between probes.
  while (true) {
    try {
      api.probeHealth(
        cancellation: PlaybackCancellationToken(),
      ).timeout(const Duration(seconds: 4));
    } on Object {
      // Any error (timeout, network, etc.) is silently swallowed.
    }
    // 5 min TTL between probes.
    sleep(const Duration(minutes: 5));
  }
}

/// Optional list of episodes the user registered (`KONGROO_USER_SOURCES` points
/// to a JSON file). A missing variable means no user sources; an invalid file
/// is reported and ignored so the rest of the app still starts.
Future<List<UserDefinedSourceEntry>> _userSourcesFromEnvironment() async {
  final String? path = Platform.environment['KONGROO_USER_SOURCES'];
  if (path == null || path.trim().isEmpty) return const [];
  try {
    return UserDefinedSourceEntry.parseJson(await File(path).readAsString());
  } on Object {
    stderr.writeln('KONGROO_USER_SOURCES ignored: invalid configuration');
    return const [];
  }
}

Future<void> _writeFirstFrameMarker(String markerPath) async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  File(markerPath)
      .writeAsStringSync('${DateTime.now().toUtc().microsecondsSinceEpoch}');
}

/// Allows local Fedora validation without touching the user's Application
/// Support database. The override is accepted only under this project root.
Future<File?> _isolatedDatabaseOverride() async {
  final String? requestedPath = Platform.environment['KONGROO_DATABASE_PATH'];
  if (requestedPath == null || requestedPath.trim().isEmpty) return null;
  final Directory current = Directory.current.absolute;
  final Directory root = current.path.endsWith('${Platform.pathSeparator}app')
      ? current.parent
      : current;
  if (!File('${root.path}${Platform.pathSeparator}AGENTS.md').existsSync()) {
    throw StateError(
      'KONGROO_DATABASE_PATH is available only when launched from the project.',
    );
  }
  if (requestedPath.split(Platform.pathSeparator).contains('..')) {
    throw ArgumentError('KONGROO_DATABASE_PATH cannot contain parent paths.');
  }
  final Directory localData = Directory(
    '${root.path}${Platform.pathSeparator}.ai-local',
  );
  await _ensureLocalDirectory(localData.path);
  final File file = File(requestedPath).absolute;
  final String allowedPrefix = '${localData.path}${Platform.pathSeparator}';
  if (!file.path.startsWith(allowedPrefix)) {
    throw ArgumentError(
      'KONGROO_DATABASE_PATH must point inside project .ai-local/.',
    );
  }
  final String parentPath = file.parent.path;
  if (parentPath != localData.path && !parentPath.startsWith(allowedPrefix)) {
    throw ArgumentError(
      'KONGROO_DATABASE_PATH parent must remain inside project .ai-local/.',
    );
  }
  if (parentPath != localData.path) {
    String currentPath = localData.path;
    final String relative = parentPath.substring(allowedPrefix.length);
    for (final String segment in relative.split(Platform.pathSeparator)) {
      if (segment.isEmpty || segment == '.') continue;
      currentPath = '$currentPath${Platform.pathSeparator}$segment';
      await _ensureLocalDirectory(currentPath);
    }
  }
  if (FileSystemEntity.typeSync(file.path, followLinks: false) ==
      FileSystemEntityType.link) {
    throw StateError('Project-local database file cannot be a symbolic link.');
  }
  return file;
}

Future<void> _ensureLocalDirectory(String path) async {
  final FileSystemEntityType type = FileSystemEntity.typeSync(
    path,
    followLinks: false,
  );
  if (type == FileSystemEntityType.link) {
    throw StateError('Project-local data path cannot follow a symbolic link.');
  }
  if (type == FileSystemEntityType.notFound) {
    await Directory(path).create();
  } else if (type != FileSystemEntityType.directory) {
    throw StateError('Project-local database parent is not a directory.');
  }
}