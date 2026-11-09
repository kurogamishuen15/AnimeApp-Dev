import 'package:drift/drift.dart';

/// Opaque durable progress document; business semantics belong to F1.10.
class ProgressDocuments extends Table {
  TextColumn get documentKey => text().named('document_key')();

  TextColumn get payloadJson => text().named('payload_json')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {documentKey};
}
