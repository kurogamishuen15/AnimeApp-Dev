import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:anime_app/domain/player/subtitles/subtitle_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('external subtitle hardsub policy', () {
    test('blocks only sources confirmed to contain hardsub', () {
      expect(
        externalSubtitleDecision(HardsubStatus.confirmedPresent),
        ExternalSubtitleDecision.blocked,
      );
      expect(
        externalSubtitleDecision(HardsubStatus.confirmedAbsent),
        ExternalSubtitleDecision.allowed,
      );
      expect(
        externalSubtitleDecision(HardsubStatus.unknown),
        ExternalSubtitleDecision.allowedWithUncertainty,
      );
    });
  });

  group('subtitle style validation', () {
    test('accepts mpv hex colors and bounded presentation values', () {
      final SubtitleStyle style = SubtitleStyle(
        fontFamily: 'Noto Sans',
        fontSize: 42,
        color: '#F2F2F2',
        outlineColor: '#CC000000',
        outlineSize: 2,
        bold: true,
        position: 92,
        overrideAssStyles: true,
      );

      expect(style.fontFamily, 'Noto Sans');
      expect(style.position, 92);
      expect(style.overrideAssStyles, isTrue);
    });

    test('rejects invalid font, colors and ranges', () {
      expect(() => SubtitleStyle(fontFamily: ' '), throwsArgumentError);
      expect(() => SubtitleStyle(color: 'white'), throwsArgumentError);
      expect(() => SubtitleStyle(fontSize: 100), throwsRangeError);
      expect(() => SubtitleStyle(outlineSize: double.nan), throwsRangeError);
      expect(() => SubtitleStyle(position: 101), throwsRangeError);
    });
  });
}
