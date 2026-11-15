import 'dart:async';

import 'package:anime_app/app/player/external_subtitle_search_panel.dart';
import 'package:anime_app/application/player/external_subtitles/external_subtitle_service.dart';
import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final class _Catalog implements ExternalSubtitleCatalog {
  int searches = 0;
  int downloads = 0;
  final ExternalSubtitleCandidate candidate = const ExternalSubtitleCandidate(
    subtitleId: 'fixture-subtitle',
    fileId: 73,
    fileName: 'episode.srt',
    language: 'en',
    format: 'srt',
  );

  @override
  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  ) async {
    searches++;
    return ExternalSubtitleSuccess([candidate, _partTwo]);
  }

  static const ExternalSubtitleCandidate _partTwo = ExternalSubtitleCandidate(
    subtitleId: 'multipart-subtitle',
    fileId: 74,
    fileName: 'episode.cd2.srt',
    language: 'en',
    format: 'srt',
    partNumber: 2,
    partCount: 2,
  );

  @override
  Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download(
    ExternalSubtitleCandidate candidate,
  ) async {
    downloads++;
    return ExternalSubtitleSuccess(
      ExternalSubtitleDownload(
        uri: Uri.parse('file:///tmp/fixture-73.srt'),
        format: 'srt',
        language: 'en',
        remainingDownloads: 4,
        resetAt: null,
      ),
    );
  }
}

final class _Loader implements ExternalSubtitleLoader {
  @override
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
    int? sourceGeneration,
  }) async => externalSubtitleDecision(hardsubStatus);
}

final class _DeferredSearchCatalog implements ExternalSubtitleCatalog {
  final Completer<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>>
  result = Completer<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>>();
  final List<ExternalSubtitleQuery> requests = [];

  @override
  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  ) {
    requests.add(query);
    return result.future;
  }

  @override
  Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download(
    ExternalSubtitleCandidate candidate,
  ) async => throw UnimplementedError();
}

void main() {
  testWidgets('searches, displays candidate and loads via service', (
    WidgetTester tester,
  ) async {
    final _Catalog catalog = _Catalog();
    final ExternalSubtitleService service = ExternalSubtitleService(
      catalog: catalog,
      loader: _Loader(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExternalSubtitleSearchPanel(service: service)),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('external-subtitle-query')),
      'Episode 1',
    );
    await tester.tap(find.byKey(const ValueKey('external-subtitle-search')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(catalog.searches, 1);
    expect(find.text('EN · SRT'), findsOneWidget);
    expect(find.text('EN · SRT · Part 2/2'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('external-subtitle-download-73')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(catalog.downloads, 1);
    expect(
      find.text('Subtitle loaded; hardsub status is unknown.'),
      findsOneWidget,
    );
  });

  testWidgets('empty search reports validation without calling service', (
    WidgetTester tester,
  ) async {
    final _Catalog catalog = _Catalog();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExternalSubtitleSearchPanel(
            service: ExternalSubtitleService(
              catalog: catalog,
              loader: _Loader(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('external-subtitle-search')));
    await tester.pump();
    expect(find.text('Enter an anime or episode title.'), findsOneWidget);
    expect(catalog.searches, 0);
  });

  testWidgets('search input is bounded to the domain query limit', (
    WidgetTester tester,
  ) async {
    final _Catalog catalog = _Catalog();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExternalSubtitleSearchPanel(
            service: ExternalSubtitleService(
              catalog: catalog,
              loader: _Loader(),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('external-subtitle-query')),
      List.filled(201, 'x').join(),
    );
    final TextField field = tester.widget(
      find.byKey(const ValueKey('external-subtitle-query')),
    );
    expect(field.controller!.text.length, lessThanOrEqualTo(200));
    await tester.tap(find.byKey(const ValueKey('external-subtitle-search')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(catalog.searches, 1);
  });

  testWidgets('submitted search cannot race an in-flight request', (
    WidgetTester tester,
  ) async {
    final _DeferredSearchCatalog catalog = _DeferredSearchCatalog();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExternalSubtitleSearchPanel(
            service: ExternalSubtitleService(
              catalog: catalog,
              loader: _Loader(),
            ),
          ),
        ),
      ),
    );
    final Finder queryField = find.byKey(
      const ValueKey<String>('external-subtitle-query'),
    );
    await tester.enterText(queryField, 'First query');
    await tester.tap(
      find.byKey(const ValueKey<String>('external-subtitle-search')),
    );
    await tester.pump();

    expect(catalog.requests, hasLength(1));
    final TextField busyField = tester.widget(queryField);
    expect(busyField.enabled, isFalse);
    busyField.onSubmitted!('Second query');
    await tester.pump();
    expect(catalog.requests, hasLength(1));
    expect(catalog.requests.single.query, 'First query');

    catalog.result.complete(
      ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>([
        const ExternalSubtitleCandidate(
          subtitleId: 'first-result',
          fileId: 91,
          fileName: 'first.srt',
          language: 'en',
          format: 'srt',
        ),
      ]),
    );
    await tester.pump();
    expect(find.text('EN · SRT'), findsOneWidget);
    expect(tester.widget<TextField>(queryField).enabled, isTrue);
  });
}
