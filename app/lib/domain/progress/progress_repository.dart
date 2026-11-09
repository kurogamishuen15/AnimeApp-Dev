import '../../core/result/result.dart';
import 'progress_document.dart';

/// Local-first contract for storing opaque progress documents by caller-owned
/// stable identity. It has no remote synchronization or conflict policy.
abstract interface class ProgressRepository {
  Future<Result<void>> save(ProgressDraft draft);

  Future<Result<ProgressDocument?>> getByIdentity(String identity);
}
