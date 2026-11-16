import 'package:dio/dio.dart';

import '../../../application/player/providers/playback_provider_manager.dart';
import 'animeheaven/animeheaven_mp4_resolver.dart';
import 'animeheaven/animeheaven_playback_provider.dart';

/// Composition root for playback discovery and host resolution.
///
/// Owns the concrete provider transport and registers public episode discovery
/// separately from host validation. The app continues using its existing
/// manager, source-switch service, and media_kit player.
final class PlaybackProvidersModule {
  PlaybackProvidersModule._(this.manager, this._client);

  factory PlaybackProvidersModule.open({
    DateTime Function()? clock,
    Dio? httpClient,
  }) {
    final Dio client =
        httpClient ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
            maxRedirects: 0,
          ),
        );
    final AnimeHeavenPlaybackProvider animeHeaven = AnimeHeavenPlaybackProvider(
      client: client,
    );
    final AnimeHeavenMp4Resolver animeHeavenMp4Resolver =
        AnimeHeavenMp4Resolver(client: client);
    return PlaybackProvidersModule._(
      PlaybackProviderManager(
        providers: <PlaybackProviderRegistration>[
          PlaybackProviderRegistration(provider: animeHeaven, priority: 50),
        ],
        videoHostResolvers: <PlaybackVideoHostResolverRegistration>[
          PlaybackVideoHostResolverRegistration(
            resolver: animeHeavenMp4Resolver,
            priority: 50,
          ),
        ],
        clock: clock ?? DateTime.now,
      ),
      client,
    );
  }

  final PlaybackProviderManager manager;
  final Dio _client;
  bool _closed = false;

  /// Releases the owned HTTP transport. The manager does not own the player.
  void close() {
    if (_closed) return;
    _closed = true;
    _client.close(force: true);
  }
}
