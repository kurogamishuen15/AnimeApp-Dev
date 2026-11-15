import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../domain/player/providers/playback_provider_contract.dart';

/// Small bounded HTTP client seam shared by public-site adapters.
///
/// It performs ordinary HTTPS GETs only. It has no cookie jar, JavaScript
/// runtime, challenge solver, credential support, or browser impersonation.
final class PublicSiteHttp {
  PublicSiteHttp({required Dio dio, required Set<String> allowedHosts})
    : this._(dio, allowedHosts);

  PublicSiteHttp._(this._dio, Set<String> allowedHosts)
    : _allowedHosts = Set.unmodifiable(allowedHosts.map(_normalizeHost));

  static const int maximumResponseBytes = 2 * 1024 * 1024;
  final Dio _dio;
  final Set<String> _allowedHosts;

  Future<String> getText(
    Uri uri, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) {
      throw const PublicSiteException(PlaybackProviderFailureKind.cancelled);
    }
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty ||
        uri.hasFragment ||
        !_isAllowedHost(uri.host)) {
      throw const PublicSiteException(
        PlaybackProviderFailureKind.invalidResponse,
      );
    }
    final CancelToken dioCancellation = CancelToken();
    final void Function() removeCancellationListener = cancellation
        .addCancelListener(
          () => dioCancellation.cancel('Playback provider request cancelled.'),
        );
    try {
      final Response<ResponseBody> response = await _dio.get<ResponseBody>(
        uri.toString(),
        cancelToken: dioCancellation,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          receiveDataWhenStatusError: true,
          headers: const {
            'Accept': 'text/html,application/json;q=0.9,*/*;q=0.5',
            'User-Agent':
                'Kongroo/0.1 (desktop; public playback source client)',
          },
        ),
      );
      if (cancellation.isCancelled) {
        throw const PublicSiteException(PlaybackProviderFailureKind.cancelled);
      }
      final int status = response.statusCode ?? 0;
      if (status == 401 || status == 403) {
        throw const PublicSiteException(
          PlaybackProviderFailureKind.unauthorized,
        );
      }
      if (status == 429) {
        throw const PublicSiteException(
          PlaybackProviderFailureKind.rateLimited,
        );
      }
      if (status != 200) {
        await response.data?.stream.listen(null).cancel();
        throw PublicSiteException(
          status == 404
              ? PlaybackProviderFailureKind.unavailable
              : PlaybackProviderFailureKind.network,
        );
      }
      final ResponseBody? responseBody = response.data;
      if (responseBody == null) {
        throw const PublicSiteException(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }
      final BytesBuilder bytes = BytesBuilder(copy: false);
      var totalBytes = 0;
      await for (final List<int> chunk in responseBody.stream) {
        totalBytes += chunk.length;
        if (totalBytes > maximumResponseBytes) {
          throw const PublicSiteException(
            PlaybackProviderFailureKind.invalidResponse,
          );
        }
        if (cancellation.isCancelled) {
          throw const PublicSiteException(
            PlaybackProviderFailureKind.cancelled,
          );
        }
        bytes.add(chunk);
      }
      try {
        return utf8.decode(bytes.takeBytes());
      } on FormatException {
        throw const PublicSiteException(
          PlaybackProviderFailureKind.invalidResponse,
        );
      }
    } on PublicSiteException {
      rethrow;
    } on DioException catch (error) {
      final PlaybackProviderFailureKind kind = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => PlaybackProviderFailureKind.timeout,
        DioExceptionType.cancel => PlaybackProviderFailureKind.cancelled,
        DioExceptionType.badResponse when error.response?.statusCode == 429 =>
          PlaybackProviderFailureKind.rateLimited,
        DioExceptionType.badResponse
            when error.response?.statusCode == 401 ||
                error.response?.statusCode == 403 =>
          PlaybackProviderFailureKind.unauthorized,
        DioExceptionType.badResponse => PlaybackProviderFailureKind.network,
        _ => PlaybackProviderFailureKind.network,
      };
      throw PublicSiteException(kind);
    } finally {
      removeCancellationListener();
    }
  }

  /// Rejects private literals and DNS names that currently resolve privately.
  /// This is a guardrail, not a DNS pinning guarantee for the native player.
  Future<bool> isPublicHttpsTarget(Uri uri) async {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return false;
    }
    final InternetAddress? literal = InternetAddress.tryParse(uri.host);
    if (literal != null) return _isPublicAddress(literal);
    try {
      final List<InternetAddress> addresses = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.any,
      ).timeout(const Duration(seconds: 3));
      return addresses.isNotEmpty && addresses.every(_isPublicAddress);
    } on Object {
      return false;
    }
  }

  bool _isAllowedHost(String host) {
    final String normalized = _normalizeHost(host);
    return _allowedHosts.any(
      (String allowed) =>
          normalized == allowed || normalized.endsWith('.$allowed'),
    );
  }
}

final class PublicSiteException implements Exception {
  const PublicSiteException(this.kind);
  final PlaybackProviderFailureKind kind;
}

bool _isPublicAddress(InternetAddress address) {
  if (address.type == InternetAddressType.IPv4) {
    final List<int> octets = address.rawAddress;
    final int first = octets[0];
    final int second = octets[1];
    return first != 0 &&
        first != 10 &&
        first != 127 &&
        !(first == 169 && second == 254) &&
        !(first == 172 && second >= 16 && second <= 31) &&
        !(first == 192 && second == 168) &&
        !(first == 100 && second >= 64 && second <= 127) &&
        first < 224;
  }
  final List<int> bytes = address.rawAddress;
  final bool ipv4Mapped =
      bytes.take(10).every((int byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (ipv4Mapped) {
    return _isPublicAddress(
      InternetAddress.fromRawAddress(Uint8List.fromList(bytes.sublist(12))),
    );
  }
  final bool loopback =
      bytes.take(15).every((int byte) => byte == 0) && bytes.last == 1;
  final bool unspecified = bytes.every((int byte) => byte == 0);
  final bool uniqueLocal = (bytes[0] & 0xfe) == 0xfc;
  final bool linkLocal = bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80;
  final bool multicast = bytes[0] == 0xff;
  return !loopback && !unspecified && !uniqueLocal && !linkLocal && !multicast;
}

String _normalizeHost(String host) => host.trim().toLowerCase();
