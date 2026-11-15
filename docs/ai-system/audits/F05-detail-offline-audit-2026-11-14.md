# Auditoría focalizada de fichas públicas

Revisión del camino Home → ficha → ID AniList → catálogo → SQLite o GraphQL.
Flutter 3.47.9 aislado. La segunda revisión del código fue propia.

## Hallazgos y corrección

- **F05-C1, P1, corregido.** `offline_first_anime_catalog.dart` delegaba el
  lookup por ID a la red. El slot previo solo servía para búsquedas coincidentes
  y browse no persistía. Al cerrar y volver sin red, el ID no encontraba la
  ficha. El nuevo test abre SQLite, consulta, reabre el archivo y reproduce
  tanto HTTP 503 como conexión rechazada. Con un ID ausente se obtiene un fallo.
- **F05-C2, P2, corregido.** `anilist_client.dart` usaba la misma lista de
  campos de resumen para la ficha. La consulta por ID añade el suplemento
  público y las pestañas existentes presentan los resultados disponibles.
- `catalog_home_page.dart` ya pasaba el identificador exacto. `CatalogModule`
  usa el proveedor real por defecto. El cliente no incluye autorización y la
  biblioteca usa su propia persistencia. TMDB y Kitsu están documentados sin
  adaptador activo. No se introdujo otro proveedor.

## Evidencia

- POST anónimo con la consulta exacta de producción para AniList 151807:
  HTTP 200, Solo Leveling, 12 personajes, 3 aristas de relación, A-1 Pictures
  y tráiler de YouTube. Referencia consultada el 2026-11-14:
  [esquema Media de AniList](https://anilist.gitbook.io/anilist-apiv2-docs/docs/reference/object/media).
- 57 pruebas del alcance de catálogo, Home, widget, Drift y F1.12.
  El widget usa un proveedor ficticio explícito y Drift real. Los casos de
  caída, reapertura y persistencia usan un servidor HTTP de loopback.
- La caché tiene máximo de 64 fichas, refresco a partir de 24 h y no conserva
  los bytes de las imágenes. El apartado de reparto está acotado a las voces
  japonesas del primer grupo de 12 personajes. La apertura desde Home se
  verificó en widgets. Queda la revisión manual en la aplicación instalada.
