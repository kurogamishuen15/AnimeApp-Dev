import 'package:drift/drift.dart';

/// One replace-on-search slot; avoids accumulating or bulk storing API data.
class LatestAnimeSearch extends Table {
  TextColumn get slot => text().named('slot')();

  TextColumn get searchQuery => text().named('search_query')();

  IntColumn get page => integer().named('page')();

  IntColumn get perPage => integer().named('per_page')();

  TextColumn get resultJson => text().named('result_json')();

  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column<Object>> get primaryKey => {slot};
}
