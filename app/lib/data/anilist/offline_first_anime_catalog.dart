import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_catalog_repository.dart';
import '../../domain/catalog/anime_summary.dart';
import '../local_db/app_database.dart';
import '../local_db/drift_anilist_detail_cache.dart';
import 'anilist_detail_fields.dart';
import 'drift_anilist_browse_cache.dart';

/// Keeps the latest search and a bounded cache of requested details.
class OfflineFirstAnimeCatalog
    implements AnimeCatalogRepository, CachedAnimeCatalog {
  OfflineFirstAnimeCatalog({
    required this.remote,
    required this.database,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _details = DriftAniListDetailCache(database);

  static const String _slot = 'latest_user_search';

  final AnimeCatalogRepository remote;
  final AppDatabase database;
  final DateTime Function() _clock;

  final DriftAniListDetailCache _details;
  late final DriftAniListBrowseCache _browseCache = DriftAniListBrowseCache(
    database,
  );
  final _pending = <int, Future<Result<AnimeSearchResult>>>{};

  Future<({AnimeSummary anime, DateTime fetchedAt, bool crosswalkSchema})?>
  _readDetails(int id) async {
    try {
      final cached = await _details.read(id);
      if (cached == null) return null;
      final raw = (jsonDecode(cached.payload) as List).single;
      final anime = _decodeAnime(raw);
      return anime.id == id
          ? (
              anime: anime,
              fetchedAt: cached.fetchedAt,
              crosswalkSchema: raw is Map && raw['metadataSchemaVersion'] == 2,
            )
          : null;
    } on Object {
      // A damaged or unavailable cache must not prevent a public refresh.
      return null;
    }
  }

  @override
  Future<AnimeSummary?> readCachedAnime(int id) async =>
      (await _readDetails(id))?.anime;

  @override
  Future<Result<AnimeSearchResult>> searchAnimeById(int id) async {
    final current = _pending[id];
    if (current != null) return current;
    final request = _refreshDetails(id);
    _pending[id] = request;
    try {
      return await request;
    } finally {
      if (identical(_pending[id], request)) _pending.remove(id)?.ignore();
    }
  }

  Future<Result<AnimeSearchResult>> _refreshDetails(int id) async {
    final cached = await _readDetails(id);
    final bool hasCurrentEpisodeMetadata =
        cached?.anime.detail?.episodeMetadataFetched ?? false;
    if (cached != null &&
        hasCurrentEpisodeMetadata &&
        cached.crosswalkSchema &&
        _clock().difference(cached.fetchedAt) < const Duration(hours: 24)) {
      return Success(
        AnimeSearchResult(
          items: [cached.anime],
          source: AnimeSearchSource.localCache,
        ),
      );
    }
    final response = await remote.searchAnimeById(id);
    if (response case Success(:final value)) {
      if (value.items.length == 1 && value.items.single.id == id) {
        final payload = _encode(value.items);
        // Keeps even long-running series offline without allowing an
        // unbounded detail document per title.
        if (payload.length <= 512 * 1024) {
          try {
            await _details.write(id, payload, _clock().toUtc());
          } on Object {
            // A failed cache write must not hide valid remote data.
          }
        }
      }
    } else if (response case Failure(:final error) when cached != null) {
      return Success(
        AnimeSearchResult(
          items: [cached.anime],
          source: AnimeSearchSource.localCache,
          refreshError: error,
        ),
      );
    }
    return response;
  }

  @override
  Future<Result<AnimeSearchResult>> searchAnime(
    String search, {
    int page = 1,
    int perPage = 20,
  }) async {
    final Result<AnimeSearchResult> response = await remote.searchAnime(
      search,
      page: page,
      perPage: perPage,
    );
    switch (response) {
      case Success<AnimeSearchResult>(:final value):
        try {
          await _save(search, page, perPage, value.items);
          return Success(value);
        } on Object {
          return const Failure(
            StorageError('Could not persist the latest requested search.'),
          );
        }
      case Failure<AnimeSearchResult>(:final error):
        if (!_isRecoverable(error)) {
          return Failure(error);
        }
        return _readFallback(search, page, perPage, error);
    }
  }

  Future<void> _save(
    String search,
    int page,
    int perPage,
    List<AnimeSummary> items,
  ) async {
    await database
        .into(database.latestAnimeSearch)
        .insertOnConflictUpdate(
          LatestAnimeSearchCompanion.insert(
            slot: _slot,
            searchQuery: search.trim(),
            page: page,
            perPage: perPage,
            resultJson: _encode(items),
            cachedAt: _clock().toUtc(),
          ),
        );
  }

  /// Public feeds are fresh for this long; afterwards the network is asked again
  /// and a stale copy is served only when that request fails.
  static const Duration browseTtl = Duration(minutes: 30);

  @override
  Future<Result<AnimeSearchResult>> browseAnime({
    AnimeBrowseSort sort = AnimeBrowseSort.popular,
    int page = 1,
    int perPage = 20,
  }) async {
    final String feedKey = 'browse:${sort.name}:$page:$perPage';
    final cached = await _readBrowse(feedKey);
    if (cached != null && _clock().difference(cached.fetchedAt) < browseTtl) {
      return Success(
        AnimeSearchResult(
          items: cached.items,
          source: AnimeSearchSource.localCache,
        ),
      );
    }
    final Result<AnimeSearchResult> response = await remote.browseAnime(
      sort: sort,
      page: page,
      perPage: perPage,
    );
    switch (response) {
      case Success<AnimeSearchResult>(:final value):
        if (value.items.isNotEmpty) {
          try {
            await _browseCache.write(
              feedKey,
              _encode(value.items),
              _clock().toUtc(),
            );
          } on Object {
            // A failed cache write must not hide valid remote data.
          }
        }
        return response;
      case Failure<AnimeSearchResult>(:final error):
        if (cached == null) return response;
        return Success(
          AnimeSearchResult(
            items: cached.items,
            source: AnimeSearchSource.localCache,
            refreshError: error,
          ),
        );
    }
  }

  Future<({List<AnimeSummary> items, DateTime fetchedAt})?> _readBrowse(
    String feedKey,
  ) async {
    try {
      final cached = await _browseCache.read(feedKey);
      if (cached == null) return null;
      return (items: _decode(cached.payload), fetchedAt: cached.fetchedAt);
    } on Object {
      // A damaged feed cache is ignored; the network remains authoritative.
      return null;
    }
  }

  static String _encode(List<AnimeSummary> items) => jsonEncode(
    items
        .map(
          (item) => {
            'id': item.id,
            'metadataSchemaVersion': 2,
            'romajiTitle': item.romajiTitle,
            'englishTitle': item.englishTitle,
            'nativeTitle': item.nativeTitle,
            'coverImageUrl': item.coverImageUrl,
            'bannerImageUrl': item.bannerImageUrl,
            'description': item.description,
            'genres': item.genres,
            'status': item.status,
            'format': item.format,
            'season': item.season,
            'seasonYear': item.seasonYear,
            'startDate': _encodeDate(item.startDate),
            'endDate': _encodeDate(item.endDate),
            'score': item.score,
            'popularity': item.popularity,
            if (item.detail case final detail?)
              'detail': encodeAniListDetails(detail),
          },
        )
        .toList(growable: false),
  );

  static Map<String, Object?>? _encodeDate(AnimeReleaseDate? date) =>
      date == null
      ? null
      : {'year': date.year, 'month': date.month, 'day': date.day};

  Future<Result<AnimeSearchResult>> _readFallback(
    String search,
    int page,
    int perPage,
    AppError refreshError,
  ) async {
    try {
      final LatestAnimeSearchData? cached = await (database.select(
        database.latestAnimeSearch,
      )..where((row) => row.slot.equals(_slot))).getSingleOrNull();
      if (cached == null ||
          cached.searchQuery != search.trim() ||
          cached.page != page ||
          cached.perPage != perPage) {
        if (search.trim().isEmpty ||
            page < 1 ||
            perPage < 1 ||
            perPage > 50 ||
            page > 64) {
          return Failure(refreshError);
        }
        final payloads = await _details.findByTitle(
          search.trim(),
          perPage,
          (page - 1) * perPage,
        );
        if (payloads.isEmpty) return Failure(refreshError);
        return Success(
          AnimeSearchResult(
            items: List.unmodifiable(payloads.expand(_decode)),
            source: AnimeSearchSource.localCache,
            refreshError: refreshError,
          ),
        );
      }
      return Success(
        AnimeSearchResult(
          items: _decode(cached.resultJson),
          source: AnimeSearchSource.localCache,
          refreshError: refreshError,
        ),
      );
    } on Object {
      return const Failure(StorageError('Could not read the latest search.'));
    }
  }

  static bool _isRecoverable(AppError error) =>
      error is NetworkError ||
      error is TimeoutAppError ||
      error is RateLimitError ||
      error is UnavailableError;

  static List<AnimeSummary> _decode(String json) {
    final Object? decoded = jsonDecode(json);
    if (decoded is! List<Object?>) {
      throw const FormatException('Cached search shape is invalid.');
    }
    return List<AnimeSummary>.unmodifiable(decoded.map(_decodeAnime));
  }

  static AnimeSummary _decodeAnime(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Cached media shape is invalid.');
    }
    final Object? id = value['id'];
    final Object? romajiTitle = value['romajiTitle'];
    final Object? englishTitle = value['englishTitle'];
    final Object? nativeTitle = value['nativeTitle'];
    final Object? coverImageUrl = value['coverImageUrl'];
    final Object? bannerImageUrl = value['bannerImageUrl'];
    final Object? description = value['description'];
    final Object? genres = value['genres'];
    final Object? status = value['status'];
    final Object? format = value['format'];
    final Object? season = value['season'];
    final Object? seasonYear = value['seasonYear'];
    final Object? score = value['score'];
    final Object? popularity = value['popularity'];
    if (id is! int ||
        id < 1 ||
        !_optionalStringIsValid(romajiTitle) ||
        !_optionalStringIsValid(englishTitle) ||
        !_optionalStringIsValid(nativeTitle) ||
        !_optionalUrlIsValid(coverImageUrl) ||
        !_optionalUrlIsValid(bannerImageUrl) ||
        !_optionalStringIsValid(description) ||
        !_optionalStringIsValid(status) ||
        !_optionalStringIsValid(format) ||
        !_optionalStringIsValid(season) ||
        !_optionalPositiveIntIsValid(seasonYear) ||
        !_stringListIsValid(genres) ||
        !_scoreIsValid(score) ||
        !_nonNegativeIntIsValid(popularity)) {
      throw const FormatException('Cached media fields are invalid.');
    }
    return AnimeSummary(
      id: id,
      romajiTitle: romajiTitle as String?,
      englishTitle: englishTitle as String?,
      nativeTitle: nativeTitle as String?,
      coverImageUrl: coverImageUrl as String?,
      bannerImageUrl: bannerImageUrl as String?,
      description: description as String?,
      genres: genres == null
          ? const []
          : List<String>.unmodifiable((genres as List<Object?>).cast<String>()),
      status: status as String?,
      format: format as String?,
      season: season as String?,
      seasonYear: seasonYear as int?,
      startDate: _decodeDate(value['startDate']),
      endDate: _decodeDate(value['endDate']),
      score: (score as num?)?.toDouble(),
      popularity: popularity as int?,
      detail: switch (value['detail']) {
        final Map<Object?, Object?> details => decodeAniListDetails(details),
        _ => null,
      },
    );
  }

  static AnimeReleaseDate? _decodeDate(Object? value) {
    if (value == null) return null;
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Cached media date is invalid.');
    }
    final Object? year = value['year'];
    final Object? month = value['month'];
    final Object? day = value['day'];
    if (!_optionalPositiveIntIsValid(year) ||
        !_optionalPositiveIntIsValid(month) ||
        !_optionalPositiveIntIsValid(day) ||
        (month is int && month > 12) ||
        (day is int && day > 31)) {
      throw const FormatException('Cached media date parts are invalid.');
    }
    return AnimeReleaseDate(
      year: year as int?,
      month: month as int?,
      day: day as int?,
    );
  }

  static bool _optionalStringIsValid(Object? value) =>
      value == null || value is String;

  static bool _optionalUrlIsValid(Object? value) {
    if (!_optionalStringIsValid(value)) return false;
    if (value == null || value == '') return true;
    final Uri? uri = Uri.tryParse(value as String);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  static bool _stringListIsValid(Object? value) =>
      value == null ||
      value is List<Object?> && value.every((item) => item is String);

  static bool _scoreIsValid(Object? value) =>
      value == null || value is num && value >= 0 && value <= 100;

  static bool _nonNegativeIntIsValid(Object? value) =>
      value == null || value is int && value >= 0;

  static bool _optionalPositiveIntIsValid(Object? value) =>
      value == null || value is int && value > 0;
}
