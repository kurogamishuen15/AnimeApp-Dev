# KONGROO — Proveedores y servidores de reproducción

Documentación maestra de la capa de descubrimiento y reproducción de Kongroo.
Cubre los nueve registros automáticos del `PlaybackProviderManager`, sus
hosts, niveles de validación y cómo mantenerlos.

---

## 1. Resumen del sistema

La arquitectura de reproducción es una cadena de responsabilidades:

```
Proveedor → Episodio → Servidor/Host → Resolver → PlaybackProviderManager → media_kit/libmpv
```

- **Proveedor** (`EpisodeSourceAdapter`): identifica el anime por crosswalk
  (AniList/MAL) o título exacto, enumera episodios y descubre los
  candidatos de servidor publicados (`PlaybackSource` con
  `SourceCandidate`s). Los seis adapters comparten los helpers de
  `episode_source_support.dart` (`read`/`check`/`contractTitle`): un único
  mapeo null→Empty, fallos de transporte→resultado propio y
  FormatException/ArgumentError→`invalidResponse`, con pruebas de
  caracterización en
  `test/data/player/providers/episode_source_support_test.dart`.
- **Resolver** (`PlaybackVideoHostResolver`): convierte un candidato en un
  medio reproducible (`ResolvedPlaybackStream`): `DirectMediaHostResolver`
  normaliza URLs directas HTTPS (HLS/MP4/DASH) y `VoeVideoHostResolver`
  extrae el HLS del embed de VOE. Los embeds que exigen navegador nunca se
  devuelven como reproducibles.
- **`PlaybackProviderManager`**: único registro y coordinador de fallback.
  Ordena por prioridad, deduplica peticiones idénticas por episodio,
  aplica circuitos por proveedor y por host, resuelve todos los
  candidatos (`resolveCandidates`) o solo el primero (`resolveSource`),
  y clasifica cada fallo (`forbidden`, `notFound`, `timeout`, `challenge`,
  `noSources`, …) para continuar con el siguiente proveedor.
- **Motor**: `media_kit/libmpv` (único, intocable). El medio llega con
  cabeceras públicas (`Referer`/`Origin`/`User-Agent` y, para AllAnime,
  `x-build-id`/`x-aa-boot` en las llamadas de API) y el progreso se persiste
  por episodio.

Los nueve registros automáticos se conectan en `PlaybackProvidersModule`
(`app/lib/data/player/providers/playback_providers_module.dart`):

| # | Registro | Prioridad | Implementación |
|--:|---|---:|---|
| 1 | `megaplay` | 110 | `megaplay/megaplay_playback_provider.dart` |
| 2 | `megaplay-dub` | 105 | ídem (variante dub) |
| 3 | `miruro-catalog` | 100 | `miruro/miruro_catalog_playback_provider.dart` |
| 4 | `animeav1` | 95 | `animeav1/animeav1_playback_provider.dart` |
| 5 | `allanime` | 92 | `allanime/allanime_playback_provider.dart` |
| 6 | `allanime-dub` | 91 | ídem (variante dub) |
| 7 | `anizone` | 86 | `anizone/anizone_playback_provider.dart` |
| 8 | `animegg` | 84 | `animegg/animegg_playback_provider.dart` |
| 9 | `animegg-dub` | 83 | ídem (variante dub) |

Opt-in: `wikimedia-commons` (`KONGROO_ENABLE_WIKIMEDIA=1`) y `user-defined`
(`KONGROO_USER_SOURCES`). Cada registro automático se desactiva con
`KONGROO_ENABLE_<NOMBRE>=0`.

---

## 2. Tabla de los nueve proveedores

| Proveedor | Prioridad | Estado inicial | Estado final | Nivel | Problema | Solución |
|---|---:|---|---|---|---|---|
| megaplay | 110 | N4 histórico | **Reparado 19-11: FRAME→ADVANCE→SEEK→REOPEN→LIVE-ENGINE-OK con engine sin auto-carga de captions remotas** | **N5 revalidado** | La auto-selección de una caption externa predeterminada hacía que libmpv reportara Playback failed; no era una falla del video/CDN en este recorrido | Las captions siguen en la lista y se cargan solo cuando se seleccionan desde el menú |
| megaplay-dub | 105 | N4 histórico | **Reparado 19-11: FRAME→ADVANCE→SEEK→REOPEN→LIVE-ENGINE-OK con captions remotas disponibles para selección manual** | **N5 revalidado** | La misma auto-selección de caption externa detenía el estado del video | Las captions siguen en la lista y se cargan solo cuando se seleccionan desde el menú |
| miruro-catalog | 100 | 403 Cloudflare | Frontend actual identificado; `/health` responde, pero catálogo `/api/config` devuelve 403 con UA propio | **N1 externo** | La interfaz de catálogo/playback no entregó respuesta; health no prueba catálogo | Solo `.cx`; hace falta contrato de API externa o habilitación del operador |
| animeav1 | 95 | `missingId`; sin cuadros | **Motor re-verificado vía VOE el 18-11 (OC-05)**: FRAME→ADVANCE→SEEK→REOPEN→LIVE-ENGINE-OK, subtítulo ES incrustado visible | **N5** | `invalidResponse` sistemático en el manager (validación multi-servidor) y 4 peticiones antes del episodio | `sourceAlternatives` + regresión por manager; **una sola pasada catálogo→confirmación MAL→episodio** |
| allanime | 92 | `aaReq` bloqueaba fuentes | **OC-06:** clasificación `challenge`; el `User-Agent` Chrome heredado se retiró 19-11; acceso con identidad Kongroo no revalidado live | **N2 protocolo histórico** | `NEED_CAPTCHA` es lógica del origen, no challenge de Cloudflare | No enviar token; se requiere vía autorizada del operador |
| allanime-dub | 91 | ídem | Igual que sub; el `User-Agent` Chrome heredado se retiró 19-11; acceso honesto no revalidado live | **N2 protocolo histórico** | ídem: captcha de aplicación | ídem |
| anizone | 86 | N4 verificado | Revalidado con motor (HLS 360/720/1080, audio ja/en) | **N5** | — | Conservado |
| animegg | 84 | N4 histórico | Reproducción con motor fue probada con UA Chrome heredado; se retiró 19-11 | **N4 histórico; actual sin revalidar** | velocidad del CDN bajo identidad Kongroo desconocida | User-Agent propio; no suplantar navegador |
| animegg-dub | 83 | N4 histórico | Reproducción con motor fue probada con UA Chrome heredado; se retiró 19-11 | **N4 histórico; actual sin revalidar** | velocidad del CDN bajo identidad Kongroo desconocida | User-Agent propio; no suplantar navegador |

**Historial N5/N4:** MegaPlay se revalidó el 19-11 después de corregir la
auto-carga de captions remotas. AnimeGG y AllAnime ya no usan los UA de
navegador con que se obtuvieron sus evidencias históricas y no se han
revalidado con identidad propia de Kongroo. **Bloqueos observados:** Miruro
WAF, AllAnime `NEED_CAPTCHA` bajo las consultas registradas.

---

## 3. Ficha técnica individual

### megaplay / megaplay-dub — `megaplay/`

- **Responsabilidad:** fuentes exactas por AniList ID y episodio, con
  **fallback a la ruta MyAnimeList** (`/stream/mal/{malId}/{ep}/{sub|dub}`)
  cuando la ruta AniList falla (404/403/sin `data-id`), igual que el
  `anikoto` de Anilili y el propio embed de 2Dhive.
- **Ruta:** `megaplay/megaplay_playback_provider.dart` (+README).
- **Dependencias:** `cryptography` (AES-256-CBC del payload `enc`), transporte
  compartido `PublicPlaybackHttp` con Retry-After por origen.
- **Hosts:** `megaplay.buzz` (embed + `stream/getSources*`), medio en
  `fetch.nexabloom.top` (HLS). **Formatos:** HLS, subtítulos VTT.
- **Idiomas:** variantes anunciadas sub/dub; pistas VTT con idioma por
  etiqueta.
- **Identificadores:** AniList ID exacto; `idMal` solo para el fallback.
- **Búsqueda→episodio→fuentes:** mapping directo (sin índice inventado,
  `listEpisodes` responde unsupported), `data-id` del embed,
  rutas descubiertas del script público del sitio (máx. 3 de la familia
  `stream/getSources…`).
- **Manager:** prioridades 110/105; fallos 403/404 inmediatos, sin reintentos.
- **Pruebas:** 12 (dos variantes, rutas retiradas, payload cifrado,
  subtítulos, Referer/Origen, 403/404, cancelación, **fallback MAL**).
- **Evidencia:** reproducción 1920×1080 re-verificada (SEEK-RESTORE 20 s,
  ADVANCE, REOPEN); capturas en `.ai-local/anilili-live/`.
- **Limitaciones:** URLs firmadas no se persisten; Nested-iframe limitado a
  la misma familia.

### miruro-catalog — `miruro/`

- **Responsabilidad:** catálogo REST público de Miruro por AniList ID.
- **Host vigente:** `www.miruro.cx`, anunciado por Miruro como dominio
  principal exclusivo. Los dominios `.to`, `.tv`, `.bz` y `.ru` se retiraron
  del registro de solicitudes para no usar hosts que Miruro ya no recomienda.
- **Estado OC-07 (2026-11-19):** el HTML y el bundle desplegados responden con
  UA propio de Kongroo; el bundle actual no incluye `VITE_BACKEND_URL` y usa
  rutas same-origin. `GET /health` devuelve JSON de salud/versionado. La ruta
  conocida `GET /api/config` devuelve 403 incluso con UA propio, por lo que no
  se obtuvieron datos de catálogo. La web actual y el backend histórico son
  contratos diferentes; no se confirmó endpoint externo actual.
- **Backend histórico:** un `.env.example` indexado del repositorio web de
  Miruro describe `VITE_BACKEND_URL` con `public-miruro-consumet-api.vercel.app`
  como ejemplo. El archivo enlazado ya devuelve 404 y no documenta un contrato
  estable de consumidor externo. No se trata como API oficial de Kongroo.
- **Pruebas:** fixtures offline del provider y parser; no prueban disponibilidad
  actual. El manager conserva fallback a otros registros.
- **Estado:** N1 externo (interfaz localizada, catálogo sin respuesta). Un
  cliente Go comunitario describe búsqueda, mapping AniList, episodios,
  listings y resolución de fuente; su modelo sirve para comparar, pero su
  transporte documenta impersonación de navegador/HTTP2 para superar el WAF y
  no se porta. Para reabrir playback se requiere documentación de API externa
  o habilitación del operador. No usar challenges, clearance ni mirrors
  retirados. Evidencia y tabla de requests: [OC-07](../../../../../docs/ai-system/missions/OC07-MIRURO-FRONTEND-BACKEND-CONTRACT-2026-11-19.md).
- **Pruebas:** heredadas (32 de providers al cierre OC-04).
- **Estado:** N1 externo según OC-07; página y health visibles, catálogo sin
  respuesta. Véase el informe OC-07 para diferenciar rutas observadas y
  límites de evidencia.

### animeav1 — `animeav1/`

- **Responsabilidad:** catálogo SvelteKit (`__data.json` devalue) con
  crosswalk MAL confirmado y embeds por episodio.
- **Hosts:** `animeav1.com` (catálogo), **`voe.sx`** (resuelto por
  `VoeVideoHostResolver` → HLS en `cloudwindow-route.com`),
  `mp4upload`/`yourupload` (sin resolutores activos).
- **Formatos:** HLS (VOE). **Idiomas:** SUB (subtítulos ES incrustados) y DUB
  latino cuando existen.
- **Pruebas:** 12 (incluida la regresión por el manager que fijó el
  `invalidResponse` sistemático).
- **Evidencia:** `LIVE-ENGINE-OK provider=animeav1` con captura.

### allanime / allanime-dub — `allanime/`

- **Responsabilidad:** fuentes de AllAnime/M.Kissa vía el protocolo público
  **client-crypto** (ver § ficha en `allanime/README.md`): bootstrap HMAC →
  `aaReq` AES-GCM → `tobeparsed` AES-GCM con clave dinámica `partB XOR
  máscara`.
- **Hosts:** `api.mkissa.net` (API+bootstrap), `allanime.day` (relé
  `clock.json`), medio en `tools.fast4speed.rsvp` (MP4 con Authorization en
  la URL).
- **Identidad:** crosswalk `malId` (cadena numérica) o título exacto.
- **Idiomas:** variantes sub/dub (`translationType`), cada una con su MP4.
- **Pruebas:** 12 (bootstrap, aaReq wire, GCM, dub, formas live
  `AA_CRYPTO_STALE`/`NEED_CAPTCHA`/`invalid_boot_token`, contratos de
  cabecera).
- **Evidencia:** descifrado real en vivo con `sourceUrls` sub+dub y sonda
  `206` de 370 MB **antes** de que la API exigiera captcha por el volumen
  de la investigación; tras ello, `challenge` clasificado y sin evasión.
- **Limitaciones:** materiales por build (190) centralizados en
  `AllAnimeBootMaterials`; rotación futura ⇒ `unavailable`.

### anizone — `anizone/`

- **Responsabilidad:** HLS directo del reproductor de AniZone, marcado
  Livewire (resultados y manifiesto en JSON escapado de `x-data`/
  `wire:snapshot`/`kPlayer(JSON.parse(...))`), sin JavaScript.
- **Hosts:** `anizone.to` (páginas), `seiryuu.vid-cdn.xyz` (HLS 360/720/1080
  con audio ja+en).
- **Idiomas:** sub; el manifiesto publica pistas de audio alternativas.
- **Identidad:** slug (`djivt6wx`) por título exacto.
- **Pruebas:** 6 con fixtures de los escapes reales de la página viva.
- **Evidencia:** `LIVE-ENGINE-OK provider=anizone` con captura.
- **Limitaciones:** subtítulos del sitio en ASS (el contrato VTT los
  descarta, no se falsean pistas).

### animegg / animegg-dub — `animegg/`

- **Responsabilidad:** espejos sub/dub de AnimeGG (`data-toggle="tab"`
  `data-version="subbed|dubbed"`) con MP4 progresivo jwplayer y HLS del
  embed `/embed/{id}`.
- **Hosts:** `www.animegg.org` (páginas+CDN `/play/{id}/video.mp4?for=` →
  302 a `vidcache.net:8166`, `206` con Range), embeds con HLS.
- **Idiomas:** variantes anunciadas por pestaña.
- **Pruebas:** 8 (manager, dub con `data-id` propio, HLS, episodio ausente,
  403, cancelación, UA en candidatos).
- **Evidencia:** motor re-verificado en ambas variantes (espejos 227251 sub
  y 226001 dub).
- **Limitaciones:** presupuesto de 6 s por petición vs GETs fríos ~5-7 s
  (varianza IPv6/v4 documentada; sonda `animegg_timing_probe.dart`).

---

## 4. Problemas encontrados y soluciones aplicadas

1. **animeav1 devolvía `invalidResponse` sistemático en el manager.**
   *Causa:* el manager exige la capacidad `sourceAlternatives` para fuentes
   con más de un servidor; AnimeAV1 ofrece voe+mp4upload pero solo declaraba
   `episodeSources`. Los tests existentes nunca pasaban por el manager, así
   que el fallo era invisible. *Archivos:* `animeav1_playback_provider.dart`
   (capacidad añadida) y `animeav1_playback_provider_test.dart` (regresión
   por manager con resolver passthrough). *Verificación:* live check 3/3 OK
   y `LIVE-ENGINE-OK provider=animeav1` con video real.
2. **AllAnime: fuentes bloqueadas por el token `aaReq`.**
   *Investigación:* el paquete cambia de dominio a `mkissa.to/api.mkissa.net`
   y de semilla estática a un bootstrap por epoch (`x-aa-boot` = doble
   HMAC-SHA256 sobre la máscara del build), con `aaReq` = AES-256-GCM
   (`partB XOR máscara`) y `tobeparsed` AES-GCM con la misma clave dinámica.
   Se ejecutó el módulo real del sitio en Node para verificar cada pieza y el
   servidor aceptó el token reconstruido (`bootstrap` devolvió `partB`).
   *Archivos:* reescritura de `allanime_playback_provider.dart` (protocolo
   completo), `AllAnimeBootMaterials` (constantes por build),
   `playback_source.dart` (cabeceras públicas `x-build-id`/`x-aa-boot`
   validadas), `playback_providers_module.dart` (allowlist mkissa),
   `allanime_playback_provider_test.dart` (12 casos autoconsistentes con
   GCM). *Verificación:* descifro `tobeparsed` real con `sourceUrls` sub y
   dub y sonda de medio `206/370 MB`; tras el volumen de sondeos la API
   exigió Turnstile (`NEED_CAPTCHA`) ⇒ clasificado `challenge`, sin evasión.
3. **Restauración de posición en MP4 progresivo remoto.**
   *Causa raíz (ya corregida el 17-11):* throttling por UA del CDN. Con el UA
   de navegador en los candidatos, `restoreStartPosition(20 s)` funciona
   (`SEEK-RESTORE confirmed`). Sin cambios en el coordinador.
4. **Lints preexistentes:** llaves de bloque en `voe_video_host_resolver.dart`
   (×2) y `public_playback_http_test.dart`; `flutter analyze` quedó 100 %
   limpio.

---

5. **AnimeAV1 encadenaba cuatro peticiones por episodio (OC-05).**
   *Causa medida:* el puente por defecto de `EpisodeSourceAdapter.findSources`
   ejecuta `searchAnime` (catálogo + media) y luego `findEpisode` (otra vez
   media) + `findEpisodeSources` (episodio). *Corrección:* `findSources`
   implementa una sola pasada `catalogo → media (confirmación MAL) → episodio`
   reutilizando el índice de episodios de la propia página de confirmación
   (`_ConfirmedMatch`); el puente genérico sigue intacto para los demás.
   *Prueba:* `animeav1_playback_provider_test.dart` 12/12, incluido «no se
   inventa un episodio ausente del índice» (no se pide `/9/` si no existe).
6. **El selector esperaba la suma de todos los proveedores (OC-05).**
   *Causa medida:* `manager.resolveCandidates` resolvía 9 cadenas en serie
   (21 918 ms de línea base; 27–40 s en rondas con red degradada).
   *Corrección:* fan-out acotado a **4 cadenas** con orden de resultados por
   prioridad, un solo intento por host compartido entre proveedores y cierre
   único de breakers (`maxConcurrentProviderChains`,
   `_ProviderCandidates`). `resolveBestStream` conserva el recorrido
   secuencial para devolver siempre el proveedor de mayor prioridad.
   *Prueba:* 24/24 del manager, incluidas concurrencia, orden y tope de 4.
7. **AnimeAV1 no publica pistas suaves; el episodio SUB lleva hardsub.**
   *Diagnóstico:* el config de VOE trae `captions: []`, el master HLS no
   declara `EXT-X-MEDIA:TYPE=SUBTITLES`, ffprobe ve solo H264+AAC+timed_id3 y
   el OCR de fotogramas reales transcribe diálogo español quemado
   («Esto es…», «Pensé en reportar tu camarada…»). *
   *Corrección:* `VoeVideoHostResolver.decodePlayer` ahora publica
   `ProviderSubtitle` **solo** cuando el config declara captions públicas
   HTTPS `.vtt` válidas y conserva la marca de pista por defecto; el usuario
   las selecciona desde el menú para aislar errores del recurso externo del
   estado del video. Si no hay captions no se inventa ninguna.
   *Prueba:* `voe_video_host_resolver_test.dart` 9/9 (VTT válido, entradas
   http/.srt/fragmento/loopback descartadas, merge con pistas declaradas).
   *Evidencia gráfica:* captura del motor con subtítulo incrustado visible.

---

8. **Cloudflare: un bloqueo no es un challenge (OC-06).**
   *Causa:* `PublicPlaybackHttp` solo reconocía el challenge por
   `cf-mitigated`; un 403 con la página de bloqueo se reportaba como
   `forbidden` genérico y un challenge sin cabecera también. Además, el
   cuerpo de error se recortaba a 200 B, antes del `<title>`.
   *Corrección:* se leen 4 KiB de denegación y, si `cf-mitigated` falta, el
   título decide: «Just a moment…» → `challenge`; «Attention Required» /
   «you have been blocked» → `forbidden`. Se registra
   `cloudflare page=...` con `cf_ray` validado para la solicitud al operador.
   *Prueba:* fixtures de challenge HTML sin cabecera y de bloqueo en
   `public_playback_http_test.dart`.
9. **`NEED_CAPTCHA` tenía una detección más estrecha que la del sitio.**
   *Causa:* el detector solo miraba `message == 'NEED_CAPTCHA'` y
   `extensions.code`; el cliente del propio sitio acepta substring y
   `extensions.exception.code`. Una variante caía en `noSources`.
   *Corrección:* `_isCaptchaDemand` replica el detector del sitio. Sigue sin
   pedir, leer ni reenviar tokens.
   *Prueba:* caso nuevo en `allanime_playback_provider_test.dart`.

---

## 5. Matriz de servidores

| Host | Tipo | Usado por | Estado |
|---|---|---|---|
| `megaplay.buzz` | Host API+embed | megaplay, megaplay-dub (2Dhive también lo embebe vía ruta MAL) | ✅ resolvió embed y fuente el 19-11 |
| `fetch.nexabloom.top` | CDN HLS | megaplay/-dub | ✅ MegaPlay N5 revalidado tras desactivar auto-carga de captions externas |
| `www.miruro.{to,bz,cx,ru,tv}` | Host API | miruro-catalog | ⛔ Bloqueo WAF (200 dentro de un navegador) |
| `animeav1.com` | Proveedor | animeav1 | ✅ catálogo |
| `voe.sx` | Embed host | animeav1 (resolver VOE) | ✅ HLS real |
| `cloudwindow-route.com` | CDN HLS | animeav1 vía VOE | ✅ operativo |
| `api.mkissa.net` | API GraphQL+bootstrap | allanime/-dub | 🟡 challenge tras sondeo intensivo |
| `allanime.day` | Relé clock.json | allanime/-dub | no ejercitado hoy |
| `tools.fast4speed.rsvp` | CDN MP4 | allanime/-dub (Yt-mp4) | ✅ `206` verificado |
| `anizone.to` | Proveedor | anizone | ✅ operativo |
| `seiryuu.vid-cdn.xyz` | CDN HLS | anizone | ✅ operativo |
| `www.animegg.org` | Proveedor+CDN | animegg/-dub | ✅ operativo (varianza de red) |
| `*.vidcache.net:8166` | CDN MP4 | animegg/-dub | ✅ `206` verificado |

Deduplicación por identidad de endpoint; variantes sub/dub y espejos
distintos se conservan (p. ej. animegg sub `227251` vs dub `226001`).

---

## 6. Resultados de pruebas

- **Fecha:** 2026-11-18. **Entorno:** Fedora KDE Wayland, Flutter
  3.50.0-0.4.pre aislado (`.ai-local/toolchains/flutter`,
  `PUB_CACHE=.ai-local/pub-cache`), códec openh264 2.6.0 local
  (`tools/player/run_kongroo_linux.sh --openh264`).
- **Unitarias/manager (OC-05, 18-11):** `bash scripts/ci.sh` → 12/12 pasos;
  suite Flutter **420 aprobadas / 10 omitidas**. Manager 24/24, AnimeAV1
  12/12, VOE 9/9.
- **OC-06 (18-11):** suite Flutter **422 aprobadas / 10 omitidas** (12/12 pasos
  de CI, `exit=0`); http+allanime+miruro **33/33**; `dart analyze` limpio.
  Casos nuevos: challenge HTML sin `cf-mitigated`, página de bloqueo, y
  `NEED_CAPTCHA` en `extensions.exception.code`.
- **Rendimiento (OC-05, Tokyo Ghoul:re ep. 9, AniList 100240 / MAL 36511):**
  AnimeAV1 4 070 ms de línea base (search 948 + findSources 1 156 + VOE
  1 952); tras la pasada única, `findSources` hace 3 peticiones y el total
  queda en 3 629–4 167 ms según red. `manager.resolveCandidates`:
  **21 918 ms → 12 303 / 13 825 / 14 055 ms** (mediana 13 825). La cola
  restante es `animegg-dub`, con timeouts de 6 s por petición en 2 de 3
  rondas; no es un coste de AnimeAV1.
- **Motor real (N4):** `tool/anilili_live_player_app.dart` con
  `KONGROO_LIVE_SEEK=20` — gates RESOLVED → PLAY → SEEK-RESTORE → FRAME →
  ADVANCE → (captura) → REOPEN → LIVE-ENGINE-OK. Ejecutado para megaplay,
  megaplay-dub, anizone, animegg, animegg-dub y animeav1.
- **OC-05 (18-11):** la re-verificación de animeav1 y anizone usó el seek
  **dentro** de la reproducción (`SEEK-IN-PLAY 20000 ms`), no
  `KONGROO_LIVE_SEEK`: en ese HLS, `restoreStartPosition` antes de `play` falla
  con `PlaybackResumeFailure` porque la duración aún no está disponible.
- **Sondas N2 sin motor:** `tool/allanime_live_check.dart`,
  `tool/anizone_live_check.dart`, `tool/animeav1_live_check.dart`,
  `tool/voe_resolver_probe.dart`, `tool/animegg_timing_probe.dart`.
- **Analyze:** `flutter analyze` sin hallazgos.
- **Evidencia local:** capturas `.ai-local/anilili-live/*.png` (1920×1080).

---

## 7. Guía para futuros desarrolladores

- **Agregar un proveedor:** crea `app/lib/data/player/providers/<name>/`
  con una clase que extienda `EpisodeSourceAdapter`; implementa
  `searchAnime`, `listEpisodes`/`findEpisode` (puede ser lazy:
  unsupported + episodio sintético verificado en fuentes) y
  `findEpisodeSources`. Declara `episodeSources`; añade
  `sourceAlternatives` **solo si devuelves >1 servidor por fuente** (la
  validación del manager lo exige). **No copies los helpers privados**:
  usa `EpisodeSourceSupport.read/check/contractTitle` para el mapeo de
  resultados, la cancelación y la normalización conservadora de títulos.
  Regístralo en `playback_providers_module.dart` con prioridad y toggle
  de entorno.
- **Registrar un resolver:** implementa `PlaybackVideoHostResolver`
  (`resolverId`, `hostId`, `supports`, `resolve`) y añádelo a
  `videoHostResolvers` del módulo. El manager valida que el stream
  resuelto echoe `providerId/sourceId/serverId`.
- **Reutilizar un resolver:** los candidatos con
  `hostId: DirectMediaHostResolver.stableHostId` y `kind: media` pasan por
  el normalizador directo; los embeds de VOE con `hostId: 'voe'`.
- **Variantes sub/dub:** patrón de Anilili/ani-cli — un solo adaptador con
  `enum XAudioVariant` y dos registros (`id` distinto por variante); el
  idioma anunciado viaja en `providerAnnouncedLanguage`.
- **Ejecutar pruebas:** `flutter test test/data/player/providers/` (unitarias
  de proveedores), `flutter test` (suite completa) y las verificaciones de
  motor con el arnés paramétrico (un proveedor por ejecución).
- **Diagnosticar reproducción:** 1) live check sin motor para discovery;
  2) arnés con motor para frame/advance; 3) `manager.diagnostics` (el arnés
  los imprime: circuit, failures, lastFailure por proveedor);
  4) capturas con `KONGROO_LIVE_SHOT`.
- **Evitar duplicaciones:** un host ya resuelto por un resolver existente
  NO se vuelve a resolver (2Dhive embebe MegaPlay ⇒ no se crea proveedor
  duplicado; se portó su ruta MAL al proveedor existente).
- **Contratos que no deben romperse:** `EpisodeSourceAdapter`
  (semántica de `findSources`), validación `_validateSources`
  (`sourceAlternatives` para multi-servidor), `PlaybackRequestHeaders`
  (solo cabeceras públicas validadas), presupuestos de `PublicPlaybackHttp`
  (6 s/petición, límites de cuerpo, Retry-After), motor único media_kit.

---

## 8. Trabajo pendiente

| Pendiente | Causa | Evidencia |
|---|---|---|
| miruro-catalog sin fuentes | **Bloqueo WAF** (no challenge) en las rutas de API; el sitio y su API responden 200 dentro de un navegador real. Anilili usa WebView + clearance, prohibido por política; `flutter_inappwebview`/`webview_flutter` no soportan Linux | Página «Attention Required», sin `cf-mitigated`, Ray IDs `a5c7f02c7926ca5c-ATL`/`a5c7f051ae3006f2-ATL`, 2026-11-18; API 200 en navegador. Requiere excepción WAF o acceso oficial del operador |
| allanime reproducción N4 | `NEED_CAPTCHA` es **lógica del origen** (Turnstile del sitio, token de un solo uso/300 s), no un challenge de Cloudflare; el `POST /api` responde JSON normal | Bundle `aa-chunk.js` (build 190) con `turnstile.render`/`_solveCaptcha`/reintento `{token, provider}`; sonda `last=challenge` |
| Materiales por build de AllAnime | La máscara rota por build del sitio (190 hoy) | `invalid_boot_token` simulado en regresión |
| Hosts MP4Upload/YourUpload de AnimeAV1 | Sin resolutores activos (históricamente 403/500) | OC-03.2 |
| Varianza de red AnimeGG | GETs fríos ~5-7 s vs presupuesto de 6 s (IPv6 4,4 s vs v4 1,9 s) | `animegg_timing_probe.dart` 3/3 OK sin motor |
| Cola de `resolveCandidates` | `animegg-dub` agota el timeout de 6 s por petición en 2 de 3 rondas y domina los ~13 s restantes | probe OC-05: `last=timeout` y streams ausentes en esas rondas |
| Captions suaves de VOE | El único episodio inspeccionado no publica ninguna; el parser queda probado con fixtures, **NO VERIFICADO contra un caption real** | `captions: []` en el config de ep. 9; sin `EXT-X-MEDIA` en el master |
| Subtítulos externos en la ruta de proveedor | Cableado (`OPENSUBTITLES_API_KEY` → `ExternalSubtitleService`); sin clave el panel no ofrece búsqueda | `provider_playback_route.dart` + `catalog_home_page.dart`; pruebas del servicio existentes |
| Android | No validado | — |

La disponibilidad de hosts externos puede cambiar en cualquier momento; las
pruebas reproducibles y la clasificación honesta de fallos son la garantía
del sistema.
