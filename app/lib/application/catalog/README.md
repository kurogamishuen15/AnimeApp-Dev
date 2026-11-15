# Aplicación de catálogo

## Responsabilidad

Orquesta los contratos Dart del catálogo con los repositorios locales de identidad, biblioteca y progreso. No importa Flutter, Drift/SQLite, HTTP, JSON de red ni plugins. La interfaz y el composition root son consumidores separados.

## Árbol

```text
application/catalog/
  catalog_service.dart   búsqueda/detalle, alta idempotente, estados y progreso
  README.md              contratos, flujo, errores y límites
```

## Contrato público

- `CatalogService.search(query)` y `details(externalId)` traducen `ProviderResult` a `Result<T>`/errores de app.
- `loadLibrary()` combina filas locales con metadata opcional del proveedor actual; si no hay metadata, conserva un título local por `AnimeId`.
- `addToLibrary(metadata)` crea/reutiliza la identidad por ID externo exacto y agrega membership. El click de añadir es evidencia `userConfirmed`; altas simultáneas para el mismo `ExternalAnimeId` comparten una operación y la fila de biblioteca es única por `AnimeId`.
- `setStatus(animeId, status)` actualiza solo membership. `planned`, `watching`, `rewatching`, `paused`, `completed` y `abandoned` no cambian automáticamente por reproducción.
- `getProgress/saveProgress(animeId)` reutilizan `PlaybackProgressRepository`; el demo guarda `ContentId(animeId.value)`, `EpisodeId('episode:1')`, posición ms y duración desconocida.

## Flujo

```text
UI → CatalogService → MetadataProvider (fake, solo búsqueda/detalle)
                  ├→ AnimeIdentityRepository → SQLite
                  ├→ LocalLibraryRepository  → SQLite
                  └→ PlaybackProgressRepository → SQLite
```

La escritura de membership solo se reporta tras el resultado del repositorio. Errores de provider se convierten en errores tipados; una falta de metadata no elimina ni bloquea la biblioteca. El fake no hace I/O, y este composition no activa AniList/TMDB/Kitsu ni OAuth.

## Pruebas

Desde `app/`:

```bash
dart analyze lib/application/catalog test/widget_test.dart
flutter test --no-pub test/widget_test.dart
flutter test --no-pub test/data/local_db/catalog_identity_repository_test.dart
```

La prueba widget recorre búsqueda, detalles, alta, duplicados, estado, progreso y cierre/reapertura de un archivo SQLite real; bloquea la creación de `HttpClient`.

## Portabilidad y límites

El caso de uso es Dart puro y portable. Los puertos permiten cambiar la implementación de datos sin cambiar UI ni identidad. No hay sync, cuenta, player, duración real, episodios seleccionables, cache durable de metadata, retry manager ni política de conflictos. `episode:1` y los estados de biblioteca son únicamente valores demostrativos pendientes de decisión de producto.

## Ficha y lectura local

`CatalogService.readCachedDetails` usa la capacidad opcional
`CachedAnimeMetadataProvider`. `details` conserva los resultados tipados
y el ID del proveedor. La referencia externa de una entrada de biblioteca
se conserva incluso si falla la metadata. La biblioteca y el progreso usan
sus propios repositorios de Drift y carecen de dependencia con OAuth.
