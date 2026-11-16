> ARCHIVO HISTÓRICO — Esta página se conserva como registro de un intento anterior; no describe el runtime actual. Los adaptadores y resolutores de este intento fueron retirados en S0-S (2026-11-16). Consulta el [índice vigente](../README.md) y la [línea base/estado S0-S](../../../../missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).

# Video host resolvers

## Estado actual — 2026-11-16

El composition root registra `AnimeHeavenMp4Resolver` desde el módulo
`animeheaven/`. Valida mirrors MP4 exactos de ese provider y está conectado al
manager existente; los tres mirrors publicados para One Piece ep. 1 llegaron a
libmpv, pero mostraron error genérico sin frame, así que no hay playback externo
confirmado.
`MiruroDirectMediaResolver`, `PublicMediaVideoHostResolver` y `PublicSiteHttp`
se retiraron en limpiezas previas. El contrato `PlaybackVideoHostResolver`, el
manager y el source switch siguen disponibles.
El [informe de limpieza posterior](../../../../../../docs/ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md)
registra referencias, cambios y pruebas actuales.

La evidencia histórica, incluidos resultados de los tests retirados y smokes
live, está en la [auditoría de hosts](../../../../../../docs/ai-system/audits/S0-video-host-audit-2026-11-15.md)
y los logs sanitizados en `.ai-local/review/s0-real-playback-2026-11-15/`.

## Historial de resolutores retirados

El contenido siguiente describe el prototipo eliminado; sus clases, allowlist,
pruebas y comandos ya no existen en el código ejecutable.

Este módulo resuelve alternativas de alojamiento de video publicadas por los
proveedores de anime. Los adaptadores de anime descubren títulos, episodios y
alternativas; `PublicMediaVideoHostResolver` obtiene un MP4/HLS público y el
`MediaKitSpikeEngine` existente reproduce la URI. El resolver no crea ni posee
un reproductor.

## Archivos e interfaces

- `public_media_video_host_resolver.dart`: resolución común para endpoints
  directos y enlaces estáticos expuestos por hosts HTTPS conocidos.
- Contrato: `PlaybackVideoHostResolver` en
  `domain/player/providers/playback_provider_contract.dart`.
- Datos: `PlaybackServer` puede incluir un `Referer` público validado. La
  respuesta conserva ese encabezado para el player.
- Transporte HTTP compartido: `PublicSiteHttp`; solo GET ordinarios, redirección
  manual acotada, allowlist de hosts y comprobación de DNS público.

## Hosts observados y límites

Las raíces permitidas incluyen AnimeAV1/Zilla, YourUpload, StreamSB (`embedsb`),
OK.ru, Mega, Netu/HQQ, AnimeGG/vidcache y el CDN vid-cdn observado en AniZone.
El inventario live del 2026-11-15 encontró Mega, StreamSB, YourUpload, OK.ru y
Netu en TioAnime; `vidcache.net` en AnimeGG; `vid-cdn.xyz` en AniZone; y el
embed Zilla de AnimeAV1. FileStream, Bee y Goma no aparecieron en las
alternativas ni páginas revisadas. Eso no prueba que estén ausentes de todos
los episodios. La allowlist permite subdominios de las raíces configuradas y
vuelve a validar cada host de redirección. Un resultado solo prueba que el
endpoint respondió como media; playback se considera confirmado únicamente
después de decodificación de video, primer cuadro y avance en libmpv.

El inventario S0 también contiene los nombres de servidor CatStream
(KickAssAnime), FlixCloud (ReAnime) y MegaPlay (2DHive). CatStream no publicó
una URI/manifiesto estático reconocible en la página observada; la fuente
upstream describe extracción dinámica y firmas/AES en rutas legacy. La fuente
upstream de ReAnime describe extracción de una máscara XOR, solicitudes de
token/stream a `enc-dec.app` y transformación de segmentos en un proxy local.
No se comprobó una ruta directa de FlixCloud que pueda abrirse sin esa
transformación. La fuente previa de 2DHive señala una etapa crypto para
MegaPlay. No se ejecutaron esos pasos ni se agregaron dominios a la allowlist.
Se mantienen como no verificados/investigación pendiente, no como resolutores
operativos.

Los embeds se inspeccionan como HTML estático. No se ejecuta JavaScript ni se
usan cookies, cuentas, desafíos, CAPTCHA, DRM o descifrado propio. Si un host
requiere uno de esos mecanismos, queda `unsupported`/bloqueado con evidencia.
URLs efímeras se resuelven bajo demanda y no se cachean ni se escriben en logs.

## MP4 y HLS

- MP4: un probe `Range: bytes=0-0`; si el host responde 405, 416 o 5xx, se hace
  una sola petición GET sin Range y se cancela el body al confirmar el MIME.
- HLS: GET ordinario sin Range; se lee como máximo 256 KiB, se exige `#EXTM3U`
  y se validan hasta 128 referencias HTTPS, allowlist y DNS. No se descarta un
  manifiesto por una respuesta a Range.
- Los redireccionamientos se limitan a tres por defecto (máximo cinco) y cada
  destino debe seguir permitido y resolver a direcciones públicas.
- Se admite únicamente `Referer` de origen HTTPS público, sin credenciales,
  query ni fragmento. No se transportan cookies ni Authorization.

## Pruebas históricas retiradas

Los resultados deterministas y live se conservan en la auditoría enlazada y en
los logs locales. La suite contenía adaptadores de red y smoke tests opt-in;
ninguno de esos tests se mantiene ejecutable tras retirar el prototipo.

## Evidencia live 2026-11-15

TioAnime publicó los cinco hosts indicados arriba. Con el resolver común:
Mega/OK.ru/Netu no expusieron medio estático (`unsupported`), StreamSB agotó el
timeout y YourUpload acabó con error de red. Una corrida histórica obtuvo URI
de YourUpload, pero libmpv no avanzó. AnimeGG resolvió una URL de `vidcache.net`;
libmpv avanzó 5311 ms y detectó codec de audio, pero no presentó dimensiones de
video. AniZone anunció un HLS en `vid-cdn.xyz`; Range y GET ordinario respondieron
404, y su acción Livewire pública devolvió 419. AnimeAV1/Zilla devolvió
`unauthorized`. Ninguno se declara reproducible. Evidencia consolidada:
[`S0-REAL-PLAYBACK-REPORT.md`](../../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).

Estas pruebas son puntuales y no justifican reintentos automáticos. Una URL
expirada o una respuesta 401/403/404/419 no se reintenta con credenciales ni
medios de evasión.
