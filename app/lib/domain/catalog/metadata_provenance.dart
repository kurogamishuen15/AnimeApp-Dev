import 'external_anime_id.dart';

/// Provenance for one provider response. Merged fields must retain their own
/// provenance; this response-level value is not permission to republish data.
final class MetadataProvenance {
  MetadataProvenance({
    required this.externalId,
    required DateTime retrievedAtUtc,
    DateTime? providerUpdatedAtUtc,
  }) : retrievedAtUtc = _requireUtc(retrievedAtUtc, 'retrievedAtUtc'),
       providerUpdatedAtUtc = providerUpdatedAtUtc == null
           ? null
           : _requireUtc(providerUpdatedAtUtc, 'providerUpdatedAtUtc');

  final ExternalAnimeId externalId;
  final DateTime retrievedAtUtc;
  final DateTime? providerUpdatedAtUtc;
}

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'Timestamp must be UTC.');
  }
  return value;
}
