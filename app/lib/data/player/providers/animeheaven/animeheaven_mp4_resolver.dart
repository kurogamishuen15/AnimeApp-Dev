import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import 'animeheaven_html_parser.dart';
import 'animeheaven_http.dart';

/// Validates the provider's public progressive MP4 mirrors without owning the
/// player. Signed URLs are used in memory only and are fetched for each request.
final class AnimeHeavenMp4Resolver implements PlaybackVideoHostResolver {
  AnimeHeavenMp4Resolver({required Dio client})
    : _http = AnimeHeavenHttp(client);

  final AnimeHeavenHttp _http;

  @override
  String get resolverId => 'animeheaven-mp4';

  @override
  bool supports(PlaybackServer server) =>
      AnimeHeavenHtmlParser.isAllowedMp4(server.endpoint);

  @override
  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve(
    PlaybackSource source,
    PlaybackServer server, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) return _cancelled();
    final Uri uri = server.endpoint;
    if (!supports(server) || source.providerId.value != 'animeheaven') {
      return const PlaybackProviderUnsupported(
        PlaybackProviderCapability.resolveServer,
      );
    }

    try {
      final AnimeHeavenHttpResponse probe = await _http.getPrefix(
        uri,
        headers: const <String, String>{
          'Accept': 'video/mp4,application/octet-stream;q=0.9,*/*;q=0.5',
          'Range': 'bytes=0-31',
        },
        cancellation: cancellation,
        prefixBytes: 12,
      );
      final PlaybackProviderFailure? statusFailure =
          animeHeavenHttpFailureForStatus(probe.statusCode);
      if (statusFailure != null) {
        return PlaybackProviderFailed<ResolvedPlaybackStream>(statusFailure);
      }
      if (probe.statusCode != 200 && probe.statusCode != 206) {
        return _failed(PlaybackProviderFailureKind.invalidResponse);
      }
      final String? contentType = probe.contentType?.split(';').first.trim();
      if (contentType?.toLowerCase() != 'video/mp4' ||
          !_hasMp4Ftyp(probe.body)) {
        return _failed(PlaybackProviderFailureKind.invalidResponse);
      }

      // The current CDN sometimes reports a full-object Content-Range for a
      // short Range request. We validate the actual prefix and MIME instead
      // of trusting that header; libmpv must still prove full playback.
      return PlaybackProviderSuccess<ResolvedPlaybackStream>(
        ResolvedPlaybackStream(
          providerId: source.providerId,
          sourceId: source.id,
          serverId: server.id,
          uri: uri,
        ),
      );
    } on AnimeHeavenHttpFailure catch (error) {
      return _failed(error.kind);
    } on DioException catch (error) {
      if (cancellation.isCancelled || error.type == DioExceptionType.cancel) {
        return _cancelled();
      }
      return _failed(
        error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout
            ? PlaybackProviderFailureKind.timeout
            : PlaybackProviderFailureKind.network,
      );
    } on Object {
      return cancellation.isCancelled
          ? _cancelled()
          : _failed(PlaybackProviderFailureKind.invalidResponse);
    }
  }

  static bool _hasMp4Ftyp(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70;

  PlaybackProviderResult<ResolvedPlaybackStream> _cancelled() =>
      const PlaybackProviderFailed<ResolvedPlaybackStream>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );

  PlaybackProviderResult<ResolvedPlaybackStream> _failed(
    PlaybackProviderFailureKind kind,
  ) => PlaybackProviderFailed<ResolvedPlaybackStream>(
    PlaybackProviderFailure(kind),
  );
}
