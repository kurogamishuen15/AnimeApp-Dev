import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../domain/player/providers/anime_identity.dart';
import '../../../../domain/player/providers/episode_source.dart';
import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../hosts/direct_media_host_resolver.dart';
import 'animesdigital_html_parser.dart';

/// Public-page adapter for the AnimesDigital episode index.
///
/// It supports only the first public player, whose page publishes a direct HLS
/// manifest. It does not execute JavaScript, open embeds, send cookies, or
/// negotiate access controls. Host resolution and playback remain in their
/// existing modules.
final class AnimesDigitalPlaybackProvider extends EpisodeSourceAdapter {
  AnimesDigitalPlaybackProvider({
    Dio? dio,
    String baseUrl = 'https://animesdigital.org/',
    AnimesDigitalHtmlParser? parser,
    Duration requestTimeout = const Duration(seconds: 20),
  }) : requestTimeout = _validatedRequestTimeout(requestTimeout),
       _dio = dio ?? _createDio(),
       _ownsDio = dio == null,
       _baseUri = _validatedBaseUri(baseUrl),
       parser = parser ?? AnimesDigitalHtmlParser();

  static final PlaybackProviderId providerId = PlaybackProviderId(
    'animesdigital',
  );
  static const int maxCatalogPages = 32;
  static const int maxHtmlBytes = 2 * 1024 * 1024;
  static const int maxTotalCatalogBytes = 16 * 1024 * 1024;
  static const int maxRedirects = 3;

  final Dio _dio;
  final bool _ownsDio;
  final Uri _baseUri;
  final AnimesDigitalHtmlParser parser;
  final Duration requestTimeout;
  bool _closed = false;

  @override
  PlaybackProviderId get id => providerId;

  @override
  String get adapterVersion => '1.0.0';

  @override
  Set<PlaybackProviderCapability> get capabilities =>
      const <PlaybackProviderCapability>{
        PlaybackProviderCapability.episodeSources,
      };

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (_closed) return _unavailable<List<SourceAnimeMatch>>();
    if (cancellation.isCancelled) return _cancelled<List<SourceAnimeMatch>>();
    final List<String> titles = identity.titles.take(3).toList(growable: false);
    if (titles.isEmpty) {
      return const PlaybackProviderFailed<List<SourceAnimeMatch>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.missingId),
      );
    }

    final _OperationDeadline deadline = _OperationDeadline(requestTimeout);
    final Map<String, SourceAnimeMatch> matches = {};
    PlaybackProviderFailure? lastFailure;
    for (final String title in titles) {
      if (cancellation.isCancelled) {
        return _cancelled<List<SourceAnimeMatch>>();
      }
      final Uri searchUri = _baseUri.replace(
        queryParameters: <String, String>{'s': title},
      );
      final PlaybackProviderResult<String> page = await _getHtml(
        searchUri,
        cancellation,
        deadline: deadline,
      );
      if (page case PlaybackProviderFailed<String>(:final failure)) {
        lastFailure = failure;
        continue;
      }
      if (page is! PlaybackProviderSuccess<String>) continue;
      for (final AnimesDigitalSearchResult result in parser.searchResults(
        page.value,
        pageUri: searchUri,
      )) {
        if (!_sameTitle(result.title, identity.titles)) continue;
        matches.putIfAbsent(
          result.sourceAnimeId,
          () => SourceAnimeMatch(
            providerId: id,
            sourceAnimeId: result.sourceAnimeId,
            title: result.title,
            requestedIdentity: identity,
            evidence: AnimeMatchEvidence.exactTitle,
            adapterVersion: adapterVersion,
          ),
        );
        if (matches.length >= 10) break;
      }
      if (matches.length >= 10) break;
    }
    if (cancellation.isCancelled) return _cancelled<List<SourceAnimeMatch>>();
    if (matches.isEmpty && lastFailure != null) {
      return PlaybackProviderFailed<List<SourceAnimeMatch>>(lastFailure);
    }
    if (matches.isEmpty) return const PlaybackProviderEmpty();
    return PlaybackProviderSuccess<List<SourceAnimeMatch>>(
      List.unmodifiable(matches.values),
    );
  }

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) => _readEpisodes(match, cancellation);

  @override
  Future<PlaybackProviderResult<EpisodeRef>> findEpisode(
    SourceAnimeMatch match, {
    required int episodeNumber,
    required PlaybackCancellationToken cancellation,
  }) async {
    if (episodeNumber < 1) {
      return const PlaybackProviderFailed<EpisodeRef>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
    final PlaybackProviderResult<List<EpisodeRef>> result = await _readEpisodes(
      match,
      cancellation,
      targetEpisode: episodeNumber,
    );
    return switch (result) {
      PlaybackProviderSuccess<List<EpisodeRef>>(:final value) =>
        value.isEmpty
            ? const PlaybackProviderEmpty<EpisodeRef>()
            : PlaybackProviderSuccess<EpisodeRef>(value.first),
      PlaybackProviderEmpty<List<EpisodeRef>>() =>
        const PlaybackProviderEmpty<EpisodeRef>(),
      PlaybackProviderFailed<List<EpisodeRef>>(:final failure) =>
        PlaybackProviderFailed<EpisodeRef>(failure),
      PlaybackProviderUnsupported<List<EpisodeRef>>(:final capability) =>
        PlaybackProviderUnsupported<EpisodeRef>(capability),
    };
  }

  Future<PlaybackProviderResult<List<EpisodeRef>>> _readEpisodes(
    SourceAnimeMatch match,
    PlaybackCancellationToken cancellation, {
    int? targetEpisode,
  }) async {
    if (_closed) return _unavailable<List<EpisodeRef>>();
    if (match.providerId != id || !_isAnimePath(match.sourceAnimeId)) {
      return const PlaybackProviderFailed<List<EpisodeRef>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
    if (cancellation.isCancelled) return _cancelled<List<EpisodeRef>>();

    final _OperationDeadline deadline = _OperationDeadline(requestTimeout);
    final Uri animeUri = _baseUri.resolve(match.sourceAnimeId);
    final PlaybackProviderResult<String> firstPage = await _getHtml(
      animeUri,
      cancellation,
      deadline: deadline,
    );
    if (firstPage case PlaybackProviderFailed<String>(:final failure)) {
      return PlaybackProviderFailed<List<EpisodeRef>>(failure);
    }
    if (firstPage is! PlaybackProviderSuccess<String>) {
      return const PlaybackProviderEmpty<List<EpisodeRef>>();
    }

    int bytesRead = utf8.encode(firstPage.value).length;
    final AnimesDigitalEpisodePage parsedFirst = parser.episodePage(
      firstPage.value,
      pageUri: animeUri,
    );
    final Map<int, EpisodeRef> episodes = {};
    void add(List<AnimesDigitalEpisodeLink> links) {
      for (final AnimesDigitalEpisodeLink link in links) {
        episodes.putIfAbsent(
          link.number,
          () => EpisodeRef(
            anime: match,
            episodeId: link.episodeId,
            episodeNumber: link.number,
            declaredLanguage: 'unknown',
            mappingEvidence: 'Public AnimesDigital episode link and number',
          ),
        );
      }
    }

    add(parsedFirst.episodes);
    if (targetEpisode != null && episodes.containsKey(targetEpisode)) {
      return PlaybackProviderSuccess<List<EpisodeRef>>(
        List<EpisodeRef>.unmodifiable(<EpisodeRef>[episodes[targetEpisode]!]),
      );
    }

    if (parsedFirst.pageCount > maxCatalogPages && targetEpisode == null) {
      return const PlaybackProviderFailed<List<EpisodeRef>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
    final int pageCount = parsedFirst.pageCount.clamp(1, maxCatalogPages);
    for (int pageNumber = 2; pageNumber <= pageCount; pageNumber++) {
      if (cancellation.isCancelled) return _cancelled<List<EpisodeRef>>();
      final Uri pageUri = _catalogPageUri(parsedFirst.pageRoot, pageNumber);
      final PlaybackProviderResult<String> page = await _getHtml(
        pageUri,
        cancellation,
        deadline: deadline,
      );
      if (page case PlaybackProviderFailed<String>(:final failure)) {
        return PlaybackProviderFailed<List<EpisodeRef>>(failure);
      }
      if (page is! PlaybackProviderSuccess<String>) continue;
      bytesRead += utf8.encode(page.value).length;
      if (bytesRead > maxTotalCatalogBytes) {
        return const PlaybackProviderFailed<List<EpisodeRef>>(
          PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
        );
      }
      add(parser.episodePage(page.value, pageUri: pageUri).episodes);
      if (targetEpisode != null && episodes.containsKey(targetEpisode)) {
        return PlaybackProviderSuccess<List<EpisodeRef>>(
          List<EpisodeRef>.unmodifiable(<EpisodeRef>[episodes[targetEpisode]!]),
        );
      }
    }

    final List<EpisodeRef> ordered = episodes.values.toList()
      ..sort((EpisodeRef a, EpisodeRef b) {
        final int byNumber = a.episodeNumber.compareTo(b.episodeNumber);
        return byNumber != 0 ? byNumber : a.episodeId.compareTo(b.episodeId);
      });
    if (ordered.isEmpty) return const PlaybackProviderEmpty();
    if (targetEpisode != null) {
      if (parsedFirst.pageCount > maxCatalogPages) {
        return const PlaybackProviderFailed<List<EpisodeRef>>(
          PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
        );
      }
      return const PlaybackProviderEmpty<List<EpisodeRef>>();
    }
    return PlaybackProviderSuccess<List<EpisodeRef>>(
      List<EpisodeRef>.unmodifiable(ordered),
    );
  }

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (_closed) return _unavailable<List<PlaybackSource>>();
    if (cancellation.isCancelled) return _cancelled<List<PlaybackSource>>();
    if (episode.providerId != id) {
      return const PlaybackProviderFailed<List<PlaybackSource>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
    final Uri episodeUri = Uri.tryParse(episode.episodeId) ?? Uri();
    if (!_isSameOrigin(episodeUri) || !episodeUri.path.startsWith('/video/')) {
      return const PlaybackProviderFailed<List<PlaybackSource>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
    final _OperationDeadline deadline = _OperationDeadline(requestTimeout);
    final PlaybackProviderResult<String> page = await _getHtml(
      episodeUri,
      cancellation,
      deadline: deadline,
    );
    if (page case PlaybackProviderFailed<String>(:final failure)) {
      return PlaybackProviderFailed<List<PlaybackSource>>(failure);
    }
    if (page is! PlaybackProviderSuccess<String>) {
      return const PlaybackProviderEmpty<List<PlaybackSource>>();
    }
    final Uri? media = parser.playerOneHls(page.value, episodeUri: episodeUri);
    if (media == null) {
      return const PlaybackProviderFailed<List<PlaybackSource>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.unsupportedEmbed),
      );
    }

    final PlaybackEpisode playbackEpisode = PlaybackEpisode.fromIdentity(
      episode.anime.requestedIdentity,
      episodeNumber: episode.episodeNumber,
    );
    return PlaybackProviderSuccess<List<PlaybackSource>>(
      List<PlaybackSource>.unmodifiable(<PlaybackSource>[
        PlaybackSource(
          id: 'animesdigital-episode-${episode.episodeNumber}',
          providerId: id,
          episode: playbackEpisode,
          language: 'unknown',
          quality: 'Auto',
          priority: 100,
          servers: <SourceCandidate>[
            SourceCandidate(
              id: 'anivideo-hls',
              endpoint: media,
              hostId: DirectMediaHostResolver.stableHostId,
              priority: 100,
              kind: PlaybackCandidateKind.media,
              declaredLanguage: 'unknown',
              sourceEpisodeId: episode.episodeId,
              provenance: 'AnimesDigital public player-one HLS link',
              requestHeaders: PlaybackRequestHeaders(<String, String>{
                'Referer': 'https://api.anivideo.net/',
              }),
            ),
          ],
        ),
      ]),
    );
  }

  Future<PlaybackProviderResult<String>> _getHtml(
    Uri initialUri,
    PlaybackCancellationToken cancellation, {
    required _OperationDeadline deadline,
  }) async {
    if (cancellation.isCancelled) return _cancelled<String>();
    if (!_isSameOrigin(initialUri) || initialUri.scheme != _baseUri.scheme) {
      return const PlaybackProviderFailed<String>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.blocked),
      );
    }
    Uri uri = initialUri;
    final Duration remaining = deadline.remaining;
    if (remaining <= Duration.zero) {
      return const PlaybackProviderFailed<String>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.timeout),
      );
    }
    final CancelToken cancelToken = CancelToken();
    var deadlineExceeded = false;
    final Timer deadlineTimer = Timer(remaining, () {
      deadlineExceeded = true;
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Provider operation deadline exceeded');
      }
    });
    final void Function() unregister = cancellation.addCancelListener(() {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Playback request cancelled');
      }
    });
    try {
      for (int redirects = 0; redirects <= maxRedirects; redirects++) {
        if (cancellation.isCancelled) return _cancelled<String>();
        final Response<ResponseBody> response = await _dio.get<ResponseBody>(
          uri.toString(),
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
            maxRedirects: 0,
            receiveDataWhenStatusError: false,
            headers: const <String, String>{
              'Accept': 'text/html,application/xhtml+xml',
            },
            validateStatus: (int? status) => status != null,
          ),
        );
        final int status = response.statusCode ?? 0;
        if (_isRedirect(status)) {
          await _discardResponseBody(response.data);
          final String? location = response.headers.value('location');
          if (location == null || redirects == maxRedirects) {
            return const PlaybackProviderFailed<String>(
              PlaybackProviderFailure(
                PlaybackProviderFailureKind.invalidResponse,
              ),
            );
          }
          final Uri? next = Uri.tryParse(location);
          if (next == null) {
            return const PlaybackProviderFailed<String>(
              PlaybackProviderFailure(
                PlaybackProviderFailureKind.invalidResponse,
              ),
            );
          }
          uri = uri.resolveUri(next);
          if (!_isSameOrigin(uri) || uri.scheme != _baseUri.scheme) {
            return const PlaybackProviderFailed<String>(
              PlaybackProviderFailure(PlaybackProviderFailureKind.blocked),
            );
          }
          continue;
        }
        if (status < 200 || status >= 300) {
          await _discardResponseBody(response.data);
          return PlaybackProviderFailed<String>(_failureForStatus(status));
        }
        final String? mime = response.headers.value('content-type');
        if (mime != null &&
            !mime.toLowerCase().contains('text/html') &&
            !mime.toLowerCase().contains('application/xhtml+xml')) {
          await _discardResponseBody(response.data);
          return const PlaybackProviderFailed<String>(
            PlaybackProviderFailure(
              PlaybackProviderFailureKind.invalidResponse,
            ),
          );
        }
        final int? contentLength = int.tryParse(
          response.headers.value('content-length') ?? '',
        );
        if (contentLength != null && contentLength > maxHtmlBytes) {
          await _discardResponseBody(response.data);
          return const PlaybackProviderFailed<String>(
            PlaybackProviderFailure(
              PlaybackProviderFailureKind.invalidResponse,
            ),
          );
        }
        final ResponseBody? body = response.data;
        if (body == null) {
          return const PlaybackProviderFailed<String>(
            PlaybackProviderFailure(
              PlaybackProviderFailureKind.invalidResponse,
            ),
          );
        }
        final BytesBuilder bytes = BytesBuilder(copy: false);
        int byteCount = 0;
        bool tooLarge = false;
        await for (final List<int> chunk in body.stream.timeout(
          const Duration(seconds: 12),
        )) {
          if (cancellation.isCancelled) return _cancelled<String>();
          byteCount += chunk.length;
          if (byteCount > maxHtmlBytes) {
            tooLarge = true;
            break;
          }
          bytes.add(chunk);
        }
        if (tooLarge || byteCount == 0) {
          return const PlaybackProviderFailed<String>(
            PlaybackProviderFailure(
              PlaybackProviderFailureKind.invalidResponse,
            ),
          );
        }
        return PlaybackProviderSuccess<String>(
          utf8.decode(bytes.takeBytes(), allowMalformed: true),
        );
      }
      return const PlaybackProviderFailed<String>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    } on DioException catch (error) {
      if (cancellation.isCancelled) {
        return _cancelled<String>();
      }
      if (deadlineExceeded) {
        return const PlaybackProviderFailed<String>(
          PlaybackProviderFailure(PlaybackProviderFailureKind.timeout),
        );
      }
      return PlaybackProviderFailed<String>(_failureForDio(error));
    } on TimeoutException {
      return const PlaybackProviderFailed<String>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.timeout),
      );
    } on Object {
      return cancellation.isCancelled
          ? _cancelled<String>()
          : const PlaybackProviderFailed<String>(
              PlaybackProviderFailure(PlaybackProviderFailureKind.network),
            );
    } finally {
      deadlineTimer.cancel();
      unregister();
    }
  }

  Future<void> _discardResponseBody(ResponseBody? body) async {
    if (body == null) return;
    final subscription = body.stream.listen((_) {});
    await subscription.cancel();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsDio) _dio.close(force: true);
  }

  static Dio _createDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      maxRedirects: 0,
      responseType: ResponseType.stream,
    ),
  );

  static Uri _validatedBaseUri(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !_isAllowedBaseScheme(uri)) {
      throw ArgumentError.value(value, 'baseUrl', 'Invalid public base URL.');
    }
    return uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }

  static Duration _validatedRequestTimeout(Duration value) {
    if (value <= Duration.zero || value > const Duration(minutes: 1)) {
      throw ArgumentError.value(
        value,
        'requestTimeout',
        'Request timeout must be greater than zero and at most one minute.',
      );
    }
    return value;
  }

  static bool _isAllowedBaseScheme(Uri uri) {
    if (uri.scheme == 'https' && uri.port == 443) return true;
    if (uri.scheme != 'http') return false;
    final String host = uri.host.toLowerCase();
    final InternetAddress? address = InternetAddress.tryParse(host);
    return host == 'localhost' || (address != null && address.isLoopback);
  }

  bool _isSameOrigin(Uri uri) =>
      uri.scheme == _baseUri.scheme &&
      uri.host.toLowerCase() == _baseUri.host.toLowerCase() &&
      uri.port == _baseUri.port &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment;

  static bool _isAnimePath(String path) =>
      path.startsWith('/anime/a/') &&
      !path.contains('..') &&
      !path.contains('\\') &&
      !path.contains('?') &&
      !path.contains('#');

  static Uri _catalogPageUri(Uri root, int pageNumber) => Uri(
    scheme: root.scheme,
    host: root.host,
    port: root.port,
    path: '${root.path.replaceFirst(RegExp(r'/+$'), '')}/page/$pageNumber/',
  );

  static bool _sameTitle(String left, Iterable<String> right) {
    final String normalized = _normalizeTitle(left);
    return normalized.isNotEmpty &&
        right.any((String title) => _normalizeTitle(title) == normalized);
  }

  static String _normalizeTitle(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  static bool _isRedirect(int status) =>
      status == 301 ||
      status == 302 ||
      status == 303 ||
      status == 307 ||
      status == 308;

  static PlaybackProviderFailure _failureForStatus(int status) {
    if (status == 401) {
      return const PlaybackProviderFailure(
        PlaybackProviderFailureKind.unauthorized,
      );
    }
    if (status == 403) {
      return const PlaybackProviderFailure(
        PlaybackProviderFailureKind.forbidden,
      );
    }
    if (status == 404) {
      return const PlaybackProviderFailure(
        PlaybackProviderFailureKind.notFound,
      );
    }
    if (status == 429) {
      return const PlaybackProviderFailure(
        PlaybackProviderFailureKind.rateLimited,
      );
    }
    if (status >= 500) {
      return const PlaybackProviderFailure(
        PlaybackProviderFailureKind.unavailable,
      );
    }
    return const PlaybackProviderFailure(
      PlaybackProviderFailureKind.invalidResponse,
    );
  }

  static PlaybackProviderFailure _failureForDio(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const PlaybackProviderFailure(PlaybackProviderFailureKind.timeout);
    }
    if (error.type == DioExceptionType.badResponse) {
      return _failureForStatus(error.response?.statusCode ?? 0);
    }
    if (error.type == DioExceptionType.connectionError) {
      return const PlaybackProviderFailure(PlaybackProviderFailureKind.network);
    }
    return const PlaybackProviderFailure(
      PlaybackProviderFailureKind.unavailable,
    );
  }

  static PlaybackProviderFailed<T> _cancelled<T>() => PlaybackProviderFailed<T>(
    const PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
  );

  static PlaybackProviderFailed<T> _unavailable<T>() =>
      PlaybackProviderFailed<T>(
        const PlaybackProviderFailure(PlaybackProviderFailureKind.unavailable),
      );
}

/// One monotonic timeout budget shared by every HTTP request in a provider
/// operation, so paginated catalogs cannot multiply the configured timeout.
final class _OperationDeadline {
  _OperationDeadline(this.timeout) : _stopwatch = Stopwatch()..start();

  final Duration timeout;
  final Stopwatch _stopwatch;

  Duration get remaining => timeout - _stopwatch.elapsed;
}
