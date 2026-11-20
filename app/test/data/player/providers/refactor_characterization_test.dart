import 'dart:convert';
import 'dart:io';

import 'package:anime_app/data/player/providers/miruro/miruro_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Miruro config preserves exact pre-refactor output', () {
    final fixture = File('test/fixtures/refactor/miruro_config.json')
        .readAsStringSync();
    final expected = jsonDecode(
      File('test/golden/refactor/miruro_config.json').readAsStringSync(),
    );
    final actual = const MiruroCatalogParser()
        .parseConfig(fixture)
        .map(
          (value) => {
            'key': value.key,
            'label': value.label,
            'visible': value.visible,
            'parent': value.parent,
            'isEmbed': value.isEmbed,
            'language': value.announcedLanguage,
          },
        )
        .toList();
    expect(actual, expected);
  });
}
