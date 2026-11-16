import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../domain/player/providers/playback_provider_contract.dart';

/// A low-memory, cancellation-aware HTTP client for this provider module.
///
/// Redirects are deliberately disabled. HTML is capped, while media probes
/// retain only a short prefix and cancel the response body immediately.
final class AnimeHeavenHttp {
  AnimeHeavenHttp(this._dio);

  static const int maxHtmlBytes = 1024 * 1024;
  static const int maxProbeBytes = 64 * 1024;

  final Dio _dio;

  Future<AnimeHeavenHttpResponse> getHtml(
    Uri uri, {
    required Map<String, String> headers,
    required PlaybackCancellationToken cancellation,
  }) async {
    final AnimeHeavenHttpResponse response = await _get(
      uri,
      headers: headers,
      cancellation: cancellation,
      maxBytes: maxHtmlBytes,
    );
    return response;
  }

  Future<AnimeHeavenHttpResponse> getPrefix(
    Uri uri, {
    required Map<String, String> headers,
    required PlaybackCancellationToken cancellation,
    required int prefixBytes,
  }) async {
    if (prefixBytes < 1 || prefixBytes > maxProbeBytes) {
      throw ArgumentError.value(prefixBytes, 'prefixBytes');
    }
    return _get(
      uri,
      headers: headers,
      cancellation: cancellation,
      maxBytes: maxProbeBytes,
      prefixBytes: prefixBytes,
    );
  }

  Future<AnimeHeavenHttpResponse> _get(
    Uri uri, {
    required Map<String, String> headers,
    required PlaybackCancellationToken cancellation,
    required int maxBytes,
    int? prefixBytes,
  }) async {
    if (cancellation.isCancelled) {
      throw const AnimeHeavenHttpFailure(PlaybackProviderFailureKind.cancelled);
    }
    final CancelToken dioCancellation = CancelToken();
    final void Function() unregister = cancellation.addCancelListener(() {
      if (!dioCancellation.isCancelled) {
        dioCancellation.cancel('Playback request cancelled.');
      }
    });
    try {
      final Response<ResponseBody> response = await _dio.getUri<ResponseBody>(
        uri,
        cancelToken: dioCancellation,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          maxRedirects: 0,
          validateStatus: (int? status) => status != null,
          headers: headers,
        ),
      );
      final ResponseBody? body = response.data;
      final int status = response.statusCode ?? 0;
      if (body == null || status == 0) {
        await _cancelResponseBody(body?.stream);
        throw const AnimeHeavenHttpFailure(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }

      final StreamIterator<List<int>> iterator = StreamIterator<List<int>>(
        body.stream,
      );
      final BytesBuilder bytes = BytesBuilder(copy: false);
      try {
        if (status < 200 || status >= 300) {
          return AnimeHeavenHttpResponse(
            statusCode: status,
            headers: response.headers,
            body: Uint8List(0),
          );
        }
        while (await _moveNextOrCancel(iterator, cancellation)) {
          if (cancellation.isCancelled) {
            throw const AnimeHeavenHttpFailure(
              PlaybackProviderFailureKind.cancelled,
            );
          }
          final List<int> chunk = iterator.current;
          final int remaining = maxBytes - bytes.length;
          if (remaining <= 0 && chunk.isNotEmpty) {
            throw const AnimeHeavenHttpFailure(
              PlaybackProviderFailureKind.invalidResponse,
            );
          }
          final int takeCount = prefixBytes == null
              ? chunk.length
              : (prefixBytes - bytes.length).clamp(0, chunk.length).toInt();
          if (takeCount > remaining) {
            throw const AnimeHeavenHttpFailure(
              PlaybackProviderFailureKind.invalidResponse,
            );
          }
          if (takeCount > 0) bytes.add(chunk.take(takeCount).toList());
          if (prefixBytes != null && bytes.length >= prefixBytes) break;
        }
      } finally {
        await iterator.cancel();
      }
      if (cancellation.isCancelled) {
        throw const AnimeHeavenHttpFailure(
          PlaybackProviderFailureKind.cancelled,
        );
      }
      return AnimeHeavenHttpResponse(
        statusCode: status,
        headers: response.headers,
        body: bytes.takeBytes(),
      );
    } on AnimeHeavenHttpFailure {
      rethrow;
    } on DioException catch (error) {
      throw _translateDioError(error, cancellation);
    } on Object {
      if (cancellation.isCancelled) {
        throw const AnimeHeavenHttpFailure(
          PlaybackProviderFailureKind.cancelled,
        );
      }
      rethrow;
    } finally {
      unregister();
    }
  }

  Future<void> _cancelResponseBody(Stream<List<int>>? stream) async {
    if (stream == null) return;
    final StreamIterator<List<int>> iterator = StreamIterator<List<int>>(
      stream,
    );
    await iterator.cancel();
  }

  Future<bool> _moveNextOrCancel(
    StreamIterator<List<int>> iterator,
    PlaybackCancellationToken cancellation,
  ) {
    if (cancellation.isCancelled) {
      throw const AnimeHeavenHttpFailure(PlaybackProviderFailureKind.cancelled);
    }
    final Completer<bool> result = Completer<bool>();
    final void Function() unregister = cancellation.addCancelListener(() {
      if (!result.isCompleted) {
        result.completeError(
          const AnimeHeavenHttpFailure(PlaybackProviderFailureKind.cancelled),
        );
      }
    });
    try {
      iterator.moveNext().then(
        (bool hasNext) {
          unregister();
          if (!result.isCompleted) result.complete(hasNext);
        },
        onError: (Object error, StackTrace stackTrace) {
          unregister();
          if (!result.isCompleted) result.completeError(error, stackTrace);
        },
      );
    } on Object catch (error, stackTrace) {
      unregister();
      result.completeError(error, stackTrace);
    }
    return result.future;
  }

  AnimeHeavenHttpFailure _translateDioError(
    DioException error,
    PlaybackCancellationToken cancellation,
  ) {
    if (cancellation.isCancelled || error.type == DioExceptionType.cancel) {
      return const AnimeHeavenHttpFailure(
        PlaybackProviderFailureKind.cancelled,
      );
    }
    return AnimeHeavenHttpFailure(switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => PlaybackProviderFailureKind.timeout,
      DioExceptionType.badCertificate => PlaybackProviderFailureKind.network,
      _ => PlaybackProviderFailureKind.network,
    });
  }
}

final class AnimeHeavenHttpResponse {
  const AnimeHeavenHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Headers headers;
  final Uint8List body;

  String get text => utf8.decode(body, allowMalformed: true);
  String? get contentType => headers.value(Headers.contentTypeHeader);
  String? get contentRange => headers.value('content-range');
}

final class AnimeHeavenHttpFailure implements Exception {
  const AnimeHeavenHttpFailure(this.kind);

  final PlaybackProviderFailureKind kind;
}

PlaybackProviderFailure? animeHeavenHttpFailureForStatus(int statusCode) {
  if (statusCode >= 200 && statusCode < 300) return null;
  if (statusCode == 401 || statusCode == 403) {
    return const PlaybackProviderFailure(
      PlaybackProviderFailureKind.unauthorized,
    );
  }
  if (statusCode == 429) {
    return const PlaybackProviderFailure(
      PlaybackProviderFailureKind.rateLimited,
    );
  }
  if (statusCode >= 300 && statusCode < 400) {
    return const PlaybackProviderFailure(
      PlaybackProviderFailureKind.unsupported,
    );
  }
  if (statusCode == 404 || statusCode >= 500) {
    return const PlaybackProviderFailure(
      PlaybackProviderFailureKind.unavailable,
    );
  }
  return const PlaybackProviderFailure(
    PlaybackProviderFailureKind.invalidResponse,
  );
}
