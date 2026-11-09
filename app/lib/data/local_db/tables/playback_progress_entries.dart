import 'package:drift/drift.dart';

class PlaybackProgressEntries extends Table {
  TextColumn get contentId => text().named('content_id')();
  TextColumn get episodeId => text().named('episode_id')();
  IntColumn get positionMs => integer().named('position_ms')();
  IntColumn get durationMs => integer().named('duration_ms').nullable()();
  DateTimeColumn get updatedAtUtc => dateTime().named('updated_at_utc')();
  TextColumn get completion => text().named('completion')();
  IntColumn get revision =>
      integer().named('revision').withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {contentId, episodeId};
}
