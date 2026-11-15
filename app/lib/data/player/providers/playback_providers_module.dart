import 'package:dio/dio.dart';

import '../../../application/player/providers/playback_provider_manager.dart';
import 'animeav1/animeav1_playback_provider.dart';
import 'tioanime/tioanime_playback_provider.dart';

/// Composition root for the real public-page playback adapters.
///
/// AnimeOnline Ninja is intentionally not registered while its public site
/// returns HTTP 403; no challenge route is inferred or bypassed.
final class PlaybackProvidersModule {
  PlaybackProvidersModule._({required this.http, required this.manager});

  factory PlaybackProvidersModule.open({DateTime Function()? clock}) {
    final Dio http = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 8),
      ),
    );
    return PlaybackProvidersModule._(
      http: http,
      manager: PlaybackProviderManager(
        providers: [
          PlaybackProviderRegistration(
            provider: AnimeAv1PlaybackProvider(dio: http),
            priority: 30,
          ),
          PlaybackProviderRegistration(
            provider: TioAnimePlaybackProvider(dio: http),
            priority: 20,
          ),
        ],
        clock: clock ?? DateTime.now,
      ),
    );
  }

  final Dio http;
  final PlaybackProviderManager manager;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    http.close(force: true);
  }
}
