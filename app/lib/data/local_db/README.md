# Persistencia local (Drift/SQLite)

`AppDatabase` encapsula SQLite mediante Drift. Domain/UI usan modelos y repositorios, no SQL. La composición es dueña de abrir/cerrar la base. Las pruebas pasan un archivo bajo `.ai-local/test-db/`; no se usan ni borran DB de usuarios.

## Árbol

```text
local_db/
  app_database.dart                     tablas, migraciones, schema v8
  app_database.g.dart                   generado por Drift/build_runner
  drift_playback_progress_repository.dart progreso tipado F1.10
  drift_anime_identity_repository.dart identidad/crosswalk/relaciones
  drift_local_library_repository.dart   membership/status local
  uuid_anime_id_generator.dart           UUID v4 local
  tables/
    settings_entries.dart
    progress_documents.dart              JSON legado preservado
    latest_anime_search.dart             una búsqueda AniList heredada
    anilist_detail_cache                 fichas públicas bajo demanda por ID
    playback_progress_entries.dart       progreso tipado
    anime_identity_entries.dart
    external_anime_identifiers.dart
    anime_identity_relationships.dart
    library_entries.dart                 membership con status
```

## Tablas y constraints

- `settings_entries`: envelopes propiedad de `settings`.
- `progress_documents`: JSON previo, sin borrado ni migración automática.
- `latest_anime_search`: última búsqueda explícita, usada como fallback.
- `anilist_detail_cache`: hasta 64 fichas públicas solicitadas por ID; no
  contiene cuentas, biblioteca, progreso ni bytes de imagen.
- `playback_progress_entries`: progreso F1.10, clave `(content_id, episode_id)`.
- `anime_identity_entries`: UUID interno `anime:<UUIDv4>` y creación UTC.
- `external_anime_identifiers`: PK `(provider_id, external_id)`, FK a identidad, evidencia validada por `CHECK`, fecha y índice por identidad. No reasigna IDs.
- `anime_identity_relationships`: PK `(source, target, kind)`, FKs a ambos IDs y checks que prohíben self-link/tipo inválido.
- `library_entries`: PK/FK `anime_id`, `added_at_utc`, status local con default `planned` y `CHECK` de `planned/watching/rewatching/paused/completed/abandoned`; índice por fecha.

No hay segunda tabla ni repositorio de biblioteca o progreso. Quitar membership borra solo la fila de `library_entries`; identidad y progreso permanecen.

## Migraciones y recuperación

Schema actual: **v8**. Las migraciones crean tablas progresivamente desde v1;
v5 añade el primer estado, v5/v6 reconstruyen `library_entries` y v8 añade la
caché de ficha sin reconstruir biblioteca. Las pruebas de migración validan
`PRAGMA integrity_check`, `foreign_key_check`, los seis estados y constraints.
La generación se ejecuta con `flutter pub run build_runner build`.

`AppDatabase.open()` usa Application Support en la app instalada. `AppDatabase.atFile(File)` es el seam de tests. La prueba del binario Linux usa el override `KONGROO_DATABASE_PATH` dentro de `.ai-local/`; el arranque rechaza `..`, ubicaciones externas y symlinks. No activar el override en producción.

## Repositorios y errores

- `DriftAnimeIdentityRepository`: get/lookup por IDs, creación transaccional de crosswalk, create local, link sin reasignación y relaciones. Errores traducidos a `Result<T>`.
- `DriftLocalLibraryRepository`: `list/get/add/setStatus/remove`; add idempotente conserva el estado existente; la tabla aplica clave/FK/checks. Un cambio de estado es explícito y no actualiza el progreso de reproducción.
- `DriftPlaybackProgressRepository`: `upsert/get/list/delete` por `ProgressKey`, usado por el flujo demo sin acoplarse a AniList/player.

Fallos SQL se devuelven como errores sanitizados; datos corruptos no se transforman en identidad vacía. Las referencias y estado desconocido se detienen en constraints o error de lectura.

## Pruebas

Desde `app/` con toolchain Flutter beta aislada documentada en `TESTING.md`:

```bash
flutter test --no-pub test/data/local_db/app_database_test.dart
flutter test --no-pub test/data/local_db/catalog_identity_repository_test.dart
flutter test --no-pub test/data/local_db/playback_progress_repository_test.dart
flutter test --no-pub test/widget_test.dart
```

`app_database_test.dart` comprueba schema/migraciones. `catalog_identity_repository_test.dart` comprueba PK/FK, conflictos y membership. `playback_progress_repository_test.dart` comprueba progreso/45:00/reinicio. `widget_test.dart` recorre UI y reapertura sobre el mismo archivo temporal, bloqueando HTTP. La suite completa y CI se registran en `docs/memory/sessions/2026-11-09-catalog-local-integration.md`.

## Portabilidad y límites

Drift/SQLite es infraestructura compartible en los targets futuros; domain
sigue Dart puro. No se añadió código de Android/TV/Windows. Los estados del
catálogo son provisionales. Se persisten solo las fichas públicas solicitadas,
con retención acotada; no se descarga el catálogo completo ni los bytes de las
imágenes.

## Caché local de fichas AniList

La migración v8 crea `anilist_detail_cache` sin reconstruir biblioteca en v7.
`DriftAniListDetailCache` usa el ID numérico de AniList como clave y hace el
upsert y el recorte en una transacción. No contiene cuentas, credenciales,
biblioteca ni progreso. La política de frescura y respaldo pertenece al
adaptador AniList. Cada documento se limita a 512 KiB; las fichas anteriores al
campo `streamingEpisodes` se refrescan una vez y los nuevos documentos se leen
offline con títulos/miniaturas de episodios cuando existen. Las pruebas de
migración están en `test/data/local_db` y
la de cierre/reapertura con caída HTTP en `test/data/anilist/offline_first_anime_catalog_test.dart`.
