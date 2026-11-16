import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/player/providers/playback_provider_manager.dart';
import '../../domain/player/providers/playback_source.dart';
import 'playback_route_session.dart';
import 'spike_player_module.dart';

typedef PlaybackRouteSessionLoader = Future<PlaybackRouteSession> Function(
  PlaybackRouteOpenCancellation cancellation,
);

/// Plays a previously resolved public stream through the existing F2 player.
/// The exact resolved URI list is passed as an allowlist to the existing
/// engine/coordinator; this route does not construct a second Player system.
final class ProviderPlaybackRoute extends StatefulWidget {
  const ProviderPlaybackRoute({
    required this.manager,
    required this.episode,
    required this.streams,
    required this.initialStream,
    @visibleForTesting this.moduleLoader,
    super.key,
  });

  final PlaybackProviderManager manager;
  final PlaybackEpisode episode;
  final List<ResolvedPlaybackStream> streams;
  final ResolvedPlaybackStream initialStream;
  final PlaybackRouteSessionLoader? moduleLoader;

  @override
  State<ProviderPlaybackRoute> createState() => _ProviderPlaybackRouteState();
}

final class _ProviderPlaybackRouteState extends State<ProviderPlaybackRoute> {
  late final Future<PlaybackRouteSession> _moduleFuture =
      Future<PlaybackRouteSession>.sync(
        () =>
            widget.moduleLoader?.call(_openCancellation) ??
            SpikePlayerModule.openForRoute(
              () => SpikePlayerModule.open(
                null,
                sourceProviderManager: widget.manager,
                sourceEpisode: widget.episode,
                initialResolvedSource: widget.initialStream,
                trustedExternalSources: {
                  for (final ResolvedPlaybackStream stream in widget.streams)
                    stream.uri,
                },
                startupCancellation: _openCancellation,
              ),
            ),
      );
  final PlaybackRouteOpenCancellation _openCancellation =
      PlaybackRouteOpenCancellation();
  PlaybackRouteSession? _module;
  bool _closing = false;
  bool _disposed = false;
  bool _startupCancellationRequested = false;
  bool _safeToLeaveAfterCloseFailure = false;
  String? _closeError;

  @override
  void dispose() {
    _disposed = true;
    if (!_closing) unawaited(_closeOnRemoval());
    super.dispose();
  }

  Future<void> _closeOnRemoval() async {
    try {
      final PlaybackRouteSession module = _module ?? await _moduleFuture;
      await module.close();
    } on SpikePlayerStartupCleanupFailure catch (failure) {
      debugPrint(
        'KONGROO_BACKGROUND_STARTUP_CLEANUP '
        'native_player_still_owned=${failure.nativePlayerStillOwned} '
        'non_native_cleanup_failed=${failure.nonNativeCleanupFailed}',
      );
    } on Object {
      // Route teardown is best effort after removal; close failures are
      // already represented by the module's lifecycle contract.
    }
  }

  void _cancelPendingOpenAndReturn() {
    if (_startupCancellationRequested || !mounted) return;
    _openCancellation.request();
    setState(() => _startupCancellationRequested = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_disposed) Navigator.of(context).pop();
    });
  }

  Future<void> _closeAndPop() async {
    if (_closing) return;
    setState(() {
      _closing = true;
      _closeError = null;
    });
    try {
      final PlaybackRouteSession module = _module ?? await _moduleFuture;
      _module = module;
      await module.close();
      if (mounted && !_disposed) Navigator.of(context).pop();
    } on PlaybackRouteCleanupFailure catch (failure) {
      if (mounted) {
        setState(() {
          _closing = false;
          _safeToLeaveAfterCloseFailure = !failure.nativePlayerStillOwned;
          _closeError = failure.nativePlayerStillOwned
              ? 'No se pudo confirmar la liberación del reproductor nativo. Reinicia la aplicación antes de volver a intentarlo.'
              : 'El reproductor nativo se liberó, pero falló la limpieza de recursos secundarios. Puedes volver al catálogo.';
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _closing = false;
          _safeToLeaveAfterCloseFailure = false;
          _closeError = 'No se pudo cerrar el reproductor con seguridad.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PlaybackRouteSession>(
    future: _moduleFuture,
    builder: (BuildContext context, AsyncSnapshot<PlaybackRouteSession> state) {
      final PlaybackRouteSession? module = state.data;
      if (module == null) {
        final SpikePlayerStartupCleanupFailure? cleanupFailure =
            state.error is SpikePlayerStartupCleanupFailure
            ? state.error! as SpikePlayerStartupCleanupFailure
            : null;
        final bool nativePlayerStillOwned =
            cleanupFailure?.nativePlayerStillOwned ?? false;
        return PopScope<Object?>(
          canPop:
              _startupCancellationRequested ||
              (state.hasError && !nativePlayerStillOwned),
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop && !state.hasError) _cancelPendingOpenAndReturn();
          },
          child: Scaffold(
            body: Center(
              child: state.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cleanupFailure != null
                              ? nativePlayerStillOwned
                                    ? 'No se pudo confirmar la liberación del reproductor nativo. Reinicia la aplicación antes de volver a intentarlo.'
                                    : cleanupFailure.nonNativeCleanupFailed
                                    ? 'El reproductor nativo se liberó, pero falló la limpieza de recursos secundarios.'
                                    : 'No se pudo abrir el reproductor; el recurso nativo está liberado.'
                              : state.error is PlaybackRoutePlayerBusy
                              ? 'Un reproductor o una apertura anterior aún conserva el recurso nativo. Espera a que termine o reinicia la aplicación antes de reproducir de nuevo.'
                              : 'No se pudo abrir el reproductor.',
                          textAlign: TextAlign.center,
                        ),
                        if (!nativePlayerStillOwned) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver al catálogo'),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _startupCancellationRequested
                              ? 'Cancelación solicitada. No se liberarán recursos nativos hasta que la apertura confirme que terminó; si no responde, reinicia la aplicación antes de intentar otra reproducción.'
                              : 'Abriendo reproducción… La cancelación no interrumpe una llamada nativa que ya comenzó; si vuelves al catálogo, la sesión seguirá supervisada y conservará el lease hasta que responda. Reinicia la aplicación antes de reproducir de nuevo si no se recupera.',
                          textAlign: TextAlign.center,
                        ),
                        if (!_startupCancellationRequested) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _cancelPendingOpenAndReturn,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text(
                              'Cancelar apertura y volver al catálogo',
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );
      }
      _module = module;
      return PopScope<Object?>(
        canPop: _safeToLeaveAfterCloseFailure,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop && !_safeToLeaveAfterCloseFailure) {
            unawaited(_closeAndPop());
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            module.build(),
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: IconButton.filledTonal(
                  tooltip: _closing
                      ? 'Cerrando'
                      : _safeToLeaveAfterCloseFailure
                      ? 'Volver al catálogo'
                      : 'Volver a la ficha',
                  onPressed: _closing
                      ? null
                      : _safeToLeaveAfterCloseFailure
                      ? () => Navigator.of(context).pop()
                      : _closeAndPop,
                  icon: _closing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_back),
                ),
              ),
            ),
            if (_closeError case final String message)
              Positioned(
                left: 16,
                right: 16,
                top: 68,
                child: Material(
                  color: Colors.red.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(message),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
