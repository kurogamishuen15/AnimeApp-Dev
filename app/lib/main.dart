import 'dart:async';
import 'dart:io';

import 'package:anime_app/app/anime_app.dart';
import 'package:material_ui/material_ui.dart';

import 'app/catalog/catalog_module.dart';
import 'data/player/providers/playback_providers_module.dart';
import 'data/player/providers/user_sources/user_defined_playback_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 120
    ..maximumSizeBytes = 48 * 1024 * 1024;
  final CatalogModule module = await CatalogModule.open(
    databaseFile: await _isolatedDatabaseOverride(),
  );
  final PlaybackProvidersModule playbackModule = PlaybackProvidersModule.open(
    enableMiruro: Platform.environment['KONGROO_ENABLE_MIRURO'] != '0',
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

  // F0.6 opt-in marker: engine rasterization is not proof that the compositor
  // presented a visible window. Keep normal launches side-effect free.
  final markerPath = Platform.environment['ANIMEAPP_FIRST_FRAME_MARKER'];
  if (markerPath != null && markerPath.isNotEmpty) {
    unawaited(_writeFirstFrameMarker(markerPath));
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
