import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../domain/catalog/external_anime_id.dart';
import '../../../../domain/player/providers/anime_identity.dart';
import '../../../../domain/player/providers/episode_source.dart';
import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../public_episode_provider.dart';
import '../public_playback_http.dart';
import 'wikimedia_identity.dart';

/// Reviewed full anime films on Commons. The catalog contains cross-references
/// and file names. The official API supplies current media and transcodes.
final class WikimediaAnimeProvider extends PublicEpisodeProvider {
  WikimediaAnimeProvider(Dio client)
    : _http = PublicPlaybackHttp(
        client,
        const {'commons.wikimedia.org'},
        userAgent: wikimediaUserAgent,
        enforceCooldown: true,
        maxConcurrent: 2,
      );

  static final ExternalAnimeId _dullSword = ExternalAnimeId(
    providerId: MetadataProviderId('anilist'),
    value: '6654',
  );
  static const String _file =
      "File:Kouichi Jun'ichi - Namakura Gatana (1917) - 4-minute restored version.webm";
  static const String _slug = 'Q2054133';
  final PublicPlaybackHttp _http;

  @override
  final PlaybackProviderId id = PlaybackProviderId('wikimedia-commons');

  @override
  bool allowsDirectMedia(Uri uri) =>
      uri.host == 'upload.wikimedia.org' &&
      uri.path.startsWith('/wikipedia/commons/') &&
      uri.path.endsWith('.webm') &&
      !uri.hasQuery;

  @override
  String episodePath(String slug, int number) => '$slug:$number';

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  }) => read(() async {
    if (cancellation.isCancelled) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.cancelled);
    }
    if (!identity.externalIds.contains(_dullSword)) return null;
    return [
      SourceAnimeMatch(
        providerId: id,
        sourceAnimeId: _slug,
        title: 'Namakura Gatana',
        requestedIdentity: identity,
        evidence: AnimeMatchEvidence.externalId,
        externalIds: [_dullSword],
      ),
    ];
  });

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) => read(() async {
    if (cancellation.isCancelled) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.cancelled);
    }
    if (match.providerId != id ||
        match.sourceAnimeId != _slug ||
        !match.requestedIdentity.externalIds.contains(_dullSword)) {
      return null;
    }
    return episodes(match, const [1]);
  });

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) => read(() async {
    if (episode.providerId != id ||
        episode.episodeId != episodePath(_slug, 1) ||
        episode.episodeNumber != 1 ||
        !episode.anime.requestedIdentity.externalIds.contains(_dullSword)) {
      return null;
    }

    final Uri request = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'titles': _file,
      'prop': 'videoinfo',
      'viprop': 'url|mime|derivatives|extmetadata',
    });
    final Object? body = jsonDecode(await _http.read(request, cancellation));
    if (body case {
      'query': {
        'pages': [
          {'title': _file, 'videoinfo': [final Map<String, Object?> video]},
        ],
      },
    }) {
      if (video case {
        'mime': 'video/webm',
        'extmetadata': {
          'LicenseShortName': {'value': 'Public domain'},
          'Copyrighted': {'value': 'False'},
        },
        'url': final String original,
        'derivatives': final List<Object?> derivatives,
      }) {
        final List<(String, Uri)> available = [];
        void add(String label, String url) {
          final Uri? uri = Uri.tryParse(url);
          if (uri != null && allowsDirectMedia(uri)) {
            final alternative = ('Wikimedia · $label', uri);
            if (label == '480p') {
              available.insert(0, alternative);
            } else {
              available.add(alternative);
            }
          }
        }

        for (final Object? derivative in derivatives) {
          if (derivative case {
            'transcodekey': final String key,
            'src': final String url,
          }) {
            final String? height = RegExp(r'^(\d{3,4})p\.(vp9|vp8)\.webm$')
                .firstMatch(key)
                ?.group(1);
            if (height != null) add('${height}p', url);
          }
        }
        add('Original', original);
        return sources(
          episode,
          available,
          mediaHeaders: PlaybackRequestHeaders({
            'User-Agent': wikimediaUserAgent,
          }),
        );
      }
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.blocked);
    }
    throw const FormatException('Invalid Commons video metadata');
  });
}
