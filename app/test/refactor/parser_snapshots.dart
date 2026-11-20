import 'dart:convert';
import 'dart:io';

import 'package:anime_app/data/player/providers/animeav1/animeav1_playback_provider.dart';
import 'package:anime_app/data/player/providers/html_playback_parsers.dart';
import 'package:anime_app/data/player/providers/miruro/miruro_catalog_parser.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';

Map<String, Object?> parserSnapshots({bool publicMedia = false}) {
  final input = jsonDecode(
    File(
      publicMedia
          ? 'test/fixtures/refactor/parser_public_media.json'
          : 'test/fixtures/refactor/parser_cases.json',
    ).readAsStringSync(),
  ) as Map<String, dynamic>;
  final html = input['html'] as String;
  const parser = MiruroCatalogParser();
  final config = parser.parseConfig(
    File('test/fixtures/refactor/miruro_config.json').readAsStringSync(),
  );
  final title = parser.parseTitle(
    jsonEncode(input['title']),
    anilistId: 100240,
  );
  final episodes = parser.parseEpisodes(jsonEncode(input['episodes']));
  final episode = EpisodeRef(
    anime: SourceAnimeMatch(
      providerId: PlaybackProviderId('miruro-catalog'),
      sourceAnimeId: 'title-1',
      title: 'Tokyo Ghoul:re',
      requestedIdentity: AnimeIdentity(localId: AnimeId('test')),
      evidence: AnimeMatchEvidence.externalId,
    ),
    episodeId: '9',
    episodeNumber: 9,
  );
  Object? resultOrError(Object? Function() action) {
    try {
      return action();
    } on Object catch (error) {
      return {
        'type': error.runtimeType.toString(),
        'message': error.toString(),
      };
    }
  }

  return {
    'html': {
      'href': HtmlPlaybackParsers.attr(html, 'href'),
      'id': HtmlPlaybackParsers.attr(html, 'data-id'),
      'absent': HtmlPlaybackParsers.attr(html, 'missing'),
      'text': HtmlPlaybackParsers.stripTags(html),
      'entities': HtmlPlaybackParsers.decodeEntities(
        '&quot;&#39;&apos;&lt;&gt;&amp;&#65;&#x42;',
      ),
      'normalize': HtmlPlaybackParsers.normalize('Tōkyo Ghoul:re 2!'),
      'scores': (input['titles'] as List)
          .map(
            (value) => HtmlPlaybackParsers.titleScore(
              'Tokyo Ghoul:re',
              value as String,
            ),
          )
          .toList(),
      'absolute': HtmlPlaybackParsers.absoluteUrl(
        'https://example.test/a/b',
        '../c',
      ),
      'hls': HtmlPlaybackParsers.hlsUrls(html),
      'escapes': HtmlPlaybackParsers.decodeJsonEscapes(
        r'{\u0022url\u0022:\u0022https:\/\/example.test\u0022}',
      ),
    },
    'miruro': {
      'title': title == null
          ? null
          : {
              'id': title.id,
              'title': title.title,
              'subCount': title.subCount,
              'dubCount': title.dubCount,
            },
      'episodes': episodes.episodes
          .map((e) => {'number': e.number, 'title': e.title, 'kind': e.kind})
          .toList(),
      'cursor': episodes.nextCursor,
      'sources': parser
          .parsePlaybackSources(
            body: jsonEncode(input['play']),
            config: config,
            episode: episode,
          )
          .map(
            (source) => {
              'id': source.id,
              'provider': source.providerId.value,
              'language': source.language,
              'quality': source.quality,
              'label': source.displayName,
              'audio': source.audioLanguage,
              'subtitle': source.subtitleLanguage,
              'servers': source.servers
                  .map(
                    (s) => {
                      'id': s.id,
                      'url': s.endpoint.toString(),
                      'host': s.hostId,
                      'priority': s.priority,
                      'kind': s.kind.name,
                      'language': s.declaredLanguage,
                      'format': s.mediaFormat.name,
                      'quality': s.quality,
                      'label': s.displayName,
                      'availability': s.availability.name,
                      'episode': s.sourceEpisodeId,
                      'expires': s.expiresAt?.toIso8601String(),
                      'provenance': s.provenance,
                      'headers': s.requestHeaders.values,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'malformed': resultOrError(() => parser.parseEpisodes('{')),
      'missingCursor': resultOrError(
        () => parser.parseEpisodes('{"has_more":true}'),
      ),
    },
    'animeav1': {
      'decoded': AnimeAv1PageData.decode(jsonEncode(input['devalue'])),
      'invalid': (input['invalid_devalue'] as List)
          .map(
            (value) =>
                resultOrError(() => AnimeAv1PageData.decode(jsonEncode(value))),
          )
          .toList(),
    },
  };
}

void main(List<String> arguments) {
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(
      parserSnapshots(publicMedia: arguments.contains('--public-media')),
    ),
  );
}
