# AllAnime directo (protocolo client-crypto de M.Kissa)

`AllAnimePlaybackProvider` adapta la API GraphQL de AllAnime/M.Kissa
(`api.mkissa.net`, Referer/Origin `mkissa.to`) a los contratos de Kongroo.
El acceso a fuentes usa el protocolo público **client-crypto** del propio
cliente web del sitio, verificado en vivo el 2026-11-18:

1. **Bootstrap** `GET /client-crypto/v1/bootstrap?buildId=190&k=k7` con
   cabeceras públicas `x-build-id` y `x-aa-boot` (HMAC-SHA256 doble sobre la
   máscara del build y `host~lane~buildId~group~epoch`). El servidor responde
   con el `epoch` autoritativo y `partB` (base64, 32 bytes).
2. **Clave de petición** = `partB XOR máscara` (materiales del build 190,
   chunk público `B3DA467b.js`: máscara `65c85a...ca35`, prefijo
   `rEVwtVi:190`, hash de consulta
   `670bbf38d0868f446e2346c1e956ca2c40c416e733ca248fd54e04f1c8b99145`,
   carril `k7`).
3. **`aaReq`** = `base64(0x01 ‖ iv ‖ AES-256-GCM(clave, iv, payload))` con
   `payload={v:1, ts:<ventana 5 min>, epoch, buildId, qh, k}` e
   `iv = SHA-256("epoch:buildId:qh:ts:lane")[0:12]`.
4. **Consulta de fuentes** con `extensions={persistedQuery, k:k7, aaReq}` y
   las cabeceras `x-build-id`/`x-aa-boot` (contratos públicos validados en
   `PlaybackRequestHeaders`: numérico y 64-hex).
5. **`tobeparsed`** = `base64(0x01 ‖ iv ‖ ct ‖ tag)` AES-256-GCM con la MISMA
   clave dinámica; su `episode.sourceUrls` entrega medios directos
   (`type:"player"`, p. ej. `Yt-mp4` en `tools.fast4speed.rsvp`) y rutas
   iframe que Kongroo nunca devuelve como reproducibles.

Sin cookies, sin sesiones, sin ejecución de JavaScript remoto; sólo los
materiales públicos del build del sitio, como hacen los clientes mantenidos
(ani-cli/Goanime). La máscara rota por build del sitio: la clase
`AllAnimeBootMaterials` centraliza las constantes y el adaptador clasifica
`invalid_boot_token` como rotación pendiente (`unavailable`).

- **Registro:** variantes `allanime` (sub, 92) y `allanime-dub` (dub, 91);
  `KONGROO_ENABLE_ALLANIME=0` las desactiva.
- **Identidad:** crosswalk `malId` (la API lo entrega como cadena numérica)
  o título exacto normalizado; nunca fuzzy.
- **Transporte:** `PublicPlaybackHttp` con allowlist
  `{api.mkissa.net, allanime.day}` (el relé `clock.json` de rutas internas
  `--` sigue en allanime.day).
- **Pruebas:** 12 casos, incluidas formas live (`AA_CRYPTO_STALE`,
  `NEED_CAPTCHA`, `invalid_boot_token`) y contratos de cabecera.

## Estado live (2026-11-18)

- **Protocolo verificado de extremo a extremo antes de la limitación:** cadena
  completa ejecutada contra la API real (bootstrap → aaReq → tobeparsed
  descifrado → `Yt-mp4` sub y dub → sonda de medio con `206` y 370 MB en
  `tools.fast4speed.rsvp`). Capturas en
  `docs/ai-system/missions/ANILILI-9PROVIDERS-2026-11-18.md`.
- **Limitación por volumen:** tras la investigación (cientos de sondas), la
  API exigió `NEED_CAPTCHA` (Cloudflare Turnstile) para las fuentes desde esta
  IP. Kongroo **no resuelve ni evita desafíos**: clasifica el estado como
  `challenge` (regresión dedicada) y el manager continúa con los demás
  proveedores. El estado decae con el tiempo; la cadena ya quedó acreditada
  con evidencia previa.
- Nivel: **N2 protocolo verificado (con descifrado real) · reproducción
  pendiente de ventana sin captcha**.

Procedencia: flujo del propio cliente web del sitio (chunk público) + el
enfoque de clientes abiertos (ani-cli, MIT; Goanime, MIT) para los materiales
por build; adaptación Dart propia.

