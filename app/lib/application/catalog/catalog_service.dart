import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_id.dart';
import '../../domain/catalog/anime_identity.dart';
import '../../domain/catalog/anime_identity_repository.dart';
import '../../domain/catalog/external_anime_id.dart';
import '../../domain/catalog/library_entry.dart';
import '../../domain/catalog/library_repository.dart';
import '../../domain/catalog/metadata_provider.dart';
import '../../domain/catalog/provider_anime_metadata.dart';
import '../../domain/catalog/provider_result.dart';
import '../../domain/progress/content_identity.dart';
import '../../domain/progress/playback_progress.dart';
import '../../domain/progress/playback_progress_repository.dart';

/// A local library row joined with optional, non-persistent provider metadata.
final class CatalogLibraryItem {
  const CatalogLibraryItem({
    required this.entry,
    this.metadata,
    this.externalId,
  });

  final LibraryEntry entry;
  final ExternalAnimeId? externalId;
  final ProviderAnimeMetadata? metadata;

  String get title => metadata?.preferredTitle ?? entry.animeId.value;
}

/// Coordinates catalog, identity, local-library, and existing progress ports.
/// It contains no Flutter, SQL, HTTP, or provider-specific DTO dependencies.
final class CatalogService {
  CatalogService({
    required this.metadataProvider,
    required this.identities,
    required this.library,
    required this.progress,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final MetadataProvider metadataProvider;
  final AnimeIdentityRepository identities;
  final LocalLibraryRepository library;
  final PlaybackProgressRepository progress;
  final DateTime Function() _clock;
  final Map<ExternalAnimeId, Future<Result<LibraryEntry>>> _pendingAdds = {};

  Future<Result<List<ProviderAnimeMetadata>>> search(String query) async {
    final ProviderResult<List<ProviderAnimeMetadata>> result =
        await metadataProvider.searchAnime(query);
    return switch (result) {
      ProviderSuccess<List<ProviderAnimeMetadata>>(:final value) => Success(
        value,
      ),
      ProviderNoResults<List<ProviderAnimeMetadata>>() => const Success(
        <ProviderAnimeMetadata>[],
      ),
      ProviderUnsupported<List<ProviderAnimeMetadata>>(:final capability) =>
        Failure(UnavailableError('Search is unsupported: $capability.')),
      ProviderFailure<List<ProviderAnimeMetadata>>(
        :final kind,
        :final retryAfter,
      ) =>
        Failure(_mapProviderFailure(kind, retryAfter)),
    };
  }

  Future<Result<List<ProviderAnimeMetadata>>> browsePopular({int limit = 20}) =>
      _browse((provider) => provider.browsePopular(limit: limit));

  Future<Result<List<ProviderAnimeMetadata>>> browseTrending({
    int limit = 20,
  }) => _browse((provider) => provider.browseTrending(limit: limit));

  Future<Result<List<ProviderAnimeMetadata>>> _browse(
    Future<ProviderResult<List<ProviderAnimeMetadata>>> Function(
      PublicAnimeBrowseProvider,
    )
    request,
  ) async {
    final provider = metadataProvider;
    if (provider is! PublicAnimeBrowseProvider) {
      return const Failure(UnavailableError('Public browse is unavailable.'));
    }
    return switch (await request(provider as PublicAnimeBrowseProvider)) {
      ProviderSuccess<List<ProviderAnimeMetadata>>(:final value) => Success(
        value,
      ),
      ProviderNoResults<List<ProviderAnimeMetadata>>() => const Success([]),
      ProviderUnsupported<List<ProviderAnimeMetadata>>() => const Failure(
        UnavailableError(),
      ),
      ProviderFailure<List<ProviderAnimeMetadata>>(
        :final kind,
        :final retryAfter,
      ) =>
        Failure(_mapProviderFailure(kind, retryAfter)),
    };
  }

  Future<ProviderAnimeMetadata?> readCachedDetails(ExternalAnimeId id) async {
    final provider = metadataProvider;
    if (provider is! CachedAnimeMetadataProvider) return null;
    return (provider as CachedAnimeMetadataProvider).readCachedAnime(id);
  }

  Future<Result<ProviderAnimeMetadata>> details(ExternalAnimeId id) async {
    final ProviderResult<ProviderAnimeMetadata> result = await metadataProvider
        .getAnimeByExternalId(id);
    return switch (result) {
      ProviderSuccess<ProviderAnimeMetadata>(:final value) => Success(value),
      ProviderNoResults<ProviderAnimeMetadata>() => const Failure(
        NotFoundAppError('Catalog item not found.'),
      ),
      ProviderUnsupported<ProviderAnimeMetadata>(:final capability) => Failure(
        UnavailableError('Details are unsupported: $capability.'),
      ),
      ProviderFailure<ProviderAnimeMetadata>(:final kind, :final retryAfter) =>
        Failure(_mapProviderFailure(kind, retryAfter)),
    };
  }

  Future<Result<List<CatalogLibraryItem>>> loadLibrary() async {
    final Result<List<LibraryEntry>> listed = await library.list();
    if (listed case Failure<List<LibraryEntry>>(:final error)) {
      return Failure(error);
    }
    final List<LibraryEntry> entries =
        (listed as Success<List<LibraryEntry>>).value;
    final List<CatalogLibraryItem> items = [];
    for (final LibraryEntry entry in entries) {
      ExternalAnimeId? externalId;
      ProviderAnimeMetadata? metadata;
      final Result<AnimeIdentity?> identityResult = await identities.getById(
        entry.animeId,
      );
      if (identityResult case Success<AnimeIdentity?>(:final value)) {
        final ExternalAnimeReference? reference = value?.externalReferences
            .where(
              (ExternalAnimeReference item) =>
                  item.externalId.providerId == metadataProvider.id,
            )
            .firstOrNull;
        if (reference != null) {
          externalId = reference.externalId;
          final Result<ProviderAnimeMetadata> detailsResult = await details(
            reference.externalId,
          );
          if (detailsResult case Success<ProviderAnimeMetadata>(:final value)) {
            metadata = value;
          }
        }
      }
      items.add(
        CatalogLibraryItem(
          entry: entry,
          metadata: metadata,
          externalId: externalId,
        ),
      );
    }
    return Success(List.unmodifiable(items));
  }

  Future<Result<LibraryEntry?>> getLibraryEntry(
    ExternalAnimeId externalId,
  ) async {
    final Result<AnimeIdentity?> resolved = await identities.findByExternalId(
      externalId,
    );
    if (resolved case Failure<AnimeIdentity?>(:final error)) {
      return Failure(error);
    }
    final AnimeIdentity? identity = (resolved as Success<AnimeIdentity?>).value;
    if (identity == null) return const Success(null);
    return library.get(identity.id);
  }

  Future<Result<LibraryEntry?>> getLibraryEntryByAnimeId(AnimeId animeId) =>
      library.get(animeId);

  /// A user pressing Add is the explicit confirmation for this local link.
  /// Concurrent requests for the same external ID share one identity write.
  Future<Result<LibraryEntry>> addToLibrary(
    ProviderAnimeMetadata metadata,
  ) async {
    final Future<Result<LibraryEntry>>? pending =
        _pendingAdds[metadata.externalId];
    if (pending != null) return await pending;

    final Future<Result<LibraryEntry>> operation = _addToLibrary(metadata);
    _pendingAdds[metadata.externalId] = operation;
    try {
      return await operation;
    } finally {
      final Future<Result<LibraryEntry>>? removed = _pendingAdds.remove(
        metadata.externalId,
      );
      if (removed != null) await removed;
    }
  }

  Future<Result<LibraryEntry>> _addToLibrary(
    ProviderAnimeMetadata metadata,
  ) async {
    final Result<AnimeIdentity> identity = await identities
        .getOrCreateForExternalId(
          metadata.externalId,
          evidence: IdentityLinkEvidence.userConfirmed,
        );
    if (identity case Failure<AnimeIdentity>(:final error)) {
      return Failure(error);
    }
    final AnimeId animeId = (identity as Success<AnimeIdentity>).value.id;
    return library.add(animeId);
  }

  Future<Result<LibraryEntry>> setStatus(
    AnimeId animeId,
    LibraryStatus status,
  ) => library.setStatus(animeId, status);

  /// Removes the local library membership while preserving identity/progress.
  Future<Result<void>> removeFromLibrary(AnimeId animeId) =>
      library.remove(animeId);

  Future<Result<PlaybackProgress?>> getProgress(AnimeId animeId) =>
      progress.get(_progressKey(animeId));

  Future<Result<PlaybackProgress>> saveProgress({
    required AnimeId animeId,
    required int positionMs,
  }) async {
    final PlaybackProgress value = PlaybackProgress(
      key: _progressKey(animeId),
      positionMs: positionMs,
      durationMs: null,
      updatedAtUtc: _clock().toUtc(),
    );
    final String? invalid = value.validate();
    if (invalid != null) return Failure(ValidationAppError(invalid));
    final Result<void> saved = await progress.upsert(value);
    if (saved case Failure<void>(:final error)) return Failure(error);
    return Success(value);
  }

  static ProgressKey _progressKey(AnimeId animeId) => ProgressKey(
    contentId: ContentId(animeId.value),
    episodeId: EpisodeId('episode:1'),
  );

  static AppError _mapProviderFailure(
    ProviderFailureKind kind,
    Duration? retryAfter,
  ) => switch (kind) {
    ProviderFailureKind.network => const NetworkError(),
    ProviderFailureKind.timeout => const TimeoutAppError(),
    ProviderFailureKind.rateLimited => RateLimitError(retryAfter: retryAfter),
    ProviderFailureKind.credentialsMissing ||
    ProviderFailureKind.authentication => const AuthAppError(),
    ProviderFailureKind.invalidResponse => const ValidationAppError(
      'Provider response is invalid.',
    ),
    ProviderFailureKind.unavailable => const UnavailableError(),
  };
}
