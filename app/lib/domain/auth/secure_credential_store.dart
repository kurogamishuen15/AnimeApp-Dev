import '../../core/result/result.dart';

/// Domain-facing access-token storage contract.
///
/// Implementations must use an operating-system secure store and must never
/// fall back to ordinary preferences, files, or the settings database.
abstract interface class SecureCredentialStore {
  Future<Result<String?>> readAccessToken();

  Future<Result<void>> writeAccessToken(String accessToken);

  Future<Result<void>> deleteAccessToken();
}
