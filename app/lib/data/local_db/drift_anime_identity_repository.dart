import 'package:drift/drift.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/catalog/anime_id.dart';
import '../../domain/catalog/anime_identity.dart';
import '../../domain/catalog/anime_identity_repository.dart';
import '../../domain/catalog/external_anime_id.dart';
import 'app_database.dart';

final class DriftAnimeIdentityRepository implements AnimeIdentityRepository {
  DriftAnimeIdentityRepository({
    required this.database,
    required this.idGenerator,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final AnimeIdGenerator idGenerator;
  final DateTime Function() _clock;

  @override
  Future<Result<AnimeIdentity?>> getById(AnimeId id) async {
    try {
      return Success(await _readIdentity(id));
    } on Object {
      return const Failure(StorageError('Could not read anime identity.'));
    }
  }

  @override
  Future<Result<AnimeIdentity?>> findByExternalId(ExternalAnimeId id) async {
    try {
      final ExternalAnimeIdentifier? row =
          await (database.select(database.externalAnimeIdentifiers)..where(
                (table) =>
                    table.providerId.equals(id.providerId.value) &
                    table.externalId.equals(id.value),
              ))
              .getSingleOrNull();
      if (row == null) return const Success(null);
      return Success(await _readIdentity(AnimeId(row.animeId)));
    } on Object {
      return const Failure(StorageError('Could not resolve external ID.'));
    }
  }

  @override
  Future<Result<AnimeIdentity>> getOrCreateForExternalId(
    ExternalAnimeId id, {
    required IdentityLinkEvidence evidence,
  }) async {
    try {
      return await database.transaction(() async {
        final ExternalAnimeIdentifier? existing =
            await (database.select(database.externalAnimeIdentifiers)..where(
                  (table) =>
                      table.providerId.equals(id.providerId.value) &
                      table.externalId.equals(id.value),
                ))
                .getSingleOrNull();
        if (existing != null) {
          final AnimeIdentity? identity = await _readIdentity(
            AnimeId(existing.animeId),
          );
          if (identity == null) {
            return const Failure(
              StorageError('Mapped anime identity could not be read.'),
            );
          }
          return Success(identity);
        }

        final AnimeId animeId = idGenerator.generate();
        await database
            .into(database.animeIdentityEntries)
            .insert(
              AnimeIdentityEntriesCompanion.insert(
                animeId: animeId.value,
                createdAtUtc: _clock().toUtc(),
              ),
            );
        await database
            .into(database.externalAnimeIdentifiers)
            .insert(
              ExternalAnimeIdentifiersCompanion.insert(
                providerId: id.providerId.value,
                externalId: id.value,
                animeId: animeId.value,
                evidence: evidence.name,
                linkedAtUtc: _clock().toUtc(),
              ),
            );
        final AnimeIdentity? created = await _readIdentity(animeId);
        if (created == null) {
          return const Failure(
            StorageError('Created anime identity could not be read.'),
          );
        }
        return Success(created);
      });
    } on Object {
      return const Failure(StorageError('Could not resolve catalog item.'));
    }
  }

  @override
  Future<Result<AnimeIdentity>> createLocalIdentity() async {
    try {
      final AnimeId id = idGenerator.generate();
      final DateTime createdAtUtc = _clock().toUtc();
      await database
          .into(database.animeIdentityEntries)
          .insert(
            AnimeIdentityEntriesCompanion.insert(
              animeId: id.value,
              createdAtUtc: createdAtUtc,
            ),
          );
      final AnimeIdentity? identity = await _readIdentity(id);
      if (identity == null) {
        return const Failure(
          StorageError('Created anime identity could not be read.'),
        );
      }
      return Success(identity);
    } on Object {
      return const Failure(StorageError('Could not create anime identity.'));
    }
  }

  @override
  Future<Result<AnimeIdentity>> linkExternalId({
    required AnimeId animeId,
    required ExternalAnimeId externalId,
    required IdentityLinkEvidence evidence,
  }) async {
    try {
      return await database.transaction(() async {
        final AnimeIdentityEntry? identityRow =
            await (database.select(database.animeIdentityEntries)
                  ..where((table) => table.animeId.equals(animeId.value)))
                .getSingleOrNull();
        if (identityRow == null) {
          return const Failure(NotFoundAppError('Anime identity not found.'));
        }

        final ExternalAnimeIdentifier? existing =
            await (database.select(database.externalAnimeIdentifiers)..where(
                  (table) =>
                      table.providerId.equals(externalId.providerId.value) &
                      table.externalId.equals(externalId.value),
                ))
                .getSingleOrNull();
        if (existing != null && existing.animeId != animeId.value) {
          return const Failure(
            ValidationAppError(
              'External ID is already linked to another anime identity.',
            ),
          );
        }
        if (existing == null) {
          await database
              .into(database.externalAnimeIdentifiers)
              .insert(
                ExternalAnimeIdentifiersCompanion.insert(
                  providerId: externalId.providerId.value,
                  externalId: externalId.value,
                  animeId: animeId.value,
                  evidence: evidence.name,
                  linkedAtUtc: _clock().toUtc(),
                ),
              );
        }
        final AnimeIdentity? identity = await _readIdentity(animeId);
        if (identity == null) {
          return const Failure(
            StorageError('Linked anime identity could not be read.'),
          );
        }
        return Success(identity);
      });
    } on Object {
      return const Failure(StorageError('Could not link external anime ID.'));
    }
  }

  @override
  Future<Result<AnimeIdentity>> addRelationship({
    required AnimeId sourceId,
    required AnimeId targetId,
    required AnimeRelationshipKind kind,
    required IdentityLinkEvidence evidence,
  }) async {
    if (sourceId == targetId) {
      return const Failure(
        ValidationAppError('An anime cannot relate to itself.'),
      );
    }
    try {
      return await database.transaction(() async {
        final AnimeIdentityEntry? source =
            await (database.select(database.animeIdentityEntries)
                  ..where((table) => table.animeId.equals(sourceId.value)))
                .getSingleOrNull();
        final AnimeIdentityEntry? target =
            await (database.select(database.animeIdentityEntries)
                  ..where((table) => table.animeId.equals(targetId.value)))
                .getSingleOrNull();
        if (source == null || target == null) {
          return const Failure(NotFoundAppError('Related anime not found.'));
        }
        await database
            .into(database.animeIdentityRelationships)
            .insert(
              AnimeIdentityRelationshipsCompanion.insert(
                sourceAnimeId: sourceId.value,
                targetAnimeId: targetId.value,
                relationshipKind: kind.name,
                evidence: evidence.name,
                linkedAtUtc: _clock().toUtc(),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        final AnimeIdentity? identity = await _readIdentity(sourceId);
        if (identity == null) {
          return const Failure(
            StorageError('Related anime identity could not be read.'),
          );
        }
        return Success(identity);
      });
    } on Object {
      return const Failure(StorageError('Could not save anime relationship.'));
    }
  }

  Future<AnimeIdentity?> _readIdentity(AnimeId id) async {
    final AnimeIdentityEntry? row = await (database.select(
      database.animeIdentityEntries,
    )..where((table) => table.animeId.equals(id.value))).getSingleOrNull();
    if (row == null) return null;

    final List<ExternalAnimeIdentifier> externalRows = await (database.select(
      database.externalAnimeIdentifiers,
    )..where((table) => table.animeId.equals(id.value))).get();
    final List<AnimeIdentityRelationship> relationshipRows =
        await (database.select(
          database.animeIdentityRelationships,
        )..where((table) => table.sourceAnimeId.equals(id.value))).get();

    return AnimeIdentity(
      id: id,
      createdAtUtc: row.createdAtUtc.toUtc(),
      externalReferences: externalRows.map(
        (ExternalAnimeIdentifier link) => ExternalAnimeReference(
          externalId: ExternalAnimeId(
            providerId: MetadataProviderId(link.providerId),
            value: link.externalId,
          ),
          evidence: IdentityLinkEvidence.values.byName(link.evidence),
          linkedAtUtc: link.linkedAtUtc.toUtc(),
        ),
      ),
      relationships: relationshipRows.map(
        (AnimeIdentityRelationship relation) => AnimeRelationship(
          targetId: AnimeId(relation.targetAnimeId),
          kind: AnimeRelationshipKind.values.byName(relation.relationshipKind),
          evidence: IdentityLinkEvidence.values.byName(relation.evidence),
          linkedAtUtc: relation.linkedAtUtc.toUtc(),
        ),
      ),
    );
  }
}
