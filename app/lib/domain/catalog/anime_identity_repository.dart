import '../../core/result/result.dart';
import 'anime_id.dart';
import 'anime_identity.dart';
import 'external_anime_id.dart';
import 'metadata_provider.dart';

abstract interface class AnimeIdentityRepository {
  Future<Result<AnimeIdentity?>> getById(AnimeId id);

  Future<Result<AnimeIdentity?>> findByExternalId(ExternalAnimeId id);

  /// Returns the existing exact mapping or atomically creates a local identity
  /// and records this explicit association.
  Future<Result<AnimeIdentity>> getOrCreateForExternalId(
    ExternalAnimeId id, {
    required IdentityLinkEvidence evidence,
  });

  Future<Result<AnimeIdentity>> createLocalIdentity();

  /// Adds an explicit cross-reference; it never reassigns an existing mapping.
  Future<Result<AnimeIdentity>> linkExternalId({
    required AnimeId animeId,
    required ExternalAnimeId externalId,
    required IdentityLinkEvidence evidence,
  });

  Future<Result<AnimeIdentity>> addRelationship({
    required AnimeId sourceId,
    required AnimeId targetId,
    required AnimeRelationshipKind kind,
    required IdentityLinkEvidence evidence,
  });
}

sealed class AnimeIdentityResolution {
  const AnimeIdentityResolution();
}

final class IdentityResolved extends AnimeIdentityResolution {
  const IdentityResolved(this.animeId);

  final AnimeId animeId;
}

final class IdentityUnresolved extends AnimeIdentityResolution {
  const IdentityUnresolved();
}

final class IdentityAmbiguous extends AnimeIdentityResolution {
  const IdentityAmbiguous(this.candidates);

  final Set<AnimeId> candidates;
}

/// Conservative resolver: only exact, namespaced IDs supplied as verified
/// references may resolve automatically. Similar titles remain unresolved.
final class AnimeIdentityResolver {
  const AnimeIdentityResolver();

  AnimeIdentityResolution resolve({
    required Iterable<VerifiedExternalAnimeReference> references,
    required Map<ExternalAnimeId, AnimeId> knownMappings,
  }) {
    final Set<AnimeId> matches = {};
    for (final VerifiedExternalAnimeReference reference in references) {
      final AnimeId? knownId = knownMappings[reference.externalId];
      if (knownId != null) {
        matches.add(knownId);
      }
    }
    return switch (matches.length) {
      0 => const IdentityUnresolved(),
      1 => IdentityResolved(matches.single),
      _ => IdentityAmbiguous(Set.unmodifiable(matches)),
    };
  }
}
