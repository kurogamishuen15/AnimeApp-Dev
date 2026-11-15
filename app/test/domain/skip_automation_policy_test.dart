import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/player/skips/skip_automation_policy.dart';
import 'package:anime_app/domain/player/skips/skip_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final PlaybackEpisode episode = PlaybackEpisode(
    animeId: AnimeId('skip-policy-test'),
    episodeNumber: 2,
  );
  const Duration duration = Duration(minutes: 24);
  const SkipAutomationPolicy policy = SkipAutomationPolicy();

  SkipSegment segment(
    SkipSegmentKind kind, {
    SkipSegmentSource source = SkipSegmentSource.aniskip,
  }) => SkipSegment(
    episode: episode,
    kind: kind,
    start: const Duration(seconds: 1),
    end: const Duration(seconds: 20),
    source: source,
    sourceId: 'fixture-segment',
  );

  test('manual prompts are on and every automatic option defaults off', () {
    const SkipAutomationSettings settings = SkipAutomationSettings();
    expect(settings.showManualPrompts, isTrue);
    expect(settings.opening, isFalse);
    expect(settings.ending, isFalse);
    expect(settings.recap, isFalse);
    expect(settings.filler, isFalse);
    expect(
      policy.allows(
        settings: settings,
        segment: segment(SkipSegmentKind.opening),
        episode: episode,
        duration: duration,
      ),
      isFalse,
    );
  });

  test(
    'opening and ending use independent switches and require valid ranges',
    () {
      expect(
        policy.allows(
          settings: const SkipAutomationSettings(opening: true),
          segment: segment(SkipSegmentKind.opening),
          episode: episode,
          duration: duration,
        ),
        isTrue,
      );
      expect(
        policy.allows(
          settings: const SkipAutomationSettings(opening: true),
          segment: segment(SkipSegmentKind.ending),
          episode: episode,
          duration: duration,
        ),
        isFalse,
      );
      expect(
        policy.allows(
          settings: const SkipAutomationSettings(ending: true),
          segment: segment(SkipSegmentKind.ending),
          episode: episode,
          duration: const Duration(seconds: 10),
        ),
        isFalse,
      );
    },
  );

  test('recap and filler need curated, episode-scoped evidence', () {
    expect(
      policy.allows(
        settings: const SkipAutomationSettings(recap: true),
        segment: segment(SkipSegmentKind.recap),
        episode: episode,
        duration: duration,
      ),
      isFalse,
    );
    expect(
      policy.allows(
        settings: const SkipAutomationSettings(recap: true),
        segment: segment(
          SkipSegmentKind.recap,
          source: SkipSegmentSource.curated,
        ),
        episode: episode,
        duration: duration,
      ),
      isTrue,
    );
    final EpisodeFillerEvidence verifiedFiller = EpisodeFillerEvidence(
      episode: episode,
      classification: FillerClassification.filler,
      sourceId: 'curated-arc-list',
      verified: true,
    );
    expect(
      policy.allows(
        settings: const SkipAutomationSettings(filler: true),
        segment: segment(
          SkipSegmentKind.filler,
          source: SkipSegmentSource.curated,
        ),
        episode: episode,
        duration: duration,
        fillerEvidence: verifiedFiller,
      ),
      isTrue,
    );
    expect(
      policy.allows(
        settings: const SkipAutomationSettings(filler: true),
        segment: segment(
          SkipSegmentKind.filler,
          source: SkipSegmentSource.curated,
        ),
        episode: episode,
        duration: duration,
        fillerEvidence: EpisodeFillerEvidence(
          episode: PlaybackEpisode(animeId: episode.animeId, episodeNumber: 3),
          classification: FillerClassification.filler,
          sourceId: 'wrong-episode',
          verified: true,
        ),
      ),
      isFalse,
    );
  });
}
