import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';

final class ExternalSubtitleLoadResult {
  const ExternalSubtitleLoadResult({
    required this.download,
    required this.hardsubDecision,
  });

  final ExternalSubtitleDownload download;
  final ExternalSubtitleDecision hardsubDecision;
}

/// Coordinates catalogue access with the existing player contract. It never
/// exposes remote URLs to the engine; only a downloaded local file is loaded.
final class ExternalSubtitleService {
  const ExternalSubtitleService({
    required this.catalog,
    required this.loader,
    this.sourceGeneration,
  });

  final ExternalSubtitleCatalog catalog;
  final ExternalSubtitleLoader loader;
  final int Function()? sourceGeneration;

  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  ) async {
    try {
      return await catalog.search(query);
    } on Object {
      return const ExternalSubtitleFailure(ExternalSubtitleFailureKind.unknown);
    }
  }

  Future<ExternalSubtitleResult<ExternalSubtitleLoadResult>> downloadAndLoad(
    ExternalSubtitleCandidate candidate, {
    required HardsubStatus hardsubStatus,
  }) async {
    final ExternalSubtitleDecision decision = externalSubtitleDecision(
      hardsubStatus,
    );
    if (decision == ExternalSubtitleDecision.blocked) {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.blockedByHardsub,
      );
    }
    final int? generation = sourceGeneration?.call();
    final ExternalSubtitleResult<ExternalSubtitleDownload> result;
    try {
      result = await catalog.download(candidate);
    } on Object {
      return const ExternalSubtitleFailure(ExternalSubtitleFailureKind.unknown);
    }
    if (result is ExternalSubtitleFailure<ExternalSubtitleDownload>) {
      return ExternalSubtitleFailure(
        result.kind,
        retryAfter: result.retryAfter,
      );
    }
    final ExternalSubtitleDownload download =
        (result as ExternalSubtitleSuccess<ExternalSubtitleDownload>).value;
    if (download.uri.scheme != 'file') {
      return const ExternalSubtitleFailure(
        ExternalSubtitleFailureKind.invalidDownloadUrl,
      );
    }
    try {
      final ExternalSubtitleDecision engineDecision = await loader
          .loadExternalSubtitle(
            download.uri,
            hardsubStatus: hardsubStatus,
            title: candidate.release ?? candidate.fileName,
            language: candidate.language,
            sourceGeneration: generation,
          );
      return ExternalSubtitleSuccess(
        ExternalSubtitleLoadResult(
          download: download,
          hardsubDecision: engineDecision,
        ),
      );
    } on Object {
      return const ExternalSubtitleFailure(ExternalSubtitleFailureKind.unknown);
    }
  }
}
