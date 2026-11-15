import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/player/subtitles/external_subtitle_catalog.dart';

typedef OpenSubtitlesSecret = Future<String?> Function();
typedef OpenSubtitlesStorageDirectory = Future<Directory> Function();
typedef OpenSubtitlesFileToken = String Function();

/// OpenSubtitles.com REST API v1 adapter. API and file-download hosts are
/// validated separately; credentials are sent only to the API origin.
final class OpenSubtitlesClient implements ExternalSubtitleCatalog {
  factory OpenSubtitlesClient({
    required OpenSubtitlesSecret apiKey,
    OpenSubtitlesSecret? bearerToken,
    Dio? dio,
    Directory? storageDirectory,
    OpenSubtitlesStorageDirectory? storageDirectoryProvider,
    OpenSubtitlesFileToken? fileToken,
    int maxDownloadBytes = 10 * 1024 * 1024,
  }) => OpenSubtitlesClient._(
    apiKey,
    bearerToken,
    dio,
    storageDirectory,
    storageDirectoryProvider ?? getApplicationSupportDirectory,
    fileToken ?? _newFileToken,
    maxDownloadBytes,
  );

  OpenSubtitlesClient._(
    this._apiKey,
    this.bearerToken,
    Dio? dio,
    this.storageDirectory,
    this._storageDirectoryProvider,
    this._fileToken,
    this.maxDownloadBytes,
  ) : _dio = dio ?? _createDio(),
      _ownsDio = dio == null;

  static const String _apiBase = 'https://api.opensubtitles.com/api/v1';
  static const String _userAgent = 'Kongroo/0.1';
  static const Set<String> _formats = {'srt', 'ass', 'ssa', 'vtt'};

  final OpenSubtitlesSecret _apiKey;
  final OpenSubtitlesSecret? bearerToken;
  final Dio _dio;
  final bool _ownsDio;
  final Directory? storageDirectory;
  final OpenSubtitlesStorageDirectory _storageDirectoryProvider;
  final OpenSubtitlesFileToken _fileToken;
  final int maxDownloadBytes;

  static String _newFileToken() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff).toRadixString(16)}';

  void close() {
    if (_ownsDio) _dio.close(force: true);
  }

  static String _normalizeImdbId(String value) => value
      .trim()
      .replaceFirst(RegExp(r'^tt', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^0+(?=\d)'), '');

  @override
  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  ) async {
    final String? key;
    try {
      key = await _readApiKey();
    } on Object {
      return const ExternalSubtitleFailure(ExternalSubtitleFailureKind.unknown);
    }
    if (key == null) {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.missingApiKey,
      );
    }
    final Map<String, Object> params = <String, Object>{};
    if (query.query?.trim().isNotEmpty ?? false) {
      params['query'] = query.query!.trim().toLowerCase();
    }
    if (query.languages.isNotEmpty) {
      params['languages'] = query.languages.join(',').toLowerCase();
    }
    if (query.imdbId?.trim().isNotEmpty ?? false) {
      params['imdb_id'] = _normalizeImdbId(query.imdbId!);
    }
    if (query.parentImdbId?.trim().isNotEmpty ?? false) {
      params['parent_imdb_id'] = _normalizeImdbId(query.parentImdbId!);
    }
    if (query.tmdbId?.trim().isNotEmpty ?? false) {
      params['tmdb_id'] = query.tmdbId!.trim();
    }
    if (query.season != null) {
      params['season_number'] = query.season!;
      params['episode_number'] = query.episode!;
    }
    if (query.movieHash?.trim().isNotEmpty ?? false) {
      params['moviehash'] = query.movieHash!.trim().toLowerCase();
    }
    if (query.fileName?.trim().isNotEmpty ?? false) {
      params.putIfAbsent('query', () => query.fileName!.trim().toLowerCase());
    }
    final Map<String, Object> sortedParams = Map.fromEntries(
      params.entries.toList()..sort(
        (MapEntry<String, Object> a, MapEntry<String, Object> b) =>
            a.key.compareTo(b.key),
      ),
    );
    try {
      final Map<String, String> stringParams = sortedParams.map(
        (String name, Object value) => MapEntry(name, value.toString()),
      );
      Uri current = Uri.parse('$_apiBase/subtitles')
          .replace(queryParameters: stringParams);
      for (var redirects = 0; redirects <= 3; redirects++) {
        final Response<Object?> response = await _dio.get<Object?>(
          current.toString(),
          options: Options(
            headers: _headers(key),
            followRedirects: false,
            validateStatus: (int? status) => status != null,
          ),
        );
        final int status = response.statusCode ?? 0;
        if (status >= 300 && status < 400) {
          final String? location = response.headers.value(
            HttpHeaders.locationHeader,
          );
          final Uri? next = location == null
              ? null
              : current.resolveUri(Uri.tryParse(location) ?? Uri());
          if (next == null || redirects == 3 || !_isTrustedApiUri(next)) {
            return const ExternalSubtitleFailure(
              ExternalSubtitleFailureKind.invalidApiRedirect,
            );
          }
          current = next;
          continue;
        }
        if (status != HttpStatus.ok) {
          return _mapStatus<List<ExternalSubtitleCandidate>>(response);
        }
        final Map<String, Object?> body = _asMap(response.data);
        final Object? rawResults = body['data'];
        if (rawResults is! List<Object?>) {
          return const ExternalSubtitleFailure(
            ExternalSubtitleFailureKind.malformedResponse,
          );
        }
        final List<ExternalSubtitleCandidate> candidates = [];
        for (final Object? raw in rawResults) {
          candidates.addAll(_mapCandidates(raw));
        }
        return ExternalSubtitleSuccess(List.unmodifiable(candidates));
      }
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.invalidApiRedirect,
      );
    } on DioException catch (error) {
      return ExternalSubtitleFailure(_mapDioError(error));
    } on Object {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.malformedResponse,
      );
    }
  }

  @override
  Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download(
    ExternalSubtitleCandidate candidate,
  ) async {
    final String format = candidate.format.toLowerCase();
    if (candidate.fileId < 1 || !_formats.contains(format)) {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.unsupportedFormat,
      );
    }
    final String? key;
    try {
      key = await _readApiKey();
    } on Object {
      return const ExternalSubtitleFailure(ExternalSubtitleFailureKind.unknown);
    }
    if (key == null) {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.missingApiKey,
      );
    }
    try {
      final Response<Object?> response = await _dio.post<Object?>(
        '$_apiBase/download',
        data: <String, Object>{
          'file_id': candidate.fileId,
          'sub_format': format,
        },
        options: Options(
          headers: await _downloadHeaders(key),
          followRedirects: false,
          validateStatus: (int? status) => status != null,
        ),
      );
      if (response.statusCode != HttpStatus.ok) {
        return _mapStatus<ExternalSubtitleDownload>(response);
      }
      final Map<String, Object?> body = _asMap(response.data);
      final Object? rawLink = body['link'];
      final Uri? link = rawLink is String ? Uri.tryParse(rawLink) : null;
      if (link == null || !_isTrustedDownloadUri(link)) {
        return const ExternalSubtitleFailure(
          ExternalSubtitleFailureKind.invalidDownloadUrl,
        );
      }
      final ExternalSubtitleResult<List<int>> bytesResult =
          await _downloadBytes(link);
      if (bytesResult case ExternalSubtitleFailure<List<int>>(
        :final kind,
        :final retryAfter,
      )) {
        return ExternalSubtitleFailure(kind, retryAfter: retryAfter);
      }
      final List<int> bytes =
          (bytesResult as ExternalSubtitleSuccess<List<int>>).value;
      if (!_validSubtitleContent(bytes, format)) {
        return const ExternalSubtitleFailure(
          ExternalSubtitleFailureKind.corruptFile,
        );
      }
      final Directory directory;
      try {
        directory = storageDirectory ?? await _storageDirectoryProvider();
        await directory.create(recursive: true);
      } on Object {
        return const ExternalSubtitleFailure(
          ExternalSubtitleFailureKind.storageFailure,
        );
      }
      final String extension = '.$format';
      final String token;
      try {
        token = _fileToken();
      } on Object {
        return const ExternalSubtitleFailure(
          ExternalSubtitleFailureKind.storageFailure,
        );
      }
      if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(token)) {
        return const ExternalSubtitleFailure(
          ExternalSubtitleFailureKind.storageFailure,
        );
      }
      final String fileName =
          'opensubtitles-${candidate.fileId}-$token$extension';
      final File target = File('${directory.path}/$fileName');
      final File temporary = File('${target.path}.part');
      var renamed = false;
      var createdTemporary = false;
      try {
        await temporary.create(exclusive: true);
        createdTemporary = true;
        await temporary.writeAsBytes(bytes, flush: true);
        if (await target.exists()) {
          return const ExternalSubtitleFailure(
            ExternalSubtitleFailureKind.storageFailure,
          );
        }
        await temporary.rename(target.path);
        renamed = true;
      } finally {
        if (!renamed && createdTemporary && await temporary.exists()) {
          await temporary.delete();
        }
      }
      return ExternalSubtitleSuccess(
        ExternalSubtitleDownload(
          uri: target.uri,
          format: format,
          language: candidate.language,
          remainingDownloads: _integer(body['remaining']),
          resetAt: DateTime.tryParse(body['reset_time_utc']?.toString() ?? ''),
        ),
      );
    } on DioException catch (error) {
      return ExternalSubtitleFailure(_mapDioError(error));
    } on FileSystemException {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.storageFailure,
      );
    } on Object {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.malformedResponse,
      );
    }
  }

  Future<ExternalSubtitleResult<List<int>>> _downloadBytes(Uri initial) async {
    Uri current = initial;
    for (var redirects = 0; redirects <= 3; redirects++) {
      if (!_isTrustedDownloadUri(current)) {
        return const ExternalSubtitleFailure(
          ExternalSubtitleFailureKind.invalidDownloadUrl,
        );
      }
      final CancelToken bodyCancellation = CancelToken();
      final Response<ResponseBody> response = await _dio.get<ResponseBody>(
        current.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          validateStatus: (int? status) => status != null,
        ),
        cancelToken: bodyCancellation,
      );
      final int status = response.statusCode ?? 0;
      if (status >= 300 && status < 400) {
        final String? location = response.headers.value(
          HttpHeaders.locationHeader,
        );
        final Uri? next = location == null
            ? null
            : current.resolveUri(Uri.tryParse(location) ?? Uri());
        if (next == null || redirects == 3 || !_isTrustedDownloadUri(next)) {
          await _discardBody(response.data, bodyCancellation);
          return const ExternalSubtitleFailure(
            ExternalSubtitleFailureKind.invalidDownloadUrl,
          );
        }
        await _discardBody(response.data, bodyCancellation);
        current = next;
        continue;
      }
      if (status != HttpStatus.ok) {
        await _discardBody(response.data, bodyCancellation);
        if (status == HttpStatus.tooManyRequests) {
          return ExternalSubtitleFailure(
            ExternalSubtitleFailureKind.rateLimited,
            retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
          );
        }
        return ExternalSubtitleFailure(_statusKind(status));
      }
      final ResponseBody? body = response.data;
      if (body == null) {
        return const ExternalSubtitleFailure(
          ExternalSubtitleFailureKind.corruptFile,
        );
      }
      return _readBoundedBody(body, bodyCancellation);
    }
    return const ExternalSubtitleFailure(
      ExternalSubtitleFailureKind.invalidDownloadUrl,
    );
  }

  Future<void> _discardBody(
    ResponseBody? body,
    CancelToken cancellation,
  ) async {
    if (body == null) {
      cancellation.cancel('Response body is not needed.');
      return;
    }
    final Completer<void> settled = Completer<void>();
    final StreamSubscription<List<int>> subscription = body.stream.listen(
      (List<int> _) {},
      onError: (Object _) {
        if (!settled.isCompleted) settled.complete();
      },
      onDone: () {
        if (!settled.isCompleted) settled.complete();
      },
    );
    cancellation.cancel('Response body is not needed.');
    await settled.future;
    await subscription.cancel();
  }

  Future<ExternalSubtitleResult<List<int>>> _readBoundedBody(
    ResponseBody body,
    CancelToken cancellation,
  ) async {
    final List<int> bytes = [];
    final Completer<ExternalSubtitleResult<List<int>>> settled =
        Completer<ExternalSubtitleResult<List<int>>>();
    var tooLarge = false;
    final StreamSubscription<List<int>> subscription = body.stream.listen(
      (List<int> chunk) {
        if (bytes.length + chunk.length > maxDownloadBytes) {
          tooLarge = true;
          cancellation.cancel('Subtitle exceeded the configured size limit.');
        } else {
          bytes.addAll(chunk);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (settled.isCompleted) return;
        if (tooLarge) {
          settled.complete(
            const ExternalSubtitleFailure(ExternalSubtitleFailureKind.tooLarge),
          );
        } else {
          settled.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (settled.isCompleted) return;
        settled.complete(
          tooLarge
              ? const ExternalSubtitleFailure(
                  ExternalSubtitleFailureKind.tooLarge,
                )
              : ExternalSubtitleSuccess(bytes),
        );
      },
    );
    try {
      final ExternalSubtitleResult<List<int>> result = await settled.future;
      await subscription.cancel();
      return result;
    } on Object {
      await subscription.cancel();
      rethrow;
    }
  }

  Future<String?> _readApiKey() async {
    final String? key = await _apiKey();
    final String? trimmed = key?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, String>> _downloadHeaders(String key) async {
    final Map<String, String> headers = _headers(key);
    final String? token = await bearerToken?.call();
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    return headers;
  }

  Map<String, String> _headers(String key) => <String, String>{
    'Api-Key': key,
    'User-Agent': _userAgent,
    'Accept': 'application/json',
  };

  static Dio _createDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
      headers: const {'Accept': 'application/json'},
    ),
  );

  static List<ExternalSubtitleCandidate> _mapCandidates(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return const <ExternalSubtitleCandidate>[];
    }
    final Map<String, Object?> root = _asMap(value);
    final Map<String, Object?> attributes = _asMap(root['attributes']);
    final Object? rawFiles = attributes['files'];
    if (rawFiles is! List<Object?> || rawFiles.isEmpty) {
      return const <ExternalSubtitleCandidate>[];
    }
    final String? language = attributes['language'] as String?;
    final String? subtitleId = root['id']?.toString();
    if (language == null || subtitleId == null) {
      return const <ExternalSubtitleCandidate>[];
    }
    final List<ExternalSubtitleCandidate> candidates = [];
    for (var index = 0; index < rawFiles.length; index++) {
      final Map<String, Object?> file = _asMap(rawFiles[index]);
      final int? fileId = _integer(file['file_id']);
      final Object? rawName = file['file_name'];
      if (fileId == null || fileId < 1 || rawName is! String) continue;
      final String format = rawName.split('.').last.toLowerCase();
      if (!_formats.contains(format)) continue;
      candidates.add(
        ExternalSubtitleCandidate(
          subtitleId: subtitleId,
          fileId: fileId,
          fileName: rawName,
          language: language,
          format: format,
          release: attributes['release'] as String?,
          downloadCount: _integer(attributes['download_count']),
          movieHashMatch: attributes['moviehash_match'] == true,
          hearingImpaired: attributes['hearing_impaired'] == true,
          fps: _number(attributes['fps']),
          partNumber: rawFiles.length > 1
              ? _integer(file['cd_number']) ?? index + 1
              : null,
          partCount: rawFiles.length > 1 ? rawFiles.length : null,
        ),
      );
    }
    return candidates;
  }

  static Map<String, Object?> _asMap(Object? value) =>
      value is Map<Object?, Object?>
      ? value.map((Object? key, Object? item) => MapEntry(key.toString(), item))
      : <String, Object?>{};

  static int? _integer(Object? value) => switch (value) {
    final int number => number,
    final num number when number.isFinite => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };

  static double? _number(Object? value) => switch (value) {
    final num number when number.isFinite => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };

  static bool _isTrustedDownloadUri(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      (uri.port == 443) &&
      uri.host == 'www.opensubtitles.com' &&
      uri.path.startsWith('/download/');

  static bool _isTrustedApiUri(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      const {
        'api.opensubtitles.com',
        'vip-api.opensubtitles.com',
      }.contains(uri.host) &&
      uri.path == '/api/v1/subtitles';

  bool _validSubtitleContent(List<int> bytes, String format) {
    if (bytes.isEmpty || bytes.length > maxDownloadBytes || bytes.contains(0)) {
      return false;
    }
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false).trim();
    } on FormatException {
      return false;
    }
    if (text.isEmpty) return false;
    return switch (format) {
      'srt' => RegExp(r'\d{2}:\d{2}:\d{2}[,.]\d{3}\s+-->').hasMatch(text),
      'vtt' => text.startsWith('WEBVTT') && text.contains('-->'),
      'ass' || 'ssa' =>
        text.contains('[Events]') &&
            RegExp(r'^Dialogue:', multiLine: true).hasMatch(text),
      _ => false,
    };
  }

  static ExternalSubtitleFailure<T> _mapStatus<T>(Response<Object?> response) {
    final int status = response.statusCode ?? 0;
    final Map<String, Object?> body = _asMap(response.data);
    final String message = body.values.join(' ').toLowerCase();
    final bool quota =
        message.contains('quota') ||
        message.contains('download limit') ||
        _integer(body['remaining']) == 0;
    if (quota) {
      return ExternalSubtitleFailure<T>(
        ExternalSubtitleFailureKind.quotaExhausted,
      );
    }
    if (status == HttpStatus.tooManyRequests) {
      final String? retry = response.headers.value('retry-after');
      return ExternalSubtitleFailure<T>(
        ExternalSubtitleFailureKind.rateLimited,
        retryAfter: _parseRetryAfter(retry),
      );
    }
    return ExternalSubtitleFailure<T>(_statusKind(status));
  }

  static Duration? _parseRetryAfter(String? value) {
    final String? normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    final int? seconds = int.tryParse(normalized);
    if (seconds != null) {
      return seconds < 0 ? Duration.zero : Duration(seconds: seconds);
    }
    try {
      final DateTime retryAt = HttpDate.parse(normalized).toUtc();
      final Duration delay = retryAt.difference(DateTime.now().toUtc());
      return delay.isNegative ? Duration.zero : delay;
    } on FormatException {
      return null;
    }
  }

  static ExternalSubtitleFailureKind _statusKind(int status) =>
      switch (status) {
        HttpStatus.unauthorized => ExternalSubtitleFailureKind.unauthorized,
        HttpStatus.forbidden => ExternalSubtitleFailureKind.forbidden,
        HttpStatus.notFound => ExternalSubtitleFailureKind.notFound,
        HttpStatus.tooManyRequests => ExternalSubtitleFailureKind.rateLimited,
        >= 500 => ExternalSubtitleFailureKind.network,
        _ => ExternalSubtitleFailureKind.unknown,
      };

  static ExternalSubtitleFailureKind _mapDioError(DioException error) =>
      switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => ExternalSubtitleFailureKind.timeout,
        DioExceptionType.connectionError => ExternalSubtitleFailureKind.network,
        _ => ExternalSubtitleFailureKind.unknown,
      };
}
