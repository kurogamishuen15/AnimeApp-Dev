> ARCHIVO HISTÓRICO — Esta página se conserva como registro de un intento anterior; no describe el runtime actual. Los adaptadores y resolutores de este intento fueron retirados en S0-S (2026-11-16). Consulta el [índice vigente](../README.md) y la [línea base/estado S0-S](../../../../missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).

# Adaptador de AnimeGG

> **Estado tras la limpieza S0 (2026-11-15): retirado.** El archivo Dart del
> adaptador ya no existe ni está registrado. El resto de esta página conserva
> el diseño y la evidencia histórica de ese intento; no describe código activo.
> No se confirmó reproducción externa. Ver la
> [auditoría de limpieza](../../../../../../docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md)
> y la [auditoría de hosts](../../../../../../docs/ai-system/audits/S0-video-host-audit-2026-11-15.md).

## Propósito y estado

**Registro histórico, no implementación activa.** En el intento del 2026-11-15,
`AnimeGgPlaybackProvider` convertía páginas públicas de AnimeGG en fuentes y
alternativas tipadas, sin crear ni controlar un reproductor. La búsqueda de One
Piece, el episodio 1 y cinco variantes se confirmaron; las resoluciones fallaron
y no se confirmó video. `RESOLVING` era el estado de aquella investigación, no
el estado runtime actual. El adaptador se retiró en la limpieza S0.

## Archivos e interfaces

| Archivo | Responsabilidad | Contratos y dependencias |
|---|---|---|
| `animegg_playback_provider.dart` | Búsqueda exacta, listado del episodio, idiomas, calidades y metadatos del host | `PlaybackSourceProvider`, modelos de `domain/player/providers`, `PublicSiteHttp` y Dio |
| `../video_hosts/public_media_video_host_resolver.dart` | Redirects y validación común MP4/HLS antes de libmpv | `PlaybackVideoHostResolver` |
| `README.md` | Contrato, seguridad, límites, estado y pruebas | Este módulo y la guía de proveedores común |

El composition root `../playback_providers_module.dart` registra el adaptador
con prioridad 10. La selección y el fallback siguen en
`PlaybackProviderManager`/`PlaybackSourceSwitchService`; la reproducción usa el
único `SpikePlayerModule` y media_kit/libmpv existentes.

## Lectura de páginas

El adaptador usa GET HTTPS públicos ordinarios para `/search/`, una ficha
`/series/<slug>`, el enlace de episodio marcado `anm_det_pop`, sus iframes del
mismo dominio y la declaración estática `videoSources` en el HTML del embed.
Solo acepta rutas `.mp4` y `.m3u8` con HTTPS y host AnimeGG. La lista se agrupa
por idioma y calidad; cada alternativa produce un servidor tipado. El límite es
de ocho páginas de episodio y ocho iframes en total por episodio para mantener
acotado el número de solicitudes. Una ficha sin coincidencia exacta o sin
medios devuelve un resultado vacío/no soportado, no una URL inventada.

AnimeGG extrae filas de idioma/calidad como fuentes de reproducción. Estas filas
no son servidores adicionales: para One Piece ep. 1 las URLs observadas parten
de `www.animegg.org` y redirigen a `vidcache.net`/`s188.vidcache.net`. El
resolver compartido verifica MP4 con Range y un GET normal acotado si el host
rechaza Range o devuelve 5xx. Para HLS usa GET normal sin Range y valida el
marcador `#EXTM3U`. Se permiten tres redirecciones por defecto y cada salto
revalida HTTPS, allowlist y DNS público. No se descarga el video completo. La
comprobación DNS reduce riesgo de SSRF, pero no fija la resolución que hará
posteriormente el proceso nativo.

AnimeGG necesita `Referer` para solicitar el medio. El adaptador entrega solo el
origen público `https://www.animegg.org/`. `PlaybackRequestHeaders` valida el
valor y solo admite ese tipo de cabecera: no acepta cookies, autorización,
query ni fragmento. El contexto viaja por el stream resuelto, coordinator,
rollback de cambio de fuente y `Media(httpHeaders: ...)`; Stop→Play conserva la
misma cabecera. Las cabeceras no se copian a otra fuente. La API usada está
documentada por [media_kit 1.2.6](https://pub.dev/packages/media_kit/versions/1.2.6)
y la versión local está fijada en `app/pubspec.lock`.

## Pruebas históricas y evidencia

Los comandos que ejecutaron la suite anterior se registran en la auditoría y el
reporte S0. El test de adaptadores fue retirado con el código y ya no se puede
repetir desde esta ruta. El test genérico del manager y la integración local de
Referer/libmpv se mantienen.

Desde `app/`, la verificación actual incluye:

```bash
flutter test --no-pub test/domain/playback_provider_contract_test.dart
flutter test --no-pub test/application/playback_provider_manager_test.dart
flutter test --no-pub test/player/spike_player_coordinator_test.dart
KONGROO_TEST_HTTP_REFERER=1 flutter test --no-pub \
  test/player/media_kit_spike_integration_test.dart \
  --plain-name 'libmpv preserves a public Referer across open and replay after Stop'
```

La fixture histórica verificaba extracción de idioma/calidad/servidores desde
HTML estático; se retiró junto al adaptador y ya no es una prueba ejecutable.
La integración local usa un servidor HTTP de prueba y libmpv para comprobar que
la cabecera llega al abrir y se conserva tras Stop→Play; no demuestra que un
proveedor externo entregue un video.

La prueba live histórica se ejecutó explícitamente con
`KONGROO_LIVE_ANIMEGG=1` y el nombre exacto del smoke. El corte del 2026-11-15
encontró `subbed/1080p`, `subbed/720p`, `subbed/480p`, `subbed/360p` y
`dubbed/360p` para One Piece episodio 1. Son cinco variantes de fuente, no cinco
tipos de host. Una resolución posterior de la variante preferida llegó a
`vidcache.net`; libmpv avanzó 5311 ms y detectó codec de audio, pero no devolvió
dimensiones de video. No se observó un cuadro ni se considera reproducción
confirmada. El smoke no cuenta las calidades como servidores independientes.
La evidencia live se registra en el informe S0.

## Referencia upstream y licencia

Se revisó como referencia de comportamiento público la
[implementación AnimeGG de Yuzono](https://github.com/yuzono/anime-extensions/blob/master/src/en/animegg/src/eu/kanade/tachiyomi/animeextension/en/animegg/AnimeGG.kt)
y la [licencia del repositorio](https://github.com/yuzono/anime-extensions/blob/master/LICENSE)
(Apache-2.0, según el repositorio consultado el 2026-11-15). Este adaptador
implementa los contratos propios del proyecto; no incorpora código fuente de
esa extensión.
