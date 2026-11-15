import 'anime_id.dart';
import 'external_anime_id.dart';

enum IdentityLinkEvidence {
  trustedProviderCrossReference,
  verifiedOfficialReference,
  userConfirmed,
}

enum AnimeRelationshipKind {
  season,
  sequel,
  prequel,
  movie,
  special,
  ova,
  alternateVersion,
}

final class ExternalAnimeReference {
  ExternalAnimeReference({
    required this.externalId,
    required this.evidence,
    required DateTime linkedAtUtc,
  }) : linkedAtUtc = _requireUtc(linkedAtUtc, 'linkedAtUtc');

  final ExternalAnimeId externalId;
  final IdentityLinkEvidence evidence;
  final DateTime linkedAtUtc;
}

final class AnimeRelationship {
  AnimeRelationship({
    required this.targetId,
    required this.kind,
    required this.evidence,
    required DateTime linkedAtUtc,
  }) : linkedAtUtc = _requireUtc(linkedAtUtc, 'linkedAtUtc');

  final AnimeId targetId;
  final AnimeRelationshipKind kind;
  final IdentityLinkEvidence evidence;
  final DateTime linkedAtUtc;
}

/// The local identity and its explicitly verified provider cross-references.
/// Metadata and user-owned library/progress values remain separate records.
final class AnimeIdentity {
  AnimeIdentity({
    required this.id,
    required DateTime createdAtUtc,
    Iterable<ExternalAnimeReference> externalReferences = const [],
    Iterable<AnimeRelationship> relationships = const [],
  }) : createdAtUtc = _requireUtc(createdAtUtc, 'createdAtUtc'),
       externalReferences = List.unmodifiable(externalReferences),
       relationships = List.unmodifiable(relationships) {
    final Set<ExternalAnimeId> externalIds = {};
    for (final ExternalAnimeReference reference in this.externalReferences) {
      if (!externalIds.add(reference.externalId)) {
        throw ArgumentError('Duplicate external identity reference.');
      }
    }
    for (final AnimeRelationship relationship in this.relationships) {
      if (relationship.targetId == id) {
        throw ArgumentError('An anime cannot relate to itself.');
      }
    }
  }

  final AnimeId id;
  final DateTime createdAtUtc;
  final List<ExternalAnimeReference> externalReferences;
  final List<AnimeRelationship> relationships;
}

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'Timestamp must be UTC.');
  }
  return value;
}
