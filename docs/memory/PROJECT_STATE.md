# Estado operativo

## Integración de proveedores Anilili · 2026-11-17 (misión ANILILI)

Se integraron y verificaron los proveedores del ZIP de Anilili compatibles con
Flutter/libmpv: **AniZone** y **AnimeGG** nuevos con verificación de motor real
(N4: FRAME/ADVANCE/SEEK/capturas en `.ai-local/anilili-live/`), **AllAnime**
nuevo con búsqueda en vivo (fuentes bloqueadas por el token anti-scraping
`aaReq` que la API añadió en julio 2026 — bloqueo demostrado, no evadido), y
**MegaPlay mejorado** con fallback a la ruta MyAnimeList
(`/stream/mal/{malId}/...`) que el propio 2Dhive embebe hoy. Bloqueos con
evidencia: ReAnime (HLS solo vía flixcloud WASM/WebView), AniNeko y AnimeKai
(hosts caídos), 2Dhive (sin contenido único: cubierto vía MegaPlay), Miruro
(403 heredado). Senshi/AniBD/KickAssAnime/RareAnimes no existen en el ZIP.
Suite: **398 aprobadas / 10 omitidas** (25 pruebas nuevas); analyze sin
hallazgos nuevos (3 infos preexistentes); build Linux debug de `lib/main.dart`
restaurado. Sin commits ni pushes.
Detalle completo y matriz: [misión ANILILI](../ai-system/missions/ANILILI-PROVIDERS-2026-11-17.md).

## Variantes y subtítulos del proveedor · 2026-11-17

MegaPlay registra sub/dub con un único adapter/resolver y transporte compartido
para Retry-After. Se verificó Tokyo Ghoul:re 9 en dub con texto inglés visible y
Attack on Titan 1 (AniList 16498) en sub con Spanish VTT superpuesto. Ambas
ventanas mostraron 1920×1080; seek, progreso y retorno pasaron. El recorrido
español final guardó 68818 ms y valida también un seek hacia atrás.
Los subtítulos publicados viajan por el contrato ProviderSubtitle; los IDs
caducan al cambiar fuente/Stop, y Stop→Play restaura catálogo. AudioLanguage
sigue unknown cuando el servidor no publica ISO; sub/dub son variantes anunciadas.
**Audio español pendiente**: AnimeAV1 declara DUB latino pero su único GET de
catálogo devolvió 403; AnikenTV/Zangetsu/KickAssAnime no aportaron otra ruta ES
verificable. No se reintroducen resolutores experimentales ni se cierran OC-03
ni la petición completa de audio/subtítulos en tres idiomas.
Suite final: **357 aprobadas / 7 omitidas**, incluidas HTTP/HLS/reanudación local.
Análisis limpio y build Linux debug normal de lib/main.dart aprobado.
Evidencia y pruebas finales: [auditoría de idiomas](../ai-system/audits/OC04-LANGUAGES-audit-2026-11-17.md).
Lanzador: `tools/player/run_kongroo_linux.sh --debug --openh264`.
Sin commits, pushes o cambios globales.


## Reproducción real de anime · MegaPlay/bee · 2026-11-17

Tokyo Ghoul:re 9 (AniList 100240) funciona en Kongroo mediante el backend
directo de bee publicado por Anilili como MegaPlay. Se verificó desde main():
búsqueda, ficha, episodios Kitsu, selector, video visible 1920×1080, reanudación,
seek en pausa, progreso SQLite y retorno a la ficha. El último recorrido guardó
143351 ms de 1449629 ms. Las capturas muestran fotogramas diferentes.
El registro conserva Miruro y añade MegaPlay con el resolver directo existente.
Miruro mantiene su 403. Se corrigió un uso de VideoOutput liberado en el
callback GTK mediante una copia generada de la traducción del plugin Linux.
Fedora aporta noopenh264, así que esta reproducción usa el códec Cisco
descargado separadamente dentro del proyecto y elegido por proceso.
Lanzamiento desde la raíz: `tools/player/run_kongroo_linux.sh --debug --openh264`.
Suite final 350 aprobadas y 8 omitidas, análisis limpio y build Linux debug
normal aprobado. No hay commits ni pushes. Otros hosts/plataformas pendientes.
[Auditoría y evidencia](../ai-system/audits/OC04-MEGAPLAY-PLAYBACK-audit-2026-11-17.md)
y [licencias/control del códec](../third-party/PLAYBACK-DEPENDENCIES.md).

## Corrección del catálogo binario de Miruro · 2026-11-17

Se reprodujo y corrigió un P1 en `PublicPlaybackHttp.readBytes`: la
decodificación UTF-8 previa rechazaba el catálogo XOR+gzip. Miruro adjunta
ahora el Referer del origen en cada petición. La prueba del manager recorre
título, configuración y episodio con cuerpos binarios. Pasan 32 pruebas de
providers y el análisis queda limpio con Flutter 3.50.0-0.4.pre del proyecto.
La ejecución posterior del manager real para AniList 100240, episodio 9,
devuelve `forbidden stage=anime status=403` en Miruro. No hay reproducción
de ese episodio. Un auditor independiente verificó la corrección interna.
[Auditoría y evidencia](../ai-system/audits/OC04-BINARY-TRANSPORT-audit-2026-11-17.md).

## Intento de apertura de episodio · 2026-11-17

Se compiló y abrió la build Linux debug actual (`flutter build linux --debug
--no-pub`, exit 0). La ventana arrancó y cargó la ficha de One Piece con 20 de
1410 episodios indexados; la interfaz marcaba las fuentes como no verificadas.
El backend Wayland captura pantalla con Spectacle, pero no ofrece teclado ni
puntero: portal remoto ausente, `ydotool` sin acceso a `/dev/uinput`; el clic de
selección falló por esa limitación. No se alcanzó la ruta de player, no se abrió
capítulo y no se confirmó medio, primer frame ni audio. Capturas locales
ignoradas por Git: `.ai-local/review/kongroo-episode-test.png` (detalle) y
`.ai-local/review/kongroo-episode-test-rebuilt.png` (Home de la build actual).
No se instalaron herramientas ni se alteraron permisos de Fedora. La ventana
principal se cerró antes de ejecutar el runner directo; no queda una ventana
interactiva abierta. El intento de interfaz solo validó compilación/arranque,
no playback.

Después se ejecutó por CLI el módulo real de providers/resolver/player para el
episodio 1 de *Namakura Gatana* (1917), publicado como película completa de
dominio público en Wikimedia Commons. El runner original falló al restaurar seek
antes de play (`PlaybackResumeFailure`). Un runner temporal sin seek resolvió
Wikimedia 480p, `media_kit` informó `Remote frame rendered` y al cabo de 25 s
reportó posición 23.233 s, duración 258.800 s y `error=null`. Esto confirma
primer cuadro y avance del medio remoto en `media_kit/libmpv`, aunque no audio ni
el recorrido visual desde la ficha. La ejecución usó `app/tool/commons_live_player_app.dart`
copiado a `.ai-local/review/commons-live-no-seek.dart`; el archivo temporal está
ignorado por Git y no se modificó código de producto. No es playback de Miruro/
`bee`, cuyo 403 permanece sin resolver. El runner cerró al finalizar.

## OC-04 · alternativa segura ante HTTP 403 · 2026-11-17

La respuesta 403 pública de Miruro no se resolvió: no se conoce la regla exacta
ni hay autorización del servicio para cambiarla. No hubo nuevas solicitudes al
origen ni intentos de variar cookies, identidad de cliente, proxy o challenge.
La ficha ahora consulta los enlaces externos públicos `streamingEpisodes` de
AniList, valida HTTPS sin credenciales y ofrece copiarlos para apertura fuera de
Kongroo. Son páginas externas, nunca fuentes directas entregadas a libmpv. El
manager continúa a otro provider registrado después de una denegación, probado
con un fake; no se afirma que exista un provider alterno real para el anime.

Tests focalizados 47/47, analyze y build Linux debug pasaron. La suite total dio
336 pass/10 skip y dos timeouts de tests nativos del player que pasaron al
repetirse aisladamente. No se modificó el engine. No se verificó AniList live,
el portapapeles manual ni playback del flujo Miruro: 0 fuentes confirmadas para
AniList 100240. Wikimedia mantiene una prueba histórica opt-in para Namakura
Gatana, separada de este fallback. Android/Windows y perfil de rendimiento en
4 GB pendientes. Detalle en
[auditoría OC-04](../ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md).
Sin commit ni push.

Revisión posterior del `Anilili-main.zip` adjunto: `AppDns.kt` usa DoH cuando
el resolver local no contesta o hace sinkhole; eso no explica los 403 HTTP que
Kongroo observó ya conectado a Cloudflare. El adapter Android de Anilili corta
al recibir 4xx; su manejo de Cloudflare aparte usa emulación/reutilización de
clearance de WebView. El desktop configura el mismo principio de parar en 4xx y
documenta huella TLS de navegador. No se portó esa evasión ni se añadieron DNS
o mirrors. Ver el anexo de la [auditoría OC-04](../ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md).

Comparación ampliada de Anilili: el cliente Android de Miruro no instala el
interceptor Cloudflare; sus comentarios registran 200 ordinario en los cinco
mirrors el 2026-10-03, no una prueba del estado actual. El desktop usa `wreq`
con perfil de navegador para Miruro y mantiene fuentes 8 min; Android cachea
respuestas `/play` 2 min. La diferencia de transporte es una hipótesis plausible,
no causa demostrada. El registro de Kongroo no guardó evidencia que permita
clasificar el 403 como CAPTCHA. No repetir probes ni implementar emulación o
clearance; consultar el addendum OC-04 para el análisis completo.

Seguimiento de integración: se cotejaron `MiruroCatalogApi.kt`/`PipeClient.kt`
con `MiruroCatalogApi` y `MiruroCatalogPlaybackProvider` de Kongroo. Los
endpoints, parámetros, payload XOR+gzip, el parseo de fuentes y la conexión al
manager ya están portados; no se encontró una pieza de catálogo Android que falte.
Las pruebas focalizadas actuales pasaron 20/20 (Miruro provider, transporte
HTTP y composición), usando fixtures/fakes; no prueban servicio live. No se
cambió el transporte para transformar el 403 ni se repitió la llamada. Para
reabrir playback hace falta un endpoint/acceso documentado por el operador o un
provider público alternativo. Ver el follow-up de OC-04.

## Snapshot anterior · OC-03 migración del registro a Miruro · 2026-11-17

Se retiraron del runtime los adapters experimentales de AnimeAV1, TioAnime,
AnimeGG, AnimeHeaven, AnimeOnline Ninja, AnimesDigital y los perfiles de
MP4Upload/YourUpload, manteniendo manager, source switch, contratos y engine
media_kit/libmpv. El registro nuevo usa `MiruroCatalogPlaybackProvider` y un
resolver genérico de media directa; Wikimedia y `user_sources` son opt-in.
El código y tests están descritos en `app/lib/data/player/providers/README.md`
y `app/lib/data/player/providers/miruro/README.md`.

Las consultas Miruro ordinarias para AniList 100240 devolvieron HTTP 403 en
dos orígenes antes de episodios o URI multimedia. Los tests fake no cambian ese
resultado: playback externo de anime confirmado 0. Flutter 3.50.0-0.4.pre es el
SDK local aislado usado para análisis y pruebas porque Flutter 3.47.9 tiene el
fallo documentado de `SemanticsRole.slider`; esto no modifica el SDK global.
Linux es la plataforma probada: suite Flutter completa 334 pass/10 opt-in
omitidos, analyze limpio y build debug exitoso. Home mostró primer frame; el
backend Wayland no permitió interacción. Android/Windows, video externo y
recursos en el equipo de 4 GB siguen pendientes. La regresión local del engine
de 20 aperturas midió RSS de 251,928,576 B antes / 396,959,744 B pico tras Stop /
377,868,288 B tras dispose; no es perfilado de app o streaming ni diagnóstico de
fugas. No commit/push.

[Auditoría de migración](../ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md)
y [procedencia/licencia](../third-party/ANILILI-MIT-0.md).

## Snapshot pre-migración · Comparación de Anilili con Kongroo · 2026-11-17

El episodio de referencia fue Tokyo Ghoul:re 9 (AniList 100240), que el
usuario reprodujo en Anilili con `bee`. En el código de escritorio `bee`
es AniKoto a través de Miruro. Kongroo carece de ese registro activo y
los GET directos de configuración e identificación devolvieron HTTP 403
de Cloudflare en dos orígenes de Miruro, antes de obtener el episodio o el
medio. Anilili implementa emulación de Chrome en ese transporte. No se
confirmó qué condición originó la denegación ni que ese episodio se vea
en Kongroo.
[Comparación y pruebas](../ai-system/audits/OC03-ANILILI-BEE-audit-2026-11-17.md).

## Snapshot pre-migración · OC-03 · Limpieza de proveedores · 2026-11-17

Ambas herramientas de AnimesDigital usan el registro de producción y se
retiraron comprobaciones redundantes del adaptador. Los resolutores de
MP4Upload y YourUpload siguen compartiendo una implementación con perfiles
separados. Antes y después de la limpieza, la suite aprobó 348 pruebas y
omitió 10. El análisis quedó limpio. Está pendiente comparar un episodio y
servidor concretos de Anilili con Kongroo.
[Inventario, validación y auditoría](../ai-system/audits/OC03-CLEANUP-audit-2026-11-17.md).

## Snapshot pre-migración · OC-03.2 · Hosts de anime · 2026-11-17

AnimeAV1 y TioAnime alcanzan sus embeds. Los CDN devolvieron 403 para
MP4Upload y 500 para YourUpload (HEAD y Range). Se verificaron los errores
por etapa y se añadieron el HEAD MP4 por perfil, UA compartido por sonda y
medio, Retry-After por origen, aislamiento de cabeceras y preservación del
error al reabrir. Los dos hosts siguen experimentales y sin cuadros visibles.
Wikimedia conserva la validación anterior. HLS local pasó con segmento
relativo y distinguió el 403 de segmento pese a playlist 200.
[Checkpoint](../ai-system/missions/OC03-2-ANIME-TRANSPORT-2026-11-17.md)
y [auditoría](../ai-system/audits/OC03-2-ANIME-TRANSPORT-audit-2026-11-17.md).


## Snapshot histórico · OC-03.1 · Transporte remoto · 2026-11-16

Wikimedia 480p dio HTTP 429 a ffprobe con UA `libmpv` y abrió con el UA de
Kongroo en un A/B controlado. Fedora mostró cuadros remotos de *Namakura
Gatana* desde el módulo de producto en el lanzador de diagnóstico, con seek
confirmado a 20 s. Se verificó el UA en la red local, ausencia de fuga al
cambiar de medio y reutilización de los derivados. La API respeta
Retry-After y el producto registra perfiles de host en datos. MP4Upload
devolvió 403 a HEAD y YourUpload 500, ambos experimentales. La segunda
fuente externa y la prueba integrada de progreso remoto siguen abiertas.
[Checkpoint de transporte](../ai-system/missions/OC03-1-REMOTE-TRANSPORT-2026-11-16.md)
y [auditoría](../ai-system/audits/OC03-1-TRANSPORT-audit-2026-11-16.md).


## Snapshot histórico · OC-03.1 · 2026-11-16

Wikimedia Commons se registra para *Namakura Gatana* (AniList 6654). AnimeAV1
y TioAnime descubren medios mediante los resolutores compartidos de MP4Upload
y YourUpload con pruebas de red aprobadas. Ambos y AnimesDigital se habilitan
por separado. La reanudación requiere confirmación de libmpv y el progreso
se escribe por episodio para identidades locales. En Fedora se recorrió
ficha → episodio Kitsu → selector → player → alternativa → ficha. El video
remoto falló en el motor. Se comprobó HTTP 429 en ffprobe remoto y un cuadro
decodificado con FFmpeg desde la descarga íntegra de control. J5 permanece
parcial. [Checkpoint](../ai-system/missions/OC03-1-EXECUTION-STATUS.md) y
[auditoría](../ai-system/audits/OC03-1-audit-2026-11-16.md).


Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-16
Módulo: núcleo y arquitectura del producto
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: `PROGRESS.md`, F1.1–F1.3 y sesiones enlazadas abajo

## Objetivo y alcance
**Regla permanente del usuario:** los archivos de proyecto solo se inspeccionan y modifican dentro de la raíz Git y sus subcarpetas; no seguir symlinks externos ni explorar archivos personales no autorizados. Los mensajes del chat son instrucciones directas. Los adjuntos enviados expresamente por el propietario pueden leerse en solo lectura desde la ruta que la plataforma proporciona, sin recorrer archivos vecinos. Respetar permisos del sandbox y mantener cambios de código dentro del repositorio.

Preparar memoria, coordinación y ejecución segura únicamente en esta carpeta de Vídeos. El proyecto contiene el scaffold Flutter Linux (F0.4), controles de calidad (F0.5), medición inicial (F0.6), módulos del núcleo F1, catálogo/biblioteca/progreso y un player reutilizable. El runtime actual registra el adaptador de catálogo Miruro y el normalizador `DirectMediaHostResolver`, además del único engine media_kit/libmpv. La auditoría de migración OC-03 retiró las implementaciones previas de proveedores/hosts del registro. Los GET públicos de Miruro para AniList 100240 respondieron 403 antes de episodios o media; no hay reproducción externa de anime confirmada. Las entradas históricas posteriores describen snapshots anteriores y no el registro actual. Linux es la única plataforma probada en este flujo; Android/Windows y el equipo objetivo de 4 GB siguen pendientes. F0.4–F0.6 y demás estados de fase conservan sus condiciones de aceptación.

## Estado

### Snapshot histórico — S0-S limpieza y contratos source-first/host-first — 2026-11-16

Se retiraron del runtime los archivos/test/harness específicos de AnimeHeaven y
se archivaron los READMEs de AnimeHeaven, AnimeAV1, TioAnime, AnimeGG, Miruro,
AnimeOnline Ninja y `video_hosts`. No se modificó `media_kit`, libmpv, la UI ni
las dependencias del player. Domain añade `AnimeIdentity`, match/episodio de
proveedor y el bridge de tres fases `EpisodeSourceAdapter`; application mantiene
un solo manager con registros versionados, cache LRU/TTL y breakers de
descubrimiento por provider y resolución por hostname. Data registra
`AnimesDigitalPlaybackProvider` v1.0.0 y el normalizador compartido
`DirectMediaHostResolver`.

Prueba live: One Piece ep. 1180 encontró una fuente pública HLS. El manifiesto
respondió 200 (4,998 bytes, 142 segmentos) y el primer segmento 200 (67,258
bytes, MPEG-TS). Ep. 1 también entregó manifiesto 200/5,313 bytes y segmento TS
200/69,756 bytes. Ambas capturas de ventana mostraron pantalla negra/error de
decodificación; no se declara reproducción funcional. La ruta de producto está
conectada en código. La secuencia normal espera `Player.open()` antes de montar
superficie; su relación con el fallo visual sigue sin prueba causal.

La prueba de provider AnimesDigital pasó 7/7; la suite Flutter completa más
reciente pasó 300 y omitió 7 casos optativos. Dart analyze y Flutter analyze no reportaron
problemas. Se corrigió el timeout renovado por cada petición: cada operación
comparte ahora 20 s y un test loopback lo verifica. Auditoría independiente
post-fix completada. El build Linux debug, formato, checker/import tests, 40
pruebas Python, `memory.py check` (`[]`) y `git diff --check` pasaron. Linux es
lo único ejercitado; Android/Windows, mpv CLI, reproducción visible, rendimiento
durante streaming y hardware de 4 GB están pendientes. No commit/push. Detalles en
[informe S0-S](../ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

Seguimiento posterior: una corrida `KONGROO_LIVE_FFPROBE=1` de ep. 1 observó
rechazo de una referencia HLS `.webp` por `allowed_segment_extensions`. No
prueba que libmpv falle por esa razón ni autoriza ampliar el filtro. La
siguiente petición al provider terminó timeout. No se modificó el engine ni se
cambiaron extensiones permitidas. Los tests offline del diagnóstico pasaron
3/3 y Dart analyze no reportó issues.

### Snapshot histórico — S0-R provider AnimeHeaven live sin frame — 2026-11-16

En ese snapshot, el composition root registraba AnimeHeaven y su resolver MP4, usando el manager,
la ruta y el único engine existentes. La búsqueda pública de One Piece, episodio
1, publicó `cx`, `ct` y `ck`; los tres llegaron a libmpv y mostraron error de
decodificación sin frame. Hay un provider implementado y cero reproducibles;
playback confirmado `0/70`. Capturas locales: `s0r-animeheaven-visible.png`,
`s0r-animeheaven-mirror-switch.png`, `s0-animeheaven-mirror-cx.png` y
`s0-animeheaven-mirror-ck.png`. 13 tests focalizados y 48 pruebas de regresión
de provider/manager/route pasan; también Flutter analyze completo y Dart
analyze focalizado. No se midió rendimiento de este provider. El propietario
respondió «Autorizar manualmente en KDE»; después, una captura no mostró el
diálogo y Wayland MCP siguió con `Transport closed`. Los mirrors se seleccionaron
por entorno, sin simular entrada. Ver [informe S0](../ai-system/missions/S0-REAL-PLAYBACK-REPORT.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md). No commit ni
push. Estos tres intentos no agotan el inventario de candidatos: la auditoría
de Anivexa enumera 28 y solo probó AniChan, AniPM y Zoko. La siguiente revisión
posible es estática y selectiva; un GET ordinario solo procede para un host
distinto con ruta pública que no dependa de controles excluidos.

### Snapshot previo a AnimeHeaven — S0-R Gate 1 review — 2026-11-16

Gate 0 permanece parcial y documentado en
[S0R-BASELINE](../ai-system/missions/S0R-BASELINE.md). Gate 1 revisó
referencias de Anilili Android/Desktop, Aimi y clientes CLI, incluyendo commits,
licencias, formatos, idiomas declarados y límites de acceso. Seis probes GET
previos dieron 403. AniWorld permitió búsqueda, ficha y episodio públicos, pero
los cuatro hosters observados no entregaron una fuente: tres dieron 403 y VOE
publicó una redirección JavaScript con lectura opcional de `localStorage`, sin
exponer media estática; no se siguió el destino. No se copió código ni se
automatizó el estado del navegador. No hay providers externos registrados ni
reproducción externa; el resultado permanece 0/70. Ver
[S0R-REFERENCE-REVIEW](../ai-system/missions/S0R-REFERENCE-REVIEW-2026-11-16.md),
STATUS y HANDOFF. La siguiente acción es evaluar una fuente independiente aún
no probada mediante protocolo público ordinario, después de revisar su licencia.
En este snapshot todavía no había cambios de código; la ejecución posterior
de AnimeHeaven se registra arriba. No hubo commit ni push.

### S0-R — Gate 0 baseline (snapshot previo a Gate 1) — 2026-11-16

La misión S0-R del propietario está activa. El Gate 0 quedó parcial: el
reproductor libmpv pasó sus pruebas locales y la demo sintética se vio en
Wayland, sin playback externo (`0/70`). En release, con un recurso local
480×270/24 fps de archivo, el proceso midió RSS 245,708–258,440 KiB y CPU media
28.84% de un núcleo durante 8 s. El host tiene 7.5 GiB, no es el equipo de 4 GB;
media_kit reportó render por software, por lo que FPS presentado y fugas siguen
sin validarse. La suite actual pasó con 268 Flutter y 40 Python; ver
[`S0R-BASELINE`](../ai-system/missions/S0R-BASELINE.md),
[`STATUS`](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[`HANDOFF`](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md). Siguiente
acción: Gate 1 con inspección de upstream oficial y selección de una integración
de bajo riesgo. El checkout `main` ya estaba sucio; ningún cambio anterior se
restauró ni se hizo commit/push.

### S0 — limpieza posterior a S0-A — 2026-11-15

Se eliminaron los archivos Dart de runtime de Miruro y sus registros; el
composition root conserva un `PlaybackProviderManager` vacío. Se archivaron
las fuentes de sus pruebas como `.dart.txt` no ejecutable. No se obtuvo media ni
se confirmó reproducción externa; S0 continúa incompleta, `0/70`. Los contratos,
manager, `PlaybackSourceSwitchService`, reproductor media_kit/libmpv, fakes y
documentación histórica se conservaron. No se tocaron componentes ajenos al
alcance. Pasaron 24 tests focalizados, la suite Flutter completa (268 pass, 6
optativas omitidas), analyze Dart/Flutter, checker de imports, 40 tests Python,
formato, memoria y diff check. Ver [auditoría](../ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

### Registro histórico — S0-A, port de Anilili/Miruro — 2026-11-15

Se implementó `MiruroPlaybackProvider` para mapear AniList ID, episodio y
alternativas del catálogo, junto con `MiruroDirectMediaResolver` para fuentes
directas HTTPS HLS/MP4. Ambos usan el manager y `PlaybackEngine` existentes; no
se agregó player paralelo. El cliente Dio limita bytes, tiempos, redirects y
cancelación. El resolver bloquea rangos DNS no globales, incluye prefijos IPv6
especiales conforme al registro IANA y conserva el riesgo DNS TOCTOU porque
libmpv resuelve el host más tarde.

Miruro `/api/config` y lookup AniList devolvieron HTTP 403 en GET ordinario. No
se usaron mirrors, cookies, perfil de navegador ni challenge. No hubo episodio,
URI reproducible, prueba gráfica Wayland o medida de recursos del provider.
Anivexa no se integra aún. Estado S0 incompleto, playback externo `0/70`.
CI actual con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislado: 40 Python y 288
Flutter pasan, 7 optativas omitidas; analyze, formato, checker y memoria pasan.
El build Linux release del app también pasó.
Ver [informe S0-A](../ai-system/missions/S0-ANILILI-PORT-REPORT.md),
[auditoría](../ai-system/audits/S0-ANILILI-port-audit-2026-11-15.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

### Snapshot histórico S0 — limpieza previa de providers — 2026-11-15

S0 permanece incompleta y la implementación externa está en pausa hasta el
siguiente prompt del propietario. El estado formal de Bloque A/T03/G1 continúa
`AUDITING` hasta aceptación propietaria. El inventario histórico tiene 22
candidatos, pero no hay providers externos ni resolutores concretos registrados
en el runtime. La limpieza retiró los adaptadores AnimeAV1/TioAnime/AnimeGG,
`PublicSiteHttp` y `PublicMediaVideoHostResolver`; se conservan los contratos,
manager, circuit breakers, source switch, fakes y el `PlaybackEngine` existente.
La meta sigue 0/70 y no se verificó playback externo.
AnimeGG/vidcache avanzó 5311 ms y detectó audio, pero no dimensiones de video;
TioAnime recorrió cinco hosts sin fuente reproducible; AniZone devolvió 404 por
Range y GET ordinario, y 419 en la acción Livewire; AnimeAV1/Zilla devolvió
`unauthorized`. FileStream, Bee y Goma no se observaron en las fuentes revisadas,
sin inferir ausencia en todo el catálogo. CatStream no expuso URI estática;
la fuente upstream de FlixCloud muestra token/stream y segmentos XOR por proxy
local, no verificados ni adaptados; MegaPlay conserva una etapa crypto no
ejecutada. Antes de la limpieza, 41 pruebas focalizadas pasaron, 3 smokes live
se omitieron y la integración local Referer/libmpv pasó 1/1. Después de la
limpieza, Flutter analyze y Dart analyze no reportaron issues; la suite Flutter
completa pasó con 267 tests y 6 optativas omitidas usando Flutter 3.50.0-0.4.pre
aislado. No se hicieron requests live durante la limpieza. Ver [informe S0](../ai-system/missions/S0-REAL-PLAYBACK-REPORT.md),
[auditoría de hosts](../ai-system/audits/S0-video-host-audit-2026-11-15.md),
[auditoría S0](../ai-system/audits/S0-provider-audit-2026-11-15.md),
[auditoría de limpieza](../ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

### Reconstrucción Kongroo T00–T03 — 2026-11-15

La reevaluación externa de A-EXT-01–06 concluyó con los criterios técnicos de
Bloque A/G1 pasando; G1 permanece en revisión hasta la aceptación propietaria.
Esta ejecución se detuvo antes de T04/B. Las evidencias están en [STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md),
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md) y la
[auditoría de reevaluación](../ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md).
Con Flutter 3.47.9 aislado, CI pasó: 40 pruebas Python y 269 Flutter; 6 opt-in
omitidas. Flutter/Dart analyze, formato, checker, memoria y diff pasaron. La
revisión externa precedió los fixes; la segunda pasada post-fix fue local y no
independiente. El composition root conserva el único `MediaKitSpikeEngine`/
`VideoController`, y traduce conflicto de lease a un error seguro para la UI.

El SDK original de PATH todavía produce el fallo LSP UTF-8; no fue modificado.
El intento histórico de doble apertura nativa agotó 45 s y sigue sin aprobar.
La prueba libmpv single-owner confirmó reproducción local y rechazo de un
segundo constructor antes de crear otro Player. Los logs originales del
incidente HTTP/timeout y el bundle histórico no están disponibles; A-EXT-03
continúa `UNATTRIBUTED / NOT_REPRODUCED`, con nueva búsqueda de la fuente actual
registrada. El lifecycle nativo completo de `VideoController` carece de prueba
E2E automatizada. No hubo requests live ni reproducción externa: `0/70`. El
propietario había autorizado publicar Bloque A al repositorio privado; esta
reevaluación no hizo commit ni push. T04/B no se considera elegible hasta que
el propietario cierre G1; no se ejecutó aquí.

### Ficha: corrección de fidelidad de cabecera — 2026-11-15

Se corrigió únicamente la composición de la cabecera de la ficha. En ancho
escritorio usa 400 px de alto, carátula 188×300 a 62 px del borde superior,
metadatos y sinopsis dentro del mismo plano cinematográfico; en teléfono usa
350 px, carátula 96×154 a 94 px y sinopsis compacta debajo. Se mantuvieron el
shell, navegación, tabs, iconos, tipografía, contratos y flujo de datos. Las
otras secciones no se modificaron.

Las once rutas temporales de las referencias originales se registraron en
[`docs/ui/ANIME_DETAIL.md`](../ui/ANIME_DETAIL.md), pero sus archivos ya no
existían al verificarlos. Por ello no hay afirmación de coincidencia píxel a
píxel. Analyze focalizado limpio; las pruebas de teléfono 390×844 y escritorio
1280×960 pasan con geometría explícita y sin excepciones; Linux release compila.
Kongroo real quedó abierto en Home sobre
`.ai-local/fase05/detail-fidelity-review.sqlite`. Spectacle capturó la ventana,
pero MCP Wayland no dispone de entrada para abrir una ficha, de modo que la
captura real de la cabecera y la comparación con la referencia siguen
pendientes. Detenerse para revisión manual; no continuar con Episodios,
Información, Reparto, Galería o títulos.

### Historial — proveedores reales de episodios — implementación técnica — 2026-11-14

AnimeAV1 y TioAnime tienen adaptadores reales en `data/player/providers`,
registrados en `PlaybackProviderManager`. La ficha de AniList pasa identidad,
aliases y número del episodio; el selector abre el `SpikePlayerModule` y el
engine media_kit existentes, con resolución por `PlaybackSourceSwitchService`.
No hay un segundo player. Se usan GETs HTTPS ordinarios; no hay cookies,
JavaScript, CAPTCHA ni bypass.

Validación live Fedora: TioAnime devolvió el título exacto, los episodios 1–25 y
cinco servidores para el episodio 1. El intento del MP4 obtenido desde
YourUpload no avanzó posición en libmpv; los otros servidores probados tampoco
produjeron reproducción. AnimeAV1 expuso episodios y un iframe público cuya
resolución respondió 403. AnimeOnline Ninja respondió 403; JKAnime permitió un
GET de búsqueda y luego respondió 403; AnimeJara mostró catálogo pero la apertura del detalle expiró en navegador; un
GET ordinario posterior falló con HTTP error y no confirmó rutas/servidores.
Ninguno queda declarado operativo. La auditoría
histórica es [`PROVIDER-SYSTEM`](../ai-system/audits/PROVIDER-SYSTEM-audit-2026-11-14.md);
la implementación/evidencia de este corte se registra en
[`PROVIDER-IMPLEMENTATION`](../ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md).

Flutter 3.47.9 aislado: `flutter analyze --no-pub` limpio; 25 pruebas
focalizadas, suite completa 250 pass/6 opt-in omitidas y build Linux release
exit 0. La prueba live libmpv sigue fallida por falta de stream reproducible. No
hay reproducción de episodio confirmada ni recorrido gráfico manual de la ficha.
`scripts/ci.sh` también ejecutó las 40 pruebas IA y las 250 Flutter, pero termina
exit 1 por una importación `dart:io` en `app/lib/app/player/spike_player_page.dart`
que el checker de capas prohíbe; es ajena a los archivos de esta integración.

### Ficha: episodios públicos visibles — 2026-11-14

La ausencia de capítulos no era un fallo de autenticación: la pestaña se había
dejado expresamente como placeholder y la consulta exacta descartaba
`streamingEpisodes`. AniList 16498 devolvió sin OAuth 25 episodios con títulos y
miniaturas. El adaptador ahora conserva ese suplemento, lo persiste en la caché
Drift acotada y refresca una vez las fichas creadas antes del nuevo campo. La UI
muestra una cuadrícula lazy: metadatos reales cuando existen y numeración
derivada del total real en los huecos. No trata el sitio externo como fuente de
reproducción. Analyze, 26 pruebas reproducibles, 3 live y build Linux pasan.
La app está abierta sobre la misma base y existe captura del Home; Wayland no
ofrece entrada para llegar a la ficha, por lo que la revisión visual manual
sigue pendiente. Ver [auditoría](../ai-system/audits/F05-episodes-audit-2026-11-14.md).
No avanzar de pantalla ni aceptar fase.

### Fichas públicas sin cuenta — 2026-11-14

El ID ya llegaba desde Home. El lookup por ID omitía SQLite y el resumen de
AniList no incluía reparto ni relaciones. Drift v8 añade caché bajo demanda por
ID con 64 registros y frescura de 24 h. La ficha muestra el registro local
antes de refrescar y Catálogo puede reencontrarlo por título sin red. AniList
responde sin OAuth y la biblioteca conserva su persistencia independiente.
Pruebas focalizadas y límites en [auditoría](../ai-system/audits/F05-detail-offline-audit-2026-11-14.md).
Pendiente revisión manual, sin avanzar de fase.


### Home de Kongroo — revisión manual del propietario — 2026-11-14

Home se basa en browse AniList sin login y conserva la composición aprobada: rail izquierdo, banner amplio y estantes AMOLED. PC aplica hover de imagen 1.035/160 ms sin reflow, overlay de cápsulas translúcidas y clic derecho con menú de escritorio oscuro. Móvil/TV dejan solo tres puntos; TV conserva foco D-pad y restauración al cerrar. El score reutiliza `averageScore` real. El hero avanza cada 6 s por defecto; selección manual reinicia el intervalo y el temporizador se pausa por movimiento reducido, ventana/ruta inactiva o hero fuera del viewport. Las filas admiten gesto táctil, flechas y rueda/trackpad; en los bordes no consumen la señal vertical de la página. Continue watching y Currently watching desaparecen sin datos locales. `Watch now` sigue deshabilitado sin fuente. No se altera el layout.

Validación de esta corrección: `dart analyze lib/app/home test/home` y `flutter analyze lib/app/home test/home` limpios; `flutter test test/home/home_screen_test.dart` 13/13; build Linux release exitoso con Flutter 3.47.9/Dart 3.13.7 aislado. Capturas reales Fedora: `.ai-local/home/home-polish-final-normal.png` y `.ai-local/home/home-polish-final-autoslide-2.png`; muestran estrella vectorial legible y el banner avanzando de Attack on Titan a Demon Slayer. MCP Wayland devolvió `Transport closed`; XTest abrió un consentimiento KDE, no concedido, y no se usó para interactuar. Hover/menú no tienen captura real; widget tests cubren ambos. La app release queda abierta en Home sobre DB aislada `.ai-local/home/home-polish-review.sqlite`. Revisión manual pendiente; no aceptar fase ni avanzar pantalla. Ver [README](../../app/lib/app/home/README.md), [dirección visual](../ui/HOME.md) y [auditoría quirúrgica](../ai-system/audits/F3-home-surgical-adjustment-audit-2026-11-14.md).

### Fase 05.1 — ficha: cabecera y navegación interna — 2026-11-14

Se implementó cabecera AMOLED con banner/carátula, título preferido y romaji, formato, año, score, géneros y emisión usando `ProviderAnimeMetadata`; se retienen romaji y año final ya presentes en `AnimeSummary`. Acciones de biblioteca conservan los seis estados y confirmación de Completed. El CTA de reproducción/descarga queda deshabilitado porque no hay fuente ni contratos de descarga integrados. Tabs de información y títulos alternativos usan metadatos reales; galería muestra solo URLs disponibles; reparto/relaciones/episodios no se fingen. Detail se apila dentro del shell para conservar rail/nav y tiene back de UI y PopScope. No se modificó layout/iconos del Home ni navegación global.

Validación actual: Flutter 3.47.9/Dart 3.13.7 aislado, analyze focalizado limpio; 21 pruebas en `widget_test`, AniList client/cache y mapper pasaron; build Linux release exit 0. La prueba telefónica de 390×844 verifica la pantalla detail aislada; la integración de escritorio confirma ruta dentro del shell y estado/confirmación de biblioteca. App real Fedora carga Home con datos públicos live de AniList y base aislada `.ai-local/fase05/detail-review.sqlite`; captura Home `.ai-local/fase05/fedora-kongroo-home.png`. La captura de detail no se obtuvo: MCP Wayland cerró el transporte; no hay backend de entrada activo. El detalle no tiene inspección visual de compositor y memoria/Android/TV no medidos. Fase 05.1 permanece pendiente de revisión visual del propietario; no iniciar 05.2. Ver [sesión](sessions/2026-11-14-fase05-1-detail.md), [auditoría](../ai-system/audits/F05.1-audit-2026-11-14.md) y [README de detalle](../../app/lib/app/catalog/detail/README.md).

### F2.2 — aceptación formal vigente — 2026-11-10

El propietario aprobó y cerró F2.2. En Fedora verificó manualmente imagen/audio, controles únicos, Play/Pause, Seek, dos Stop → Play con recuperación y cierre normal de ventana/proceso. CI exit 0 (40 pruebas de infraestructura + 99 Flutter), build Linux release del entrypoint spike exit 0. Se conserva el parche UTF-8 local Flutter 3.47.9. Limitación documentada: no hay prueba automatizada end-to-end del lifecycle nativo de `VideoController`. La aceptación cerró F2.2; la autorización separada para F2.3 consta en la sección siguiente. Ver [informe v2](../player/F2.2-spike-report-v2.md), [auditoría Stop → Play](../ai-system/audits/F2.2-stop-play-audit-2026-11-10.md) y evidencias en `.ai-local/f2.2/evidence/`.

### F2.3 — implementación verificada; aceptación pendiente — 2026-11-10

El propietario autorizó F2.3 y luego la operación autónoma F2.3–F2.10. Se reprodujo y corrigió en Fedora KDE Wayland el estado fullscreen obsoleto: GTK confirmaba `fullscreenChanged(true)`, pero el resultado inmediato `false` del método `setFullscreen` llegaba después y revertía el snapshot Dart. `setFullscreen` ahora responde null y solo el evento `window-state-event` actualiza estado; una generación invalida Futures tardíos tras confirmación. Se añadió botón fullscreen con la misma acción que F. Pruebas focalizadas 20/20, CI exit 0 (40 Python + 118 Flutter), Dart/Flutter analyze sin issues y build Linux release del entrypoint `-t lib/main_player_spike.dart` exit 0 con toolchain aislada Flutter 3.47.9/Dart 3.13.7. En el compositor real se observaron F entrar/salir, Escape salir, reproducción con fotogramas cambiantes y cierre GTK desde fullscreen. Audio no se midió por loopback en esta corrida; el foco tras clic no quedó verificado. El auditor independiente revisó secuencialmente el fix y test sin hallazgo pendiente en su alcance; no hizo build/GUI. F2.3 está implementada/verificada, no aceptada. Ver [reevaluación](../ai-system/audits/F2.3-fullscreen-reevaluation-2026-11-10.md), [guía](../../app/lib/app/player/README.md) y [PROGRESS](../../PROGRESS.md).

### F2.4–F2.6 — operación del reproductor — implementación técnica; aceptación pendiente — 2026-11-10

F2.4 ya dispone de snapshot de sesión tipado, estados de apertura/reproducción/cierre, seek ortogonal y generación lógica de fuente; coordinator tests cubren estados, rollback, errores y cleanup. Riesgo abierto para F2.7: `Player.stream.error` solo emite String sin identidad de fuente. La generación de aplicación no añade correlación que el evento nativo no contiene; no se afirma aislamiento completo de error A/B.

F2.5 implementa contratos provider-neutral y gestor de solicitudes deduplicadas con cancelación por caller. Auditoría secuencial confirmó que cancelar un caller no cancela a los demás; cancelar el último elimina la solicitud para permitir una nueva operación, y un Future viejo no borra la nueva entrada. 19 pruebas de contrato/manager; proveedor que no observa cancelación puede seguir trabajando de forma cooperativa.

F2.6 implementa dominio `SubtitleTrackInfo`/`SubtitleStyle`/`HardsubPolicy`, coordinación serializada, adaptador libmpv y controles de pista/estilo/delay. Integración real verifica SRT/ASS internos, `mov_text`, SRT externo, selección/estilos/delay y rechazos. Captura KDE Wayland muestra texto SRT sobre un frame; hubo fallback EGL a software, sin validación gráfica de ASS ni hardware. Auditoría focalizada registró una afirmación falsa sobre pausa en `setSubtitleTrack` como refutada tras inspección del source instalado. Fontconfig sigue emitiendo aviso de caché no escribible. No se automatizó ciclo de vida nativo completo de VideoController.

Los resultados anteriores de CI (40 infraestructura + 150 Flutter) y build Linux release son la línea base del 2026-11-10, antes de los cambios F2.8; no se usan como evidencia de este corte. Ver informes [`F2.5`](../ai-system/audits/F2.5-audit-2026-11-10.md) y [`F2.6`](../ai-system/audits/F2.6-audit-2026-11-10.md), y [estado vivo](../../PROGRESS.md).

### F2.8 — OpenSubtitles — implementación en verificación; aceptación pendiente — 2026-11-11

El contrato domain valida query/IDs/límites, parent IMDb, partes multipart y fallos tipados; el adaptador Dio 5.11.1 consulta API v1 y guarda solo formatos locales con máximo 10 MiB, redirects allowlisted, headers aislados, metadata de cuota y `Retry-After`. Application bloquea hardsub confirmado antes de solicitar descarga, captura excepciones y entrega solo URI `file:` al coordinator. UI y servicio bloquean operaciones de búsqueda/descarga reentrantes. El composition root cierra el cliente HTTP en rollback y lifecycle. La integración HTTP fake → almacenamiento temporal → service/coordinator → libmpv real confirmó que el subtítulo descargado aparece como pista externa seleccionada. En este corte pasaron 24 tests focalizados, 1 integración libmpv, `flutter analyze --no-pub`, build Linux release `-t lib/main_player_spike.dart` y CI completa exit 0 (40 pruebas de infraestructura + 175 Flutter). Auditoría independiente secuencial corrigió A1–A4, R1/R2 y dos hallazgos adicionales de `Retry-After`/concurrencia; la segunda pasada no detectó nuevos defectos en ese alcance. No hay API key/bearer: no se ejecutó API live ni se consumió cuota. El test nativo no demuestra glifos visibles en compositor. Ver [README del adaptador](../../app/lib/data/opensubtitles/README.md), [auditoría F2.8](../ai-system/audits/F2.8-audit-2026-11-11.md) y [PROGRESS](../../PROGRESS.md).

F2.7 conserva como riesgo no resuelto la ausencia de identidad de fuente en `Player.stream.error`; la generación Dart no permite atribuir un error nativo tardío A/B. No afirmar aislamiento de ese evento. F2.3–F2.8 siguen pendientes de aceptación formal; continuar solo trabajo autorizado y sin construir dependencias sobre un comportamiento no verificado. No iniciar F2.11/F3 ni aceptar automáticamente fases.

### F2.7 — error de comando tras cambiar servidor — corrección focalizada 2026-11-12

Se reprodujo el mensaje genérico por una selección de audio abierta antes del cambio de fuente: el ID nativo pertenecía a A, pero el callback tomaba la generación vigente de B y enviaba el par incorrecto al adaptador. El menú ahora lleva `(trackId, sourceGeneration, mediaContextRevision)` y el coordinator incrementa la revisión al solicitar `open`, cambio de fuente o Stop antes de la cola serializada. Widget tests cubren tanto el cambio pendiente detrás de un seek como Stop encolado; se descartan opciones viejas sin operación del motor. Un recorrido libmpv con Morevna a 00:40 comprobó A↔B repetido, Pause→switch→Play, seeks y rollback ante 503 con posición dentro de 2 s. CI 40 Python + 206 Flutter y Linux release específico pasan. Auditoría independiente en dos pasadas: sin P1/P2 restantes en este límite de UI. Sin embargo, no se pudo interactuar con la ventana del escritorio en esta sesión; el control Wayland no tenía backend de puntero/teclado y la captura MCP se agotó. La prueba explica un origen reproducible del mensaje, pero no demuestra que fuera la única causa de la interacción manual reportada. El riesgo separado de `Player.stream.error` sin identidad de fuente continúa abierto; no se cierra globalmente la fase. Ver [auditoría focalizada](../ai-system/audits/F2.7-server-switch-audit-2026-11-12.md), [guía Morevna](../player/demo-morevna.md) y evidencia local `.ai-local/player-demo/evidence/ui/server-switch-*`.

### Protocolo global de auditoría — 2026-11-09

Instalados en la raíz del repositorio los gates de calidad de `AGENTS.md` y la skill `.agents/skills/kongroo-deep-audit/SKILL.md`. Se aplican a todos los módulos y subfases, con informes en `docs/ai-system/audits/`. Las correcciones v2 de F2.2, su matriz de doce hallazgos y la evidencia actual están en el [informe v2](../player/F2.2-spike-report-v2.md). El propietario aceptó después F2.2; la verificación manual y sus límites constan en la nota vigente anterior. La revisión de artefactos/licencias de distribución no se incluye en esta aceptación.

### Integración local de catálogo — 2026-11-09

Flujo mínimo validado en la UI con provider fake sintético offline y Drift schema v6: búsqueda, detalle, alta idempotente, status provisional, progreso F1.10 y recuperación tras cerrar/reabrir SQLite. Suite completa 62 tests, formato/análisis/checker/build Linux y arranque Fedora aislado. No se usó la base personal; binario usa el override `.ai-local/`. No hay provider externo, auth, sync de cuenta ni player. ADR-A14 y estados continúan pendientes de aceptación. Evidencia detallada en [`sesión de integración`](sessions/2026-11-09-catalog-local-integration.md) y [PROGRESS.md](../../PROGRESS.md).

### Context7 para documentación de dependencias — 2026-11-09

Configurado como MCP remoto de solo lectura para documentación de Flutter/Dart y paquetes (por ejemplo, Drift y Dio), limitado a `resolve-library-id` y `query-docs`. No se añadió dependencia ni código MCP a la aplicación. La conexión requiere que Codex cargue la configuración del proyecto; las consultas enviadas al servicio deben limitarse a nombres de bibliotecas y preguntas sin datos privados. Ver [registro MCP](../ai-system/MCP_REGISTRY.md).


### Configuración de agentes — 2026-11-09

Los 21 perfiles `.codex/agents/*.toml` y `.codex/config.toml` ya no fijan modelo ni esfuerzo para subagentes; Codex hereda ambos del chat principal conforme a la precedencia oficial. Se preservaron las instrucciones y funciones específicas. Ver [registro de agentes](../ai-system/AGENT_REGISTRY.md) y [política de tokens](../ai-system/TOKEN_POLICY.md).

Infraestructura de coordinación, memoria Markdown/FTS5 y evaluación documentadas. F0.2 completada: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, rama activa `main`, antigua `ai/setup-autonomous-environment` conservada, `origin` privado verificado y clonación limpia comprobada. F0.1 y F0.3 completas. F0.4–F0.6 siguen parciales. La causa de `flutter analyze` quedó confirmada en Flutter 3.47.9: LSP Content-Length contado en caracteres, no bytes UTF-8. El SDK beta 3.50.0-0.4.pre aislado pasa analyze y CI cuando se selecciona explícitamente, pero no se adopta como solución permanente; stable actual sigue fallando. También se corrigió `analysis_options.yaml` y se migró la UI mínima a `material_ui`. Ver [PROGRESS.md](../../PROGRESS.md), [F0.1 Fedora](../environment/F0.1-FEDORA.md), [TESTING.md](../../TESTING.md) y [sesión](sessions/2026-11-08-flutter-analyze-ci-repair.md). El spike opt-in F2.2 está separado de `AnimeApp` y fue aceptado/cerrado por el propietario el 2026-11-10; lifecycle automatizado de VideoController continúa como limitación de cobertura. Detalle en [informe v2](../player/F2.2-spike-report-v2.md). `AnimeApp-Dev` es privado; `AnimeApp` es público y permanece vacío. Los informes ENVIRONMENT_AUDIT.md y MCP_RESEARCH.md son internos y se excluyen de toda publicación pública salvo aprobación de una versión revisada. Runner aislado sigue sin acreditación de modo nocturno; requiere proveedor y aislamiento reales. Resultados de la infraestructura en [FINAL_REPORT.md](../ai-system/FINAL_REPORT.md).

F1.1 fue aprobada formalmente el 2026-11-08: baseline final 18 FR + 13 NFR, con FR-11 acotado y su definición de negocio por campo pendiente; objetivos de rendimiento son preliminares. F1.2: las 14 selecciones del plan están aprobadas como arquitectura de referencia; validaciones de integración pendientes. F1.3: núcleo Dart compartido, Fedora/Linux primero, adaptadores progresivos; completada documentalmente. F1.4 se completó. F1.5 completó registry/store genéricos; preferencias concretas siguen pendientes. F1.6 Drift/migraciones, F1.7 Result/logger, F1.8 cliente AniList read-only (elegibilidad pendiente), F1.9 secure storage (sin keyring/OAuth real), F1.10 progreso tipado y F1.11 contrato/FakeRemote se detallan en `PROGRESS.md`. F1.12 mantiene evidencia histórica. El catálogo local tiene contratos/UUID/crosswalk, fake sintético y UI mínima funcional sobre Drift schema v6; la suite vigente y los límites constan en `sessions/2026-11-09-catalog-local-integration.md`. ADR-A14 sigue propuesta y sin aceptación formal. F2.2 agrega un spike de reproducción local aislado; no conecta providers externos ni el flujo de producto. F0.4–F0.6 siguen parciales; Flutter stable conserva el fallo LSP Unicode.

## Archivos y comprobaciones
Herramientas en tools/ai, pruebas en tests/ai, políticas en docs/ai-system. Ejecutar index, check y unittest; las métricas de recuperación se registran con evaluate.py.

## Siguiente paso
Siguiente paso: investigar y resolver o acotar con evidencia la correlación de errores nativos tardíos requerida por F2.7 antes de crear comportamientos dependientes en F2.9/F2.10. La documentación instalada de media_kit 1.2.6 confirma que `Player.stream.error` es `Stream<String>` sin identidad de fuente. No afirmar aislamiento A/B solo por generación Dart. F2.8 tiene CI, build y auditoría de este corte completados y está pendiente de aceptación del propietario. La autorización F2.3–F2.10 y rendimiento continúa vigente; ninguna fase salvo F2.2 está formalmente aceptada. No implementar F2.11/F3 ni cerrar automáticamente fases.

### F2.1 — Evaluación multimedia — 2026-11-09

Se evaluó documentalmente `media_kit`/libmpv para Linux y una arquitectura modular con adaptador único. Se recomienda un spike local en F2.2; no se integró el motor ni se probó reproducción. F2.1 requiere revisión de runtime/artefacto y licencias exactas. Ver [evaluación](../architecture/F2.1-player-evaluation.md), [sesión](sessions/2026-11-09-f2-1-player-evaluation.md) y `PROGRESS.md`.

### F2.2 — Spike de reproducción Linux — 2026-11-09

Spike opt-in con `media_kit`/libmpv real. Tras la matriz v2: el slider envía solo el destino final y coalesce pendientes; GTK espera cleanup Dart; el helper genera el fixture sintético ignorado si falta y valida sus tres directorios padres contra symlinks; el entrypoint deriva y valida la ruta dentro del proyecto; el adaptador exige fuente local; pruebas reales cubren stop/reopen, medio inválido y recuperación. La superficie distingue inicialización del controller, registro de textura y primer frame procesado. La suite focalizada pasó 25 pruebas y la suite completa 87 con el Flutter explícito de `.ai-local/toolchains/flutter`; `flutter analyze`, build Linux release con `-t lib/main_player_spike.dart`, `dart analyze`, formato, import checker, memory check y diff check pasaron. El launcher resuelve la raíz desde su ubicación; la regresión manual de symlink salió con código 2. Un intento de test del VideoController con canal simulado no completó `platform.future`; no hay ciclo nativo automatizado. El bundle creó una textura, pero esta sesión no ofreció ventana nativa a CUA: primer frame/compositor y evento GTK de cierre quedan sin verificar. El archivo externo v2 no se encontró tras la verificación solicitada; se contrastaron los doce hallazgos pegados y la auditoría distinta `Kongroo_F2_2_Auditoria_Independiente.md`, sin presentarla como el documento externo. La reevaluación independiente confirmó R1/R2 corregidos y solicitó alinear los conteos del informe y del traspaso; se actualizaron. No se modificó catálogo/Drift en esta corrección. F2.2 sigue abierta y no aceptada; no avanzar F2.3. Detalle y límites en el [informe v2](../player/F2.2-spike-report-v2.md).

### F2.2 — Controles exclusivos y cierre con watchdog — 2026-11-10

Se corrigió el defecto confirmado de controles dobles: `MediaKitVideoSurface` pasa `NoVideoControls` tipado como `VideoControlsBuilder?`; la versión instalada define el sentinel como `null`, que omite el overlay entero en `VideoState.build`. Play/Pause es un único botón sincronizado con snapshot, el tiempo se lee como `MM:SS`/`H:MM:SS` y el slider tiene etiqueta semántica. Auditoría independiente halló que un seek coalescido podía ir después de Stop; ahora la UI elimina el destino pendiente, espera el seek activo y solo entonces detiene, con regresión que exige `seek → stop`. También se añadió en GTK un watchdog GLib nominal de 20 s. Si el canal no responde, limpia el guard local y permite retry cuando la llamada original ya contestó; mientras una invocación siga pendiente, no se duplican llamadas. No destruye ventana ni cancela cleanup y depende de que el main loop siga respondiendo. `GWeakRef` evita retener otra referencia fuerte al application por callback; una tarea de canal sin respuesta puede quedar pendiente, manteniendo la ventana abierta. El objeto `my_application.cc` compiló aisladamente. El close gate Dart conserva watchdog de respuesta de 15 s y pasó el probe no cancelante. Guard shell de symlinks y dos fixtures reproducibles byte-idénticos pasaron en este corte. Flutter analyze local pasa, pero tests/build fallan antes del producto por incompatibilidad framework/engine: `SemanticsRole.slider` no se maneja en `semantics.dart:164`. Una ejecución accidental mediante Flutter resuelto por PATH obtuvo 30 tests player/92 app y build, pero no cuenta como gate del toolchain del proyecto. Broadway aislado no soportó EGL/OpenGL; no hay evidencia de píxeles visibles, audio actual, ciclo nativo de VideoController ni cierre GTK real. F2.2 sigue abierta/no aceptada; no iniciar F2.3. Ver [auditoría](../ai-system/audits/F2.2-audit-2026-11-10.md) e [informe](../player/F2.2-spike-report-v2.md).

### F2.2 — Revalidación de tests y build — 2026-11-10

Nota vigente que supersede los bloqueos de test/build descritos arriba: Flutter 3.47.9 stable/Dart 3.13.7 aislado satisface el mínimo del proyecto. El test de startup/cierre pasó 2/2, suite player 32/32, suite Flutter 94/94 y build release Linux del entrypoint `-t lib/main_player_spike.dart`; `pub get --offline --enforce-lockfile` preservó `pubspec.lock`. `dart analyze` exit 0 con ocho infos. `scripts/ci.sh` termina exit 1 solo por Flutter analyze (255), bloqueado por LSP UTF-8 en la ruta Unicode. El video visible, `VideoController` nativo y cierre GTK real siguen pendientes. No se acepta F2.2 ni se inicia F2.3. Ver [auditoría F2.2](../ai-system/audits/F2.2-audit-2026-11-10.md), [informe](../player/F2.2-spike-report-v2.md) y [TESTING.md](../../TESTING.md).

## Restricciones
Un especialista a la vez en sesiones nuevas; no rebajar el modelo para ahorrar tokens. Sin push, sin servicios residentes ni secretos. Ante aprobación necesaria, continuar tareas independientes y registrar bloqueo.

### Auditoría de pruebas reales F1.5–F1.12 — 2026-11-09

Se ejecutaron 44 pruebas Flutter, `flutter analyze`, Dart analyze, build Linux release y CI con Flutter `3.50.0-0.4.pre` / Dart `3.14.0-315.3.beta` aislado; todos los comandos obligatorios finalizaron exit 0. CI incluye 40 pruebas IA. SQLite real pasó persistencia, reopen, ruta migratoria v1→v2→v3, v2→v3, rollback e `integrity_check`. El test nuevo integra settings, HTTP loopback, cache, servidor cerrado, offline tras reopen y recuperación. La revisión detectó/corrigió eventos redundantes en `SettingsStore.watch`, redirect del POST AniList, mapeo de 401 y crash potencial al sanear URLs malformadas. AniList externo: 0 solicitudes por elegibilidad pendiente; keyring y OAuth reales no probados. F1.10 permanece JSON opaco; F1.11 carece de outbox/políticas. El flujo del producto sigue sin conectar estos adaptadores y no se inició F2. Evidencia en [`informe de validación`](../../docs/validation/2026-11-09-f1-5-f1-12-real-tests.md) y [`sesión`](sessions/2026-11-09-f1-5-f1-12-real-tests.md). La CI stable de Flutter 3.47.9 sigue bloqueada por LSP Unicode.

### F2.2 — Revisión final de cierre — 2026-11-10

La ruta solicitada `docs/ai-system/audits/entrada/Operacion-cierre-F2.2.txt` no existe; se leyó el archivo homónimo disponible en `docs/ai-system/audits/Operacion-cierre-F2.2.txt`. La auditoría final encontró que el aviso de cleanup quedaba oculto si fallaba el startup. `main_player_spike.dart` ahora lo presenta sobre los estados de apertura/error y se añadieron dos widget tests. El gate puede responder que sí al cierre tras `module.close()` o tras un rollback de apertura que liberó correctamente recursos; README e informe lo aclaran. Dart analyze pasa; el test Flutter no carga por el mismatch framework/engine `SemanticsRole.slider`. La verificación gráfica del compositor, VideoController Linux real y cierre GTK siguen pendientes. F2.2 continúa abierta/no aceptada; no iniciar F2.3.


### F2.2 — Últimas comprobaciones — 2026-11-10

La nota previa queda supersedida para Flutter analyze: el SDK aislado 3.47.9 recibió un backport local reproducible del arreglo upstream LSP de longitud UTF-8; se reconstruyó Flutter Tools y `flutter analyze` pasó en la ruta Unicode real. La última `bash scripts/ci.sh` terminó exit 0, incluidos 40 tests Python y 94 Flutter. Ocho infos `prefer_final_locals` se corrigieron sin desactivar reglas. El propietario verificó manualmente (no automatizado) video visible/fotogramas cambiantes, audio, controles únicos, Play/Pause y seek bidireccional. La captura de Stop/cierre GTK queda pendiente de ejecución manual con `tools/player/capture_f2_2_owner_close.sh`; logs de cleanup/handshake/exit se guardarán bajo `.ai-local/f2.2/evidence/`. No hay prueba real de `VideoController` Linux; no se abrió otra ventana del escritorio. F2.2 continúa abierta/no aceptada; no iniciar F2.3.

Revisión estática independiente focalizada (solo lectura) aclaró que el watchdog GTK no debe reintentar una llamada MethodChannel sin callback porque timeout no la cancela; se corrigieron comentarios y se añadieron guardas contra symlinks de SDK, caché y evidencia. No quedan hallazgos estáticos en ese alcance. No constituye prueba GTK dinámica.


### F2.2 — Recuperación Stop → Play — 2026-11-10

El defecto se reprodujo con libmpv real: media_kit 1.2.6 Stop limpia la playlist; Play aislado no reabre fuente. El adaptador conserva la última URI abierta con éxito, emite `stopped`, y Play posterior revalida/reabre en el mismo Player; Pause→Play preserva posición. Widget muestra estado detenido sin crear otra superficie. Focalizada 14/14; `bash scripts/ci.sh` exit 0 con 40 pruebas de infraestructura + 99 Flutter, Flutter analyze y checks Dart; build Linux release `-t lib/main_player_spike.dart` exit 0. Evidencias en `.ai-local/f2.2/evidence/stop-play-*`. La auditoría independiente no encontró defecto de capa/cola; sigue P1 pendiente: imagen real tras reabrir misma URI en compositor Fedora (upstream issue #957 está abierta), y cierre GTK/VideoController en esta secuencia no se observó. El propietario confirma previo Play/Pause/seek/video pero aún debe confirmar Stop→Play visual/audio. F2.2 abierta/no aceptada; no iniciar F2.3. Ver [auditoría Stop→Play](../ai-system/audits/F2.2-stop-play-audit-2026-11-10.md) e [informe F2.2](../player/F2.2-spike-report-v2.md).

### Operación extendida del reproductor

El spike tiene un DEMO con archivos originales, espejos HTTP loopback y dos episodios, selección de audio y diagnóstico básico. Las verificaciones y brechas se mantienen en [la guía de la operación extendida](../player/operacion-extendida.md).

### Corrección de interfaz con Morevna, 2026-11-12

El launcher predeterminado prepara dos episodios reales licenciados y los controles nuevos. Los tonos y barras quedaron en modo sintético optativo. Evidencia, arquitectura y límites en [DEMO Morevna](../player/demo-morevna.md).

### Selector de calidad de video — 2026-11-12

Se añadió `PlayerQualityPanel` a los controles. Domain normaliza únicamente las dimensiones/bitrate/códec observados; application valida IDs y generación en la cola; el adaptador selecciona con `Player.setVideoTrack` y confirma el ID nativo. La pista `auto` se ofrece solo con varias pistas reales y significa selección predeterminada del motor, no ABR. Widget y libmpv prueban dos dimensiones, continuidad de posición y preservación de audio/subtítulos; Morevna real se verificó como única pista 534×300 y aparece fija. El flujo actual no parsea variantes de manifests HLS/DASH ni fuentes de URL externas. Auditoría focalizada: [informe](../ai-system/audits/PLAYER-QUALITY-audit-2026-11-12.md). No se modifica el estado de aceptación de las fases.

### Documentación modular — 2026-11-12

Se añadieron README a subdirectorios de código que carecían de guía: `core/errors`, `core/logger`, `core/result`, `data/local_db/tables`, `data/testing` y los submódulos de diagnóstico, subtítulos externos, skips, cambio de fuente, proveedores y dominio de subtítulos del player. Índice: [MODULE_INDEX](MODULE_INDEX.md). Cambios solo documentales; sin alteración de código funcional.
