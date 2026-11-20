import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'transport_snapshots.dart';

void main() {
  test(
    'wire decoding, direct media and manual source JSON retain exact output',
    () {
      final expected = jsonDecode(
        File('test/golden/refactor/transport_outputs.json').readAsStringSync(),
      );
      final actual = transportSnapshots();
      expect(actual['plain'], actual['xorGzip']);
      expect(actual, expected);
    },
  );
}
