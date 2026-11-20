import 'dart:io';
import 'dart:collection';

import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/player/providers/anime_identity.dart';
import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';

import '../episode_source_support.dart';
import '../public_playback_http.dart';
import 'miruro_catalog_api.dart';
import 'miruro_catalog_parser.dart';

/// AniList → Miruro title → episode → direct server candidates.
///
/// It adapts Anilili's public REST catalog flow to Kongroo's existing
/// `EpisodeSourceAdapter` and manager. It does not create a player or resolve
/// iframe pages. Only direct, declared HTTPS media streams reach the generic
/// `DirectMediaHostResolver`.
final class MiruroCatalogPlaybackProvider extends EpisodeSourceAdapter {
  MiruroCatalogPlaybackProvider(
    this._api, {
    this._parser = const MiruroCatalogParser(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const String semanticVersion = '1.0.0';
  static const Duration _configTtl = Duration(minutes: 30);
  static const Duration _titleTtl = Duration(minutes: 30);
  static const Duration _episodeTtl = Duration(minutes: 5);
  static const int _maxCachedTitles = 128;
  static const int _maxCachedEpisodeLists = 2;
  static const int _maxEpisodes = MiruroCatalogParser.maxEpisodes;
  static final MetadataProviderId _anilistProviderId = MetadataProviderId(
    'anilist',
  );

  final MiruroCatalogApi _api;
  final MiruroCatalogParser _parser;
  final DateTime Function() _clock;
  DateTime? _configFetchedAt;
  List<MiruroProviderConfig>? _config;
  final LinkedHashMap<int, _TimedValue<MiruroTitleRecord>> _titles =
      LinkedHashMap<int, _TimedValue<MiruroTitleRecord>>();
  final LinkedHashMap<String, _TimedValue<List<MiruroCatalogEpisode>>>
  _episodeLists =
      LinkedHashMap<String, _TimedValue<List<MiruroCatalogEpisode>>>();

  @override
  final PlaybackProviderId id = PlaybackProviderId('miruro-catalog');

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    PlaybackProviderCapability.sourceAlternatives,
  };

  @override
  String get adapterVersion => MiruroCatalogPlaybackProvider.semanticVersion;

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  }) => EpisodeSourceSupport.read(() async {
    EpisodeSourceSupport.check(cancellation);
    final int? anilistId = _anilistId(identity);
    if (anilistId == null) return null;
    final MiruroTitleRecord? title = await _title(anilistId, cancellation);
    if (title == null) return null;
    return <SourceAnimeMatch>[_match(identity, title, anilistId)];
  });

  /// The detail page already has its episode index from Kitsu. Resolve its
  /// selected number directly instead of downloading a provider-wide list on
  /// each playback click. [listEpisodes] remains available for catalog views.
  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode requested, {
    required PlaybackCancellationToken cancellation,
  }) async {
    EpisodeSourceSupport.check(cancellation);
    if (requested.episodeNumber < 1) return const PlaybackProviderEmpty<List<PlaybackSource>>();
    final int? anilistId = _anilistId(requested.identity);
    // ── DEBUG DIAGNOSTIC ──────────────────────────────────────────────
    // Log what we have before deciding. This never blocks UI; the log
    // appears in the trace/kongroo.playback.http output.
    // ignore: avoid_print
    print('MIRURO_DIAG: findSources anilistId=${anilistId ?? 'null'} '
        'episodeNumber=${requested.episodeNumber} '
        'kitsuId=${_kitsuId(requested.identity)} '
        'tmdbId=${_tmdbId(requested.identity)} '
        'flag=${Platform.environment['KONGROO_ENABLE_MIRURO_BACKEND'] ?? 'not-set'}');
    // ────────────────────────────────────────────────────────────────────
    // OC-07.7 §3: Si no hay ID, la entrada sigue visible pero deshabilitada
    // con motivo "sin identificar", en lugar de desaparecer en silencio.
    if (anilistId == null) {
      return PlaybackProviderEmpty<List<PlaybackSource>>();
    }
    final MiruroTitleRecord? title = await _title(anilistId, cancellation);
    if (title == null) return const PlaybackProviderEmpty<List<PlaybackSource>>();
    final SourceAnimeMatch match = _match(requested.identity, title, anilistId);
    final List<PlaybackSource>? sources = await _sourcesFor(
      _episodeRef(match, requested.episodeNumber),
      cancellation,
    );
    return sources != null
      ? PlaybackProviderSuccess<List<PlaybackSource>>(sources)
      : const PlaybackProviderEmpty<List<PlaybackSource>>();
  }

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) => EpisodeSourceSupport.read(() async {
    EpisodeSourceSupport.check(cancellation);
    if (!_validMatch(match)) return null;
    final List<MiruroCatalogEpisode> records = await _episodes(
      match.sourceAnimeId,
      cancellation,
    );
    return <EpisodeRef>[
      for (final MiruroCatalogEpisode record in records)
        _episodeRef(match, record.number),
    ];
  });

  @override
  Future<PlaybackProviderResult<EpisodeRef>> findEpisode(
    SourceAnimeMatch match, {
    required int episodeNumber,
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) return _failedCancelled<EpisodeRef>();
    final PlaybackProviderResult<List<EpisodeRef>> result = await listEpisodes(
      match,
      cancellation: cancellation,
    );
    return switch (result) {
      PlaybackProviderFailed<List<EpisodeRef>>(:final failure) =>
        PlaybackProviderFailed<EpisodeRef>(failure),
      PlaybackProviderUnsupported<List<EpisodeRef>>(:final capability) =>
        PlaybackProviderUnsupported<EpisodeRef>(capability),
      PlaybackProviderEmpty<List<EpisodeRef>>() =>
        const PlaybackProviderEmpty<EpisodeRef>(),
      PlaybackProviderSuccess<List<EpisodeRef>>(:final value) => _findNumber(
        value,
        episodeNumber,
      ),
    };
  }

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) => EpisodeSourceSupport.read(() async {
    EpisodeSourceSupport.check(cancellation);
    if (!_validEpisode(episode)) return null;
    final List<MiruroProviderConfig> config = await _providerConfig(
      cancellation,
    );
    return _sourcesFromPlayResponse(episode, config, cancellation);
  });

  Future<List<PlaybackSource>?> _sourcesFor(
    EpisodeRef episode,
    PlaybackCancellationToken cancellation,
  ) async {
    EpisodeSourceSupport.check(cancellation);
    if (!_validEpisode(episode)) return null;
    final List<MiruroProviderConfig> config = await _providerConfig(
      cancellation,
    );
    return _sourcesFromPlayResponse(episode, config, cancellation);
  }

  Future<List<PlaybackSource>?> _sourcesFromPlayResponse(
    EpisodeRef episode,
    List<MiruroProviderConfig> config,
    PlaybackCancellationToken cancellation,
  ) async {
    final String path =
        'v1/anime/${episode.sourceAnimeId}/episodes/${episode.episodeNumber}/play';
    final String body = await _api.get(
      path,
      cancellation: cancellation,
      stage: PlaybackHttpStage.episode,
    );
    EpisodeSourceSupport.check(cancellation);
    final List<PlaybackSource> sources = _parser.parsePlaybackSources(
      body: body,
      config: config,
      episode: episode,
    );
    return sources.isEmpty ? null : sources;
  }

  int? _anilistId(AnimeIdentity identity) {
    final List<ExternalAnimeId> ids = identity.externalIds
        .where(
          (ExternalAnimeId value) =>
              value.providerId.value == _anilistProviderId.value,
        )
        .toList(growable: false);
    if (ids.length != 1) return null;
    final int? id = int.tryParse(ids.single.value);
    return id != null && id > 0 && id <= 0x7fffffff ? id : null;
  }

  String? _kitsuId(AnimeIdentity identity) {
    final List<ExternalAnimeId> ids = identity.externalIds
        .where(
          (ExternalAnimeId value) =>
              value.providerId.value == 'kitsu',
        )
        .toList(growable: false);
    if (ids.length != 1) return null;
    return ids.single.value;
  }

  String? _tmdbId(AnimeIdentity identity) {
    final List<ExternalAnimeId> ids = identity.externalIds
        .where(
          (ExternalAnimeId value) =>
              value.providerId.value == 'tmdb',
        )
        .toList(growable: false);
    if (ids.length != 1) return null;
    return ids.single.value;
  }

  SourceAnimeMatch _match(
    AnimeIdentity identity,
    MiruroTitleRecord title,
    int anilistId,
  ) => SourceAnimeMatch(
    providerId: id,
    sourceAnimeId: title.id,
    title:
        title.title ??
        (identity.titles.isEmpty
            ? 'AniList $anilistId'
            : identity.titles.first),
    requestedIdentity: identity,
    evidence: AnimeMatchEvidence.externalId,
    externalIds: <ExternalAnimeId>[
      ExternalAnimeId(providerId: _anilistProviderId, value: '$anilistId'),
    ],
    adapterVersion: adapterVersion,
  );

  Future<MiruroTitleRecord?> _title(
    int anilistId,
    PlaybackCancellationToken cancellation,
  ) async {
    final _TimedValue<MiruroTitleRecord>? cached = _titles.remove(anilistId);
    if (cached != null && _clock().difference(cached.at) < _titleTtl) {
      _titles[anilistId] = cached;
      return cached.value;
    }
    final String body = await _api.get(
      'v1/anime',
      query: <String, String>{'anilist_id_in': '$anilistId', 'limit': '100'},
      cancellation: cancellation,
      stage: PlaybackHttpStage.anime,
    );
    final MiruroTitleRecord? title = _parser.parseTitle(
      body,
      anilistId: anilistId,
    );
    if (title != null) {
      _titles[anilistId] = _TimedValue(title, _clock());
      while (_titles.length > _maxCachedTitles) {
        _titles.remove(_titles.keys.first);
      }
    }
    return title;
  }

  Future<List<MiruroProviderConfig>> _providerConfig(
    PlaybackCancellationToken cancellation,
  ) async {
    final List<MiruroProviderConfig>? cached = _config;
    final DateTime? fetchedAt = _configFetchedAt;
    if (cached != null &&
        fetchedAt != null &&
        _clock().difference(fetchedAt) < _configTtl) {
      return cached;
    }
    final String body = await _api.get(
      'config',
      cancellation: cancellation,
      stage: PlaybackHttpStage.catalog,
    );
    final List<MiruroProviderConfig> parsed = _parser.parseConfig(body);
    if (parsed.isEmpty) throw const FormatException('Miruro config is empty.');
    _config = parsed;
    _configFetchedAt = _clock();
    return parsed;
  }

  Future<List<MiruroCatalogEpisode>> _episodes(
    String titleId,
    PlaybackCancellationToken cancellation,
  ) async {
    final _TimedValue<List<MiruroCatalogEpisode>>? cached = _episodeLists
        .remove(titleId);
    if (cached != null && _clock().difference(cached.at) < _episodeTtl) {
      _episodeLists[titleId] = cached;
      return cached.value;
    }
    final List<MiruroCatalogEpisode> all = <MiruroCatalogEpisode>[];
    final Set<int> numbers = <int>{};
    final Set<String> cursors = <String>{};
    String? cursor;
    do {
      EpisodeSourceSupport.check(cancellation);
      final String body = await _api.get(
        'v1/anime/$titleId/episodes',
        query: <String, String>{
          'limit': '10000',
          if (cursor case final String nextCursor) 'cursor': nextCursor,
        },
        cancellation: cancellation,
        stage: PlaybackHttpStage.episode,
        maxResponseBytes: PublicPlaybackHttp.maxAllowedResponseBytes,
      );
      final ({List<MiruroCatalogEpisode> episodes, String? nextCursor}) page =
          _parser.parseEpisodes(body);
      for (final MiruroCatalogEpisode item in page.episodes) {
        if (numbers.add(item.number) && all.length < _maxEpisodes) {
          all.add(item);
        }
      }
      cursor = page.nextCursor;
      if (cursor != null && !cursors.add(cursor)) {
        throw const FormatException('Miruro repeated an episode cursor.');
      }
    } while (cursor != null && all.length < _maxEpisodes);

    final List<MiruroCatalogEpisode> immutable =
        List<MiruroCatalogEpisode>.unmodifiable(all);
    _episodeLists[titleId] = _TimedValue(immutable, _clock());
    while (_episodeLists.length > _maxCachedEpisodeLists) {
      _episodeLists.remove(_episodeLists.keys.first);
    }
    return immutable;
  }

  bool _validMatch(SourceAnimeMatch match) =>
      match.providerId == id &&
      match.adapterVersion == adapterVersion &&
      match.evidence == AnimeMatchEvidence.externalId &&
      RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(match.sourceAnimeId) &&
      match.externalIds.length == 1 &&
      match.requestedIdentity.externalIds.contains(match.externalIds.single);

  bool _validEpisode(EpisodeRef episode) =>
      _validMatch(episode.anime) &&
      episode.episodeId ==
          _episodeId(episode.sourceAnimeId, episode.episodeNumber);

  EpisodeRef _episodeRef(SourceAnimeMatch match, int number) => EpisodeRef(
    anime: match,
    episodeId: _episodeId(match.sourceAnimeId, number),
    episodeNumber: number,
    mappingEvidence: 'Miruro public episode catalog',
  );

  static String _episodeId(String titleId, int number) =>
      'miruro:$titleId:$number';

  PlaybackProviderResult<EpisodeRef> _findNumber(
    List<EpisodeRef> values,
    int episodeNumber,
  ) {
    if (episodeNumber < 1) return const PlaybackProviderEmpty<EpisodeRef>();
    for (final EpisodeRef episode in values) {
      if (episode.episodeNumber == episodeNumber) {
        return PlaybackProviderSuccess<EpisodeRef>(episode);
      }
    }
    return const PlaybackProviderEmpty<EpisodeRef>();
  }

  static PlaybackProviderFailed<T> _failedCancelled<T>() =>
      PlaybackProviderFailed<T>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );
}

final class _TimedValue<T> {
  const _TimedValue(this.value, this.at);

  final T value;
  final DateTime at;
}

PlaybackSourceProvider createMiruroCatalogProvider(
  MiruroCatalogApi api, {
  DateTime Function()? clock,
}) => MiruroCatalogPlaybackProvider(api, clock: clock);
