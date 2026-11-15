import 'dart:math';

import 'package:anime_app/data/local_db/uuid_anime_id_generator.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/anime_identity.dart';
import 'package:anime_app/domain/catalog/anime_identity_repository.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/metadata_provider.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:anime_app/domain/catalog/provider_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalog identity contracts', () {
    test('normalizes internal IDs and compares by value', () {
      final AnimeId first = AnimeId('  ANIME:ABC-123  ');
      final AnimeId second = AnimeId('anime:abc-123');

      expect(first.value, 'anime:abc-123');
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('local UUID generator emits distinct namespaced UUIDv4 values', () {
      final UuidAnimeIdGenerator generator = UuidAnimeIdGenerator(
        random: Random(42),
      );
      final AnimeId first = generator.generate();
      final AnimeId second = generator.generate();
      final RegExp uuidV4 = RegExp(
        r'^anime:[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      expect(uuidV4.hasMatch(first.value), isTrue);
      expect(uuidV4.hasMatch(second.value), isTrue);
      expect(first, isNot(second));
    });

    test('rejects empty, whitespace, and non-ASCII internal IDs', () {
      expect(() => AnimeId(''), throwsArgumentError);
      expect(() => AnimeId('   '), throwsArgumentError);
      expect(() => AnimeId('anime:á'), throwsArgumentError);
    });

    test('external IDs use a provider namespace and unambiguous key', () {
      final ExternalAnimeId anilist = ExternalAnimeId(
        providerId: MetadataProviderId(' AniList '),
        value: '1:23',
      );
      final ExternalAnimeId kitsu = ExternalAnimeId(
        providerId: MetadataProviderId('kitsu'),
        value: '1:23',
      );
      final ExternalAnimeId another = ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '1:2',
      );

      expect(anilist.providerId.value, 'anilist');
      expect(anilist, isNot(kitsu));
      expect(anilist, isNot(another));
      expect(anilist.canonicalKey, isNot(another.canonicalKey));
      expect(
        () => ExternalAnimeId(
          providerId: MetadataProviderId('anilist'),
          value: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('identity rejects duplicate aliases and self relationships', () {
      final ExternalAnimeId externalId = ExternalAnimeId(
        providerId: MetadataProviderId('anilist'),
        value: '1',
      );
      final ExternalAnimeReference reference = ExternalAnimeReference(
        externalId: externalId,
        evidence: IdentityLinkEvidence.userConfirmed,
        linkedAtUtc: DateTime.utc(2026),
      );

      expect(
        () => AnimeIdentity(
          id: AnimeId('anime:one'),
          createdAtUtc: DateTime.utc(2026),
          externalReferences: [reference, reference],
        ),
        throwsArgumentError,
      );
      expect(
        () => AnimeIdentity(
          id: AnimeId('anime:one'),
          createdAtUtc: DateTime.utc(2026),
          relationships: [
            AnimeRelationship(
              targetId: AnimeId('anime:one'),
              kind: AnimeRelationshipKind.sequel,
              evidence: IdentityLinkEvidence.userConfirmed,
              linkedAtUtc: DateTime.utc(2026),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('resolver uses only exact verified IDs and surfaces ambiguity', () {
      const AnimeIdentityResolver resolver = AnimeIdentityResolver();
      final ExternalAnimeId knownId = ExternalAnimeId(
        providerId: MetadataProviderId('provider-a'),
        value: 'same-title-1',
      );
      final ExternalAnimeId similarTitleId = ExternalAnimeId(
        providerId: MetadataProviderId('provider-b'),
        value: 'same-title-2',
      );
      final AnimeId animeId = AnimeId('anime:one');

      final AnimeIdentityResolution unresolved = resolver.resolve(
        references: [
          VerifiedExternalAnimeReference(
            externalId: similarTitleId,
            evidence: IdentityLinkEvidence.trustedProviderCrossReference,
          ),
        ],
        knownMappings: {knownId: animeId},
      );
      expect(unresolved, isA<IdentityUnresolved>());

      final AnimeIdentityResolution resolved = resolver.resolve(
        references: [
          VerifiedExternalAnimeReference(
            externalId: knownId,
            evidence: IdentityLinkEvidence.verifiedOfficialReference,
          ),
        ],
        knownMappings: {knownId: animeId},
      );
      expect(resolved, isA<IdentityResolved>());
      expect((resolved as IdentityResolved).animeId, animeId);

      final AnimeIdentityResolution ambiguous = resolver.resolve(
        references: [
          VerifiedExternalAnimeReference(
            externalId: knownId,
            evidence: IdentityLinkEvidence.trustedProviderCrossReference,
          ),
          VerifiedExternalAnimeReference(
            externalId: similarTitleId,
            evidence: IdentityLinkEvidence.verifiedOfficialReference,
          ),
        ],
        knownMappings: {knownId: animeId, similarTitleId: AnimeId('anime:two')},
      );
      expect(ambiguous, isA<IdentityAmbiguous>());
    });
  });

  group('provider contracts', () {
    test('registry is disabled by default and sorts enabled capabilities', () {
      final MetadataProvider first = _FakeMetadataProvider(
        id: MetadataProviderId('first'),
        capabilities: {MetadataCapability.publicSearch},
      );
      final MetadataProvider second = _FakeMetadataProvider(
        id: MetadataProviderId('second'),
        capabilities: {MetadataCapability.publicSearch},
      );
      final MetadataProviderRegistry disabled = MetadataProviderRegistry(
        providers: [first, second],
      );
      expect(disabled.enabledFor(MetadataCapability.publicSearch), isEmpty);

      final MetadataProviderRegistry enabled = MetadataProviderRegistry(
        providers: [first, second],
        configurations: [
          MetadataProviderConfiguration(
            providerId: first.id,
            enabled: true,
            priority: 20,
          ),
          MetadataProviderConfiguration(
            providerId: second.id,
            enabled: true,
            priority: 10,
          ),
        ],
      );
      expect(
        enabled
            .enabledFor(MetadataCapability.publicSearch)
            .map((MetadataProvider provider) => provider.id.value),
        ['second', 'first'],
      );
      expect(enabled.enabledFor(MetadataCapability.episodeMetadata), isEmpty);
    });

    test('provider failures expose retry policy without leaking payloads', () {
      const ProviderFailure<void> rateLimit = ProviderFailure(
        ProviderFailureKind.rateLimited,
        retryAfter: Duration(seconds: 15),
      );
      const ProviderFailure<void> missingCredentials = ProviderFailure(
        ProviderFailureKind.credentialsMissing,
      );
      const ProviderUnsupported<void> unsupported = ProviderUnsupported(
        'episodeMetadata',
      );

      expect(rateLimit.isRetryable, isTrue);
      expect(rateLimit.retryAfter, const Duration(seconds: 15));
      expect(missingCredentials.isRetryable, isFalse);
      expect(unsupported.capability, 'episodeMetadata');
      expect(
        const ProviderNoResults<List<ProviderAnimeMetadata>>(),
        isA<ProviderNoResults<List<ProviderAnimeMetadata>>>(),
      );
    });

    test('registry snapshots provider capabilities at registration', () {
      final Set<MetadataCapability> mutableCapabilities = {
        MetadataCapability.publicSearch,
      };
      final MetadataProvider provider = _FakeMetadataProvider(
        id: MetadataProviderId('mutable'),
        capabilities: mutableCapabilities,
      );
      final MetadataProviderRegistry registry = MetadataProviderRegistry(
        providers: [provider],
        configurations: [
          MetadataProviderConfiguration(providerId: provider.id, enabled: true),
        ],
      );

      mutableCapabilities.clear();

      expect(registry.enabledFor(MetadataCapability.publicSearch), [
        same(provider),
      ]);
    });
  });
}

final class _FakeMetadataProvider implements MetadataProvider {
  const _FakeMetadataProvider({required this.id, required this.capabilities});

  @override
  final MetadataProviderId id;

  @override
  final Set<MetadataCapability> capabilities;

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
