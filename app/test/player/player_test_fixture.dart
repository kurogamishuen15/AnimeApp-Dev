import 'dart:io';

/// Resolves the ignored F2.2 fixture from either the project root or app/.
/// Tests can also set KONGROO_PROJECT_ROOT to make their working directory
/// irrelevant. No general parent-directory search is performed.
File resolveF2_2Fixture({Directory? projectRootForTesting}) {
  final String? configuredRoot = Platform.environment['KONGROO_PROJECT_ROOT'];
  final Directory root;
  if (projectRootForTesting != null) {
    root = projectRootForTesting.absolute;
  } else if (configuredRoot != null && configuredRoot.isNotEmpty) {
    root = Directory(configuredRoot).absolute;
  } else {
    final Directory current = Directory.current.absolute;
    if (_isProjectRoot(current)) {
      root = current;
    } else if (_isProjectRoot(current.parent) &&
        File('${current.path}/pubspec.yaml').existsSync()) {
      root = current.parent;
    } else {
      throw StateError(
        'Run player tests from the project root or app/, or set '
        'KONGROO_PROJECT_ROOT.',
      );
    }
  }

  if (!_isProjectRoot(root)) {
    throw StateError('KONGROO_PROJECT_ROOT is not the Kongroo project root.');
  }
  final String canonicalRoot = root.resolveSymbolicLinksSync();
  final File fixture = File('$canonicalRoot/.ai-local/f2.2/fixtures/spike.mp4');
  _validateFixtureDirectories(canonicalRoot, requireExisting: false);
  if (FileSystemEntity.typeSync(fixture.path, followLinks: false) ==
      FileSystemEntityType.notFound) {
    final String generator =
        '$canonicalRoot/tools/player/generate_f2_2_fixture.sh';
    final ProcessResult result = Process.runSync('bash', [
      generator,
    ], workingDirectory: canonicalRoot);
    if (result.exitCode != 0) {
      throw StateError(
        'Could not generate the F2.2 test fixture (exit '
        '${result.exitCode}): ${result.stderr}',
      );
    }
  }
  _validateFixtureDirectories(canonicalRoot, requireExisting: true);
  if (FileSystemEntity.typeSync(fixture.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw StateError('The F2.2 test fixture is not a regular local file.');
  }
  return fixture;
}

File resolveF2_6SubtitleFixture() {
  return _resolveF2_6Fixture('subtitles-v2.mkv');
}

File resolveF2_6MovTextFixture() {
  return _resolveF2_6Fixture('mov-text.mp4');
}

File _resolveF2_6Fixture(String fileName) {
  final File baseline = resolveF2_2Fixture();
  final String projectRoot = baseline.parent.parent.parent.parent.path;
  final Directory fixtureDirectory = Directory(
    '$projectRoot/.ai-local/f2.6/fixtures',
  );
  for (final String relativePath in [
    '.ai-local',
    '.ai-local/f2.6',
    '.ai-local/f2.6/fixtures',
  ]) {
    final FileSystemEntityType type = FileSystemEntity.typeSync(
      '$projectRoot/$relativePath',
      followLinks: false,
    );
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw StateError('The project-local F2.6 fixture path is invalid.');
    }
  }
  final File fixture = File('${fixtureDirectory.path}/$fileName');
  if (FileSystemEntity.typeSync(fixture.path, followLinks: false) ==
      FileSystemEntityType.notFound) {
    final ProcessResult result = Process.runSync('bash', [
      '$projectRoot/tools/player/generate_f2_6_subtitle_fixture.sh',
    ], workingDirectory: projectRoot);
    if (result.exitCode != 0) {
      throw StateError(
        'Could not generate the F2.6 subtitle fixture (exit '
        '${result.exitCode}): ${result.stderr}',
      );
    }
  }
  if (FileSystemEntity.typeSync(fixture.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw StateError('The F2.6 subtitle fixture is not a regular local file.');
  }
  return fixture;
}

bool _isProjectRoot(Directory directory) =>
    File('${directory.path}/AGENTS.md').existsSync() &&
    File('${directory.path}/app/pubspec.yaml').existsSync();

void _validateFixtureDirectories(String root, {required bool requireExisting}) {
  for (final String relativePath in [
    '.ai-local',
    '.ai-local/f2.2',
    '.ai-local/f2.2/fixtures',
  ]) {
    final FileSystemEntityType type = FileSystemEntity.typeSync(
      '$root/$relativePath',
      followLinks: false,
    );
    if (type == FileSystemEntityType.link ||
        (requireExisting && type != FileSystemEntityType.directory) ||
        (!requireExisting &&
            type != FileSystemEntityType.directory &&
            type != FileSystemEntityType.notFound)) {
      throw StateError('The project-local F2.2 fixture directory is invalid.');
    }
  }
}
