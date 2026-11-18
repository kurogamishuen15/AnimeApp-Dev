# KONGROO — Auditoría de lectura: GitHub, carátulas, episodios y referencias AnikenTV

**Fecha:** 16 de noviembre de 2026  
**Repositorio examinado:** https://github.com/kurogamishuen15/AnimeApp-Dev  
**Rama y commit examinados:** `main` — `6cc3e5e075760b845eac26fb48b1424cd38b5fa1`  
**Fuente adicional:** ZIP proporcionado por el propietario, `anikentv-release.zip` (paquete fuente `anikentv-release/`, Android/Kotlin, README se identifica como *Anilili*).  
**Alcance:** inspección estática del código remoto y del ZIP. **No se ejecutó Flutter, no se pudo observar el Fedora del usuario, no se midió red ni se confirmó reproducción**. Los estados de pruebas del repositorio provienen de sus propios informes, no de una ejecución independiente actual.

## 1. Diagnóstico con evidencia diferenciada

| Hallazgo | Ubicación comprobada | Evidencia | Diagnóstico/acción |
|---|---|---|---|
| Home utiliza AniList para metadatos de carátulas y banner | `app/lib/app/catalog/catalog_module.dart`, `app/lib/data/anilist/anilist_metadata_provider.dart`, `app/lib/app/home/home_data.dart` | `CatalogModule.open` elige proveedor público AniList salvo modo demo; `CatalogHomeSource` pide populares/tendencias | Si fallan todos los posters, investigar primeramente solicitud GraphQL, respuesta/mapeo, CDN e imagen. **No atribuirlo a codecs de libmpv**. |
| Error gráfico oculto | `app/lib/app/home/home_artwork.dart` | `Image.network(... errorBuilder: (_,_,_) => fallback)` muestra un fondo vacío sin diagnóstico específico | Registrar fallos sanitizados y distinguir URL vacía, HTTP, TLS, DNS, decoding de imagen y error de layout, sin exponer URLs firmadas completas. |
| Home tiene timeout global fijo de 12 s | `app/lib/app/home/home_screen.dart`, `_reload()` | `widget.load().timeout(Duration(seconds: 12))` | Una carga de biblioteca lenta o múltiples peticiones puede convertir datos válidos en «No se pudo cargar Inicio». Probar con instrumentación y evitar que una fuente lenta bloquee toda Home. |
| Home espera biblioteca y dos feeds antes de entregar contenido | `app/lib/app/home/home_data.dart`, `CatalogHomeSource.load()` | `browsePopular`, `browseTrending`, `loadLibrary` y `(...).wait`; error de biblioteca aborta Home | Separar éxito parcial, caché local, carga progresiva y errores; una biblioteca degradada no debe ocultar populares cargados. |
| Browse popular/tendencias no dispone de fallback local | `app/lib/data/anilist/offline_first_anime_catalog.dart`, `browseAnime` | Delega directamente a `remote.browseAnime`; la caché implementada cubre búsqueda y detalle, no el feed de Home | Implementar caché persistente limitada y stale-while-revalidate para feeds públicos, con pruebas de desconexión. No inventar posters ni datos. |
| Home no produce «Continuar viendo» desde el progreso real | `app/lib/app/home/home_data.dart` | Declara `final episodes = <HomeEpisode>[];` y retorna esa lista sin poblarla | **Defecto funcional comprobado estáticamente:** sección de continuar viendo vacía independientemente del progreso; conectar con la persistencia de progreso y validar episodios reales. |
| El control de continuar viendo todavía ofrece un diálogo sin reproducción | `app/lib/app/home/home_sections.dart`, `showResume()` | Texto literal «No hay una fuente de reproducción conectada para este episodio» | No declarar flujo completo; integrar acción al manager de reproducción o mostrar estado honesto según fuentes. |
| Los episodios de ficha provienen de AniList `streamingEpisodes` | `app/lib/data/anilist/anilist_client.dart` y `anilist_detail_fields.dart` | Query por ID pide `episodes` y `streamingEpisodes {title thumbnail site}`; decoder numera por título o índice | AniList no garantiza lista completa ni fuentes reales; construir índice de episodios aparte y fusionarlo conservadoramente con metadatos AniList. |
| La UI fabrica tarjetas numéricas hasta el total declarado | `app/lib/app/catalog/detail/anime_detail_tab_content.dart`, `_EpisodesTab` | `episodeCount=max(episodeCount, highestSupplied)` y genera índices 1..N aunque falte dato individual | Puede mostrar tarjetas sin metadatos/fuente confirmada; distinguir temporada total, emitido, disponible, faltante y reproducible. El botón Play debe indicar la disponibilidad de fuente sin engañar. |
| Los tests reales de AniList están opt-in | `app/test/data/anilist/anilist_live_smoke_test.dart` | `bool.fromEnvironment('KONGROO_TEST_ANILIST_LIVE')`, `skip: !enabled` | Una suite verde por defecto no demuestra AniList vivo ni descarga de imágenes; diseñar un smoke real controlado, no confundir con unit tests. |
| Source/host sí están separados de engine en el código reciente | `app/lib/data/player/providers/playback_providers_module.dart` y `app/lib/application/player/providers/playback_provider_manager.dart` | 1 registro AnimesDigital y 1 resolver `direct-media`; manager maneja breaker/fallback/TTL | **Conservar** contratos y manager que pasen pruebas, no reescribir desde cero por frustración. |
| AnimesDigital no es todavía reproducible acreditado | `docs/ai-system/audits/S0S-audit-2026-11-16.md` y `docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md` | Manifiesto HLS 200, primer segmento MPEG-TS, UI negra y «The media could not be opened or decoded» | Separar transporte, demux, decodificación, video output y visualización; no declarar éxito por HTTP o posición de reproducción. |
| El resolver directo valida formato por extensión del path | `app/lib/data/player/providers/hosts/direct_media_host_resolver.dart` | `_formatFor` reconoce `.mp4`, `.m3u8`, `.mpd` y devuelve `unknown` en otros casos | Revisar con casos reales de URLs válidas con rutas no convencionales y type de contenido; evitar abrir HTML como video. No relajar SSRF. |
| Hay una discrepancia de montaje bajo investigación | `app/lib/app/player/provider_playback_route.dart`, `spike_player_module.dart`, informe S0-S | La ruta espera abrir módulo/reproductor antes de construir el widget; el harness que adjuntó superficie antes pudo completar `open` | Hipótesis, **no causalidad confirmada**. Probar A/B con misma fuente y fixture antes de alterar el engine. |
| Android y Windows no tienen runners en el árbol público actual | Árbol GitHub `app/` | Existe `app/linux/`; no se encontraron `app/android/` ni `app/windows/` en el commit inspeccionado | Núcleo Dart compartible es objetivo, pero **build Android/Windows no está validado**; planificar scaffolds después de pruebas y con cambios controlados. |

### Relación entre fallos

Los defectos de imágenes y feeds están aguas arriba del reproductor: transporte de metadatos/imagen y presentación. Los episodios tienen dos conceptos hoy mezclados: `episodes`/`streamingEpisodes` de AniList (metadatos) y `EpisodeRef` del proveedor de fuentes (reproducción). El fallo de video es otra cadena: episodio → candidato → HLS → segmentos → demux/decoder → textura → frame presentado. Una arquitectura de observabilidad debe etiquetar **en cuál de esas cadenas falló** sin colapsar todo en «no funciona».

## 2. Lo que realmente muestra el ZIP AnikenTV

**Fuente:** `anikentv-release/app/src/main/java/com/miruronative/` (el ZIP aportado por el usuario). Es una versión de referencia: no presume que sus endpoints estén hoy activos.

1. `data/MiruroRepository.kt`, líneas aproximadas 114–171: métodos separados `miruroEpisodes(anilistId)` y `anivexaEpisodes(anilistId)`; usa caché por backend; `episodes(anilistId)` combina resultados; `sources(pipeId, provider, category, anilistId)` enruta por la familia de proveedor.
2. `data/MiruroRepository.kt`, 175–205: `resolveSources` reordena proveedor preferido + otros, elimina duplicados, encuentra el episodio pertinente y prueba hasta `maxAttempts=5`; el resultado mantiene la identidad del proveedor que entregó la fuente. **No usa libmpv como índice**; resuelve primero y entrega después.
3. `data/ProviderCatalog.kt`: distingue familia MIRURO/ANIVEXA y tipos nativo vs iframe; el ejemplo enumera etiquetas como `bonk`, `kiwi`, `bee`, `twin`, `cog`, y fuentes Anivexa (`anikoto`, `allanime`, `animekai`, `reanime`, `anizone`, `animegg`, etc.). La lista es histórica y **no es evidencia de disponibilidad actual**.
4. `data/remote/AnivexaClient.kt`: `getSources` hace dispatch específico al proveedor (`anikoto`, `allanime`, `animekai`, ...), mientras `getEpisodes` genera filas basadas en un conteo estimado de AniList. **Precaución:** esas filas pueden representar candidatos y no capítulos realmente comprobados. No copiar este supuesto como disponibilidad verificada.
5. `data/remote/PipeBridge.kt`: efectúa parte de las peticiones desde WebView mediante puente JS (`fetch('/api/secure/pipe?...')`), atado al contexto de la página; no es «solo GET a host multimedia». No prometer que esto funcione igual en Fedora ni trasladar cookies/autorizaciones para evadir controles.
6. `ui/watch/WatchViewModel.kt`: carga listas combinadas, elige la columna vertebral de capítulos (`pickSpine`), resuelve servidor, conserva capítulo y posición, soporta selección y reporte de errores. `playback/PlaybackService.kt` y las vistas Android implementan reproducción con Media3/WebView, componentes **no portables directamente a Dart**.
7. El README del ZIP declara HLS nativo y fallback web para embeds. La misma app ilustra por qué hay que separar **fuente**, **host**, **medio** y **motor**.

**Diferencia crítica de versiones:** el ZIP contiene Miruro `pipe`/WebView; el repositorio más reciente de Anilili incorpora `MiruroCatalogApi.kt` para rutas REST nuevas y registros ampliados. La referencia vieja puede servir para contratos y comportamiento, no para repetir URLs históricas sin verificación.

## 3. Patrones de otras referencias públicas

- **Anilili Android:** https://github.com/sanilili/Anilili — `ProviderCatalog.kt`, `MiruroCatalogApi.kt`, `MiruroCatalog.kt`, `MiruroEmbedResolver.kt`, `AnivexaClient.kt`. Contratos y orden de fuentes; protocolos vigentes sujetos a verificación.
- **Anilili Desktop:** https://github.com/sanilili/desktoprepo1 — `src/lib/providers.ts`, `src/lib/player.ts`, `crates/core/src/miruro.rs`, `providers/` y `wit/provider.wit`. Adaptadores separados de libmpv; el desktop usa técnicas propias de Rust/Tauri que **no son requisitos para Kongroo**.
- **Zangetsu:** https://github.com/Spyou/Zangetsu y https://github.com/Spyou/zangetsu-providers — registro de fuentes JS por manifiesto `index.json`; extractores por **hostname de embed** en `extractors/`. Es buen modelo de responsabilidades, no autorización de ejecutar JS remoto sin sandbox ni verificación de licencias.
- **anime-sh:** https://github.com/Anime123450/anime-sh — CLI modular: providers, resolvers, mpv; tests y canary reales para distinguir servicio caído de app rota. Puede analizarse sin instalarlo ni cambiar Fedora.
- **anipy-cli:** https://github.com/sdaqo/anipy-cli — `api/src/anipy_api/provider/base.py` define contrato de `ProviderStream` con URL, resolución, subtítulos, language y referrer. La licencia y condiciones de reutilización se deben verificar antes de portar código.
- **GoAnime:** https://github.com/alvarorichard/GoAnime — separa scraper, playback, selección y health; referencia para smoke y pruebas.
- **Kuroko (documentación pública, no código fuente comprobado):** https://kuroko.cc/help — describe coordinación por `api.stream` y un proxy `/media/<token>` privado firmado. **No copiar, aprovechar ni falsificar el token ajeno**. El patrón replicable es la separación orquestador/proveedor/host, no depender de su backend.

### Lo que NO demuestran estos proyectos

No demuestran que un host que funcionó en otro momento o equipo funcione ahora en Fedora; tampoco que las rutas de terceros permitan a Kongroo acceder a sus archivos, ni que sus licencias permitan copia literal. Una fuente puede exponer medios autorizados y directos; un tercero también puede exigir navegador, permisos propios, DRM o negar acceso. El diagnóstico debe ser exacto, y los bloqueos externos se reconocen sin alterar controles.

## 4. Prioridades comprobables para OpenCode

**P0 — Catálogo:** demostrar si AniList responde en Fedora; recuperar Home/carátulas/feeds y que un fallo de una consulta no oculte todas las demás. Mostrar estados de error observables. Añadir tests offline + smoke opt-in.

**P1 — Episodios:** separar conteo AniList de filas verificadas por proveedores; impedir que la UI anuncie reproducción de episodios inexistentes; permitir navegación y selección real con datos cuando existan.

**P2 — Fuentes/hosts:** conservar módulos válidos del commit `6cc3e5e`, retirar runtime muerto tras inventario; implementar resolutores y proveeduría por contrato, no registrar 20 nombres vacíos. Buscar medios públicos mediante índices/APIs permitidos y archivos servidos, sin forzar webs de catálogo cuando exista API propia o un índice documentado.

**P3 — Diagnóstico de media:** control A/B con un mismo fixture externo y uno local; capturar logs redacted de playlist/segmento, demux, video output, error, frame visible. Conservar `media_kit/libmpv` y comprobar toda regresión antes de alterar opciones nativas.

**P4 — Portabilidad:** core Dart con contratos neutralizados; adapters por plataforma para WebView/red/renderer si hicieran falta; Linux probado primero, Android/Windows planificados sin afirmar builds que no se han corrido.

## 5. Límites de esta auditoría

Esta lectura **no identifica todavía la causa exacta del fallo observado en el Fedora del usuario**: no hay sesión gráfica ni traces actuales de red dentro de este entorno. Se identifican defectos estáticos (Continuar viendo vacío, browse sin caché, episodios placeholder) e hipótesis precisas comprobables (timeout Home, errores CDN, montaje HLS, demux), pero ninguna prueba viva independiente. Los estados `PASS` de la documentación histórica no acreditan el estado actual hasta ejecutarse nuevamente.
