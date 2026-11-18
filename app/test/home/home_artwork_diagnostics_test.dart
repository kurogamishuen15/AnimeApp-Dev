import 'dart:io';

import 'package:anime_app/app/home/home_artwork.dart';
import 'package:anime_app/app/home/home_artwork_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('classifies failures without exposing URL details', () {
    expect(
      HomeArtworkDiagnostics.classify(
        NetworkImageLoadException(
          statusCode: 403,
          uri: Uri.parse('https://a.test/x'),
        ),
      ),
      'http_403',
    );
    expect(
      HomeArtworkDiagnostics.classify(const SocketException('dns fail')),
      'socket',
    );
    expect(HomeArtworkDiagnostics.classify(const HttpException('x')), 'http');
    expect(
      HomeArtworkDiagnostics.classify(Exception('Invalid image data.')),
      'decode',
    );
  });

  test('logs only the host, never the query or path', () {
    final HomeArtworkDiagnostics diagnostics = HomeArtworkDiagnostics.instance;
    final List<String> lines = [];
    final void Function(String) previous = diagnostics.sink;
    diagnostics.sink = lines.add;
    addTearDown(() => diagnostics.sink = previous);

    diagnostics.reportFailure(
      'https://img.test/poster.jpg?token=SECRET123',
      const HttpException('boom'),
    );

    expect(lines.single, 'home_artwork_failed kind=http host=img.test');
    expect(lines.join(), isNot(contains('SECRET123')));
    expect(lines.join(), isNot(contains('poster.jpg')));
    expect(HomeArtworkDiagnostics.safeHost('not a url'), 'invalid');
  });

  testWidgets('a failed network poster is counted and falls back', (
    tester,
  ) async {
    final HomeArtworkDiagnostics diagnostics = HomeArtworkDiagnostics.instance;
    final List<String> lines = [];
    final void Function(String) previous = diagnostics.sink;
    diagnostics.sink = lines.add;
    addTearDown(() => diagnostics.sink = previous);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeArtwork(
          asset: null,
          width: 120,
          height: 180,
          url: 'https://img.test/poster.jpg?token=SECRET123',
        ),
      ),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && lines.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });

    expect(lines, isNotEmpty);
    expect(lines.join(), contains('host=img.test'));
    expect(lines.join(), isNot(contains('SECRET123')));
  });
}
