import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../domain/player/providers/playback_provider_contract.dart';
import '../../../domain/player/providers/playback_source.dart';

/// Bounded ordinary GETs to exact provider or embed hosts.
final class PublicPlaybackHttp {
  static const int defaultMaxResponseBytes = 2 * 1024 * 1024;
  static const int maxAllowedResponseBytes = 8 * 1024 * 1024;

  PublicPlaybackHttp(
    this.client,
    this.allowedHosts, {
    this.userAgent = 'Kongroo/0.1 (public anime catalog client)',
    this.enforceCooldown = true,
    this.maxConcurrent,
  });

  final Dio client;
  final Set<String> allowedHosts;
  final String userAgent;
  final bool enforceCooldown;
  final int? maxConcurrent;
  int _active = 0;
  final Map<String, DateTime> _retryUntilByOrigin = {};

  static Duration? _retryAfter(String? value, DateTime now) {
    if (value == null) return null;
    final int? seconds = int.tryParse(value.trim());
    if (seconds != null && seconds >= 0 && seconds <= 315360000) {
      return Duration(seconds: seconds);
    }
    try {
      final Duration delay = HttpDate.parse(value.trim()).difference(now);
      return delay.isNegative ? Duration.zero : delay;
    } on FormatException {
      return null;
    } on HttpException {
      return null;
    }
  }

  Future<String> read(
    Uri uri,
    PlaybackCancellationToken cancellation, {
    PlaybackHttpStage stage = PlaybackHttpStage.catalog,
    int maxResponseBytes = defaultMaxResponseBytes,
    PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(),
    bool ajax = false,
  }) async => (await _request(
    uri,
    cancellation,
    stage: stage,
    maxResponseBytes: maxResponseBytes,
    headers: headers,
    ajax: ajax,
    allows: (target) =>
        target.port == 443 && allowedHosts.contains(target.host),
  )).text;

  /// Posts one bounded JSON document through the same host allowlist,
  /// cancellation, timeout and retry policy as [read]. Used by public catalog
  /// APIs whose documented search endpoint requires a request body.
  Future<String> readJson(
    Uri uri,
    PlaybackCancellationToken cancellation, {
    required String jsonBody,
    PlaybackHttpStage stage = PlaybackHttpStage.catalog,
    int maxResponseBytes = defaultMaxResponseBytes,
    PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(),
  }) async {
    if (jsonBody.isEmpty || jsonBody.length > 65536) {
      throw ArgumentError.value(jsonBody.length, 'jsonBody');
    }
    return (await _request(
      uri,
      cancellation,
      stage: stage,
      maxResponseBytes: maxResponseBytes,
      headers: headers,
      jsonBody: jsonBody,
      allows: (target) =>
          target.port == 443 && allowedHosts.contains(target.host),
    )).text;
  }

  /// Reads a bounded binary response through the same host, cancellation,
  /// timeout and retry policy as [read]. Used for public APIs whose documented
  /// catalog payload is compressed or otherwise not UTF-8 text.
  Future<Uint8List> readBytes(
    Uri uri,
    PlaybackCancellationToken cancellation, {
    PlaybackHttpStage stage = PlaybackHttpStage.catalog,
    int maxResponseBytes = defaultMaxResponseBytes,
    PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(),
  }) async => (await _request(
    uri,
    cancellation,
    stage: stage,
    maxResponseBytes: maxResponseBytes,
    headers: headers,
    decodeText: false,
    allows: (target) =>
        target.port == 443 && allowedHosts.contains(target.host),
  )).bytes;

  /// Verifies the selected host's public response headers before offering it.
  /// Only one same-origin redirect to another admitted media URI is allowed.
  Future<Uri> checkMp4(
    Uri uri,
    PlaybackCancellationToken cancellation, {
    required bool Function(Uri) allows,
    required PlaybackRequestHeaders headers,
  }) async => (await _request(
    uri,
    cancellation,
    stage: PlaybackHttpStage.media,
    headOnly: true,
    allows: allows,
    headers: headers,
  )).uri;

  Future<({Uri uri, String text, Uint8List bytes})> _request(
    Uri uri,
    PlaybackCancellationToken cancellation, {
    required PlaybackHttpStage stage,
    required bool Function(Uri) allows,
    int maxResponseBytes = defaultMaxResponseBytes,
    PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(),
    bool decodeText = true,
    bool ajax = false,
    bool headOnly = false,
    String? jsonBody,
  }) async {
    if (maxResponseBytes < 1 || maxResponseBytes > maxAllowedResponseBytes) {
      throw ArgumentError.value(maxResponseBytes, 'maxResponseBytes');
    }
    final bool head = headOnly;
    final String method = jsonBody != null
        ? 'POST'
        : head
        ? 'HEAD'
        : 'GET';
    bool permits(Uri target) =>
        target.scheme == 'https' &&
        target.userInfo.isEmpty &&
        !target.hasFragment &&
        allows(target);
    if (!permits(uri)) {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.blocked,
        stage: stage,
      );
    }
    if (cancellation.isCancelled) {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.cancelled,
        stage: stage,
        host: uri.host,
      );
    }
    final DateTime requestStarted = DateTime.now();
    _retryUntilByOrigin.removeWhere(
      (_, deadline) => !deadline.isAfter(requestStarted),
    );
    if (_retryUntilByOrigin[uri.origin] case final DateTime retryAt) {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.rateLimited,
        host: uri.host,
        retryAfter: retryAt.difference(requestStarted),
        stage: stage,
      );
    }
    if (maxConcurrent case final int limit when _active >= limit) {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.rateLimited,
        host: uri.host,
        retryAfter: const Duration(seconds: 5),
        stage: stage,
      );
    }
    _active++;
    final Stopwatch elapsed = Stopwatch()..start();
    final CancelToken token = CancelToken();
    final Timer timer = Timer(const Duration(seconds: 6), () => token.cancel());
    final void Function() unregister = cancellation.addCancelListener(
      token.cancel,
    );
    try {
      Future<Response<ResponseBody>> send(Uri target) =>
          client.requestUri<ResponseBody>(
            target,
            cancelToken: token,
            data: jsonBody,
            options: Options(
              method: method,
              responseType: ResponseType.stream,
              followRedirects: false,
              validateStatus: (_) => true,
              headers: {
                if (jsonBody != null) 'Content-Type': 'application/json',
                if (!head)
                  'Accept':
                      'application/json, application/octet-stream;q=0.9, '
                      'text/html;q=0.8',
                'User-Agent': userAgent,
                if (ajax && !head) 'X-Requested-With': 'XMLHttpRequest',
                ...headers.values,
              },
            ),
          );

      Response<ResponseBody> response = await send(uri);
      final String? location = response.headers['location']?.firstOrNull;
      if (head &&
          location != null &&
          const {301, 302, 303, 307, 308}.contains(response.statusCode) &&
          response.headers['cf-mitigated']?.firstOrNull != 'challenge') {
        final Uri? relative = Uri.tryParse(location);
        final Uri? next = relative == null ? null : uri.resolveUri(relative);
        if (next != null &&
            permits(next) &&
            next.origin == uri.origin &&
            next != uri) {
          await response.data?.stream.listen(null).cancel();
          developer.log(
            'stage=${stage.name} method=$method host=${uri.host} '
            'status=${response.statusCode} redirect=same-origin',
            name: 'kongroo.playback.http',
          );
          uri = next;
          response = await send(uri);
        }
      }
      final int code = response.statusCode ?? 0;
      final String? declaredServer = response.headers['server']?.firstOrNull;
      final String? server =
          declaredServer != null &&
              RegExp(r'^[a-zA-Z0-9 /_.-]{1,64}$').hasMatch(declaredServer)
          ? declaredServer
          : null;
      final String? mime = response.headers['content-type']?.firstOrNull
          ?.split(';')
          .first
          .trim()
          .toLowerCase();
      final String? contentType =
          mime != null &&
              RegExp(r'^[a-z0-9+_.-]+/[a-z0-9+_.-]+$').hasMatch(mime) &&
              mime.length <= 96
          ? mime
          : null;
      final DateTime now = DateTime.now();
      final bool challenge =
          response.headers['cf-mitigated']?.firstOrNull == 'challenge';
      final bool throttled =
          !challenge && (code == 429 || (code == 503 && enforceCooldown));
      final Duration? retryAfter = throttled
          ? _retryAfter(response.headers['retry-after']?.firstOrNull, now) ??
                Duration(milliseconds: 5000 + Random().nextInt(1001))
          : null;
      if (enforceCooldown && retryAfter != null) {
        final DateTime next = now.add(retryAfter);
        final DateTime? previous = _retryUntilByOrigin[uri.origin];
        if (previous == null || next.isAfter(previous)) {
          _retryUntilByOrigin[uri.origin] = next;
        }
      }
      developer.log(
        'stage=${stage.name} method=$method host=${uri.host} status=$code '
        'content_type=${contentType ?? "unknown"} server=${server ?? "unknown"} '
        'elapsed_ms=${elapsed.elapsedMilliseconds} retry_ms=${retryAfter?.inMilliseconds}'
        '${enforceCooldown ? " ua=$userAgent" : ""}',
        name: 'kongroo.playback.http',
      );
      final bool success = code == 200 && !challenge;
      final body = response.data;
      if (throttled) {
        throw PublicPlaybackFailure(
          PlaybackProviderFailureKind.rateLimited,
          status: code,
          host: uri.host,
          server: server,
          retryAfter: enforceCooldown
              ? _retryUntilByOrigin[uri.origin]?.difference(now)
              : retryAfter,
          stage: stage,
          contentType: contentType,
        );
      }
      if (head && success) {
        if (!const {
          'video/mp4',
          'application/octet-stream',
        }.contains(contentType)) {
          throw PublicPlaybackFailure(
            PlaybackProviderFailureKind.invalidResponse,
            status: code,
            host: uri.host,
            server: server,
            stage: stage,
            contentType: contentType,
          );
        }
        return (uri: uri, text: '', bytes: Uint8List(0));
      }
      if (body == null) {
        throw const PublicPlaybackFailure(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }

      final BytesBuilder bytes = BytesBuilder(copy: false);
      await for (final chunk in body.stream.timeout(
        const Duration(seconds: 6),
      )) {
        final int limit = success ? maxResponseBytes + 1 : 200;
        bytes.add(
          chunk.length > limit - bytes.length
              ? chunk.sublist(0, limit - bytes.length)
              : chunk,
        );
        if (bytes.length >= limit) break;
      }
      if (token.isCancelled) {
        throw PublicPlaybackFailure(
          cancellation.isCancelled
              ? PlaybackProviderFailureKind.cancelled
              : PlaybackProviderFailureKind.timeout,
        );
      }
      if (success && (bytes.length == 0 || bytes.length > maxResponseBytes)) {
        throw const PublicPlaybackFailure(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }
      final Uint8List responseBytes = bytes.takeBytes();
      // Binary catalog formats must reach their decoder without a UTF-8 pass.
      // Error bodies still use a permissive prefix for HTTP classification.
      final String text = success && !decodeText
          ? ''
          : utf8.decode(responseBytes, allowMalformed: !success);
      if (!success) {
        final String prefix = text.toLowerCase();
        throw PublicPlaybackFailure(
          switch (code) {
            _ when challenge => PlaybackProviderFailureKind.challenge,
            403 when prefix.contains('error code: 1020') =>
              PlaybackProviderFailureKind.policyBlocked,
            403 when prefix.contains('error code: 1006') =>
              PlaybackProviderFailureKind.ipBlocked,
            403 => PlaybackProviderFailureKind.forbidden,
            401 => PlaybackProviderFailureKind.unauthorized,
            404 || 410 => PlaybackProviderFailureKind.notFound,
            451 => PlaybackProviderFailureKind.blocked,
            >= 300 && < 400 => PlaybackProviderFailureKind.blocked,
            >= 500 => PlaybackProviderFailureKind.unavailable,
            _ => PlaybackProviderFailureKind.invalidResponse,
          },
          status: code,
          host: uri.host,
          server: server,
          stage: stage,
          contentType: contentType,
        );
      }
      return (uri: uri, text: text, bytes: responseBytes);
    } on DioException catch (error) {
      throw PublicPlaybackFailure(
        switch (error.type) {
          _ when cancellation.isCancelled =>
            PlaybackProviderFailureKind.cancelled,
          DioExceptionType.cancel ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.connectionTimeout =>
            PlaybackProviderFailureKind.timeout,
          _ => PlaybackProviderFailureKind.network,
        },
        stage: stage,
        host: uri.host,
      );
    } on TimeoutException {
      throw PublicPlaybackFailure(
        PlaybackProviderFailureKind.timeout,
        stage: stage,
        host: uri.host,
      );
    } on FormatException {
      throw const PublicPlaybackFailure(
        PlaybackProviderFailureKind.invalidResponse,
      );
    } finally {
      // Dio owns an upstream subscription while a streamed body is active.
      // Cancel it even when we stop reading after a small diagnostic prefix.
      token.cancel();
      unregister();
      timer.cancel();
      _active--;
    }
  }
}

final class PublicPlaybackFailure implements Exception {
  const PublicPlaybackFailure(
    this.kind, {
    this.status,
    this.host,
    this.server,
    this.retryAfter,
    this.stage,
    this.contentType,
  });
  final PlaybackProviderFailureKind kind;
  final int? status;
  final String? host;
  final String? server;
  final Duration? retryAfter;
  final PlaybackHttpStage? stage;
  final String? contentType;

  PlaybackProviderFailed<T> result<T>() => PlaybackProviderFailed<T>(
    PlaybackProviderFailure(
      kind,
      httpStatus: status,
      host: host,
      server: server,
      retryAfter: retryAfter,
      stage: stage,
      contentType: contentType,
    ),
  );
}
