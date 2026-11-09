import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/auth/secure_credential_store.dart';
import 'flutter_secure_storage_api.dart';
import 'secure_storage_api.dart';

/// `flutter_secure_storage` adapter for a single AniList access token.
///
/// Errors deliberately omit plugin exception details because they may include
/// keyring state or secret values. No fallback to non-secure storage exists.
final class FlutterSecureCredentialStore implements SecureCredentialStore {
  FlutterSecureCredentialStore({SecureStorageApi? storage})
    : _storage = storage ?? FlutterSecureStorageApi();

  static const _accessTokenKey = 'anilist.access_token';

  final SecureStorageApi _storage;

  @override
  Future<Result<String?>> readAccessToken() async {
    try {
      return Success(await _storage.read(key: _accessTokenKey));
    } on Object {
      return const Failure(StorageError());
    }
  }

  @override
  Future<Result<void>> writeAccessToken(String accessToken) async {
    if (accessToken.trim().isEmpty) {
      return const Failure(ValidationAppError());
    }
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      return const Success(null);
    } on Object {
      return const Failure(StorageError());
    }
  }

  @override
  Future<Result<void>> deleteAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      return const Success(null);
    } on Object {
      return const Failure(StorageError());
    }
  }
}
