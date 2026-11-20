import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../application/player/diagnostics/playback_performance.dart';
import '../../../application/player/playback_spike_contract.dart';
import '../../../domain/player/audio_track_info.dart';
import '../../../domain/player/providers/playback_source.dart';
import '../../../domain/player/subtitles/hardsub_policy.dart';
import '../../../domain/player/subtitles/subtitle_style.dart';
import '../../../domain/player/subtitles/subtitle_track_info.dart';
import '../../../domain/player/video_track_info.dart';
import 'active_player_lease.dart';
import 'media_codec_support.dart';
import 'mpv_performance_reader.dart';
import 'mpv_subtitle_properties.dart';

/// F2.2 adapter. The sole owner of one media_kit Player and its video surface.
final class MediaKitSpikeEngine
    implements
        PlaybackSpikeEngine,
        PlaybackAudioSelection,
        PlaybackVideoSelection,
        PlaybackPerformanceSource {
  factory MediaKitSpikeEngine({
    Set<Uri> demoSources = const {},
    Set<Uri> trustedExternalSources = const {},
    Map<Uri, List<ProviderSubtitle>> providerSubtitles = const {},
  }) {
    if (providerSubtitles.keys.any(
      (uri) =>
          !trustedExternalSources.contains(uri) && !demoSources.contains(uri),
    )) {
      throw ArgumentError(
        'Caption catalogs require an authorized media source.',
      );
    }
    final ActivePlayerLease lease = ActivePlayerLease.acquire();
    final StreamController<PlaybackSpikeSnapshot> snapshots =
        StreamController<PlaybackSpikeSnapshot>.broadcast();
    Player? player;
    try {
      // media_kit must be initialized before constructing Player. The codec
      // module reports the platform H.264 strategy (Linux bundles a verified
      // decoder; Android/Windows use the platform stack) and is a no-op when
      // no preparation is required.
      prepareMediaCodecSupport();
      MediaKit.ensureInitialized();
      player = Player(configuration: const PlayerConfiguration(libass: true));
      // Keep construction minimal: surface/controller creation happens only
      // after the caller owns this engine and can await its cleanup on failure.
      return MediaKitSpikeEngine._(
        player,
        snapshots,
        lease,
        demoSources: demoSources,
        trustedExternalSources: trustedExternalSources,
        providerSubtitles: providerSubtitles,
      );
    } catch (error, stack) {
      final Player? allocatedPlayer = player;
      bool playerDisposeAttempted = false;
      Object? playerDisposeFailure;
      StackTrace? playerDisposeFailureStack;

      Future<void> rollbackNativePlayer() async {
        if (allocatedPlayer != null && !playerDisposeAttempted) {
          playerDisposeAttempted = true;
          try {
            await allocatedPlayer.dispose();
          } catch (disposeError, disposeStack) {
            playerDisposeFailure = disposeError;
            playerDisposeFailureStack = disposeStack;
          }
        }
        if (playerDisposeFailure != null) {
          Error.throwWithStackTrace(
            playerDisposeFailure!,
            playerDisposeFailureStack!,
          );
        }
      }

      unawaited(
        lease
            .release(rollbackNativePlayer)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
      unawaited(
        snapshots.close().then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {},
        ),
      );
      Error.throwWithStackTrace(error, stack);
    }
  }

  /// Creates an engine whose native dispose call can be fault-injected.
  @visibleForTesting
  factory MediaKitSpikeEngine.forTesting({
    required Future<void> Function(Player player) disposePlayer,
    Future<void> Function()? auxiliaryCleanupForTesting,
  }) {
    final ActivePlayerLease lease = ActivePlayerLease.acquire();
    final StreamController<PlaybackSpikeSnapshot> snapshots =
        StreamController<PlaybackSpikeSnapshot>.broadcast();
    Player? player;
    try {
      MediaKit.ensureInitialized();
      final Player createdPlayer = Player(
        configuration: const PlayerConfiguration(libass: true),
      );
      player = createdPlayer;
      return MediaKitSpikeEngine._(
        createdPlayer,
        snapshots,
        lease,
        disposePlayer: () => disposePlayer(createdPlayer),
        auxiliaryCleanupForTesting: auxiliaryCleanupForTesting,
      );
    } catch (error, stack) {
      final Player? allocatedPlayer = player;
      var playerDisposeAttempted = false;
      Object? playerDisposeFailure;
      StackTrace? playerDisposeFailureStack;
      Future<void> rollbackNativePlayer() async {
        if (allocatedPlayer != null && !playerDisposeAttempted) {
          playerDisposeAttempted = true;
          try {
            await allocatedPlayer.dispose();
          } catch (disposeError, disposeStack) {
            playerDisposeFailure = disposeError;
            playerDisposeFailureStack = disposeStack;
          }
        }
        if (playerDisposeFailure != null) {
          Error.throwWithStackTrace(
            playerDisposeFailure!,
            playerDisposeFailureStack!,
          );
        }
      }

      unawaited(
        lease
            .release(rollbackNativePlayer)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
      unawaited(
        snapshots.close().then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {},
        ),
      );
      Error.throwWithStackTrace(error, stack);
    }
  }

  /// Retries cleanup left pending after a previous dispose failure.
  /// If native Player.dispose itself failed, the lease stays quarantined and
  /// this rethrows that failure; restarting the process is required before a
  /// new native Player can be created safely.
  static Future<void> retryPendingDispose() =>
      ActivePlayerLease.retryPendingRelease();

  /// Whether a live or quarantined native Player still owns the exclusive slot.
  static bool get hasActivePlayerLease => ActivePlayerLease.hasActiveLease;

  MediaKitSpikeEngine._(
    Player player,
    this._snapshots,
    this._lease, {
    Future<void> Function()? disposePlayer,
    this._auxiliaryCleanupForTesting,
    Set<Uri> demoSources = const {},
    Set<Uri> trustedExternalSources = const {},
    Map<Uri, List<ProviderSubtitle>> providerSubtitles = const {},
  }) : _providerSubtitles = Map.unmodifiable({
         for (final entry in providerSubtitles.entries)
           entry.key: List<ProviderSubtitle>.unmodifiable(entry.value),
       }),
       _demoSources = Set.unmodifiable(demoSources),
       _trustedExternalSources = Set.unmodifiable(trustedExternalSources),
       _player = player,
       _disposePlayer = disposePlayer ?? player.dispose;

  final Map<Uri, List<ProviderSubtitle>> _providerSubtitles;
  final Set<Uri> _demoSources;
  final Set<Uri> _trustedExternalSources;
  final Player _player;
  final Future<void> Function() _disposePlayer;
  final Future<void> Function()? _auxiliaryCleanupForTesting;
  final ActivePlayerLease _lease;
  final StreamController<PlaybackSpikeSnapshot> _snapshots;
  VideoController? _videoController;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  StreamSubscription<String>? _sourceErrorSubscription;
  Future<void>? _disposeFuture;
  PlaybackSpikeSnapshot _state = const PlaybackSpikeSnapshot();
  bool _initialized = false;
  bool _disposed = false;
  bool _playerDisposeAttempted = false;
  bool _playerDisposed = false;
  Object? _playerDisposeFailure;
  StackTrace? _playerDisposeFailureStack;
  int _nativeErrorRevision = 0;
  int? _nativeHttpStatus;
  int _sourceGeneration = 0;
  Uri? _currentSource;
  PlaybackRequestHeaders _currentHttpHeaders =
      const PlaybackRequestHeaders.empty();
  bool _stopped = false;
  bool _automaticVideoSelection = false;
  int _positionEventCount = 0;
  int _previousPositionEventCount = 0;
  DateTime? _previousPerformanceSampleTime;

  /// The UI surface uses this controller for this adapter's single Player.
  VideoController get videoController =>
      _videoController ??
      (throw StateError('This engine was created without a video surface.'));

  /// Creates the presentation controller after the caller owns this engine.
  /// If setup throws, the caller can still await [dispose] and retry cleanup.
  void attachVideoSurface() {
    _ensureNotDisposed();
    if (_videoController != null) {
      throw StateError('A video surface is already attached.');
    }
    _videoController = VideoController(_player);
  }

  /// Most recently observed engine state, useful for diagnostics/tests.
  PlaybackSpikeSnapshot get currentSnapshot => _state;

  @override
  Future<PlaybackPerformanceSample> samplePerformance() {
    _ensureReady();
    final DateTime now = DateTime.now();
    final DateTime? previous = _previousPerformanceSampleTime;
    final Duration? elapsed = previous == null
        ? null
        : now.difference(previous);
    final int delta = _positionEventCount - _previousPositionEventCount;
    _previousPerformanceSampleTime = now;
    _previousPositionEventCount = _positionEventCount;
    final double? rate =
        elapsed == null ||
            elapsed <= Duration.zero ||
            elapsed > const Duration(seconds: 2)
        ? null
        : delta / (elapsed.inMicroseconds / 1000000);
    return readMpvPerformance(_player, positionEventsPerSecond: rate);
  }

  @override
  Stream<PlaybackSpikeSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> initialize() async {
    _ensureNotDisposed();
    if (_initialized) return;
    MediaKit.ensureInitialized();
    _listen<bool>(_player.stream.playing, (bool value) {
      if (_player.state.playing == value) _copy(playing: value);
    });
    _listen<bool>(_player.stream.buffering, (bool value) {
      if (_player.state.buffering == value) _copy(buffering: value);
    });
    _listen<Duration>(_player.stream.position, (Duration value) {
      _positionEventCount++;
      if (_player.state.position == value) _copy(position: value);
    });
    _listen<Duration>(_player.stream.duration, (Duration value) {
      if (_player.state.duration == value) _copy(duration: value);
    });
    _listen<double>(_player.stream.volume, (double value) {
      if (_player.state.volume == value) {
        _copy(
          volume: value.clamp(
            playbackSpikeMinimumVolume,
            playbackSpikeMaximumVolume,
          ),
        );
      }
    });
    _listen<Tracks>(_player.stream.tracks, (Tracks value) {
      if (_player.state.tracks == value) _syncTrackState();
    });
    _listen<Track>(_player.stream.track, (Track value) {
      if (_player.state.track == value) _syncTrackState();
    });
    _state = _state.copyWith(
      volume: _player.state.volume.clamp(
        playbackSpikeMinimumVolume,
        playbackSpikeMaximumVolume,
      ),
    );
    _initialized = true;
    _publish();
  }

  @override
  Future<void> open(
    Uri source, {
    int sourceGeneration = 0,
    PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(),
  }) async {
    _ensureReady();
    await _validateSource(source);
    _sourceGeneration = sourceGeneration;
    _captionRevision++;
    _captionSource = null;
    _automaticVideoSelection = false;
    await _replaceSourceErrorSubscription(sourceGeneration);
    _copy(
      playing: false,
      stopped: false,
      buffering: true,
      position: Duration.zero,
      duration: Duration.zero,
      audioTracks: const [],
      selectedAudioId: 'auto',
      videoTracks: const [],
      selectedVideoId: 'auto',
      subtitleTracks: const [],
      selectedSubtitleId: 'auto',
      clearError: true,
    );
    // Hide the previous source's optional captions even while open is pending.
    _captionSource = null;
    await _openValidated(source, play: false, httpHeaders: httpHeaders);
    _currentSource = source;
    _captionSource = source;
    _currentHttpHeaders = httpHeaders;
    _stopped = false;
    _copy(
      stopped: false,
      position: Duration.zero,
      subtitleTracks: _subtitleTrackInfo(),
      selectedSubtitleId: _selectedSubtitleId,
      audioTracks: _audioTrackInfo(),
      selectedAudioId: _player.state.track.audio.id,
      videoTracks: _videoTrackInfo(),
      selectedVideoId: _player.state.track.video.id,
    );
  }

  Future<void> _validateSource(Uri source) async {
    if (source.scheme == 'https' &&
        source.host.isNotEmpty &&
        source.userInfo.isEmpty &&
        !source.hasFragment &&
        _trustedExternalSources.contains(source)) {
      return;
    }
    if (source.scheme == 'http' &&
        source.host == '127.0.0.1' &&
        source.hasPort &&
        source.userInfo.isEmpty &&
        !source.hasQuery &&
        !source.hasFragment &&
        _trustedExternalSources.contains(source)) {
      // The loopback media proxy. Only the exact URI the manager resolved is
      // accepted, so the engine never opens an arbitrary local address.
      return;
    }
    if (source.scheme == 'http' &&
        source.host == '127.0.0.1' &&
        source.hasPort &&
        source.userInfo.isEmpty &&
        !source.hasQuery &&
        !source.hasFragment &&
        _demoSources.contains(source)) {
      return;
    }
    if (source.scheme != 'file') {
      throw ArgumentError('F2.2 accepts local file URIs only.');
    }
    final File sourceFile;
    try {
      sourceFile = File.fromUri(source);
    } on Object {
      throw ArgumentError('F2.2 accepts valid local file URIs only.');
    }
    final FileSystemEntityType sourceType = await FileSystemEntity.type(
      sourceFile.path,
      followLinks: false,
    );
    if (sourceType != FileSystemEntityType.file) {
      throw StateError(
        'The local media source is not an existing regular file.',
      );
    }
  }

  Future<void> _openValidated(
    Uri source, {
    required bool play,
    PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(),
  }) async {
    final int errorRevisionAtOpen = _nativeErrorRevision;
    _nativeHttpStatus = null;
    await _player.open(
      Media(source.toString(), httpHeaders: httpHeaders.values),
      play: play,
    );
    // Clear an old failure only if this open attempt did not report a new
    // stream error before its Future completed.
    if (_nativeErrorRevision == errorRevisionAtOpen) _copy(clearError: true);
  }

  Future<void> _replaceSourceErrorSubscription(int generation) async {
    await _sourceErrorSubscription?.cancel();
    _sourceErrorSubscription = _player.stream.error.listen(
      (String value) {
        if (_sourceGeneration != generation) return;
        _nativeErrorRevision++;
        _copy(error: _safeError(value));
      },
      onError: (Object _) {
        if (_sourceGeneration == generation) {
          _copy(error: 'The native playback engine reported an error.');
        }
      },
    );
  }

  @override
  Future<void> play() async {
    _ensureReady();
    if (_stopped) {
      final Uri? source = _currentSource;
      if (source == null) {
        throw StateError('No media source is available after Stop.');
      }
      await _validateSource(source);
      await _openValidated(
        source,
        play: true,
        httpHeaders: _currentHttpHeaders,
      );
      _stopped = false;
      _syncTrackState();
      _copy(
        stopped: false,
        position: Duration.zero,
        buffering: true,
        clearError: true,
      );
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    _ensureReady();
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    _ensureReady();
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _ensureReady();
    if (!volume.isFinite ||
        volume < playbackSpikeMinimumVolume ||
        volume > playbackSpikeMaximumVolume) {
      throw RangeError.value(
        volume,
        'volume',
        'Expected a finite value from 0 to 100.',
      );
    }
    await _player.setVolume(volume);
  }

  @override
  Future<void> selectSubtitleTrack(String id) async {
    _ensureReady();
    for (final caption in _currentProviderSubtitles) {
      if (id == _captionTrackId(caption)) {
        await _player.setSubtitleTrack(
          SubtitleTrack.uri(
            caption.uri.toString(),
            title: caption.label,
            language: caption.language,
          ),
        );
        _syncTrackState();
        return;
      }
    }
    SubtitleTrack? track;
    for (final SubtitleTrack candidate in _player.state.tracks.subtitle) {
      if (candidate.id == id) {
        track = candidate;
        break;
      }
    }
    if (track == null) {
      throw ArgumentError.value(id, 'id', 'Unknown subtitle track.');
    }
    await _player.setSubtitleTrack(track);
    _syncTrackState();
  }

  @override
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
  }) async {
    _ensureReady();
    final ExternalSubtitleDecision decision = externalSubtitleDecision(
      hardsubStatus,
    );
    if (decision == ExternalSubtitleDecision.blocked) {
      throw StateError(
        'External subtitles are blocked for a source confirmed with hardsub.',
      );
    }
    if (source.scheme != 'file') {
      throw ArgumentError('Only local subtitle files are supported here.');
    }
    final String path = source.path.toLowerCase();
    if (!['.srt', '.ass', '.ssa', '.vtt'].any(path.endsWith)) {
      throw ArgumentError('Subtitle file format is not supported.');
    }
    final File subtitleFile;
    try {
      subtitleFile = File.fromUri(source);
    } on Object {
      throw ArgumentError('Subtitle file URI is invalid.');
    }
    if (await FileSystemEntity.type(subtitleFile.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw StateError('Subtitle source is not a regular local file.');
    }
    await _player.setSubtitleTrack(
      SubtitleTrack.uri(source.toString(), title: title, language: language),
    );
    _syncTrackState();
    return decision;
  }

  @override
  Future<void> applySubtitleStyle(SubtitleStyle style) async {
    _ensureReady();
    final Map<String, String> properties = {
      'sub-ass-override': style.overrideAssStyles ? 'force' : 'no',
      'sub-font': style.fontFamily,
      'sub-font-size': _number(style.fontSize),
      'sub-color': style.color,
      'sub-bold': style.bold ? 'yes' : 'no',
      'sub-outline-color': style.outlineColor,
      'sub-outline-size': _number(style.outlineSize),
      'sub-pos': style.position.toString(),
    };
    for (final MapEntry<String, String> property in properties.entries) {
      await writeMpvSubtitleProperty(_player, property.key, property.value);
    }
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    _ensureReady();
    if (delay.abs() > const Duration(seconds: 30)) {
      throw RangeError('Expected subtitle delay from -30 to 30 seconds.');
    }
    final String value = (delay.inMicroseconds / Duration.microsecondsPerSecond)
        .toStringAsFixed(6);
    await writeMpvSubtitleProperty(_player, 'sub-delay', value);
  }

  @override
  Future<void> stop() async {
    _ensureReady();
    _captionRevision++;
    await _player.stop();
    _stopped = true;
    _automaticVideoSelection = false;
    _copy(
      playing: false,
      stopped: true,
      buffering: false,
      position: Duration.zero,
      audioTracks: const [],
      selectedAudioId: 'auto',
      videoTracks: const [],
      selectedVideoId: 'auto',
      subtitleTracks: const [],
      selectedSubtitleId: 'auto',
    );
  }

  @override
  Future<void> dispose() {
    final Future<void>? current = _disposeFuture;
    if (current != null) return current;
    _disposed = true;
    final Future<void> future = _disposeResources();
    _disposeFuture = future;
    unawaited(
      future.then<void>(
        (_) => _clearDisposeFuture(future),
        onError: (Object _, StackTrace _) => _clearDisposeFuture(future),
      ),
    );
    return future;
  }

  void _clearDisposeFuture(Future<void> future) {
    if (identical(_disposeFuture, future)) _disposeFuture = null;
  }

  Future<void> _disposeResources() async {
    Object? nativeFailure;
    StackTrace? nativeFailureStack;
    try {
      await _lease.release(() async {
        if (_playerDisposed) return;
        if (_playerDisposeFailure != null) {
          Error.throwWithStackTrace(
            _playerDisposeFailure!,
            _playerDisposeFailureStack!,
          );
        }
        if (_playerDisposeAttempted) {
          throw StateError(
            'Native player disposal was attempted without confirmed completion.',
          );
        }
        _playerDisposeAttempted = true;
        try {
          await _disposePlayer();
          _playerDisposed = true;
        } catch (error, stack) {
          // A partially failed media_kit dispose is not safely retryable.
          // Keep the native lease quarantined instead of risking a second
          // active libmpv instance.
          _playerDisposeFailure = error;
          _playerDisposeFailureStack = stack;
          Error.throwWithStackTrace(error, stack);
        }
      });
    } catch (error, stack) {
      nativeFailure = error;
      nativeFailureStack = stack;
    }
    _currentSource = null;
    _currentHttpHeaders = const PlaybackRequestHeaders.empty();

    Object? auxiliaryFailure;
    StackTrace? auxiliaryFailureStack;
    Future<void> attemptAuxiliaryCleanup(
      Future<void> Function() cleanup,
    ) async {
      try {
        await cleanup();
      } catch (error, stack) {
        auxiliaryFailure ??= error;
        auxiliaryFailureStack ??= stack;
      }
    }

    final StreamSubscription<String>? sourceErrors = _sourceErrorSubscription;
    if (sourceErrors != null) {
      await attemptAuxiliaryCleanup(() async {
        await sourceErrors.cancel();
        _sourceErrorSubscription = null;
      });
    }
    while (_subscriptions.isNotEmpty) {
      final StreamSubscription<Object?> subscription = _subscriptions.first;
      try {
        await subscription.cancel();
        _subscriptions.removeAt(0);
      } catch (error, stack) {
        auxiliaryFailure ??= error;
        auxiliaryFailureStack ??= stack;
        break;
      }
    }
    if (_auxiliaryCleanupForTesting
        case final Future<void> Function() cleanup) {
      await attemptAuxiliaryCleanup(cleanup);
    }
    if (!_snapshots.isClosed) {
      await attemptAuxiliaryCleanup(_snapshots.close);
    }

    if (nativeFailure != null || auxiliaryFailure != null) {
      final Object cause = nativeFailure ?? auxiliaryFailure!;
      final StackTrace? causeStack = nativeFailure != null
          ? nativeFailureStack
          : auxiliaryFailureStack;
      throw MediaKitSpikeEngineDisposeFailure(
        nativePlayerStillOwned: !_playerDisposed,
        cause: cause,
        causeStack: causeStack,
      );
    }
  }

  void _listen<T>(Stream<T> stream, void Function(T) update) {
    _subscriptions.add(
      stream.listen(
        update,
        onError: (Object _) {
          _copy(error: 'The native playback engine reported an error.');
        },
      ),
    );
  }

  void _copy({
    bool? playing,
    bool? stopped,
    bool? buffering,
    Duration? position,
    Duration? duration,
    double? volume,
    String? error,
    List<SubtitleTrackInfo>? subtitleTracks,
    String? selectedSubtitleId,
    List<AudioTrackInfo>? audioTracks,
    String? selectedAudioId,
    List<VideoTrackInfo>? videoTracks,
    String? selectedVideoId,
    bool clearError = false,
  }) {
    _state = _state.copyWith(
      playing: playing,
      stopped: stopped,
      buffering: buffering,
      position: position,
      duration: duration,
      volume: volume,
      error: error,
      subtitleTracks: subtitleTracks,
      selectedSubtitleId: selectedSubtitleId,
      audioTracks: audioTracks,
      selectedAudioId: selectedAudioId,
      videoTracks: videoTracks,
      selectedVideoId: selectedVideoId,
      sourceGeneration: _sourceGeneration,
      clearError: clearError,
    );
    _publish();
  }

  @override
  Future<void> selectAudioTrack(String id) async {
    _ensureReady();
    if (_stopped || _currentSource == null) {
      throw StateError('No active audio source.');
    }
    final AudioTrack? track = switch (id) {
      'auto' => AudioTrack.auto(),
      'no' => AudioTrack.no(),
      _ =>
        _player.state.tracks.audio
            .where(
              (AudioTrack candidate) => !candidate.uri && candidate.id == id,
            )
            .firstOrNull,
    };
    if (track == null) throw ArgumentError('Audio track is unavailable.');
    await _player.setAudioTrack(track);
    final String observed = await readMpvSubtitleProperty(_player, 'aid');
    if (observed != id) {
      throw StateError('mpv did not confirm the requested audio selection.');
    }
    _syncTrackState();
  }

  @override
  Future<void> selectVideoTrack(String id) async {
    _ensureReady();
    if (_stopped || _currentSource == null) {
      throw StateError('No active video source.');
    }
    final List<VideoTrackInfo> availableVideoTracks = _videoTrackInfo();
    final VideoTrack? track = id == 'auto'
        ? (availableVideoTracks.length > 1 ? VideoTrack.auto() : null)
        : _player.state.tracks.video
              .where((candidate) => candidate.id == id && id != 'no')
              .firstOrNull;
    if (track == null) throw ArgumentError('Video track is unavailable.');
    await _player.setVideoTrack(track);
    final String observed = await readMpvSubtitleProperty(_player, 'vid');
    if (id == 'auto') {
      final bool isAvailable = _player.state.tracks.video.any(
        (candidate) =>
            candidate.id == observed &&
            candidate.id != 'auto' &&
            candidate.id != 'no',
      );
      if (!isAvailable) {
        throw StateError('mpv did not confirm an available automatic track.');
      }
      _automaticVideoSelection = true;
    } else if (observed != id) {
      throw StateError('mpv did not confirm the requested video selection.');
    } else {
      _automaticVideoSelection = false;
    }
    _syncTrackState();
  }

  List<AudioTrackInfo> _audioTrackInfo() => List.unmodifiable([
    for (final AudioTrack track in _player.state.tracks.audio)
      if (!track.uri)
        AudioTrackInfo(
          id: track.id,
          title: track.title,
          language: track.language,
          codec: track.codec,
          channels: track.channelscount,
          sampleRate: track.samplerate,
          bitrate: track.bitrate,
          isDefault: track.isDefault,
        ),
  ]);

  List<VideoTrackInfo> _videoTrackInfo() => List.unmodifiable([
    for (final VideoTrack track in _player.state.tracks.video)
      if (track.id != 'auto' &&
          track.id != 'no' &&
          track.image != true &&
          track.albumart != true)
        VideoTrackInfo(
          id: track.id,
          title: track.title,
          codec: track.codec,
          width: track.w,
          height: track.h,
          fps: track.fps,
          bitrate: track.bitrate,
          isDefault: track.isDefault,
        ),
  ]);

  void _syncTrackState() => _copy(
    audioTracks: _audioTrackInfo(),
    selectedAudioId: _player.state.track.audio.id,
    videoTracks: _videoTrackInfo(),
    selectedVideoId: _automaticVideoSelection
        ? 'auto'
        : _player.state.track.video.id,
    subtitleTracks: _subtitleTrackInfo(),
    selectedSubtitleId: _selectedSubtitleId,
  );

  Uri? _captionSource;
  int _captionRevision = 0;
  String _captionTrackId(ProviderSubtitle caption) =>
      'provider:$_captionRevision:${caption.id}';
  List<ProviderSubtitle> get _currentProviderSubtitles =>
      _stopped ? const [] : _providerSubtitles[_captionSource] ?? const [];

  String get _selectedSubtitleId {
    final selected = _player.state.track.subtitle.id;
    for (final caption in _currentProviderSubtitles) {
      if (caption.uri.toString() == selected) return _captionTrackId(caption);
    }
    return selected;
  }

  List<SubtitleTrackInfo> _subtitleTrackInfo() {
    final SubtitleTrack selected = _player.state.track.subtitle;
    final List<SubtitleTrack> available = [..._player.state.tracks.subtitle];
    if (!available.any((SubtitleTrack track) => track.id == selected.id)) {
      available.add(selected);
    }
    return List.unmodifiable([
      for (final caption in _currentProviderSubtitles)
        SubtitleTrackInfo(
          id: _captionTrackId(caption),
          label: caption.label,
          kind: SubtitleTrackKind.external,
          language: caption.language,
          isDefault: caption.isDefault,
          isSelected: _selectedSubtitleId == _captionTrackId(caption),
        ),
      ...available
          .where(
            (track) => !_currentProviderSubtitles.any(
              (caption) => caption.uri.toString() == track.id,
            ),
          )
          .map((SubtitleTrack track) {
            final SubtitleTrackKind kind = switch (track.id) {
              'auto' => SubtitleTrackKind.automatic,
              'no' => SubtitleTrackKind.disabled,
              _ when track.uri || track.data => SubtitleTrackKind.external,
              _ => SubtitleTrackKind.embedded,
            };
            final String? title = track.title?.trim();
            final String? language = track.language?.trim();
            return SubtitleTrackInfo(
              id: track.id,
              label: title != null && title.isNotEmpty
                  ? title
                  : language != null && language.isNotEmpty
                  ? language
                  : switch (track.id) {
                      'auto' => 'Automatic subtitles',
                      'no' => 'Subtitles off',
                      _ => 'Subtitle ${track.id}',
                    },
              kind: kind,
              language: language?.isEmpty ?? true ? null : language,
              codec: track.codec,
              isDefault: track.isDefault ?? false,
              isSelected: track.id == selected.id,
            );
          }),
    ]);
  }

  String _number(num value) => value.toString();

  @visibleForTesting
  Future<String> subtitlePropertyForTesting(String property) =>
      readMpvSubtitleProperty(_player, property);

  void _publish() {
    if (!_snapshots.isClosed) _snapshots.add(_state);
  }

  static final RegExp _httpErrorCode = RegExp(
    r'\b(?:HTTP(?:/[0-9.]+)?(?: error)?|Server returned)\s+([45][0-9]{2})\b',
    caseSensitive: false,
  );

  String _safeError(String nativeMessage) {
    final String? status = _httpErrorCode.firstMatch(nativeMessage)?.group(1);
    if (status != null) _nativeHttpStatus = int.parse(status);
    return switch (_nativeHttpStatus) {
      401 || 403 =>
        'El servidor del vídeo denegó el acceso (HTTP $_nativeHttpStatus).',
      429 => 'El servidor del vídeo limitó las solicitudes (HTTP 429). Intenta más tarde.',
      final int code => 'El servidor del vídeo respondió HTTP $code.',
      null => 'The media could not be opened or decoded.',
    };
  }

  void _ensureReady() {
    _ensureNotDisposed();
    if (!_initialized) throw StateError('Engine has not been initialized.');
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('Engine is disposed.');
  }
}

/// Cleanup failed after all safe cleanup steps were attempted.
///
/// [nativePlayerStillOwned] is true only while the native-player lease remains
/// quarantined. Auxiliary stream cleanup failures do not retain that lease
/// after `Player.dispose()` has completed successfully.
final class MediaKitSpikeEngineDisposeFailure extends StateError {
  MediaKitSpikeEngineDisposeFailure({
    required this.nativePlayerStillOwned,
    required this.cause,
    this.causeStack,
  }) : super('MediaKit engine cleanup failed.');

  final bool nativePlayerStillOwned;
  final Object cause;
  final StackTrace? causeStack;
}
