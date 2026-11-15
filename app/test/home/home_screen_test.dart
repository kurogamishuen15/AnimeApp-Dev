import 'dart:async';

import 'package:anime_app/app/home/home_appearance.dart';
import 'package:anime_app/app/home/home_artwork.dart';
import 'package:anime_app/app/home/home_card_actions.dart';
import 'package:anime_app/app/home/home_data.dart';
import 'package:anime_app/app/home/home_hero.dart';
import 'package:anime_app/app/home/home_score_badge.dart';
import 'package:anime_app/app/home/home_screen.dart';
import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(
  HomeLoader load, {
  ValueChanged<HomeTitle>? onDetails,
  TextScaler scaler = TextScaler.noScaling,
  Future<void> Function(HomeTitle, HomeCardLibraryCommand)? onLibraryAction,
  NavigationMode navigationMode = NavigationMode.traditional,
  TargetPlatform platform = TargetPlatform.linux,
  HomeAppearance appearance = const HomeAppearance(),
  bool disableAnimations = false,
  Size screenSize = const Size(1280, 800),
}) => MaterialApp(
  theme: ThemeData.dark().copyWith(
    platform: platform,
    extensions: [appearance],
  ),
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(
        textScaler: scaler,
        navigationMode: navigationMode,
        disableAnimations: disableAnimations,
        size: screenSize,
      ),
      child: HomeScreen(
        load: load,
        onDetails: onDetails ?? (_) {},
        onLibraryAction: onLibraryAction ?? (_, _) async {},
      ),
    ),
  ),
);

void main() {
  testWidgets('loading, network failure, retry and empty', (tester) async {
    final pending = Completer<Result<HomeContent>>();
    var calls = 0;
    await tester.pumpWidget(
      _host(() {
        calls++;
        return calls == 1
            ? pending.future
            : Future.value(const Success(HomeContent()));
      }),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Failure(NetworkError()));
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión'), findsOneWidget);
    await tester.tap(find.text('Volver a cargar'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio está vacío'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('offline content stays visible while a single retry runs', (
    tester,
  ) async {
    final retry = Completer<Result<HomeContent>>();
    var calls = 0;
    await tester.pumpWidget(
      _host(() {
        calls++;
        return calls == 1
            ? Future.value(
                const Success(
                  HomeContent(
                    featured: HomeTitle(title: 'Disponible sin red'),
                    offline: true,
                  ),
                ),
              )
            : retry.future;
      }),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(find.text('Disponible sin red'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Actualizando…'),
    );
    expect(button.onPressed, isNull);
    expect(calls, 2);
    retry.complete(const Success(HomeContent()));
    await tester.pumpAndSettle();
  });

  testWidgets('timeout becomes a recoverable error', (tester) async {
    await tester.pumpWidget(
      _host(() => Completer<Result<HomeContent>>().future),
    );
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar Inicio'), findsOneWidget);
  });

  testWidgets('desktop at 720 shows resume; keyboard opens hero details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const title = HomeTitle(title: 'Faroles', airing: true);
    HomeTitle? selected;
    await tester.pumpWidget(
      _host(
        () async => const Success(
          HomeContent(
            featured: title,
            episodes: [HomeEpisode(title, 'Episodio 2', 2700000, 3000000)],
            watching: [title],
            offline: true,
          ),
        ),
        onDetails: (title) => selected = title,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión · Contenido local'), findsOneWidget);
    expect(find.text('Continue watching').hitTestable(), findsOneWidget);
    // First focusable control is the offline retry action.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, same(title));
    await tester.tap(find.text('Episodio 2\n5:00 restantes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Episodio 2 · 45:00'), findsOneWidget);
  });

  testWidgets('narrow with scaled text, fallback art and a long lazy shelf', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 660));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const title = HomeTitle(title: 'Una aventura de invierno muy larga');
    await tester.pumpWidget(
      _host(
        () async => Success(
          HomeContent(
            featured: title,
            episodes: List.generate(
              120,
              (index) =>
                  HomeEpisode(title, 'Episodio ${index + 1}', 11000, null),
            ),
          ),
        ),
        scaler: const TextScaler.linear(1.7),
        screenSize: const Size(360, 660),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue watching'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Episodio 120'), findsNothing);
    await tester.ensureVisible(find.byTooltip('Siguientes'));
    await tester.tap(find.byTooltip('Siguientes'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'poster captions fit below the art and shelf scrolls without a bar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const firstTitle =
          'Anime 0 con un título largo para comprobar el texto inferior';
      await tester.pumpWidget(
        _host(
          () async => Success(
            HomeContent(
              shelves: [
                (
                  label: 'Estante de prueba',
                  titles: List.generate(
                    20,
                    (index) => const HomeTitle(title: firstTitle),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue watching'), findsNothing);
      expect(find.text('Currently watching'), findsNothing);
      await tester.ensureVisible(find.text('Estante de prueba'));
      await tester.pumpAndSettle();

      final shelfRect = tester.getRect(
        find.byKey(const PageStorageKey<String>('Estante de prueba')),
      );
      final captionRect = tester.getRect(find.text(firstTitle).first);
      expect(captionRect.bottom, lessThanOrEqualTo(shelfRect.bottom - 12));
      expect(find.byType(Scrollbar), findsNothing);
      expect(find.byTooltip('Siguientes'), findsOneWidget);
      await tester.tap(find.byTooltip('Siguientes'));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const PageStorageKey<String>('Estante de prueba')),
          matching: find.byType(Scrollable),
        ),
      );
      final pointer = TestPointer(31, PointerDeviceKind.mouse);
      final pointerLocation = tester.getCenter(find.text(firstTitle).first);
      await tester.sendEventToBinding(
        pointer.addPointer(location: pointerLocation),
      );
      await tester.sendEventToBinding(pointer.hover(pointerLocation));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 160)));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));
      final offsetAfterWheel = scrollable.position.pixels;
      await tester.sendEventToBinding(pointer.scroll(const Offset(160, 0)));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(offsetAfterWheel));
      await tester.sendEventToBinding(pointer.removePointer());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('desktop hover keeps actions inside the cover and opens menu', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final title = HomeTitle(
      title: 'Portada de prueba',
      animeId: AnimeId('anime:100'),
      libraryStatus: LibraryStatus.watching,
      score: 86,
      externalId: ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '100',
      ),
    );
    HomeTitle? details;
    HomeCardLibraryCommand? selected;
    await tester.pumpWidget(
      _host(
        () async => Success(
          HomeContent(
            shelves: [
              (label: 'Pruebas', titles: [title]),
            ],
          ),
        ),
        onDetails: (value) => details = value,
        onLibraryAction: (value, command) async {
          selected = command;
        },
      ),
    );
    await tester.pumpAndSettle();
    final artwork = find.byType(HomeArtwork).first;
    await tester.ensureVisible(artwork);
    await tester.pumpAndSettle();
    final coverRect = tester.getRect(artwork);
    final overlay = find.byKey(
      const ValueKey('home-card-overlay-Portada de prueba'),
    );
    expect(tester.widget<AnimatedOpacity>(overlay).opacity, 0);
    final contextClick = await tester.startGesture(
      coverRect.center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await contextClick.up();
    await tester.pumpAndSettle();
    expect(find.text('Move in Kongroo'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.byType(PopupMenuItem), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xf20d0d0f),
      ),
      findsOneWidget,
    );
    expect(find.text('86%'), findsOneWidget);
    final scoreStar = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(HomeScoreBadge).first,
        matching: find.byType(CustomPaint),
      ),
    );
    expect(scoreStar.size, const Size.square(14));
    expect(HomeScoreBadge.starColor, const Color(0xffffcf62));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await contextClick.removePointer();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: coverRect.center);
    await mouse.moveTo(coverRect.center);
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.widget<AnimatedOpacity>(overlay).opacity, 1);
    expect(find.byTooltip('Details'), findsOneWidget);
    expect(find.byTooltip('Card actions'), findsOneWidget);
    final visibleOverlay = tester.widget<AnimatedOpacity>(overlay);
    final actionRow = (visibleOverlay.child as IgnorePointer).child;
    expect(actionRow, isA<Row>());
    final normalCoverRect = tester.getRect(artwork);
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale,
      1.035,
    );
    expect(tester.getRect(artwork), normalCoverRect);
    expect(
      tester.getRect(find.byTooltip('Card actions')).bottom,
      lessThanOrEqualTo(coverRect.bottom),
    );
    await mouse.moveTo(tester.getCenter(find.byTooltip('Card actions')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<AnimatedOpacity>(overlay).opacity, 1);
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<AnimatedOpacity>(overlay).opacity, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<AnimatedOpacity>(overlay).opacity, 1);
    await mouse.moveTo(coverRect.center);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byTooltip('Details'));
    expect(details, same(title));
    details = null;
    await tester.tap(find.byTooltip('Card actions'));
    await tester.pumpAndSettle();
    expect(find.text('Move in Kongroo'), findsOneWidget);
    expect(find.text('Remove from list'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('Paused'));
    await tester.pumpAndSettle();
    expect(selected?.status, LibraryStatus.paused);
    await tester.tap(find.byTooltip('Card actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(selected?.copyLink, isTrue);
    await tester.tap(find.byTooltip('Card actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from list'));
    await tester.pumpAndSettle();
    expect(selected?.remove, isTrue);
    await mouse.removePointer();
  });

  testWidgets('hero exposes provider metadata and selectable highlight dots', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const first = HomeTitle(
      title: 'Season One',
      formatLabel: 'TV',
      seasonLabel: 'Fall 2026',
      score: 88,
      genres: ['Action', 'Adventure', 'Drama'],
    );
    const second = HomeTitle(
      title: 'Season Two',
      formatLabel: 'Movie',
      seasonLabel: 'Spring 2027',
      score: 91,
      genres: ['Fantasy'],
    );
    HomeTitle? selectedDetails;
    await tester.pumpWidget(
      _host(
        () async => const Success(
          HomeContent(featured: first, highlights: [first, second]),
        ),
        onDetails: (value) => selectedDetails = value,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('Fall 2026'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('Season One'), findsOneWidget);
    expect(find.text('Action · Adventure · Drama'), findsOneWidget);
    expect(find.text('Watch now'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
      isNull,
    );
    await tester.tap(find.bySemanticsLabel('Mostrar Season Two'));
    await tester.pumpAndSettle();
    expect(find.text('Season Two'), findsOneWidget);
    expect(find.text('Spring 2027'), findsOneWidget);
    await tester.tap(find.text('Details'));
    expect(selectedDetails, same(second));
  });

  testWidgets(
    'banner auto-advances on hover and resets after manual selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const first = HomeTitle(title: 'Autoslide one', score: 82);
      const second = HomeTitle(title: 'Autoslide two', score: 88);
      const third = HomeTitle(title: 'Autoslide three', score: 91);
      await tester.pumpWidget(
        _host(
          () async => const Success(
            HomeContent(featured: first, highlights: [first, second, third]),
          ),
          appearance: const HomeAppearance(
            bannerAutoSlideInterval: Duration(seconds: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Autoslide one'), findsOneWidget);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.text('Autoslide one')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Autoslide two'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Mostrar Autoslide one'));
      await tester.pumpAndSettle();
      expect(find.text('Autoslide one'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.text('Autoslide one'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Autoslide two'), findsOneWidget);

      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('banner defaults to six seconds and respects reduced motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const first = HomeTitle(title: 'Reduced motion one');
    const second = HomeTitle(title: 'Reduced motion two');
    expect(
      const HomeAppearance().bannerAutoSlideInterval,
      const Duration(seconds: 6),
    );
    await tester.pumpWidget(
      _host(
        () async => const Success(
          HomeContent(featured: first, highlights: [first, second]),
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Reduced motion one'), findsOneWidget);
    expect(find.text('Reduced motion two'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('banner pauses while scrolled out of the Home viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const first = HomeTitle(title: 'Visible hero one');
    const second = HomeTitle(title: 'Visible hero two');
    await tester.pumpWidget(
      _host(
        () async => Success(
          HomeContent(
            featured: first,
            highlights: const [first, second],
            shelves: List.generate(
              4,
              (index) => (
                label: 'Viewport shelf $index',
                titles: List.generate(12, (_) => first),
              ),
            ),
          ),
        ),
        appearance: const HomeAppearance(
          bannerAutoSlideInterval: Duration(seconds: 2),
        ),
        screenSize: const Size(1100, 620),
      ),
    );
    await tester.pumpAndSettle();
    final homeScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('home-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    homeScroll.position.jumpTo(homeScroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byType(HomeHero), findsNothing);
    await tester.pump(const Duration(seconds: 3));

    homeScroll.position.jumpTo(homeScroll.position.minScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.widget<HomeHero>(find.byType(HomeHero)).visible, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(HomeHero),
        matching: find.text('Visible hero two'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android always shows only the touch options control', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final title = HomeTitle(
      title: 'Tarjeta móvil',
      externalId: ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '200',
      ),
    );
    HomeTitle? details;
    HomeCardLibraryCommand? selected;
    await tester.pumpWidget(
      _host(
        () async => Success(
          HomeContent(
            shelves: [
              (label: 'Pruebas', titles: [title]),
            ],
          ),
        ),
        onDetails: (value) => details = value,
        onLibraryAction: (value, command) async {
          selected = command;
        },
        platform: TargetPlatform.android,
      ),
    );
    await tester.pumpAndSettle();
    final artwork = find.byType(HomeArtwork).first;
    await tester.ensureVisible(artwork);
    await tester.pumpAndSettle();
    expect(find.byTooltip('More actions'), findsOneWidget);
    expect(find.byTooltip('Details'), findsNothing);
    final touchButton = find.ancestor(
      of: find.byTooltip('More actions'),
      matching: find.byType(IconButton),
    );
    final touchActionRect = tester.getRect(touchButton.first);
    expect(
      touchActionRect.bottom,
      lessThanOrEqualTo(tester.getRect(artwork).bottom),
    );
    expect(touchActionRect.top, greaterThan(tester.getRect(artwork).top));
    expect(touchActionRect.width, greaterThanOrEqualTo(48));
    expect(touchActionRect.height, greaterThanOrEqualTo(48));
    await tester.tap(artwork);
    expect(details, same(title));
    details = null;
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(details, isNull);
    expect(find.text('Plan to watch'), findsOneWidget);
    await tester.tap(find.text('Plan to watch'));
    await tester.pumpAndSettle();
    expect(selected?.add, isTrue);
  });

  testWidgets('TV focused card exposes remote menu and Escape restores focus', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final firstTitle = HomeTitle(
      title: 'Primera tarjeta TV',
      externalId: ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '300',
      ),
    );
    final secondTitle = HomeTitle(
      title: 'Segunda tarjeta TV',
      externalId: ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '301',
      ),
    );
    await tester.pumpWidget(
      _host(
        () async => Success(
          HomeContent(
            shelves: [
              (label: 'Pruebas', titles: [firstTitle, secondTitle]),
            ],
          ),
        ),
        navigationMode: NavigationMode.directional,
        platform: TargetPlatform.android,
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 150));
    final firstOverlay = find.byKey(
      const ValueKey('home-card-overlay-Primera tarjeta TV'),
    );
    final secondOverlay = find.byKey(
      const ValueKey('home-card-overlay-Segunda tarjeta TV'),
    );
    expect(tester.widget<AnimatedOpacity>(firstOverlay).opacity, 1);
    expect(tester.widget<AnimatedOpacity>(secondOverlay).opacity, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<AnimatedOpacity>(firstOverlay).opacity, 0);
    expect(tester.widget<AnimatedOpacity>(secondOverlay).opacity, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Plan to watch'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byTooltip('More actions'), findsNWidgets(2));
    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip('More actions').last,
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .focusNode
          ?.hasPrimaryFocus,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
