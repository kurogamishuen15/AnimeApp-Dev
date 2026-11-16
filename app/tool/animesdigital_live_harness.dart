import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/data/player/providers/animesdigital/animesdigital_playback_provider.dart';
import 'package:anime_app/data/player/providers/hosts/direct_media_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

/// Live, bounded probe for the real public provider chain.
///
/// It deliberately never writes or prints the potentially short-lived media
/// URI. This is a source/manifest check; libmpv/display verification is done by
/// the app's existing player route.
Future<void> main(List<String> arguments) async {
  final int episodeNumber = arguments.isEmpty
      ? 1180
      : int.tryParse(arguments.single) ?? 0;
  if (episodeNumber < 1 || arguments.length > 1) {
    stderr.writeln(
      'Usage: dart run tool/animesdigital_live_harness.dart [episode]',
    );
    exitCode = 64;
    return;
  }

  final AnimesDigitalPlaybackProvider provider =
      AnimesDigitalPlaybackProvider();
  final PlaybackProviderManager manager = PlaybackProviderManager(
    providers: <PlaybackProviderRegistration>[
      PlaybackProviderRegistration(
        provider: provider,
        priority: 100,
        cacheTtl: Duration.zero,
        version: provider.adapterVersion,
      ),
    ],
    videoHostResolvers: <PlaybackVideoHostResolverRegistration>[
      PlaybackVideoHostResolverRegistration(
        resolver: DirectMediaHostResolver(),
        version: '1.0.0',
      ),
    ],
    clock: DateTime.now,
  );

  final PlaybackEpisode episode = PlaybackEpisode(
    animeId: AnimeId('animesdigital-live-one-piece'),
    episodeNumber: episodeNumber,
    animeTitles: const <String>['One Piece'],
  );
  final Dio manifestClient = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.stream,
      maxRedirects: 0,
    ),
  );

  try {
    final PlaybackProviderResult<PlayableSource> result = await manager
        .resolveBestStream(episode, cancellation: PlaybackCancellationToken());
    if (result is! PlaybackProviderSuccess<PlayableSource>) {
      final String failure = result is PlaybackProviderFailed<PlayableSource>
          ? result.failure.kind.name
          : result.runtimeType.toString();
      stderr.writeln('source_resolution=failed kind=$failure');
      exitCode = 1;
      return;
    }

    final PlayableSource source = result.value;
    if (Platform.environment['KONGROO_LIVE_FFPROBE'] == '1') {
      await _probeWithFfprobe(source);
    }
    final Response<ResponseBody> response = await manifestClient
        .get<ResponseBody>(
          source.uri.toString(),
          options: Options(
            followRedirects: false,
            validateStatus: (int? status) => status != null,
            headers: source.httpHeaders.values,
          ),
        );
    final int status = response.statusCode ?? 0;
    final String contentType =
        response.headers.value('content-type')?.split(';').first.trim() ??
        'unknown';
    if (status != HttpStatus.ok || response.data == null) {
      stderr.writeln(
        'source_resolution=ok provider=animesdigital episode=$episodeNumber '
        'host=${source.uri.host} format=${source.format.name} '
        'manifest_status=$status content_type=$contentType',
      );
      exitCode = 1;
      return;
    }

    final BytesBuilder bytes = BytesBuilder(copy: false);
    int length = 0;
    bool tooLarge = false;
    await for (final List<int> chunk in response.data!.stream.timeout(
      const Duration(seconds: 15),
    )) {
      length += chunk.length;
      if (length > 256 * 1024) {
        tooLarge = true;
        break;
      }
      bytes.add(chunk);
    }
    final String manifest = utf8.decode(
      bytes.takeBytes(),
      allowMalformed: true,
    );
    if (tooLarge || !manifest.startsWith('#EXTM3U')) {
      stderr.writeln(
        'source_resolution=ok provider=animesdigital episode=$episodeNumber '
        'host=${source.uri.host} manifest_status=$status '
        'valid_hls=false bytes=$length',
      );
      exitCode = 1;
      return;
    }
    final int segments = RegExp(
      r'^#EXTINF:',
      multiLine: true,
    ).allMatches(manifest).length;
    final String manifestReferenceSummary = summarizeHlsReferences(
      source.uri,
      manifest,
    );
    String? firstSegment;
    for (final String line in manifest.split('\n')) {
      final String value = line.trim();
      if (value.isNotEmpty && !value.startsWith('#')) {
        firstSegment = value;
        break;
      }
    }
    if (firstSegment == null) {
      stderr.writeln(
        'source_resolution=ok provider=animesdigital episode=$episodeNumber '
        'host=${source.uri.host} valid_hls=true segments=0',
      );
      exitCode = 1;
      return;
    }
    final Uri segmentUri = source.uri.resolve(firstSegment);
    if (segmentUri.scheme != 'https' || segmentUri.host.isEmpty) {
      stderr.writeln('segment_probe=blocked reason=non_https');
      exitCode = 1;
      return;
    }
    final Response<ResponseBody> segmentResponse = await manifestClient
        .get<ResponseBody>(
          segmentUri.toString(),
          options: Options(
            followRedirects: false,
            validateStatus: (int? value) => value != null,
            headers: source.httpHeaders.values,
          ),
        );
    int segmentBytesRead = 0;
    final BytesBuilder segmentPrefix = BytesBuilder(copy: false);
    final ResponseBody? segmentBody = segmentResponse.data;
    if (segmentBody != null) {
      await for (final List<int> chunk in segmentBody.stream.timeout(
        const Duration(seconds: 15),
      )) {
        segmentBytesRead += chunk.length;
        if (segmentPrefix.length < 16) {
          segmentPrefix.add(
            chunk.take(16 - segmentPrefix.length).toList(growable: false),
          );
        }
        if (segmentBytesRead >= 64 * 1024) break;
      }
    }
    final List<int> prefix = segmentPrefix.takeBytes();
    final String segmentType =
        segmentResponse.headers
            .value('content-type')
            ?.split(';')
            .first
            .trim() ??
        'unknown';
    final String prefixText = String.fromCharCodes(prefix).toLowerCase();
    final bool htmlLike =
        prefixText.trimLeft().startsWith('<!doctype') ||
        prefixText.trimLeft().startsWith('<html');
    final bool transportStream = prefix.isNotEmpty && prefix.first == 0x47;
    final bool fragmentedMp4 =
        prefix.length >= 8 &&
        String.fromCharCodes(prefix.sublist(4, 8)) == 'ftyp';
    stdout.writeln(
      'source_resolution=ok provider=animesdigital episode=$episodeNumber '
      'host=${source.uri.host} format=${source.format.name} '
      'manifest_status=$status content_type=$contentType bytes=$length '
      'valid_hls=true segments=$segments '
      'manifest_references={$manifestReferenceSummary} '
      'first_segment_host=${segmentUri.host} '
      'first_segment_status=${segmentResponse.statusCode ?? 0} '
      'first_segment_bytes_read=$segmentBytesRead '
      'first_segment_type=$segmentType html_like=$htmlLike '
      'ts_signature=$transportStream fmp4_signature=$fragmentedMp4 '
      'referer=${source.httpHeaders.isEmpty ? 'absent' : 'present'} '
      'media_url_redacted=true',
    );
  } on Object catch (error) {
    stderr.writeln('live_probe=failed error_type=${error.runtimeType}');
    exitCode = 1;
  } finally {
    manifestClient.close(force: true);
    provider.close();
  }
}

Future<void> _probeWithFfprobe(PlayableSource source) async {
  try {
    final String headers = source.httpHeaders.values.entries
        .map(
          (MapEntry<String, String> entry) =>
              '${entry.key}: ${entry.value}\r\n',
        )
        .join();
    final ProcessResult result = await Process.run(
      'ffprobe',
      <String>[
        '-v',
        'error',
        '-rw_timeout',
        '15000000',
        if (headers.isNotEmpty) ...<String>['-headers', headers],
        '-show_entries',
        'stream=codec_type,codec_name,width,height:format=duration',
        '-of',
        'json',
        source.uri.toString(),
      ],
      runInShell: false,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    ).timeout(const Duration(seconds: 20));
    if (result.exitCode != 0 || result.stdout is! String) {
      final String diagnostic = result.stderr is String
          ? redactLiveProbeDiagnostic(result.stderr as String)
          : '';
      stdout.writeln(
        'ffprobe=failed exit=${result.exitCode} '
        'detail=${diagnostic.isEmpty ? 'unavailable' : diagnostic} '
        'url_redacted=true',
      );
      return;
    }
    final Object? decoded = jsonDecode(result.stdout as String);
    if (decoded is! Map<String, dynamic>) {
      stdout.writeln('ffprobe=invalid_output url_redacted=true');
      return;
    }
    final List<Object?> rawStreams = decoded['streams'] is List<Object?>
        ? decoded['streams'] as List<Object?>
        : const <Object?>[];
    final List<String> streams = rawStreams
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> stream) {
          final String type = stream['codec_type'] is String
              ? stream['codec_type']! as String
              : 'unknown';
          final String codec = stream['codec_name'] is String
              ? stream['codec_name']! as String
              : 'unknown';
          final Object? width = stream['width'];
          final Object? height = stream['height'];
          final String dimensions = width is int && height is int
              ? ':${width}x$height'
              : '';
          return '$type:$codec$dimensions';
        })
        .toList(growable: false);
    final Object? rawFormat = decoded['format'];
    final Object? duration = rawFormat is Map<String, dynamic>
        ? rawFormat['duration']
        : null;
    stdout.writeln(
      'ffprobe=complete exit=0 duration=${duration is String ? duration : 'unknown'} '
      'streams=${streams.isEmpty ? 'none' : streams.join(',')} url_redacted=true',
    );
  } on TimeoutException {
    stdout.writeln('ffprobe=timeout url_redacted=true');
  } on ProcessException {
    stdout.writeln('ffprobe=unavailable url_redacted=true');
  } on Object catch (error) {
    stdout.writeln(
      'ffprobe=failed error_type=${error.runtimeType} url_redacted=true',
    );
  }
}

String redactLiveProbeDiagnostic(String value) {
  final String oneLine = value
      .replaceAllMapped(RegExp(r'https?://[^\s"<>]+'), (Match match) {
        final String rawUri = match
            .group(0)!
            .replaceFirst(RegExp(r'[),.;:]+$'), '');
        final String extension = _uriPathExtension(Uri.tryParse(rawUri));
        return '<redacted-uri extension=$extension>';
      })
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .trim();
  return oneLine.length <= 300 ? oneLine : '${oneLine.substring(0, 300)}…';
}

String _uriPathExtension(Uri? uri) {
  final List<String> segments = uri?.pathSegments ?? const <String>[];
  if (segments.isEmpty) return 'none';
  final String name = segments.last;
  final int dot = name.lastIndexOf('.');
  return dot < 0 || dot == name.length - 1
      ? 'none'
      : name.substring(dot + 1).toLowerCase();
}

String summarizeHlsReferences(Uri base, String manifest) {
  final Map<String, int> references = <String, int>{};
  int nonHttpsCount = 0;
  int crossOriginCount = 0;
  final RegExp uriAttribute = RegExp(r'URI="([^"]+)"');
  String? pendingUriTag;

  for (final String rawLine in manifest.split('\n')) {
    final String line = rawLine.trim();
    if (line.isEmpty) continue;
    final bool isTag = line.startsWith('#');
    final String tag;
    final Iterable<String> values;
    if (isTag) {
      tag = line.substring(1).split(':').first;
      values = uriAttribute
          .allMatches(line)
          .map((Match match) => match.group(1)!);
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        pendingUriTag = 'variant';
      }
    } else {
      tag = pendingUriTag ?? 'segment';
      pendingUriTag = null;
      values = <String>[line];
    }

    for (final String value in values) {
      final Uri? uri = Uri.tryParse(value);
      if (uri == null) continue;
      final Uri resolved = base.resolveUri(uri);
      if (resolved.scheme != 'https') nonHttpsCount++;
      if (!_hasSameOrigin(resolved, base)) crossOriginCount++;
      final String key = '$tag:${_uriPathExtension(resolved)}';
      references.update(key, (int count) => count + 1, ifAbsent: () => 1);
    }
  }

  final List<String> entries = references.keys.toList()..sort();
  final String counts = entries
      .map((String key) => '$key=${references[key]}')
      .join(',');
  return '$counts;non_https=$nonHttpsCount;cross_origin=$crossOriginCount';
}

bool _hasSameOrigin(Uri left, Uri right) =>
    left.scheme == right.scheme &&
    left.host.toLowerCase() == right.host.toLowerCase() &&
    left.port == right.port;
