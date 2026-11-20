import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'capture_sources.dart';

void main() {
  for (final entry in sourceCases.entries) {
    test(
      '${entry.key} preserves source data and exact HTTP requests',
      () async {
        final expected = jsonDecode(
          File('test/golden/refactor/${entry.key}_sources.json')
              .readAsStringSync(),
        );
        final actual = jsonDecode(jsonEncode(await entry.value()));
        expect(actual, expected);
      },
      skip: entry.key == 'allanime'
          ? 'B0-09: DateTime.now changes aaReq; frozen expectation retained'
          : false,
    );
  }
  test('AllAnime preserves exact source output independently of timestamped request', () async {
    final expected = jsonDecode(
      File('test/golden/refactor/allanime_sources.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final actual = jsonDecode(
      jsonEncode(await sourceCases['allanime']!()),
    ) as Map<String, dynamic>;
    expect(actual['sources'], expected['sources']);
  });
}
