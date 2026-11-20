import 'dart:io';

import 'package:anime_app/app/catalog/anime_detail_page.dart';
import 'package:anime_app/app/catalog/catalog_module.dart';
import 'package:anime_app/app/catalog/detail/anime_detail_header.dart';
import 'package:anime_app/app/home/home_appearance.dart';
import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/core/bootstrap/anime_app.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/domain/catalog/episode_index_provider.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:anime_app/domain/catalog/metadata_provenance.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:anime_app/domain/catalog/provider_result.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<Directory> _temporaryDatabaseDirectory() async {
  final Directory appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app')) {
    throw StateError('Run the catalog UI integration test from app/.');
  }
  final Directory projectDirectory = appDirectory.parent;
  if (!File('${projectDirectory.path}${Platform.pathSeparator}AGENTS.md')
          .existsSync() ||
      !Directory('${projectDirectory.path}${Platform.pathSeparator}.git')
          .existsSync()) {
    throw StateError('Could not verify project root for temporary DB cleanup.');
  }
  String testRoot = projectDirectory.path;
  for (final String segment in ['.ai-local', 'test-db', 'catalog-ui']) {
    testRoot = '$testRoot${Platform.pathSeparator}$segment';
    final FileSystemEntityType type = FileSystemEntity.typeSync(
      testRoot,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link) {
      throw StateError('Catalog UI test path cannot follow a symlink.');
    }
    if (type == FileSystemEntityType.notFound) {
      await Directory(testRoot).create();
    } else if (type != FileSystemEntityType.directory) {
      throw StateError('Catalog UI test path is not a directory.');
    }
  }
  final Directory directory = Directory(
    '$testRoot${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create();
  return directory;
}

Future<void> _pumpUntil(WidgetTester tester, Finder target) async {
  for (int attempt = 0; attempt < 80; attempt++) {
    if (target.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  throw StateError('Timed out waiting for a catalog UI state: $target');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('detail header and tabs adapt to a phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final Directory directory = (await tester.runAsync(
      _temporaryDatabaseDirectory,
    ))!;
    final HttpOverrides? previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _DenyNetworkOverrides();
    final CatalogModule module = (await tester.runAsync(
      () => CatalogModule.open(
        databaseFile: File('${directory.path}/catalog.sqlite'),
        useDemoProvider: true,
        episodeIndex: const _FixtureEpisodeIndex(),
        clock: () => DateTime.utc(2026, 11, 9, 12),
      ),
    ))!;
    try {
      final ProviderAnimeMetadata selected = await module.service
          .search('Jardín')
          .then(
            (result) =>
                result.fold((items) => items.single, (error) => throw error),
          );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            scaffoldBackgroundColor: HomeAppearance.background,
            extensions: const [HomeAppearance()],
          ),
          home: AnimeDetailPage(
            service: module.service,
            externalId: selected.externalId,
            fallbackTitle: selected.preferredTitle,
            initialMetadata: selected,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detail-back')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('detail-tab-information')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('detail-tab-links')), findsOneWidget);
      expect(find.text('Jardín orbital'), findsOneWidget);
      final Rect compactHeader = tester.getRect(
        find.byKey(const ValueKey('detail-cinematic-header')),
      );
      final Rect compactPoster = tester.getRect(
        find.byKey(const ValueKey('detail-poster')),
      );
      expect(compactHeader.height, 350);
      expect(compactPoster.size, const Size(96, 154));
      expect(compactPoster.top - compactHeader.top, 94);
      expect(
        find.byKey(const ValueKey('detail-header-synopsis')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.runAsync(module.close);
      HttpOverrides.global = previousOverrides;
      await tester.runAsync(() => directory.delete(recursive: true));
    }
  });

  testWidgets('compact cinematic header separates rich metadata and synopsis', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final Directory directory = (await tester.runAsync(
      _temporaryDatabaseDirectory,
    ))!;
    final CatalogModule module = (await tester.runAsync(
      () => CatalogModule.open(
        databaseFile: File('${directory.path}/catalog.sqlite'),
        useDemoProvider: true,
        episodeIndex: const _FixtureEpisodeIndex(),
      ),
    ))!;
    try {
      final ProviderAnimeMetadata selected = await module.service
          .search('Jardín')
          .then(
            (result) =>
                result.fold((items) => items.single, (error) => throw error),
          );
      final ProviderAnimeMetadata richMetadata = ProviderAnimeMetadata(
        externalId: selected.externalId,
        preferredTitle: 'Attack on Titan',
        romajiTitle: 'Shingeki no Kyojin',
        provenance: selected.provenance,
        format: AnimeFormat.tv,
        releaseYear: 2013,
        endYear: 2023,
        averageScore: 88,
        genres: const ['Acción', 'Drama', 'Fantasía', 'Suspenso'],
        synopsis:
            'La humanidad sobrevive tras enormes murallas que la protegen '
            'de titanes devoradores de personas.',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: AnimeDetailHeader(
              title: richMetadata.preferredTitle,
              metadata: richMetadata,
              entry: null,
              saving: false,
              onBack: () {},
              onAdd: () {},
              onStatus: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      final Rect info = tester.getRect(
        find.byKey(const ValueKey('detail-header-info')),
      );
      final Rect synopsis = tester.getRect(
        find.byKey(const ValueKey('detail-header-synopsis')),
      );
      expect(info.bottom, lessThanOrEqualTo(synopsis.top));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.runAsync(module.close);
      await tester.runAsync(() => directory.delete(recursive: true));
    }
  });

  testWidgets(
    'offline catalog search, details, library status and progress survive restart',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final Directory directory = (await tester.runAsync(
        _temporaryDatabaseDirectory,
      ))!;
      final File databaseFile = File('${directory.path}/catalog.sqlite');
      final HttpOverrides? previousOverrides = HttpOverrides.current;
      HttpOverrides.global = _DenyNetworkOverrides();
      CatalogModule module = (await tester.runAsync(
        () => CatalogModule.open(
          databaseFile: databaseFile,
          useDemoProvider: true,
          episodeIndex: const _FixtureEpisodeIndex(),
          clock: () => DateTime.utc(2026, 11, 9, 12),
        ),
      ))!;

      try {
        await tester.pumpWidget(AnimeApp(catalogService: module.service));
        await _pumpUntil(tester, find.text('Tendencias'));
        expect(find.text('Continue watching'), findsNothing);
        expect(find.text('Currently watching'), findsNothing);
        final card = find.text('Jardín orbital').hitTestable().first;
        await tester.ensureVisible(card);
        await tester.tap(card);
        await _pumpUntil(tester, find.byKey(const ValueKey('detail-back')));
        final Rect wideHeader = tester.getRect(
          find.byKey(const ValueKey('detail-cinematic-header')),
        );
        final Rect widePoster = tester.getRect(
          find.byKey(const ValueKey('detail-poster')),
        );
        expect(wideHeader.height, 400);
        expect(widePoster.size, const Size(188, 300));
        expect(widePoster.top - wideHeader.top, 62);
        await tester.tap(find.byKey(const ValueKey('detail-tab-information')));
        await _pumpUntil(
          tester,
          find.text('La tripulación de una estación cultiva el último jardín.'),
        );
        await tester.tap(find.byKey(const ValueKey('detail-back')));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Buscar'));
        await tester.pumpAndSettle();
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('catalog-search-field')),
        );
        expect(find.byTooltip('Perfil sin iniciar sesión'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('catalog-search-field')),
          'Jardín',
        );
        await tester.tap(find.byKey(const ValueKey('catalog-search-button')));
        await _pumpUntil(tester, find.text('Jardín orbital'));
        final ProviderAnimeMetadata selected = await module.service
            .search('Jardín')
            .then(
              (result) =>
                  result.fold((items) => items.single, (error) => throw error),
            );

        await tester.tap(
          find.byKey(const ValueKey('catalog-item-orbital-garden')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byKey(const ValueKey('detail-back')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('detail-tab-information')),
          findsOneWidget,
        );
        expect(find.byTooltip('Buscar'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('detail-tab-information')));
        await tester.pump();
        await _pumpUntil(
          tester,
          find.text('La tripulación de una estación cultiva el último jardín.'),
        );

        await tester.tap(find.byKey(const ValueKey('add-to-library')));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('detail-library-status')),
        );
        final LibraryEntry added = (await tester.runAsync(
          () => module.service.getLibraryEntry(selected.externalId),
        ))!.fold((entry) => entry!, (error) => throw error);

        await tester.tap(find.byKey(const ValueKey('detail-library-status')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Viendo').last);
        await _pumpUntil(tester, find.text('Viendo'));
        await tester.pumpAndSettle();
        final LibraryEntry watching = (await tester.runAsync(
          () => module.service.getLibraryEntryByAnimeId(added.animeId),
        ))!.fold((entry) => entry!, (error) => throw error);
        expect(watching.status, LibraryStatus.watching);

        final statusDropdown = find.byKey(
          const ValueKey('detail-library-status'),
        );
        await tester.ensureVisible(statusDropdown);
        await tester.pumpAndSettle();
        await tester.tap(statusDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Completados').last);
        await tester.pumpAndSettle();
        expect(find.text('Marcar como completado'), findsOneWidget);
        expect(
          find.textContaining('no puede verificar que todos los episodios'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        final LibraryEntry afterCancel = (await tester.runAsync(
          () => module.service.getLibraryEntryByAnimeId(added.animeId),
        ))!.fold((entry) => entry!, (error) => throw error);
        expect(afterCancel.status, LibraryStatus.watching);

        await tester.tap(find.byKey(const ValueKey('detail-tab-episodes')));
        await tester.pump();
        expect(
          find.text('12 de 12 indexados · fuentes sin verificar'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('episode-card-1')), findsOneWidget);

        await tester.tap(statusDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Completados').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Marcar completado'));
        await tester.pumpAndSettle();
        final LibraryEntry completed = (await tester.runAsync(
          () => module.service.getLibraryEntryByAnimeId(added.animeId),
        ))!.fold((entry) => entry!, (error) => throw error);
        expect(completed.status, LibraryStatus.completed);

        await tester.tap(statusDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Viendo').last);
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('progress-seconds')),
          500,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.enterText(
          find.byKey(const ValueKey('progress-seconds')),
          '2700',
        );
        await tester.tap(find.byKey(const ValueKey('save-progress')));
        await _pumpUntil(tester, find.text('Recuperado: 2700 segundos'));
        final PlaybackProgress? saved = (await tester.runAsync(
          () => module.service.getProgress(added.animeId),
        ))!.fold((value) => value, (error) => throw error);
        expect(saved?.positionMs, 2700000);

        final List<bool> duplicateResults = (await tester.runAsync(() async {
          final List<Result<LibraryEntry>> results = await Future.wait([
            module.service.addToLibrary(selected),
            module.service.addToLibrary(selected),
          ]);
          return results
              .map((Result<LibraryEntry> result) => result.isSuccess)
              .toList(growable: false);
        }))!;
        expect(duplicateResults, everyElement(isTrue));
        final List<CatalogLibraryItem> library = (await tester.runAsync(
          () => module.service.loadLibrary(),
        ))!.fold((items) => items, (error) => throw error);
        expect(library, hasLength(1));
        expect(library.single.entry.status, LibraryStatus.watching);
        expect(module.demoProvider!.searchRequestCount, greaterThan(0));
        expect(module.demoProvider!.detailsRequestCount, greaterThan(0));

        await tester.tap(find.byKey(const ValueKey('detail-back')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Biblioteca'));
        await _pumpUntil(
          tester,
          find.byKey(ValueKey('library-item-${added.animeId.value}')),
        );
        await tester.tap(find.byTooltip('Inicio'));
        await _pumpUntil(tester, find.text('Currently watching'));
        await tester.runAsync(
          () =>
              module.service.setStatus(added.animeId, LibraryStatus.completed),
        );
        await tester.runAsync(
          () => module.service.setStatus(added.animeId, LibraryStatus.watching),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(module.close);

        // Reopen the same isolated SQLite file with a new composition/service.
        module = (await tester.runAsync(
          () => CatalogModule.open(
            databaseFile: databaseFile,
            useDemoProvider: true,
            episodeIndex: const _FixtureEpisodeIndex(),
            clock: () => DateTime.utc(2026, 11, 9, 13),
          ),
        ))!;
        await tester.pumpWidget(AnimeApp(catalogService: module.service));
        await tester.tap(find.byTooltip('Biblioteca'));
        await _pumpUntil(tester, find.text('Jardín orbital'));
        expect(find.text('Viendo'), findsWidgets);

        await tester.tap(
          find.byKey(
            ValueKey('library-item-${library.single.entry.animeId.value}'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('saved-progress-summary')),
          500,
          scrollable: find.byType(Scrollable).last,
        );
        await _pumpUntil(tester, find.text('Recuperado: 2700 segundos'));
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(module.close);
        HttpOverrides.global = previousOverrides;
        await tester.runAsync(() => directory.delete(recursive: true));
      }
    },
  );
}

final class _DenyNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Unexpected HTTP client in offline catalog test.');
}

/// Deterministic public-index stand-in: no network in widget tests.
final class _FixtureEpisodeIndex implements EpisodeIndexProvider {
  const _FixtureEpisodeIndex();

  @override
  MetadataProviderId get id => MetadataProviderId('fixture');

  @override
  Future<ProviderResult<EpisodeIndexPage>> listEpisodes(
    ExternalAnimeId anime, {
    int offset = 0,
    int limit = 20,
  }) async {
    final DateTime retrieved = DateTime.utc(2026, 11, 9);
    return ProviderSuccess(
      EpisodeIndexPage(
        episodes: [
          for (
            var number = 1 + offset;
            number <= 12 && number <= offset + limit;
            number++
          )
            ProviderEpisodeMetadata(
              animeId: anime,
              externalEpisodeId: 'fixture:$number',
              episodeNumber: number,
              title: 'Fixture $number',
              provenance: MetadataProvenance(
                externalId: anime,
                retrievedAtUtc: retrieved,
              ),
            ),
        ],
        totalCount: 12,
        hasMore: offset + limit < 12,
      ),
    );
  }
}
