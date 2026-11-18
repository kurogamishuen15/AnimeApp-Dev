# AnimeAV1: catálogo y candidatos

Adapter estático para `EpisodeSourceAdapter`; no posee motor ni resuelve hosts.
Adapta el protocolo de `AnimeAv1Provider.kt` de Anilili, revisión
`d7b80f1f5b6c3d014317af471a8565749947397d`, licencia MIT No Attribution (MIT-0):
[fuente](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeAv1Provider.kt),
[licencia](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/LICENSE).
Consultado el 2026-11-17; los resolutores VOE/YourUpload/MP4Upload son módulos separados.

## Verificación 2026-11-18

- **Flujo completo en vivo:** búsqueda `catalogo` → crosswalk MAL
  (`tokyo-ghoulre`) → episodio 9 con embeds SUB `voe.sx` + `mp4upload`.
- **VOE resuelto:** `VoeVideoHostResolver` extrae HLS real del embed
  (`ugc-cdn-caching...cloudwindow-route.com/engine/hls2/.../master.m3u8`,
  `#EXTM3U`, 1280×720).
- **Motor verificado (N4):** `LIVE-ENGINE-OK provider=animeav1` con
  SEEK-RESTORE 20 s, FRAME, ADVANCE 20041 ms, captura
  `.ai-local/anilili-live/animeav1-voe-tokyo-ghoul-re-9.png`, REOPEN.
- **Fix crítico:** el adaptador declaraba solo `episodeSources` y la
  validación `_validateSources` del manager rechazaba sus respuestas
  multi-servidor con `invalidResponse` sistemático (invisible a los tests
  que no pasaban por el manager). Añadida `sourceAlternatives` +
  regresión por el manager con un resolver passthrough de contrato.
- **Hosts:** VOE operativo; MP4Upload/YourUpload sin resolutores activos
  (históricamente 403/500); `missingId` sin `idMal` (conservativo).
- DUB latino cuando la página del episodio lo publica; TG:re 9 solo SUB.
La licencia del código no acredita derechos sobre los medios externos.

## Identidad y transporte

Requiere exactamente un ID `myanimelist` válido y al menos un título de consulta.
Busca hasta tres títulos y confirma hasta tres candidatos por `media.malId`;
no usa igualdad ni similitud del título como prueba de identidad.
AniList se conserva en la identidad solicitada, sin inferir equivalencias.
El índice explícito omite fracciones y deduplica enteros positivos.
La página del episodio vuelve a comprobar MAL, índice y número solicitado.

GET públicos mediante `PublicPlaybackHttp`, origen HTTPS configurable, Referer
público, sin cookies, autenticación ni ejecución de JavaScript:

- `/catalogo/__data.json?search=<título>`
- `/media/<slug>/__data.json`
- `/media/<slug>/<n>/__data.json`

El decoder SvelteKit/devalue adapta el upstream con límites de 64 niveles,
100000 expansiones y rechazo de referencias cíclicas o fuera del arreglo.
Errores HTTP conservan su fallo tipado; 403 no genera otro intento del adapter.
Cada operación puede cancelarse. El propietario del Dio cierra el transporte.

## Variantes y hosts

`episode.variants` determina las variantes de ese episodio, sin extrapolar
doblaje del primero a los siguientes. Según la declaración de Anilili:
SUB significa audio `ja`, subtítulos `es` incrustados; DUB significa audio `es`
y `latinSpanish`. Hardsub no crea una pista externa ni un VTT inventado.

Solo se ofrecen embeds HTTPS públicos declarados en `embeds.SUB/DUB`, con
`hostId` `voe`, `yourupload` o `mp4upload`, prioridad 30/20/10 y tipo `embed`.
Los resolutores deben validar sus dominios y responder por el medio final.
Un candidato listado no significa transporte ni reproducción verificados.

La consulta pública del 2026-11-17 confirmó Naruto MAL 20, episodio 1, variantes
SUB/DUB y esas tres familias. Tokyo Ghoul:re MAL 36511, episodio 9, declaró
solo SUB. Son observaciones temporales del catálogo.

## Verificación

Desde `app`: `flutter test --no-pub test/data/player/providers/animeav1_playback_provider_test.dart`.
Fixtures mínimos SvelteKit, sin medios firmados, cubren identidad, variantes,
hosts inválidos/duplicados, cancelación, 403, números inconsistentes y ciclos.
No constituyen prueba de reproducción ni de audio observado.
