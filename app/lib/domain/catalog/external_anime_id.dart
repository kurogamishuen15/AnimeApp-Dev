/// Namespace for an independently operated metadata provider.
final class MetadataProviderId {
  factory MetadataProviderId(String value) {
    final String normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(normalized)) {
      throw ArgumentError.value(
        value,
        'value',
        'Provider IDs must be normalized ASCII slugs.',
      );
    }
    return MetadataProviderId._(normalized);
  }

  const MetadataProviderId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is MetadataProviderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Provider-scoped identifier. The provider may define case sensitivity;
/// AnimeApp trims but otherwise preserves the provider's external value.
final class ExternalAnimeId {
  factory ExternalAnimeId({
    required MetadataProviderId providerId,
    required String value,
  }) {
    final String normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 256) {
      throw ArgumentError.value(value, 'value', 'Invalid external anime ID.');
    }
    return ExternalAnimeId._(providerId, normalized);
  }

  const ExternalAnimeId._(this.providerId, this.value);

  final MetadataProviderId providerId;
  final String value;

  /// Length-prefix encoding is unambiguous even if either value contains `:`.
  String get canonicalKey =>
      '${providerId.value.length}:${providerId.value}${value.length}:$value';

  @override
  bool operator ==(Object other) =>
      other is ExternalAnimeId &&
      other.providerId == providerId &&
      other.value == value;

  @override
  int get hashCode => Object.hash(providerId, value);

  @override
  String toString() => '${providerId.value}:$value';
}
