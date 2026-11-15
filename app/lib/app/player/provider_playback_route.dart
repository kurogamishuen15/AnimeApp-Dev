import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/player/providers/playback_provider_manager.dart';
import '../../domain/player/providers/playback_source.dart';
import 'playback_route_session.dart';
import 'spike_player_module.dart';

typedef PlaybackRouteSessionLoader = Future<PlaybackRouteSession> Function();

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
            widget.moduleLoader?.call() ??
            SpikePlayerModule.open(
              null,
              sourceProviderManager: widget.manager,
              sourceEpisode: widget.episode,
              initialResolvedSource: widget.initialStream,
              trustedExternalSources: {
                for (final ResolvedPlaybackStream stream in widget.streams)
                  stream.uri,
              },
            ),
      );
  PlaybackRouteSession? _module;
  bool _closing = false;
  bool _disposed = false;
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
    } on Object {
      // Route teardown is best effort after removal; close failures are
      // already represented by the module's lifecycle contract.
    }
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
    } on Object {
      if (mounted) {
        setState(() {
          _closing = false;
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
        final bool cleanupFailed =
            state.error is SpikePlayerStartupCleanupFailure;
        return PopScope<Object?>(
          canPop: state.hasError && !cleanupFailed,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop && !state.hasError) unawaited(_closeAndPop());
          },
          child: Scaffold(
            body: Center(
              child: state.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cleanupFailed
                              ? 'No se pudo cerrar el reproductor con seguridad. Reinicia la aplicación antes de volver a intentarlo.'
                              : 'No se pudo abrir el reproductor.',
                          textAlign: TextAlign.center,
                        ),
                        if (!cleanupFailed) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver al catálogo'),
                          ),
                        ],
                      ],
                    )
                  : const Text('Abriendo reproducción…'),
            ),
          ),
        );
      }
      _module = module;
      return PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) unawaited(_closeAndPop());
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
                  tooltip: _closing ? 'Cerrando' : 'Volver a la ficha',
                  onPressed: _closing ? null : _closeAndPop,
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
