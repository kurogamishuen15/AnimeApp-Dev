# Dominio de catálogo

Contratos Dart puros para identidad interna, IDs externos, metadatos, proveedor, relaciones y biblioteca local. No importa Flutter, Drift, Dio, GraphQL ni plugins.

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `anime_id.dart` | `AnimeId` opaco y puerto `AnimeIdGenerator` |
| `external_anime_id.dart` | namespace validado y clave namespaced de fuente externa |
| `anime_identity.dart` | identidad local, crosswalk y relaciones con evidencia |
| `anime_identity_repository.dart` | puertos de identidad y resolución exacta/ambigua |
| `library_entry.dart` | membership, fecha UTC y estado local elegido por usuario |
| `library_repository.dart` | `list/get/add/setStatus/remove` por `AnimeId` |
| `metadata_provenance.dart` | fuente de respuesta y timestamps UTC |
| `provider_anime_metadata.dart` | modelos normalizados, incluyendo romaji/años derivados; episodio/source scoped |
| `anime_detail_metadata.dart` | suplemento público: estudios, reparto, relaciones y episodios no reproducibles |
| `provider_result.dart` | success, no-results, unsupported y fallos tipados |
| `metadata_provider.dart` | contrato, capacidades, configuración/registry default-disabled y referencia verificada |
| `anime_summary.dart`, `anime_catalog_repository.dart` | contrato F1.8 legacy todavía presente para AniList |

## Invariantes y confianza

- `AnimeId` no deriva del título ni del ID de una fuente. La infraestructura genera UUID v4 local `anime:<uuid>`.
- `ExternalAnimeId` compara `(providerId, value)`; trims extremos del valor y conserva su capitalización porque las fuentes pueden definirla.
- El resolver solo compara IDs exactos namespaced; títulos similares nunca unen identidades y múltiples matches producen ambigüedad.
- `VerifiedExternalAnimeReference` es una afirmación construible por cualquier caller Dart: el tipo no valida criptográficamente ni consulta el origen de la evidencia. Solo pasar datos confirmados por un adapter confiable o una acción del usuario.
- En el flujo demo, el botón de alta representa confirmación explícita y se registra como `userConfirmed`.
- `planned`, `watching`, `rewatching`, `paused`, `completed` y `abandoned`, con default `planned`, se guardan localmente como selección explícita del usuario. No se transicionan automáticamente ni implican conteo de episodios vistos. El cambio manual a `completed` muestra confirmación porque la app aún no puede verificar la lista completa de episodios.
- Capacidades del provider se copian inmutables al construir el registry; `ProviderUnsupported` no equivale a lista vacía.
- `ProviderEpisodeMetadata.episodeNumber` es numeración de la fuente, no
  identidad canónica de episodio. Título, miniatura y sitio son metadatos; no
  conceden una fuente de reproducción.

## Errores y pruebas

Constructores inválidos lanzan `ArgumentError`; puertos de datos devuelven `Result<T>` con error tipado. Los adapters no pasan JSON ni excepciones de infraestructura a UI/dominio. Ejecutar desde `app/`:

```bash
dart analyze lib/domain/catalog test/domain/catalog
flutter test --no-pub test/domain/catalog/catalog_contracts_test.dart
flutter test --no-pub test/data/local_db/catalog_identity_repository_test.dart
```

SQLite y migraciones físicas están descritas en [`local_db`](../../data/local_db/README.md); el flujo visible está en [`app/catalog`](../../app/catalog/README.md).

## Portabilidad y estado

El dominio se puede compartir como Dart VM. El fake de metadatos está en `data/metadata` y se inyecta explícitamente para pruebas/demo; el flujo normal usa AniList a través de la capa data. Browse público no se almacena; solo existe la caché limitada de una búsqueda explícita. OAuth, sync de lista y relación con un proveedor de video siguen desconectados. ADR-A14 sigue propuesto y no aceptado.

## Datos opcionales de ficha

`AnimeDetailMetadata` comparte estudios, tráiler, personajes, voces,
relaciones y episodios públicos entre `AnimeSummary` y
`ProviderAnimeMetadata`. `episodeMetadataFetched` distingue una respuesta
actual (incluso vacía) de una caché antigua que aún debe refrescarse.
`CachedAnimeMetadataProvider` y `CachedAnimeCatalog` exponen lectura local
opcional. Un proveedor que no almacena fichas conserva el contrato base.
