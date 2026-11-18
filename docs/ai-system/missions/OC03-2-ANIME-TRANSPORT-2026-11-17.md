# OC-03.2 · Transporte de AnimeAV1 y TioAnime

17 de noviembre de 2026, Bogotá. El anexo revisado es el alcance vigente.
Este checkpoint distingue descubrimiento, respuesta de sonda y vídeo visible.

## P0 · Resultado de red

| Flujo | Catálogo, ficha, episodio y embed | Medio | Estado |
|---|---|---|---|
| AnimeAV1 · One Piece 1 → MP4Upload | Los cuatro GET dieron 200 | HEAD a `a4.mp4upload.com:183` dio 403 HTML, `Server: nginx` | Resuelto, acceso denegado a la sonda |
| TioAnime · Naruto 1 → YourUpload | Los cuatro GET dieron 200 | `vidcache.net:8161` dio 500 JSON a HEAD y GET con Range 0–31 | Resuelto, fallo HTTP en el CDN |
| TioAnime · Naruto 1 → segunda alternativa YourUpload | Embed dio 200 | La declaración no identificó un MP4 en un CDN permitido | Sin medio admitido |
| AnimeAV1 · HLS Zilla | Embed dio 403 con servidor Cloudflare | Sin manifiesto | Denegación sin indicador de desafío |
| AnimeAV1 · VOE y Byse | Embeds dieron 200 | Sin declaración MP4 ni etiqueta fuente en la sonda estática | Candidatos sin resolver |
| TioAnime · StreamSB | Agotó el plazo | Sin medio | Acceso sin confirmar |
| TioAnime · OK.ru y Netu | Embeds dieron 200 | Sin MP4 estático en las sondas | Candidatos sin resolver |

Los dos CDN prioritarios respondieron a HTTPS sin redirección, `Retry-After`
ni `cf-mitigated`. La respuesta MP4Upload no tenía Ray ID. El CDN de
YourUpload no identificó servidor. La primera sonda YourUpload dio 500 y
la lectura acotada dio el mismo código y MIME. TioAnime emitió cookies en
sus páginas. El embed y CDN no anunciaron una sesión autorizada para el
cliente de reproducción. Los ensayos usaron peticiones ordinarias y no
transfirieron cookies.

Hay evidencia de qué solicitud falla. El 403 no revela la regla concreta
del sitio ni confirma hotlinking, JA3/JA4, caducidad o bloqueo de IP. El FAQ
de MP4Upload prohíbe enlaces directos de ese tipo. YourUpload documenta
enlaces personales y su player embebido. El JSON 500 no permitió atribuir
la causa interna ni demostrar un requisito de Referer. Se conservaron
ambos conectores experimentales. Los MP4 rechazados por el CDN se retiraron
del selector para esos intentos y no se enviaron a libmpv.

## Implementación

- Las sondas de los dos perfiles usan HEAD con MIME MP4 admitido. Admiten
  una redirección del mismo origen y puerto a un MP4 dentro del perfil.
  Normalizan URLs relativas frente al embed antes de aplicar la allowlist.
  Se rechaza una fuente con expiración declarada vencida.
- El resolver entrega al motor el mismo User-Agent por medio que envía al
  CDN en HEAD. Los perfiles experimentales carecen de cookies, Origin,
  Referer y Authorization por falta de requisitos autorizados demostrados.
  El contrato admite un Referer público por medio cuando existe ese permiso.
- Los errores distinguen catálogo, ficha, episodio, embed y medio. El manager
  preserva una respuesta HTTP concreta aunque una alternativa posterior no
  se pueda resolver. Respeta Retry-After por origen, distingue desafío,
  regla 1020 y bloqueo de IP 1006. Los errores nativos conservan el código
  HTTP explícito cuando media_kit lo expone y se mantienen tras Play/Stop→Play.
- Kongroo verifica el medio antes de presentar el selector. Cuando el CDN
  rechaza la sonda, la ficha informa el código. La prueba de reproducción
  visible se mantiene como comprobación aparte.
- Pruebas con HTTP local cubren MIME falso en 200, 403, desafío, 1006,
  Retry-After, 500, redirección del mismo origen, rechazo de cambio de
  origen, ausencia de fuga de cookies, UA de CDN, expiración y cancelación.
  El smoke de libmpv cubre una playlist y segmento relativos válidos, y
  el fallo de segmento 403 con playlist 200. La prueba de cambio de medio
  conserva las cabeceras correctas y borra el contexto del medio anterior.

## Evidencia

`.ai-local/oc03-2/final-hosts.log`, `yourupload-method.log`,
`alternate-embed.log`, `expanded-transport.log`, `final-full.log`,
`clean-analyze.log`, `hls-specific.log`. Los artefactos omiten URLs completas
y datos de sesión. La prueba gráfica anterior al anexo revisado guardó
`episode:1` a 34.067 ms y reanudó vía Inicio en la aplicación de producto,
con cambio 480p→240p y diferencia de 0 ms. Se conserva como evidencia de
Wikimedia. No se usó esa película como resultado de los dos hosts de anime.

## Prueba gráfica de esta revisión

Después de la suite interna y los ocho casos focalizados se usó el mouse
en Kongroo release, en Fedora con un XWayland anidado y base de datos aislada.
Desde Inicio se abrió One Piece y se pulsó el episodio 1. La ficha mostró
«El servidor del vídeo denegó el acceso (HTTP 403)». En una segunda
ejecución se buscó Naruto, se eligió el resultado de 2002 y se pulsó el
episodio 1. La ficha mostró HTTP 500 y permitió regresar a la búsqueda.
Los candidatos rechazados no abrieron la superficie nativa. Artefactos
`.ai-local/oc03-2/mp4-toast-summary.png`,
`yu-toast-summary.png` y `tio-return.png`.

## Opciones pendientes

Mega y las alternativas internas de TioAnime se observaron en el índice.
FileStream, Bee, Goma File Stream, Filemoon, StreamWish y Streamtape
no se confirmaron como rutas útiles de estos episodios. Para promover
un host queda pendiente verificar una ruta de reproducción permitida,
fijar su procedencia y probar cuadros dentro de la app. El control local
HLS no cubre claves, inicializaciones, DRM ni audio/subtítulos alternativos.

P2P queda como propuesta de módulo independiente para contenido autorizado.
Requiere decisión sobre política de redistribución, presupuesto de
almacenamiento y evaluación por plataforma. Se conserva media_kit/libmpv
como motor único. No se agregaron dependencias ni servicios.

## Fuentes primarias

- [FAQ de MP4Upload](https://www.mp4upload.com/faq/) y
  [condiciones](https://www.mp4upload.com/tos/).
- [Condiciones de YourUpload](https://www.yourupload.com/page/terms-of-service).
- Cloudflare documenta [detección de desafíos](https://developers.cloudflare.com/cloudflare-challenges/challenge-types/challenge-pages/detect-response/),
  [1020](https://developers.cloudflare.com/support/troubleshooting/http-status-codes/cloudflare-1xxx-errors/error-1020/),
  [1006](https://developers.cloudflare.com/support/troubleshooting/http-status-codes/cloudflare-1xxx-errors/error-1006/)
  y [JA3/JA4](https://developers.cloudflare.com/bots/additional-configurations/ja3-ja4-fingerprint/).
