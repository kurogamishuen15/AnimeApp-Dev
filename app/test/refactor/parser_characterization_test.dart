import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'parser_snapshots.dart';

void main() {
  test('current HTML, Miruro and AnimeAV1 parsers match frozen output', () {
    final expected = jsonDecode(
      File('test/golden/refactor/parser_outputs.json').readAsStringSync(),
    );
    expect(parserSnapshots(), expected);
  });
  test('public Miruro media preserves source order, qualities and headers', () {
    final actual = parserSnapshots(publicMedia: true);
    final miruro = actual['miruro']! as Map<String, Object?>;
    expect(miruro['sources'], isNotEmpty);
    final expected = jsonDecode(
      File('test/golden/refactor/parser_public_media_outputs.json')
          .readAsStringSync(),
    );
    expect(actual, expected);
  });
}
