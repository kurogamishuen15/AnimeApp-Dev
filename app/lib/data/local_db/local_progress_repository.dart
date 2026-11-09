import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/progress/progress_document.dart';
import '../../domain/progress/progress_repository.dart';
import 'app_database.dart' hide ProgressDocument;

final class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository({required this.database, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final DateTime Function() _clock;

  @override
  Future<Result<void>> save(ProgressDraft draft) async {
    if (draft.identity.trim().isEmpty) {
      return const Failure(ValidationAppError('Progress identity is empty.'));
    }

    late final String encodedPayload;
    try {
      encodedPayload = jsonEncode(draft.payload);
    } on Object {
      return const Failure(
        ValidationAppError('Progress payload must be JSON-compatible.'),
      );
    }

    try {
      await database
          .into(database.progressDocuments)
          .insertOnConflictUpdate(
            ProgressDocumentsCompanion.insert(
              documentKey: draft.identity,
              payloadJson: encodedPayload,
              updatedAt: _clock().toUtc(),
            ),
          );
      return const Success<void>(null);
    } on Object {
      return const Failure(StorageError('Could not save local progress.'));
    }
  }

  @override
  Future<Result<ProgressDocument?>> getByIdentity(String identity) async {
    if (identity.trim().isEmpty) {
      return const Failure(ValidationAppError('Progress identity is empty.'));
    }

    try {
      final row =
          await (database.select(database.progressDocuments)
                ..where((table) => table.documentKey.equals(identity)))
              .getSingleOrNull();
      if (row == null) return const Success(null);

      final Object? decoded = jsonDecode(row.payloadJson);
      if (decoded is! Map<String, dynamic>) {
        return const Failure(StorageError('Stored progress is invalid.'));
      }
      return Success(
        ProgressDocument(
          identity: row.documentKey,
          payload: Map<String, Object?>.from(decoded),
          updatedAtUtc: row.updatedAt.toUtc(),
        ),
      );
    } on Object {
      return const Failure(StorageError('Could not read local progress.'));
    }
  }
}
