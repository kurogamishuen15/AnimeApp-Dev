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
| megaplay | 110 | N4 verificado | Revalidado con motor; seek 20 s previo a reproducción | **N5** | — | Conservado; fallback MAL añadido el 17-11 |
| megaplay-dub | 105 | N4 verificado | Revalidado con motor (variante dub propia) | **N5** | — | Conservado |
| miruro-catalog | 100 | 403 Cloudflare | Bloqueo externo re-verificado (REST y pipe, 4 orígenes) | **N0 externo** | WAF de Cloudflare en todas las rutas de API | Sin evasión por política; evidencia documentada |
| animeav1 | 95 | `missingId`; sin cuadros | **Motor verificado vía VOE** | **N4** | `invalidResponse` sistemático en el manager (validación multi-servidor) | Añadida capacidad `sourceAlternatives` + regresión por manager |
| allanime | 92 | `aaReq` bloqueaba fuentes | **Protocolo client-crypto completo implementado y verificado en vivo** (bootstrap→aaReq→tobeparsed→medio 206) | **N2 protocolo** | `NEED_CAPTCHA` tras la investigación intensiva | Clasificado `challenge` (sin evasión); evidencia previa de descifrado real |
| allanime-dub | 91 | ídem | Verificado junto a sub (variante dub con su propio MP4) | **N2 protocolo** | ídem | ídem |
| anizone | 86 | N4 verificado | Revalidado con motor (HLS 360/720/1080, audio ja/en) | **N5** | — | Conservado |
| animegg | 84 | N4 verificado | Revalidado con motor (MP4 espejo 227251) | **N5** | Throttling por UA (28 KB/s) | UA de navegador en candidatos (A/B documentado) |
| animegg-dub | 83 | N4 verificado | Revalidado con motor (MP4 espejo dub 226001) | **N5** | — | Conservado |

**Operativos con video real hoy:** megaplay, megaplay-dub, animeav1 (VOE),
anizone, animegg, animegg-dub (6 de 9). **Protocolo verificado sin ventana de
reproducción:** allanime, allanime-dub. **Bloqueo externo demostrado:**
miruro-catalog.

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
- **Hosts:** `www.miruro.{to,tv,bz,cx,ru}` — **bloqueo Cloudflare en
  `/api/v1/...` y `/api/secure/pipe`** (verificado 2026-11-18 con
  `cf-mitigated: challenge` en los cuatro orígenes; la página estática
  responde 200, la API 403). Anilili resuelve esto con un WebView real y
  clearance de navegador; la política del proyecto lo prohíbe.
- **Pruebas:** heredadas (32 de providers al cierre OC-04).
- **Estado:** N0 externo, pendiente de autorización del operador del origen.

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

## 5. Matriz de servidores

| Host | Tipo | Usado por | Estado |
|---|---|---|---|
| `megaplay.buzz` | Host API+embed | megaplay, megaplay-dub (2Dhive también lo embebe vía ruta MAL) | ✅ operativo |
| `fetch.nexabloom.top` | CDN HLS | megaplay/-dub | ✅ operativo |
| `www.miruro.{to,bz,cx,ru,tv}` | Host API | miruro-catalog | ⛔ Cloudflare |
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
- **Unitarias/manager:** `flutter test` suite completa — ver el cierre de
  esta misión para el recuento final (387 aprobadas/10 omitidas antes de
  añadir las pruebas nuevas de esta fase; todas en verde).
- **Motor real (N4):** `tool/anilili_live_player_app.dart` con
  `KONGROO_LIVE_SEEK=20` — gates RESOLVED → PLAY → SEEK-RESTORE → FRAME →
  ADVANCE → (captura) → REOPEN → LIVE-ENGINE-OK. Ejecutado para megaplay,
  megaplay-dub, anizone, animegg, animegg-dub y animeav1.
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
| miruro-catalog sin fuentes | Cloudflare WAF en todas las rutas de API (REST y pipe); Anilili usa WebView real, prohibido por política | curl con `cf-mitigated: challenge`, 4 orígenes, 2026-11-18 |
| allanime reproducción N4 | La API exigió `NEED_CAPTCHA` (Turnstile) tras la investigación intensiva desde esta IP; el protocolo quedó verificado antes con descifrado real y sonda 206 | `AA_CRYPTO_STALE`/`NEED_CAPTCHA` capturados; token boot aceptado; MP4 370 MB |
| Materiales por build de AllAnime | La máscara rota por build del sitio (190 hoy) | `invalid_boot_token` simulado en regresión |
| Hosts MP4Upload/YourUpload de AnimeAV1 | Sin resolutores activos (históricamente 403/500) | OC-03.2 |
| Varianza de red AnimeGG | GETs fríos ~5-7 s vs presupuesto de 6 s (IPv6 4,4 s vs v4 1,9 s) | `animegg_timing_probe.dart` 3/3 OK sin motor |
| Android | No validado | — |

La disponibilidad de hosts externos puede cambiar en cualquier momento; las
pruebas reproducibles y la clasificación honesta de fallos son la garantía
del sistema.
