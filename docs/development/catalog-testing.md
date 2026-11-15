# Pruebas de catálogo

## Ejecutables y alcance

Desde `app/`, con Flutter beta aislado seleccionado según [TESTING.md](../../TESTING.md):

```bash
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter analyze --no-pub
flutter test --no-pub test/domain/catalog/catalog_contracts_test.dart
flutter test --no-pub test/data/local_db/catalog_identity_repository_test.dart
flutter test --no-pub test/data/local_db/app_database_test.dart
flutter test --no-pub test/data/local_db/playback_progress_repository_test.dart
flutter test --no-pub test/widget_test.dart
```

Desde raíz:

```bash
bash scripts/ci.sh
dart scripts/check_imports.dart --root .
```

Drift genera código con:

```bash
flutter pub run build_runner build
```

## Qué se prueba realmente

- Tests de dominio cubren IDs vacíos/no ASCII, normalización/equality/hash, IDs externos con namespace, key length-prefix, registry apagado por defecto, orden/filtrado de capacidades, estados de error/retry y resolver exacto/ambiguo.
- `catalog_identity_repository_test.dart` usa archivo SQLite real bajo `.ai-local/test-db/`, cierre/reapertura, link externo, conflicto de reasignación, relaciones tipadas, add/remove idempotente, conservación de progreso exacto, `integrity_check` y `foreign_key_check`.
- Migraciones usan snapshots SQL versionados y comprueban v1→v6, v2→v6, v3→v6, v4→v6 y v5→v6 conservando los datos que existen en cada esquema; registros JSON antiguos no se interpretan ni eliminan.
- `test/widget_test.dart` bloquea creación de `HttpClient` y recorre catálogo, ficha, alta, duplicado, cambio de estado y progreso sobre un SQLite físico bajo `.ai-local/test-db/`. Cierra el archivo, crea nueva composición y valida biblioteca/status/progreso recuperados.
- La app Linux se construye con Flutter beta aislado y se arranca con `KONGROO_DATABASE_PATH` apuntando a `.ai-local/`. `ANIMEAPP_FIRST_FRAME_MARKER` prueba primer frame rasterizado, no confirma por sí solo visibilidad del compositor.
- AniList existente se prueba con servidor HTTP loopback y cliente de Dio. La suite no llama `graphql.anilist.co`.
- Fakes son escritos a mano. No se usan paquetes de mock.

## Límites

La verificación de esta subfase (2026-11-09) ejecutó: formato (0 archivos cambiados), Dart analyze sin issues, Flutter analyze sin issues, 62 pruebas Flutter, checker de imports y suite sintética, build Linux debug y arranque del binario con DB SQLite v6 aislada (`integrity_check=ok`, sin filas de usuario). El informe final y sus limitaciones están en `docs/memory/sessions/2026-11-09-catalog-local-integration.md`.

Estas pruebas no acreditan autorización de AniList/TMDB/Kitsu, OAuth, keyring/Secret Service, sync de lista, retención externa, provider real, reproducción, rendimiento de búsqueda, circuit breaker ni carga. Los estados de biblioteca y el episodio demo no constituyen reglas aprobadas.

Las llamadas reales están prohibidas hasta verificar términos/cuotas y autorización. No agregar API keys a tests, fixtures o Git. Providers no autorizados se prueban con fake manual, no contra producción.
