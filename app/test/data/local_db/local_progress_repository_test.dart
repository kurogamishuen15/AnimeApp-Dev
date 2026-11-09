import 'dart:io';

import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/local_db/app_database.dart'
    hide ProgressDocument;
import 'package:anime_app/data/local_db/local_progress_repository.dart';
import 'package:anime_app/domain/progress/progress_document.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Directory> _temporaryDatabaseDirectory() async {
  final appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app')) {
    throw StateError('F1.10 tests must run from app/.');
  }
  final projectDirectory = appDirectory.parent;
  if (!File('${appDirectory.path}/pubspec.yaml').existsSync() ||
      !File('${projectDirectory.path}/AGENTS.md').existsSync() ||
      !Directory('${projectDirectory.path}/.git').existsSync()) {
    throw StateError('Could not verify project scope for F1.10 cleanup.');
  }
  final directory = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}f1_10'
    '${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

void main() {
  test(
    'saves and retrieves an opaque document across database reopen',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final file = File('${directory.path}/anime_app.sqlite');
      final fixedInstant = DateTime.parse('2026-11-09T12:30:00-05:00');
      var database = AppDatabase.atFile(file);
      try {
        final repository = LocalProgressRepository(
          database: database,
          clock: () => fixedInstant,
        );
        final saved = await repository.save(
          ProgressDraft(
            identity: 'caller-defined-opaque-id',
            payload: {'callerField': 'opaque-value'},
          ),
        );
        expect(saved, isA<Success<void>>());
        await database.close();

        database = AppDatabase.atFile(file);
        final loaded = await LocalProgressRepository(database: database)
            .getByIdentity('caller-defined-opaque-id');
        expect(loaded, isA<Success<ProgressDocument?>>());
        final document = (loaded as Success<ProgressDocument?>).value!;
        expect(document.payload, {'callerField': 'opaque-value'});
        expect(document.updatedAtUtc, DateTime.utc(2026, 11, 9, 17, 30));
        expect(document.updatedAtUtc.isUtc, isTrue);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('replaces the payload for the exact caller-supplied identity', () async {
    final directory = await _temporaryDatabaseDirectory();
    final database = AppDatabase.atFile(
      File('${directory.path}/anime_app.sqlite'),
    );
    try {
      final repository = LocalProgressRepository(database: database);
      await repository.save(
        ProgressDraft(identity: 'id-a', payload: {'revision': 1}),
      );
      await repository.save(
        ProgressDraft(identity: 'id-a', payload: {'revision': 2}),
      );

      final rows = await database.select(database.progressDocuments).get();
      expect(rows, hasLength(1));
      final loaded = await repository.getByIdentity('id-a');
      expect((loaded as Success<ProgressDocument?>).value!.payload, {
        'revision': 2,
      });
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'reports absent records and rejects invalid payloads/identity',
    () async {
      final directory = await _temporaryDatabaseDirectory();
      final database = AppDatabase.atFile(
        File('${directory.path}/anime_app.sqlite'),
      );
      try {
        final repository = LocalProgressRepository(database: database);
        final absent = await repository.getByIdentity('missing');
        expect(absent, isA<Success<ProgressDocument?>>());
        expect((absent as Success<ProgressDocument?>).value, isNull);

        final blank = await repository.getByIdentity(' ');
        expect(blank, isA<Failure<ProgressDocument?>>());

        final invalidPayload = <String, Object?>{'unsupported': Object()};
        final invalid = await repository.save(
          ProgressDraft(identity: 'id-b', payload: invalidPayload),
        );
        expect(invalid, isA<Failure<void>>());
        expect(
          await database.select(database.progressDocuments).get(),
          isEmpty,
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
