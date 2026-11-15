# Adaptadores de datos

`data/` implementa persistencia y acceso a servicios detrás de contratos neutrales. Los repositorios/adaptadores traducen formatos externos; los modelos específicos de proveedor no deben filtrarse a domain ni UI.

| Módulo | Responsabilidad | Guía |
|---|---|---|
| `local_db/` | Drift, tablas, migraciones y repositorios locales | [`local_db/README.md`](local_db/README.md) |
| `anilist/` | Cliente GraphQL y catálogo/cache legacy de AniList | [`anilist/README.md`](anilist/README.md) |
| `metadata/` | Proveedor metadata local de pruebas | [`metadata/README.md`](metadata/README.md) |
| `player/` | Engine media_kit y adaptadores de proveedores | [`player/README.md`](player/README.md) |
| `opensubtitles/` | Transporte OpenSubtitles y almacenamiento local acotado | [`opensubtitles/README.md`](opensubtitles/README.md) |
| `aniskip/` | Cliente/caché de segmentos AniSkip | [`aniskip/README.md`](aniskip/README.md) |

Para extender un módulo, implementar el puerto domain/application correspondiente y probar errores, cancelación y ciclo de vida. No añadir solicitudes HTTP a widgets ni dependencias concretas al dominio.
