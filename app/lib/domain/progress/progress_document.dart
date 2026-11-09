/// A caller-identified, JSON-compatible persisted progress document.
///
/// Its payload is intentionally opaque until the owner defines the actual
/// progress fields and temporal/business semantics.
final class ProgressDocument {
  const ProgressDocument({
    required this.identity,
    required this.payload,
    required this.updatedAtUtc,
  });

  final String identity;
  final Map<String, Object?> payload;

  /// Technical persistence instant, normalized to UTC by the local adapter.
  final DateTime updatedAtUtc;
}

/// Input for a local progress write. The persistence adapter supplies the
/// technical write timestamp so callers cannot imply business-time meaning.
final class ProgressDraft {
  const ProgressDraft({required this.identity, required this.payload});

  final String identity;
  final Map<String, Object?> payload;
}
