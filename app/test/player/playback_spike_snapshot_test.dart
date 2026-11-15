import 'package:anime_app/application/player/playback_spike_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unrelated updates preserve errors until explicit recovery', () {
    const PlaybackSpikeSnapshot failed = PlaybackSpikeSnapshot(
      error: 'Could not open media.',
    );

    expect(
      failed.copyWith(position: const Duration(seconds: 2)).error,
      'Could not open media.',
    );
    expect(failed.copyWith(error: 'Decode failed.').error, 'Decode failed.');
    expect(failed.copyWith(clearError: true).error, isNull);
  });

  test('Stop state is distinct from Pause and survives unrelated updates', () {
    const PlaybackSpikeSnapshot stopped = PlaybackSpikeSnapshot(stopped: true);
    expect(
      stopped.copyWith(position: const Duration(seconds: 1)).stopped,
      isTrue,
    );
    expect(stopped.copyWith(stopped: false).stopped, isFalse);
    expect(const PlaybackSpikeSnapshot().stopped, isFalse);
  });

  test('session state keeps seeking orthogonal to playback status', () {
    const PlaybackSessionSnapshot playing = PlaybackSessionSnapshot(
      playback: PlaybackSpikeSnapshot(
        playing: true,
        position: Duration(seconds: 3),
      ),
      status: PlaybackSessionStatus.playing,
      sourceGeneration: 7,
    );

    final PlaybackSessionSnapshot seeking = playing.copyWith(seeking: true);
    expect(seeking.status, PlaybackSessionStatus.playing);
    expect(seeking.playing, isTrue);
    expect(seeking.position, const Duration(seconds: 3));
    expect(seeking.sourceGeneration, 7);
    expect(playing.seeking, isFalse);
  });
}
