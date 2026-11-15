import 'package:anime_app/application/player/external_subtitles/external_subtitle_service.dart';
import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:anime_app/domain/player/subtitles/hardsub_policy.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Catalog implements ExternalSubtitleCatalog {
  _Catalog(this.downloadResult);

  final ExternalSubtitleResult<ExternalSubtitleDownload> downloadResult;
  int downloadCalls = 0;

  @override
  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  ) async => const ExternalSubtitleSuccess(<ExternalSubtitleCandidate>[]);

  @override
  Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download(
    ExternalSubtitleCandidate candidate,
  ) async {
    downloadCalls++;
    return downloadResult;
  }
}

final class _Loader implements ExternalSubtitleLoader {
  Uri? loaded;

  @override
  Future<ExternalSubtitleDecision> loadExternalSubtitle(
    Uri source, {
    required HardsubStatus hardsubStatus,
    String? title,
    String? language,
    int? sourceGeneration,
  }) async {
    loaded = source;
    return externalSubtitleDecision(hardsubStatus);
  }
}

final class _ThrowingCatalog implements ExternalSubtitleCatalog {
  @override
  Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search(
    ExternalSubtitleQuery query,
  ) async => throw StateError('fixture transport failure');

  @override
  Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download(
    ExternalSubtitleCandidate candidate,
  ) async => throw StateError('fixture transport failure');
}

final ExternalSubtitleCandidate _candidate = ExternalSubtitleCandidate(
  subtitleId: 'fixture-1',
  fileId: 4,
  fileName: 'sample.srt',
  language: 'en',
  format: 'srt',
);

ExternalSubtitleDownload _download(Uri uri) => ExternalSubtitleDownload(
  uri: uri,
  format: 'srt',
  language: 'en',
  remainingDownloads: 12,
  resetAt: null,
);

void main() {
  test('confirmed hardsub blocks before consuming a download', () async {
    final _Catalog catalog = _Catalog(
      ExternalSubtitleSuccess(
        _download(Uri.parse('file:///tmp/candidate.srt')),
      ),
    );
    final _Loader loader = _Loader();
    final ExternalSubtitleService service = ExternalSubtitleService(
      catalog: catalog,
      loader: loader,
    );

    final result = await service.downloadAndLoad(
      _candidate,
      hardsubStatus: HardsubStatus.confirmedPresent,
    );
    expect(result, isA<ExternalSubtitleFailure<ExternalSubtitleLoadResult>>());
    expect(
      (result as ExternalSubtitleFailure<ExternalSubtitleLoadResult>).kind,
      ExternalSubtitleFailureKind.blockedByHardsub,
    );
    expect(catalog.downloadCalls, 0);
    expect(loader.loaded, isNull);
  });

  test('unknown hardsub loads only the local downloaded URI', () async {
    final Uri localUri = Uri.parse('file:///tmp/safe-generated.srt');
    final _Catalog catalog = _Catalog(
      ExternalSubtitleSuccess(_download(localUri)),
    );
    final _Loader loader = _Loader();
    final ExternalSubtitleService service = ExternalSubtitleService(
      catalog: catalog,
      loader: loader,
    );

    final result = await service.downloadAndLoad(
      _candidate,
      hardsubStatus: HardsubStatus.unknown,
    );
    expect(result, isA<ExternalSubtitleSuccess<ExternalSubtitleLoadResult>>());
    expect(loader.loaded, localUri);
    expect(catalog.downloadCalls, 1);
    expect(
      (result as ExternalSubtitleSuccess<ExternalSubtitleLoadResult>)
          .value
          .hardsubDecision,
      ExternalSubtitleDecision.allowedWithUncertainty,
    );
  });

  test(
    'catalog exceptions become typed failures at the application boundary',
    () async {
      final ExternalSubtitleService service = ExternalSubtitleService(
        catalog: _ThrowingCatalog(),
        loader: _Loader(),
      );
      final search = await service.search(
        ExternalSubtitleQuery(query: 'episode'),
      );
      expect(
        (search as ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>)
            .kind,
        ExternalSubtitleFailureKind.unknown,
      );
      final download = await service.downloadAndLoad(
        _candidate,
        hardsubStatus: HardsubStatus.unknown,
      );
      expect(
        (download as ExternalSubtitleFailure<ExternalSubtitleLoadResult>).kind,
        ExternalSubtitleFailureKind.unknown,
      );
    },
  );

  test(
    'rejects a remote URI returned by a catalog before loading it',
    () async {
      final _Loader loader = _Loader();
      final ExternalSubtitleService service = ExternalSubtitleService(
        catalog: _Catalog(
          ExternalSubtitleSuccess(
            _download(Uri.parse('https://www.opensubtitles.com/temporary.srt')),
          ),
        ),
        loader: loader,
      );
      final result = await service.downloadAndLoad(
        _candidate,
        hardsubStatus: HardsubStatus.unknown,
      );
      expect(
        (result as ExternalSubtitleFailure<ExternalSubtitleLoadResult>).kind,
        ExternalSubtitleFailureKind.invalidDownloadUrl,
      );
      expect(loader.loaded, isNull);
    },
  );
}
