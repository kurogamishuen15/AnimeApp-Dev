import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../domain/catalog/external_anime_id.dart';
import '../../../../domain/player/providers/anime_identity.dart';
import '../../../../domain/player/providers/episode_source.dart';
import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../hosts/direct_media_host_resolver.dart';
import '../public_playback_http.dart';

/// AnimeAV1 catalogue protocol adapted from Anilili d7b80f1 (MIT-0).
/// Requires a confirmed MAL crosswalk. Host resolution belongs to resolvers.
final class AnimeAv1PlaybackProvider extends EpisodeSourceAdapter {
  AnimeAv1PlaybackProvider(Dio client, {Uri? origin})
    : origin = origin ?? Uri.https('animeav1.com') {
    if (!DirectMediaHostResolver.isSyntacticallyPublicHttps(this.origin) ||
        !const {'', '/'}.contains(this.origin.path) ||
        this.origin.hasQuery) {
      throw ArgumentError.value(this.origin, 'origin');
    }
    _http = PublicPlaybackHttp(client, {this.origin.host});
  }

  final Uri origin;
  late final PublicPlaybackHttp _http;
  static final _slug = RegExp(r'^[a-z0-9][a-z0-9-]{0,180}$');
  static const _hosts = {'voe': 30, 'yourupload': 20, 'mp4upload': 10};

  @override
  PlaybackProviderId get id => PlaybackProviderId('animeav1');

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    // The episode page legitimately offers several host alternatives
    // (voe/yourupload/mp4upload); without this capability the manager's
    // source validation rejects every multi-server response.
    PlaybackProviderCapability.sourceAlternatives,
  };

  int? _mal(AnimeIdentity identity) {
    final ids = identity.externalIds
        .where((value) => value.providerId.value == 'myanimelist')
        .toList();
    if (ids.length != 1 ||
        !RegExp(r'^[1-9][0-9]{0,9}$').hasMatch(ids.single.value)) {
      return null;
    }
    final value = int.tryParse(ids.single.value);
    return value != null && value <= 0x7fffffff ? value : null;
  }

  bool _validMatch(SourceAnimeMatch match) =>
      match.providerId == id &&
      match.adapterVersion == adapterVersion &&
      match.evidence == AnimeMatchEvidence.externalId &&
      _slug.hasMatch(match.sourceAnimeId) &&
      _mal(match.requestedIdentity) != null &&
      match.externalIds.length == 1 &&
      match.externalIds.single.providerId.value == 'myanimelist' &&
      match.externalIds.single.value ==
          _mal(match.requestedIdentity).toString() &&
      match.isConservativeMatch();

  Future<Map<String, dynamic>> _data(
    String path,
    PlaybackCancellationToken cancellation, {
    String? search,
    PlaybackHttpStage stage = PlaybackHttpStage.catalog,
  }) async {
    _check(cancellation);
    final uri = origin
        .resolve('/$path/__data.json')
        .replace(queryParameters: search == null ? null : {'search': search});
    final text = await _http.read(
      uri,
      cancellation,
      stage: stage,
      headers: PlaybackRequestHeaders({
        'Referer': origin.resolve('/').toString(),
      }),
    );
    _check(cancellation);
    return AnimeAv1PageData.decode(text);
  }

  static Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected object');
    }
    return value;
  }

  Map<String, dynamic> _media(Map<String, dynamic> page, int mal) {
    final media = _object(page['media']);
    if (media['malId'] != mal) throw const FormatException('MAL mismatch');
    return media;
  }

  static List<int> _numbers(Map<String, dynamic> media) {
    final episodes = media['episodes'];
    if (episodes is! List) throw const FormatException('Missing episode index');
    final numbers = <int>{};
    for (final entry in episodes) {
      final number = entry is Map ? entry['number'] : null;
      if (number is num &&
          number.isFinite &&
          number > 0 &&
          number <= 0x7fffffff &&
          number == number.roundToDouble()) {
        numbers.add(number.toInt());
      }
    }
    return numbers.toList()..sort();
  }

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    final mal = _mal(identity);
    if (mal == null) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.missingId);
    }
    if (identity.titles.isEmpty) return null;
    final seen = <String>{};
    var confirmations = 0;
    for (final title in identity.titles.take(3)) {
      final page = await _data('catalogo', cancellation, search: title);
      final results = page['results'];
      if (results is! List) {
        throw const FormatException('Missing search results');
      }
      for (final value in results.take(20)) {
        if (value is! Map) continue;
        final slug = value['slug'];
        final name = value['title'];
        if (slug is! String ||
            !_slug.hasMatch(slug) ||
            !seen.add(slug) ||
            name is! String ||
            name.trim().isEmpty ||
            name.length > 256) {
          continue;
        }
        if (++confirmations > 3) return null;
        final detail = await _data(
          'media/$slug',
          cancellation,
          stage: PlaybackHttpStage.anime,
        );
        final media = _object(detail['media']);
        if (media['malId'] != mal) continue;
        _numbers(media); // A title-only record is not an episode catalogue.
        return [
          SourceAnimeMatch(
            providerId: id,
            sourceAnimeId: slug,
            title: name,
            requestedIdentity: identity,
            evidence: AnimeMatchEvidence.externalId,
            adapterVersion: adapterVersion,
            externalIds: [
              ExternalAnimeId(
                providerId: MetadataProviderId('myanimelist'),
                value: '$mal',
              ),
            ],
          ),
        ];
      }
    }
    return null;
  });

  EpisodeRef _episode(SourceAnimeMatch match, int number) => EpisodeRef(
    anime: match,
    episodeId: '${match.sourceAnimeId}:$number',
    episodeNumber: number,
    mappingEvidence: 'AnimeAV1 MAL-confirmed title and explicit episode index',
  );

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    if (!_validMatch(match)) {
      throw const FormatException('Invalid source identity');
    }
    final page = await _data(
      'media/${match.sourceAnimeId}',
      cancellation,
      stage: PlaybackHttpStage.anime,
    );
    final numbers = _numbers(_media(page, _mal(match.requestedIdentity)!));
    return numbers.isEmpty
        ? null
        : numbers.map((n) => _episode(match, n)).toList();
  });

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    if (!_validMatch(episode.anime) ||
        episode.episodeId !=
            _episode(episode.anime, episode.episodeNumber).episodeId) {
      throw const FormatException('Invalid episode identity');
    }
    final page = await _data(
      'media/${episode.sourceAnimeId}/${episode.episodeNumber}',
      cancellation,
      stage: PlaybackHttpStage.episode,
    );
    final media = _media(page, _mal(episode.anime.requestedIdentity)!);
    if (!_numbers(media).contains(episode.episodeNumber)) return null;
    final record = _object(page['episode']);
    if (record['number'] != episode.episodeNumber) {
      throw const FormatException('Episode mismatch');
    }
    final variants = _object(record['variants']);
    final embeds = _object(page['embeds']);
    final result = <PlaybackSource>[];
    for (final variant in const ['SUB', 'DUB']) {
      final count = variants[variant];
      if (count is! num || count <= 0) continue;
      final values = embeds[variant];
      if (values is! List) continue;
      final candidates = <SourceCandidate>[];
      final seen = <Uri>{};
      for (final value in values.take(32)) {
        if (value is! Map ||
            value['server'] is! String ||
            value['url'] is! String) {
          continue;
        }
        final host = (value['server'] as String).trim().toLowerCase();
        final uri = Uri.tryParse(value['url'] as String);
        if (!_hosts.containsKey(host) ||
            uri == null ||
            (value['url'] as String).length > 8192 ||
            !DirectMediaHostResolver.isSyntacticallyPublicHttps(uri) ||
            !seen.add(uri)) {
          continue;
        }
        candidates.add(
          SourceCandidate(
            id: '$host-${variant.toLowerCase()}-${candidates.length}',
            hostId: host,
            endpoint: uri,
            kind: PlaybackCandidateKind.embed,
            priority: _hosts[host]!,
            declaredLanguage: variant == 'DUB' ? 'es' : 'ja',
            displayName: value['server'] as String,
            sourceEpisodeId: episode.episodeId,
            requestHeaders: PlaybackRequestHeaders({
              'Referer': origin.resolve('/').toString(),
            }),
            provenance: 'AnimeAV1 episode embeds/$variant (Anilili MIT-0)',
          ),
        );
      }
      if (candidates.isEmpty) continue;
      final dubbed = variant == 'DUB';
      result.add(
        PlaybackSource(
          id: 'animeav1:${episode.episodeId}:${variant.toLowerCase()}',
          providerId: id,
          episode: PlaybackEpisode.fromIdentity(
            episode.anime.requestedIdentity,
            episodeNumber: episode.episodeNumber,
          ),
          language: dubbed ? 'es' : 'ja',
          quality: 'unknown',
          audioLanguage: dubbed ? 'es' : 'ja',
          subtitleLanguage: dubbed ? null : 'es',
          dubbingType: dubbed
              ? PlaybackDubbingType.latinSpanish
              : PlaybackDubbingType.originalAudio,
          providerAnnouncedLanguage: dubbed
              ? 'Español latino (DUB)'
              : 'Japonés + subtítulos españoles incrustados (SUB)',
          displayName: dubbed
              ? 'AnimeAV1 · Español latino'
              : 'AnimeAV1 · Japonés · Sub ES incrustados',
          servers: candidates,
        ),
      );
    }
    return result.isEmpty ? null : result;
  });

  static void _check(PlaybackCancellationToken cancellation) {
    if (cancellation.isCancelled) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.cancelled);
    }
  }

  Future<PlaybackProviderResult<T>> _read<T>(Future<T?> Function() load) async {
    try {
      final value = await load();
      return value == null
          ? PlaybackProviderEmpty<T>()
          : PlaybackProviderSuccess(value);
    } on PublicPlaybackFailure catch (error) {
      return error.result<T>();
    } on FormatException {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    } on ArgumentError {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.invalidResponse),
      );
    }
  }
}

/// Bounded adaptation of Anilili's SvelteKit/devalue pageData/hydrate parser.
abstract final class AnimeAv1PageData {
  static Map<String, dynamic> decode(String text) {
    final root = jsonDecode(text);
    final nodes = root is Map ? root['nodes'] : null;
    if (nodes is! List) throw const FormatException('Missing page nodes');
    final node = nodes
        .whereType<Map<String, dynamic>>()
        .where((n) => n['type'] == 'data')
        .lastOrNull;
    final flat = node?['data'];
    if (flat is! List || flat.isEmpty) {
      throw const FormatException('Missing route data');
    }
    var budget = 100000;
    final active = <int>{};
    Object? hydrate(int index, int depth) {
      if (--budget < 0 || depth > 64) {
        throw const FormatException('Page expansion limit');
      }
      if (index < 0) return null; // devalue sentinels: undefined, NaN, etc.
      if (index >= flat.length || !active.add(index)) {
        throw const FormatException('Invalid page reference');
      }
      try {
        final value = flat[index];
        Object? ref(Object? index) {
          if (index is! int) {
            throw const FormatException('Invalid page reference');
          }
          return hydrate(index, depth + 1);
        }

        if (value is Map) {
          return value.map((key, val) => MapEntry(key as String, ref(val)));
        }
        if (value is List) {
          if (value.isNotEmpty && value.first is String) {
            return value; // typed scalar
          }
          return value.map(ref).toList();
        }
        return value;
      } finally {
        active.remove(index);
      }
    }

    final page = hydrate(0, 0);
    if (page is! Map<String, dynamic>) {
      throw const FormatException('Invalid page root');
    }
    return page;
  }
}
