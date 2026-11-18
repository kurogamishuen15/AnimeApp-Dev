// Live probe for the VOE host resolver against a real embed URL.
// Usage: dart run tool/voe_resolver_probe.dart <embed-url>
import 'dart:io';

import 'package:anime_app/data/player/providers/hosts/voe_video_host_resolver.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:dio/dio.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: voe_resolver_probe <embed-url>');
    exit(64);
  }
  final Uri? embed = Uri.tryParse(args[0]);
  if (embed == null) {
    stderr.writeln('invalid url');
    exit(64);
  }
  final Dio client = Dio();
  try {
    final resolver = VoeVideoHostResolver(client);
    final source = PlaybackSource(
      id: 'probe-source',
      providerId: PlaybackProviderId('animeav1'),
      episode: PlaybackEpisode(
        animeId: AnimeId('probe'),
        episodeNumber: 9,
        externalAnimeIds: [
          ExternalAnimeId(
            providerId: MetadataProviderId('anilist'),
            value: '100240',
          ),
        ],
        animeTitles: const ['Tokyo Ghoul:re'],
      ),
      language: 'ja',
      quality: 'unknown',
      servers: [
        SourceCandidate(
          id: 'voe-sub-0',
          endpoint: embed,
          hostId: 'voe',
          kind: PlaybackCandidateKind.embed,
          requestHeaders: PlaybackRequestHeaders({
            'Referer': 'https://animeav1.com/',
          }),
          sourceEpisodeId: 'animeav1:tokyo-ghoulre:9:sub',
        ),
      ],
    );
    final candidate = source.servers.single;
    stdout.writeln('resolver supports candidate: ${resolver.supports(candidate)}');
    final result = await resolver.resolve(
      source,
      candidate,
      cancellation: PlaybackCancellationToken(),
    );
    switch (result) {
      case PlaybackProviderSuccess<ResolvedPlaybackStream>(:final value):
        stdout.writeln(
          'RESOLVED uri=${value.uri} format=${value.format.name}',
        );
      case PlaybackProviderFailed<ResolvedPlaybackStream>(:final failure):
        stdout.writeln(
          'FAILED kind=${failure.kind} status=${failure.httpStatus} '
          'stage=${failure.stage} host=${failure.host}',
        );
      case PlaybackProviderEmpty<ResolvedPlaybackStream>():
        stdout.writeln('EMPTY');
      case PlaybackProviderUnsupported<ResolvedPlaybackStream>(:final capability):
        stdout.writeln('UNSUPPORTED $capability');
    }
  } finally {
    client.close(force: true);
  }
}
