# ANILILI — Integración de proveedores y servidores · 2026-11-17

Misión: integrar en Kongroo todos los proveedores/servidores del código de Anilili
(anikentv-release.zip, `com.miruronative`, 71 archivos Kotlin) que sean técnicamente
compatibles con el stack Flutter/Dart + libmpv, conservando Bee/MegaPlay.

Fuente primaria: ZIP adjunto por el propietario (solo lectura, extraído a
`/tmp/opencode/anilili/` para análisis). Referencia secundaria:
https://github.com/Unknowmyt1M/anilili y https://github.com/sanilili.

Regla de portado: Anilili es Android/Kotlin (OkHttp + WebView + Media3). Se adaptan
algoritmos y flujos a Dart/Dio + libmpv. Lo que depende de WebView (emulación de
navegador para sortear Cloudflare o ejecutar JS/WASM del host) NO se porta, conforme
a la política del proyecto contra evasión de controles de acceso.

---

## FASE A — Estado recuperado de Codex

- HEAD `main` = `6cc3e5e` (sin commits nuevos; cambios en árbol sin commitear, conservados).
- MegaPlay/bee funciona: Tokyo Ghoul:re 9 (AniList 100240) verificado con sub y dub,
  subtítulos ES/EN, seek, progreso y retorno (auditoría OC04-MEGAPLAY + OC04-LANGUAGES).
- Códec: openh264 2.6.0 local en `.ai-local/native-codecs/`, lanzador
  `tools/player/run_kongroo_linux.sh --debug --openh264`.
- Módulo de providers registrado: megaplay (110), megaplay-dub (105), miruro-catalog (100),
  animeav1 (95), wikimedia (opt-in), user-defined (50). Resolutores: Voe + DirectMedia.
- Miruro directo sigue en HTTP 403 de Cloudflare (bloqueo documentado, no se reintenta ni evade).
- **Regresión detectada y corregida en esta fase:** el test
  `user_defined_playback_provider_test.dart` («registers the user provider only when
  entries exist») fallaba con «Bad state: Too many elements» porque Codex añadió
  `enableAnimeAv1 = true` al módulo sin actualizar el test que espera `diagnostics.single`.
  Corregido añadiendo `enableAnimeAv1: false` al caso (el test aísla user-defined).
- Línea base tras el fix: **61/61 tests de providers en verde** (toolchain
  `.ai-local/toolchains/flutter` 3.50.0-0.4.pre, `PUB_CACHE=.ai-local/pub-cache`).
- Suite completa: ver sección de verificación final.

## FASE B — Matriz de proveedores del ZIP

| Nombre | Referencia Anilili | Tipo | Flujo | Idiomas | Formato | Kongroo | Riesgos | Estado |
|---|---|---|---|---|---|---|---|---|
| Miruro pipe (`bonk`,`kiwi`,`pewe`,`bee`,`ally`,`moo`,`hop` nativos; `nun`,`bun`,`twin`,`cog`,`telli` embeds) | `PipeBridge.kt` + `PipeClient.kt` + `docs/PIPE_PROTOCOL.md` | Proveedor (pipe) | WebView same-origin → `/api/secure/pipe?e=b64` → XOR+gzip | sub+dub | HLS nativo / iframe embeds | Parcial: `MiruroCatalogApi` ya porta el protocolo (episodes/sources, decode XOR+gzip) | Cloudflare fingerprint: el pipe solo pasa desde un WebView real con `cf_clearance`; HTTP directo = 403 (verificado por Codex) | **Bloqueado** (política: sin WebView/evasión) |
| AniKoto → **MegaPlay** (`megaplay.buzz`) | `AnivexaClient.anikoto` + `anikotoMalSources` | Host/proveedor | embed `/stream/{ani|mal}/{id}/{ep}/{audio}` → `data-id` → `/stream/getSources*` | sub+dub | HLS + subtítulos VTT | **Implementado** (`megaplay` + `megaplay-dub`, N4 verificado) | Dependencia de rutas JS del host | Probado |
| AllAnime | `AllAnimeProvider.kt` + `AllAnimeCodec` | Proveedor (API GraphQL) | search GraphQL → sources por `sha256Hash` persistido → decrypt AES-CTR → `--hex` → `/clock.json` | sub+dub (`translationType`) | HLS/MP4 | Ausente → **implementar** | API pública con payload cifrado; verificación de reproducible con `#EXTM3U`/Range | Por implementar |
| AnimeKai | `AnimeKaiProvider.kt` + `AnimeKaiParser` | Proveedor (HTML, 5 mirrors `anikai.cc`) | `/browser?keyword` → `/watch/{slug}/ep-N` → `server-items` → embed → HLS verificado | sub (hsub/softsub) + dub | HLS + subtítulos | Ausente → **implementar** | mirrors rotativos; matching con verificación MAL | Por implementar |
| ReAnime | `AnivexaClient.reanime` + `FlixcloudBridge.kt` + `ReanimeFlixcloudParser.kt` | Proveedor (API + embeds) | `reanime.to/api/flix/{anilistId}/{ep}` → servers `dataLink` → flixcloud.cc en WebView para capturar HLS | sub+dub (dual-audio `a=1`) | HLS (solo vía WebView) | Ausente | El HLS de flixcloud se genera con JS/WASM rotativo: sin WebView no hay HLS; los embeds no son reproducibles por libmpv | **Bloqueado** (sin WebView) |
| AniZone | `AnivexaClient.anizone` | Proveedor (HTML) | `/anime?search=` → `/anime/{slug}/{ep}` → `<media-player src=...m3u8>` + `<track>` | sub | HLS + subtítulos | Ausente → **implementar** | HTML scraping | Por implementar |
| AnimeGG | `AnivexaClient.animegg` | Proveedor (HTML) | `/search/?q=` → `/series/{id}` → tabs `data-toggle` (sub/dub) → `/embed/{id}` → HLS/MP4 jwplayer | sub+dub | HLS/MP4 | Ausente → **implementar** | HTML scraping | Por implementar |
| AniNeko | `AnivexaClient.anineko` | Proveedor (HTML) | `/browser?keyword=` → `/watch/{slug}/ep-N` → `nv-server-grid` (sub/dub) → embeds `data-video` → HLS en embed + subs por query | sub+dub | HLS + subtítulos | Ausente → **implementar** | HTML scraping | Por implementar |
| 2DHive | `AnivexaClient.twoDhive` | Proveedor (API + Astro props) | requiere **MAL id** → `/episode?anime={mal}&ep={n}` → props Astro `servers` → `/api/hadfree?slug` (dub) + `/api/hianime?mal_id` (sub) | sub+dub | HLS/MP4 | Ausente → **implementar** | depende de idMal de AniList | Por implementar |
| Senshi / AniBD / KickAssAnime / RareAnimes | — | — | — | — | — | — | **No existen en esta versión del ZIP** (verificado por grep) | N/A |

### Proveedores con bloqueo demostrado (2026-11-17)

| Proveedor | Bloqueo | Evidencia |
|---|---|---|
| ReAnime | HLS nativo inaccesible sin WebView | La API `reanime.to/api/flix/{anilistId}/{ep}` responde 200 con servers (HD-1/HD-2 `dataLink` → `flixcloud.cc/e/...`), pero el embed no expone `.m3u8` estático: solo workers WASM (`subtitles-octopus-worker.wasm`) y JS rotativo; Anilili lo resuelve con `FlixcloudBridge` (WebView real). Política del proyecto: sin WebView ni ejecución de JS del host. No se registran los embeds (libmpv no reproduce iframes). | 
| AniNeko | Host caído | `anineko.to`: DNS resuelve (Cloudflare) pero la conexión TLS abre y el servidor no entrega datos (timeout con 0 bytes). Sin forma de verificar nada; no se integra código no verificable. |
| AnimeKai | Host caído | Los 5 mirrors (`anikai.cc`, `www1-4`) fallan en conexión (timeout TCP). Igual criterio que AniNeko. |
| 2Dhive (ver PASO 5) | Sin contenido único | Sus APIs propias no entregan playlist para ningún título probado; su página solo embebe MegaPlay, host ya cubierto. Se portó su aporte real: la ruta MAL de MegaPlay. |

Deducción de identidad (regla 5.1): AllAnime y AnimeKai publican `malId` en sus
resultados de búsqueda → matching conservativo por `externalId` (crosswalk MAL).
AniZone/AnimeGG/AniNeko/2DHive no publican MAL → matching por título exacto
normalizado (`exactTitle`); si no hay coincidencia exacta, el proveedor devuelve
vacío (nunca fuzzy silencioso). 2DHive usa idMal directamente como parámetro.

## FASE C — Implementación

(Se documenta cada proveedor al completarse; ver secciones siguientes.)

---

## Registro de pasos

### PASO 1 — FASE A completada (2026-11-17)
Recuperación del estado de Codex, corrección de la regresión del test user-defined
(61/61 providers en verde), inventario del ZIP y matriz de la FASE B. Sin commits.

### PASO 2 — AllAnime integrado (2026-11-17)
- **Archivos:** `app/lib/data/player/providers/allanime/allanime_playback_provider.dart`
  (+README), extensión POST JSON de `public_playback_http.dart`, registro en
  `playback_providers_module.dart` (sub 92 / dub 91) y toggle en `main.dart`
  (`KONGROO_ENABLE_ALLANIME`).
- **Puerto:** `AllAnimeProvider.kt` + `AllAnimeCodec` de Anilili (MIT-0): búsqueda
  GraphQL por título (crosswalk `malId` o título exacto), fuentes por consulta
  persistida, descifrado AES-CTR del payload con semilla pública `Xot36i3lK3:v1`,
  códec hex `--` y relé `clock.json`; embeds descartados.
- **Pruebas:** 10 casos nuevos (92→93 suite de providers); analyze limpio.
- **Live (N2):** búsqueda verificada HTTP 200 en `api.allanime.day` (y espejo
  `api.mkissa.net`) con resultados reales; Tokyo Ghoul:re resuelve por título
  exacto y por crosswalk MAL. **Fuentes bloqueadas**: la consulta `episode()`
  exige desde julio 2026 el token anti-scraping `aaReq` (AES-256-GCM con clave
  rotativa epoch/partB+mask extraída de un bundle ofuscado de 1,1 MB; valida
  carril/build/ventana: AA_CRYPTO_MISSING/LANE/BUILD/QUERY_MISMATCH). La forma
  live real (`HTTP 200 + errors + episode:null`) está reproducida como regresión
  y el adaptador la traduce a `noSources` para que el fallback continúe.
  ani-cli eliminó AllAnime en v5 por la misma razón; no se evita el control.
- **Bugs reales encontrados por la verificación live:** lista `const` inmodificable
  que rompía `.sort()` (no cubierto por fakes), y `malId` entregado como cadena
  (Anilili lo parseaba; el adaptador inicial lo descartaba). Ambos corregidos.
- Estado: **N2-búsqueda verificada / fuentes bloqueadas (demostrado)**.

### PASO 3 — AniZone integrado y verificado con motor (2026-11-17)
- **Archivos:** `html_playback_parsers.dart` (puerto compartido de
  `NativeProviderParsers.kt`: attr/stripTags/decodeEntities/titleScore bigram-Dice/
  absoluteUrl/hlsUrls/decodeJsonEscapes) y
  `anizone/anizone_playback_provider.dart`.
- **Puerto:** `AnivexaClient.anizone` de Anilili (MIT-0) adaptado al marcado
  actual (Livewire): los resultados de `/anime?search=` y el manifiesto del
  reproductor viven en JSON escapado (`\u0022`, `\/`, `JSON.parse('...')`) —
  el `anmTitles` del snapshot ya no existe. Matching conservativo por título
  exacto; nunca fuzzy.
- **Live N2:** búsqueda 200 con slugs reales (TG:re → `djivt6wx`); página
  `/anime/djivt6wx/9` publica HLS directo
  (`seiryuu.vid-cdn.xyz/.../master.m3u8`, `#EXTM3U`, calidades 360/720/1080,
  audio ja+en). Subtítulos solo `.ass` → el contrato VTT los descarta
  (limitación documentada).
- **Live N3/N4 (motor real, runner `tool/anilili_live_player_app.dart`):**
  RESOLVED 3 (megaplay, megaplay-dub, anizone), PLAY anizone, SEEK 20000 ms,
  FRAME renderizado, ADVANCE 24587/1452075 ms, captura
  `.ai-local/anilili-live/anizone-tokyo-ghoul-re-9.png`, REOPEN, LIVE-ENGINE-OK.
- **Pruebas:** 6 casos (fixture con escapes reales de la página viva);
  suite de providers 99/99 al integrarlo.
- **Diagnósticos de cadena en vivo:** miruro=forbidden, animeav1=missingId,
  allanime=noSources — el fallback del manager funciona como está diseñado.

### PASO 4 — AnimeGG integrado y verificado con motor (2026-11-17)
- **Archivo:** `animegg/animegg_playback_provider.dart` (variantes
  `animegg` 84 / `animegg-dub` 83; `KONGROO_ENABLE_ANIMEGG`).
- **Puerto:** `AnivexaClient.animegg` adaptado: título en `<h2>` del ancla
  `mse` (el `<strong>` del snapshot ya no está), filas `anm_det_pop`,
  pestañas `data-toggle="tab"` con `data-version="subbed|dubbed"`
  (comillas simples en `data-id`, cubiertas por el parser de atributos),
  embeds con HLS y MP4 progresivos jwplayer (`/play/{id}/video.mp4?for=`).
- **Live N2:** búsqueda 200; serie `/series/tokyo-ghoulre`; episodio 9 →
  `/tokyo-ghoulre-episode-9`; embed 91335 → dos MP4 que redirigen (302) a
  `s121.vidcache.net:8166` con `206 video/mp4` (Range).
- **Hallazgo real (throttling por UA):** con UA `libmpv` el CDN entrega
  ~28 KB/s (injugable); con UA móvil Chrome ~176 KB/s. Añadido User-Agent
  de navegador a las cabeceras de medio del candidato (Referer ya estaba).
  A/B documentado en el README del provider.
- **Live N3/N4:** RESOLVED 7 (megaplay×2, anizone, animegg×2, animegg-dub×2),
  FRAME renderizado con openh264, ADVANCE 2002 ms, SEEK-IN-PLAY 20000 ms,
  captura `.ai-local/anilili-live/animegg-tokyo-ghoul-re-9.png`, REOPEN,
  LIVE-ENGINE-OK provider=animegg. Nota: `restoreStartPosition(20s)` antes de
  abrir falla en MP4 progresivos remotos (`PlaybackResumeFailure`, ya visto
  por Codex en Commons); el arnés verifica seek EN reproducción.
- **Pruebas:** 8 casos; suite de providers 107/107 al integrarlo.

### PASO 5 — 2Dhive: sin contenido propio; su valor real era la ruta MAL de MegaPlay (2026-11-17)
- **Evidencia live:** el sitio responde, pero la página de episodio
  (`/episode?anime=36511&ep_num=9`) solo embebe un iframe
  `megaplay.buzz/stream/mal/36511/9/sub`; los props Astro con `prefetchedHls`/
  HAdfree del snapshot de Anilili ya no existen; `/api/hianime` responde
  `No streamable video playlist` para Tokyo Ghoul:re y para 5 series de portada
  (One Piece 21, Bleach 269, etc.); `/api/hadfree` queda inalcanzable sin los
  props que daban el slug.
- **Decisión:** NO se integra un provider 2dhive duplicado del host MegaPlay
  (regla de la misión: no duplicar resolutores del mismo host). En su lugar se
  portó la mejora demostrable: **fallback MAL en MegaPlay**
  (`/stream/mal/{malId}/{ep}/{audio}`, igual que `anikotoMalSources` de Anilili
  y que el propio embed de 2Dhive).
- **Live N2 de la ruta MAL:** `/stream/mal/36511/9/sub` → 200 con
  `data-id="74086"`; `getSources?id=74086` devuelve el manifiesto con pistas VTT
  (misma media que la ruta ani). El resto del pipeline ya está acreditado a N4.
- **Pruebas:** caso nuevo «MyAnimeList fallback serves when the AniList route
  misses» en la suite de megaplay (12/12); las 11 pruebas previas sin cambios
  prueban que el comportamiento sin idMal se conserva (403/404 → fallo
  inmediato, sin reintentos).



### PASO 6 — Proveedores con bloqueo demostrado + regresión final (2026-11-17)
- ReAnime: API viva (servers con `dataLink` a flixcloud) pero el HLS se genera
  con JS/WASM en WebView — sin `.m3u8` estático en el embed (verificado).
  No se portó el `FlixcloudBridge` (política anti-WebView del proyecto).
- AniNeko/AnimeKai: hosts caídos en la verificación (TLS sin datos / timeout
  en los 5 mirrors). No se integra código imposible de verificar.
- **Regresión final:** `flutter analyze` — 3 infos + 1 lint preexistentes
  (voe×2, public_playback_http_test×1) y 0 hallazgos nuevos; **suite completa
  398 aprobadas / 10 omitidas** (25 pruebas nuevas en la misión);
  `memory.py check` limpio; build Linux debug de `lib/main.dart` restaurado
  como bundle actual. Sin commits ni pushes (HEAD `6cc3e5e`).

---

### PASO 7 — Correcciones posteriores al informe (2026-11-18)
- **`PlaybackResumeFailure` en MP4 progresivo: RESUELTO, sin cambio de código.**  Reproducido y verificado con el motor real sobre la fuente AnimeGG:
  `restoreStartPosition(20 s)` responde `SEEK-RESTORE confirmed: 20000 ms`
  → primer fotograma → ADVANCE 20061/1450179 ms. La causa raíz era el
  throttling por UA ya corregido en el PASO 4 (mpv a ~28 KB/s no terminaba de
  sondear el archivo dentro del presupuesto de 12 s) — misma familia que el
  429/UA de Wikimedia documentado en OC-03.1. El seek en reproducción
  (SEEK-IN-PLAY) también queda verificado. No se modificó el coordinador.
- **Varianza de red documentada (sin cambio):** en dos arranques del motor el
  descubrimiento de AnimeGG agotó el presupuesto de 6 s por petición ( primer
  GET frío ~5-7 s bajo carga de arranque; IPv6 de Cloudflare a 4,4 s vs 1,9 s
  v4 medidos con curl). Sonda Dart sin motor: 3/3 OK (7541/3151/3379 ms). El
  manager registró `timeout` y continuó con el resto por diseño; en el tercer
  arranque resolvió los 7 streams. Se conserva el presupuesto del transporte
  (decisión de diseño de OC-02); se añade la sonda
  `tool/animegg_timing_probe.dart` para medirlo sin motor.
- **`flutter analyze` 100 % limpio (0 avisos):** corregidos los 3 infos
  preexistentes de Codex (llaves de bloque en `voe_video_host_resolver.dart`
  ×2 y `public_playback_http_test.dart` ×1). El cast innecesario del test de
  AnimeGG se corrigió el día anterior.
- **Resto de «fallos pendientes» del informe:** siguen siendo bloqueos
  externos demostrados, no errores de Kongroo (aaReq de AllAnime; AniNeko y
  AnimeKai caídos; ReAnime sin WebView; Miruro 403). No hay acción posible
  legítima por parte del proyecto hasta que cambien.


---

## INFORME FINAL — Niveles de validación

| Proveedor | Integrado | Fuente obtenida | Video real | Pruebas | Estado |
|---|---|---|---|---|---|
| MegaPlay/bee (AniKoto) | Sí (sub+dub, + fallback MAL) | Sí (ani y mal, en vivo) | Sí (N4 previo + regresión N3 nueva: FRAME/ADVANCE/captura) | 12/12 | **N4-N5** |
| AniZone | Sí | Sí (en vivo, HLS directo) | Sí (N3/N4: FRAME/ADVANCE/SEEK/captura/LIVE-ENGINE-OK) | 6/6 | **N4** |
| AnimeGG | Sí (sub+dub) | Sí (en vivo, MP4+HLS) | Sí (N3/N4: FRAME/ADVANCE/SEEK-RESTORE 20 s + SEEK-IN-PLAY/captura) | 8/8 | **N4** |
| AllAnime | Sí (sub+dub) | Búsqueda sí; fuentes NO (aaReq) | No | 10/10 (incluye forma live AA_CRYPTO) | **N2-búsqueda / fuentes bloqueadas** |
| Miruro pipe | Parcial (heredado) | No (403 CF) | No | heredadas | Bloqueado (heredado) |
| ReAnime | No | API sí; HLS no | No | — | Bloqueado (flixcloud WASM/WebView) |
| 2Dhive | No (host duplicado) | Su embed usa MegaPlay (ruta MAL portada) | Vía MegaPlay | 12/12 megaplay | Cubierto vía MegaPlay |
| AniNeko | No | No | No | — | Host caído (demostrado) |
| AnimeKai | No | No | No | — | Host caído (demostrado) |
| Senshi/AniBD/KickAss/RareAnimes | No | — | — | — | No existen en el ZIP |

Servidores que aparecen en la interfaz (flujo de resolución real, en vivo):
MegaPlay · Original/Doblaje, AniZone, AnimeGG ×2 sub + ×2 dub (por espejo
`data-mirror`), más los heredados (Wikimedia opt-in, user-defined).

## ENTREGA PARA LA SIGUIENTE ETAPA — MODULARIZACIÓN

Qué queda estable y qué proteger:

- **Módulos estables (contratos a preservar):** `EpisodeSourceAdapter` /
  `PlaybackSourceProvider` / `PlaybackVideoHostResolver` (domain),
  `PlaybackProviderManager` (fallback + circuitos + dedup — no cambiar su
  semántica de `stopAfterFirst`/prioridades sin ADR),
  `PublicPlaybackHttp` (allowlist, presupuesto, Retry-After; el POST JSON
  nuevo sigue la misma política), `DirectMediaHostResolver`, engine
  media_kit/libmpv (intocable), persistencia de progreso.
- **Código duplicado (candidatos a plantilla/base):** `_read/_check/
  _validMatch/_contractTitle` se repiten en allanime/anizone/animegg
  (y parcialmente en animeav1/megaplay); los bucles «hasta 3 títulos,
  dedupe, match exacto» son idénticos; los tres scrapers repiten el patrón
  de acumulación de candidatos con tope.
- **Parsers:** consolidar `html_playback_parsers.dart` con el parser devalue
  de AnimeAV1 (`AnimeAv1PageData`) y el extractor AES de MegaPlay en un solo
  módulo de utilidades de proveedores, con sus tests unitarios propios
  (hoy solo se prueban vía adapters).
- **Dependencias separables:** `cryptography` solo la usan megaplay
  (AES-CBC) y allanime (AES-CTR + SHA-256); considerar aislarla tras un
  contrato de descifrado si se quiere recortar superficie.
- **Pruebas que protegen el comportamiento:** megaplay 12, allanime 10,
  anizone 6, animegg 8, manager 21, user-defined/module (actualizados),
  wikimedia opt-in — más los runners `app/tool/*live*` y la sonda
  `animegg_timing_probe.dart` para N2/N3.
- **Problemas de rendimiento pendientes:** presupuesto de 6 s por petición
  frente a GETs fríos ~5-7 s (varianza IPv6/v4 documentada en el PASO 7);
  presupuesto total de la cadena de resolución con 9 providers registrados
  (animeav1 puede consumir varias peticiones antes de fallar); el runner de
  motor abre ventana Wayland (~60 s por verificación, secuencial).
- **No ejecutar la modularización todavía** — orden del propietario.
