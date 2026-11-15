import 'dart:io';

import 'package:anime_app/application/player/spike_player_coordinator.dart';
import 'package:anime_app/data/player/engine/media_kit_spike_engine.dart';
import 'package:anime_app/data/player/providers/animeav1/animeav1_playback_provider.dart';
import 'package:anime_app/data/player/providers/public_site_http.dart';
import 'package:anime_app/data/player/providers/tioanime/tioanime_playback_provider.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TioAnime searches an exact title and lists provider-confirmed episode servers', () async {
    final Dio dio = _fixtureDio({
      '/directorio': _html('''
        <article class="anime"><a href="/anime/shingeki-no-kyojin">
          <h3 class="title">Shingeki no Kyojin</h3>
        </a></article>
      '''),
      '/anime/shingeki-no-kyojin': _html('''
        <script>
          var anime_info = ["999", "shingeki-no-kyojin", "Shingeki no Kyojin"];
          var episodes = [2, 1];
        </script>
      '''),
      '/ver/shingeki-no-kyojin-1': _html('''
        <script>var videos = [["Mirror", "https://mirror.example/embed/123", 0, 0]];</script>
      '''),
    });
    addTearDown(dio.close);
    final TioAnimePlaybackProvider provider = TioAnimePlaybackProvider(
      dio: dio,
    );
    final PlaybackProviderResult<List<PlaybackSource>> result = await provider
        .findSources(_episode(1), cancellation: PlaybackCancellationToken());
    expect(result, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
    final PlaybackSource source =
        (result as PlaybackProviderSuccess<List<PlaybackSource>>).value.single;
    expect(source.episode.episodeNumber, 1);
    expect(source.servers.single.endpoint.host, 'mirror.example');
    expect(
      dio.httpClientAdapter,
      isA<_FixtureAdapter>(),
      reason: 'Provider requests remain injectable for deterministic tests.',
    );
  });

  test(
    'AnimeAV1 decodes public SvelteKit results and confirms episode number',
    () async {
      final Dio dio = _fixtureDio({
        '/catalogo/__data.json': _payload('''
        [{"results":1},[2],{"id":3,"title":4,"slug":5},"171","Shingeki no Kyojin","shingeki-no-kyojin"]
      '''),
        '/media/shingeki-no-kyojin/__data.json': _payload('''
        [{"media":1},{"episodes":2},[3],{"id":4,"number":5},2336,1]
      '''),
        '/media/shingeki-no-kyojin/1': _html(
          '<iframe src="https://player.zilla-networks.com/play/public-id"></iframe>',
        ),
      });
      addTearDown(dio.close);
      final AnimeAv1PlaybackProvider provider = AnimeAv1PlaybackProvider(
        dio: dio,
      );
      final PlaybackProviderResult<List<PlaybackSource>> result = await provider
          .findSources(_episode(1), cancellation: PlaybackCancellationToken());
      expect(result, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
      final PlaybackSource source =
          (result as PlaybackProviderSuccess<List<PlaybackSource>>)
              .value
              .single;
      expect(source.episode.episodeNumber, 1);
      expect(source.servers.single.endpoint.host, 'player.zilla-networks.com');
    },
  );

  test('public-site HTTP rejects redirects and maps access denials', () async {
    final Dio dio = _fixtureDio({
      '/redirect': (302, ''),
      '/blocked': (403, 'Access denied'),
    });
    addTearDown(dio.close);
    final PublicSiteHttp http = PublicSiteHttp(
      dio: dio,
      allowedHosts: const {'animeav1.com'},
    );
    for (final (String path, PlaybackProviderFailureKind expected) in [
      ('/redirect', PlaybackProviderFailureKind.network),
      ('/blocked', PlaybackProviderFailureKind.unauthorized),
    ]) {
      try {
        await http.getText(
          Uri.https('animeav1.com', path),
          cancellation: PlaybackCancellationToken(),
        );
        fail('Expected a typed HTTP failure for $path.');
      } on PublicSiteException catch (error) {
        expect(error.kind, expected);
      }
    }
  });

  test(
    'public target check rejects IPv4-mapped private IPv6 addresses',
    () async {
      final Dio dio = Dio();
      addTearDown(dio.close);
      final PublicSiteHttp http = PublicSiteHttp(
        dio: dio,
        allowedHosts: const {'example.com'},
      );

      expect(
        await http.isPublicHttpsTarget(
          Uri.parse('https://[::ffff:127.0.0.1]/video.mp4'),
        ),
        isFalse,
      );
      expect(
        await http.isPublicHttpsTarget(
          Uri.parse('https://[::ffff:10.0.0.1]/video.mp4'),
        ),
        isFalse,
      );
    },
  );

  test('cancellation listeners unregister and run once', () {
    final PlaybackCancellationToken token = PlaybackCancellationToken();
    var calls = 0;
    final void Function() remove = token.addCancelListener(() => calls++);
    remove();
    token.cancel();
    expect(calls, 0);
    token.addCancelListener(() => calls++);
    token.cancel();
    expect(calls, 1);
  });

  test(
    'live TioAnime search, episode, server resolution, and stream open',
    () async {
      final Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final TioAnimePlaybackProvider provider = TioAnimePlaybackProvider(
        dio: dio,
      );
      final PlaybackEpisode episode = _episode(1);
      try {
        final PlaybackProviderResult<List<PlaybackSource>> found =
            await provider.findSources(
              episode,
              cancellation: PlaybackCancellationToken(),
            );
        expect(found, isA<PlaybackProviderSuccess<List<PlaybackSource>>>());
        final PlaybackSource source =
            (found as PlaybackProviderSuccess<List<PlaybackSource>>)
                .value
                .single;
        expect(source.episode.episodeNumber, 1);
        var played = false;
        for (final PlaybackServer server in source.servers) {
          final PlaybackProviderResult<ResolvedPlaybackStream> resolved =
              await provider.resolveServer(
                source,
                server,
                cancellation: PlaybackCancellationToken(),
              );
          debugPrint(
            'live_server=${server.id} resolution=${resolved.runtimeType}',
          );
          if (resolved case PlaybackProviderSuccess<ResolvedPlaybackStream>(
            :final value,
          )) {
            final MediaKitSpikeEngine engine = MediaKitSpikeEngine(
              trustedExternalSources: {value.uri},
            );
            final SpikePlayerCoordinator coordinator = SpikePlayerCoordinator(
              engine,
              trustedExternalSources: {value.uri},
            );
            try {
              await coordinator.initialize();
              await coordinator.open(value.uri);
              await coordinator.play();
              final snapshot = await coordinator.states
                  .firstWhere(
                    (state) =>
                        state.position > Duration.zero || state.error != null,
                  )
                  .timeout(const Duration(seconds: 12));
              debugPrint(
                'live_player position_ms=${snapshot.position.inMilliseconds} '
                'has_error=${snapshot.error != null}',
              );
              if (snapshot.position > Duration.zero) {
                played = true;
                break;
              }
            } on Object catch (error) {
              debugPrint('live_player_open_failed=${error.runtimeType}');
            } finally {
              await coordinator.dispose();
            }
          }
        }
        expect(
          played,
          isTrue,
          reason: 'No listed server produced playback through libmpv.',
        );
      } finally {
        dio.close(force: true);
      }
    },
    skip: Platform.environment['KONGROO_LIVE_PROVIDER_SMOKE'] != '1',
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

PlaybackEpisode _episode(int number) => PlaybackEpisode(
  animeId: AnimeId('playback-anilist-16498'),
  episodeNumber: number,
  externalAnimeId: ExternalAnimeId(
    providerId: MetadataProviderId('anilist'),
    value: '16498',
  ),
  animeTitles: const ['Shingeki no Kyojin'],
);

Dio _fixtureDio(Map<String, (int, String)> responses) =>
    Dio()..httpClientAdapter = _FixtureAdapter(responses);

(int, String) _html(String body) => (200, body);
(int, String) _payload(String data) =>
    (200, '{"nodes":[null,{"type":"data","data":$data}]}');

final class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.responses);
  final Map<String, (int, String)> responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (int status, String body) =
        responses[options.uri.path] ?? (404, 'not found');
    return ResponseBody.fromString(body, status);
  }

  @override
  void close({bool force = false}) {}
}
