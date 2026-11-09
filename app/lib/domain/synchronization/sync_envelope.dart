/// Opaque application-owned payload offered to a remote adapter.
///
/// Identity and payload semantics remain caller-owned until the sync policy is
/// approved; this contract does not merge or order changes.
final class SyncEnvelope {
  const SyncEnvelope({required this.requestId, required this.payload});

  final String requestId;
  final Map<String, Object?> payload;
}

/// Acknowledgment that the remote adapter accepted this request identifier.
final class SyncReceipt {
  const SyncReceipt({required this.requestId});

  final String requestId;
}
