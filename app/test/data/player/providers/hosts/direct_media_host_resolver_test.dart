import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final PlaybackEpisode episode = PlaybackEpisode(
    animeId: AnimeId('anime-1'),
    episodeNumber: 1,
    animeTitles: const ['Example'],
  );
  final PlaybackProviderId providerId = PlaybackProviderId('direct-test');
  final PlaybackSource source = PlaybackSource(
    id: 'example-source',
    providerId: providerId,
    episode: episode,
    language: 'unknown',
    quality: 'unknown',
    servers: [
      SourceCandidate(
        id: 'candidate',
        hostId: DirectMediaHostResolver.stableHostId,
        endpoint: Uri.https('media.example.org', '/video.mp4'),
      ),
    ],
  );

  test(
    'normalizes MP4, HLS and DASH without losing candidate metadata',
    () async {
      final DirectMediaHostResolver resolver = DirectMediaHostResolver(
        clock: () => DateTime.utc(2026, 11, 16),
      );
      final PlaybackRequestHeaders headers = PlaybackRequestHeaders({
        'Referer': 'https://source.example.org/watch/',
      });

      for (final (String path, PlaybackMediaFormat format) in [
        ('/video.mp4', PlaybackMediaFormat.mp4),
        ('/master.M3U8', PlaybackMediaFormat.hls),
        ('/manifest.mpd', PlaybackMediaFormat.dash),
      ]) {
        final SourceCandidate candidate = SourceCandidate(
          id: 'candidate-${format.name}',
          hostId: DirectMediaHostResolver.stableHostId,
          endpoint: Uri.https('media.example.org', path).replace(
            queryParameters: format == PlaybackMediaFormat.hls
                ? const {'sig': 'short-lived'}
                : null,
          ),
          expiresAt: DateTime.utc(2026, 11, 16, 0, 1),
          provenance: 'public direct media listing',
          requestHeaders: headers,
        );
        final PlaybackProviderResult<PlayableSource> result = await resolver
            .resolve(
              source,
              candidate,
              cancellation: PlaybackCancellationToken(),
            );

        expect(result, isA<PlaybackProviderSuccess<PlayableSource>>());
        final PlayableSource playable =
            (result as PlaybackProviderSuccess<PlayableSource>).value;
        expect(playable.uri, candidate.endpoint);
        expect(playable.format, format);
        expect(playable.providerId, providerId);
        expect(playable.sourceId, source.id);
        expect(playable.serverId, candidate.id);
        expect(playable.expiresAt, candidate.expiresAt);
        expect(playable.provenance, candidate.provenance);
        expect(playable.httpHeaders.values, headers.values);
        expect(playable.validatedAt, isNull);
      }
    },
  );

  test('rejects unknown formats, embeds and redirects', () async {
    final DirectMediaHostResolver resolver = DirectMediaHostResolver();
    for (final PlaybackCandidateKind kind in [
      PlaybackCandidateKind.media,
      PlaybackCandidateKind.embed,
      PlaybackCandidateKind.redirect,
    ]) {
      final SourceCandidate candidate = SourceCandidate(
        id: 'page',
        hostId: DirectMediaHostResolver.stableHostId,
        endpoint: Uri.https('media.example.org', '/watch'),
        kind: kind,
      );
      expect(resolver.supports(candidate), isFalse);
      expect(
        await resolver.resolve(
          source,
          candidate,
          cancellation: PlaybackCancellationToken(),
        ),
        isA<PlaybackProviderUnsupported<PlayableSource>>(),
      );
    }
  });

  test('refuses non-HTTPS, credentialed and local/private destinations', () {
    final DirectMediaHostResolver resolver = DirectMediaHostResolver();
    for (final Uri endpoint in [
      Uri.http('media.example.org', '/video.mp4'),
      Uri.https('user:password@media.example.org', '/video.mp4'),
      Uri.https('127.0.0.1', '/video.mp4'),
      Uri.https('127.1', '/video.mp4'),
      Uri.https('10.0.0.2', '/video.mp4'),
      Uri.https('172.16.0.4', '/video.mp4'),
      Uri.https('192.168.1.10', '/video.mp4'),
      Uri.https('[::1]', '/video.mp4'),
      Uri.https('[fd00::1]', '/video.mp4'),
      Uri.https('media.internal', '/video.mp4'),
      Uri.https('media.local', '/video.mp4'),
      Uri.https('media.example.org:8443', '/video.mp4'),
      Uri.https('media.example.org', '/video.mp4#fragment'),
    ]) {
      final SourceCandidate candidate = SourceCandidate(
        id: 'unsafe-endpoint',
        hostId: DirectMediaHostResolver.stableHostId,
        endpoint: endpoint,
      );
      expect(
        resolver.supports(candidate),
        isFalse,
        reason:
            'Endpoint must be rejected: ${endpoint.scheme}://${endpoint.host}',
      );
    }
  });

  test('accepts syntactically public HTTPS host and IP endpoints', () {
    final DirectMediaHostResolver resolver = DirectMediaHostResolver();
    for (final Uri endpoint in [
      Uri.https('media.example.org', '/video.mp4'),
      Uri.https('8.8.8.8', '/video.mp4'),
    ]) {
      expect(
        resolver.supports(
          SourceCandidate(
            id: 'public-endpoint',
            hostId: DirectMediaHostResolver.stableHostId,
            endpoint: endpoint,
          ),
        ),
        isTrue,
      );
    }
  });

  test('expired candidates and cancelled requests never normalize', () async {
    final DateTime now = DateTime.utc(2026, 11, 16);
    final DirectMediaHostResolver resolver = DirectMediaHostResolver(
      clock: () => now,
    );
    final SourceCandidate candidate = SourceCandidate(
      id: 'expired',
      hostId: DirectMediaHostResolver.stableHostId,
      endpoint: Uri.https('media.example.org', '/video.mp4'),
      expiresAt: now,
    );

    final PlaybackProviderResult<PlayableSource> expired = await resolver
        .resolve(source, candidate, cancellation: PlaybackCancellationToken());
    expect(
      expired,
      isA<PlaybackProviderFailed<PlayableSource>>().having(
        (PlaybackProviderFailed<PlayableSource> value) => value.failure.kind,
        'failure kind',
        PlaybackProviderFailureKind.expired,
      ),
    );

    final PlaybackCancellationToken cancellation = PlaybackCancellationToken()
      ..cancel();
    final PlaybackProviderResult<PlayableSource> cancelled = await resolver
        .resolve(source, candidate, cancellation: cancellation);
    expect(
      cancelled,
      isA<PlaybackProviderFailed<PlayableSource>>().having(
        (PlaybackProviderFailed<PlayableSource> value) => value.failure.kind,
        'failure kind',
        PlaybackProviderFailureKind.cancelled,
      ),
    );
  });
}
