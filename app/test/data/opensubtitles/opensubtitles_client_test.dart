import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_app/data/opensubtitles/opensubtitles_client.dart';
import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  String body,
  int status, {
  Map<String, List<String>> headers = const {
    Headers.contentTypeHeader: ['application/json'],
  },
}) => ResponseBody.fromString(body, status, headers: headers);

const String _searchBody = '''
{"data":[{"id":"sub-17","attributes":{"language":"en","release":"episode.release","download_count":34,"moviehash_match":true,"hearing_impaired":false,"fps":23.976,"files":[{"file_id":1701,"file_name":"unsafe/../episode.srt"}]}}]}
''';
const String _subtitleText = '''1
00:00:01,000 --> 00:00:02,000
hello
''';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kongroo-opensubs-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('search requires an API key and sends normalized v1 query', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      (_) => _jsonResponse(_searchBody, HttpStatus.ok),
    );
    final Dio dio = Dio()..httpClientAdapter = adapter;
    final OpenSubtitlesClient client = OpenSubtitlesClient(
      apiKey: () async => 'test-only-placeholder',
      dio: dio,
      storageDirectory: directory,
    );
    final ExternalSubtitleResult<List<ExternalSubtitleCandidate>> result =
        await client.search(
          ExternalSubtitleQuery(
            query: ' A show ',
            languages: const ['EN'],
            imdbId: 'tt00123',
            season: 1,
            episode: 2,
          ),
        );
    expect(
      result,
      isA<ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>>(),
    );
    final ExternalSubtitleCandidate candidate =
        (result as ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>)
            .value
            .single;
    expect(candidate.fileId, 1701);
    expect(candidate.movieHashMatch, isTrue);
    expect(candidate.format, 'srt');
    expect(adapter.requests.single.uri.path, '/api/v1/subtitles');
    expect(adapter.requests.single.uri.queryParameters['languages'], 'en');
    expect(adapter.requests.single.uri.queryParameters['imdb_id'], '123');
    expect(adapter.requests.single.headers['Api-Key'], 'test-only-placeholder');
    expect(adapter.requests.single.uri.queryParameters.keys.toList(), [
      ...adapter.requests.single.uri.queryParameters.keys.toList()..sort(),
    ]);
    dio.close(force: true);

    var called = false;
    final OpenSubtitlesClient noKey = OpenSubtitlesClient(
      apiKey: () async => null,
      dio: Dio()
        ..httpClientAdapter = _FakeAdapter((_) {
          called = true;
          return _jsonResponse('{}', HttpStatus.ok);
        }),
      storageDirectory: directory,
    );
    final resultWithoutKey = await noKey.search(
      ExternalSubtitleQuery(query: 'anime'),
    );
    expect(
      resultWithoutKey,
      isA<ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>>(),
    );
    expect(
      (resultWithoutKey
              as ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>)
          .kind,
      ExternalSubtitleFailureKind.missingApiKey,
    );
    expect(called, isFalse);
  });

  test('maps empty, malformed, authentication and quota responses', () async {
    Future<ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>>
    searchStatus(int status, String body) async {
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) => _jsonResponse(body, status));
      final OpenSubtitlesClient client = OpenSubtitlesClient(
        apiKey: () async => 'test-only-placeholder',
        dio: dio,
        storageDirectory: directory,
      );
      final result = await client.search(ExternalSubtitleQuery(query: 'anime'));
      dio.close(force: true);
      return result as ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>;
    }

    final Dio emptyDio = Dio()
      ..httpClientAdapter = _FakeAdapter(
        (_) => _jsonResponse('{"data":[]}', HttpStatus.ok),
      );
    final OpenSubtitlesClient emptyClient = OpenSubtitlesClient(
      apiKey: () async => 'test-only-placeholder',
      dio: emptyDio,
      storageDirectory: directory,
    );
    expect(
      (await emptyClient.search(ExternalSubtitleQuery(query: 'anime')))
          .asSuccess
          .value,
      isEmpty,
    );
    emptyDio.close(force: true);

    expect(
      (await searchStatus(HttpStatus.unauthorized, '{}')).kind,
      ExternalSubtitleFailureKind.unauthorized,
    );
    expect(
      (await searchStatus(HttpStatus.forbidden, '{}')).kind,
      ExternalSubtitleFailureKind.forbidden,
    );
    expect(
      (await searchStatus(
        HttpStatus.tooManyRequests,
        '{"message":"Daily quota exceeded","remaining":0}',
      )).kind,
      ExternalSubtitleFailureKind.quotaExhausted,
    );
    expect(
      (await searchStatus(HttpStatus.ok, '{"data":{}}')).kind,
      ExternalSubtitleFailureKind.malformedResponse,
    );
  });

  test('uses the parent IMDb identifier for series episode searches', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      (_) => _jsonResponse('{"data":[]}', HttpStatus.ok),
    );
    final Dio dio = Dio()..httpClientAdapter = adapter;
    final OpenSubtitlesClient client = OpenSubtitlesClient(
      apiKey: () async => 'test-only-placeholder',
      dio: dio,
      storageDirectory: directory,
    );
    await client.search(
      ExternalSubtitleQuery(
        query: 'series',
        parentImdbId: 'tt00123',
        season: 1,
        episode: 2,
      ),
    );
    expect(
      adapter.requests.single.uri.queryParameters['parent_imdb_id'],
      '123',
    );
    expect(
      adapter.requests.single.uri.queryParameters.containsKey('imdb_id'),
      isFalse,
    );
    dio.close(force: true);
  });

  test('follows only an official API search redirect', () async {
    var call = 0;
    final _FakeAdapter adapter = _FakeAdapter((RequestOptions request) {
      call++;
      if (call == 1) {
        return ResponseBody.fromString(
          '',
          HttpStatus.temporaryRedirect,
          headers: {
            'location': [
              'https://vip-api.opensubtitles.com/api/v1/subtitles?query=anime',
            ],
          },
        );
      }
      return _jsonResponse(_searchBody, HttpStatus.ok);
    });
    final Dio dio = Dio()..httpClientAdapter = adapter;
    final OpenSubtitlesClient client = OpenSubtitlesClient(
      apiKey: () async => 'test-only-placeholder',
      dio: dio,
      storageDirectory: directory,
    );
    final result = await client.search(ExternalSubtitleQuery(query: 'anime'));
    expect(
      result,
      isA<ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>>(),
    );
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.uri.host, 'api.opensubtitles.com');
    expect(adapter.requests.last.uri.host, 'vip-api.opensubtitles.com');
    expect(
      adapter.requests.every(
        (RequestOptions request) =>
            request.headers['Api-Key'] == 'test-only-placeholder',
      ),
      isTrue,
    );
    dio.close(force: true);
  });

  test('rejects search redirects outside the official API origins', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      (_) => ResponseBody.fromString(
        '',
        HttpStatus.temporaryRedirect,
        headers: {
          'location': ['https://evil.example/api/v1/subtitles'],
        },
      ),
    );
    final Dio dio = Dio()..httpClientAdapter = adapter;
    final OpenSubtitlesClient client = OpenSubtitlesClient(
      apiKey: () async => 'test-only-placeholder',
      dio: dio,
      storageDirectory: directory,
    );
    final result = await client.search(ExternalSubtitleQuery(query: 'anime'));
    expect(
      (result as ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>).kind,
      ExternalSubtitleFailureKind.invalidApiRedirect,
    );
    expect(adapter.requests, hasLength(1));
    dio.close(force: true);
  });

  test(
    'maps every supported file part instead of dropping multipart results',
    () async {
      final Map<String, Object?> multipart = {
        'data': [
          {
            'id': 'multipart-1',
            'attributes': {
              'language': 'en',
              'files': [
                {'file_id': 71, 'file_name': 'movie.cd1.srt', 'cd_number': 1},
                {'file_id': 72, 'file_name': 'movie.cd2.srt', 'cd_number': 2},
              ],
            },
          },
        ],
      };
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => _jsonResponse(jsonEncode(multipart), HttpStatus.ok),
        );
      final OpenSubtitlesClient client = OpenSubtitlesClient(
        apiKey: () async => 'test-only-placeholder',
        dio: dio,
        storageDirectory: directory,
      );
      final result = await client.search(ExternalSubtitleQuery(query: 'movie'));
      final List<ExternalSubtitleCandidate> candidates =
          (result as ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>)
              .value;
      expect(candidates.map((ExternalSubtitleCandidate item) => item.fileId), [
        71,
        72,
      ]);
      expect(
        candidates.map((ExternalSubtitleCandidate item) => item.partNumber),
        [1, 2],
      );
      expect(
        candidates.every(
          (ExternalSubtitleCandidate item) => item.partCount == 2,
        ),
        isTrue,
      );
      dio.close(force: true);
    },
  );

  test(
    'preserves a valid Retry-After delay without retrying automatically',
    () async {
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => _jsonResponse(
            '{"message":"slow down"}',
            HttpStatus.tooManyRequests,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
              'retry-after': ['17'],
            },
          ),
        );
      final OpenSubtitlesClient client = OpenSubtitlesClient(
        apiKey: () async => 'test-only-placeholder',
        dio: dio,
        storageDirectory: directory,
      );
      final result = await client.search(ExternalSubtitleQuery(query: 'anime'));
      expect(
        result,
        isA<ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>>(),
      );
      final failure =
          result as ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>;
      expect(failure.kind, ExternalSubtitleFailureKind.rateLimited);
      expect(failure.retryAfter, const Duration(seconds: 17));
      expect(dio.httpClientAdapter, isA<_FakeAdapter>());
      expect((dio.httpClientAdapter as _FakeAdapter).requests, hasLength(1));
      dio.close(force: true);
    },
  );

  test(
    'preserves Retry-After when the subtitle file endpoint is rate limited',
    () async {
      final _FakeAdapter adapter = _FakeAdapter((RequestOptions request) {
        if (request.method == 'POST') {
          return _jsonResponse(
            jsonEncode({
              'link':
                  'https://www.opensubtitles.com/download/fake/subfile/a.srt',
            }),
            HttpStatus.ok,
          );
        }
        return _jsonResponse(
          '{"message":"slow down"}',
          HttpStatus.tooManyRequests,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            'retry-after': ['17'],
          },
        );
      });
      final Dio dio = Dio()..httpClientAdapter = adapter;
      final OpenSubtitlesClient client = OpenSubtitlesClient(
        apiKey: () async => 'test-only-placeholder',
        dio: dio,
        storageDirectory: directory,
      );

      final ExternalSubtitleResult<ExternalSubtitleDownload> result =
          await client.download(
            const ExternalSubtitleCandidate(
              subtitleId: 'sub-17',
              fileId: 17,
              fileName: 'episode.srt',
              language: 'en',
              format: 'srt',
            ),
          );

      expect(result, isA<ExternalSubtitleFailure<ExternalSubtitleDownload>>());
      final ExternalSubtitleFailure<ExternalSubtitleDownload> failure =
          result as ExternalSubtitleFailure<ExternalSubtitleDownload>;
      expect(failure.kind, ExternalSubtitleFailureKind.rateLimited);
      expect(failure.retryAfter, const Duration(seconds: 17));
      expect(adapter.requests.map((RequestOptions request) => request.method), [
        'POST',
        'GET',
      ]);
      dio.close(force: true);
    },
  );

  test('cancels rejected streamed download response bodies', () async {
    var canceled = false;
    var listened = false;
    final StreamController<Uint8List> body = StreamController<Uint8List>(
      onListen: () {
        listened = true;
      },
      onCancel: () {
        canceled = true;
      },
    );
    final _FakeAdapter adapter = _FakeAdapter((RequestOptions request) {
      if (request.method == 'POST') {
        return _jsonResponse(
          jsonEncode({
            'link': 'https://www.opensubtitles.com/download/fake/subfile/a.srt',
          }),
          HttpStatus.ok,
        );
      }
      return ResponseBody(body.stream, HttpStatus.serviceUnavailable);
    });
    final Dio dio = Dio()..httpClientAdapter = adapter;
    final OpenSubtitlesClient client = OpenSubtitlesClient(
      apiKey: () async => 'test-only-placeholder',
      dio: dio,
      storageDirectory: directory,
    );
    final result = await client.download(
      const ExternalSubtitleCandidate(
        subtitleId: 'sub-1',
        fileId: 17,
        fileName: 'episode.srt',
        language: 'en',
        format: 'srt',
      ),
    );
    expect(result.asFailure.kind, ExternalSubtitleFailureKind.network);
    expect(adapter.requests.map((RequestOptions item) => item.method), [
      'POST',
      'GET',
    ]);
    expect(listened, isTrue);
    expect(canceled, isTrue);
    await body.close();
    dio.close(force: true);
  });

  test(
    'downloads bounded UTF-8 SRT and never forwards API credentials',
    () async {
      final _FakeAdapter adapter = _FakeAdapter((RequestOptions request) {
        if (request.method == 'POST') {
          return _jsonResponse(
            jsonEncode({
              'link':
                  'https://www.opensubtitles.com/download/fake/subfile/a.srt',
              'file_name': '../untrusted.srt',
              'remaining': 9,
              'reset_time_utc': '2026-11-11T00:00:00Z',
            }),
            HttpStatus.ok,
          );
        }
        return ResponseBody.fromBytes(
          utf8.encode(_subtitleText),
          HttpStatus.ok,
        );
      });
      final Dio dio = Dio()..httpClientAdapter = adapter;
      final OpenSubtitlesClient client = OpenSubtitlesClient(
        apiKey: () async => 'test-only-placeholder',
        bearerToken: () async => 'test-token-placeholder',
        dio: dio,
        storageDirectory: directory,
      );
      final ExternalSubtitleCandidate candidate = ExternalSubtitleCandidate(
        subtitleId: 'sub-17',
        fileId: 1701,
        fileName: '../untrusted.srt',
        language: 'en',
        format: 'srt',
      );
      final result = await client.download(candidate);
      expect(result, isA<ExternalSubtitleSuccess<ExternalSubtitleDownload>>());
      final ExternalSubtitleDownload downloaded =
          (result as ExternalSubtitleSuccess<ExternalSubtitleDownload>).value;
      expect(downloaded.uri.scheme, 'file');
      expect(downloaded.remainingDownloads, 9);
      expect(await File.fromUri(downloaded.uri).readAsString(), _subtitleText);
      expect(adapter.requests[0].headers['Api-Key'], 'test-only-placeholder');
      expect(
        adapter.requests[0].headers['Authorization'],
        'Bearer test-token-placeholder',
      );
      expect(adapter.requests[1].headers.containsKey('Api-Key'), isFalse);
      expect(adapter.requests[1].headers.containsKey('Authorization'), isFalse);
      expect(
        downloaded.uri.pathSegments.any((String part) => part == '..'),
        isFalse,
      );
      dio.close(force: true);
    },
  );

  test(
    'a failed exclusive create preserves a pre-existing temporary file',
    () async {
      final File existingPart = File(
        '${directory.path}/opensubtitles-1701-collision.srt.part',
      );
      await existingPart.writeAsString('owned by another transfer');
      final _FakeAdapter adapter = _FakeAdapter((RequestOptions request) {
        if (request.method == 'POST') {
          return _jsonResponse(
            jsonEncode({
              'link':
                  'https://www.opensubtitles.com/download/fake/subfile/a.srt',
            }),
            HttpStatus.ok,
          );
        }
        return ResponseBody.fromBytes(
          utf8.encode(_subtitleText),
          HttpStatus.ok,
        );
      });
      final Dio dio = Dio()..httpClientAdapter = adapter;
      final OpenSubtitlesClient client = OpenSubtitlesClient(
        apiKey: () async => 'test-only-placeholder',
        dio: dio,
        storageDirectory: directory,
        fileToken: () => 'collision',
      );
      final result = await client.download(
        const ExternalSubtitleCandidate(
          subtitleId: 'sub-17',
          fileId: 1701,
          fileName: 'episode.srt',
          language: 'en',
          format: 'srt',
        ),
      );
      expect(result.asFailure.kind, ExternalSubtitleFailureKind.storageFailure);
      expect(await existingPart.readAsString(), 'owned by another transfer');
      dio.close(force: true);
    },
  );

  test('directory-provider failures map to storage failure', () async {
    final _FakeAdapter adapter = _FakeAdapter((RequestOptions request) {
      if (request.method == 'POST') {
        return _jsonResponse(
          jsonEncode({
            'link': 'https://www.opensubtitles.com/download/fake/subfile/a.srt',
          }),
          HttpStatus.ok,
        );
      }
      return ResponseBody.fromBytes(utf8.encode(_subtitleText), HttpStatus.ok);
    });
    final Dio dio = Dio()..httpClientAdapter = adapter;
    final OpenSubtitlesClient client = OpenSubtitlesClient(
      apiKey: () async => 'test-only-placeholder',
      dio: dio,
      storageDirectoryProvider: () async => throw StateError('no support path'),
    );
    final result = await client.download(
      const ExternalSubtitleCandidate(
        subtitleId: 'sub-17',
        fileId: 1701,
        fileName: 'episode.srt',
        language: 'en',
        format: 'srt',
      ),
    );
    expect(result.asFailure.kind, ExternalSubtitleFailureKind.storageFailure);
    dio.close(force: true);
  });

  test(
    'rejects untrusted URLs, unsupported formats, oversized and corrupt data',
    () async {
      Future<ExternalSubtitleResult<ExternalSubtitleDownload>> downloadWith({
        String link = 'https://www.opensubtitles.com/download/x/subfile/a.srt',
        List<int> bytes = const [],
        String format = 'srt',
        int maxBytes = 1024,
      }) async {
        final _FakeAdapter adapter = _FakeAdapter((RequestOptions request) {
          if (request.method == 'POST') {
            return _jsonResponse(jsonEncode({'link': link}), HttpStatus.ok);
          }
          return ResponseBody.fromBytes(bytes, HttpStatus.ok);
        });
        final Dio dio = Dio()..httpClientAdapter = adapter;
        final OpenSubtitlesClient client = OpenSubtitlesClient(
          apiKey: () async => 'test-only-placeholder',
          dio: dio,
          storageDirectory: directory,
          maxDownloadBytes: maxBytes,
        );
        final result = await client.download(
          ExternalSubtitleCandidate(
            subtitleId: 'id',
            fileId: 5,
            fileName: 'name.$format',
            language: 'en',
            format: format,
          ),
        );
        dio.close(force: true);
        return result;
      }

      expect(
        (await downloadWith(link: 'https://evil.example/download/x/a.srt'))
            .asFailure
            .kind,
        ExternalSubtitleFailureKind.invalidDownloadUrl,
      );
      expect(
        (await downloadWith(format: 'zip')).asFailure.kind,
        ExternalSubtitleFailureKind.unsupportedFormat,
      );
      expect(
        (await downloadWith(bytes: List<int>.filled(1025, 65))).asFailure.kind,
        ExternalSubtitleFailureKind.tooLarge,
      );
      expect(
        (await downloadWith(bytes: utf8.encode('not a subtitle')))
            .asFailure
            .kind,
        ExternalSubtitleFailureKind.corruptFile,
      );
    },
  );
}

extension _ResultAccess<T> on ExternalSubtitleResult<T> {
  ExternalSubtitleSuccess<T> get asSuccess =>
      this as ExternalSubtitleSuccess<T>;
  ExternalSubtitleFailure<T> get asFailure =>
      this as ExternalSubtitleFailure<T>;
}
