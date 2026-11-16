# S0-A — Portabilidad de servidores de Anilili a Kongroo

**Fecha:** 2026-11-15
**Estado del corte:** integración Miruro implementada y registrada en ese momento; fue retirada en una limpieza posterior. Disponibilidad externa bloqueada; misión S0 incompleta.
**Rama/HEAD de inicio:** `main` / `b1bd952ac03c8711ce50cf22d249fa448d2e2880`.
**Git:** cambios locales; sin commit ni push. El árbol ya estaba modificado antes de esta ejecución y se preservó.

> **Estado actual:** este informe conserva la evidencia histórica del port S0-A.
> Los archivos de runtime Miruro se retiraron después; el composition root
> actual no registra providers ni resolutores concretos. Consulta la
> [auditoría de limpieza posterior](../audits/S0-provider-cleanup-followup-audit-2026-11-15.md).

## 1. Componentes de referencia estudiados

Se usaron como referencia los commits fijados por el propietario:

- [Anilili `d7b80f1f5b6c3d014317af471a8565749947397d`](https://github.com/sanilili/Anilili/tree/d7b80f1f5b6c3d014317af471a8565749947397d): `ProviderCatalog.kt`, `MiruroRepository.kt`, `MiruroCatalogApi.kt`, `MiruroCatalog.kt`, pruebas de parsing/prioridad, `AnivexaClient.kt`, `ZokoProvider.kt`, `AniChanProvider.kt` y `AniPmProvider.kt`.
- [desktoprepo1 `e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd`](https://github.com/sanilili/desktoprepo1/tree/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd): `wit/provider.wit`, `src/lib/providers.ts`, `src/lib/player.ts` y `src/lib/player-policy.ts`, como referencia de contratos, selección y transporte al reproductor.
- Las licencias `LICENSE` en ambos commits dicen **MIT No Attribution (MIT-0)**: [Anilili](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/LICENSE), [desktoprepo1](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/LICENSE).

Dio está fijado en `app/pubspec.lock` como `5.11.1`. Se consultó su documentación primaria para `ResponseType.stream`, `ResponseBody`, cancelación, timeout y control explícito de redirects: [Dio README](https://github.com/cfug/dio/blob/main/dio/README.md) y [adaptador IO](https://github.com/cfug/dio/blob/main/dio/lib/src/adapters/io_adapter.dart), verificados el 2026-11-15.

## 2. Equivalencias Kotlin/Rust → Dart

| Referencia | Equivalente Kongroo | Resultado |
| --- | --- | --- |
| `MiruroCatalogApi.kt` | `DioMiruroCatalogApi` | GET acotado al origen canónico, rutas/query del catálogo, XOR+gzip documentado y fallos tipados |
| `MiruroCatalog.kt` | `MiruroCatalogParser` | Config dinámica, ID de título, episodios regulares, tracks, proveedores, streams y embeds |
| `MiruroRepository` / `ProviderCatalog` | `MiruroPlaybackProvider` | AniList → ID Miruro → episodio → opciones; orden/config leídos del upstream |
| Fuente nativa Miruro | `MiruroDirectMediaResolver` | Handoff de HTTPS HLS/MP4 a la ruta existente del engine |
| `provider.wit`, `providers.ts`, `player.ts` | `PlaybackProviderManager`, `ResolvedPlaybackStream`, `PlaybackSourceSwitchService` | Se reutilizan contratos/manager y el mismo player; no se añade un motor paralelo |
| `PipeBridge`, WebView y sesiones Android | Sin equivalente/port | No se introduce Android SDK, WebView, cookies, challenge handlers ni Tauri |

La implementación Dart adapta el esquema y sus reglas; no copia el runtime Kotlin/Rust. La procedencia se mantiene documentada en el README del módulo. No se incorporaron `withLegacyTrustAnchors`, `clearance`, extracción de desafíos, cookies, autorización o código de descifrado de fuentes.

## 3. Código y archivos afectados

Implementación nueva:

- `app/lib/data/player/providers/miruro/miruro_catalog.dart`
- `app/lib/data/player/providers/miruro/miruro_catalog_api.dart`
- `app/lib/data/player/providers/miruro/miruro_playback_provider.dart`
- `app/lib/data/player/providers/miruro/README.md`
- `app/test/data/player/providers/miruro/miruro_catalog_test.dart`
- `app/test/data/player/providers/miruro/miruro_catalog_api_test.dart`
- `app/test/data/player/providers/miruro/miruro_playback_provider_test.dart`
- `app/test/data/player/providers/miruro/miruro_live_smoke_test.dart` (opt-in)

Integración y documentación actualizada:

- `app/lib/data/player/providers/playback_providers_module.dart`
- `app/test/data/player/providers/playback_providers_module_test.dart`
- `app/lib/data/player/providers/README.md`
- `docs/ai-system/archive/providers/S0-2026-11-16/video_hosts/README.md` (guía archivada durante S0-S)
- `docs/ai-system/missions/KONGROO-RECONSTRUCTION-PLAN.md`
- `docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md`
- `docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md`
- `docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md`
- `docs/memory/PROJECT_STATE.md`, `AI_HANDOFF.md`, `MODULE_INDEX.md`, `RESEARCH_INDEX.md`
- `PROGRESS.md`, `TESTING.md`

El resto de archivos modificados antes de esta misión se mantuvo intacto; no se preparó el índice.

## 4. Proveedores y servidores implementados

**Miruro:** provider y resolver están registrados en el composition root existente. La configuración de backend y su orden son dinámicos; no se inventa ni hardcodea una lista de hosts. `sub`, `ssub` y `dub` se distinguen. Calidad es parte de una fuente; diferentes URLs del mismo servidor/calidad no se cuentan como servidores separados. Se aceptan streams directos MP4/HLS y los embeds se reconocen sin ejecutarlos.

**Anivexa:** no se registra un provider. `Zoko` publica una página con configuración client-side, pero el manifiesto devuelto respondió 403 en una solicitud corriente; no se enviaron `Referer+Origin` para cambiar esa denegación. La ruta probada exige un ID MAL, que el contrato actual de `PlaybackEpisode` no contiene. La API pública consultada de AniChan devolvió 403 y no se solicitó una cookie de sesión; AniPM devolvió 403 y la fuente upstream describe una condición Cloudflare de huella/cliente. No se portaron esas sesiones, huellas ni mecanismos de acceso. La matriz del `AnivexaClient` no queda cerrada: proveedores restantes no están declarados operativos ni todos fueron probados en vivo.

La lectura del commit fijado también muestra que el cliente Anivexa upstream
aplica `CloudflareInterceptor` a su cliente compartido y que AnimePahe se
alcanza a través de WebView. Por la restricción de no resolver challenges, no se
portó ese interceptor ni se copió el runtime WebView. Esto no clasifica por sí
solo a los otros adapters: falta completar el inventario estático y encontrar
rutas públicas de proveedores individuales que no dependan de esos mecanismos.
Fuentes: [AnivexaClient.kt](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnivexaClient.kt), [ProviderCatalog.kt](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/ProviderCatalog.kt).

**Otros proveedores/hosts:** no se restauraron los adaptadores retirados de AnimeAV1, TioAnime o AnimeGG. Sus resultados históricos siguen en el informe S0 y auditorías. No se confirmó FileStream, Bee ni Goma en las fuentes revisadas.

## 5. Fuentes reproducibles y fuentes bloqueadas

No se obtuvo ninguna fuente multimedia reproducible ni se abrió media externa con libmpv. Conteo S0 permanece **0/70**.

| Probe corriente, 2026-11-15 | Solicitud pública | Resultado observado | Estado |
| --- | --- | --- | --- |
| Miruro config | GET normal, sin cookie ni redirect | HTTP 403; cliente Dart lo mapea a `unauthorized` | `BLOCKED_EXTERNAL` |
| Miruro lookup AniList | GET normal, sin cookie ni redirect | HTTP 403 | `BLOCKED_EXTERNAL` |
| Miruro `.tv` config | GET normal | HTTP 403 con HTML de Cloudflare observado en la verificación inicial | No se usa como fallback |
| Zoko raíz | GET normal | HTTP 200 | No es evidencia de media |
| Zoko `/stream/mal/16498/1/sub` | GET normal; cuerpo acotado, sin publicar URL | HTTP 200 y payload público presente | Descubrimiento parcial; identidad no verificada |
| Manifiesto HLS de esa respuesta | GET normal, sin cabeceras especiales y sin redirects | HTTP 403 | `BLOCKED_EXTERNAL`; no se repite con cabeceras de evasión |
| AniChan lista | GET normal con `anilistId=16498` | HTTP 403 JSON | `BLOCKED_EXTERNAL` |
| AniPM raíz | GET normal | HTTP 403 | `BLOCKED_EXTERNAL` |

Las solicitudes no transportaron cookies, credenciales ni desafíos. No se registraron URLs firmadas ni tokens. Los 403 son bloqueos del servicio, no errores que el resolver trate de superar.

## 6. Pruebas y CI

Las pruebas focalizadas cubren shapes de config/título/episodios/play, tracks y embeds, clasificación de HLS/MP4, XOR+gzip con límites, rutas/query, redirects rechazados, respuesta 403, errores JSON, cancelación, timeout DNS, direcciones locales, headers permitidos, deduplicación de alternativas y registro/cierre del módulo. Los fixtures usan dominios de ejemplo y no sustituyen integración real.

- Suite Miruro + composition root: **22 pruebas deterministas**, aprobadas con el Flutter aislado del proyecto.
- `flutter analyze --no-pub` y `dart analyze lib test`: sin issues.
- Smoke live opt-in con el cliente real Dio: el test terminó con `MIRURO_LIVE outcome=blocked_or_unavailable status=403 kind=unauthorized`. El runner terminó exit 0 porque el caso registra y clasifica el bloqueo; no certifica disponibilidad ni playback.
- Última `scripts/ci.sh` tras el refuerzo del resolver: exit 0; 40 pruebas Python y 288 Flutter, 7 optativas omitidas. Formato (187 archivos, 0 cambios), checker de imports (positivos y negativos), memoria y análisis pasaron.
- `flutter build linux --release --no-pub`: exit 0; produjo `app/build/linux/x64/release/bundle/anime_app`. Esta compilación verifica integración/paquete, no playback ni visualización de media externa.
- No se conservó un log crudo permanente de CI; este resumen registra la salida observada. Las pruebas locales existentes de libmpv no prueban una fuente de Miruro.

## 7. Hallazgos, límites y rendimiento

- **P1 — gate de producto no cumplido:** no existe una URI de media accesible en el entorno actual; no se realizó decodificación, primer cuadro, seek, audio ni cierre de playback externo.
- **P2 — cobertura parcial Anivexa:** Zoko no tiene ID MAL en el contrato de episodio; AniChan/AniPM respondieron 403; no se habilitan mecanismos que alteren la denegación.
- **P2 — DNS TOCTOU:** el resolver rechaza nombres/IPs locales y una lista conservadora de prefijos IPv6 no globales contrastada con el [registro de direcciones especiales de IANA](https://www.iana.org/assignments/iana-ipv6-special-registry). Libmpv resuelve el nombre de nuevo después, así que la comprobación no fija la conexión ni elimina DNS rebinding.
- **P2 — paridad pendiente:** el contrato actual no transporta subtítulos/skip-times desde esta integración; DASH no se admite. Los embeds no se reproducen internamente.
- El módulo aplica límites de memoria/transporte y cierra Dio al cerrar la app. No se midieron RAM, CPU, tiempo de arranque o fugas en hardware Fedora de 4 GB; tampoco hay medición durante reproducción porque no se obtuvo video.
- No hubo inspección visual Wayland del reproductor: no había una fuente aceptada que abrir. Esto queda **NO VERIFICADO**, no simulado.

## 8. Siguiente tarea

Mantener S0 abierto y GATE B pendiente. Continuar el inventario estático de `AnivexaClient.kt`/`ProviderCatalog.kt` y probar únicamente rutas públicas que respondan sin alterar headers de acceso, cookies, desafíos, firmas ni cifrado. No reintentar endpoints 403 sin nueva evidencia de acceso público. Antes de declarar Anivexa implementado, resolver el mapeo de identidad requerido mediante datos ya permitidos por el producto y obtener una fuente directa que el motor pueda abrir. Luego ejecutar apertura real con dimensiones de video/cuadro visible, seek, audio si corresponde y cierre seguro, antes de ampliar cobertura.

## 9. Estado de aceptación

- Gate A (paridad): parcial; parser y mapping de tracks implementados, subtítulos/skip/DASH pendientes y API live bloqueada.
- Gate B (primera reproducción real): **no cumplido; bloqueado por 403 externo**.
- Gate C (varias alternativas, selección/fallback real): no verificado con medios reales.
- Gate D (cobertura Anivexa): parcial; sin adapter Anivexa registrado.
- Gate E (flujo ficha → episodio → UI → player): wiring usa el manager y player existentes; recorrido externo completo pendiente.
- Gate F (auditoría sin P0/P1 y reproducción): no cumplido por Gate B.

No se avanzó a F1 ni se cambió el estado formal de T00–T24.
