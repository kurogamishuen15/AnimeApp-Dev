import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/testing/fake_sync_remote.dart';
import 'package:anime_app/domain/synchronization/sync_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts an opaque request and acknowledges its supplied id', () async {
    final remote = FakeSyncRemote();
    final request = SyncEnvelope(
      requestId: 'caller-request-1',
      payload: {'opaque': 'value'},
    );

    final result = await remote.submit(request);

    expect(result, isA<Success<SyncReceipt>>());
    expect((result as Success<SyncReceipt>).value.requestId, request.requestId);
    expect(remote.requests, hasLength(1));
    expect(remote.requests.single.payload, request.payload);
  });

  test(
    'returns the scripted typed failure and records the exact attempt',
    () async {
      final remote = FakeSyncRemote(
        reply: (_) async => const Failure(UnavailableError()),
      );
      final request = SyncEnvelope(requestId: 'request-offline', payload: {});

      final result = await remote.submit(request);

      expect(result, isA<Failure<SyncReceipt>>());
      expect((result as Failure<SyncReceipt>).error, isA<UnavailableError>());
      expect(remote.requests.map((item) => item.requestId), [
        'request-offline',
      ]);
    },
  );

  test(
    'deep snapshots nested payload collections at submission time',
    () async {
      final remote = FakeSyncRemote();
      final nested = <String, Object?>{
        'items': [
          {'value': 1},
        ],
      };
      await remote.submit(SyncEnvelope(requestId: 'snapshot', payload: nested));

      ((nested['items'] as List).single as Map)['value'] = 2;

      final captured = remote.requests.single.payload;
      expect(((captured['items'] as List).single as Map)['value'], 1);
    },
  );

  test('rejects empty identifiers without invoking the fake reply', () async {
    var calls = 0;
    final remote = FakeSyncRemote(
      reply: (request) async {
        calls++;
        return Success(SyncReceipt(requestId: request.requestId));
      },
    );

    final result = await remote.submit(
      const SyncEnvelope(requestId: ' ', payload: {}),
    );

    expect(result, isA<Failure<SyncReceipt>>());
    expect((result as Failure<SyncReceipt>).error, isA<ValidationAppError>());
    expect(calls, 0);
    expect(remote.requests, isEmpty);
  });
}
