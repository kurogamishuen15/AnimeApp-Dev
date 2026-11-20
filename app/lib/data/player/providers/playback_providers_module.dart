import 'package:dio/dio.dart';

import '../../../application/player/providers/playback_provider_manager.dart';
import 'allanime/allanime_playback_provider.dart';
import 'animeav1/animeav1_playback_provider.dart';
import 'animegg/animegg_playback_provider.dart';
import 'anizone/anizone_playback_provider.dart';
import 'hosts/direct_media_host_resolver.dart';
import 'hosts/voe_video_host_resolver.dart';
import 'megaplay/megaplay_playback_provider.dart';
import 'miruro/miruro_catalog_api.dart';
import 'miruro/miruro_catalog_playback_provider.dart';
import 'public_playback_http.dart';
import 'registry/provider_spec.dart';
import 'user_sources/user_defined_playback_provider.dart';
import 'wikimedia/wikimedia_anime_provider.dart';
import 'jkanime/jkanime_playback_provider.dart';

/// Composition root for anime discovery and shared direct-media resolution.
///
/// MegaPlay and Miruro provide automatic episode discovery. Wikimedia is an explicit
/// regression provider for a known public-domain title; user-defined sources
/// are optional. The module registers one generic direct-media resolver and
/// never creates or owns the playback engine.
final class PlaybackProvidersModule {
  PlaybackProvidersModule._(this.manager, this._publicClient);

  factory PlaybackProvidersModule.open({
    DateTime Function()? clock,
    bool enableMiruro = true,
    bool enableMegaPlay = true,
    bool enableAnimeAv1 = true,
    bool enableAllAnime = true,
    bool enableAniZone = true,
    bool enableAnimeGg = true,
    bool enableWikimedia = false,
    bool enableJkanime = true,
    Iterable<UserDefinedSourceEntry> userSources = const [],
  }) {
    final List<PlaybackProviderRegistration> providers =
        <PlaybackProviderRegistration>[];
        if (enableJkanime) {
      final JKAnimePlaybackProvider jkanime = JKAnimePlaybackProvider();
      providers.add(
        PlaybackProviderRegistration(
          provider: jkanime,
          priority: 70,
          cacheTtl: Duration.zero,
          version: jkanime.adapterVersion,
        ),
      );
    }

final List<UserDefinedSourceEntry> userEntries = userSources.toList();
    final Dio? publicClient =
        enableMiruro ||
            enableMegaPlay ||
            enableWikimedia ||
            enableAnimeAv1 ||
            enableAllAnime ||
            enableAniZone ||
            enableAnimeGg
        ? Dio()
        : null;
    final megaPlayHttp = enableMegaPlay
        ? PublicPlaybackHttp(publicClient!, {
            MegaPlayPlaybackProvider.defaultOrigin.host,
          })
        : null;
    if (enableMegaPlay) {
      final MegaPlayPlaybackProvider megaPlay = MegaPlayPlaybackProvider(
        publicClient!,
        transport: megaPlayHttp,
      );
      providers.add(
        PlaybackProviderRegistration(
          provider: megaPlay,
          priority: 110,
          cacheTtl: Duration.zero,
          version: megaPlay.adapterVersion,
        ),
      );
    }
    if (enableMegaPlay) {
      final dubbed = MegaPlayPlaybackProvider(
        publicClient!,
        variant: MegaPlayAudioVariant.dub,
        transport: megaPlayHttp,
      );
      providers.add(
        PlaybackProviderRegistration(
          provider: dubbed,
          priority: 105,
          cacheTtl: Duration.zero,
          version: dubbed.adapterVersion,
        ),
      );
    }
    if (enableMiruro) {
      final PublicPlaybackHttp transport = PublicPlaybackHttp(
        publicClient!,
        miruroCatalogOrigins.toSet(),
        enforceCooldown: false,
        maxConcurrent: 2,
      );
      final MiruroCatalogPlaybackProvider miruro =
          MiruroCatalogPlaybackProvider(MiruroCatalogApi(transport));
      providers.add(
        PlaybackProviderRegistration(
          provider: miruro,
          priority: 100,
          cacheTtl: Duration.zero,
          version: miruro.adapterVersion,
        ),
      );
    }
    if (enableAnimeAv1) {
      final animeAv1 = AnimeAv1PlaybackProvider(publicClient!);
      providers.add(
        PlaybackProviderRegistration(
          provider: animeAv1,
          priority: 95,
          cacheTtl: Duration.zero,
          version: animeAv1.adapterVersion,
        ),
      );
    }
    if (enableAllAnime) {
      final allAnimeHttp = PublicPlaybackHttp(publicClient!, {
        'api.mkissa.net',
        'allanime.day',
      });
      for (final entry in const [
        (AllAnimeAudioVariant.sub, 92),
        (AllAnimeAudioVariant.dub, 91),
      ]) {
        final allAnime = AllAnimePlaybackProvider(
          publicClient,
          variant: entry.$1,
          transport: allAnimeHttp,
        );
        providers.add(
          PlaybackProviderRegistration(
            provider: allAnime,
            priority: entry.$2,
            cacheTtl: Duration.zero,
            version: allAnime.adapterVersion,
          ),
        );
      }
    }
    if (enableAniZone) {
      final anizone = AniZonePlaybackProvider(publicClient!);
      providers.add(
        PlaybackProviderRegistration(
          provider: anizone,
          priority: 86,
          cacheTtl: Duration.zero,
          version: anizone.adapterVersion,
        ),
      );
    }
    if (enableAnimeGg) {
      for (final entry in const [
        (AnimeGgAudioVariant.sub, 84),
        (AnimeGgAudioVariant.dub, 83),
      ]) {
        final animeGg = AnimeGgPlaybackProvider(
          publicClient!,
          variant: entry.$1,
        );
        providers.add(
          PlaybackProviderRegistration(
            provider: animeGg,
            priority: entry.$2,
            cacheTtl: Duration.zero,
            version: animeGg.adapterVersion,
          ),
        );
      }
    }
    if (enableWikimedia) {
      final WikimediaAnimeProvider wikimedia = WikimediaAnimeProvider(
        publicClient!,
      );
      providers.add(
        PlaybackProviderRegistration(
          provider: wikimedia,
          priority: 90,
          cacheTtl: const Duration(minutes: 5),
          version: wikimedia.adapterVersion,
        ),
      );
    }
    if (userEntries.isNotEmpty) {
      final UserDefinedPlaybackProvider user = UserDefinedPlaybackProvider(
        userEntries,
      );
      providers.add(
        PlaybackProviderRegistration(
          provider: user,
          priority: 50,
          cacheTtl: Duration.zero,
          version: UserDefinedPlaybackProvider.adapterVersion,
        ),
      );
    }

    return PlaybackProvidersModule._(
      PlaybackProviderManager(
        providers: providers,
        videoHostResolvers: <PlaybackVideoHostResolverRegistration>[
          if (enableAnimeAv1)
            PlaybackVideoHostResolverRegistration(
              resolver: VoeVideoHostResolver(publicClient!),
              version: '1.0.0',
            ),
          PlaybackVideoHostResolverRegistration(
            resolver: DirectMediaHostResolver(clock: clock),
            version: '1.0.0',
          ),
        ],
        clock: clock ?? DateTime.now,
      ),
      publicClient,
    );
  }

  final PlaybackProviderManager manager;
  final Dio? _publicClient;
  bool _closed = false;

  /// Idempotent lifecycle hook retained by the app composition root.
  void close() {
    if (_closed) return;
    _closed = true;
    _publicClient?.close(force: true);
  }
}
