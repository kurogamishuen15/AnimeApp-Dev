import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/secure_storage/flutter_secure_credential_store.dart';
import 'package:anime_app/data/secure_storage/secure_storage_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterSecureCredentialStore', () {
    test('writes, reads, and deletes only the access-token key', () async {
      final storage = _FakeSecureStorageApi();
      final store = FlutterSecureCredentialStore(storage: storage);

      final written = await store.writeAccessToken('fake-oauth-token');
      expect(written, isA<Success<void>>());
      expect(storage.values, {'anilist.access_token': 'fake-oauth-token'});

      final read = await store.readAccessToken();
      expect(read, isA<Success<String?>>());
      expect((read as Success<String?>).value, 'fake-oauth-token');

      final deleted = await store.deleteAccessToken();
      expect(deleted, isA<Success<void>>());
      expect(storage.values, isEmpty);
      expect(storage.operations, ['write', 'read', 'delete']);
    });

    test('rejects empty values without touching storage', () async {
      final storage = _FakeSecureStorageApi();
      final result = await FlutterSecureCredentialStore(storage: storage)
          .writeAccessToken('  \n');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationAppError>());
      expect(storage.operations, isEmpty);
    });

    test('maps backend failures without exposing exception contents', () async {
      final storage = _FakeSecureStorageApi()..failure = true;
      final store = FlutterSecureCredentialStore(storage: storage);

      final write = await store.writeAccessToken('fake-oauth-token');
      final read = await store.readAccessToken();
      final delete = await store.deleteAccessToken();

      for (final result in [write, read, delete]) {
        expect(result, isA<Failure<dynamic>>());
        final error = (result as Failure<dynamic>).error;
        expect(error, isA<StorageError>());
        expect(error.toString(), isNot(contains('fake-oauth-token')));
        expect(error.toString(), isNot(contains('keyring-fixture-secret')));
      }
    });

    test('reads missing credential as null', () async {
      final store = FlutterSecureCredentialStore(
        storage: _FakeSecureStorageApi(),
      );
      final result = await store.readAccessToken();

      expect(result, isA<Success<String?>>());
      expect((result as Success<String?>).value, isNull);
    });
  });
}

final class _FakeSecureStorageApi implements SecureStorageApi {
  final Map<String, String> values = {};
  final List<String> operations = [];
  bool failure = false;

  void _maybeFail() {
    if (failure) throw StateError('keyring-fixture-secret');
  }

  @override
  Future<String?> read({required String key}) async {
    operations.add('read');
    _maybeFail();
    return values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    operations.add('write');
    _maybeFail();
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    operations.add('delete');
    _maybeFail();
    values.remove(key);
  }
}
