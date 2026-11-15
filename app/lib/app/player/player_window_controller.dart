import 'dart:async';

import 'package:flutter/services.dart';

/// Platform boundary for the real application window, separate from media
/// playback. A successful request is not a claim that the window transitioned.
abstract interface class PlayerWindowController {
  Stream<PlayerWindowSnapshot> get states;
  PlayerWindowSnapshot get state;

  Future<void> initialize();
  Future<void> requestFullscreen(bool fullscreen);
  Future<void> dispose();
}

final class PlayerWindowSnapshot {
  const PlayerWindowSnapshot({
    this.fullscreen = false,
    this.observed = false,
    this.requestPending = false,
    this.error,
  });

  final bool fullscreen;
  final bool observed;
  final bool requestPending;
  final String? error;

  PlayerWindowSnapshot copyWith({
    bool? fullscreen,
    bool? observed,
    bool? requestPending,
    String? error,
    bool clearError = false,
  }) => PlayerWindowSnapshot(
    fullscreen: fullscreen ?? this.fullscreen,
    observed: observed ?? this.observed,
    requestPending: requestPending ?? this.requestPending,
    error: clearError ? null : error ?? this.error,
  );
}

/// GTK implementation of [PlayerWindowController] for the Linux spike.
/// GTK's window-state event, not the request Future, confirms fullscreen.
final class GtkPlayerWindowController implements PlayerWindowController {
  GtkPlayerWindowController({
    MethodChannel? channel,
    this.transitionTimeout = const Duration(seconds: 3),
  }) : _channel = channel ?? const MethodChannel('kongroo/f2.3/window');

  final MethodChannel _channel;
  final Duration transitionTimeout;
  final StreamController<PlayerWindowSnapshot> _states =
      StreamController<PlayerWindowSnapshot>.broadcast(sync: true);
  PlayerWindowSnapshot _state = const PlayerWindowSnapshot();
  Future<void>? _initializeFuture;
  Timer? _transitionTimer;
  bool? _requestedFullscreen;
  bool _requestDispatching = false;
  int _dispatchGeneration = 0;
  bool _disposed = false;

  @override
  Stream<PlayerWindowSnapshot> get states => _states.stream;

  @override
  PlayerWindowSnapshot get state => _state;

  @override
  Future<void> initialize() {
    if (_disposed) {
      return Future<void>.error(StateError('Window controller is disposed.'));
    }
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    _channel.setMethodCallHandler(_handlePlatformCall);
    try {
      final bool fullscreen =
          await _channel.invokeMethod<bool>('getFullscreenState') ?? false;
      _emit(_state.copyWith(fullscreen: fullscreen, observed: true));
    } on Object {
      _emit(
        _state.copyWith(
          observed: false,
          error: 'GTK fullscreen state could not be read.',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> requestFullscreen(bool fullscreen) async {
    if (_disposed) throw StateError('Window controller is disposed.');
    if (_requestDispatching || _state.requestPending) return;
    final bool? unresolvedRequest = _requestedFullscreen;
    if (unresolvedRequest != null && unresolvedRequest != fullscreen) return;
    _requestDispatching = true;
    final int dispatchGeneration = ++_dispatchGeneration;

    try {
      await initialize();
      if (_state.requestPending || _state.fullscreen == fullscreen) return;

      _requestedFullscreen = fullscreen;
      _emit(_state.copyWith(requestPending: true, clearError: true));
      _transitionTimer?.cancel();
      _transitionTimer = Timer(transitionTimeout, () {
        if (!_disposed && _state.requestPending) {
          _emit(
            _state.copyWith(
              requestPending: false,
              error: 'GTK did not confirm the fullscreen transition.',
            ),
          );
        }
      });

      // This channel call only requests a transition. Its MethodChannel reply
      // may race with GTK's window-state-event and therefore cannot be used as
      // the observed state. Only fullscreenChanged confirms the new state.
      await _channel.invokeMethod<void>('setFullscreen', fullscreen);
    } on Object {
      if (dispatchGeneration == _dispatchGeneration) {
        _transitionTimer?.cancel();
        _requestedFullscreen = null;
        _emit(
          _state.copyWith(
            requestPending: false,
            error: 'GTK rejected the fullscreen request.',
          ),
        );
        rethrow;
      }
    } finally {
      if (dispatchGeneration == _dispatchGeneration) {
        _requestDispatching = false;
      }
    }
  }

  Future<Object?> _handlePlatformCall(MethodCall call) async {
    if (_disposed) return null;
    if (call.method != 'fullscreenChanged' || call.arguments is! bool) {
      throw MissingPluginException('Unsupported GTK window event.');
    }
    _acceptObservedFullscreen(call.arguments! as bool);
    return null;
  }

  void _acceptObservedFullscreen(bool fullscreen) {
    final bool confirmed = _requestedFullscreen == fullscreen;
    if (confirmed) {
      _transitionTimer?.cancel();
      _requestedFullscreen = null;
      // The platform event proves the transition completed even if the
      // request Future is delayed. Let a subsequent opposite transition run;
      // the generation prevents the older Future from settling its state.
      _requestDispatching = false;
      _dispatchGeneration++;
      _emit(
        _state.copyWith(
          fullscreen: fullscreen,
          observed: true,
          requestPending: false,
          clearError: true,
        ),
      );
    } else if (_requestedFullscreen == null) {
      _transitionTimer?.cancel();
      _emit(
        _state.copyWith(
          fullscreen: fullscreen,
          observed: true,
          requestPending: false,
          clearError: true,
        ),
      );
    } else {
      // A state event that contradicts an unresolved request updates the
      // observed state, but cannot complete or replace that request.
      _emit(_state.copyWith(fullscreen: fullscreen, observed: true));
    }
  }

  void _emit(PlayerWindowSnapshot snapshot) {
    _state = snapshot;
    if (!_states.isClosed) _states.add(snapshot);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _transitionTimer?.cancel();
    _transitionTimer = null;
    _requestedFullscreen = null;
    _channel.setMethodCallHandler(null);
    await _states.close();
  }
}
