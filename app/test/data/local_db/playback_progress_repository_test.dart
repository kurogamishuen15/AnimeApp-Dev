import 'dart:async';
import 'dart:io';

import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/local_db/app_database.dart';
import 'package:anime_app/data/local_db/drift_playback_progress_repository.dart';
import 'package:anime_app/domain/progress/checkpoint_coordinator.dart';
import 'package:anime_app/domain/progress/content_identity.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:anime_app/domain/progress/playback_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<Directory> tempDir() async {
  final root = Directory.current.parent;
  if (!Directory('${root.path}/.git').existsSync()) {
    throw StateError('Run tests from app/.');
  }
  final dir = Directory(
    '${root.path}/.ai-local/test-db/f1_10-final/${DateTime.now().microsecondsSinceEpoch}',
  );
  await dir.create(recursive: true);
  return dir;
}

ProgressKey key(String content, String episode) =>
    ProgressKey(contentId: ContentId(content), episodeId: EpisodeId(episode));
PlaybackProgress progress(
  ProgressKey key,
  int pos,
  DateTime at, {
  int? duration = 5400000,
  CompletionState state = CompletionState.inProgress,
}) => PlaybackProgress(
  key: key,
  positionMs: pos,
  durationMs: duration,
  updatedAtUtc: at.toUtc(),
  completion: state,
);

void main() {
  test('identity normalization, equality and composite key isolation', () {
    expect(() => ContentId('   '), throwsArgumentError);
    expect(() => EpisodeId(''), throwsArgumentError);
    expect(ContentId('  anime-α  '), ContentId('anime-α'));
    expect(key('ab', 'c'), isNot(key('a', 'bc')));
    expect(key('anime', 'ep-1'), isNot(key('anime', 'ep-2')));
    expect(key('anime-α', '第1話'), key('anime-α', '第1話'));
  });

  test(
    'SQLite v4 CRUD, 45:00 reopen, episode isolation and integrity',
    () async {
      final dir = await tempDir();
      final file = File('${dir.path}/progress.sqlite');
      var db = AppDatabase.atFile(file);
      final repo = DriftPlaybackProgressRepository(db);
      final k1 = key('local:anime-A', 'episode:1');
      final k2 = key('local:anime-A', 'episode:2');
      final k3 = key('local:anime-B', 'episode:1');
      try {
        final item = progress(k1, 2700000, DateTime.utc(2026, 11, 9));
        expect(await repo.upsert(item), isA<Success<void>>());
        expect(
          await repo.upsert(
            progress(k1, 2700000, DateTime.utc(2026, 11, 9, 1)),
          ),
          isA<Success<void>>(),
        );
        await repo.upsert(progress(k2, 1000, DateTime.utc(2026)));
        await repo.upsert(progress(k3, 2000, DateTime.utc(2026)));
        final all = await repo.list(const ContentIdFilter(null));
        expect((all as Success<List<PlaybackProgress>>).value, hasLength(3));
        await db.close();
        db = AppDatabase.atFile(file);
        final reopened = DriftPlaybackProgressRepository(db);
        final got = await reopened.get(k1);
        expect((got as Success<PlaybackProgress?>).value!.positionMs, 2700000);
        expect(
          (await reopened.get(
            k2,
          ) as Success<PlaybackProgress?>).value!.key.episodeId.value,
          'episode:2',
        );
        expect(await reopened.delete(k2), isA<Success<void>>());
        expect(
          (await reopened.list(
            const ContentIdFilter(null),
          ) as Success<List<PlaybackProgress>>).value,
          hasLength(2),
        );
        await db.close();
        final raw = sqlite.sqlite3.open(file.path);
        expect(raw.select('PRAGMA integrity_check').single.values.single, 'ok');
        expect(raw.select('PRAGMA user_version').single.values.single, 4);
        raw.close();
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'v3 to v4 migration preserves settings, legacy docs and cache',
    () async {
      final dir = await tempDir();
      final file = File('${dir.path}/v3.sqlite');
      var db = AppDatabase.atFile(file);
      await db
          .into(db.settingsEntries)
          .insert(
            SettingsEntriesCompanion.insert(
              settingKey: 'legacy',
              valueJson: '"ok"',
              updatedAt: DateTime.utc(2026),
            ),
          );
      await db
          .into(db.progressDocuments)
          .insert(
            ProgressDocumentsCompanion.insert(
              documentKey: 'legacy-progress',
              payloadJson: '{"opaque":true}',
              updatedAt: DateTime.utc(2026),
            ),
          );
      await db.close();
      final sqlite.Database raw = sqlite.sqlite3.open(file.path);
      raw.execute('DROP TABLE playback_progress_entries');
      raw.execute('PRAGMA user_version=3');
      raw.close();
      db = AppDatabase.atFile(file);
      try {
        expect(await db.select(db.settingsEntries).get(), hasLength(1));
        expect(await db.select(db.progressDocuments).get(), hasLength(1));
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          4,
        );
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'checkpoint queue preserves minute 15 then minute 45 during pending write',
    () async {
      final dir = await tempDir();
      final file = File('${dir.path}/race.sqlite');
      final db = AppDatabase.atFile(file);
      final repo = DriftPlaybackProgressRepository(db);
      final k = key('content', 'episode');
      final now = DateTime.utc(2026, 11, 9);
      final gate = Completer<void>();
      final started = Completer<void>();
      var writes = 0;
      final coordinator = CheckpointCoordinator(
        clock: () => now,
        write: (p) async {
          writes++;
          if (writes == 1) {
            started.complete();
            await gate.future;
          }
          return repo.upsert(p);
        },
      );
      try {
        final first = coordinator.handle(
          event: PlaybackEventKind.paused,
          key: k,
          positionMs: 900000,
          durationMs: 5400000,
        );
        await started.future;
        final second = coordinator.handle(
          event: PlaybackEventKind.seeked,
          key: k,
          positionMs: 2700000,
          durationMs: 5400000,
        );
        gate.complete();
        expect(await first, isTrue);
        expect(await second, isTrue);
        await db.close();
        final reopened = AppDatabase.atFile(file);
        final saved = await DriftPlaybackProgressRepository(reopened).get(k);
        expect(
          (saved as Success<PlaybackProgress?>).value!.positionMs,
          2700000,
        );
        await reopened.close();
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'periodic, pause, seek, close, complete; failed writes are not confirmed',
    () async {
      var now = DateTime.utc(2026);
      final saved = <PlaybackProgress>[];
      var failNext = false;
      final c = CheckpointCoordinator(
        clock: () => now,
        write: (p) async {
          if (failNext) {
            failNext = false;
            return const Failure(StorageError());
          }
          saved.add(p);
          return const Success(null);
        },
      );
      final k = key('c', 'e');
      expect(
        await c.handle(
          event: PlaybackEventKind.playing,
          key: k,
          positionMs: 0,
          durationMs: null,
        ),
        isTrue,
      );
      now = now.add(const Duration(seconds: 10));
      expect(
        await c.handle(
          event: PlaybackEventKind.playing,
          key: k,
          positionMs: 12000,
          durationMs: null,
        ),
        isTrue,
      );
      expect(
        await c.handle(
          event: PlaybackEventKind.seeked,
          key: k,
          positionMs: 20000,
          durationMs: null,
        ),
        isFalse,
      );
      expect(
        await c.handle(
          event: PlaybackEventKind.seeked,
          key: k,
          positionMs: 60000,
          durationMs: null,
        ),
        isTrue,
      );
      failNext = true;
      expect(
        await c.handle(
          event: PlaybackEventKind.closing,
          key: k,
          positionMs: 61000,
          durationMs: null,
        ),
        isFalse,
      );
      expect(
        await c.handle(
          event: PlaybackEventKind.completed,
          key: k,
          positionMs: 61000,
          durationMs: null,
        ),
        isTrue,
      );
      expect(saved.last.completion, CompletionState.completed);
    },
  );
}
