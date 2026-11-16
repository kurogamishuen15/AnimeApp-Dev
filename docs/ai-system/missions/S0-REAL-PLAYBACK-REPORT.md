# KONGROO — informe de reproducción real S0

> Estado: `ACTIVE` — actualización 2026-11-16. Ningún proveedor ha superado todavía la reproducción real de video con libmpv. Este documento registra evidencia, no declara disponibilidad permanente.

> **Nota de continuidad:** los snapshots siguientes describen cortes previos a la integración AnimeHeaven. El runtime actual tiene AnimeHeaven registrado, pero sin reproducción externa confirmada. La limpieza posterior retiró Miruro y los adapters anteriores. Ver el [README del provider actual](../../../app/lib/data/player/providers/animeheaven/README.md), la [auditoría AnimeHeaven](../audits/S0R-ANIMEHEAVEN-audit-2026-11-16.md), la [auditoría de limpieza](../audits/S0-provider-cleanup-followup-audit-2026-11-15.md) y la [auditoría del port](../audits/S0-ANILILI-port-audit-2026-11-15.md).

## S0-R — prueba visible de AnimeHeaven — 2026-11-16

El runtime integra un provider de AnimeHeaven y un resolver MP4 separado,
registrados en `PlaybackProvidersModule`. One Piece, episodio 1, publicó tres
alternativas: `mirror-cx`, `mirror-ct` y `mirror-ck`. Se abrieron por separado
con el harness y la ruta/player existentes. Los tres mostraron el error
genérico de apertura/decodificación y ningún fotograma. Las capturas
`.ai-local/review/s0r-animeheaven-visible.png`,
`.ai-local/review/s0r-animeheaven-mirror-switch.png`,
`.ai-local/review/s0-animeheaven-mirror-cx.png` y
`.ai-local/review/s0-animeheaven-mirror-ck.png` documentan las ventanas. El
probe HTTP validó las alternativas y el MIME/prefijo, pero eso no demuestra que
libmpv pueda abrirlas. No se conservó log nativo para atribuir la causa; no se
confirmó frame, reproducción ni audio externo. AnimeHeaven no queda operativo y
el conteo continúa **0/70**.

El usuario indicó que autorizó manualmente en KDE. Una captura posterior ya no
mostró el diálogo; el conector Wayland siguió devolviendo `Transport closed`,
así que no se usó control simulado. El harness se ejecutó con un ID de mirror
por proceso; cada instancia se cerró antes de lanzar la siguiente. No se
guardaron ni imprimieron URLs efímeras.

Checks ejecutados tras estos cambios: 13 pruebas focalizadas de AnimeHeaven y
composition root, más 48 regresiones focalizadas de providers, manager,
contratos, route y player module. `flutter analyze --no-pub` en el paquete y
`dart analyze` de los módulos/tests/harness pasaron. Una prueba consume 512
chunks pequeños; otra cancela un body abierto. La cancelación usa un listener
temporal desregistrado tras cada avance. La prueba `flutter test` no sirve como
smoke live: `TestWidgetsFlutterBinding` interceptó HTTP y respondió 400. No hay
prueba de rendimiento del stream; las medidas previas son de una máquina con
7.5 GiB y no validan el objetivo de 4 GB. S0 sigue abierta, Gate 0/1 parciales,
1 provider implementado, 0 reproducibles.

El diagnóstico diferencial CLI del Gate 0 no se pudo ejecutar: `mpv --version`
no está disponible porque `mpv` no se encontró en PATH. No se instaló software
ni se modificó el sistema. Por ello no se puede separar todavía un fallo de la
fuente/codec de una diferencia específica entre libmpv integrada y la ruta de
Kongroo.

El resultado de AnimeHeaven no agota el inventario de proveedores. En
particular, la auditoría de Anivexa enumera 28 candidatos, de los que solo
AniChan, AniPM y Zoko recibieron probes live; los demás no están clasificados
como agotados. El siguiente trabajo permitido es una inspección estática
selectiva y, solo si encuentra un host distinto con ruta pública ordinaria,
como máximo un GET sin sesión ni controles excluidos. No se afirma que todos
los candidatos restantes estén bloqueados.

## Registro previo — S0-R actualización de accesibilidad — 2026-11-16

Gate 0 permanece parcial según [S0R-BASELINE.md](S0R-BASELINE.md). Gate 1
revisó referencias y licencias de Anilili Android/Desktop, Aimi, ani-cli,
anipy-cli, anime-sh, GoAnime y anime1v-api. Commits, idiomas declarados,
mecanismos y límites están en
[S0R-REFERENCE-REVIEW-2026-11-16.md](S0R-REFERENCE-REVIEW-2026-11-16.md).

Seis probes GET públicos previos en AniZone, Miruro, AnimeFire, 123AnimeHub,
AnimesDigital y AnimeDrive respondieron HTTP 403. AniWorld permitió búsqueda,
ficha, temporada y episodio públicos de One Piece; cuatro familias de hoster
aparecieron en sus alternativas. Doodstream, Filemoon y Vidmoly devolvieron
403; VOE devolvió HTML con redirección JavaScript y lectura opcional de
`localStorage`, sin una fuente MP4/HLS/DASH estática. No se ejecutó JavaScript,
no se leyó/creó token y no se siguió el destino. En ese corte aún no se había
implementado ni registrado código nuevo. S0 continuaba 0/70, con cero
proveedores externos operativos y ninguna reproducción externa visible. El detalle está en
[S0R-REFERENCE-REVIEW-2026-11-16.md](S0R-REFERENCE-REVIEW-2026-11-16.md).

## Historial: estado tras limpieza de S0-A — 2026-11-15

Se retiraron `MiruroPlaybackProvider`, `DioMiruroCatalogApi` y
`MiruroDirectMediaResolver`. El único composition root de providers queda con
un manager vacío. La prueba activa comprueba que no se registran adapters; las
pruebas específicas S0-A se conservaron fuera de `app/test` como fuentes
archivadas. S0 continúa incompleta: no hubo reproducción externa y el conteo es
`0/70`. Ver la [auditoría de seguimiento](../audits/S0-provider-cleanup-followup-audit-2026-11-15.md).

## Registro histórico — ejecución S0-A — 2026-11-15

El único provider implementado en el runtime es `MiruroPlaybackProvider`, con
`MiruroDirectMediaResolver`, ambos conectados al manager y al engine existentes.
No se implementó Anivexa. Los GET públicos ordinarios de config y lookup de
Miruro respondieron HTTP 403; el smoke real con Dio clasificó el resultado como
`unauthorized`. No se obtuvo episodio o fuente multimedia accesible y no hubo
apertura externa de libmpv, primer frame, seek o audio. Playback externo sigue
`0/70`. No se probó la ventana del reproductor en Wayland ni se midió rendimiento
del provider.

La CI posterior al refuerzo DNS pasó: 40 pruebas Python, 288 pruebas Flutter y
7 pruebas optativas omitidas; Flutter/Dart analyze, formato, checker de imports
y memoria pasaron con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislado. La evidencia de
los probes, arquitectura, límites y auditoría está en el [informe de port
S0-A](S0-ANILILI-PORT-REPORT.md) y su [auditoría](../audits/S0-ANILILI-port-audit-2026-11-15.md).
`flutter build linux --release --no-pub` también pasó; compilar no acredita
reproducción de media externa.

La limpieza previa conservó su registro como historia. Las métricas y matrices
de las secciones siguientes describen la línea anterior y no sustituyen el
estado actual indicado arriba.

## Snapshot histórico de alcance e indicadores (pre-limpieza)

- Inventario autorizado: **22 candidatos** listados en el plan maestro.
- Adaptadores implementados en el árbol: **3** (AnimeAV1, TioAnime y AnimeGG).
- Candidatos con alguna evidencia pública parcial vigente: **21/22**; esto no significa que los 21 hayan completado búsqueda, episodio, servidor y resolución.
- Clasificación del inventario: **3 `RESOLVING`**, **11 `BLOCKED_EXTERNAL`**,
  **7 `INVESTIGATING`** y **1 `PENDING`** (AnimeV1; identidad/dominio actual
  sin confirmar).
- Una resolución externa reciente produjo URI para libmpv (AnimeGG/vidcache): avanzó 5311 ms y detectó audio, pero no dimensiones de video. YourUpload produjo una URI en una corrida anterior, sin reproducir.
- Proveedores con reproducción verificada: **0**.
- Títulos distintos reproducidos de la meta de 70: **0/70**.
- Publicaciones de `PlaybackSourceSwitchService` verificadas con proveedores externos: **0**.

## Snapshot histórico pre-limpieza: revisión S0 enfocada en hosts — 2026-11-15

La arquitectura y los resultados siguientes describen el alcance conocido en
ese corte anterior a la limpieza; no son verificaciones del runtime actual.
`AnimeProvider` conserva búsqueda, identificación de episodio
y descubrimiento de alternativas; un `PlaybackVideoHostResolver` compartido
resuelve fuentes públicas; el `MediaKitSpikeEngine` existente conserva la
propiedad y reproducción libmpv. No se añadió un segundo reproductor.

| Host observado | Proveedor/fuente de descubrimiento | Entrega/resultado observado | Clasificación al momento del probe |
|---|---|---|---|
| `player.zilla-networks.com` / AnimeAV1 | AnimeAV1, Shingeki no Kyojin ep. 1 | GET ordinario al embed denegado `unauthorized`; sin URI para libmpv. No se reintentó ni eludió. | `RESOLVING` |
| `mega.nz` (Mega) | TioAnime ep. 1 | Resolver estático compartido devuelve `unsupported`; no se obtuvo fuente directa pública. | `RESOLVING` |
| `embedsb.com` (StreamSB) | TioAnime ep. 1 | Timeout en la inspección pública acotada; no hubo URI. | `RESOLVING` |
| `yourupload.com` (YourUpload) | TioAnime ep. 1 | Corrida previa extrajo URI, pero libmpv no avanzó y reportó error; última repetición del host terminó `network` antes de URI. | `RESOLVING` |
| `ok.ru` (OK.ru) | TioAnime ep. 1 | HTML público sin medio estático reconocido; resolver `unsupported`. | `RESOLVING` |
| `hqq.tv` (Netu) | TioAnime ep. 1 | HTML público sin medio estático reconocido; resolver `unsupported`. | `RESOLVING` |
| `vidcache.net` | AnimeGG, One Piece ep. 1 | La variante preferida resolvió tras redirects allowlisted; libmpv avanzó 5311 ms y detectó codec de audio, pero `video=nullxnull`. Sin cuadro de video ni reproducción confirmada. | `RESOLVING` |
| `seiryuu.vid-cdn.xyz` | AniZone, manifiesto anunciado como HLS | Range y GET ordinario devolvieron HTTP 404 con body HTML; la acción Livewire pública respondió 419. No se intentó superar el control. | `BLOCKED_EXTERNAL` |
| CatStream (dominio del media endpoint no confirmado) | KickAssAnime, One Piece ep. 1 | La página del player respondió 200 pero no expuso URL/manifiesto estático reconocible; la referencia upstream señala rutas con JS y firma/AES para servidores legacy. No se adaptó esa extracción. | `BLOCKED_EXTERNAL` |
| FlixCloud (dominio del media endpoint no fijado aquí) | ReAnime | La fuente upstream inspeccionada obtiene token/stream mediante `enc-dec.app` y decodifica segmentos XOR en un proxy local. No se verificó una URL directa sin esa transformación; no hubo probe live ni implementación. | `INVESTIGATING` |
| MegaPlay (dominio del media endpoint no confirmado para 2DHive) | 2DHive | La evidencia previa de fuente señala una etapa crypto antes del medio; no se obtuvo una URI HLS/MP4 directa y no se intentó descifrarla. | `INVESTIGATING` |
| FileStream, Bee, Goma | No aparecieron en las cinco alternativas de TioAnime ni en las fuentes/fixtures examinadas de AnimeAV1, AnimeGG o AniZone. | No hay URL, formato o evidencia para probar un resolver de esos hosts. Esta búsqueda acotada no demuestra que no existan en otros episodios. | No observado |

Las cinco filas de calidad/idioma de AnimeGG son variantes de fuente, no cinco
servidores. El único host de entrega confirmado durante esa selección fue
`vidcache.net`. No se registró ninguna URL multimedia firmada en documentos ni
logs.

### Transporte y validaciones

- MP4 prueba un `Range: bytes=0-0`; si responde 405, 416 o 5xx, hace una sola
  petición ordinaria sin Range en ese endpoint. Respuestas de redirect se
  procesan manualmente, con límite y revalidación HTTPS, allowlist y DNS público.
- HLS se solicita con GET ordinario y sin `Range`; el body acotado debe comenzar
  con `#EXTM3U`. Se revisan MIME reconocidos, referencias HTTPS permitidas y DNS;
  `SAMPLE-AES` se rechaza. La prueba no descarta HLS por un Range fallido.
- Se transporta solo un `Referer` de origen HTTPS público validado; no se usan
  cookies, Authorization, credenciales, CAPTCHA, JS de extracción ni descifrado.
- Las pruebas deterministas acreditan contrato y transporte, no disponibilidad
  externa. La reproducción completa requiere dimensiones de video, avance y
  ausencia de error en libmpv.

## Evidencia de esta ejecución

> Las subsecciones de búsqueda y hosts de este bloque describen intentos
> previos al retiro de los adapters. En particular, el texto sobre AnimeGG y
> sus variantes no significa que ese módulo siga registrado en el runtime.

### Historial — AnimeGG, búsqueda, episodio y variantes observadas

Anime: `One Piece`; episodio: 1. La búsqueda exacta encontró la ficha y el
episodio público. Se detectaron cinco variantes: `subbed/1080p`,
`subbed/720p`, `subbed/480p`, `subbed/360p` y `dubbed/360p`, cada una con un
servidor multimedia listado. La prueba live intentó resolver cada servidor una
vez; los cinco devolvieron `PlaybackProviderFailureKind.network`. Ninguno
obtuvo URI para libmpv y no hubo reproducción, frame visible, audio ni seek.
AnimeGG sigue `RESOLVING`.

Se registró el adaptador modular `data/player/providers/animegg/`, con lectura
de páginas públicas y de la declaración estática `videoSources`. La validación
de media usa un request de un byte, hasta tres redirecciones y allowlist de
hosts HTTPS. El stream transporta un `Referer` público restringido por el
dominio hasta `Media(httpHeaders: ...)`; no se transmiten credenciales ni se
ejecuta JavaScript. Una integración local con servidor de prueba y libmpv
confirmó el `Referer` en apertura y reapertura Stop→Play; no es evidencia de un
servidor externo. Los cinco fallos de red se registraron como diagnóstico y no
se repitieron durante este corte.

### Regresión contractual TioAnime

TioAnime devuelve varios servidores en una fuente. La prueba directa con dos alternativas demostró que el manager rechazaba la respuesta porque el adaptador no declaraba `sourceAlternatives`. Se añadió esa capacidad, se documentó en el README de TioAnime y la prueba de regresión pasó a través del `PlaybackProviderManager`.

El manager también contaba cada servidor fallido como un fallo separado del circuito de resolución. Una regresión con tres servidores fallidos y un cuarto válido reprodujo que el circuito se abría antes de probar el cuarto. El manager ahora contabiliza el fallo del conjunto de alternativas al agotarse la operación; una resolución válida en cualquiera de ellas reinicia el circuito. La suite del manager pasa con la regresión incluida.

### Intento Fedora/libmpv de TioAnime

Anime: `Shingeki no Kyojin`; episodio: 1; idioma informado por el adaptador: `es`; calidad: `auto`; servidores encontrados: 5.

| Servidor listado | Resolución | Resultado con libmpv |
|---|---|---|
| Mega | `PlaybackProviderUnsupported` | No se abrió |
| StreamSB | `PlaybackProviderFailed(timeout)` | No se obtuvo una URI |
| YourUpload | `PlaybackProviderSuccess` | `position_ms=0`, el engine informó error; no hay reproducción |
| OK.ru | `PlaybackProviderUnsupported` | No se abrió |
| Netu | `PlaybackProviderUnsupported` | No se abrió |

La prueba recorrió los cinco servidores secuencialmente y cerró el coordinator en cada intento que abrió el engine. No se verificaron primer frame visible, audio, seek ni el flujo desde la ficha AniList. Por tanto, TioAnime sigue `RESOLVING`, no `PLAYBACK_VERIFIED`.

### AnimeAV1

Para el mismo anime/episodio, `findSources` devolvió una fuente real. La alternativa pública del reproductor falló durante la resolución con `PlaybackProviderFailed(unauthorized)`; esta corrida no obtuvo una URI para abrir con libmpv. La portada dio HTTP 200. No se infiere de ello que el reproductor o sus medios estén disponibles; la denegación no se eludió.

El smoke optativo registra como éxito únicamente posición avanzada y dimensiones de video decodificado. Su primera corrida terminó en fallo de aserción; ese pipeline inicial no propagó el código de salida porque se ejecutó sin `pipefail`. Una repetición diagnóstica registró exit 1 y `unauthorized`; no se hicieron más solicitudes después de esa evidencia.

### Otros candidatos sondeados

Las solicitudes fueron GET públicos simples, acotados y sin cookies. No se siguieron rutas de desafío ni se reintentó tras una denegación.

| Candidato | Evidencia actual | Estado |
|---|---|---|
| AnimeOnline Ninja | GET a `ww3`: HTTP 403; la referencia pública upstream describe `ww4` como host canónico, pero su GET de portada también devolvió 403. La PR informa que la verificación manual actual se detiene por un desafío Cloudflare interactivo. | `BLOCKED_EXTERNAL` |
| JKAnime | GET de portada: HTTP 403 | `BLOCKED_EXTERNAL` |
| AnimeJara | La portada había respondido HTTP 200 con curl y 403 con otro cliente. En esta continuación, el GET corriente de `/catalogo/` devolvió 403. No se confirmó detalle/episodio sin denegación. | `BLOCKED_EXTERNAL` |
| AnimeFLV | `animeflv.net` devolvió error de transporte (`000`). El candidato comunitario separado `vww.animeflv.one` respondió 200; la búsqueda GET devolvió One Piece y dos fichas públicas (One Piece, Demons' Crest) devolvieron 200 pero no expusieron rutas de episodio detectables. No se atribuye ese dominio a AnimeFLV original ni se implementó adaptador. | `INVESTIGATING` |
| AnimeV1 | El dominio candidato `anime1v.com` devolvió error de transporte (`000`); identidad/dominio actuales no confirmados. `anime1v-api` documenta scraping de AnimeAV1.com, no un proveedor independiente AnimeV1; no se usó su API autenticada ni su lógica de anti-bot/bypass. | `PENDING` |
| Latanime | La lista de extensiones consultada señala `latanime.org`; GET público de portada devolvió 403. No se siguió ninguna ruta de búsqueda/episodio. | `BLOCKED_EXTERNAL` |
| Henaojara | GET a `www.henaojara.com` devolvió 301 a `animejara.com`. La redirección no se siguió porque corresponde a otro candidato y no se ha confirmado como mirror. | `INVESTIGATING` |
| AnimeKai | Los GET a `animekai.to`, `.fi` y `.gs` fallaron en DNS. La extensión consultada describe Cloudflare y descifrado externo para resolver video; no se usaron esos mecanismos. | `BLOCKED_EXTERNAL` |
| AllAnime | GET a la raíz de `allmanga.to` devolvió 200, sin rutas de búsqueda/episodio parseables en el HTML. La referencia upstream reporta verificaciones Cloudflare en páginas de episodio; no se siguió esa ruta. | `BLOCKED_EXTERNAL` |
| Miruro | GET de portada a `miruro.to`: HTTP 403. No se siguió el pipe ni se intentó superar el desafío. | `BLOCKED_EXTERNAL` |
| Senshi | La solicitud pública registrada devolvió HTTP 523. No se identificaron rutas públicas de episodio/servidor. | `BLOCKED_EXTERNAL` |
| AniBD | La identidad pública examinada redirigió a MMani; no se confirmó relación de mirror ni se siguió como si fuera el mismo proveedor. | `INVESTIGATING` |
| AniKoto | Búsqueda y detalle públicos respondieron; la ruta de servidores requiere un parámetro `vrf`. No se reprodujo el flujo ni se intentó generar o eludir ese control. | `INVESTIGATING` |
| KickAssAnime | En `kaa.lt`, búsqueda, detalle, idioma, episodio 1 y lista de servidor públicos respondieron. La fuente actual fue CatStream; su página de player respondió 200 pero no expuso una URL/manifiesto estático reconocible. El extractor upstream requiere JS para algunas rutas y firma/AES para servidores legacy; no se aplicaron esas rutas. | `BLOCKED_EXTERNAL` |
| ReAnime | Páginas públicas de anime/episodio accesibles; el código upstream de FlixCloud usa token/stream por API y segmentos XOR transformados en proxy local. No se verificó ni ejecutó ese mecanismo. | `INVESTIGATING` |
| AniZone | Se observó host `vid-cdn.xyz`; manifiesto devolvió 404 por Range y GET ordinario; acción Livewire pública devolvió 419. | `BLOCKED_EXTERNAL` |
| 2DHive | Búsqueda, detalle y episodio accesibles; el servidor MegaPlay requiere una etapa crypto no ejecutada. | `INVESTIGATING` |
| AniNeko | El dominio examinado expiró en timeout y el dominio alternativo visto no quedó confirmado por fuente primaria. | `BLOCKED_EXTERNAL` |
| RareAnimes | Dominio/identidad y páginas actuales inciertos; no se halló una ruta confirmada de episodio o medios. | `INVESTIGATING` |

Los errores 403 se conservan como bloqueos observados en esas solicitudes, no como juicio permanente sobre la disponibilidad del proveedor. Las respuestas de portada 200 tampoco confirman búsqueda, episodios, servidores o streams.

## Snapshot de runtime actual — 2026-11-16

| Provider | Título / episodio | Host / formato | Idioma | Resolución live | Frame/libmpv | Estado |
|---|---|---|---|---|---|---|
| AnimeHeaven | One Piece, episodio 1 | `mirror-cx`, `mirror-ct`, `mirror-ck`; MP4 progresivo | Subtitulado; idioma no validado | Los probes pasaron; los 3 intentos con libmpv mostraron error genérico | No | Implementado; no reproducible |

Conteo actual: **1 provider implementado, 0 con reproducción confirmada, 0/70**.
El harness utilizó la ruta y engine existentes; la ficha completa AniList no se
recorrió de punta a punta.

## Historial: matriz del inventario autorizado (snapshot previo a la limpieza)

`IMPLEMENTED` significa que existe adaptador; no acredita funcionamiento externo. `INVESTIGATING` indica evidencia parcial sin recorrido completo; `PENDING` indica que aún no hay evidencia suficiente para clasificar el candidato.

| Proveedor | Anime | Episodio | Servidor | Idioma | Resolución | Reproducción | Estado |
|---|---|---:|---|---|---|---|---|
| AnimeAV1 | Shingeki no Kyojin | 1 | public embed | japonés (adaptador) | fallida | No | `RESOLVING` |
| TioAnime | Shingeki no Kyojin | 1 | 5 alternativas | español (adaptador) | 1 URI resuelta; demás unsupported/failure | No | `RESOLVING` |
| AnimeOnline Ninja | — | — | — | — | — | No | `BLOCKED_EXTERNAL` |
| JKAnime | — | — | — | — | — | No | `BLOCKED_EXTERNAL` |
| AnimeJara | — | — | — | — | — | No | `BLOCKED_EXTERNAL` |
| AnimeFLV | One Piece / Demons' Crest (candidato Animeflv.one) | — | — | — | búsqueda sí; 2 fichas sin rutas episodio | No | `INVESTIGATING` |
| AnimeV1 | — | — | — | — | dominio sin confirmar | No | `PENDING` |
| Latanime | — | — | — | — | portada 403 | No | `BLOCKED_EXTERNAL` |
| Henaojara | — | — | — | — | 301 a AnimeJara, no seguido | No | `INVESTIGATING` |
| Miruro | — | — | — | — | — | No | `BLOCKED_EXTERNAL` |
| Senshi | — | — | — | — | 523 observado | No | `BLOCKED_EXTERNAL` |
| AniBD | — | — | — | — | redirección a MMani, relación no confirmada | No | `INVESTIGATING` |
| AniKoto | anime no fijado | — | — | — | búsqueda/detalle sí; ruta server exige `vrf` sin reproducir | No | `INVESTIGATING` |
| KickAssAnime | One Piece | 1 | CatStream | — | player HTTP 200; sin URL/manifiesto estático reconocido | No | `BLOCKED_EXTERNAL` |
| AllAnime | — | — | — | — | raíz 200; episodios protegidos según upstream | No | `BLOCKED_EXTERNAL` |
| AnimeKai | — | — | — | — | mirrors publicados sin DNS; no se usó resolver | No | `BLOCKED_EXTERNAL` |
| ReAnime | anime no fijado | episodio público | FlixCloud | — | upstream: token/stream API y segmentos XOR por proxy; sin probe live | No | `INVESTIGATING` |
| AniZone | anime no fijado | flujo Livewire | `vid-cdn.xyz` | — | manifiesto 404 por Range y GET; acción 419 | No | `BLOCKED_EXTERNAL` |
| AnimeGG | One Piece | 1 | `vidcache.net` (variante preferida) | subbed/1080p | URI entregada; 5311 ms y audio, sin dimensiones de video | No | `RESOLVING` |
| AniNeko | — | — | — | — | timeout; alternativa no confirmada | No | `BLOCKED_EXTERNAL` |
| 2DHive | anime no fijado | episodio accesible | MegaPlay | — | etapa crypto no ejecutada | No | `INVESTIGATING` |
| RareAnimes | — | — | — | — | identidad/ruta no confirmadas | No | `INVESTIGATING` |

## Cambios, pruebas y artefactos

- `TioAnimePlaybackProvider` declara `sourceAlternatives`; regresión por fixture valida que el manager acepte las dos alternativas.
- `PlaybackProviderManager` difiere el fallo del breaker hasta terminar las alternativas del proveedor; regresión prueba el cuarto servidor sano después de tres fallos.
- Se añadió un smoke optativo de AnimeAV1 que exige decodificación de video y avance, pero no se ejecuta en CI por defecto.
- `PlaybackSourceSwitchService` conservó fallback a un candidato posterior después del fallo del primero con engine fake. Un test separado con libmpv y medios locales verificó cambio de fuente y conservación de posición; esto no acredita fallback con proveedores externos.
- Suite focalizada post-cambio: **16/16** pruebas del manager pasan. Suite combinada providers + manager: **22 pasan, 2 live omitidas**.
- Source switch con fallback fake: **1/1**; cambio de fuente con libmpv/fixtures locales: **1/1**.
- Flutter analyze aislado 3.47.9: **sin issues**.
- Corridas live optativas de TioAnime y AnimeAV1: ambas exit 1; no se acredita reproducción. TioAnime reportó timeout de StreamSB; AnimeAV1 reportó `unauthorized` al resolver el embed. Recheck focalizado Flutter 3.47.9: 22 pass, 2 live skipped; Flutter/Dart analyze y formato pasan.
- Salidas sanitizadas: [`.ai-local/review/s0-real-playback-2026-11-15/`](../../../.ai-local/review/s0-real-playback-2026-11-15/). Los probes guardan códigos HTTP, paths y labels; no se conservaron cookies, respuestas completas ni URLs multimedia.
- Logs de este recheck: `provider-manager-focused-suite-s0-recheck.log`, `flutter-analyze-s0-recheck.log`, `dart-analyze-s0-recheck.log`, `animeflv-one-public-route-probe.log`, `animeflv-one-second-detail-probe.log`, `latanime-root-probe.log`, `henaojara-redirect-probe.log`, `animekai-root-probe.log`, `animekai-mirror-probes.log` y `allanime-root-probe.log` dentro del directorio privado anterior.

### Continuación AnimeGG — verificaciones adicionales

- `flutter analyze --no-pub` con Flutter 3.47.9 aislado: sin issues.
- Adaptador providers: 7 pasaron; tres smokes live omitidos por defecto.
- Contrato domain: 6/6; manager: 16/16; coordinator: 28/28.
- Integración local `Referer` + libmpv con Stop→Play: 1/1. Registró tres
  requests al servidor loopback y vio la cabecera válida en apertura y replay.
- Smoke live AnimeGG: búsqueda y cinco variantes pasaron; resolución de los
  cinco servidores falló `network`; prueba exit 1 porque ninguno pudo abrirse.
- No se ejecutó CI completa ni prueba visual de ventana para esta continuación.

## Referencias técnicas actuales

- Un [PR público de la extensión AnimeOnline Ninja](https://github.com/yuzono/anime-extensions/pull/1274) propone `ww4` como host canónico y registra que la verificación manual se detuvo ante el desafío Cloudflare interactivo. Se sondeó `ww4` con un GET normal; respondió 403. No se adaptó ni evadió el desafío.
- Una [solicitud comunitaria de fuente Animeflv.one](https://github.com/yuzono/anime-extensions/issues/1278) menciona `vww.animeflv.one`; no es una implementación ni confirma que sea el AnimeFLV incluido en el alcance. La portada y búsqueda GET respondieron HTTP 200 con una coincidencia para One Piece; las fichas públicas de One Piece y Demons' Crest respondieron 200 pero no expusieron rutas de episodio.
- Se inspeccionó la [configuración pública del proyecto Miruro](https://github.com/Miruro-no-kuon/Miruro/blob/main/.env.example) para ubicar su backend. El único request live de esta corrida fue el GET de portada a `miruro.to`, que devolvió 403; no se llamó a APIs de pipe ni a servicios externos de extracción.
- El repositorio público [`anime1v-api`](https://github.com/FxxMorgan/anime1v-api) se describe como un scraper de AnimeAV1.com, tiene licencia MIT y documenta una API que requiere clave; el README también describe automatización anti-bot/Puppeteer. No se ejecutó, no se pidió una clave y no se adaptó ninguna ruta de bypass. Esto no confirma un proveedor independiente llamado AnimeV1.
- Se consultaron la [implementación pública AnimeGG de Yuzono](https://github.com/yuzono/anime-extensions/blob/master/src/en/animegg/src/eu/kanade/tachiyomi/animeextension/en/animegg/AnimeGG.kt) y la [licencia de su repositorio](https://github.com/yuzono/anime-extensions/blob/master/LICENSE) para contrastar el uso público de `Referer`/`videoSources`. El adaptador local no copia código fuente; la guía técnica local documenta la licencia upstream observada (Apache-2.0) y la limitación de la resolución live.
- KickAssAnime: su [FAQ actual](https://kickassanime.es/faq) describe selección de servidor y SUB/DUB, pero no se confirmó que ese dominio `.es` corresponda al proveedor del inventario. El [catálogo de extensiones de Yuzono](https://github.com/mojuru/anime-repo/blob/repo/index.json) registra `kaa.lt`/`kaa.to`; el source de [KickAssAnime en Yuzono](https://github.com/yuzono/anime-extensions/blob/master/src/en/kickassanime/src/eu/kanade/tachiyomi/animeextension/en/kickassanime/KickAssAnime.kt) define `kaa.lt` como primario. En un probe acotado de One Piece episodio 1, búsqueda, detalle, idioma, episodio y servidor CatStream dieron HTTP 200. La página CatStream pública también dio 200, pero el body no contenía el marcador de manifiesto directo ni el marcador `cid` que reconoce el extractor. El extractor upstream calcula firmas y descifra AES para ciertos servidores legacy; no se adaptó ni ejecutó esa lógica. Se conserva `BLOCKED_EXTERNAL` hasta identificar una fuente pública directa que no requiera ese mecanismo.
- La extensión pública de [AnimeKai](https://github.com/aniyomi-addons/animekai-ext) documenta `animekai.to` y mirrors, pero su flujo de video descrito depende de Cloudflare, tokens y un servicio externo; Kongroo no ejecutará ese flujo. El [issue upstream AllAnime #607](https://github.com/yuzono/anime-extensions/issues/607) reportó que páginas de episodio redirigían a `mkissa.to` y activaban Cloudflare; el [cambio histórico #4566](https://github.com/keiyoushi/extensions-source/issues/4566) documentó el cambio previo a `allmanga.to`, sin probar disponibilidad actual.
- La [referencia histórica Henaojara](https://github.com/aniyomiorg/aniyomi-extensions/issues/2309) identifica `www.henaojara.com`; el GET actual devolvió 301 a AnimeJara, redirección que no se siguió. La lista de extensiones consultada señala [Latanime](https://github.com/mojuru/anime-repo/blob/repo/index.json) en `latanime.org`; su GET actual devolvió 403.
- En la continuación del 2026-11-15, Animeflv.one respondió a GETs públicos de portada y búsqueda (`One Piece`); sus fichas de One Piece y Demons' Crest devolvieron HTTP 200, pero cero rutas de episodio detectables. AnimeJara `/catalogo/` devolvió HTTP 403 en una petición pública corriente. No se alteraron agentes ni se reintentó tras la denegación.

## Bloqueos y siguiente trabajo

1. No existe una fuente de episodio actual que haya superado la apertura/decodificación y avance por libmpv. Los tres mirrors de AnimeHeaven llegaron al player y mostraron error sin frame; no repetirlos para este episodio sin evidencia de cambio.
2. AnimeAV1 resuelve catálogo/episodio, pero el host de embed devuelve `unauthorized`; no se intenta superar la denegación.
3. TioAnime enumera cinco alternativas: tres están `unsupported`, una falla con timeout y una entrega URI, pero libmpv no avanza.
4. Ninja y JKAnime están bloqueados por respuestas 403 en solicitudes ordinarias actuales.
5. AnimeJara presentó HTTP 403 en `/catalogo/` con la petición corriente de esta continuación; faltan rutas públicas de anime/episodio confirmadas.
6. El candidato comunitario Animeflv.one permite búsqueda, pero las dos fichas observadas no publicaron rutas de episodio; el dominio original `animeflv.net` no completó transporte (`000`).
7. AnimeGG encontró cinco variantes de idioma/calidad para One Piece episodio 1; son variantes de fuente, no hosts. La variante preferida resolvió a `vidcache.net`; libmpv avanzó 5311 ms y detectó audio, pero no video ni dimensiones. No hay reproducción externa confirmada.
8. KickAssAnime tiene descubrimiento y servidor CatStream públicos, pero su página no expuso una URI o manifiesto estático; no se copió la extracción de firma/descifrado upstream. Queda `BLOCKED_EXTERNAL` bajo las restricciones vigentes.
9. AniZone queda `BLOCKED_EXTERNAL` por los fallos públicos HTTP 404 del manifiesto (Range y GET normal) y 419 de la acción Livewire. CatStream no expuso URI/manifiesto estático. La fuente upstream de FlixCloud requiere token/stream por API y decodificación XOR en proxy local; MegaPlay tiene una etapa crypto reportada. No se ejecutaron esas rutas.
10. FileStream, Bee y Goma no se observaron en las fuentes revisadas; esto no demuestra que no existan en otros episodios.
11. Siete candidatos siguen `INVESTIGATING` sin recorrido completo; AnimeV1 sigue `PENDING` por identidad/dominio sin confirmar. La evidencia parcial tampoco equivale a búsqueda/episodio/servidores/resolución completos.
12. La ficha AniList → identidad del proveedor → selección UI → cambio/fallback → ventana visible no ha sido recorrida con un episodio externo.

No repetir los hosts ya probados salvo evidencia nueva y concreta de disponibilidad. Continuar si una fuente pública de episodio presenta un host distinto o si el acceso cambia de forma verificable; no ampliar catálogos sin ese motivo técnico. La ruta local de `PlaybackSourceSwitchService` ya tiene fallback con fake y cambio libmpv sobre fixture, pero aún falta el recorrido externo. S0 sigue activa; no se declara reproducción ni cierre global y el gate formal G1 continúa pendiente de aceptación del propietario.
