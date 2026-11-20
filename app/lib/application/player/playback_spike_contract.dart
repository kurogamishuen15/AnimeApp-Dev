import 'package:anime_app/domain/player/audio_track_info.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_style.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_track_info.dart';
import 'package:anime_app/domain/player/video_track_info.dart';

/// Minimal F2.2 seam between playback coordination and the native adapter.
/// This is a spike contract, not the final F2.5 PlaybackEngine API.
const double playbackSpikeMinimumVolume = 0;
const double playbackSpikeMaximumVolume = 100;

abstract interface class PlaybackSpikeEngine {
  Stream<PlaybackSpikeSnapshot> get snapshots;

  Future<void> initialize();
  Future<void> open(
    Uri source, {
    int sourceGeneration = 0,
    PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(),
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> selectSubtitleTrack(String id);
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
  });
  Future<void> applySubtitleStyle(SubtitleStyle style);
  Future<void> setSubtitleDelay(Duration delay);
  Future<void> stop();
  Future<void> dispose();
}

/// Optional capability implemented by adapters that expose native audio tracks.
abstract interface class PlaybackAudioSelection {
  Future<void> selectAudioTrack(String id);
}

/// Optional native capability for sources containing multiple video tracks.
/// This does not imply HLS/DASH adaptive bitrate support.
abstract interface class PlaybackVideoSelection {
  Future<void> selectVideoTrack(String id);
}

/// Immutable observable state emitted by the engine adapter.
final class PlaybackSpikeSnapshot {
  const PlaybackSpikeSnapshot({
    this.playing = false,
    this.stopped = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100,
    this.error,
    this.sourceGeneration = 0,
    this.subtitleTracks = const [],
    this.selectedSubtitleId = 'auto',
    this.audioTracks = const [],
    this.selectedAudioId = 'auto',
    this.videoTracks = const [],
    this.selectedVideoId = 'auto',
  });

  final bool playing;

  /// True only after Stop unloaded the native media. Pause keeps this false.
  final bool stopped;
  final bool buffering;
  final Duration position;
  final Duration duration;

  /// Player-local output volume, expressed as a percentage in [0, 100].
  final double volume;
  final String? error;

  /// Origin marker assigned by the application before an open operation.
  /// Adapters carry it through their snapshots so stale events are rejected.
  final int sourceGeneration;
  final List<SubtitleTrackInfo> subtitleTracks;
  final String selectedSubtitleId;
  final List<AudioTrackInfo> audioTracks;
  final String selectedAudioId;
  final List<VideoTrackInfo> videoTracks;
  final String selectedVideoId;

  /// Copies state while preserving [error] unless a new error or explicit
  /// [clearError] is supplied. Successful recovery paths may clear the error.
  PlaybackSpikeSnapshot copyWith({
    bool? playing,
    bool? stopped,
    bool? buffering,
    Duration? position,
    Duration? duration,
    double? volume,
    String? error,
    int? sourceGeneration,
    List<SubtitleTrackInfo>? subtitleTracks,
    String? selectedSubtitleId,
    List<AudioTrackInfo>? audioTracks,
    String? selectedAudioId,
    List<VideoTrackInfo>? videoTracks,
    String? selectedVideoId,
    bool clearError = false,
  }) => PlaybackSpikeSnapshot(
    playing: playing ?? this.playing,
    stopped: stopped ?? this.stopped,
    buffering: buffering ?? this.buffering,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    volume: volume ?? this.volume,
    error: clearError ? null : error ?? this.error,
    sourceGeneration: sourceGeneration ?? this.sourceGeneration,
    subtitleTracks: subtitleTracks ?? this.subtitleTracks,
    selectedSubtitleId: selectedSubtitleId ?? this.selectedSubtitleId,
    audioTracks: audioTracks ?? this.audioTracks,
    selectedAudioId: selectedAudioId ?? this.selectedAudioId,
    videoTracks: videoTracks ?? this.videoTracks,
    selectedVideoId: selectedVideoId ?? this.selectedVideoId,
  );
}

/// Coarse state owned by the application session, separate from native
/// playback facts. Seeking is orthogonal so it can overlap Playing or Paused.
enum PlaybackSessionStatus {
  idle,
  opening,
  ready,
  buffering,
  playing,
  paused,
  completed,
  stopped,
  switchingSource,
  error,
  closing,
  disposed,
}

/// Application-visible session state. Native adapters continue to publish
/// [PlaybackSpikeSnapshot]; the coordinator adds operation/lifecycle status.
final class PlaybackSessionSnapshot {
  const PlaybackSessionSnapshot({
    this.playback = const PlaybackSpikeSnapshot(),
    this.observedPosition = Duration.zero,
    this.status = PlaybackSessionStatus.idle,
    this.seeking = false,
    this.sourceGeneration = 0,
    this.sourceUri,
  });

  final PlaybackSpikeSnapshot playback;

  /// Last position snapshot from the engine, separate from an optimistic seek.
  final Duration observedPosition;
  final PlaybackSessionStatus status;
  final bool seeking;

  /// Increments for each serialized open so consumers can reject stale work.
  final int sourceGeneration;
  final Uri? sourceUri;

  bool get playing => playback.playing;
  bool get stopped => playback.stopped;
  bool get buffering => playback.buffering;
  Duration get position => playback.position;
  Duration get duration => playback.duration;
  double get volume => playback.volume;
  String? get error => playback.error;
  List<SubtitleTrackInfo> get subtitleTracks => playback.subtitleTracks;
  String get selectedSubtitleId => playback.selectedSubtitleId;
  List<VideoTrackInfo> get videoTracks => playback.videoTracks;
  String get selectedVideoId => playback.selectedVideoId;

  PlaybackSessionSnapshot copyWith({
    PlaybackSpikeSnapshot? playback,
    Duration? observedPosition,
    PlaybackSessionStatus? status,
    bool? seeking,
    int? sourceGeneration,
    Uri? sourceUri,
    bool clearSourceUri = false,
  }) => PlaybackSessionSnapshot(
    playback: playback ?? this.playback,
    observedPosition: observedPosition ?? this.observedPosition,
    status: status ?? this.status,
    seeking: seeking ?? this.seeking,
    sourceGeneration: sourceGeneration ?? this.sourceGeneration,
    sourceUri: clearSourceUri ? null : sourceUri ?? this.sourceUri,
  );
}

enum PlaybackResumeFailureReason { durationUnknown, seekFailed }

final class PlaybackResumeFailure implements Exception {
  const PlaybackResumeFailure(this.reason);

  final PlaybackResumeFailureReason reason;
}

enum PlaybackSourceSwitchDisposition {
  changed,
  unchanged,
  targetFailedPreviousRestored,
  targetAndPreviousFailed,
}

/// Observable result of one coordinator-owned source-switch transaction.
final class PlaybackSourceSwitchResult {
  const PlaybackSourceSwitchResult({
    required this.disposition,
    required this.previousSource,
    required this.selectedSource,
    required this.referencePosition,
    required this.observedPosition,
    this.error,
  });

  final PlaybackSourceSwitchDisposition disposition;
  final Uri? previousSource;
  final Uri? selectedSource;
  final Duration referencePosition;
  final Duration? observedPosition;
  final String? error;

  bool get succeeded =>
      disposition == PlaybackSourceSwitchDisposition.changed ||
      disposition == PlaybackSourceSwitchDisposition.unchanged;

  Duration? get positionDelta {
    final Duration? observed = observedPosition;
    return observed == null ? null : observed - referencePosition;
  }
}
