import '../../../application/player/providers/playback_provider_manager.dart';
import 'animesdigital/animesdigital_playback_provider.dart';
import 'hosts/direct_media_host_resolver.dart';

/// Composition root for playback discovery and host resolution.
///
/// Registers AnimesDigital as a candidate, not a verified source. The only
/// built-in resolver wraps explicit direct-media candidates; it does not
/// validate network availability or own the playback engine.
final class PlaybackProvidersModule {
  PlaybackProvidersModule._(this.manager, this._ownedAdapters);

  factory PlaybackProvidersModule.open({DateTime Function()? clock}) {
    final AnimesDigitalPlaybackProvider animesDigital =
        AnimesDigitalPlaybackProvider();
    return PlaybackProvidersModule._(
      PlaybackProviderManager(
        providers: <PlaybackProviderRegistration>[
          PlaybackProviderRegistration(
            provider: animesDigital,
            priority: 100,
            cacheTtl: Duration.zero,
            version: animesDigital.adapterVersion,
          ),
        ],
        videoHostResolvers: <PlaybackVideoHostResolverRegistration>[
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(),
            version: '1.0.0',
          ),
        ],
        clock: clock ?? DateTime.now,
      ),
      <AnimesDigitalPlaybackProvider>[animesDigital],
    );
  }

  final PlaybackProviderManager manager;
  final List<AnimesDigitalPlaybackProvider> _ownedAdapters;
  bool _closed = false;

  /// Idempotent lifecycle hook retained for the application composition root.
  /// Registered adapters own and close their own injected transports.
  void close() {
    if (_closed) return;
    _closed = true;
    for (final AnimesDigitalPlaybackProvider adapter in _ownedAdapters) {
      adapter.close();
    }
  }
}
