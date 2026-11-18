import '../../domain/catalog/anime_detail_metadata.dart';
import '../../domain/catalog/external_anime_id.dart';

AnimeDetailMetadata decodeAniListDetails(Map<Object?, Object?> media) {
  final trailer = _map(media['trailer']);
  final List<Object?> streamingEpisodes = _list(media['streamingEpisodes'])
      .toList(growable: false);
  return AnimeDetailMetadata(
    externalIds: [
      if (_id(media['idMal']) case final id?)
        ExternalAnimeId(
          providerId: MetadataProviderId('myanimelist'),
          value: id.toString(),
        ),
    ],
    episodeCount: _id(media['episodes']),
    studios: List.unmodifiable([
      for (final item in _list(_map(media['studios'])['nodes']))
        ?_text(_map(item)['name']),
    ]),
    trailer: switch ((_text(trailer['site']), _text(trailer['id']))) {
      (final site?, final id?) => (site: site, id: id),
      _ => null,
    },
    characters: List.unmodifiable(
      _list(_map(media['characters'])['edges']).map(_character).nonNulls,
    ),
    relations: List.unmodifiable(
      _list(_map(media['relations'])['edges']).map(_relation).nonNulls,
    ),
    episodes: List.unmodifiable([
      for (var index = 0; index < streamingEpisodes.length; index++)
        ?_episode(streamingEpisodes[index], index + 1),
    ]),
    episodeMetadataFetched: switch (media['episodeMetadataFetched']) {
      final bool value => value,
      _ => media.containsKey('streamingEpisodes'),
    },
  );
}

AnimeEpisodeMetadata? _episode(Object? value, int fallbackNumber) {
  final episode = _map(value);
  final title = _text(episode['title']);
  if (title == null) return null;
  final match = RegExp(
    r'\bEpisode\s+(\d+)\b',
    caseSensitive: false,
  ).firstMatch(title);
  final number =
      _id(episode['number']) ??
      int.tryParse(match?.group(1) ?? '') ??
      fallbackNumber;
  final thumbnail = _httpsUrl(_text(episode['thumbnail']));
  final externalWatchUri = _httpsUri(_text(episode['url']));
  return AnimeEpisodeMetadata(
    number: number,
    title: title,
    thumbnailUrl: thumbnail,
    site: _text(episode['site']),
    externalWatchUri: externalWatchUri,
  );
}

AnimeCharacter? _character(Object? value) {
  final edge = _map(value);
  final node = _map(edge['node']);
  final id = _id(node['id']);
  final name = _text(_map(node['name'])['full']);
  if (id == null || name == null) return null;
  final image = _text(_map(node['image'])['medium']);
  final uri = image == null ? null : Uri.tryParse(image);
  return (
    id: id,
    name: name,
    imageUrl:
        uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? image
        : null,
    role: _text(edge['role']),
    voiceActors: List<AnimeVoiceActor>.unmodifiable(
      _list(edge['voiceActors']).map((value) {
        final actor = _map(value);
        final id = _id(actor['id']);
        final name = _text(_map(actor['name'])['full']);
        if (id == null || name == null) return null;
        return (id: id, name: name, language: _text(actor['languageV2']));
      }).nonNulls,
    ),
  );
}

RelatedAnime? _relation(Object? value) {
  final edge = _map(value);
  final node = _map(edge['node']);
  final titles = _map(node['title']);
  final id = _id(node['id']);
  final title =
      _text(titles['english']) ??
      _text(titles['romaji']) ??
      _text(titles['native']);
  if (node['type'] != 'ANIME' || id == null || title == null) return null;
  return (id: id, title: title, relation: _text(edge['relationType']));
}

Map<String, Object?> encodeAniListDetails(AnimeDetailMetadata details) => {
  'episodes': details.episodeCount,
  'idMal': int.tryParse(
    details.externalIds
            .where((id) => id.providerId.value == 'myanimelist')
            .firstOrNull
            ?.value ??
        '',
  ),
  'streamingEpisodes': [
    for (final episode in details.episodes)
      {
        'number': episode.number,
        'title': episode.title,
        'thumbnail': episode.thumbnailUrl,
        'site': episode.site,
        'url': episode.externalWatchUri?.toString(),
      },
  ],
  'episodeMetadataFetched': details.episodeMetadataFetched,
  'studios': {
    'nodes': [
      for (final name in details.studios) {'name': name},
    ],
  },
  if (details.trailer case final trailer?)
    'trailer': {'site': trailer.site, 'id': trailer.id},
  'characters': {
    'edges': [
      for (final character in details.characters)
        {
          'role': character.role,
          'node': {
            'id': character.id,
            'name': {'full': character.name},
            'image': {'medium': character.imageUrl},
          },
          'voiceActors': [
            for (final actor in character.voiceActors)
              {
                'id': actor.id,
                'name': {'full': actor.name},
                'languageV2': actor.language,
              },
          ],
        },
    ],
  },
  'relations': {
    'edges': [
      for (final related in details.relations)
        {
          'relationType': related.relation,
          'node': {
            'id': related.id,
            'type': 'ANIME',
            'title': {'romaji': related.title},
          },
        },
    ],
  },
};

String? _httpsUrl(String? value) {
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri.replace(scheme: 'https').toString();
}

Uri? _httpsUri(String? value) {
  if (value == null) return null;
  final Uri? uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

Map<Object?, Object?> _map(Object? value) =>
    value is Map<Object?, Object?> ? value : const {};
Iterable<Object?> _list(Object? value) =>
    value is List<Object?> ? value : const [];
String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
int? _id(Object? value) => value is int && value > 0 ? value : null;
