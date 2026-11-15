# Proveedores reales desde la ficha — 2026-11-14

Fuente: autorización directa del propietario para providers técnicos públicos.
Fecha: 2026-11-14
Módulo: `app/lib/data/player/providers` + ficha/player.
Estado: adapters e integración añadidos; reproducción real no alcanzada.
Decisión: integración técnica sin aceptar proveedores hasta playback real.
Evidencia: tests Flutter, requests públicos y libmpv en Fedora.

## Cambios

- Implementados adaptadores AnimeAV1 y TioAnime en data, con Dio compartido,
  GET HTTPS acotado, timeouts, cancelación, validación de episode number y
  errores tipados. No usan cookies, JavaScript, CAPTCHA o mecanismos de evasión.
- AnimeAV1 interpreta el payload SvelteKit público, toma el iframe declarado y
  busca solo media directa declarada por HTML. TioAnime busca título exacto,
  confirma episodio contra la página del anime y lee servidores de la página del
  episodio. Solo URL directa `.mp4`/`.m3u8` visible se pasa al engine.
- Registrados en el `PlaybackProviderManager` actual. Ninja queda sin adapter;
  JKAnime y AnimeJara tampoco se registran al no quedar rutas de media ordinarias
  estables/confirmadas.
- La ficha de AniList entrega external ID, títulos alternativos y número. UI ofrece
  selección de servidor y monta el player/libmpv existente. Cambios de servidor
  siguen el `PlaybackSourceSwitchService`; no se crea un segundo Player.
- Se añadió `PlaybackEpisode.externalAnimeId`/`animeTitles` al request key y
  listeners cooperativos al token de cancelación.
- La allowlist HTTPS exacta protege la apertura en coordinator/engine. Revisión
  encontró que una URL temporal renovada puede no pertenecer a esa allowlist; se
  documentó y se mantiene cerrado hasta definir renovación confinada a provider.
- Revisión de `auditor_codigo` detectó IPv4 privada IPv6-mapped aceptada. El
  validador ahora normaliza esos bytes y se añadió un test negativo.

## Evidencia real

- TioAnime respondió con match exacto de `Shingeki no Kyojin`, lista de episodios
  1–25 y cinco servidores para episodio 1. Con libmpv: Mega/OK.ru/Netu no
  entregaron stream directo; StreamSB timeout; YourUpload expuso un MP4 que
  libmpv no pudo abrir/decodificar. Ninguno avanzó la posición.
- AnimeAV1 respondió con catálogo/detalle; la página pública ofreció iframe y
  el GET normal al iframe respondió 403.
- AnimeOnline Ninja respondió 403 después de redirección. JKAnime respondió 200
  al primer GET de búsqueda y 403 al siguiente muestreo normal. El GET de
  AnimeJara `/catalogo/` fue legible, pero el detalle seleccionado expiró en navegador y un GET ordinario posterior
  falló con HTTP error; no se verificaron episodios/servidores.
- No se consiguió reproducción ni revisión manual de la ruta gráfica ficha →
  servidor → video. El live test actual queda intencionalmente rojo cuando
  ninguna URL avanza en libmpv.

## Checks

- Flutter isolated 3.47.9 / Dart 3.13.7: `flutter analyze --no-pub` limpio.
- Full `flutter test --no-pub --reporter compact`: 250 pass / 6 skipped.
- Tras esa regresión: focused provider/domain/manager: 25 pass / 1 live skipped.
- Linux release build: `flutter build linux --release --no-pub`, exit 0 tras el
  hardening IPv4-mapped.
- `scripts/ci.sh`: 40 pruebas IA, análisis Dart/Flutter y 250 Flutter pasan;
  exit 1 por un import `dart:io` prohibido en `app/lib/app/player/spike_player_page.dart`,
  fuera de este cambio.
- Live Fedora con TioAnime + libmpv no pasó reproducción. No se midieron RAM/CPU
  bajo reproducción; el stream nunca llegó a iniciar.
- No commit ni push. No se preparó índice; había cambios concurrentes.

## Pendiente

Encontrar servidor público y compatible que abra realmente en libmpv; recorrer UI
gráficamente en Fedora; repetir full suite/build tras el guard actualizado; medir
RAM/CPU/arranque/reproducción y ciclo prolongado en hardware objetivo; resolver
renovación segura de URLs firmadas; añadir adapter JKAnime/AnimeJara solo si las
rutas ordinarias quedan verificables; registrar episodios reproducidos con
evidencia real. Ver [auditoría](../../ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md).
