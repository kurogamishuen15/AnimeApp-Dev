# Fallos del catálogo y modo offline

| Escenario | Comportamiento implementado o requerido | Evidencia/estado |
| --- | --- | --- |
| Primera ejecución, online, sin login | Se abre el catálogo sintético sin login; el flujo no inicia requests externos | Widget test con provider fake y `HttpOverrides` que rechaza HTTP |
| Primera ejecución, offline | El fake trae tres records deterministas; no requiere red y permite abrir detalle | Búsqueda/ficha demostradas en `test/widget_test.dart` |
| Datos locales con metadata no disponible | Biblioteca/identidad/progreso siguen en SQLite; título cae al `AnimeId` local y la fila no se elimina | `CatalogService.loadLibrary` tolera fallo de detalle; repositorios separados |
| Reinicio app/módulo | Cerrar y abrir SQLite recupera identidad, crosswalk, membership/status y progreso | Widget test sobre el mismo archivo temporal, probado tras crear/cerrar/reabrir |
| Alta repetida o concurrente | La PK `anime_id` y deduplicación por ID externo impiden segunda fila; conserva status | Prueba de repositorio SQLite y alta concurrente desde service en widget test |
| Status desconocido por SQL | El `CHECK` rechaza valor ajeno al enum demo | Migración v5→v6 probada contra SQLite físico |
| DB de prueba/runtime | Se pasa un archivo bajo `.ai-local/`; el override rechaza `..`, rutas externas y symlinks | Widget test aislado; binario Linux verificado con DB v6 de prueba |
| Proveedor fake recibe episodio | Declara episodios no soportados; no inventa episodios ni enlaza reproductor | `ProviderUnsupported('episodeMetadata')` |
| HTTP 429 / `Retry-After` | Reportar cuota agotada; esperar el intervalo informado. Sin reintentos de bucle | AniList legacy mapea 429 y header; loopback cubierto |
| AniList HTTP/GraphQL 403 | Marcar fuente no disponible y mantener local. No intentar alterna no autorizada automáticamente | AniList loopback cubre 403; sin request real |
| Provider devuelve `Unsupported` | No interpretarlo como lista vacía; omitir esa capacidad y conservar datos previos | `ProviderUnsupported`, prueba de contrato |
| Respuesta corrupta | `invalidResponse`, no persistir payload incompleto ni mostrar DTO/stack | Mapping tests de AniList y `ProviderFailureKind`, loopback/contrato |
| IDs externos apuntan a dos identidades | Devolver `IdentityAmbiguous`; no reasignar crosswalk ni unir progreso | Resolver puro y PK compuesta; conflicto real se prueba con SQLite |
| Títulos parecidos / dos temporadas | No fusionar por título ni asignar episodios por orden/título | Regla conservadora del resolver; metadata episódica conserva namespace |
| Desconectar AniList | Quitar solo el token/relación de cuenta una vez implementados; biblioteca/progreso continúan | Sin OAuth actualmente; regla obligatoria futura, pendiente de F1.9 |
| Error de sync | Mantener outbox/local y nunca sobrescribir biblioteca/progreso por error remoto | El nuevo flujo AniList sync no existe; Supabase/F1.11 es contrato separado |

No hay fallback entre proveedores automático en esta fase: AniList, TMDB y Kitsu no están habilitados. No se hace broadcast a todos los providers al abrir una pantalla. Cuando exista un adapter autorizado, la app deberá presentar fuente, antigüedad/error recuperable, deduplicar requests por recurso y respetar políticas del proveedor.
