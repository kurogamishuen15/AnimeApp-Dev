import 'anime_identity.dart';
import 'external_anime_id.dart';
import 'provider_anime_metadata.dart';
import 'provider_result.dart';

enum MetadataCapability { publicSearch, animeDetails, episodeMetadata }

/// Read-only metadata source. Account synchronization is a separate port.
abstract interface class MetadataProvider {
  MetadataProviderId get id;

  Set<MetadataCapability> get capabilities;

  Future<ProviderResult<List<ProviderAnimeMetadata>>> searchAnime(
    String query, {
    int limit = 20,
  });

  Future<ProviderResult<ProviderAnimeMetadata>> getAnimeByExternalId(
    ExternalAnimeId id,
  );

  Future<ProviderResult<List<ProviderEpisodeMetadata>>> getEpisodes(
    ExternalAnimeId animeId,
  );

  Future<ProviderResult<ProviderHealth>> checkHealth();
}

final class MetadataProviderConfiguration {
  const MetadataProviderConfiguration({
    required this.providerId,
    this.enabled = false,
    this.priority = 100,
  });

  final MetadataProviderId providerId;
  final bool enabled;
  final int priority;
}

/// Explicit allowlist. A registered adapter is disabled unless enabled by
/// configuration; no provider is queried merely because it is installed.
final class MetadataProviderRegistry {
  MetadataProviderRegistry({
    required Iterable<MetadataProvider> providers,
    Iterable<MetadataProviderConfiguration> configurations = const [],
  }) : _providers = List.unmodifiable(providers),
       _configurations = List.unmodifiable(configurations) {
    final Set<MetadataProviderId> providerIds = {};
    for (final MetadataProvider provider in _providers) {
      if (!providerIds.add(provider.id)) {
        throw ArgumentError('Metadata provider IDs must be unique.');
      }
    }

    final Set<MetadataProviderId> configuredIds = {};
    for (final MetadataProviderConfiguration configuration in _configurations) {
      if (!configuredIds.add(configuration.providerId) ||
          !providerIds.contains(configuration.providerId)) {
        throw ArgumentError('Provider configuration is unknown or repeated.');
      }
    }

    _capabilitiesByProvider = Map.unmodifiable({
      for (final MetadataProvider provider in _providers)
        provider.id: Set<MetadataCapability>.unmodifiable(
          provider.capabilities,
        ),
    });
  }

  final List<MetadataProvider> _providers;
  final List<MetadataProviderConfiguration> _configurations;
  late final Map<MetadataProviderId, Set<MetadataCapability>>
  _capabilitiesByProvider;

  List<MetadataProvider> enabledFor(MetadataCapability capability) {
    final Map<MetadataProviderId, MetadataProviderConfiguration> settings = {
      for (final MetadataProviderConfiguration configuration in _configurations)
        configuration.providerId: configuration,
    };
    final List<MetadataProvider> result = _providers.where((provider) {
      final MetadataProviderConfiguration? configuration =
          settings[provider.id];
      return configuration?.enabled == true &&
          _capabilitiesByProvider[provider.id]!.contains(capability);
    }).toList();
    result.sort((first, second) {
      final int firstPriority = settings[first.id]!.priority;
      final int secondPriority = settings[second.id]!.priority;
      return firstPriority.compareTo(secondPriority);
    });
    return List.unmodifiable(result);
  }
}

/// Evidence-bearing cross-reference received from a provider or verified by
/// the owner. Titles alone are never sufficient evidence for identity merges.
final class VerifiedExternalAnimeReference {
  const VerifiedExternalAnimeReference({
    required this.externalId,
    required this.evidence,
  });

  final ExternalAnimeId externalId;
  final IdentityLinkEvidence evidence;
}

/// Optional public browse capability, independent of account authentication.
abstract interface class PublicAnimeBrowseProvider {
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browsePopular({
    int limit = 20,
  });
  Future<ProviderResult<List<ProviderAnimeMetadata>>> browseTrending({
    int limit = 20,
  });
}

abstract interface class CachedAnimeMetadataProvider {
  Future<ProviderAnimeMetadata?> readCachedAnime(ExternalAnimeId id);
}
