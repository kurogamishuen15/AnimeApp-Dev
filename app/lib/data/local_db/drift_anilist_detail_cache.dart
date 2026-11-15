import 'package:drift/drift.dart';

import 'app_database.dart';

/// Bounded persistent storage for explicitly requested AniList IDs.
final class DriftAniListDetailCache {
  const DriftAniListDetailCache(this.database);
  final AppDatabase database;

  Future<({String payload, DateTime fetchedAt})?> read(int id) async {
    final row = await database
        .customSelect(
          'SELECT payload, fetched_at FROM anilist_detail_cache WHERE media_id = ?',
          variables: [Variable<int>(id)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      payload: row.read<String>('payload'),
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('fetched_at'),
        isUtc: true,
      ),
    );
  }

  Future<List<String>> findByTitle(String title, int limit, int offset) async {
    final rows = await database
        .customSelect(
          r'''
      SELECT payload FROM anilist_detail_cache
      WHERE json_valid(payload) AND (
        instr(lower(coalesce(json_extract(payload, '$[0].romajiTitle'), '')), lower(?)) > 0
        OR instr(lower(coalesce(json_extract(payload, '$[0].englishTitle'), '')), lower(?)) > 0
        OR instr(lower(coalesce(json_extract(payload, '$[0].nativeTitle'), '')), lower(?)) > 0
      )
      ORDER BY fetched_at DESC, media_id DESC LIMIT ? OFFSET ?
      ''',
          variables: [
            Variable<String>(title),
            Variable<String>(title),
            Variable<String>(title),
            Variable<int>(limit),
            Variable<int>(offset),
          ],
        )
        .get();
    return rows.map((row) => row.read<String>('payload')).toList();
  }

  Future<void> write(int id, String payload, DateTime fetchedAt) =>
      database.transaction(() async {
        await database.customStatement(
          'INSERT OR REPLACE INTO anilist_detail_cache VALUES (?, ?, ?)',
          [id, payload, fetchedAt.millisecondsSinceEpoch],
        );
        await database.customStatement('''
          DELETE FROM anilist_detail_cache WHERE media_id IN (
            SELECT media_id FROM anilist_detail_cache
            ORDER BY fetched_at DESC, media_id DESC LIMIT -1 OFFSET 64
          )
        ''');
      });
}
