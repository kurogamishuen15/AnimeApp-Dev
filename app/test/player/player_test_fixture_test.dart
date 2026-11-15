import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'player_test_fixture.dart';

void main() {
  test('rejects a symlink at every fixture directory level', () async {
    final File realFixture = resolveF2_2Fixture();
    final Directory projectRoot = realFixture.parent.parent.parent.parent;
    final Directory scratch = Directory(
      '${projectRoot.path}/.ai-local/f2.2/fixture-path-check-$pid',
    );
    await scratch.create(recursive: true);

    try {
      final List<String> linkedDirectories = [
        '.ai-local',
        '.ai-local/f2.2',
        '.ai-local/f2.2/fixtures',
      ];
      for (int index = 0; index < linkedDirectories.length; index++) {
        final Directory fakeRoot = Directory('${scratch.path}/root-$index');
        await fakeRoot.create(recursive: true);
        await File('${fakeRoot.path}/AGENTS.md').writeAsString('test root');
        await Directory('${fakeRoot.path}/app').create();
        await File('${fakeRoot.path}/app/pubspec.yaml')
            .writeAsString('name: test');

        final String linkedRelative = linkedDirectories[index];
        final Directory linkPath = Directory(
          '${fakeRoot.path}/$linkedRelative',
        );
        await linkPath.parent.create(recursive: true);

        final Directory target = Directory('${fakeRoot.path}/redirect-target');
        final Directory targetFixtureDirectory = switch (linkedRelative) {
          '.ai-local' => Directory('${target.path}/f2.2/fixtures'),
          '.ai-local/f2.2' => Directory('${target.path}/fixtures'),
          _ => target,
        };
        await targetFixtureDirectory.create(recursive: true);
        await File('${targetFixtureDirectory.path}/spike.mp4')
            .writeAsBytes([0]);
        await Link(linkPath.path).create(target.path);

        expect(
          () => resolveF2_2Fixture(projectRootForTesting: fakeRoot),
          throwsStateError,
          reason: linkedRelative,
        );
      }
    } finally {
      if (await scratch.exists()) await scratch.delete(recursive: true);
    }
  });
}
