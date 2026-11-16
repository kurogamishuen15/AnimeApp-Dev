import 'player_video_display.dart';

/// Presentation options resolved by the player composition root.
///
/// The page receives these values as data and does not read process
/// environment or other operating-system APIs.
final class SpikePlayerPageOptions {
  const SpikePlayerPageOptions({
    this.showNerdPanel = false,
    this.performanceDiagnosticsEnabled = false,
    this.initialFit,
    this.initialAspect,
  });

  factory SpikePlayerPageOptions.fromEnvironment(
    Map<String, String> environment,
  ) {
    return SpikePlayerPageOptions(
      showNerdPanel: environment['KONGROO_DEMO_SHOW_NERD'] == '1',
      performanceDiagnosticsEnabled:
          environment['KONGROO_PERF_DIAGNOSTIC'] == '1',
      initialFit: switch (environment['KONGROO_DEMO_FIT']) {
        'cover' => PlayerVideoFit.cover,
        'fill' => PlayerVideoFit.fill,
        'original' => PlayerVideoFit.originalSize,
        _ => null,
      },
      initialAspect: switch (environment['KONGROO_DEMO_ASPECT']) {
        '16:9' => PlayerVideoAspect.widescreen,
        '4:3' => PlayerVideoAspect.classic,
        '21:9' => PlayerVideoAspect.cinema,
        _ => null,
      },
    );
  }

  final bool showNerdPanel;
  final bool performanceDiagnosticsEnabled;
  final PlayerVideoFit? initialFit;
  final PlayerVideoAspect? initialAspect;

  @override
  bool operator ==(Object other) =>
      other is SpikePlayerPageOptions &&
      showNerdPanel == other.showNerdPanel &&
      performanceDiagnosticsEnabled == other.performanceDiagnosticsEnabled &&
      initialFit == other.initialFit &&
      initialAspect == other.initialAspect;

  @override
  int get hashCode => Object.hash(
    showNerdPanel,
    performanceDiagnosticsEnabled,
    initialFit,
    initialAspect,
  );
}
