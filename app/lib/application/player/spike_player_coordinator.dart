import 'dart:async';

import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_style.dart';

import 'playback_spike_contract.dart';

/// Serializes the basic F2.2 commands and exposes one coherent state stream.
/// It owns subscriptions and the engine lifecycle, but never imports media_kit.
final class SpikePlayerCoordinator implements ExternalSubtitleLoader {
  SpikePlayerCoordinator(
    this._engine, {
    Set<Uri> demoSources = const {},
    Set<Uri> trustedExternalSources = const {},
  }) : _demoSources = Set.unmodifiable(demoSources),
       _trustedExternalSources = Set.unmodifiable(trustedExternalSources);

  final Set<Uri> _demoSources;
  final Set<Uri> _trustedExternalSources;

  final PlaybackSpikeEngine _engine;
  final StreamController<PlaybackSessionSnapshot> _states =
      StreamController<PlaybackSessionSnapshot>.broadcast();
  StreamSubscription<PlaybackSpikeSnapshot>? _subscription;
  PlaybackSessionSnapshot _state = const PlaybackSessionSnapshot();
  Future<void> _tail = Future<void>.value();
  Future<void>? _disposeFuture;
  bool _initialized = false;
  bool _disposed = false;
  bool _disposeRequested = false;
  bool _engineDisposed = false;
  bool _hasOpenedSource = false;
  bool _seeking = false;
  int _sourceGeneration = 0;
  bool? _requestedPlaying;
  bool _playbackCommandInFlight = false;
  bool _switchingSource = false;
  Duration? _seekTarget;
  Duration? _seekAnchor;
  Duration _observedPosition = Duration.zero;
  double? _volumeTarget;
  Uri? _sourceUri;
  PlaybackRequestHeaders _sourceHttpHeaders =
      const PlaybackRequestHeaders.empty();
  int _mediaContextRevision = 0;

  /// Changes synchronously when an open, source switch, or Stop is requested,
  /// before its serialized engine operation starts. UI actions use it to
  /// invalidate track choices created for the preceding media context.
  int get mediaContextRevision => _mediaContextRevision;

  Stream<PlaybackSessionSnapshot> get states => _states.stream;
  PlaybackSessionSnapshot get state => _state;

  Future<void> initialize() => _serialize(() async {
    if (_initialized) return;
    _ensureOpen();
    try {
      await _engine.initialize();
    } catch (_) {
      _emitError('Playback engine initialization failed.');
      rethrow;
    }
    _subscription = _engine.snapshots.listen(
      (PlaybackSpikeSnapshot snapshot) {
        _acceptSnapshot(snapshot);
      },
      onError: (Object error, StackTrace stack) {
        _emitError('Playback engine reported an error.');
      },
    );
    _initialized = true;
    final PlaybackSpikeSnapshot playback = _state.playback.copyWith(
      clearError: true,
    );
    _publishState(playback, status: _statusFor(playback));
  });

  Future<void> open(
    Uri source, {
    PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(),
  }) {
    _mediaContextRevision++;
    return _serialize(() async {
      _ensureInitialized();
      final bool allowedExternal =
          source.scheme == 'https' &&
          source.host.isNotEmpty &&
          source.userInfo.isEmpty &&
          !source.hasFragment &&
          _trustedExternalSources.contains(source);
      if (source.scheme != 'file' &&
          !_demoSources.contains(source) &&
          !allowedExternal) {
        _emitError('Only local media files are supported.');
        throw ArgumentError('The source is not in the configured allowlist.');
      }
      final int generation = ++_sourceGeneration;
      _observedPosition = Duration.zero;
      _publishState(
        _state.playback.copyWith(clearError: true),
        status: PlaybackSessionStatus.opening,
        sourceGeneration: generation,
      );
      try {
        await _engine.open(
          source,
          sourceGeneration: generation,
          httpHeaders: httpHeaders,
        );
      } catch (_) {
        if (generation == _sourceGeneration) {
          _emitError('Could not open the selected media source.');
        }
        rethrow;
      }
      _hasOpenedSource = true;
      _sourceUri = source;
      _sourceHttpHeaders = httpHeaders;
      _observedPosition = Duration.zero;
      _seekTarget = null;
      _seekAnchor = null;
      _requestedPlaying = false;
      _publishState(
        _state.playback.copyWith(
          playing: false,
          stopped: false,
          clearError: true,
        ),
        status: PlaybackSessionStatus.ready,
        sourceUri: source,
      );
    });
  }

  /// Changes sources through the existing engine while preserving playback
  /// position and Play/Pause intent. Native error events still lack source IDs
  /// in media_kit 1.2.6, so asynchronous errors cannot be perfectly attributed.
  Future<PlaybackSourceSwitchResult> switchSource(
    Uri target, {
    PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(),
    Duration? referencePosition,
    bool? resumePlayback,
    Duration? rollbackPosition,
    bool preserveTracks = false,
  }) {
    _mediaContextRevision++;
    return _serialize(() async {
      _ensureInitialized();
      final bool allowedExternal =
          target.scheme == 'https' &&
          target.host.isNotEmpty &&
          target.userInfo.isEmpty &&
          !target.hasFragment &&
          _trustedExternalSources.contains(target);
      if (target.scheme != 'file' &&
          !_demoSources.contains(target) &&
          !allowedExternal) {
        throw ArgumentError('The source is not in the configured allowlist.');
      }
      if (_state.stopped) {
        throw StateError('Cannot switch source while playback is stopped.');
      }
      final Uri? previous = _sourceUri;
      if (previous == null && referencePosition == null) {
        throw StateError('No active source is available.');
      }
      final Duration reference =
          referencePosition ?? _seekTarget ?? _observedPosition;
      final bool wasPlaying = resumePlayback ?? _state.playing;
      final PlaybackSpikeSnapshot previousTracks = _state.playback;
      final PlaybackRequestHeaders previousHttpHeaders = _sourceHttpHeaders;
      if (target == previous &&
          _sameHeaders(httpHeaders.values, previousHttpHeaders.values)) {
        return PlaybackSourceSwitchResult(
          disposition: PlaybackSourceSwitchDisposition.unchanged,
          previousSource: previous,
          selectedSource: previous,
          referencePosition: reference,
          observedPosition: _observedPosition,
        );
      }

      _switchingSource = true;
      _seekTarget = null;
      _seekAnchor = null;
      _observedPosition = Duration.zero;
      final int generation = ++_sourceGeneration;
      _publishState(
        _state.playback.copyWith(
          playing: false,
          stopped: false,
          buffering: true,
          position: Duration.zero,
          duration: Duration.zero,
          clearError: true,
        ),
        status: PlaybackSessionStatus.switchingSource,
        sourceGeneration: generation,
      );

      try {
        if (wasPlaying) await _engine.pause();
        await _engine.open(
          target,
          sourceGeneration: generation,
          httpHeaders: httpHeaders,
        );
        await _waitForSwitchSnapshot(
          generation,
          (PlaybackSessionSnapshot snapshot) =>
              snapshot.error != null || snapshot.duration > Duration.zero,
        );
        if (_state.error != null) {
          throw StateError('The new source failed to load.');
        }
        final Duration targetPosition = _boundedPosition(
          reference,
          _state.duration,
        );
        await _engine.seek(targetPosition);
        _seekTarget = targetPosition;
        _seekAnchor = reference;
        final Duration observed = await _waitForObservedPosition(
          generation,
          targetPosition,
        );
        if (preserveTracks) await _restoreEquivalentTracks(previousTracks);
        if (wasPlaying) {
          await _engine.play();
        } else {
          await _engine.pause();
        }
        if (_state.error != null) {
          throw StateError('The source failed during switch.');
        }
        _sourceUri = target;
        _sourceHttpHeaders = httpHeaders;
        _hasOpenedSource = true;
        _requestedPlaying = null;
        _seekTarget = null;
        _seekAnchor = null;
        final PlaybackSpikeSnapshot playback = _state.playback.copyWith(
          playing: wasPlaying,
          stopped: false,
          buffering: false,
          position: observed,
          clearError: true,
        );
        _publishState(
          playback,
          status: _statusFor(playback),
          sourceUri: target,
        );
        return PlaybackSourceSwitchResult(
          disposition: PlaybackSourceSwitchDisposition.changed,
          previousSource: previous,
          selectedSource: target,
          referencePosition: reference,
          observedPosition: observed,
        );
      } catch (_) {
        final bool restored =
            previous != null &&
            await _restoreSource(
              previous,
              rollbackPosition ?? reference,
              wasPlaying,
              previousTracks,
              previousHttpHeaders,
            );
        if (restored) {
          return PlaybackSourceSwitchResult(
            disposition:
                PlaybackSourceSwitchDisposition.targetFailedPreviousRestored,
            previousSource: previous,
            selectedSource: previous,
            referencePosition: reference,
            observedPosition: _observedPosition,
            error:
                'The selected source failed; the previous source was restored.',
          );
        }
        _sourceUri = null;
        _sourceHttpHeaders = const PlaybackRequestHeaders.empty();
        _hasOpenedSource = false;
        _emitError(
          'The selected source and previous source could not be restored.',
          clearSourceUri: true,
        );
        return PlaybackSourceSwitchResult(
          disposition: PlaybackSourceSwitchDisposition.targetAndPreviousFailed,
          previousSource: previous,
          selectedSource: null,
          referencePosition: reference,
          observedPosition: null,
          error:
              'The selected source and previous source could not be restored.',
        );
      } finally {
        _switchingSource = false;
      }
    });
  }

  Future<void> play() => _serialize(() async {
    _ensureInitialized();
    _ensureSourceOpen();
    await _setPlaybackIntent(true, _engine.play);
  });

  Future<void> pause() => _serialize(() async {
    _ensureInitialized();
    _ensureSourceOpen();
    if (_state.stopped) {
      throw StateError('Cannot pause while playback is stopped.');
    }
    await _setPlaybackIntent(false, _engine.pause);
  });

  /// Toggles from the latest serialized playback intent, so rapid keyboard
  /// presses cannot both choose an action from a stale widget snapshot.
  Future<void> togglePlayback() => _serialize(() async {
    _ensureInitialized();
    _ensureSourceOpen();
    final bool shouldPlay = !(_requestedPlaying ?? _state.playing);
    await _setPlaybackIntent(
      shouldPlay,
      shouldPlay ? _engine.play : _engine.pause,
    );
  });

  Future<void> seek(Duration position, {int? generation}) =>
      _serialize(() async {
        if (generation != null && generation != _sourceGeneration) {
          throw StateError('Seek belongs to a previous source.');
        }
        _ensureInitialized();
        _ensureSourceOpen();
        if (_state.stopped) {
          throw StateError('Cannot seek while playback is stopped.');
        }
        if (position.isNegative ||
            (_state.duration > Duration.zero && position > _state.duration)) {
          throw RangeError('Seek position is outside the media duration.');
        }
        await _seekTo(position, anchor: _state.position);
      });

  /// Applies a relative seek at execution time, after earlier queued seeks.
  Future<void> seekBy(Duration delta) => _serialize(() async {
    _ensureInitialized();
    _ensureSourceOpen();
    if (_state.stopped) {
      throw StateError('Cannot seek while playback is stopped.');
    }
    final Duration base = _seekTarget ?? _state.position;
    Duration target = base + delta;
    if (target.isNegative) target = Duration.zero;
    if (_state.duration > Duration.zero && target > _state.duration) {
      target = _state.duration;
    }
    await _seekTo(target, anchor: base);
  });

  /// Sets player-local volume, clamped to Kongroo's 0–100 range.
  Future<void> setVolume(double volume) => _serialize(() async {
    _ensureInitialized();
    if (!volume.isFinite) throw RangeError.value(volume, 'volume');
    await _setVolumeTarget(
      volume.clamp(playbackSpikeMinimumVolume, playbackSpikeMaximumVolume),
    );
  });

  /// Applies a relative volume change after earlier queued volume changes.
  Future<void> adjustVolumeBy(double delta) => _serialize(() async {
    _ensureInitialized();
    if (!delta.isFinite) throw RangeError.value(delta, 'delta');
    final double base = _volumeTarget ?? _state.volume;
    final double target = (base + delta).clamp(
      playbackSpikeMinimumVolume,
      playbackSpikeMaximumVolume,
    );
    await _setVolumeTarget(target);
  });

  Future<void> selectAudioTrack(String id, {required int generation}) =>
      _serialize(() async {
        _ensureInitialized();
        _ensureSourceOpen();
        if (_state.stopped || generation != _sourceGeneration) {
          throw StateError('Audio selection is no longer available.');
        }
        final PlaybackSpikeEngine engine = _engine;
        if (engine is! PlaybackAudioSelection) {
          throw UnsupportedError('Audio selection is unavailable.');
        }
        await (engine as PlaybackAudioSelection).selectAudioTrack(id);
      });

  /// Selects an actual track in the currently loaded media. A menu opened for
  /// an earlier source cannot apply its native ID to a replacement source.
  Future<void> selectVideoTrack(String id, {required int generation}) =>
      _serialize(() async {
        _ensureInitialized();
        _ensureSourceOpen();
        if (_state.stopped || generation != _sourceGeneration) {
          throw StateError('Video selection is no longer available.');
        }
        final bool autoIsAvailable =
            id == 'auto' && _state.videoTracks.length > 1;
        if (!autoIsAvailable &&
            !_state.videoTracks.any((track) => track.id == id)) {
          throw ArgumentError.value(id, 'id', 'Video track is unavailable.');
        }
        final PlaybackSpikeEngine engine = _engine;
        if (engine is! PlaybackVideoSelection) {
          throw UnsupportedError('Video selection is unavailable.');
        }
        await (engine as PlaybackVideoSelection).selectVideoTrack(id);
      });

  Future<void> selectSubtitleTrack(String id) => _serialize(() async {
    _ensureInitialized();
    _ensureSourceOpen();
    await _engine.selectSubtitleTrack(id);
  });

  @override
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
    int? sourceGeneration,
  }) async {
    late ExternalSubtitleDecision decision;
    await _serialize(() async {
      _ensureInitialized();
      _ensureSourceOpen();
      if (sourceGeneration != null && sourceGeneration != _sourceGeneration) {
        throw StateError('Subtitle belongs to a previous source.');
      }
      decision = await _engine.loadExternalSubtitle(
        source,
        hardsubStatus: hardsubStatus,
        title: title,
        language: language,
      );
    });
    return decision;
  }

  Future<void> applySubtitleStyle(SubtitleStyle style) => _serialize(() async {
    _ensureInitialized();
    await _engine.applySubtitleStyle(style);
  });

  Future<void> setSubtitleDelay(Duration delay) => _serialize(() async {
    _ensureInitialized();
    _ensureSourceOpen();
    await _engine.setSubtitleDelay(delay);
  });

  Future<void> _seekTo(Duration target, {required Duration anchor}) async {
    final Duration previousPosition = _state.position;
    final Duration? previousTarget = _seekTarget;
    final Duration? previousAnchor = _seekAnchor;
    _seekAnchor = anchor;
    _seekTarget = target;
    _seeking = true;
    _publishState(_state.playback.copyWith(position: target), seeking: true);
    try {
      await _engine.seek(target);
    } catch (_) {
      _seekTarget = previousTarget;
      _seekAnchor = previousAnchor;
      _seeking = false;
      _publishState(
        _state.playback.copyWith(position: previousTarget ?? previousPosition),
        seeking: false,
      );
      _emitError('Seek failed.');
      rethrow;
    }
    _seeking = false;
    final PlaybackSpikeSnapshot playback = _state.playback.copyWith(
      clearError: true,
    );
    _publishState(playback, status: _statusFor(playback), seeking: false);
  }

  Future<void> _setVolumeTarget(double target) async {
    final double previousVolume = _state.volume;
    final double? previousTarget = _volumeTarget;
    _volumeTarget = target;
    _publishState(_state.playback.copyWith(volume: target));
    try {
      await _engine.setVolume(target);
      final PlaybackSpikeSnapshot playback = _state.playback.copyWith(
        clearError: true,
      );
      _publishState(playback, status: _statusFor(playback));
    } catch (_) {
      _volumeTarget = previousTarget;
      _publishState(
        _state.playback.copyWith(volume: previousTarget ?? previousVolume),
      );
      _emitError('Volume change failed.');
      rethrow;
    }
  }

  Future<void> stop() {
    _mediaContextRevision++;
    return _serialize(() async {
      _ensureInitialized();
      _seekTarget = null;
      _seekAnchor = null;
      try {
        await _engine.stop();
        _requestedPlaying = false;
        if (_state.playing == false) _requestedPlaying = null;
        _publishState(
          _state.playback.copyWith(
            playing: false,
            stopped: true,
            buffering: false,
            position: Duration.zero,
            clearError: true,
          ),
          status: PlaybackSessionStatus.stopped,
        );
      } catch (_) {
        _emitError('Stop failed.');
        rethrow;
      }
    });
  }

  Future<void> _setPlaybackIntent(
    bool shouldPlay,
    Future<void> Function() operation,
  ) async {
    _requestedPlaying = shouldPlay;
    _playbackCommandInFlight = true;
    try {
      await operation();
      final PlaybackSpikeSnapshot playback = _state.playback.copyWith(
        playing: shouldPlay,
        stopped: shouldPlay ? false : _state.stopped,
        buffering: false,
        clearError: true,
      );
      _publishState(
        playback,
        status: shouldPlay
            ? PlaybackSessionStatus.playing
            : (_hasOpenedSource
                  ? PlaybackSessionStatus.paused
                  : PlaybackSessionStatus.idle),
      );
    } catch (_) {
      _requestedPlaying = null;
      _emitError(shouldPlay ? 'Playback failed.' : 'Pause failed.');
      rethrow;
    } finally {
      _playbackCommandInFlight = false;
      if (_state.playing == shouldPlay) _requestedPlaying = null;
    }
  }

  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    final Future<void>? current = _disposeFuture;
    if (current != null) return current;

    _disposeRequested = true;
    final Future<void> future = _serialize(_disposeResources);
    _disposeFuture = future;
    unawaited(
      future.then<void>(
        (_) => _clearDisposeFuture(future),
        onError: (Object _, StackTrace _) => _clearDisposeFuture(future),
      ),
    );
    return future;
  }

  Future<void> _disposeResources() async {
    _publishState(_state.playback, status: PlaybackSessionStatus.closing);
    Object? failure;
    StackTrace? failureStack;
    try {
      await _subscription?.cancel();
      _subscription = null;
    } catch (error, stack) {
      failure = error;
      failureStack = stack;
    }

    try {
      // The adapter may have allocated Player before initialize failed.
      if (!_engineDisposed) {
        await _engine.dispose();
        _engineDisposed = true;
      }
    } catch (error, stack) {
      failure ??= error;
      failureStack ??= stack;
    }

    bool errorPublished = false;
    if (failure != null) {
      _emitError('Playback cleanup failed.');
      errorPublished = true;
    } else {
      _publishState(_state.playback, status: PlaybackSessionStatus.disposed);
    }

    try {
      if (!_states.isClosed) await _states.close();
    } catch (error, stack) {
      failure ??= error;
      failureStack ??= stack;
    }

    if (failure != null) {
      if (!errorPublished) _emitError('Playback cleanup failed.');
      Error.throwWithStackTrace(failure, failureStack!);
    }
    _disposed = true;
  }

  void _clearDisposeFuture(Future<void> future) {
    if (identical(_disposeFuture, future)) _disposeFuture = null;
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final Completer<T> result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stack) {
        if (!result.isCompleted) result.completeError(error, stack);
      }
    });
    return result.future;
  }

  void _ensureOpen() {
    if (_disposeRequested) {
      throw StateError('Playback coordinator is disposing or disposed.');
    }
  }

  void _ensureInitialized() {
    _ensureOpen();
    if (!_initialized) throw StateError('Playback engine is not initialized.');
  }

  void _ensureSourceOpen() {
    if (!_hasOpenedSource) throw StateError('No media source is open.');
  }

  void _emitError(String message, {bool clearSourceUri = false}) {
    if (clearSourceUri) {
      _sourceHttpHeaders = const PlaybackRequestHeaders.empty();
    }
    _publishState(
      _state.playback.copyWith(error: message),
      status: PlaybackSessionStatus.error,
      clearSourceUri: clearSourceUri,
    );
  }

  void _acceptSnapshot(PlaybackSpikeSnapshot snapshot) {
    if (snapshot.sourceGeneration != _sourceGeneration) {
      return;
    }
    if (_state.status == PlaybackSessionStatus.closing ||
        _state.status == PlaybackSessionStatus.disposed) {
      return;
    }
    _observedPosition = snapshot.position;
    if (!_playbackCommandInFlight && _requestedPlaying == snapshot.playing) {
      _requestedPlaying = null;
    }
    if (_seekTarget case final Duration target) {
      final Duration anchor = _seekAnchor ?? target;
      final bool reached = target > anchor
          ? snapshot.position >= target - const Duration(milliseconds: 100)
          : target < anchor
          ? snapshot.position <= target + const Duration(milliseconds: 100)
          : (snapshot.position - target).inMilliseconds.abs() <= 100;
      if (reached) {
        _seekTarget = null;
        _seekAnchor = null;
      }
    }
    if (_volumeTarget case final double target) {
      if ((snapshot.volume - target).abs() < 0.01) _volumeTarget = null;
    }
    final PlaybackSpikeSnapshot playback = snapshot.copyWith(
      position: _seekTarget ?? snapshot.position,
      volume: _volumeTarget ?? snapshot.volume,
    );
    _publishState(
      playback,
      status: _switchingSource
          ? PlaybackSessionStatus.switchingSource
          : _statusFor(playback),
    );
  }

  Duration _boundedPosition(Duration reference, Duration duration) {
    if (duration <= Duration.zero) {
      throw StateError('The selected source has no known VOD duration.');
    }
    if (reference > duration) {
      throw StateError(
        'The selected source is shorter than the current position.',
      );
    }
    return reference;
  }

  Future<PlaybackSessionSnapshot> _waitForSwitchSnapshot(
    int generation,
    bool Function(PlaybackSessionSnapshot snapshot) predicate,
  ) async {
    bool matches(PlaybackSessionSnapshot snapshot) =>
        snapshot.sourceGeneration == generation && predicate(snapshot);
    if (matches(_state)) return _state;
    final Completer<PlaybackSessionSnapshot> completer = Completer();
    final StreamSubscription<PlaybackSessionSnapshot> subscription = states
        .listen((PlaybackSessionSnapshot snapshot) {
          if (!completer.isCompleted && matches(snapshot)) {
            completer.complete(snapshot);
          }
        });
    try {
      return await completer.future.timeout(const Duration(seconds: 12));
    } finally {
      await subscription.cancel();
    }
  }

  Future<Duration> _waitForObservedPosition(
    int generation,
    Duration target,
  ) async {
    final PlaybackSessionSnapshot current = _state;
    if (current.sourceGeneration == generation) {
      if (current.error != null) {
        throw StateError('The source failed during seek.');
      }
      if ((current.observedPosition - target).abs() <=
          const Duration(seconds: 2)) {
        return current.observedPosition;
      }
    }
    final Completer<Duration> completer = Completer();
    void inspect(PlaybackSessionSnapshot snapshot) {
      if (completer.isCompleted || snapshot.sourceGeneration != generation) {
        return;
      }
      if (snapshot.error != null) {
        completer.completeError(StateError('The source failed during seek.'));
      } else if ((snapshot.observedPosition - target).abs() <=
          const Duration(seconds: 2)) {
        completer.complete(snapshot.observedPosition);
      }
    }

    final StreamSubscription<PlaybackSessionSnapshot> subscription = states
        .listen(inspect);
    inspect(_state);
    try {
      return await completer.future.timeout(const Duration(seconds: 12));
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _restoreEquivalentTracks(PlaybackSpikeSnapshot previous) async {
    final audio = previous.audioTracks
        .where((track) => track.id == previous.selectedAudioId)
        .firstOrNull;
    final String? audioLanguage = audio?.language?.toLowerCase();
    final audioTracks = _state.playback.audioTracks;
    final exactAudio = audioTracks
        .where(
          (track) =>
              track.id == audio?.id &&
              track.language == audio?.language &&
              track.title == audio?.title &&
              track.codec == audio?.codec,
        )
        .firstOrNull;
    final audioMatches = audioTracks
        .where(
          (track) =>
              audioLanguage != null &&
              track.language?.toLowerCase() == audioLanguage,
        )
        .toList();
    final engine = _engine;
    if (engine is PlaybackAudioSelection) {
      final String? id = switch (previous.selectedAudioId) {
        'auto' || 'no' => previous.selectedAudioId,
        _ =>
          exactAudio?.id ??
              (audioMatches.length == 1 ? audioMatches.single.id : null),
      };
      if (id != null && id != _state.playback.selectedAudioId) {
        await (engine as PlaybackAudioSelection).selectAudioTrack(id);
      }
    }
    final subtitle = previous.subtitleTracks
        .where((track) => track.id == previous.selectedSubtitleId)
        .firstOrNull;
    final String? subtitleLanguage = subtitle?.language?.toLowerCase();
    final exactSubtitle = _state.subtitleTracks
        .where(
          (track) =>
              track.id == subtitle?.id &&
              track.kind == subtitle?.kind &&
              track.language == subtitle?.language &&
              track.label == subtitle?.label,
        )
        .firstOrNull;
    final subtitleMatches = _state.subtitleTracks
        .where(
          (track) =>
              subtitleLanguage != null &&
              track.kind == subtitle?.kind &&
              track.language?.toLowerCase() == subtitleLanguage,
        )
        .toList();
    final String? subtitleId = switch (previous.selectedSubtitleId) {
      'auto' || 'no' => previous.selectedSubtitleId,
      _ =>
        exactSubtitle?.id ??
            (subtitleMatches.length == 1 ? subtitleMatches.single.id : null),
    };
    if (subtitleId != null && subtitleId != _state.selectedSubtitleId) {
      await _engine.selectSubtitleTrack(subtitleId);
    }
  }

  Future<bool> _restoreSource(
    Uri source,
    Duration reference,
    bool wasPlaying,
    PlaybackSpikeSnapshot? previousTracks,
    PlaybackRequestHeaders httpHeaders,
  ) async {
    final int generation = ++_sourceGeneration;
    _seekTarget = null;
    _seekAnchor = null;
    _observedPosition = Duration.zero;
    _publishState(
      _state.playback.copyWith(
        playing: false,
        stopped: false,
        buffering: true,
        position: Duration.zero,
        duration: Duration.zero,
        clearError: true,
      ),
      status: PlaybackSessionStatus.switchingSource,
      sourceGeneration: generation,
    );
    try {
      await _engine.open(
        source,
        sourceGeneration: generation,
        httpHeaders: httpHeaders,
      );
      await _waitForSwitchSnapshot(
        generation,
        (PlaybackSessionSnapshot snapshot) =>
            snapshot.error != null || snapshot.duration > Duration.zero,
      );
      if (_state.error != null) return false;
      final Duration target = _boundedPosition(reference, _state.duration);
      await _engine.seek(target);
      final Duration observed = await _waitForObservedPosition(
        generation,
        target,
      );
      if ((observed - reference).abs() > const Duration(seconds: 2)) {
        return false;
      }
      if (previousTracks != null) {
        await _restoreEquivalentTracks(previousTracks);
      }
      if (wasPlaying) {
        await _engine.play();
      } else {
        await _engine.pause();
      }
      if (_state.error != null) return false;
      _sourceUri = source;
      _sourceHttpHeaders = httpHeaders;
      _hasOpenedSource = true;
      _requestedPlaying = null;
      _seekTarget = null;
      _seekAnchor = null;
      final PlaybackSpikeSnapshot playback = _state.playback.copyWith(
        playing: wasPlaying,
        stopped: false,
        buffering: false,
        position: observed,
        clearError: true,
      );
      _publishState(playback, status: _statusFor(playback), sourceUri: source);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _sameHeaders(
    Map<String, String> first,
    Map<String, String> second,
  ) =>
      first.length == second.length &&
      first.entries.every(
        (MapEntry<String, String> entry) => second[entry.key] == entry.value,
      );

  PlaybackSessionStatus _statusFor(PlaybackSpikeSnapshot playback) {
    if (playback.error != null) return PlaybackSessionStatus.error;
    if (playback.stopped) return PlaybackSessionStatus.stopped;
    if (playback.buffering) return PlaybackSessionStatus.buffering;
    if (playback.playing) return PlaybackSessionStatus.playing;
    if (!_hasOpenedSource) return PlaybackSessionStatus.idle;
    if (playback.duration > Duration.zero &&
        playback.position >= playback.duration) {
      return PlaybackSessionStatus.completed;
    }
    if (_state.status == PlaybackSessionStatus.ready &&
        playback.position == Duration.zero) {
      return PlaybackSessionStatus.ready;
    }
    return PlaybackSessionStatus.paused;
  }

  void _publishState(
    PlaybackSpikeSnapshot playback, {
    PlaybackSessionStatus? status,
    bool? seeking,
    int? sourceGeneration,
    Uri? sourceUri,
    bool clearSourceUri = false,
  }) {
    _state = _state.copyWith(
      playback: playback,
      observedPosition: _observedPosition,
      status: status ?? _statusFor(playback),
      seeking: seeking ?? _seeking,
      sourceGeneration: sourceGeneration ?? _sourceGeneration,
      sourceUri: sourceUri,
      clearSourceUri: clearSourceUri,
    );
    if (!_states.isClosed) _states.add(_state);
  }
}
