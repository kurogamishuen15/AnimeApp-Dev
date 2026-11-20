import 'package:drift/drift.dart';

import '../local_db/app_database.dart';

/// Bounded storage for public popular/trending pages. Keeps the newest
/// [maxFeeds] keys; payloads are normalized AniList summaries, never URLs with
/// signatures or account data.
final class DriftAniListBrowseCache {
  const DriftAniListBrowseCache(this.database);

  final AppDatabase database;

  static const int maxFeeds = 16;

  Future<({String payload, DateTime fetchedAt})?> read(String feedKey) async {
    final row = await database
        .customSelect(
          'SELECT payload, fetched_at FROM anilist_browse_cache WHERE feed_key = ?',
          variables: [Variable<String>(feedKey)],
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

  Future<void> write(String feedKey, String payload, DateTime fetchedAt) =>
      database.transaction(() async {
        await database.customStatement(
          'INSERT OR REPLACE INTO anilist_browse_cache VALUES (?, ?, ?)',
          [feedKey, payload, fetchedAt.millisecondsSinceEpoch],
        );
        await database.customStatement(
          '''
          DELETE FROM anilist_browse_cache WHERE feed_key IN (
            SELECT feed_key FROM anilist_browse_cache
            ORDER BY fetched_at DESC, feed_key DESC LIMIT -1 OFFSET ?
          )
          ''',
          [maxFeeds],
        );
      });
}
