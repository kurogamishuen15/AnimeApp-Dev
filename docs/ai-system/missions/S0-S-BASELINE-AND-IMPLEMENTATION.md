# KONGROO S0-S — línea base y ejecución

**Fecha de inicio:** 2026-11-16
**Estado:** EN CURSO
**Orden:** `KONGROO_S0-S_ARQUITECTURA_FUENTES_HOSTS_2026-11-16.md`
**Alcance:** limpieza del runtime anterior, evolución del sistema existente y verificación de la cadena de playback. No commit ni push.

## Estado Git y alcance protegido

- Raíz confirmada por `git rev-parse --show-toplevel`: `/home/kyouma/Vídeos/PROYECTO ANIME`.
- Rama `main`; al inicio `HEAD` y `origin/main` coincidían en `19470ed6bb19583cc0fc00938c08ab6c2f855300`.
- No había cambios rastreados. Permanecen sin seguimiento y fuera de esta misión `.codex-attachments/` y `KONGROO_RECONSTRUCCION_CODEX_T00-T24.zip`; se conservan sin inspeccionar su contenido.
- No se hizo `git add`, commit, push, reset ni limpieza general.

## Línea base del reproductor antes de cambios de proveedores

No se modificaron `media_kit`, libmpv, el engine, la UI del reproductor ni sus dependencias en esta misión.

| Verificación | Resultado observado | Límite |
|---|---|---|
| Suite `test/player` | 120 aprobadas, 3 omitidas | Incluye controles, ruta, fullscreen, teclado, cierre de ventana y regresiones nativas automatizadas. |
| Integración `media_kit_spike_integration_test.dart` | 14 aprobadas, 2 omitidas | Casos automatizados locales; no sustituye ver la reproducción en una ventana real. |
| 20 ciclos nativos de abrir/detener/disponer | RSS aproximado: 245–247 MB antes, pico 389–392 MB, 371–372 MB después de dispose | Crecimiento observado, no prueba de fuga. |
| `player_performance_integration_test.dart` | 1 aprobada; RSS 353.6–355.0 MB | El test no monta `VideoController`/VO: FPS de salida, drops y sincronía A/V son `null`; no es una medición visual de reproducción. |
| Fixture real local | Theora 534×300 a 25 fps, Vorbis y 3 pistas SRT | Resultado de `ffprobe`; no reproduce una fuente externa. |
| Ventana Wayland | Se abrió el target correcto `main_player_spike.dart`; Spectacle capturó un frame sintético visible y pausado | No se verificó movimiento ni audio. Wayland MCP devolvió `Transport closed`. El proceso del spike terminó mediante señal dirigida porque la sesión de Flutter tenía stdin cerrado; esto no prueba cierre gráfico limpio. |
| mpv CLI | No está instalado/disponible en `PATH` | No se instaló nada ni se modificó Fedora. El A/B mpv/libmpv queda pendiente. |

El host reportó 8 CPU lógicas y 8,041,324,544 bytes de RAM total (aprox. 7.5 GiB); **no es el equipo objetivo de 4 GB**. Hubo avisos de Fontconfig por falta de caché escribible; las pruebas pasaron y no se alteró configuración del sistema.

La primera ejecución de `run_f2_2_spike.sh` reutilizó un bundle release de la aplicación de catálogo, no el spike. Su captura está identificada localmente como inválida y no forma parte de la evidencia aprobatoria. La segunda ejecución especificó el target Flutter correcto y produjo la captura `.ai-local/review/s0s-player-baseline-2026-11-16/spike-window.png`.

## Revisión de implementaciones y referencias

El estado inicial tenía un único provider externo activo, AnimeHeaven, y su resolver MP4 bajo el propio módulo. Los registros previos documentan tres mirrors que alcanzaron libmpv pero no produjeron frame. AnimeAV1, TioAnime, AnimeGG, Miruro, AnimeOnline Ninja y `video_hosts` solo conservaban README históricos en sus carpetas; los adaptadores retirados no estaban en el runtime. El manager, sus contratos, circuit breaker, `PlaybackSourceSwitchService`, la ruta y el único engine son piezas compartidas conservables.

Revisión upstream primaria del 2026-11-16:

| Referencia | Patrón útil | Decisión de adaptación |
|---|---|---|
| [Anilili](https://github.com/sanilili/Anilili) | Separación entre catálogo/provider, selección de host y Media3; licencia MIT-0 declarada en el repositorio. | Tomar el límite arquitectónico como referencia. No portar rutas antiguas de Miruro ni Android al core Dart. |
| [Zangetsu Providers](https://github.com/Spyou/zangetsu-providers) | Manifiesto con ID estable, versión, tipo e idioma; extractores de host independientes. El README actual reclama MIT, pero en la raíz consultada no apareció un archivo `LICENSE`. | Adoptar versionado y registro estático. No se copia código mientras la licencia no pueda confirmarse en un archivo de licencia. |
| [anime-sh](https://github.com/Anime123450/anime-sh) | Separa providers y resolvers y entrega medios a mpv; el proyecto declara MIT. | Usar el patrón de capas y fallback; no copiar código. |
| [anipy-cli](https://github.com/sdaqo/anipy-cli) y [ani-cli](https://github.com/pystardust/ani-cli) | API/CLI y selección separadas del reproductor; ambos declaran GPL-3.0. | Referencia conceptual; no copiar código ni importar dependencias. |
| [GoAnime](https://github.com/alvarorichard/GoAnime) | Fuentes múltiples, health checks y reproducción con un proceso mpv. | Referencia de selección y tests; no copiar código. |

Estas páginas prueban la estructura y las declaraciones de licencia visibles en cada repositorio, no la disponibilidad actual de sus proveedores ni reproducción en Kongroo. Para Zangetsu, la ausencia de `LICENSE` en el árbol consultado mantiene la reutilización de código en espera. Las implementaciones serán Dart estático; no se ejecutará código de terceros.

## Criterios y estado de S0-S

| Criterio | Estado | Evidencia faltante / próximo paso |
|---|---|---|
| Línea base y protección del player | PARCIAL | A/B del mismo medio externo con mpv CLI y Kongroo; audio y movimiento en ventana; medición en equipo de 4 GB. |
| Retirada de runtime obsoleto | IMPLEMENTADO | AnimeHeaven Dart/runtime/tests/harness retirados; READMEs/evidencias archivados; engine y regresiones genéricas preservados. |
| Contratos de identidad, episodio, candidato, resolver y fuente reproducible | IMPLEMENTADO | `AnimeIdentity`, `SourceAnimeMatch`, `EpisodeRef`, bridge de `EpisodeSourceAdapter`, `SourceCandidate`, `PlayableSource`; pruebas offline. |
| Registro, caché, versiones y circuitos | IMPLEMENTADO | Manager único; versiones SemVer, caché LRU de 128 fuentes acotada por TTL/expiración y mapa LRU de 128 breakers de hostname; circuitos de provider/hostname con tests. La expulsión puede descartar historial de fallos cerrado/vencido. |
| Resolver directo y límites de red | PARCIAL | Normaliza HTTPS MP4/HLS/DASH y rechaza destinos literales locales/privados; no hace lookup DNS, GET ni valida redirects. |
| Adaptadores de plataforma Linux/Android/Windows | PARCIAL | Dominio/application y contratos son neutrales; resolver usa solo `dart:io` estándar para IP literal. Linux probado; Android/Windows sin build. |
| Fuente externa técnica en libmpv | PARCIAL | HLS público de prueba abrió, reportó duración 634584 ms y posición 2038 ms con pistas H.264/dimensiones nulas. Sin ventana/frame/audio observados; no es episodio. |
| Provider de anime y recorrido ficha→episodio→fuente→player | PARCIAL | AnimesDigital v1.0.0 registrado y One Piece ep. 1180/HLS/segmento resueltos; la ventana real presentó error de decodificación y no mostró video. La integración de ficha y regreso no se acreditó. |
| Fallback entre hosts externos | PARCIAL | El manager pasa tests deterministas de fallback; no hay alternativas externas reproducidas y no se confirma un segundo host para este episodio. |
| Auditoría, memoria y documentación sincronizada | EN CURSO | README/STATUS/HANDOFF se sincronizarán con la auditoría, el análisis y los resultados finales de esta ejecución. |

## Actualización de implementación S0-S — 2026-11-16

En el primer corte de S0-S, se completó la limpieza controlada de runtime y se
conservaron pruebas e informes como archivo histórico. El único resolver
registrado era `DirectMediaHostResolver`: no es un parser de host ni un provider
de episodios. El manager permanecía como coordinador único y el motor no cambió.
Una actualización posterior añadió AnimesDigital; su evidencia está debajo.

El smoke HLS usa un provider sintético solo dentro de la prueba opt-in. GET
normal del manifiesto devolvió HTTP 200 (`audio/mpegurl`, 752 bytes); a través
del manager y el resolver, libmpv avanzó de `0` a `2038 ms`, informó duración
`634584 ms` y cinco pistas H.264 con ancho/alto `null`. No se observó superficie
gráfica, audio ni primer cuadro; Wayland MCP devolvió `Transport closed`. Es
evidencia de transporte y avance técnico, no un resultado de S0 de anime.

La lectura del endpoint usa HTTPS público de prueba, sin Range, cookies,
credenciales ni redirects. La política local rechaza IPs privadas/locales
literales y puertos no estándar, pero no resuelve DNS ni evita rebinding/TOCTOU.
Faltan comparación mpv CLI (binario no disponible), builds Android/Windows,
prueba sobre el equipo de 4 GB, medición CPU/RAM durante el stream, y el recorrido
completo desde ficha hasta retorno. La prueba anterior de la suite completa
antes del límite de breakers pasó 282 tests y omitió 7 optativos; el resultado
final posterior a ese cambio se registrará cuando concluya la corrida actual.
S0-S permanece parcial.

## Primer corte — AnimesDigital live — 2026-11-16

Se implementó `AnimesDigitalPlaybackProvider` como `EpisodeSourceAdapter`
modular y se registró v1.0.0 en `PlaybackProvidersModule`, junto al resolver
reutilizable `DirectMediaHostResolver`. No se añadieron dependencias. El
provider conserva matching por título exacto, consulta páginas en orden, limita
bytes/redirects/tiempos y solo acepta el player público que expone HLS directo.
No sigue embeds alternativos, ejecuta JavaScript ni usa cookies, credenciales o
desafíos. La documentación del módulo está en
[`app/lib/data/player/providers/animesdigital/README.md`](../../../app/lib/data/player/providers/animesdigital/README.md).

### Evidencia de red y media

El harness Dart normal, sin `flutter_test` (que intercepta HTTP), resolvió One
Piece episodio 1180 mediante el manager. GET ordinario del manifiesto HLS:
HTTP 200, `application/vnd.apple.mpegurl`, 4,998 bytes y 142 entradas de
segmento. GET del primer segmento con el Referer público documentado: HTTP 200,
67,258 bytes leídos; la firma fue MPEG-TS y no HTML. El host reportado fue
`cdn-s01.mywallpaper-4k-image.net`. No se guardaron la URL completa ni datos
firmados. Esto valida catálogo→source candidate→normalizador→respuesta HTTP,
no reproducción.

### Prueba en ventana real

`app/tool/animesdigital_live_player_app.dart` montó `SpikePlayerPage`,
`MediaKitVideoSurface`, `SpikePlayerCoordinator` y `MediaKitSpikeEngine` antes
de invocar `open/play`. `Player.open()` completó; libmpv informó metadatos,
duración 1,415,808 ms y pistas de audio/video. La captura de la ventana real
`.ai-local/review/animesdigital-live-player-current.png` mostró fondo negro y
el error “The media could not be opened or decoded.” La posición aumentó, pero
no se observó un cuadro válido ni audio. Resultado: fuente/respuesta HTTP
accesibles, **0 reproducciones externas confirmadas**. No declarar este host
funcional.

El primer intento montó el engine y esperó a que `Player.open()` concluyera
antes de montar la superficie; no terminó en más de 2 minutos y se cerró
manualmente. El segundo harness montó la superficie antes y `open()` completó,
pero se mantuvo el error de decodificación. Es evidencia de que el orden de
montaje cambia el resultado de `open()` en este harness, no prueba de que sea
la causa del error de video. La ruta productiva actual devuelve el módulo tras
`coordinator.open()` y `ProviderPlaybackRoute` monta su widget después. Debe
validarse con una regresión de ruta controlada antes de modificar el player.

### Verificación ejecutada en esta actualización

- `dart format` en código nuevo/afectado: pasó; formateó 2 archivos.
- Suite focalizada de provider/parser, manager/cache, host resolver, módulo y
  contratos: **48/48 pasaron**.
- Análisis Dart focalizado: primera ejecución encontró un único info
  `cancel_subscriptions` en el harness; la suscripción se transfiere a la app y
  se cancela en `dispose()`. Se ajustó el comentario de lint y falta repetir el
  análisis.
- Aún faltan `flutter analyze`, análisis Dart final, suite Flutter completa,
  CI/checker de imports, memoria, y la auditoría escrita de S0-S.
- Sin medición nueva de CPU/RAM, estabilidad o fugas del provider/stream. El
  host de prueba tiene 7.5 GiB; el equipo objetivo de 4 GB no está disponible en
  la evidencia de esta ejecución. Android y Windows no se compilaron.

## Investigación de rutas públicas y límites observados — 2026-11-16

Se consultaron implementaciones primarias de [GoAnime](https://github.com/alvarorichard/GoAnime),
[AnimeFire API](https://github.com/alvarorichard/GoAnime/blob/main/internal/scraper/providers/animefire/api.go),
[AnimeDrive](https://github.com/alvarorichard/GoAnime/blob/main/internal/scraper/providers/animedrive/client.go),
la [guía de proveedores](https://github.com/alvarorichard/GoAnime/blob/main/docs/ADDING_A_SOURCE.md)
y la [guía de streaming de AniKotoAPI](https://github.com/Shineii86/AniKotoAPI/blob/main/docs/streaming.md).
No se copió código.

| Candidato | Evidencia live o upstream | Decisión de esta ejecución |
|---|---|---|
| AnimeFire mediante GoAnime | GET ordinario `https://api.animefire.one/animes/pesquisar?q=One%20Piece&v=3` devolvió HTTP 403. El README upstream explica su ruta de búsqueda/episodio/stream, pero no prueba que esa API acepte Kongroo. | No reintentar con cookies, headers de impersonación, challenge ni mecanismos de evasión; no registrar adapter sin acceso ordinario comprobado. |
| AnimeDrive mediante GoAnime | GET de búsqueda del catálogo devolvió HTTP 200 y encontró One Piece; la ficha devolvió HTTP 200 con 539 bloques de episodios; la página pública del episodio 1022-5 devolvió HTTP 200 y publicó una etiqueta `<video>/<source>` MP4 en `mangas.cloud`. Las dos solicitudes de disponibilidad del MP4 con `Range` (una con referer de catálogo y otra con referer exacto de la página) devolvieron HTTP 403 HTML de Cloudflare. | Es un catálogo y enlace observados, no una fuente multimedia comprobada. No se registró una URL efímera ni se implementó código que falle al primer paso del host. No se intentó superar el control. |
| AnivexaAPI | La ruta pública consultada devolvió HTTP 402 Payment Required; la metadata consultada no declara licencia de código. | No integrar ni copiar. Clasificada como servicio inaccesible en la prueba actual, sin inferir que todas sus rutas estén caídas. |
| AniKotoAPI | La guía propia indica bloqueo de sus pasos AJAX/resolución bajo Cloudflare y ofrece modalidad iframe/WebView. | No es una ruta native-media equivalente al contrato actual; requiere un adaptador WebView independiente con contrato de plataforma y no se añadió en S0-S. |
| Zangetsu Providers | README del repositorio declara MIT; no se observó un `LICENSE` en la raíz consultada. | Se corrige la atribución previa a GPL-3.0. No se reutiliza código hasta verificar la licencia en texto de licencia explícito. |

En el corte de esos probes aún no se había registrado un `AnimeProvider`
externo; la integración posterior de AnimesDigital se documenta arriba y abajo.
Los GET 403/402 son evidencia de los recursos y rutas probados en esa fecha; no
son evidencia de inexistencia de otros endpoints. Siguiente investigación:
seleccionar una ruta documentada y hacer solo requests ordinarias; ante bloqueo,
detener esa ruta y pasar a una alternativa distinta.

Una revisión posterior de la [guía de proveedores de GoAnime](https://github.com/alvarorichard/GoAnime/blob/main/docs/ADDING_A_SOURCE.md)
confirma un patrón de cliente hoja separado del registro, descriptor,
health checks y pruebas; el README del [repositorio GoAnime](https://github.com/alvarorichard/GoAnime)
documenta búsqueda multi-source con fallback y uso de mpv. Se toma como
referencia de modularidad y verificación, sin portar código Go ni declarar sus
fuentes operativas en Kongroo.

## Auditoría y verificación post-fix — 2026-11-16

### Integración observada

El código conecta AniList identity/aliases→episodio de proveedor→candidato
AnimesDigital→`PlaybackProviderManager`/`DirectMediaHostResolver`→selector de
fuente→`ProviderPlaybackRoute`→engine media_kit/libmpv existente. La ficha crea
`PlaybackEpisode`; `CatalogHomePage` consulta el manager, abre el selector y
empuja la ruta de playback. La interacción visual real desde ficha y el regreso
no se probaron; el harness de video abrió directamente el player.

La lista allowlisted de media se limita al hostname observado
`cdn-s01.mywallpaper-4k-image.net`. AnimesDigital conserva idioma `unknown`, no
ejecuta JS ni usa cookies/challenges, y TTL de fuente cero. No se añaden
dependencias. El motor, la presentación y la UI del player permanecen intactos.

### Evidencia live de dos episodios

| Episodio | Manifiesto | Primer segmento | Resultado en ventana |
|---|---|---|---|
| One Piece 1180 | 200, 4,998 B, 142 segmentos | 200, 67,258 B, firma MPEG-TS | Negro y error “The media could not be opened or decoded”; no frame confirmado. |
| One Piece 1 | 200, 5,313 B, 151 segmentos | 200, 69,756 B, respuesta TS | UI mostró 00:12/25:00, negro y error de decodificación; no se confirmó pista de video/frame. |

Capturas locales ignoradas por Git:
`.ai-local/review/animesdigital-live-player-current.png` y
`.ai-local/review/animesdigital-live-player-episode-1.png`. HTTP 200, duración,
posición y eventos nativos no cuentan como reproducción. No se guardó URI
firmada ni log nativo que identifique codec/demux. No se atribuye causa a la
red, al medio, a las cabeceras ni al engine.

### Fixes y revisión de código

- El adapter conserva límite individual de 2 MiB HTML, límite total 16 MiB,
  máximo 32 páginas, redirects same-origin y cancelación.
- Una revisión independiente detectó que el timeout de 20 s se reiniciaba por
  petición, por lo que aliases/paginación podían alargar una operación. Ahora
  `searchAnime`, lectura de episodios y lookup de fuentes comparten un
  `_OperationDeadline` de 20 s; la prueba loopback de búsquedas lentas confirma
  `timeout` antes de continuar. Test AnimesDigital focalizado: 7/7.
- La misma revisión comprobó la clave `requestKey` encuadrada con longitudes y
  conteo (test de títulos que incluyen separadores) y el filtro del parser que
  omite campos HTML >256 caracteres. No ejecutó pruebas; la verificación se
  hizo en este turno.
- El allowlist reduce candidatos arbitrarios, pero DNS, redirects del media
  server y URI descendientes de playlist/segmentos no están validados antes de
  que libmpv los consuma. Es riesgo condicionado, no explotación demostrada.
- Orden de montaje distinto entre `ProviderPlaybackRoute` y harness: posible
  riesgo de arranque, aún no se aisló con un test de ruta. No cambiar engine por
  correlación no probada.

### Verificación

- Última suite Flutter completa: **300 aprobadas, 7 optativas omitidas**, exit
  0 con el SDK aislado. Esta última salida quedó en consola, no en archivo; el
  log `.ai-local/review/s0s-final-flutter-suite-2026-11-16.log` conserva la
  ejecución anterior de 297/7.
- `dart analyze lib test tool`: sin issues. `flutter analyze --no-pub`: sin
  issues. Flutter Linux debug build: exit 0.
- Formato: 192 archivos revisados, cero cambios. Checker de imports: 31 archivos
  player y 36 domain válidos. Pruebas del checker: dos positivas y doce
  negativas. Suite Python IA: 40 aprobadas. `pkg-config` GTK disponible.
- `scripts/ci.sh` no se ejecutó porque invoca `flutter pub get`; no se
  modificaron manifiesto/lock ni se añadieron paquetes. Las pruebas, análisis,
  checker, formato y build relevantes se ejecutaron por separado.
- `python3 tools/ai/memory.py check` devolvió `[]` y `git diff --check` terminó
  con exit 0 después de la actualización. El escaneo de archivos nuevos
  encontró solo tres finales intencionales de dos espacios de Markdown en el
  baseline, usados como hard breaks; no encontró whitespace accidental en
  código/tests/auditoría.

### Estado de criterios S0-S

| Criterio | Estado a 2026-11-16 | Evidencia faltante |
|---|---|---|
| Limpieza y contratos separados | Implementado; pruebas offline | Revisión futura si se agrega otro adapter/host. |
| Fuente candidata→resolutor→player | Cableado; protocolo HTTP live observado | Imagen externa no decodificada ni mostrada. |
| Reproducción visible y player estable | Bloqueado; no se confirma episodio externo | Frame/dimensiones/avance visual/audio/cierre. |
| A/B en mpv externo | Pendiente | mpv CLI no está disponible; no se instaló. |
| Click de ficha y retorno | Código conectado; app normal abierta visualmente en Home | La captura `.ai-local/review/s0s-real-ui-home.png` confirma el Home, pero Wayland devolvió `Transport closed`; `xdotool` no encontró la ventana y `ydotool` no tenía daemon. Falta ficha→episodio→selector→player→retorno. |
| Segunda alternativa y fallback real | Pendiente | No hay dos fuentes externas reproducidas. |
| Linux/Android/Windows | Linux build probado | Builds/contratos de ejecución Android y Windows. |
| Recursos y equipo de 4 GB | Pendiente | CPU/RAM/estabilidad durante stream en ese equipo. |
| SSRF de destinos descendientes | Riesgo condicionado | Validación DNS/redirect/playlist/segmentos con negativos. |

La misión continúa `PARTIAL`; no hay fundamento para declarar el provider
`verified_video` ni cerrar S0-S. Ver la [auditoría S0-S](../audits/S0S-audit-2026-11-16.md),
[STATUS](KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](KONGROO-RECONSTRUCTION-HANDOFF.md).

## Continuación diagnóstica del HLS — 2026-11-16

Se habilitó en el harness una salida de error de `ffprobe` con URLs redactadas
y un resumen de extensiones URI del manifiesto; el cambio está limitado a
`app/tool/animesdigital_live_harness.dart`. En una ejecución que alcanzó el
manifiesto de One Piece ep. 1, `ffprobe` terminó con error porque libavformat
rechazó una referencia `.webp` mediante `allowed_segment_extensions`; también
apareció una referencia `.m3u8`. El probe HTTP confirmó manifiesto 200, 151
entradas y primer segmento TS 200. Una siguiente llamada al provider terminó
`timeout`, de modo que no se volvió a identificar el manifiesto.

Esta es evidencia de rechazo de una referencia por ffprobe, no un log de libmpv
ni una explicación confirmada de las capturas negras. No se modificó el motor,
no se relajaron extensiones/protocolos y no se guardaron manifiestos o URLs. La
extensión podría corresponder a metadata auxiliar o a otra referencia
relevante; el tag HLS exacto sigue sin evidencia. Debe confirmarse con una
fuente vigente y una allowlist estrecha antes de proponer una opción por
provider. `dart analyze` del harness/test pasó y la prueba offline del resumen y
redacción pasó 3/3; la petición live posterior agotó su timeout y no cuenta
como playback.

La suite completa más reciente repitió los 20 ciclos nativos sobre el fixture
local: RSS del proceso 245,678,080 bytes antes, pico 390,635,520 y
371,400,704 después de dispose. La prueba de performance reportó muestras de
355,278,848–356,700,160 bytes, con video/FPS/drops nulos y solo audio Vorbis.
Esto no mide streaming externo ni demuestra una fuga, y el host sigue siendo de
7.5 GiB. La corrida también imprimió advertencias de Fontconfig por falta de
caché escribible en `/var/cache/fontconfig`; las pruebas pasaron y no se cambió
ninguna configuración del sistema.
