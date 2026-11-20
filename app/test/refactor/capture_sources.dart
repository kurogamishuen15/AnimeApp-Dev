import 'dart:convert';
import 'dart:io';

import '../fixtures/refactor/allanime_harness.dart' as allanime;
import '../fixtures/refactor/animeav1_harness.dart' as animeav1;
import '../fixtures/refactor/animegg_harness.dart' as animegg;
import '../fixtures/refactor/anizone_harness.dart' as anizone;
import '../fixtures/refactor/megaplay_harness.dart' as megaplay;

import '../fixtures/refactor/voe_harness.dart' as voe;
import '../fixtures/refactor/wikimedia_harness.dart' as wikimedia;

final sourceCases = {
  'voe': voe.snapshot,
  'wikimedia': wikimedia.snapshot,
  'allanime': allanime.snapshot,
  'animeav1': animeav1.snapshot,
  'animegg': animegg.snapshot,
  'anizone': anizone.snapshot,
  'megaplay': megaplay.snapshot,
};

Future<void> main(List<String> arguments) async {
  for (final entry in sourceCases.entries) {
    if (arguments.isNotEmpty && !arguments.contains(entry.key)) continue;
    try {
      final output = await entry.value();
      final file = File('test/golden/refactor/${entry.key}_sources.json');
      if (file.existsSync()) {
        throw StateError('Refusing to overwrite frozen output');
      }
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(output)}\n',
      );
      stdout.writeln('${entry.key}: captured nonempty sources');
    } on Object catch (error) {
      stderr.writeln('${entry.key}: $error');
      exitCode = 1;
    }
  }
}
