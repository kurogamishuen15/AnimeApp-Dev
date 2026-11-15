import 'package:anime_app/domain/player/video_track_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'quality labels use reported dimensions and never invent resolution',
    () {
      expect(
        const VideoTrackInfo(id: 'a', width: 640, height: 360).label,
        '360p · 640×360',
      );
      expect(
        const VideoTrackInfo(id: 'b', width: 3840, height: 2160).label,
        '4K · 3840×2160',
      );
      expect(
        const VideoTrackInfo(id: 'c', width: 534, height: 300).label,
        '534×300',
      );
      expect(
        const VideoTrackInfo(id: 'd', codec: 'h264').label,
        'Resolución no informada · h264',
      );
    },
  );

  test('reported bitrate is included only when positive', () {
    expect(
      const VideoTrackInfo(
        id: 'a',
        width: 1280,
        height: 720,
        bitrate: 2500000,
      ).label,
      '720p · 1280×720 · 2.5 Mbps',
    );
    expect(
      const VideoTrackInfo(id: 'b', width: 640, height: 360, bitrate: 0).label,
      '360p · 640×360',
    );
  });
}
