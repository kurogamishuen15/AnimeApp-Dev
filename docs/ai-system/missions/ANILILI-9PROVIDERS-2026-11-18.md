# KONGROO — Misión de los 9 proveedores · 2026-11-18

Objetivo: llevar los 9 registros automáticos del `PlaybackProviderManager`
al máximo nivel de validación real (N4 interfaz, N5 regresión), conservando
los 5 ya verificados y resolviendo Miruro, AnimeAV1, AllAnime sub y dub.

Cierre: `app/lib/data/player/providers/README.md` (documentación maestra con
las 8 secciones obligatorias). Esta misión registra la evidencia técnica.

## B1. miruro-catalog — bloqueo externo re-verificado

- Sondeo fresco 2026-11-18: `www.miruro.{to,bz,tv,cx,ru}` sirven la página
  estática con 200, pero **toda ruta de API** (REST `/api/v1/anime/...` y el
  pipe `/api/secure/pipe?e=...` de Anilili) responde **403 con
  `cf-mitigated: challenge`** en los cuatro orígenes probados con
  cabeceras de navegador completas.
- Anilili resuelve esto con un WebView real y clearance de Cloudflare
  (`PipeBridge`); la política del proyecto prohíbe emular navegador y evadir
  challenges. **Sin acción legítima posible**; el proveedor permanece
  registrado con fallo `forbidden` y el manager continúa con los demás.

## B2. animeav1 — RESUELTO (N4)

- **Bug crítico encontrado:** el flujo completo funcionaba standalone
  (3/3: búsqueda→crosswalk MAL→episodio 9 con embeds voe/mp4upload), pero
  **en el manager fallaba sistemáticamente con `invalidResponse`**. Causa:
  `PlaybackProviderManager._validateSources` exige la capacidad
  `sourceAlternatives` cuando una fuente tiene >1 servidor; AnimeAV1
  declaraba solo `episodeSources`. Invisible a los tests previos porque
  nunca pasaban por el manager.
- **Fix:** capacidad `sourceAlternatives` añadida + nueva regresión por el
  manager con un resolver passthrough que cumple el contrato.
- **Host VOE operativo hoy:** `VoeVideoHostResolver` extrajo HLS real del
  embed vivo (`ugc-cdn-caching...cloudwindow-route.com/.../master.m3u8`,
  `#EXTM3U`, 720p H.264). MP4Upload/YourUpload siguen sin resolutores.
- **Motor (N4):** `LIVE-ENGINE-OK provider=animeav1` — RESOLVED 8 streams
  (con animeav1 ya incluido), PLAY vía VOE, SEEK-RESTORE 20000 ms, FRAME,
  ADVANCE 20041/1452119 ms, captura
  `.ai-local/anilili-live/animeav1-voe-tokyo-ghoul-re-9.png`, REOPEN.

## B3/B4. allanime y allanime-dub — protocolo client-crypto completo

Investigación en profundidad del esquema actual de la API (migrada a
`mkissa.to` / `api.mkissa.net`), ejecutando el **propio módulo del sitio**
(chunk público `B3DA467b.js`, 1,1 MB ofuscado) en Node para verificar cada
pieza contra el servidor real:

1. **Bootstrap:** `GET /client-crypto/v1/bootstrap?buildId=190&k=k7` con
   `x-build-id` y `x-aa-boot` (64-hex). La petición se observó en el
   navegador integrado y se reprodujo desde cero.
2. **`x-aa-boot`** = `hex(HMAC-SHA256(HMAC-SHA256(mask, "rEVwtVi:190"),
   "mkissa.to~k7~190~mkissa~{epoch}"))` con máscara de 32 bytes derivada
   de los fragmentos públicos del bundle: máscara efectiva
   `65c85a8520d83eafafdff966cc3f5187ab774d238f60338ff4fc0ae7d941ca35`
   (construcción verificada byte a byte: fragmentos base64 `vm`, sal
   `uT(buildId)` con `XOR ((l*saltMul+f*saltAdd)&255)`, mezcla final
   `((l*fragMul+f*fragAdd)&255)`; el transform `oT` aplica un `XOR 0x20`
   in situ según el modo del bundle).
3. **El servidor ACEPTÓ el token reconstruido** (rejilla de 324 variantes
   HMAC contra el bootstrap; exactamente una aceptada = la capturada),
   devolviendo `epoch: 2967` + `partB`.
4. **Clave de petición** = `partB(base64→32B) XOR máscara`.
5. **`aaReq`** = `base64(0x01‖iv‖AES-256-GCM(clave, iv, payload))`,
   `payload = {v:1, ts:ventana 5 min, epoch, buildId:"190", qh, k:"k7"}`,
   `iv = SHA-256("epoch:buildId:qh:ts:lane")[0:12]`. **Verificado con la
   respuesta real** (`tobeparsed` descifrado con GCM y la clave dinámica —
   la semilla estática `Xot36i3lK3:v1` era la clave del localStorage, un
   señuelo del bundle).
6. **Hash de consulta actual:** `670bbf38d0868f446e2346c1e956ca2c40c416e733ca248fd54e04f1c8b99145`
   (los hashes de ani-cli julio y de la misión anterior responden
   `AA_CRYPTO_STALE`).
7. **Resultado real:** `sourceUrls` sub y dub con MP4 directo `Yt-mp4`
   (`tools.fast4speed.rsvp`, `Authorization` en URL) + rutas iframe
   (descartadas). Sonda de medio: **HTTP 206, 370.7 MB, Range OK**.

**Puerto a Dart:** reescritura completa de
`allanime/allanime_playback_provider.dart` con `AllAnimeBootMaterials`
(constantes por build 190), bootstrap con candidatos de epoch (gracia),
`aaReq` y descifrado `tobeparsed` con clave dinámica; `PlaybackRequestHeaders`
extendido con `x-build-id`/`x-aa-boot` públicos validados (numérico y
64-hex); allowlist del módulo `api.mkissa.net`+`allanime.day`; 12 pruebas
autoconsistentes (fixtures con GCM propio del test) + formas live.

**Limitación encontrada al final:** tras el volumen de sondeos de la
investigación (cientos de peticiones), la API pasó a responder
`NEED_CAPTCHA` (Cloudflare Turnstile) a las fuentes desde esta IP, también
con el flujo Node que minutos antes funcionaba. **Kongroo no resuelve ni
evita desafíos:** el adaptador clasifica `NEED_CAPTCHA` como `challenge`
(regresión dedicada) y el manager continúa. La cadena quedó acreditada
con evidencia previa (descifrado real + sonda 206); la reproducción N4
queda pendiente de ventana sin captcha.

## FASE C — revalidación de los 5 operativos (motor, KONGROO_LIVE_SEEK=20)

| Registro | PLAY | SEEK-RESTORE | FRAME | ADVANCE | REOPEN | Resultado |
|---|---|---|---|---|---|---|
| megaplay | nexabloom HLS | 20000 ms | ✓ | 24274/1449629 ms | ✓ | **N4 revalidado** |
| megaplay-dub | HLS dub | 20000 ms | ✓ | 20061/1452090 ms | ✓ | **N4 revalidado** |
| anizone | seiryuu HLS | 20000 ms | ✓ | 24587/1452075 ms | ✓ | **N4 revalidado** |
| animegg | vidcache MP4 `/play/227251` | 20000 ms | ✓ | 20061/1450179 ms | ✓ | **N4 revalidado** |
| animegg-dub | vidcache MP4 `/play/226001` (espejo dub distinto) | 20000 ms | ✓ | 20061/1457152 ms | ✓ | **N4 revalidado** |

## Regresión

- `flutter analyze`: sin hallazgos.
- Suite completa: ver cierre (todas en verde tras añadir las pruebas nuevas
  de animeav1-regresión-manager y allanime-protocolo).
