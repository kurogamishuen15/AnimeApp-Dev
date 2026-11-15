import 'hardsub_policy.dart';

/// User-facing search request for a third-party subtitle catalogue.
final class ExternalSubtitleQuery {
  ExternalSubtitleQuery({
    String? query,
    Iterable<String> languages = const [],
    this.imdbId,
    this.parentImdbId,
    this.tmdbId,
    this.season,
    this.episode,
    this.movieHash,
    this.fileName,
  }) : query = query,
       languages = List.unmodifiable(languages) {
    if ((query == null || query.trim().isEmpty) &&
        (imdbId == null || imdbId!.trim().isEmpty) &&
        (parentImdbId == null || parentImdbId!.trim().isEmpty) &&
        (tmdbId == null || tmdbId!.trim().isEmpty) &&
        (movieHash == null || movieHash!.trim().isEmpty)) {
      throw ArgumentError('A title, trusted ID, or file hash is required.');
    }
    if ((query?.trim().length ?? 0) > 200 || (fileName?.length ?? 0) > 512) {
      throw ArgumentError('Subtitle search text is too long.');
    }
    final String? normalizedImdb = imdbId?.trim().replaceFirst(
      RegExp(r'^tt', caseSensitive: false),
      '',
    );
    if (normalizedImdb != null &&
        !RegExp(r'^\d{1,12}$').hasMatch(normalizedImdb)) {
      throw ArgumentError('IMDb ID is invalid.');
    }
    final String? normalizedParentImdb = parentImdbId?.trim().replaceFirst(
      RegExp(r'^tt', caseSensitive: false),
      '',
    );
    if (normalizedParentImdb != null &&
        !RegExp(r'^\d{1,12}$').hasMatch(normalizedParentImdb)) {
      throw ArgumentError('Parent IMDb ID is invalid.');
    }
    if (normalizedImdb != null && normalizedParentImdb != null) {
      throw ArgumentError('Use either an episode IMDb ID or its parent ID.');
    }
    final String? resolvedTmdbId = tmdbId;
    if (resolvedTmdbId != null &&
        !RegExp(r'^\d{1,12}$').hasMatch(resolvedTmdbId.trim())) {
      throw ArgumentError('TMDB ID is invalid.');
    }
    final String? resolvedMovieHash = movieHash;
    if (resolvedMovieHash != null &&
        !RegExp(r'^[a-fA-F0-9]{16}$').hasMatch(resolvedMovieHash.trim())) {
      throw ArgumentError('Movie hash is invalid.');
    }
    if ((season == null) != (episode == null) ||
        (season != null && season! < 0) ||
        (episode != null && episode! < 1)) {
      throw ArgumentError('Season and episode must be a valid pair.');
    }
    if (languages.any(
      (String value) =>
          !RegExp(r'^[a-zA-Z]{2,3}(-[A-Za-z]{2})?$').hasMatch(value),
    )) {
      throw ArgumentError('A language code is invalid.');
    }
  }

  final String? query;
  final List<String> languages;
  final String? imdbId;
  final String? parentImdbId;
  final String? tmdbId;
  final int? season;
  final int? episode;
  final String? movieHash;
  final String? fileName;
}

final class ExternalSubtitleCandidate {
  const ExternalSubtitleCandidate({
    required this.subtitleId,
    required this.fileId,
    required this.fileName,
    required this.language,
    required this.format,
    this.release,
    this.downloadCount,
    this.movieHashMatch = false,
    this.hearingImpaired = false,
    this.fps,
    this.partNumber,
    this.partCount,
  });

  final String subtitleId;
  final int fileId;
  final String fileName;
  final String language;
  final String format;
  final String? release;
  final int? downloadCount;
  final bool movieHashMatch;
  final bool hearingImpaired;
  final double? fps;
  final int? partNumber;
  final int? partCount;
}

final class ExternalSubtitleDownload {
  const ExternalSubtitleDownload({
    required this.uri,
    required this.format,
    required this.language,
    required this.remainingDownloads,
    required this.resetAt,
  });

  /// Local file URI only; a temporary remote URL must never escape data layer.
  final Uri uri;
  final String format;
  final String language;
  final int? remainingDownloads;
  final DateTime? resetAt;
}

sealed class ExternalSubtitleResult<T> {
  const ExternalSubtitleResult();
}

final class ExternalSubtitleSuccess<T> extends ExternalSubtitleResult<T> {
  const ExternalSubtitleSuccess(this.value);
  final T value;
}

final class ExternalSubtitleFailure<T> extends ExternalSubtitleResult<T> {
  const ExternalSubtitleFailure(this.kind, {this.retryAfter});
  final ExternalSubtitleFailureKind kind;
  final Duration? retryAfter;
}

enum ExternalSubtitleFailureKind {
  missingApiKey,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  quotaExhausted,
  timeout,
  network,
  malformedResponse,
  unsupportedFormat,
  invalidDownloadUrl,
  invalidApiRedirect,
  tooLarge,
  corruptFile,
  storageFailure,
  blockedByHardsub,
  unknown,
}

abstract interface class ExternalSubtitleCatalog {
  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  );

  Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download(
    ExternalSubtitleCandidate candidate,
  );
}

/// Engine capability used by application to attach a downloaded local subtitle.
abstract interface class ExternalSubtitleLoader {
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
    int? sourceGeneration,
  });
}
