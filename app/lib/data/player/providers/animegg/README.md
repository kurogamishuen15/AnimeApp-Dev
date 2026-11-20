# AnimeGG directo

`AnimeGgPlaybackProvider` adapta el sitio público de AnimeGG
(`www.animegg.org`) a `EpisodeSourceAdapter` + `DirectMediaHostResolver`,
siguiendo el flujo `AnivexaClient.animegg` de Anilili (MIT-0), actualizado al
marcado actual: título en `<h2>` dentro del ancla `mse`, filas `anm_det_pop`
con el número de episodio en el texto `strong`, y pestañas
`data-toggle="tab"` con `data-version="subbed|dubbed"` cuyos documentos
`/embed/{data-id}` publican playlists HLS y MP4 progresivos jwplayer
(`/play/{id}/video.mp4?for=...`). Los embeds que no exponen medio directo no
se devuelven como reproducibles.

- **Registro:** variantes `animegg` (sub, prioridad 84) y `animegg-dub`
  (dub, 83); `KONGROO_ENABLE_ANIMEGG=0` las desactiva.
- **Identidad:** título exacto normalizado (`exactTitle`); nunca fuzzy.
- **Fuentes:** MP4 progresivos (redirección 302 del sitio al CDN
  `vidcache.net`, que libmpv sigue por sí mismo) y HLS del embed.
- **Cabeceras de medio:** Referer del sitio + User-Agent propio de Kongroo.
  El A/B histórico observó ~28 KB/s con `libavformat` y ~176 KB/s con UA de
  Chrome, pero el perfil de Chrome se retiró el 2026-11-19 para no suplantar
  identidad de navegador. Ese A/B no demuestra rendimiento del transporte
  actual.
- **Transporte:** `PublicPlaybackHttp` con allowlist `{www.animegg.org}`,
  presupuestos por petición, cancelación y Retry-After.
- **Pruebas:** 8 casos (MP4 por el manager, dub con su propio `data-id`,
  HLS del embed, episodio ausente → `noEpisodes`, sin coincidencia → vacío,
  embed sin medio → `noSources`, 403 → forbidden, cancelación).

## Estado live (2026-11-17)

- **N3/N4 históricos con el motor real** (`tool/anilili_live_player_app.dart`):
  Tokyo Ghoul:re 9 → RESOLVED 7 streams (megaplay×2, anizone, animegg×2,
  animegg-dub×2) → PLAY MP4 → primer fotograma remoto con openh264 →
  ADVANCE 2002 ms → SEEK-IN-PLAY 20000 ms → captura
  `.ai-local/anilili-live/animegg-tokyo-ghoul-re-9.png` → REOPEN →
  `LIVE-ENGINE-OK provider=animegg`.
- **Reanudación pre-apertura histórica (2026-11-18):** con el UA de
  navegador entonces usado en el candidato, `restoreStartPosition(20 s)` sobre el MP4
  progresivo responde `SEEK-RESTORE confirmed: 20000 ms` → primer fotograma →
  ADVANCE desde 20 s. El `PlaybackResumeFailure` original tenía la misma causa
  raíz que el 429/UA de Wikimedia (OC-03.1): el CDN servía al cliente de
  biblioteca a ~28 KB/s y mpv no terminaba de sondear el archivo dentro del
  presupuesto de reanudación. Sin cambios en el coordinador.

Procedencia: port de `AnivexaClient.animegg` (Anilili, MIT-0) con la forma
live del marcado reproducida en pruebas.

## Estado actual del transporte (2026-11-19)

Los candidatos ahora llevan `Kongroo/0.1 (public anime catalog client)`. Las
pruebas con fakes confirman el contrato de identidad; no se ha vuelto a medir
el CDN real bajo ese identificador. La reproducción histórica no acredita que
la velocidad o la reanudación sigan siendo utilizables después de retirar el
UA de Chrome.
