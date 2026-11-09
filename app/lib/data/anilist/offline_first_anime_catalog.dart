import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../data/local_db/app_database.dart';
import '../../domain/catalog/anime_catalog_repository.dart';
import '../../domain/catalog/anime_summary.dart';

/// Writes only the latest explicitly requested search and uses it on outage.
class OfflineFirstAnimeCatalog implements AnimeCatalogRepository {
  OfflineFirstAnimeCatalog({
    required this.remote,
    required this.database,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const String _slot = 'latest_user_search';

  final AnimeCatalogRepository remote;
  final AppDatabase database;
  final DateTime Function() _clock;

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
    final String json = jsonEncode(
      items
          .map(
            (item) => {
              'id': item.id,
              'romajiTitle': item.romajiTitle,
              'englishTitle': item.englishTitle,
              'nativeTitle': item.nativeTitle,
            },
          )
          .toList(growable: false),
    );
    await database
        .into(database.latestAnimeSearch)
        .insertOnConflictUpdate(
          LatestAnimeSearchCompanion.insert(
            slot: _slot,
            searchQuery: search.trim(),
            page: page,
            perPage: perPage,
            resultJson: json,
            cachedAt: _clock().toUtc(),
          ),
        );
  }

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
        return Failure(refreshError);
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
    if (id is! int ||
        id < 1 ||
        !_optionalStringIsValid(romajiTitle) ||
        !_optionalStringIsValid(englishTitle) ||
        !_optionalStringIsValid(nativeTitle)) {
      throw const FormatException('Cached media fields are invalid.');
    }
    return AnimeSummary(
      id: id,
      romajiTitle: romajiTitle as String?,
      englishTitle: englishTitle as String?,
      nativeTitle: nativeTitle as String?,
    );
  }

  static bool _optionalStringIsValid(Object? value) =>
      value == null || value is String;
}
