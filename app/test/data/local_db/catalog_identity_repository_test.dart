import 'dart:io';

import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/data/local_db/app_database.dart';
import 'package:anime_app/data/local_db/drift_anime_identity_repository.dart';
import 'package:anime_app/data/local_db/drift_local_library_repository.dart';
import 'package:anime_app/data/local_db/drift_playback_progress_repository.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/anime_identity.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:anime_app/domain/catalog/library_repository.dart';
import 'package:anime_app/domain/progress/content_identity.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<Directory> _temporaryDatabaseDirectory() async {
  final Directory appDirectory = Directory.current.absolute;
  if (!appDirectory.path.endsWith('${Platform.pathSeparator}app')) {
    throw StateError('Run catalog persistence tests from app/.');
  }
  final Directory projectDirectory = appDirectory.parent;
  if (!File('${appDirectory.path}/pubspec.yaml').existsSync() ||
      !File('${projectDirectory.path}/AGENTS.md').existsSync() ||
      !Directory('${projectDirectory.path}/.git').existsSync()) {
    throw StateError('Could not verify the project root for test cleanup.');
  }
  final Directory root = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}.ai-local'
    '${Platform.pathSeparator}test-db${Platform.pathSeparator}catalog',
  );
  final Directory directory = Directory(
    '${root.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persists provider IDs and typed franchise links in real SQLite',
    () async {
      final Directory directory = await _temporaryDatabaseDirectory();
      final File file = File('${directory.path}/catalog.sqlite');
      final _QueueIdGenerator generator = _QueueIdGenerator([
        AnimeId('anime:uuid-one'),
        AnimeId('anime:uuid-two'),
      ]);
      AppDatabase database = AppDatabase.atFile(file);
      final DateTime createdAt = DateTime.utc(2026, 11, 9, 12);
      DriftAnimeIdentityRepository identities = DriftAnimeIdentityRepository(
        database: database,
        idGenerator: generator,
        clock: () => createdAt,
      );

      try {
        final AnimeIdentity first = (await identities.createLocalIdentity())
            .fold((AnimeIdentity value) => value, (error) => throw error);
        final AnimeIdentity second = (await identities.createLocalIdentity())
            .fold((AnimeIdentity value) => value, (error) => throw error);
        final ExternalAnimeId external = ExternalAnimeId(
          providerId: MetadataProviderId('anilist'),
          value: '15125',
        );
        final AnimeIdentity linked = (await identities.linkExternalId(
          animeId: first.id,
          externalId: external,
          evidence: IdentityLinkEvidence.userConfirmed,
        )).fold((AnimeIdentity value) => value, (error) => throw error);
        expect(linked.externalReferences.single.externalId, external);

        final Result<AnimeIdentity> conflict = await identities.linkExternalId(
          animeId: second.id,
          externalId: external,
          evidence: IdentityLinkEvidence.trustedProviderCrossReference,
        );
        expect(conflict.isSuccess, isFalse);

        final AnimeIdentity relationship = (await identities.addRelationship(
          sourceId: first.id,
          targetId: second.id,
          kind: AnimeRelationshipKind.sequel,
          evidence: IdentityLinkEvidence.verifiedOfficialReference,
        )).fold((AnimeIdentity value) => value, (error) => throw error);
        expect(
          relationship.relationships.single.kind,
          AnimeRelationshipKind.sequel,
        );

        final DriftLocalLibraryRepository library = DriftLocalLibraryRepository(
          database: database,
          clock: () => createdAt,
        );
        final LocalLibraryRepository libraryContract = library;
        final added = await libraryContract.add(first.id);
        expect(added.isSuccess, isTrue);
        final repeated = await libraryContract.add(first.id);
        expect(
          repeated.fold((entry) => entry.addedAtUtc, (error) => null),
          createdAt,
        );
        expect(
          repeated.fold((entry) => entry.status, (error) => null),
          LibraryStatus.planned,
        );
        final statusChanged = await libraryContract.setStatus(
          first.id,
          LibraryStatus.watching,
        );
        expect(
          statusChanged.fold((entry) => entry.status, (error) => null),
          LibraryStatus.watching,
        );
        final repeatedAfterStatusChange = await libraryContract.add(first.id);
        expect(
          repeatedAfterStatusChange.fold(
            (entry) => entry.status,
            (error) => null,
          ),
          LibraryStatus.watching,
        );
        for (final LibraryStatus status in LibraryStatus.values) {
          final changed = await libraryContract.setStatus(first.id, status);
          expect(
            changed.fold((entry) => entry.status, (error) => null),
            status,
          );
        }
        final Result<LibraryEntry> restoredWatching = await libraryContract
            .setStatus(first.id, LibraryStatus.watching);
        expect(
          restoredWatching.fold((entry) => entry.status, (error) => null),
          LibraryStatus.watching,
        );
        final DriftPlaybackProgressRepository progress =
            DriftPlaybackProgressRepository(database);
        final ProgressKey progressKey = ProgressKey(
          contentId: ContentId(first.id.value),
          episodeId: EpisodeId('episode:s1e1'),
        );
        expect(
          await progress.upsert(
            PlaybackProgress(
              key: progressKey,
              positionMs: 2700000,
              durationMs: 5400000,
              updatedAtUtc: createdAt,
            ),
          ),
          isA<Success<void>>(),
        );

        final integrity = await database
            .customSelect('PRAGMA integrity_check')
            .getSingle();
        expect(integrity.read<String>('integrity_check'), 'ok');
        final foreignKeys = await database
            .customSelect('PRAGMA foreign_key_check')
            .get();
        expect(foreignKeys, isEmpty);

        await database.close();
        database = AppDatabase.atFile(file);
        identities = DriftAnimeIdentityRepository(
          database: database,
          idGenerator: generator,
          clock: () => createdAt,
        );
        final AnimeIdentity? recovered = (await identities.getById(first.id))
            .fold((AnimeIdentity? value) => value, (error) => throw error);
        expect(recovered!.externalReferences.single.externalId, external);
        expect(recovered.relationships.single.targetId, second.id);
        final DriftLocalLibraryRepository reopenedLibrary =
            DriftLocalLibraryRepository(database: database);
        final entries = await reopenedLibrary.list();
        expect(
          entries.fold((value) => value.single.animeId, (error) => throw error),
          first.id,
        );
        expect(
          entries.fold((value) => value.single.status, (error) => throw error),
          LibraryStatus.watching,
        );

        await reopenedLibrary.remove(first.id);
        expect(
          (await reopenedLibrary.list()).fold((value) => value, (e) => throw e),
          isEmpty,
        );
        expect((await identities.getById(first.id)).isSuccess, isTrue);
        final Result<PlaybackProgress?> savedProgress =
            await DriftPlaybackProgressRepository(database).get(progressKey);
        expect(
          savedProgress.fold(
            (value) => value!.positionMs,
            (error) => throw error,
          ),
          2700000,
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'v4 to v7 migration preserves user progress and defaults library status',
    () async {
      final Directory directory = await _temporaryDatabaseDirectory();
      final File file = File('${directory.path}/catalog-v4.sqlite');
      final sqlite.Database oldDatabase = sqlite.sqlite3.open(file.path);
      final File schema = File(
        '${Directory.current.path}/drift_schemas/schema_v4.sql',
      );
      for (final String statement in schema.readAsStringSync().split(';')) {
        if (statement.trim().isNotEmpty) oldDatabase.execute(statement);
      }
      oldDatabase.execute('INSERT INTO settings_entries VALUES (?, ?, ?)', [
        'theme.mode',
        '"system"',
        DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
      ]);
      oldDatabase.execute('INSERT INTO progress_documents VALUES (?, ?, ?)', [
        'legacy-document',
        '{"keep":true}',
        DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
      ]);
      oldDatabase.execute(
        'INSERT INTO playback_progress_entries '
        '(content_id, episode_id, position_ms, duration_ms, updated_at_utc, completion, revision) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'anime:uuid-one',
          'episode:s1e1',
          2700000,
          5400000,
          DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
          'inProgress',
          2,
        ],
      );
      oldDatabase.execute('PRAGMA user_version = 4');
      oldDatabase.close();

      final AppDatabase database = AppDatabase.atFile(file);
      try {
        expect(
          (await database.select(database.settingsEntries).getSingle())
              .valueJson,
          '"system"',
        );
        expect(
          (await database.select(database.progressDocuments).getSingle())
              .payloadJson,
          '{"keep":true}',
        );
        expect(
          (await database.select(database.playbackProgressEntries).getSingle())
              .positionMs,
          2700000,
        );
        expect(
          await database.select(database.animeIdentityEntries).get(),
          isEmpty,
        );
        expect(
          await database.select(database.localLibraryEntries).get(),
          isEmpty,
        );
        expect(
          (await database.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          9,
        );
        expect(
          (await database.customSelect('PRAGMA integrity_check').getSingle())
              .read<String>('integrity_check'),
          'ok',
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

final class _QueueIdGenerator implements AnimeIdGenerator {
  _QueueIdGenerator(this._values);

  final List<AnimeId> _values;

  @override
  AnimeId generate() {
    if (_values.isEmpty) throw StateError('No test IDs remain.');
    return _values.removeAt(0);
  }
}
