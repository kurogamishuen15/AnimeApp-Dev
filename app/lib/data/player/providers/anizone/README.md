# AniZone directo

`AniZonePlaybackProvider` adapta el sitio público de AniZone
(`anizone.to`) a `EpisodeSourceAdapter` + `DirectMediaHostResolver`,
siguiendo el flujo `AnivexaClient.anizone` de Anilili (MIT-0), actualizado al
marcado actual: los resultados de `/anime?search=` y el manifiesto del
reproductor viajan dentro de JSON escapado (`\u0022` para comillas, `\/` para
barras) en atributos `x-data`/`wire:snapshot` y en `kPlayer(JSON.parse('...'))`,
decodificados por `HtmlPlaybackParsers.decodeJsonEscapes` sin ejecutar JS.

- **Registro:** `anizone` (prioridad 86); `KONGROO_ENABLE_ANIZONE=0` lo
  desactiva. Sub únicamente: el manifiesto publicado publica pistas de audio
  (ja/en) que media_kit expone; no se anuncia dub por eso.
- **Identidad:** título exacto normalizado (`exactTitle`); nunca fuzzy. El
  slug (`djivt6wx` para Tokyo Ghoul:re) es el id de origen.
- **Fuentes:** HLS directo del JSON del reproductor (`seiryuu.vid-cdn.xyz`),
  con referencias de la página. Subtítulos: solo pistas `.vtt` (el sitio
  publica `.ass`, fuera del contrato VTT — limitación documentada, no se
  falsean pistas).
- **Transporte:** `PublicPlaybackHttp` con allowlist `{anizone.to}`,
  presupuestos por petición, cancelación y Retry-After.
- **Pruebas:** 6 casos con fixtures que reproducen los escapes de la página
  viva (2026-11-17).

## Estado live (2026-11-17)

- Búsqueda y episodio verificados en vivo; manifiesto `#EXTM3U` con calidades
  360/720/1080 y grupos de audio ja/en, servido con Referer de AniZone.
- **N3/N4 verificados con el motor real** (`tool/anilili_live_player_app.dart`):
  Tokyo Ghoul:re 9 → RESOLVED (megaplay, megaplay-dub, anizone) → SEEK 20000 ms
  → primer fotograma remoto → ADVANCE 24587/1452075 ms → captura
  `.ai-local/anilili-live/anizone-tokyo-ghoul-re-9.png` (1920×1080) → REOPEN →
  `LIVE-ENGINE-OK provider=anizone`.

Procedencia: port de `AnivexaClient.anizone` (Anilili, MIT-0) con la forma
live del marcado reproducida en pruebas.
