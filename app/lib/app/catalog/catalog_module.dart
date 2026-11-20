import 'dart:io';

import '../../application/catalog/catalog_service.dart';
import '../../data/anilist/anilist_client.dart';
import '../../data/anilist/anilist_metadata_provider.dart';
import '../../data/anilist/offline_first_anime_catalog.dart';
import '../../data/kitsu/kitsu_episode_index.dart';
import '../../data/local_db/app_database.dart';
import '../../data/local_db/drift_anime_identity_repository.dart';
import '../../data/local_db/drift_local_library_repository.dart';
import '../../data/local_db/drift_playback_progress_repository.dart';
import '../../data/local_db/uuid_anime_id_generator.dart';
import '../../data/metadata/fake_metadata_provider.dart';
import '../../domain/catalog/episode_index_provider.dart';
import '../../domain/catalog/metadata_provider.dart';

/// Linux-first composition for the offline catalog walkthrough.
final class CatalogModule {
  CatalogModule._({
    required this.database,
    required this.service,
    required this.anilistClient,
    this.demoProvider,
  });

  final AppDatabase database;
  final CatalogService service;
  final AniListClient anilistClient;
  final FakeMetadataProvider? demoProvider;

  static Future<CatalogModule> open({
    File? databaseFile,
    DateTime Function()? clock,
    bool useDemoProvider = false,
    EpisodeIndexProvider? episodeIndex,
  }) async {
    if (databaseFile != null) {
      await databaseFile.parent.create(recursive: true);
    }
    final AppDatabase database = databaseFile == null
        ? AppDatabase.open()
        : AppDatabase.atFile(databaseFile);
    final AniListClient client = AniListClient();
    final FakeMetadataProvider? demo = useDemoProvider
        ? FakeMetadataProvider(clock: clock)
        : null;
    final AniListMetadataProvider publicProvider = AniListMetadataProvider(
      OfflineFirstAnimeCatalog(
        remote: client,
        database: database,
        clock: clock,
      ),
      clock: clock,
    );
    final MetadataProvider provider = demo ?? publicProvider;
    return CatalogModule._(
      database: database,
      anilistClient: client,
      demoProvider: demo,
      service: CatalogService(
        metadataProvider: provider,
        identities: DriftAnimeIdentityRepository(
          database: database,
          idGenerator: UuidAnimeIdGenerator(),
          clock: clock,
        ),
        library: DriftLocalLibraryRepository(database: database, clock: clock),
        progress: DriftPlaybackProgressRepository(database),
        clock: clock,
        episodeIndex: episodeIndex ?? KitsuEpisodeIndex.public(clock: clock),
      ),
    );
  }

  Future<void> close() async {
    anilistClient.close();
    await database.close();
  }
}
