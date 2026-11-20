// OC-07 proxy diagnostics (run: dart run, from app/).
// Resolves episode 9, publishes through the loopback proxy, then fetches the
// loopback master and one rewritten child with a Range to prove the proxy path
// independently of libmpv.
import 'dart:convert';
import 'dart:io';

import 'package:anime_app/data/player/providers/miruro/miruro_catalog_api.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_parser.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_playback_provider.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_media_proxy.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

Future<void> main(List<String> args) async {
  final int episode = args.isNotEmpty ? int.tryParse(args[0]) ?? 9 : 9;
  final MiruroMediaProxy proxy = await MiruroMediaProxy.start();
  final Dio client = Dio();
  final MiruroCatalogPlaybackProvider provider = MiruroCatalogPlaybackProvider(
    MiruroCatalogApi(
      PublicPlaybackHttp(
        client,
        miruroCatalogOrigins.toSet(),
        enforceCooldown: false,
        maxConcurrent: 2,
      ),
    ),
    parser: MiruroCatalogParser(proxy: proxy),
  );
  try {
    final sources = await provider.findSources(
      PlaybackEpisode(
        animeId: AnimeId('oc07-proxy'),
        episodeNumber: episode,
        externalAnimeIds: <ExternalAnimeId>[
          ExternalAnimeId(
            providerId: MetadataProviderId('anilist'),
            value: '100240',
          ),
        ],
        animeTitles: const <String>['Tokyo Ghoul:re'],
      ),
      cancellation: PlaybackCancellationToken(),
    );
    if (sources is! PlaybackProviderSuccess<List<PlaybackSource>>) {
      stdout.writeln('SOURCES=$sources');
      return;
    }
    final List<SourceCandidate> candidates = <SourceCandidate>[
      for (final PlaybackSource source in sources.value) ...source.servers,
    ];
    stdout.writeln('PROXY=${proxy.origin} SERVERS=${candidates.length}');
    for (final SourceCandidate candidate in candidates) {
      stdout.writeln(
        '  ${candidate.id} -> ${candidate.endpoint} '
        'headers=${candidate.requestHeaders.values}',
      );
    }

    for (final SourceCandidate candidate in candidates.take(6)) {
      final HttpClient http = HttpClient();
      http.connectionTimeout = const Duration(seconds: 8);
      try {
        final HttpClientRequest request = await http.getUrl(
          candidate.endpoint,
        );
        final HttpClientResponse response = await request.close().timeout(
          const Duration(seconds: 15),
        );
        final String body = await utf8.decoder
            .bind(response)
            .join()
            .timeout(const Duration(seconds: 15));
        stdout.writeln(
          'MASTER ${candidate.id} status=${response.statusCode} '
          'ct=${response.headers.contentType} lines=${body.split('\n').length}',
        );
        final List<String> lines = body.split('\n');
        final String first = lines.firstWhere(
          (String line) => line.trim().isNotEmpty && !line.startsWith('#'),
          orElse: () => '',
        );
        if (first.isEmpty) {
          stdout.writeln('  (no child in playlist)');
          continue;
        }
        final HttpClientRequest childRequest = await http.getUrl(
          Uri.parse(first),
        );
        childRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=0-1023');
        final HttpClientResponse childResponse = await childRequest.close()
            .timeout(const Duration(seconds: 15));
        final List<int> childBytes = await childResponse
            .fold<List<int>>(
              <int>[],
              (List<int> acc, List<int> chunk) => acc..addAll(chunk),
            )
            .timeout(const Duration(seconds: 15));
        stdout.writeln(
          '  CHILD status=${childResponse.statusCode} '
          'range=${childResponse.headers.value(HttpHeaders.contentRangeHeader)} '
          'bytes=${childBytes.length}',
        );
      } on Object catch (error) {
        stdout.writeln('  ${candidate.id} ERROR ${error.runtimeType}: $error');
      } finally {
        http.close(force: true);
      }
    }
  } finally {
    await proxy.close();
    client.close(force: true);
  }
}
