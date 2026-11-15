import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/synchronization/sync_envelope.dart';
import '../../domain/synchronization/sync_remote.dart';

typedef SyncReply = Future<Result<SyncReceipt>> Function(SyncEnvelope request);

/// Deterministic in-memory test double; it does not model server policy.
final class FakeSyncRemote implements SyncRemote {
  FakeSyncRemote({SyncReply? reply}) : _reply = reply ?? _acknowledge;

  final SyncReply _reply;
  final List<SyncEnvelope> requests = [];

  @override
  Future<Result<SyncReceipt>> submit(SyncEnvelope envelope) async {
    if (envelope.requestId.trim().isEmpty) {
      return const Failure(ValidationAppError('Sync request id is empty.'));
    }
    late final Map<String, Object?> payloadSnapshot;
    try {
      final Object? decoded = jsonDecode(jsonEncode(envelope.payload));
      if (decoded is! Map<String, dynamic>) {
        return const Failure(
          ValidationAppError('Sync payload must be a JSON object.'),
        );
      }
      payloadSnapshot = _freezeMap(decoded);
    } on Object {
      return const Failure(
        ValidationAppError('Sync payload must be JSON-compatible.'),
      );
    }
    requests.add(
      SyncEnvelope(requestId: envelope.requestId, payload: payloadSnapshot),
    );
    try {
      return await _reply(envelope);
    } on Object {
      return const Failure(UnavailableError('Fake remote failed.'));
    }
  }

  static Future<Result<SyncReceipt>> _acknowledge(
    SyncEnvelope envelope,
  ) async => Success(SyncReceipt(requestId: envelope.requestId));

  static Map<String, Object?> _freezeMap(Map<String, dynamic> map) =>
      Map<String, Object?>.unmodifiable(
        map.map((key, value) => MapEntry(key, _freezeValue(value))),
      );

  static Object? _freezeValue(Object? value) => switch (value) {
    final Map<String, dynamic> value => _freezeMap(value),
    final List<Object?> value => List<Object?>.unmodifiable(
      value.map(_freezeValue),
    ),
    _ => value,
  };
}
