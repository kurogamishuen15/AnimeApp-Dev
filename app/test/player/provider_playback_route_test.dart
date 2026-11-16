import 'dart:async';

import 'package:anime_app/app/player/playback_route_session.dart';
import 'package:anime_app/app/player/provider_playback_route.dart';
import 'package:anime_app/app/player/spike_player_module.dart';
import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('active player contention lets the user return to the catalog', (
    tester,
  ) async {
    final ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input =
        _playbackInput();

    await tester.pumpWidget(
      _catalogApp(
        onBuild: (BuildContext _) {},
        moduleLoader: (_) => throw PlaybackRoutePlayerBusy(),
        input: input,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-playback')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Un reproductor o una apertura anterior aún conserva el recurso nativo. Espera a que termine o reinicia la aplicación antes de reproducir de nuevo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Volver al catálogo'), findsOneWidget);

    await tester.tap(find.text('Volver al catálogo'));
    await tester.pumpAndSettle();
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('No se pudo abrir el reproductor.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleanup failure keeps the route and requires restart', (
    tester,
  ) async {
    late BuildContext catalogContext;
    final ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input =
        _playbackInput();

    await tester.pumpWidget(
      _catalogApp(
        onBuild: (BuildContext context) => catalogContext = context,
        moduleLoader: (_) async => throw SpikePlayerStartupCleanupFailure(
          startupError: StateError('startup failure'),
          cleanupError: StateError('dispose failure'),
          nativePlayerStillOwned: true,
          nonNativeCleanupFailed: false,
        ),
        input: input,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-playback')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No se pudo confirmar la liberación del reproductor nativo. Reinicia la aplicación antes de volver a intentarlo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Volver al catálogo'), findsNothing);

    await Navigator.of(catalogContext).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Catálogo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending startup can be cancelled and a late session closes safely',
    (tester) async {
      final ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input =
          _playbackInput();
      final Completer<PlaybackRouteSession> opening =
          Completer<PlaybackRouteSession>();
      final _ControlledSession lateSession = _ControlledSession(
        Future<void>.value(),
      );
      PlaybackRouteOpenCancellation? cancellation;

      await tester.pumpWidget(
        _catalogApp(
          onBuild: (BuildContext _) {},
          moduleLoader: (PlaybackRouteOpenCancellation token) {
            cancellation = token;
            return opening.future;
          },
          input: input,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-playback')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Abriendo reproducción…'), findsOneWidget);
      expect(
        find.text('Cancelar apertura y volver al catálogo'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar apertura y volver al catálogo'));
      await tester.pumpAndSettle();
      expect(cancellation?.isRequested, isTrue);
      expect(find.text('Catálogo'), findsOneWidget);

      opening.complete(lateSession);
      await tester.pumpAndSettle();
      expect(lateSession.closeCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'released native player allows return after accessory cleanup failure',
    (tester) async {
      final ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input =
          _playbackInput();
      late BuildContext catalogContext;

      await tester.pumpWidget(
        _catalogApp(
          onBuild: (BuildContext context) => catalogContext = context,
          moduleLoader: (_) async => throw SpikePlayerStartupCleanupFailure(
            startupError: StateError('startup failure'),
            cleanupError: StateError('catalog disposal failure'),
            nativePlayerStillOwned: false,
            nonNativeCleanupFailed: true,
          ),
          input: input,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-playback')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El reproductor nativo se liberó, pero falló la limpieza de recursos secundarios.',
        ),
        findsOneWidget,
      );
      expect(find.text('Volver al catálogo'), findsOneWidget);
      await Navigator.of(catalogContext).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Catálogo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving an open session waits for its close future', (
    tester,
  ) async {
    late BuildContext catalogContext;
    final ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input =
        _playbackInput();
    final Completer<void> closeGate = Completer<void>();
    final _ControlledSession session = _ControlledSession(closeGate.future);

    await tester.pumpWidget(
      _catalogApp(
        onBuild: (BuildContext context) => catalogContext = context,
        moduleLoader: (_) async => session,
        input: input,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-playback')));
    await tester.pumpAndSettle();
    expect(find.text('Player session'), findsOneWidget);

    await Navigator.of(catalogContext).maybePop();
    await tester.pump();
    expect(find.text('Player session'), findsOneWidget);
    expect(find.text('Catálogo'), findsNothing);
    expect(session.closeCalls, 1);

    closeGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Player session'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed close keeps the route until a retry succeeds', (
    tester,
  ) async {
    final ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input =
        _playbackInput();
    final _FailThenSucceedSession session = _FailThenSucceedSession();

    await tester.pumpWidget(
      _catalogApp(
        onBuild: (BuildContext _) {},
        moduleLoader: (_) async => session,
        input: input,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-playback')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver a la ficha'));
    await tester.pumpAndSettle();

    expect(session.closeCalls, 1);
    expect(find.text('Player session'), findsOneWidget);
    expect(
      find.text('No se pudo cerrar el reproductor con seguridad.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Volver a la ficha'));
    await tester.pumpAndSettle();
    expect(session.closeCalls, 2);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Player session'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'released native player lets the user leave after close cleanup failure',
    (tester) async {
      final ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input =
          _playbackInput();
      final _ReleasedPlayerCloseFailureSession session =
          _ReleasedPlayerCloseFailureSession();

      await tester.pumpWidget(
        _catalogApp(
          onBuild: (BuildContext _) {},
          moduleLoader: (_) async => session,
          input: input,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-playback')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver a la ficha'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El reproductor nativo se liberó, pero falló la limpieza de recursos secundarios. Puedes volver al catálogo.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Volver al catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo'), findsOneWidget);
      expect(session.closeCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _catalogApp({
  required void Function(BuildContext) onBuild,
  required PlaybackRouteSessionLoader moduleLoader,
  required ({PlaybackEpisode episode, ResolvedPlaybackStream stream}) input,
}) {
  final PlaybackProviderManager manager = PlaybackProviderManager(
    providers: const [],
    clock: DateTime.now,
  );
  return MaterialApp(
    home: Builder(
      builder: (BuildContext context) {
        onBuild(context);
        return Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open-playback'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ProviderPlaybackRoute(
                    manager: manager,
                    episode: input.episode,
                    streams: [input.stream],
                    initialStream: input.stream,
                    moduleLoader: moduleLoader,
                  ),
                ),
              ),
              child: const Text('Catálogo'),
            ),
          ),
        );
      },
    ),
  );
}

({PlaybackEpisode episode, ResolvedPlaybackStream stream}) _playbackInput() {
  final PlaybackEpisode episode = PlaybackEpisode(
    animeId: AnimeId('anime-test'),
    episodeNumber: 1,
    animeTitles: const ['Anime de prueba'],
  );
  final ResolvedPlaybackStream stream = ResolvedPlaybackStream(
    providerId: PlaybackProviderId('test'),
    sourceId: 'source',
    serverId: 'server',
    uri: Uri.https('example.com', '/episode.m3u8'),
  );
  return (episode: episode, stream: stream);
}

final class _ControlledSession implements PlaybackRouteSession {
  _ControlledSession(this._closeFuture);

  final Future<void> _closeFuture;
  int closeCalls = 0;

  @override
  Widget build() => const Scaffold(body: Center(child: Text('Player session')));

  @override
  Future<void> close() {
    closeCalls++;
    return _closeFuture;
  }
}

final class _FailThenSucceedSession implements PlaybackRouteSession {
  int closeCalls = 0;

  @override
  Widget build() => const Scaffold(body: Center(child: Text('Player session')));

  @override
  Future<void> close() async {
    closeCalls++;
    if (closeCalls == 1) throw StateError('injected close failure');
  }
}

final class _ReleasedPlayerCloseFailureSession implements PlaybackRouteSession {
  int closeCalls = 0;

  @override
  Widget build() => const Scaffold(body: Center(child: Text('Player session')));

  @override
  Future<void> close() async {
    closeCalls++;
    throw PlaybackRouteCleanupFailure(
      cause: StateError('accessory cleanup failure'),
      nativePlayerStillOwned: false,
      nonNativeCleanupFailed: true,
    );
  }
}
