# Progreso de AnimeApp

Fuente viva del estado de fases. Actualizar al terminar o bloquear una subfase; el plan no equivale a implementación.

Estados: Pendiente, En desarrollo, Completado, Bloqueado, Requiere revisión.

## Kongroo OC-04 — alternativa ante HTTP 403 — 2026-11-17

La denegación 403 del origen Miruro permanece sin resolver. Un cliente no puede
convertirla legítimamente en acceso autorizado: RFC 9110 la define como rechazo
del servidor y Cloudflare documenta políticas de origen/WAF/IP como causas
posibles, sin que la respuesta observada permita saber cuál aplica. No se
repitió la solicitud bloqueada ni se añadieron cookies, tokens, huellas,
proxies, mirrors o reintentos de evasión.

Quedó preparada una alternativa de uso: la ficha solicita los enlaces
`streamingEpisodes` públicos de AniList, valida que sean HTTPS sin credenciales,
los muestra como páginas externas y permite copiar el enlace. Estos enlaces no
son medios directos y no se envían a libmpv. Además, una prueba confirma que el
manager puede continuar a un segundo provider registrado después de un 403; esto
no demuestra que haya un provider alterno real habilitado para ese anime.

Verificación de esta ejecución: pruebas focalizadas **47/47**, `flutter analyze`
sin issues y build Linux debug aprobados. La suite completa dio **336 aprobadas,
10 omitidas y 2 timeouts** en pruebas nativas de libmpv; cada timeout pasó al
repetirse por separado. No se tocó el reproductor. No hubo prueba live de
AniList, interacción manual ni reproducción externa durante OC-04: Miruro y su
fallback para AniList 100240 siguen en **0 fuentes confirmadas**. Wikimedia
conserva evidencia histórica opt-in de Namakura Gatana, que no valida este
flujo. Android/Windows y rendimiento en el equipo de 4 GB siguen sin validar. La
respuesta del origen y reproducción en la app requieren que el servicio autorice
solicitudes ordinarias o que exista otro provider público compatible. Ver
[auditoría OC-04](docs/ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md).
No commit ni push.

Anexo de investigación: el DoH de Anilili atiende ausencia/sinkhole de DNS;
MiruroCatalogApi se detiene en 4xx, también al recibir 403. El manejo Cloudflare
aparte usa emulación de identidad web y clearance de WebView; no se portó por la
restricción contra evadir challenges. Kongroo ya tiene sus orígenes configurados.
Sin autorización del operador, el 403 sigue bloqueando el flujo Miruro.

## Kongroo OC-03 — migración de providers basada en Anilili — 2026-11-17

Se retiraron del runtime los adaptadores y perfiles experimentales anteriores
de AnimeAV1, TioAnime, AnimeGG, AnimeHeaven, AnimeOnline Ninja, AnimesDigital,
MP4Upload y YourUpload. Se preservaron `PlaybackProviderManager`,
`PlaybackSourceSwitchService`, los contratos source/episode, y el único player
`media_kit/libmpv`. El nuevo `MiruroCatalogPlaybackProvider` consulta por AniList
ID, descubre episodios/fuentes directas y pasa al normalizador compartido
`DirectMediaHostResolver`; Wikimedia y `user_sources` siguen opt-in.

Los tests del provider cubren parser, paginación, límites de memoria, grouping de
calidad, errores, cancelación y denegación. La suite focalizada pasó **62/62**;
la suite completa pasó **334** y omitió **10** pruebas live opt-in. `flutter
analyze --no-pub` terminó sin issues y `flutter build linux --debug --no-pub`
compiló. La Home abrió en Fedora y su primer frame quedó capturado en el archivo
local ignorado `.ai-local/review/oc03-home.png`; el backend de entrada Wayland no
estuvo disponible, así que no se afirma interacción gráfica completa.

La evidencia live anterior de Miruro da HTTP 403 en configuración/lookup para
AniList 100240 antes de obtener episodios o media. No se evadió ni se repitió
la denegación. No se confirma reproducción externa de anime (**0 servidores**).
Android/Windows, playback de episodio, RAM/CPU del stream y pruebas en el equipo
de 4 GB siguen pendientes; el build Linux y los tests locales no cubren esos
criterios. El log de regresión de 20 aperturas locales informó RSS 251,928,576 B
antes, 396,959,744 B pico tras Stop y 377,868,288 B después de dispose; es una
prueba local del engine, no perfilado de la app ni evidencia para inferir fuga o
ausencia de fugas. Sin commit ni push.

Ver [auditoría de migración](docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md),
[READMEs de providers](app/lib/data/player/providers/README.md) y
[procedencia MIT-0](docs/third-party/ANILILI-MIT-0.md).

## Historial — Kongroo S0-S source-first / host-first — 2026-11-16

La limpieza de runtime terminó y se archivaron READMEs/evidencias anteriores.
El root ahora registra `AnimesDigitalPlaybackProvider` v1.0.0 como candidato,
un `DirectMediaHostResolver` común y el manager existente con cache/breakers
acotados. La búsqueda exacta encontró One Piece, el episodio 1180 y un HLS
público. GET ordinario validó manifiesto 200/4998 bytes (142 segmentos) y el
primer segmento TS 200/67258 bytes.

La ejecución gráfica real con la UI y engine existentes abrió el medio y
reportó metadatos/pistas, pero las capturas de One Piece episodios 1180 y 1
mostraron pantalla negra y “The media could not be opened or decoded.” No se
acreditan video visible, audio ni reproducción funcional. `AnimesDigital`
permanece candidato; S0-S sigue parcial. El código conecta la ficha, su episodio,
el manager, selector y `ProviderPlaybackRoute`; falta validar con interacción
gráfica real el clic y retorno. La ruta productiva espera `Player.open()` antes
de montar su superficie, mientras el harness la monta primero; una regresión
debe aislar si esa diferencia explica el fallo antes de tocar el engine.

La prueba focalizada de AnimesDigital pasó 7/7. La suite Flutter completa más
reciente pasó 300 pruebas y omitió 7 optativas. Dart analyze (`lib test tool`) y
Flutter analyze (`--no-pub`) no reportaron problemas. La revisión independiente
confirmó varias correcciones y encontró que el límite de 20 s se renovaba por
solicitud; ahora es un presupuesto compartido por operación, cubierto por un
test lento. Engine/UI y dependencias del player no se modificaron. Linux es lo
único probado; Android/Windows, streaming en equipo de 4 GB y CPU/RAM del stream
siguen pendientes. Una corrida `ffprobe` observó una referencia HLS `.webp`
rechazada por el filtro de extensiones; esto no se confirmó como causa del error
de libmpv. La siguiente petición del provider terminó en timeout. No se amplió
el filtro. Las pruebas offline nuevas del diagnóstico pasaron 3/3; la suite
completa más reciente pasó 300/7. No hay commit ni push. Ver [informe y baseline](docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md), [STATUS](docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md), [HANDOFF](docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md) y [auditoría](docs/ai-system/audits/S0S-audit-2026-11-16.md).

## Historial — Kongroo S0-R AnimeHeaven — 2026-11-16

Se integró un provider AnimeHeaven y resolver MP4 en el composition root
existente, sin agregar dependencias ni un segundo reproductor. One Piece ep. 1
recorrió búsqueda, episodio, alternativas y la ruta real del player. Los mirrors
`cx`, `ct` y `ck` llegaron a libmpv por separado, pero todos mostraron error de
decodificación y ningún frame. Estado: **1 implementado, 0 reproducibles,
0/70**; S0 no está cerrada. Pasan 13 tests
focalizados y 48 regresiones de provider/manager/route; Flutter analyze completo
y Dart analyze focalizado. Capturas en
`.ai-local/review/s0r-animeheaven-visible.png`,
`s0r-animeheaven-mirror-switch.png`, `s0-animeheaven-mirror-cx.png` y
`s0-animeheaven-mirror-ck.png`. El propietario respondió «Autorizar manualmente
en KDE»; después la captura ya no mostró el diálogo, aunque Wayland MCP siguió
con `Transport closed`. No se simuló entrada y los mirrors se eligieron por ID
de entorno. No se midió rendimiento del provider ni del stream; la línea base
existente es de 7.5 GiB, no del objetivo de 4 GB. No repetir estos mirrors sin
evidencia nueva.
Sin staging, commit ni push. Ver [informe S0](docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md), [STATUS](docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y [HANDOFF](docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

## Historial — Kongroo limpieza posterior a S0-A — 2026-11-15

Se retiraron del runtime el adapter Miruro, su transporte Dio y el resolver
directo HLS/MP4 porque los GET públicos devolvieron HTTP 403 y no se obtuvo
episodio, media ni reproducción. El composition root vuelve a crear un manager
sin providers/resolvers concretos. Se conservaron contratos, manager, source
switch, player media_kit/libmpv, documentación histórica, logs y pruebas fuente
archivadas `.dart.txt`. Pasaron 24 pruebas focalizadas y la suite Flutter
completa (268 pass, 6 optativas omitidas), Flutter/Dart analyze, 40 pruebas
Python, checker, formato y memoria. La prueba de composición confirma que no se
registran adapters externos. S0 continúa incompleta, playback externo `0/70`,
G1/T03 sin aceptación y F1 sin iniciar. Ver la
[auditoría de seguimiento](docs/ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md).

## Historial — S0-A: port de catálogo Miruro — 2026-11-15

Se agregó `MiruroPlaybackProvider` y `MiruroDirectMediaResolver` bajo el
composition root existente; no se creó otro reproductor. El mapping está
preparado para AniList ID → título Miruro → episodio → alternativas directas
HLS/MP4, con embeds clasificados como no reproducibles internamente. El
endpoint público de config y el lookup AniList respondieron 403; el smoke real
con Dio clasificó el bloqueo como `unauthorized`. No se obtuvo capítulo ni
fuente reproducible. **S0 sigue incompleta y playback externo queda en 0/70.**
Anivexa no está conectado.

El resolver usa HTTPS, no sigue redirects, acota DNS a 3 s y rechaza direcciones
no globales, incluyendo prefijos IPv6 especiales según IANA. Queda el riesgo
TOCTOU porque libmpv vuelve a resolver el host; no se validó ningún manifiesto
HLS por GET ni se abrió la UI con media externo. Tampoco se midió RAM/CPU,
arranque o fugas de este flujo en Fedora de 4 GB. No se usaron cookies, auth,
huella de navegador, CAPTCHA ni mecanismo para cambiar una respuesta 403.

Con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislado, la última `scripts/ci.sh`
terminó exit 0: 40 Python, 288 Flutter, 7 optativas omitidas; Flutter/Dart
analyze, formato, checker de imports y memoria pasaron. Los tests nativos del
player usan medios locales y no prueban esta integración externa. Ver [informe
S0-A](docs/ai-system/missions/S0-ANILILI-PORT-REPORT.md), [auditoría
profunda](docs/ai-system/audits/S0-ANILILI-port-audit-2026-11-15.md),
[STATUS](docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

## Historial S0 — limpieza previa de providers — 2026-11-15

S0 sigue incompleta; por la instrucción más reciente, el trabajo de providers
queda **en pausa tras la limpieza**, pendiente del siguiente prompt de
integración. G1/T03 conserva su estado formal `AUDITING`. El inventario
histórico contiene 22 candidatos, pero la app ahora registra **cero providers
externos y cero resolutores concretos**. Las implementaciones AnimeAV1,
TioAnime, AnimeGG, el resolver estático y su transporte se retiraron porque no
confirmaron reproducción externa. La arquitectura genérica, el manager, los
contratos y el único engine se mantienen. Playback externo sigue en **0/70**;
no se declara S0 completada.

En el trabajo previo, TioAnime declaró `sourceAlternatives` y se corrigió el
breaker del manager para no abrirse tras fallos de espejos dentro de una sola
operación. El manager pudo probar un cuarto servidor sano después de tres
fallidos en su regresión. La arquitectura conserva separados `AnimeProvider`,
`VideoHostResolver` y `PlaybackEngine` media_kit. Las corridas live previas de
TioAnime, AnimeAV1, AnimeGG y AniZone no confirmaron video:
AnimeGG avanzó 5311 ms y detectó audio, pero no dimensiones de video; otros
hosts dieron `unsupported`, timeout, error de red, `unauthorized`, 404 o 419.
Las cinco variantes de AnimeGG son idioma/calidad, no cinco servidores.
KickAssAnime
`kaa.lt` respondió búsqueda, episodio y servidor CatStream, pero la página de
player no expuso manifiesto ni URI estática; no se adaptó la firma/AES upstream.
ReAnime/FlixCloud y 2DHive/MegaPlay figuran en el inventario; sus pasos crypto
no se ejecutaron ni adaptaron. FileStream/Bee/Goma no aparecieron en fuentes
revisadas.
Ninja, JKAnime, AnimeJara y Latanime devolvieron 403. AnimeKai no resolvió sus
mirrors; AllAnime reporta Cloudflare en episodio; Animeflv.one no publicó rutas
de episodio y no se atribuye a AnimeFLV; Henaojara redirigió a AnimeJara. Detalles y
matriz por proveedor: [informe S0](docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md),
[auditoría S0](docs/ai-system/audits/S0-provider-audit-2026-11-15.md),
[STATUS](docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md),
[HANDOFF](docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

Antes de la limpieza, con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislados, pasaron
41 pruebas contratos/resolver, 35 route/coordinator y la integración local
Referer/libmpv 1/1; analyze pasó y dos smokes live fallaron sin video. Son
resultados históricos del código ya retirado. Después de la limpieza pasaron
`flutter analyze --no-pub`, `dart analyze lib test` y la suite Flutter completa
`flutter test --no-pub` (267 pass, 6 optativas omitidas), con ese mismo SDK
aislado. La prueba del composition root confirma cero providers registrados.
El detalle de archivos y los límites constan en la
[auditoría de limpieza](docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md).

## Reconstrucción Kongroo — Bloque A (T00–T03), reevaluación 2026-11-15

| Tarea | Estado | Evidencia |
| --- | --- | --- |
| T00 — Inventario y estado Git | DONE | Rama `main`, base `33ceaef5b996c55577524c3448bbb4bee5363952`; checkout y grafo registrados en [auditoría A](docs/ai-system/audits/KONGROO-reconstruction-A-2026-11-15.md). |
| T01 — Fallos de apertura | DONE | La búsqueda actual en `app/lib` no encuentra la frase reportada. Su origen histórico sigue `UNATTRIBUTED / NOT_REPRODUCED`; se documentó la falta de bundle/log original, sin atribuirlo ni llamarlo corregido. |
| T02 — CI y límites | DONE | `SpikePlayerPage` recibe opciones tipadas; panel player no importa `data`/`dart:io`. CI y checker pasan con Flutter 3.47.9 aislado. |
| T03 — Modularidad y lifecycle | Requiere revisión | Cancelación cooperativa, cierre tardío supervisado, limpieza auxiliar diferenciada y traducción de lease en el composition root; se conserva un único Player/VideoController. Pruebas focalizadas y CI pasan; aceptación final del propietario pendiente. |

**G1: Requiere revisión del propietario.** Los criterios técnicos pasan: `scripts/ci.sh` exit 0 (40 pruebas Python y 269 Flutter; 6 opt-in omitidas), Flutter/Dart analyze, formato, checker e integridad de memoria con Flutter 3.47.9 aislado. El primer rerun detectó una importación de `data` desde la ruta UI; se corrigió en la composición y el rerun final pasó. La prueba libmpv usa una sesión nativa y confirma que un segundo constructor se rechaza antes de crear otro Player. No se cierra el gate ni se autoriza automáticamente B.

La auditoría externa precedió estas correcciones; después hice una segunda pasada adversarial local, que no es una revisión independiente nueva. A-EXT-03 permanece sin atribución; los logs originales históricos y el bundle revisado originalmente no están disponibles, y se conserva evidencia nueva con su limitación explícita. El intento doble nativo de 45 s sigue fallido/no aprobado y no se repitió. No hubo solicitudes a proveedores ni reproducción externa en esta corrida: `0/70`. El ciclo nativo completo de `VideoController` con compositor continúa sin E2E automatizada. Rama `main`, base `33ceaef5b996c55577524c3448bbb4bee5363952`, HEAD `b1bd952ac03c8711ce50cf22d249fa448d2e2880`; cambios de reevaluación locales sin commit/push. Consultar [estado](docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md), [handoff](docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md) y [auditoría de reevaluación](docs/ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md). B no se inicia hasta tu aceptación formal de G1 y una nueva orden de ejecución.

## F0 Preparación Fedora

| ID | Estado | Evidencia / resultado | Pendiente | Commit privado |
| --- | --- | --- | --- | --- |
| F0.1 | Completado | Flutter/Dart, toolchain Linux, GTK3, libsecret y libmpv verificados en Fedora 44. Detalle reproducible: [auditoría F0.1](docs/environment/F0.1-FEDORA.md). | Android SDK no instalado (fuera del destino Linux); validación del equipo objetivo 4 GB pendiente. | `2af0a4c` |
| F0.2 | Completado | Commit `84efbfb`; `main` subida a `AnimeApp-Dev` privado. Clone limpio; público `AnimeApp` vacío. Registro: [sesión F0.2](docs/memory/sessions/2026-11-07-f0-2-git.md). | Ninguno para el alcance F0.2. | `84efbfb`, `b18a79c` |
| F0.3 | Completado | README y otros siete documentos Markdown completos y enlazados; enlaces relativos verificados. | D3: decisión del propietario sobre archivo `LICENSE` antes de distribuir. No bloquea F0.3. | `2af0a4c` |
| F0.4 | Parcial | En Flutter 3.47.9 aislado con backport reproducible de #191377, `flutter analyze`, suite Flutter (250 pass/6 opt-in skip) y build Linux release pasan. Se evita el mismatch `SemanticsRole.slider` de beta sin tocar SDK global, app ni exclusiones de análisis. [Evidencia y procedimiento](TESTING.md). | F0 permanece parcial: repetir sobre una stable oficial sin backport y validar en hardware objetivo 4 GB. | `47a0e6e` |
| F0.5 | Parcial | La violación `dart:io` de `spike_player_page.dart` se corrigió separando opciones del entorno hacia composición. CI vigente pasó con Flutter 3.47.9 aislado y `pub get --offline`: 40 pruebas IA y 257 Flutter (6 opt-in omitidas), analyzer y límites limpios. [Evidencia](TESTING.md) y [misión T00–T03](docs/ai-system/audits/KONGROO-reconstruction-A-2026-11-15.md). | F0 sigue parcial: el Flutter 3.47.9 que resolvía inicialmente en el PATH falló en el analysis server con una trama LSP UTF-8 incompleta. No se cambió ese SDK; para desarrollo repetir con el toolchain aislado del proyecto. | `2644ef7` |
| F0.6 | Parcial | Bundle release y tres muestras completas. Medianas: primer frame 462 ms, RSS frame 140096 KiB, RSS tras 5 s 145284 KiB, CPU reposo 0.60% de un núcleo. Captura manual confirma ventana visible, pero el script no obtuvo latencia numérica de ventana. Informe: [medición Linux](docs/perf/measure-20261108T133341Z-15982.tsv). | Repetir en el objetivo de 4 GB cuando esté disponible; no hay reproducción ni prueba de fugas prolongada. No extrapolar del entorno de 7.5 GiB. | `0569396` |

## F1–F7

| ID | Estado | Evidencia / resultado | Pendiente | Commit privado |
| --- | --- | --- | --- | --- |
| F1.1 | Completado documental (aprobado por propietario) | Baseline final 18 FR + 13 NFR; seis omisiones MVP añadidas; FR-12/NFR-12 incorporados; FR-11 delimita semántica y pendientes. [Especificación F1.1](docs/requirements/F1.1-CORE-REQUIREMENTS.md). | Definición de semántica por campo FR-11; metas de rendimiento siguen preliminares hasta medir objetivo 4 GB. Validaciones técnicas por fase. | — |
| F1.2 | Completado documental (14 selecciones aprobadas como referencia) | ADR-001–014 corresponden uno a uno con la lista del propietario. [Índice y condiciones ADR](docs/adr/README.md). Se preservaron 13 análisis adicionales aparte. | Compatibilidad, seguridad, licencias y rendimiento se validan en fase propietaria antes de integrar/distribuir. La aprobación no permite adelantar trabajo. | — |
| F1.3 | Completado documental (arquitectura aprobada) | Núcleo Dart compartido + Fedora/Linux primero + adaptadores progresivos; límites de capas, módulos conceptuales, diagramas de contexto/capas/flujos y propuesta acotada de F1.4 en [ARCHITECTURE.md](ARCHITECTURE.md); decisión independiente en [ADR-015](docs/adr/ADR-015-arquitectura-core-linux-first.md). No se implementó código. | Validaciones técnicas de F1.2 continúan en sus fases. Android, Android TV y Windows siguen futuros. | `e7bcde9` |
| F1.4 | Completado | Se conserva `main.dart`, composición `app/` e identidad `domain/`; READMEs describen ambos módulos. Checker protege todo `domain` bajo `app/lib`, resuelve imports package/relativos y tiene fixtures positivos y diez negativos. Sin dependencias ni código de plataformas futuras. Detalle: [README de app](app/README.md), [checker](scripts/README.md), [sesión F1.4](docs/memory/sessions/2026-11-08-f1-4-modular-structure.md). | F1.5: especificar/implementar catálogo tipado de ajustes, defaults y store lógico con pruebas; persistencia Drift/reinicio y migraciones en F1.6. Flutter analyzer LSP continúa registrado como limitación de F0.4/F0.5. | — |
| F1.7 | Completado | `Result<T>`, errores tipados y `SafeLogger` con redacción recursiva y sinks inyectables. Pruebas unitarias pasan; CI con Flutter 3.50 beta seleccionado pasa. Revisión de seguridad estática completada. [README core](app/lib/core/README.md). | La stable Flutter 3.47.9 aún falla LSP; el uso temporal de beta y la condición de CI están en [TESTING.md](TESTING.md). | `7d550d1` |
| F1.6 | Completado | Drift/SQLite schema v2 con migración real v1→v2 que conserva datos, persistencia en archivo, cierre/reapertura y rollback transaccional. Snapshot v1 y pruebas bajo [local_db](app/lib/data/local_db/README.md). Tres pruebas específicas, analyze y Flutter analyze pasan con Flutter beta seleccionado. | Medir rendimiento en hardware objetivo; validar licencias y empaquetado Flatpak en sus fases. No se implementaron reglas de progreso: el documento es opaco hasta F1.10. Stable Flutter 3.47.9 conserva el fallo LSP de F0.5. | `09b9f75`, refuerzo cleanup `a0fbc6b` |
| F1.5 | Completado como infraestructura; catálogo producto pendiente | Registro tipado y store Drift `get/set/watch`, defaults, validación, reapertura y aislamiento reactivo entre claves. Pruebas con SQLite en archivo. [README settings](app/lib/settings/README.md), [sesión](docs/memory/sessions/2026-11-09-f1-5-settings.md), [auditoría real](docs/validation/2026-11-09-f1-5-f1-12-real-tests.md). | No se inventaron preferencias de producto: faltan nombres/defaults/sincronización aprobados. Secrets excluidos (F1.9). | `5a7bab2` |
| F1.8 | Completado técnicamente (loopback); uso de producción pendiente | Cliente Dio GraphQL read-only, rate gate, mapeo de errores HTTP/GraphQL y caché persistente. Pruebas loopback incluyen 401, 403, 429, 5xx, redirección, timeout, rate dinámico y desconexión real/reinicio/recovery integrados. Cero requests externos. [README AniList](app/lib/data/anilist/README.md), [auditoría real](docs/validation/2026-11-09-f1-5-f1-12-real-tests.md). | Elegibilidad de AnimeApp requiere aprobación frente a términos vigentes; caché no tiene TTL/frescura aprobada; UI/startup desconectados. | `669db74` |
| F1.9 | Infraestructura segura implementada; fase requiere revisión para OAuth/runtime | Puerto de dominio y adaptador `flutter_secure_storage 11.2.0`; 4 pruebas fake de write/read/delete, validación y fallos sin filtrar excepciones. `flutter build linux --debug` compila plugin Linux 3.0.3. [README](app/lib/data/secure_storage/README.md), [sesión](docs/memory/sessions/2026-11-09-f1-9-secure-storage.md). | No se accedió al llavero real: runtime Secret Service disponible/ausente/denegado pendiente. OAuth sigue sin decisión sobre grant, callback, scope, expiración/refresh y revocación; no se crearon sesiones ni credenciales. Verificar elegibilidad AniList antes de uso. | `5724afa`, test `3bc6da3` |
| F1.10 | Completado técnicamente: progreso tipado local | `ContentId`/`EpisodeId`/`PlaybackProgress`, repositorio Drift y checkpoints serializados; schema v4 en el commit F1.10, preservado en el schema actual v6. 12 pruebas focalizadas y 49 Flutter total en su cierre original; evidencia actual de integración en sesión catálogo. [README](app/lib/domain/progress/README.md), [sesión](docs/memory/sessions/2026-11-09-f1-10-typed-progress.md). | Métricas en equipo objetivo, tiempo estrictamente activo y política cross-device quedan pendientes; el incremento de catálogo no cambia la semántica F1.10. | `5a7f39a` |
| F1.11 | Contrato/FakeRemote implementados; políticas de protocolo pendientes | Puerto Dart puro `SyncRemote` y fake determinista en memoria con respuesta configurable; 4 pruebas de ack, error configurable, snapshot profundo e ID inválido; checker protege dominio. [ADR-A11](docs/adr/additional/ADR-A11-sincronizacion-fakeremote.md), [sesión](docs/memory/sessions/2026-11-09-f1-11-sync-contract.md). No se conectó Supabase. | No se aprobaron idempotencia/duplicados, conflictos, orden, borrado, retries o campos de réplica. Fake no simula persistencia ni policy server; F1.11 permanece parcial hasta definición/aceptación de esos contratos. | `6bea050` |
| F1.12 | Completado técnicamente para el alcance de núcleo; OAuth y sync de cuenta siguen parciales | Integración real recorre settings, SQLite en disco, HTTP loopback, cache, cierre/reapertura, conexión rechazada offline y recuperación. Linux se compiló. Evidencia histórica: [auditoría F1.5–F1.12](docs/validation/2026-11-09-f1-5-f1-12-real-tests.md). | Stable Flutter 3.47.9 mantiene el fallo LSP Unicode. AniList requiere revisión de elegibilidad; keyring/OAuth reales y protocolo de sync siguen pendientes. F1.10 tipado fue añadido después del informe histórico. | `0b7757b` |
| Catálogo local (integración incremental, sin renumerar fases) | Recorrido local mínimo completado; providers externos pendientes | Fake sintético sin I/O; búsqueda, detalle, alta idempotente, status provisional y progreso F1.10 desde UI; Drift v6 con migración v5→v6. 9 pruebas focalizadas, 62 pruebas Flutter, 40 pruebas IA en CI, analyze/formato/checker/build Linux y arranque del binario con SQLite aislado/integrity ok. [Sesión](docs/memory/sessions/2026-11-09-catalog-local-integration.md), [auditoría](docs/architecture/catalog-system-audit.md). | Estados/default provisional; aceptación formal ADR-A14; elegibilidad/TOS/retención de AniList/TMDB/Kitsu; sin cache multi-provider, OAuth, sync de cuenta ni player. No se conectó DB personal. | Sin commit |
| Historial: providers reales desde ficha | Implementación retirada del runtime actual | En el corte del 2026-11-14 AnimeAV1/TioAnime estaban registrados en `PlaybackProviderManager`; la ficha AniList pasaba título/ID/número, selector y player media_kit existente. Analyze, 25 pruebas focalizadas, suite 250 pass/6 skipped y Linux release build. Live Fedora: TioAnime encontró episodio 1/5 servidores, sin playback; AnimeAV1 iframe 403. | Ningún episodio probó reproducción; Ninja/JKAnime 403 y AnimeJara sin ruta confirmada. El runtime se limpió después; ver la auditoría de limpieza S0. [Auditoría original](docs/ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md). | Sin commit |
| F2.1 | Requiere revisión | Evaluación documental de `media_kit`/libmpv, plataforma Linux, límites de licencia y arquitectura con adaptador único. Se recomienda usarlo en el spike F2.2. [Evaluación](docs/architecture/F2.1-player-evaluation.md), [sesión](docs/memory/sessions/2026-11-09-f2-1-player-evaluation.md). | Verificar reproducción/runtime Fedora, artefacto y dependencias/licencias exactas; no hay reproducción ni validación de rendimiento. | Sin commit |
| F2.2 | Completado — aceptado formalmente por el propietario (2026-11-10) | El propietario confirmó manualmente en Fedora imagen/audio, controles únicos, Play/Pause, Seek, dos ciclos Stop → Play con recuperación y cierre normal GTK/proceso. CI exit 0: 40 pruebas de infraestructura + 99 Flutter; build Linux release `-t lib/main_player_spike.dart` exit 0. El SDK Flutter 3.47.9 aislado conserva el backport UTF-8 local, documentado en `tools/flutter/` y `TESTING.md`; Flutter global no se modificó. | Limitación conocida: no hay una prueba automatizada end-to-end del lifecycle nativo de `VideoController`. | Sin commit |
| F2.3 | Implementada y verificada; pendiente de aceptación del propietario (2026-11-10) | Space/K Play-Pause, flechas ±10 s seek, flechas ±5 volumen y F/Escape GTK; botón visual fullscreen comparte la acción de F. Corregida la carrera de respuesta MethodChannel obsoleta. 20 pruebas focalizadas, CI exit 0 (40 Python + 118 Flutter), Flutter/Dart analyze sin issues, build release del entrypoint específico exit 0 y comprobación gráfica real de F/F/Escape/cierre GTK en Wayland. | Foco real después de clic no se verificó; salida de audio no se midió con loopback en esta prueba. Aceptación formal pendiente. | Sin commit |
| F2.4 | Implementada técnicamente; aceptación pendiente | Estado tipado, generación de fuente, seek ortogonal, transiciones, rollback y lifecycle documentados en `app/lib/application/player/README.md`; cubiertos por coordinator tests y CI actual. | `Player.stream.error` no incluye identidad de fuente; un error tardío entre A/B no se correlaciona. No afirmar aislamiento total. | Sin commit |
| F2.5 | Implementada/revisada; aceptación pendiente | Contratos provider-neutral y manager deduplicado. Cancelación propiedad por caller y finalización tardía cubiertas por 19 tests de manager/contratos; análisis focalizado limpio. [Auditoría](docs/ai-system/audits/F2.5-audit-2026-11-10.md). | Cancelación depende de cooperación del proveedor; revisar aceptación del propietario. | Sin commit |
| F2.6 | Implementada/verificada técnicamente; aceptación pendiente | Política de subtítulos, pistas internas/externas, estilo, delay, hardsub y controles UI; integración libmpv y widget tests. CI exit 0: 40 pruebas Python + 150 Flutter; build Linux release del entrypoint spike exit 0. Captura KDE Wayland muestra video y texto SRT visible. [Auditoría](docs/ai-system/audits/F2.6-audit-2026-11-10.md). | ASS visual no validado; no hay lifecycle nativo automatizado completo de VideoController; F2.6 no aceptada formalmente. | Sin commit |
| F2.7 | Pendiente de resolver la correlación de errores nativos | No se afirma aislamiento completo entre fuente A/B mientras `Player.stream.error` exponga solo `String`. Ver detalle en [estado del proyecto](docs/memory/PROJECT_STATE.md). | Aún sin solución reproducible para errores nativos tardíos; no afirmar cambio de fuente robusto. | Sin commit |
| F2.8 | Implementada y auditada técnicamente; aceptación pendiente | OpenSubtitles API v1 modular, query/candidatos tipados (incluye multipart), búsqueda/carga UI con exclusión de operaciones concurrentes, política hardsub y almacenamiento local seguro. 24 tests focalizados, integración HTTP fake → storage local → coordinator → libmpv real 1/1, CI exit 0 (40 Python + 175 Flutter), analyze y build Linux release específico pasan. | Sin credenciales: API live, cuota y redirects reales no probados; la integración no verifica glifos dibujados por compositor. Informe: [F2.8](docs/ai-system/audits/F2.8-audit-2026-11-11.md). | Sin commit |

F2.1 mantiene pendiente la revisión de artefactos/licencias para distribución. F2.2 fue aceptada y cerrada por el propietario el 2026-11-10. F2.3–F2.8 continúan pendientes de aceptación formal. El propietario autorizó proseguir F2.3–F2.10 y rendimiento sin aceptar fases automáticamente. F2.4–F2.6 tienen implementación técnica y límites documentados; F2.7 mantiene el riesgo de correlación nativa. El alcance de esta ejecución incorpora F2.8 de forma independiente; la transición a F2.9/F2.10 dependerá de que sus contratos no oculten ese riesgo ni generen saltos sobre una fuente no confirmada.

## Registro de cambios

- 2026-11-15: S0-A adaptó temporalmente el catálogo Miruro desde Anilili y conectó el resolver directo al manager/player existentes. GET ordinarios respondieron 403; no se obtuvo media ni reproducción externa (`0/70`). Sus fuentes de test se archivaron y el runtime se retiró después. [Informe histórico](docs/ai-system/missions/S0-ANILILI-PORT-REPORT.md), [auditoría posterior](docs/ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md).
- 2026-11-15: reevaluación externa del Bloque A A-EXT-01–06. Se corrigió cancelación/lifecycle y el límite de imports; la CI aislada final pasó (40 IA + 269 Flutter, 6 opt-in omitidas). A-EXT-03 sigue sin atribución; el timeout de 45 s no se repitió ni aprobó. No hubo reproducción externa: 0/70. [Auditoría](docs/ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md).
- 2026-11-15: Bloque A T00–T03 inicial. Se corrigió el límite de imports y se conservó un solo engine/controller. La CI inicial documentó 262 Flutter; esa línea base no reemplaza la reevaluación actual. [Auditoría](docs/ai-system/audits/KONGROO-reconstruction-A-2026-11-15.md).
- 2026-11-14: conectados adaptadores reales AnimeAV1/TioAnime al catálogo y al player existente. 25 pruebas focalizadas y analyze limpio; live TioAnime encontró servidores pero libmpv no reprodujo, AnimeAV1 iframe 403. Ninja/JKAnime bloqueados por 403, AnimeJara sin ruta confirmada. Sin commit; flujo no aceptado como operativo. [Auditoría](docs/ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md).
- 2026-11-08: F0.2 completada; commits `84efbfb` y actualización documental `b18a79c`, con push privado verificado.
- 2026-11-08: F0.1 y F0.3 completadas; D3/Licencia sigue pendiente y no bloquea F0.3.
- 2026-11-08: F0.4–F0.6 verificadas parcialmente. Build release y medición reproducible completados; CI conserva el fallo de Flutter analyze y no se acreditó ventana visible Wayland. Detalle reproducible en [sesión F0.1–F0.6](docs/memory/sessions/2026-11-08-f0-3-f0-6.md).
- 2026-11-08 (F0-FINAL): captura Spectacle verificó ventana Wayland; analyzer estable 3.47.9 sigue fallando, beta aislada no se pudo descargar en tiempo razonable, y equipo 4 GB no disponible. F0.4/F0.5/F0.6 continúan parciales; no iniciar F1.
- 2026-11-08: propietario aprobó F1.1 (18 FR/13 NFR con condiciones FR-11, rendimiento preliminar, FR-12 y NFR-12) y las 14 selecciones F1.2 como arquitectura de referencia. Validaciones por fase siguen pendientes; 13 ADR adicionales permanecen separados y no aprobados automáticamente. F0.4–F0.6 siguen parciales.
- 2026-11-08: propietario aprobó F1.3: núcleo compartido Dart, Fedora/Linux primero y adaptadores progresivos por necesidad real. Se documentaron arquitectura, capas, módulos, flujos y propuesta de F1.4; ADR-015 registra la decisión. F1.3 completada documentalmente, sin código ni inicio de F1.4.
- 2026-11-08: F1.4 completada: estructura real mínima Linux documentada, checker global de dominios e imports package/relativos ampliado, un fixture permitido y diez violaciones sintéticas, READMEs de aplicación/módulos y regresiones registradas en sesión. No se añadieron dependencias ni se inició F1.5.
- 2026-11-08: reparación parcial de análisis/CI: causa LSP confirmada en Flutter 3.47.9, beta 3.50.0-0.4.pre con fix validada en toolchain aislado, configuración de modos estrictos corregida y migración oficial a `material_ui`. CI pasa solo al seleccionar explícitamente el beta; stable predeterminada aún falla exit 255. F0.4/F0.5 siguen parciales. [Sesión de reparación](docs/memory/sessions/2026-11-08-flutter-analyze-ci-repair.md).
- 2026-11-09: F1.7 completada: `Result`, errores tipados, logger sanitizado, pruebas de sinks/URI/cabeceras y revisión de seguridad estática. CI pasa con SDK beta seleccionado; commits por subfase pendientes de publicación en esta misión. [Sesión F1.7](docs/memory/sessions/2026-11-09-f1-7-core-result-logger.md).
- 2026-11-09: F1.6 completada: Drift schema v2, archivo SQLite real, migración v1→v2 no destructiva, cierre/reapertura y rollback probados. La dependencia nativa de SQLite se verificó con SHA-256 oficial y permanece solo en caché ignorada. La descarga desde el hook tuvo HTTP 504, se obtuvo el mismo artefacto oficial directamente; no se modificaron configuraciones globales. [README](app/lib/data/local_db/README.md) y sesión F1.6.
- 2026-11-09: F1.5 completada como infraestructura: definición/registro genéricos tipados y store SQLite `get/set/watch` con defaults, validación, observación y persistencia. No se agregaron preferencias de producto porque faltan nombres y defaults aprobados; el catálogo queda pendiente de definición propietaria. [README settings](app/lib/settings/README.md).
- 2026-11-09: F1.8 completada técnicamente con transporte HTTP loopback: Dio GraphQL de solo lectura, respuesta/errores tipados, rate gate compartido, cache persistida en un solo slot y migración v2→v3. No se ejecutaron requests reales. Términos vigentes de AniList requieren revisión de elegibilidad antes de cablear el proveedor; ver [README](app/lib/data/anilist/README.md) y sesión F1.8.
- 2026-11-09: F1.9 añadió contrato y adaptador Flutter Secure Storage Linux, con CRUD y errores sanitizados probados con fake; el build compila. No se accedió al keyring. OAuth y prueba de runtime Secret Service permanecen pendientes. [Sesión F1.9](docs/memory/sessions/2026-11-09-f1-9-secure-storage.md).
- 2026-11-09: F1.10 añadió un repositorio local para payloads opacos e identidades exactas, con persistencia, reapertura, reemplazo y validación probadas en SQLite. Campos y semántica de progreso siguen pendientes; FR-03 no se declara cerrado. [Sesión F1.10](docs/memory/sessions/2026-11-09-f1-10-local-progress.md).
- 2026-11-09: F1.11 añadió `SyncRemote` y `FakeSyncRemote` in-memory configurable; no implementa deduplicación, conflictos, retries, Supabase ni sincronización real. Las políticas de protocolo siguen pendientes. [Sesión F1.11](docs/memory/sessions/2026-11-09-f1-11-sync-contract.md).
- 2026-11-09: auditoría real F1.5–F1.12 detectó y corrigió emisiones redundantes de settings, redirección de POST AniList, mapeo HTTP/GraphQL 401 y fallo del logger ante URL malformada. Suite Flutter: 44 pruebas; Flutter analyze, build Linux release y `scripts/ci.sh` exit 0 con beta aislada. Se verificó cache tras socket cerrado y reinicio SQLite. AniList público: 0 requests por elegibilidad no confirmada; keyring real/OAuth y semántica de progreso/sync permanecen pendientes. [Informe](docs/validation/2026-11-09-f1-5-f1-12-real-tests.md).
- 2026-11-09: F1.10 implementó modelo tipado `ContentId`/`EpisodeId`/`PlaybackProgress`, repositorio Drift y checkpoints serializados en schema v4. Validado con 12 pruebas focalizadas, 49 Flutter total, análisis Dart/Flutter, CI y Linux debug build, todos exit 0. Migración v1→v4 y v3→v4 conserva filas heredadas; carrera minuto 15→45 persiste el valor final tras reopen. QA pidió estado por clave y gate determinista; corregidos. Reloj aún representa tiempo de pared desde último guardado, no acumulación estricta de tiempo activo. Ver [README progreso](app/lib/domain/progress/README.md) y [sesión F1.10](docs/memory/sessions/2026-11-09-f1-10-typed-progress.md).
- 2026-11-09: incremento de arquitectura de catálogo: contratos `MetadataProvider` default-disabled, UUID interno/crosswalk/resolución conservadora, membership local y Drift schema v5. Se probaron contratos, SQLite físico, conflictos, reopen, progreso intacto al quitar membership y migraciones v1→v5/v3→v5/v4→v5. 16 pruebas focalizadas, 61 Flutter, CI y build Linux debug pasaron con SDK beta aislado. No se habilitaron AniList/TMDB/Kitsu por condiciones de uso y retención pendientes. [Auditoría](docs/architecture/catalog-system-audit.md), [sesión](docs/memory/sessions/2026-11-09-catalog-system.md), [ADR-A14 propuesto](docs/adr/additional/ADR-A14-catalog-providers-identity.md).
- 2026-11-09: F1.12 completó pruebas de núcleo y una integración local-first; `scripts/ci.sh` exit 0 con Flutter 3.50 beta seleccionado explícitamente (40 IA + 36 Flutter, análisis/checkers). La limitación de stable Flutter 3.47.9 no cambia. [Sesión F1.12](docs/memory/sessions/2026-11-09-f1-12-core-tests.md).
- 2026-11-09: F2.1 evaluó media_kit/libmpv y registró una arquitectura con adaptador único; recomienda continuar con spike local F2.2. Sigue en revisión hasta comprobar reproducción/runtime y artefactos/licencias concretos. No se añadió dependencia ni se ejecutó reproducción. [Evaluación](docs/architecture/F2.1-player-evaluation.md).
- 2026-11-09: F2.2 implementó el spike opt-in en `app/lib/{application,data,app}/player`, con `PlaybackSpikeEngine` temporal, un `MediaKitSpikeEngine`/`Player`, fixture sintético local, controles de UI y pruebas fake + libmpv real. Revisión de UI por compositor y licencias/paquete siguen pendientes; sin commit ni avance de subfase. [Informe](docs/player/F2.2-spike-report.md).
- 2026-11-09: Correcciones F2.2 y reevaluación técnica: se cerraron los hallazgos originales, el auditor independiente no encontró defecto nuevo tras la política de cuarentena de `Player.dispose()`; suite focalizada 11, CI 40 IA + 73 Flutter y build Linux release, todos exit 0. F2.2 sigue abierta por primer frame visible y artefactos/licencias; no aceptar ni iniciar F2.3. [Reevaluación](docs/ai-system/audits/F2.2-audit-reevaluation-2026-11-09.md).
- 2026-11-09: Correcciones F2.2 tras matriz de auditoría v2: slider final/coalescing, close gate GTK/Dart, fixture reproducible/ruta desde raíz, validación local, stop→reopen, negativos/recuperación y stream bajo dispose fallido. Las pruebas player y de aplicación, análisis y build release del entrypoint explícito pasan. La ventana creó textura, pero CUA no expuso apps; cierre GTK y compositor quedan pendientes. Matriz/evidencia: [informe v2](docs/player/F2.2-spike-report-v2.md). F2.2 sigue abierta, no aceptada; no iniciar F2.3.
- 2026-11-10: Se añadió barrera Stop/seek tras hallar que un destino coalescido podía ejecutarse después de Stop: la UI elimina el pendiente y espera el seek activo. Un segundo hallazgo GTK produjo watchdog GLib best-effort de 20 s; limpia el guard local, limita a una invocación MethodChannel pendiente y descarta respuestas tardías sin cancelar cleanup ni cerrar ventana. `GWeakRef` evita retener una referencia fuerte del application por cada gesto repetido. La revisión `auditor_codigo` confirmó orden seek/stop y la política de generaciones; también se reconoce que una llamada/channel sin respuesta puede permanecer pendiente y mantener la ventana abierta. Flutter analyze local pasa; Flutter test/build locales fallan antes del producto por `SemanticsRole.slider`. El objeto C++ compiló directamente. Broadway aislado no soportó EGL/OpenGL; no se capturó imagen ni se probó cierre real. La corrida accidental vía PATH con 30/92 tests y build es diagnóstico, no gate válido. F2.2 sigue abierta/no aceptada. Ver [auditoría](docs/ai-system/audits/F2.2-audit-2026-11-10.md) e [informe](docs/player/F2.2-spike-report-v2.md).
- 2026-11-10: Revalidación F2.2 con Flutter 3.47.9/Dart 3.13.7 en checkout aislado: test startup/cierre 2/2, suite player 32/32, suite Flutter 94/94 y build Linux release con entrypoint explícito pasan; `pub get --offline --enforce-lockfile` conserva lock. `dart analyze` exit 0 con ocho infos; Flutter analyze stable sigue en exit 255 por LSP UTF-8 en ruta Unicode. La evidencia visible y el cierre GTK end-to-end siguen pendientes. F2.2 continúa abierta/no aceptada y no se inició F2.3. Ver [auditoría](docs/ai-system/audits/F2.2-audit-2026-11-10.md) e [informe](docs/player/F2.2-spike-report-v2.md).

- 2026-11-10: **F2.2 aceptada y cerrada formalmente por el propietario.** Verificó manualmente en Fedora imagen/audio, controles únicos, Play/Pause, Seek, dos ciclos Stop → Play con recuperación y cierre normal de ventana/proceso. Gates registrados: CI exit 0 (40 pruebas de infraestructura + 99 Flutter) y build Linux release del entrypoint spike exit 0. Se conserva el parche local UTF-8 de Flutter 3.47.9; la única limitación documentada es no contar con test automatizado end-to-end del lifecycle nativo de `VideoController`. No iniciar F2.3 sin nueva autorización. [Informe](docs/player/F2.2-spike-report-v2.md), [auditoría focalizada](docs/ai-system/audits/F2.2-stop-play-audit-2026-11-10.md).
- 2026-11-10: F2.3 añade atajos scoped al foco, volumen local, seek relativo y fullscreen solicitado/observado por GTK. F23-A1 se corrigió y confirmó por reevaluación independiente; 54 pruebas player, 116 suite Flutter, CI completa exit 0 y build Linux release del entrypoint específico exit 0. La primera CI falló solo porque el informe aún no existía al correr memory check; la corrida posterior quedó verde. No hay compositor gráfico aislado; el propietario debe validar foco/fullscreen/video/audio en Fedora. F2.3 abierta/no aceptada, no iniciar F2.4. [Auditoría](docs/ai-system/audits/F2.3-audit-2026-11-10.md).

### Operación extendida del reproductor

El DEMO integra dos episodios sintéticos, selección nativa de tres pistas de audio, seis subtítulos por episodio, espejos HTTP loopback con Range, restauración tras 503 y un panel Nerd inicial. Ver [informe y launcher](docs/player/operacion-extendida.md). F2.7 y los saltos avanzaron con pruebas focalizadas. Siguen abiertas la correlación de errores nativos por fuente y la verificación integral de la operación.

### Corrección de la interfaz DEMO con contenido real

El launcher predeterminado abre Morevna en Fedora. La UI separa controles, paneles y textura, conserva los espejos y permite seleccionar episodios. Se capturaron subtítulos publicados en ES y EN. Los clics de compositor, el doblaje alternativo compatible, el cierre GTK y la validación en 4 GB siguen pendientes. Ver [auditoría focalizada](docs/ai-system/audits/UI-Morevna-audit-2026-11-12.md).

### F2.7 — estabilización del error al cambiar servidor — 2026-11-12

Se reprodujo `Playback command failed.` al elegir una pista desde un menú de audio que sobrevivía al cambio: un ID nativo de la fuente anterior se asociaba con la generación nueva. La corrección liga el item a su generación y a `mediaContextRevision`, que se invalida síncronamente al solicitar apertura, cambio de fuente o Stop. Widget tests cubren el cambio detrás de seek pendiente y Stop encolado; integración libmpv de Morevna a 00:40 cubre A↔B, Pause/Play, seek, posición ≤2 s y rollback de C/503. Suite player: 94 passed/1 omitida; Flutter total: 206 passed/1 omitida; CI (40 Python + Flutter) y build Linux release específico pasan. La auditoría independiente no halló P1/P2 pendientes en esta interacción. Validación gráfica del caso en la sesión Fedora no fue posible por falta de backend de entrada Wayland; permanece sin captura o clics actuales. La incertidumbre separada de eventos `Player.stream.error` sin ID de fuente también permanece. La fase del reproductor continúa **PENDIENTE**, no finalizada. [Auditoría](docs/ai-system/audits/F2.7-server-switch-audit-2026-11-12.md), [documentación del selector](app/lib/app/player/README.md), [guía DEMO](docs/player/demo-morevna.md).
