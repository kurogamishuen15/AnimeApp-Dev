import 'dart:io';

import 'package:media_kit/media_kit.dart';

import '../../../application/player/diagnostics/playback_performance.dart';

/// Reads a bounded set of native properties once per requested sample.
/// `NativePlayer.getProperty` returns an empty string for unavailable mpv
/// properties. This reader never changes playback configuration.
Future<PlaybackPerformanceSample> readMpvPerformance(
  Player player, {
  double? positionEventsPerSecond,
}) async {
  final PlatformPlayer? platform = player.platform;
  if (platform is! NativePlayer) {
    return PlaybackPerformanceSample(collectedAt: DateTime.now());
  }

  Future<String?> read(String name) async {
    try {
      final String value = (await platform.getProperty(name)).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      // A property may be unavailable during open/stop/dispose. Keep the
      // remaining independent metrics rather than failing the entire sample.
      return null;
    }
  }

  final String? nominalFps = await read('container-fps');
  final String? decodedFps = await read('estimated-vf-fps');
  final String? framesDropped = await read('frame-drop-count');
  final String? decoderFramesDropped = await read('decoder-frame-drop-count');
  final String? avSync = await read('avsync');
  final String? totalAvSyncChange = await read('total-avsync-change');
  final String? cache = await read('demuxer-cache-duration');
  final String? hwdec = await read('hwdec-current');
  final String? videoCodec = await read('video-codec');
  final String? audioCodec = await read('audio-codec');
  final String? vo = await read('current-vo');
  final String? ao = await read('current-ao');
  final String? videoBitrate = await read('video-bitrate');
  final String? audioBitrate = await read('audio-bitrate');
  final videoParams = player.state.videoParams;
  final audioParams = player.state.audioParams;
  return PlaybackPerformanceSample(
    collectedAt: DateTime.now(),
    nominalFps: double.tryParse(nominalFps ?? ''),
    decodedFps: double.tryParse(decodedFps ?? ''),
    positionEventsPerSecond: positionEventsPerSecond,
    framesDropped: int.tryParse(framesDropped ?? ''),
    decoderFramesDropped: int.tryParse(decoderFramesDropped ?? ''),
    avSyncSeconds: double.tryParse(avSync ?? ''),
    totalAvSyncChangeSeconds: double.tryParse(totalAvSyncChange ?? ''),
    cacheSeconds: double.tryParse(cache ?? ''),
    hardwareDecoder: hwdec,
    videoCodec: videoCodec,
    audioCodec: audioCodec,
    videoOutput: vo,
    audioOutput: ao,
    videoWidth: videoParams.w,
    videoHeight: videoParams.h,
    pixelFormat: videoParams.pixelformat,
    audioChannels: audioParams.hrChannels ?? audioParams.channels,
    audioSampleRate: audioParams.sampleRate,
    videoBitrate: double.tryParse(videoBitrate ?? ''),
    audioBitrate: double.tryParse(audioBitrate ?? ''),
    rssBytes: ProcessInfo.currentRss,
  );
}
