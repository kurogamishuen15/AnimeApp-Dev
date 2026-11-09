/// Small injectable surface over the platform secure-storage plugin.
///
/// The interface keeps tests independent of a desktop keyring and allows
/// failure behavior to be exercised without accessing user credentials.
abstract interface class SecureStorageApi {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});
}
