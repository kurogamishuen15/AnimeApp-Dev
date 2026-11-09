import '../../core/result/result.dart';
import 'sync_envelope.dart';

/// Remote boundary only. It intentionally leaves retries, conflict handling,
/// ordering, deletion, and idempotency policy to a future approved protocol.
abstract interface class SyncRemote {
  Future<Result<SyncReceipt>> submit(SyncEnvelope envelope);
}
