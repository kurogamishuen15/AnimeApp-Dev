import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/local_db/app_database.dart'
    hide ProgressDocument;
import 'package:anime_app/data/local_db/local_progress_repository.dart';
import 'package:anime_app/data/testing/fake_sync_remote.dart';
import 'package:anime_app/domain/progress/progress_document.dart';
import 'package:anime_app/domain/synchronization/sync_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Directory> _temporaryDatabaseDirectory() async {
  final appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app')) {
    throw StateError('F1.12 tests must run from app/.');
  }
  final projectDirectory = appDirectory.parent;
  if (!File('${appDirectory.path}/pubspec.yaml').existsSync() ||
      !File('${projectDirectory.path}/AGENTS.md').existsSync() ||
      !Directory('${projectDirectory.path}/.git').existsSync()) {
    throw StateError('Could not verify project scope for F1.12 cleanup.');
  }
  final directory = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}f1_12'
    '${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

void main() {
  test('remote failure leaves persisted local progress unchanged', () async {
    final directory = await _temporaryDatabaseDirectory();
    final database = AppDatabase.atFile(
      File('${directory.path}/anime_app.sqlite'),
    );
    try {
      final local = LocalProgressRepository(database: database);
      await local.save(
        const ProgressDraft(
          identity: 'opaque-local-record',
          payload: {'opaque': 'preserved'},
        ),
      );

      final remote = FakeSyncRemote(
        reply: (_) async => const Failure(UnavailableError()),
      );
      final response = await remote.submit(
        const SyncEnvelope(
          requestId: 'test-outage',
          payload: {'opaque': 'outbound'},
        ),
      );

      expect(response, isA<Failure<SyncReceipt>>());
      final stored = await local.getByIdentity('opaque-local-record');
      expect(stored, isA<Success<ProgressDocument?>>());
      expect((stored as Success<ProgressDocument?>).value!.payload, {
        'opaque': 'preserved',
      });
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
