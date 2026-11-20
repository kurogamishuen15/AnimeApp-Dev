import 'package:anime_app/app/home/home_data.dart';
import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/anime_identity.dart';
import 'package:anime_app/domain/catalog/anime_identity_repository.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:anime_app/domain/catalog/library_repository.dart';
import 'package:anime_app/domain/catalog/metadata_provenance.dart';
import 'package:anime_app/domain/catalog/metadata_provider.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:anime_app/domain/catalog/provider_result.dart';
import 'package:anime_app/domain/progress/content_identity.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:anime_app/domain/progress/playback_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps popular titles when trending and library fail', () async {
    final source = CatalogHomeSource(
      _service(
        popular: ProviderSuccess([_anime(1, 'Popular one')]),
        trending: ProviderFailure(ProviderFailureKind.unavailable),
        library: const Failure(UnknownAppError('library')),
      ),
    );

    final result = await source.load();

    final content = (result as Success<HomeContent>).value;
    expect(
      content.shelves
          .firstWhere((s) => s.label == 'Populares')
          .titles
          .map((t) => t.title),
      ['Popular one'],
    );
    expect(
      content.shelves.firstWhere((s) => s.label == 'Tendencias').titles,
      isEmpty,
    );
    expect(content.offline, isFalse);
  });

  test(
    'continue watching uses only saved in-progress local episodes',
    () async {
      final source = CatalogHomeSource(
        _service(
          popular: const ProviderSuccess([]),
          trending: const ProviderSuccess([]),
          library: Success([_watching('a1'), _watching('a2')]),
          progress: Success([
            _progress('a1', positionMs: 91000),
            _progress(
              'a2',
              positionMs: 5000,
              completion: CompletionState.completed,
            ),
            _progress('ghost', positionMs: 7000),
          ]),
        ),
      );

      final content = ((await source.load()) as Success<HomeContent>).value;

      expect(content.episodes.map((e) => e.anime.title), ['a1']);
      expect(content.episodes.single.label, 'Episodio 3');
      expect(content.episodes.single.positionMs, 91000);
      expect(content.episodes.single.durationMs, 1400000);
    },
  );

  test('a failed progress read leaves continue watching empty only', () async {
    final source = CatalogHomeSource(
      _service(
        popular: const ProviderSuccess([]),
        trending: const ProviderSuccess([]),
        library: Success([_watching('a1')]),
        progress: const Failure(UnknownAppError('progress')),
      ),
    );

    final content = ((await source.load()) as Success<HomeContent>).value;

    expect(content.episodes, isEmpty);
    expect(content.watching.map((t) => t.title), ['a1']);
  });

  test(
    'continue watching keeps the persisted episode identity for resume',
    () async {
      final source = CatalogHomeSource(
        _service(
          popular: const ProviderSuccess([]),
          trending: const ProviderSuccess([]),
          library: Success([_watching('a1')]),
          progress: Success([_progress('a1', positionMs: 500000)]),
        ),
      );

      final content = ((await source.load()) as Success<HomeContent>).value;

      expect(content.episodes.single.label, 'Episodio 3');
      expect(content.episodes.single.positionMs, 500000);
      expect(content.episodes.single.playback?.animeId.value, 'a1');
      expect(content.episodes.single.playback?.episodeNumber, 3);
    },
  );

  test('a slow library is bounded and does not hide loaded feeds', () async {
    final source = CatalogHomeSource(
      _service(
        popular: ProviderSuccess([_anime(1, 'Popular one')]),
        trending: const ProviderSuccess([]),
        library: Success([_watching('a1')]),
        libraryDelay: const Duration(milliseconds: 300),
      ),
      sectionBudget: const Duration(milliseconds: 30),
    );

    final content = ((await source.load()) as Success<HomeContent>).value;

    expect(
      content.shelves
          .firstWhere((s) => s.label == 'Populares')
          .titles
          .map((t) => t.title),
      ['Popular one'],
    );
    expect(content.watching, isEmpty);
  });

  test('keeps trending titles when popular fails without network', () async {
    final source = CatalogHomeSource(
      _service(
        popular: ProviderFailure(ProviderFailureKind.unavailable),
        trending: ProviderSuccess([_anime(2, 'Trending two')]),
        library: const Success(<CatalogLibraryItem>[]),
      ),
    );

    final result = await source.load();

    final content = (result as Success<HomeContent>).value;
    expect(
      content.shelves
          .firstWhere((s) => s.label == 'Tendencias')
          .titles
          .map((t) => t.title),
      ['Trending two'],
    );
  });

  test(
    'fails visibly only when no catalog or library content exists',
    () async {
      final source = CatalogHomeSource(
        _service(
          popular: ProviderFailure(ProviderFailureKind.unavailable),
          trending: ProviderFailure(ProviderFailureKind.unavailable),
          library: const Success(<CatalogLibraryItem>[]),
        ),
      );

      final result = await source.load();

      expect(result, isA<Failure<HomeContent>>());
    },
  );

  test('marks content offline only when both feeds lost the network', () async {
    final source = CatalogHomeSource(
      _service(
        popular: ProviderFailure(ProviderFailureKind.network),
        trending: ProviderFailure(ProviderFailureKind.network),
        library: const Success(<CatalogLibraryItem>[]),
      ),
    );

    final result = await source.load();

    expect((result as Success<HomeContent>).value.offline, isTrue);
  });
}

CatalogService _service({
  required ProviderResult<List<ProviderAnimeMetadata>> popular,
  required ProviderResult<List<ProviderAnimeMetadata>> trending,
  required Result<List<CatalogLibraryItem>> library,
  Result<List<PlaybackProgress>> progress = const Success([]),
  Duration libraryDelay = Duration.zero,
}) => CatalogService(
  metadataProvider: _BrowseProvider(popular: popular, trending: trending),
  identities: _Identities(),
  library: _Library(library, delay: libraryDelay),
  progress: _Progress(progress),
);

CatalogLibraryItem _watching(String animeId) => CatalogLibraryItem(
  entry: LibraryEntry(
    animeId: AnimeId(animeId),
    addedAtUtc: DateTime.utc(2026),
    status: LibraryStatus.watching,
  ),
);

PlaybackProgress _progress(
  String animeId, {
  required int positionMs,
  CompletionState completion = CompletionState.inProgress,
}) => PlaybackProgress(
  key: ProgressKey(
    contentId: ContentId(animeId),
    episodeId: EpisodeId('episode:3'),
  ),
  positionMs: positionMs,
  durationMs: 1400000,
  updatedAtUtc: DateTime.utc(2026),
  completion: completion,
);

ProviderAnimeMetadata _anime(int id, String title) {
  final externalId = ExternalAnimeId(
    providerId: _BrowseProvider.providerId,
    value: '$id',
  );
  return ProviderAnimeMetadata(
    externalId: externalId,
    preferredTitle: title,
    provenance: MetadataProvenance(
      externalId: externalId,
      retrievedAtUtc: DateTime.utc(2026),
    ),
  );
}

final class _BrowseProvider
    implements MetadataProvider, PublicAnimeBrowseProvider {
  const _BrowseProvider({required this.popular, required this.trending});

  static final MetadataProviderId providerId = MetadataProviderId('anilist');

  final ProviderResult<List<ProviderAnimeMetadata>> popular;
  final ProviderResult<List<ProviderAnimeMetadata>> trending;

  @override
  MetadataProviderId get id => providerId;

  @override
  Set<MetadataCapability> get capabilities => const {
    MetadataCapability.publicSearch,
  };

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browsePopular({
    int limit = 20,
  }) async => popular;

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browseTrending({
    int limit = 20,
  }) async => trending;

  @override
  Future<ProviderResult<ProviderHealth>> checkHealth() async =>
      const ProviderUnsupported('healthCheck');

  @override
  Future<ProviderResult<ProviderAnimeMetadata>> getAnimeByExternalId(
    ExternalAnimeId id,
  ) async => const ProviderUnsupported('animeDetails');

  @override
  Future<ProviderResult<List<ProviderEpisodeMetadata>>> getEpisodes(
    ExternalAnimeId animeId,
  ) async => const ProviderUnsupported('episodeMetadata');

  @override
  Future<ProviderResult<List<ProviderAnimeMetadata>>> searchAnime(
    String query, {
    int limit = 20,
  }) async => const ProviderNoResults();
}

final class _Library implements LocalLibraryRepository {
  const _Library(this.listed, {this.delay = Duration.zero});

  final Result<List<CatalogLibraryItem>> listed;
  final Duration delay;

  @override
  Future<Result<List<LibraryEntry>>> list() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return _entries();
  }

  Result<List<LibraryEntry>> _entries() => switch (listed) {
    Success<List<CatalogLibraryItem>>(:final value) => Success([
      for (final item in value) item.entry,
    ]),
    Failure<List<CatalogLibraryItem>>(:final error) => Failure(error),
  };

  @override
  Future<Result<LibraryEntry?>> get(AnimeId animeId) =>
      throw UnimplementedError();

  @override
  Future<Result<LibraryEntry>> add(AnimeId animeId) =>
      throw UnimplementedError();

  @override
  Future<Result<LibraryEntry>> setStatus(
    AnimeId animeId,
    LibraryStatus status,
  ) => throw UnimplementedError();

  @override
  Future<Result<void>> remove(AnimeId animeId) => throw UnimplementedError();
}

final class _Identities implements AnimeIdentityRepository {
  @override
  Future<Result<AnimeIdentity?>> getById(AnimeId id) async =>
      const Success<AnimeIdentity?>(null);

  @override
  Future<Result<AnimeIdentity?>> findByExternalId(ExternalAnimeId id) =>
      throw UnimplementedError();

  @override
  Future<Result<AnimeIdentity>> getOrCreateForExternalId(
    ExternalAnimeId id, {
    required IdentityLinkEvidence evidence,
  }) => throw UnimplementedError();

  @override
  Future<Result<AnimeIdentity>> createLocalIdentity() =>
      throw UnimplementedError();

  @override
  Future<Result<AnimeIdentity>> linkExternalId({
    required AnimeId animeId,
    required ExternalAnimeId externalId,
    required IdentityLinkEvidence evidence,
  }) => throw UnimplementedError();

  @override
  Future<Result<AnimeIdentity>> addRelationship({
    required AnimeId sourceId,
    required AnimeId targetId,
    required AnimeRelationshipKind kind,
    required IdentityLinkEvidence evidence,
  }) => throw UnimplementedError();
}

final class _Progress implements PlaybackProgressRepository {
  const _Progress(this.saved);

  final Result<List<PlaybackProgress>> saved;

  @override
  Future<Result<void>> upsert(PlaybackProgress progress) =>
      throw UnimplementedError();

  @override
  Future<Result<PlaybackProgress?>> get(ProgressKey key) =>
      throw UnimplementedError();

  @override
  Future<Result<List<PlaybackProgress>>> list(ContentIdFilter filter) async =>
      saved;

  @override
  Future<Result<void>> delete(ProgressKey key) => throw UnimplementedError();
}
