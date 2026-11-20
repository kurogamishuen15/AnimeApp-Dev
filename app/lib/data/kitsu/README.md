# data/kitsu — índice público de episodios

| Archivo | Responsabilidad |
|---|---|
| `kitsu_episode_index.dart` | `KitsuEpisodeIndex implements EpisodeIndexProvider`. Mapea un ID AniList a Kitsu (`/mappings`) y lista episodios (`/anime/{id}/episodes`). |

## Contrato

- Entrada: `ExternalAnimeId` con proveedor `anilist`. Otros proveedores devuelven `ProviderNoResults` sin tocar la red.
- Salida: `EpisodeIndexPage` con `ProviderEpisodeMetadata` (número, título, miniatura HTTPS, procedencia) y `totalCount` / `hasMore`.
- **No devuelve URLs reproducibles.** Un episodio listado no es una fuente y no debe mostrarse como reproducible.
- Miniaturas `http://` se descartan; entradas sin número válido (<1) se omiten sin invalidar la página.
- Errores: 429 → `rateLimited`; timeouts → `timeout`; sin conexión → `network`; resto → `unavailable`. No se registran URLs.
- Caché en memoria: mapeos y páginas, TTL 6 h, máximo 64 entradas. Sin persistencia todavía.

## Pruebas

- `test/data/kitsu/kitsu_episode_index_test.dart` (5 casos offline, servidor loopback).
- `test/data/kitsu/kitsu_live_smoke_test.dart` (opt-in: `--dart-define=KONGROO_TEST_KITSU_LIVE=true`). Última ejecución: PASS en Fedora, 2026-11-16.

## Licencia y uso

Kitsu expone datos públicos de lectura. Antes de distribuir, verificar sus términos de uso vigentes; esta integración solo lee metadatos de episodios y no copia código de terceros.
