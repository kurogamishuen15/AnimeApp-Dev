# KONGROO — ESTADO DE LA RECONSTRUCCIÓN

## Ejecución activa — S0-S arquitectura y limpieza — 2026-11-16

- **Estado:** `PARTIAL / IMPLEMENTING`. Se leyó íntegro el mandato S0-S. La
  limpieza de runtime está hecha; se implementó AnimesDigital v1.0.0 y se
  registró en el manager único. El candidato obtiene un HLS accesible, pero la
  ventana libmpv presentó pantalla negra/error de decodificación. No se cierra
  S0-S y no se considera funcional.
- **Git al inicio:** `main`, `HEAD == origin/main ==
  19470ed6bb19583cc0fc00938c08ab6c2f855300`. Hay cambios rastreados y nuevos
  archivos de la ejecución y de trabajo previo; nada fue stageado ni revertido.
  `.codex-attachments/` y `KONGROO_RECONSTRUCCION_CODEX_T00-T24.zip` siguen
  preservados sin inspeccionar.
- **Línea base player:** `test/player` 120 pass/3 skip; integración libmpv
  14 pass/2 skip; ventana correcta del spike capturó un frame sintético pausado.
  No se verificaron movimiento ni audio. `mpv` CLI no está disponible. RSS en
  stress: 245–247 MB antes, 389–392 MB pico, 371–372 MB después de dispose;
  observación que no demuestra fuga. El host tiene 7.5 GiB, no 4 GB. Evidencia
  y límites: [S0-S baseline](S0-S-BASELINE-AND-IMPLEMENTATION.md).
- **Limpieza S0-S:** retirados los archivos/runtime/tests/harness específicos
  AnimeHeaven; READMEs y evidencia antigua permanecen archivados. AnimeAV1,
  TioAnime, AnimeGG, Miruro, AnimeOnline Ninja y `video_hosts` ya no tienen
  adaptadores Dart activos. Se preservan manager, source switching, ruta,
  contratos genéricos, el único engine media_kit/libmpv y sus regresiones.
- **Implementación nueva:** domain separa identidad, match y episodio; el
  manager mantiene registros versionados, caché LRU de 128 fuentes, circuitos
  de provider y un mapa LRU de máximo 128 hostnames. `PlaybackProvidersModule`
  registra AnimesDigital v1.0.0 y un normalizador genérico HTTPS
  MP4/HLS/DASH (`direct-media`). El candidato soporta solo el player público
  que expone HLS directo; player 2 y embeds no estáticos quedan fuera. El
  normalizador rechaza destinos locales/IP privadas literales, pero no hace
  DNS ni valida redirects; no equivale a un extractor de host ni elimina el
  riesgo DNS TOCTOU.
- **Prueba live de transporte:** AnimesDigital encontró One Piece, episodio
  1180. El GET ordinario del manifiesto respondió 200, 4,998 bytes y 142
  segmentos; el primer segmento respondió 200 con 67,258 bytes y firma MPEG-TS.
  No se registraron URLs completas ni valores firmados.
- **Prueba live en ventana:** el harness montó `SpikePlayerPage`, coordinator,
  `MediaKitVideoSurface` y `MediaKitSpikeEngine` existentes antes de abrir la
  fuente. `Player.open()` terminó y se recibieron duración/pistas; la captura
  `.ai-local/review/animesdigital-live-player-current.png` mostró una ventana
  real, pantalla negra y “The media could not be opened or decoded.” El stream
  no cuenta como reproducción funcional. La captura se guarda en área local
  ignorada por Git. Otra captura de One Piece ep. 1 muestra 00:12/25:00 y la
  interfaz Kongroo, pero también negro y el mismo error; el avance del reloj y
  un evento nativo de primer frame no prueban que se presentara un cuadro.
- **Ruta de producto:** el código sí está conectado: la ficha crea un
  `PlaybackEpisode`, `CatalogHomePage` consulta `PlaybackProviderManager`, abre
  un selector de fuentes y luego `ProviderPlaybackRoute`. El harness live abrió
  directamente el player, no ejercitó clic real desde la ficha ni regreso a
  ella. La app normal abrió Home en la captura
  `.ai-local/review/s0s-real-ui-home.png`; no se pudo hacer clic porque Wayland
  devolvió `Transport closed`, `xdotool` no encontró la ventana Wayland y
  `ydotool` no tenía daemon/socket. No se inició uno. La ruta productiva espera
  `Player.open()` antes de construir el widget de superficie; esa secuencia
  difiere del harness y su efecto causal no está aislado.
- **Seguimiento de demux:** `KONGROO_LIVE_FFPROBE=1` produjo un diagnóstico
  redacted: libavformat rechazó una referencia `.webp` del HLS por
  `allowed_segment_extensions`; la herramienta también mencionó una referencia
  `.m3u8`. No se sabe qué tag lo publicó ni si libmpv falla por el mismo motivo.
  Una solicitud posterior agotó el timeout del provider. No se relajó el filtro
  ni se modificó el engine. Los tests offline de redacción y resumen HLS pasan
  3/3; Dart analyze del harness y su test no reporta issues.
- **Pruebas actuales:** provider AnimesDigital focalizado 7/7 y suite Flutter
  completa más reciente 300 aprobadas/7 optativas omitidas. Dart analyze
  (`lib test tool`) y Flutter analyze (`--no-pub`) terminaron sin problemas. Linux debug build,
  formato de 192 archivos, checker/import tests, 40 pruebas Python, `memory.py
  check` y `git diff --check` también pasaron. `scripts/ci.sh` no se ejecutó
  porque invoca `flutter pub get`; no hubo cambios de dependencias y sus pasos
  de test/análisis se ejecutaron por separado.
- **Alcance plataforma/rendimiento:** las capas domain/application no usan
  dependencias de sistema; se añadió `dart:io` estándar únicamente para revisar
  IPs literales en el resolver data. Linux es el único destino ejercitado;
  Android y Windows no tienen build verificado. No se midió consumo del smoke ni
  se probó en el equipo de 4 GB.
- **Investigación primaria:** Anilili MIT-0 separa catálogo/proveedor/Media3;
  Zangetsu Providers tiene un README que declara MIT, pero la raíz consultada no
  mostró un archivo `LICENSE`; no se copia su código. anime-sh (MIT) separa
  providers/resolvers; anipy-cli y ani-cli declaran GPL-3.0; GoAnime declara
  MIT y documenta AnimeFire, AnimeDrive y HiAnime. Se usan patrones, sin copiar
  código ni cargar extensiones remotas.
- **Investigación live:** AnimeFire API respondió 403 a GET ordinario. AnimeDrive
  devolvió catálogo/ficha/episodio públicos, pero sus dos solicitudes de
  disponibilidad al MP4 de `mangas.cloud` respondieron 403 HTML de Cloudflare.
  AnivexaAPI devolvió 402; no se copió código. La guía de AniKotoAPI documenta
  bloqueo de AJAX/resolución y ofrece iframe/WebView, no una fuente native-media
  comprobada. Ningún candidato entregó un medio reproducible; detalle en el
  [baseline S0-S](S0-S-BASELINE-AND-IMPLEMENTATION.md).
- **Auditoría del código:** la revisión inicial encontró dos defectos P2
  (pérdida de IDs externos secundarios y enfriamiento reiniciado por fallo
  permanente en probe); ambos se corrigieron con regresiones. La pasada
  adversarial añadió LRU de 128 para el mapa de breakers host. La segunda
  revisión independiente confirmó claves encuadradas, límites HTML y deadline
  anti-goteo; advirtió que el timeout se reiniciaba por cada petición. Se
  corrigió con presupuesto total de 20 s por operación y test de varias
  búsquedas lentas. Riesgo condicionado aún no verificado: el allowlist protege
  el hostname HLS inicial, pero no se probaron DNS/redirects ni destinos de
  segmentos/playlist que libmpv solicita después.
- **Auditoría:** [S0-S audit](../audits/S0S-audit-2026-11-16.md) registra un P1
  de aceptación abierto (sin video visible), un riesgo P2 condicionado en
  destinos HLS/DNS, una pista no confirmada de extensión HLS rechazada por
  ffprobe, la brecha no causal del orden de montaje y el timeout total ya
  corregido. No hay P0 confirmado.
- **Siguiente paso:** con una fuente pública vigente, identificar el tag HLS de
  la referencia `.webp` y probar una allowlist estrecha en ffprobe/libmpv antes
  de proponer una configuración por fuente; no ampliar extensiones globales.
  Aislar con una regresión el orden `open`/montaje de la ruta productiva y
  obtener una fuente externa que muestre un cuadro real;
  comparar el mismo medio con mpv CLI solo si ya está disponible. Mantener
  AnimesDigital como candidato hasta ver frame, avance y audio si corresponde;
  después validar clic real desde ficha, retorno, segunda alternativa y
  fallback. Android/Windows, mpv CLI, medición streaming y equipo de 4 GB siguen
  pendientes. No cambió engine/UI ni dependencias del player. No stagear,
  commit ni push.
- **Git:** no staging, commit ni push.

> Estado histórico actualizado el 2026-11-15 tras la limpieza posterior a S0-A. La ejecución activa S0-R se registra debajo; no implica aceptar G1/T03 ni avanzar a F1.

## Historial de ejecución — S0-R, provider AnimeHeaven — 2026-11-16

- **Estado:** se integró un provider AnimeHeaven y su resolver MP4 en el
  composition root existente. La búsqueda pública de One Piece, episodio 1,
  produjo tres alternativas (`mirror-cx`, `mirror-ct`, `mirror-ck`). Cada una
  llegó a libmpv por separado; las tres mostraron error genérico de apertura/
  decodificación y ningún frame. Resultado: **1 provider implementado, 0
  reproducibles, 0/70**. Gate 1 y Gate 0 siguen
  parciales; no se acepta S0 ni se avanza a otra fase.
- **Evidencia visible:** `s0r-animeheaven-visible.png` y
  `s0r-animeheaven-mirror-switch.png` documentan `ct`; las capturas
  `s0-animeheaven-mirror-cx.png` y `s0-animeheaven-mirror-ck.png` documentan las
  otras alternativas, todas con error y sin imagen. No cuentan como
  reproducción. No hay log nativo persistido ni URI firmada registrada.
- **Pruebas ejecutadas ahora:** 13 tests focalizados de AnimeHeaven/composition;
  48 regresiones focalizadas de providers, manager, contratos, ruta y módulo;
  `flutter analyze --no-pub` completo; `dart analyze` de provider, resolver,
  tests y harness. Todo pasó; no es una prueba live exitosa. La revisión
  independiente no encontró P0/P1; sus tres P2 iniciales se corrigieron. Una
  revisión posterior encontró y motivó sustituir `Future.any` por un listener
  temporal desregistrado al completar cada fragmento.
- **Acceso gráfico:** el propietario respondió «Autorizar manualmente en KDE».
  Una captura posterior no muestra el diálogo, pero Wayland MCP continúa con
  `Transport closed`. No se simuló entrada: los mirrors se seleccionaron con el
  ID explícito del harness. No se abrió una navegación gráfica de producto.
- **Rendimiento:** no hay medición nueva del provider ni durante streaming. La
  línea base anterior es de un host con 7.5 GiB, no del objetivo de 4 GB; Gate 0
  sigue parcial.
- **Diagnóstico A/B con mpv CLI:** no ejecutado; `mpv` no está disponible en
  PATH. No se instaló software ni se modificó el sistema.
- **Siguiente paso:** no repetir `cx`, `ct` ni `ck` para este episodio sin
  evidencia de disponibilidad nueva. Los demás nombres de la allowlist no
  fueron ofrecidos, así que no se inventan URLs. Las rutas ya probadas no
  ofrecen ahora una fuente elegible, pero el inventario total no está agotado:
  la revisión previa de Anivexa lista 28 candidatos y solo probó AniChan,
  AniPM y Zoko. Revisar estáticamente un candidato no probado y sondear como
  máximo una ruta con GET ordinario solo si documenta un host distinto y no
  depende de sesión, autenticación, challenge ni transformación protegida.
  Mantener S0 abierta. No se ejecutó CI completa.
- **Git:** rama `main`, HEAD `b1bd952ac03c8711ce50cf22d249fa448d2e2880`;
  los cambios locales y preexistentes siguen sin staging, commit ni push.
- **Auditoría:** [S0R-ANIMEHEAVEN-audit-2026-11-16.md](../audits/S0R-ANIMEHEAVEN-audit-2026-11-16.md)
  registra la revisión independiente, los P2 corregidos y la evidencia que falta.

## Registro previo — S0-R, Gate 1 — 2026-11-16

- **Estado:** Gate 1 PARTIAL / NO_PLAYABLE_SOURCE_VERIFIED; Gate 0 sigue
  PARTIAL. Se revisaron referencias Android, desktop, Flutter y CLI. Seis
  probes GET previos dieron 403. AniWorld permitió buscar One Piece, abrir su
  ficha/temporada/episodio y observar cuatro hosters; Doodstream, Filemoon y
  Vidmoly dieron 403, y VOE solo publicó una redirección dependiente de
  rama opcional que lee `localStorage`, sin medio estático. No se siguió ese
  destino ni se obtuvo playback: S0 sigue 0/70.
- **Entorno:** Flutter `3.50.0-0.4.pre` / Dart `3.14.0-315.3.beta`, Fedora 44,
  KDE Wayland, 8 CPUs lógicas y 7.5 GiB disponibles. No es el equipo objetivo
  de 4 GB.
- **Pruebas:** suite Flutter 268 pass/6 optativas omitidas, 40 Python, analyze
  Flutter/Dart limpios, formato, checker de imports y memoria limpios. Ver
  [`S0R-BASELINE.md`](S0R-BASELINE.md) y sus logs privados.
- **Rendimiento observado:** demo local release 480×270/24 fps de archivo,
  proceso RSS 245,708–258,440 KiB y CPU media 28.84% de un núcleo durante 8 s.
  `media_kit` informa render por software en esta sesión. No es medida 4 GB ni
  FPS efectivamente presentado.
- **Riesgos/pendientes Gate 0:** no hay latencia exacta del primer frame ni
  conteo de drops; `scripts/measure.sh` no sirve al entrypoint spike y dejó un
  resultado `incomplete`; RSS quedó alto tras 20 ciclos y requiere perfil
  comparable adicional. No se atribuye un leak confirmado.
- **Investigación:** commits, licencias, idiomas, solicitudes y límites están
  en [S0R-REFERENCE-REVIEW-2026-11-16.md](S0R-REFERENCE-REVIEW-2026-11-16.md).
  AniWorld añade un candidato de cobertura alemana/inglesa, no un adapter
  integrado. No se copió código ni se añadieron providers/resolvers al root.
- **Siguiente tarea:** inspeccionar código/licencia de un proveedor no probado
  que no requiera challenges, autenticación, descifrado ni impersonación. Solo
  hacer una solicitud pública ordinaria si su protocolo documentado es
  elegible. No repetir los seis probes ni los cuatro hosters AniWorld ya
  observados. Iniciar Gate 2 solo con una ruta multimedia accesible.
- **Git:** `main`, HEAD `b1bd952ac03c8711ce50cf22d249fa448d2e2880`; el checkout
  ya estaba sucio al iniciar. Todos los cambios previos se preservaron. Esta
  ejecución no hizo commit ni push.

## Snapshot histórico — limpieza posterior de providers S0 — 2026-11-15

Se retiró el runtime S0-A de Miruro después de que los GET públicos ordinarios
de configuración y lookup devolvieran HTTP 403. No hubo episodios, URI
reproducible ni reproducción externa. El composition root conserva el
`PlaybackProviderManager` vacío; el contrato `PlaybackVideoHostResolver`, el
`PlaybackSourceSwitchService` y el único engine media_kit/libmpv siguen
disponibles. También se conservan las pruebas genéricas y los README históricos.
Playback externo continúa `0/70`; no se acepta G1 ni se inicia F1.

Los cuatro archivos de prueba específicos de Miruro se retiraron del descubrimiento de
Flutter y se archivaron como fuentes `.dart.txt`; la prueba del composition root
verifica que no haya adapters externos registrados. AnimeAV1, TioAnime, AnimeGG,
el transporte HTTP público y el resolver estático ya estaban retirados en la
limpieza anterior. Con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislados pasaron los
24 tests focalizados, la suite completa (268 pass, 6 optativas skip), Flutter y
Dart analyze, checker, 40 tests Python, formato, memoria y diff check. No se
ejecutó `flutter pub get`, build Linux ni requests live. Ver la
[auditoría de seguimiento](../audits/S0-provider-cleanup-followup-audit-2026-11-15.md).

## Registro histórico — S0-A, port de Anilili/Miruro — 2026-11-15

Se implementó el provider de catálogo Miruro y un resolver directo MP4/HLS,
registrados en el `PlaybackProviderManager` y el composition root existentes.
No se creó un segundo player. El resolver mantiene HTTPS, límites de tamaño,
timeouts, cancelación, bloqueo de redirects y validación DNS, con denylist IPv6
conservadora contrastada con IANA. Persisten el riesgo DNS TOCTOU y la falta de
GET de validación HLS.

- **Resultado externo:** `www.miruro.to` `/api/config` y lookup AniList dieron
  HTTP 403 en GET públicos ordinarios. No se intentaron mirrors, cookies,
  perfiles de navegador, challenges ni repetición con cabeceras para alterar la
  denegación. Un smoke con Dio clasificó el 403 como `unauthorized`.
- **Resultado de producto:** no se obtuvo episodio ni URI accesible; libmpv no
  abrió video externo. Conteo vigente: **0/70**. Miruro es una integración de
  código, no un proveedor confirmado funcional. Anivexa no está integrado.
- **CI local actual:** con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislado,
  `scripts/ci.sh` exit 0: 40 pruebas Python, 288 Flutter aprobadas y 7 optativas
  omitidas; Dart/Flutter analyze, formato, checker e integridad de memoria
  pasan. `flutter build linux --release --no-pub` produjo el bundle release.
  El test de playback real existente usa fixture local y no acredita proveedor
  externo.
- **No medido:** playback externo, ventana Wayland del provider, recursos en
  equipo de 4 GB, ni RAM/CPU/arranque/fugas durante streaming. El entorno de la
  CI y sus fixtures no sustituyen esas mediciones.
- **Siguiente paso elegible:** continuar S0-A con el inventario estático de
  Anivexa y solo rutas ordinarias que no requieran alterar controles de acceso;
  no repetir Miruro 403 sin evidencia nueva. Luego probar el recorrido real
  ficha→episodio→fuente→libmpv cuando haya una URI autorizada y accesible.
- **Evidencia:** [informe del port](S0-ANILILI-PORT-REPORT.md), [auditoría
  profunda](../audits/S0-ANILILI-port-audit-2026-11-15.md), [informe de playback
  S0](S0-REAL-PLAYBACK-REPORT.md).

## Registro histórico: S0 tras limpieza, antes del port S0-A

## S0 — estado tras limpieza previa — 2026-11-15

La instrucción más reciente suspende la implementación de proveedores hasta
que el propietario envíe el siguiente prompt de integración. S0 sigue
incompleta; esta limpieza no acepta G1 ni inicia tareas B–F. T03/G1 permanece
`AUDITING`. No se declara `PLAYBACK_VERIFIED` por HTTP, HTML, iframe o URL.

- **Estado S0:** incompleta; integración externa en pausa por instrucción del propietario.
- **Implementación activa:** cero providers externos y cero resolutores
  concretos registrados. Los adapters AnimeAV1, TioAnime y AnimeGG, el resolver
  HTTP estático y su transporte se retiraron; contratos, manager, circuit
  breakers, source switching, mocks y engine media_kit/libmpv se conservaron.
- **Inventario histórico:** 22 candidatos; 0 reproducciones externas y 0/70
  títulos. Las etiquetas previas `RESOLVING`, `BLOCKED_EXTERNAL`,
  `INVESTIGATING` y `PENDING` describen los sondeos anteriores, no adapters
  activos en el runtime actual.
- **Verificación previa archivada:** 41 tests de contratos/resolver, 35 de
  route/coordinator, 1 integración Referer/libmpv local y analyze limpios; los
  smokes live fallaron para reproducción y el código de esos tests se retiró.
  Los logs y resultados siguen en `.ai-local/review/s0-real-playback-2026-11-15/`
  y en el informe histórico S0. Después de la limpieza, Flutter analyze, Dart
  analyze y toda la suite Flutter pasaron (267 pass, 6 optativas omitidas) con
  Flutter 3.50.0-0.4.pre aislado. El detalle está en la auditoría de limpieza.
- **Bloqueos actuales:** no se confirmó ningún cuadro de video externo. AnimeGG
  avanzó a 5,3 s y expuso codec de audio, pero no dimensiones de video; TioAnime
  dio Mega/OK.ru/Netu `unsupported`, StreamSB timeout y YourUpload error de red.
  AnimeAV1 se detuvo en `unauthorized`. AniZone devolvió HTTP 404 tanto a GET
  normal como Range en su manifiesto observado, y HTTP 419 en la acción Livewire
  pública; se clasifica `BLOCKED_EXTERNAL`. Los hosts FileStream, Bee y Goma no
  aparecieron en el inventario live ni en las fuentes de episodio revisadas.
  Ninja, JKAnime,
  AnimeJara `/catalogo/` y Latanime devolvieron 403; AnimeKai no resolvió DNS en
  sus tres mirrors publicados; AllAnime solo dio 200 en la raíz y sus episodios
  tienen verificación Cloudflare reportada upstream. AnimeAV1 devuelve
  `unauthorized` al resolver; TioAnime no abrió el único media URI resuelto.
  AnimeGG encontró 5 variantes de One Piece episodio 1, pero solo se cuenta un
  host de entrega, `vidcache.net`; la variante preferida resolvió URI y llegó a
  libmpv sin cuadro de video. KickAssAnime respondió en búsqueda/episodio/servidor;
  CatStream no expuso un manifiesto/URI estático en la página pública. El
  extractor upstream requiere firma/AES para ciertas rutas, no adaptadas.
  ReAnime/FlixCloud y 2DHive/MegaPlay figuran en el inventario. La fuente
  upstream de FlixCloud describe token/stream por `enc-dec.app` y segmentos XOR
  transformados por proxy local; no se confirmó ruta directa ni se adaptó ese
  flujo. MegaPlay conserva una etapa crypto no investigada live.
  Animeflv.one permite búsqueda pero dos fichas no mostraron episodios; no se considera
  dominio confirmado de AnimeFLV. Henaojara redirige a AnimeJara y no se siguió.
- **Informe y evidencias:** [S0-REAL-PLAYBACK-REPORT.md](S0-REAL-PLAYBACK-REPORT.md)
  y `.ai-local/review/s0-real-playback-2026-11-15/`.
- **Auditoría S0:** [S0-provider-audit-2026-11-15.md](../audits/S0-provider-audit-2026-11-15.md).
  No encontró un defecto nuevo demostrado en el código revisado; deja abierto
  el P1 de aceptación por ausencia de reproducción real y el P2 de cobertura.
- **Siguiente acción:** esperar el siguiente prompt del propietario antes de
  integrar proveedores o hosts. S0 no se cierra hasta verificar reproducción
  externa completa; no marcar G1 aceptado.

- **Misión:** reconstruir integración de episodios/proveedores/reproductor y validar 70 títulos.
- **Inicio recomendado:** solicitar/registrar aceptación propietaria de G1 antes de considerar T04/B.
- **Bloque activo:** A, en revisión de cierre; esta ejecución no inició B.
- **Rama:** `main`. Base de Bloque A: `33ceaef5b996c55577524c3448bbb4bee5363952`; el HEAD de referencia actual al abrir esta reevaluación era `b1bd952ac03c8711ce50cf22d249fa448d2e2880`.
- **Commit de referencia de lectura:** `33ceaef5b996c55577524c3448bbb4bee5363952` (GitHub; puede haber cambios nuevos).
- **Última CI completa antes de la auditoría externa:** `PASS`, `scripts/ci.sh` con Flutter 3.47.9 aislado; 40 pruebas Python, 262 Flutter y 6 opt-in omitidas. Esa ejecución histórica no valida las correcciones locales actuales.
- **Verificación final de esta reevaluación:** 43 pruebas focalizadas, `flutter analyze --no-pub`, `dart analyze lib test` y `scripts/ci.sh` pasan. La CI pasó 40 pruebas Python y 269 Flutter; 6 opt-in se omitieron. Checker de imports, formato, memoria y diff check pasan.
- **Reproducciones externas verificadas en esta misión:** `0/70` (cero evidencias creadas por este paquete; no significa que un usuario nunca haya reproducido otro medio).
- **Proveedores operativos acreditados en esta misión:** `0`.
- **Hallazgos de auditoría externa:** A-EXT-01/02/05 corregidos y cubiertos por regresiones; A-EXT-03 sigue `UNATTRIBUTED / NOT_REPRODUCED` conforme a la evidencia; A-EXT-04 conserva como no aprobado el timeout previo y registra logs nuevos; A-EXT-06 corregido en handoff. La CI final pasó. La auditoría independiente original fue anterior a los fixes; el coordinador hizo una segunda pasada local adversarial, no independiente.
- **P1 posterior abierto:** la auditoría de providers del 2026-11-14 no confirmó reproducción de ningún episodio real; corresponde a los gates de providers/playback posteriores y no se declara resuelto por esta ejecución.
- **Última ejecución:** 2026-11-15, reevaluación A-EXT-01–06; T04/B no iniciada.
- **Estado Git:** `HEAD` y la referencia local `origin/main` coincidían en `b1bd952ac03c8711ce50cf22d249fa448d2e2880` al iniciar. Las correcciones de esta reevaluación están sin commit ni push. La publicación anterior de Bloque A ocurrió después de una autorización explícita; el ZIP se generó en una tarea posterior sin cambiar Git. La referencia local no es una consulta remota en vivo.

## Reglas del tablero

Los estados válidos son `PENDING`, `INVESTIGATING`, `IMPLEMENTING`, `TESTING`, `AUDITING`, `BLOCKED`, `DONE`. Para cambiar a `DONE`, citar prueba y criterio de aceptación. Si una tarea falla o un proveedor responde 403, reportarlo sin falsear resultados. Una tarea `BLOCKED` solo bloquea sus dependientes, no el trabajo independiente autorizado.

## Matriz de tareas

| ID | Bloque | Estado | Dependencias | Evidencia / notas |
|---|---|---|---|---|
| T00 | A | DONE | — | Checkout `main` coincide con el commit de referencia; inventario y línea base registrados en `docs/ai-system/audits/KONGROO-reconstruction-A-2026-11-15.md`. |
| T01 | A | DONE | T00 | El incidente del texto HTTP queda registrado `UNATTRIBUTED / NOT_REPRODUCED`; no se marca `FIXED` ni se atribuye a proveedor. Los mensajes tipados cubren fallos actuales. Ver `docs/ai-system/incidents/PLAYBACK-HTTP-ERROR-UNATTRIBUTED-2026-11-15.md`. |
| T02 | A | DONE | T00 | `dart:io` retirado de `spike_player_page.dart`; opciones tipadas desde composition root; checker y CI aislada pasan. |
| T03 | A | AUDITING | T00,T02 | Cancelación cooperativa/cierre tardío supervisado; errores diferencian lease ocupado y cleanup auxiliar. 43 focalizadas y CI (269 Flutter + 40 Python; 6 opt-in skip) pasan. Evidencia y segunda pasada local documentadas; falta aceptación propietaria de G1. |
| T04 | B | PENDING | G1 | Sin ejecutar |
| T05 | B | PENDING | T04 | Sin ejecutar |
| T06 | B | PENDING | T04,T05 | Sin ejecutar |
| T07 | B | PENDING | T04–T06 | Sin ejecutar |
| T08 | B | PENDING | T04,T07 | Sin ejecutar |
| T09 | C | PENDING | T02,T04 | Sin ejecutar |
| T10 | C | PENDING | T04 | Sin ejecutar |
| T11 | C | PENDING | T09,T10 | Sin ejecutar |
| T12 | C | PENDING | T04–T11 | Sin ejecutar |
| T13 | C | PENDING | T10–T12 | Sin ejecutar |
| T14 | D | PENDING | T04,T10 | Sin ejecutar |
| T15 | D | PENDING | T09,T14 | Sin ejecutar |
| T16 | D | PENDING | T15 | Sin ejecutar |
| T17 | D | PENDING | T14–T16 | Sin ejecutar |
| T18 | E | PENDING | T05,T15 | Sin ejecutar |
| T19 | E | PENDING | T18 | Sin ejecutar |
| T20 | E | PENDING | T15–T19 | Sin ejecutar |
| T21 | F | PENDING | T11–T20 | Sin ejecutar |
| T22 | F | PENDING | funcionales | Sin ejecutar |
| T23 | F | PENDING | reproducción | Sin ejecutar |
| T24 | F | PENDING | T00–T23 | Sin ejecutar |

## Gates

| Gate | Bloque | Estado | Criterio pendiente |
|---|---|---|---|
| G1 | A | AUDITING | Los criterios técnicos pasan: A-EXT-01/02/05 cubiertos y corregidos; T01/A-EXT-03 registrado sin falsa atribución; CI, checker y análisis pasan. Los logs históricos ausentes y el timeout previo no aprobado permanecen como límites. Cierre formal pendiente del propietario; no se ejecuta B. |
| G2 | B | PENDING | Contratos, episodios, idiomas y settings comprobados |
| G3 | C | PENDING | Proveedores reales/manager y extensibilidad auditados |
| G4 | D | PENDING | Apertura, fallback y cierre reproducibles con libmpv |
| G5 | E | PENDING | Progreso por episodio + Home + opcionales integrados |
| G6 | F | PENDING | ≥70 reproducciones reales + CI + auditoría sin P0/P1 |

## Hallazgos y bloqueos activos

**Hallazgos de la revisión externa y estado:** A-EXT-01 recibe un token cooperativo de cancelación; la ruta puede volver al catálogo y supervisa el Future pendiente, y una sesión tardía se cierra sin liberar anticipadamente el lease. Si libmpv no responde, el lease permanece retenido y la UI indica esperar/reiniciar. A-EXT-02 distingue `nativePlayerStillOwned` de limpieza secundaria; la navegación solo queda bloqueada mientras el Player nativo siga retenido. La UI no importa `data`: el composition root traduce la contención a `PlaybackRoutePlayerBusy`. A-EXT-05 queda atendido con overrides opcionales y test de preferencias inyectadas. A-EXT-03 se mantiene `UNATTRIBUTED / NOT_REPRODUCED` en el registro de incidente y la búsqueda actual de `app/lib` no encuentra la frase. A-EXT-04 conserva el timeout de 45 s como fallo/no aprobado; no se repite la doble apertura. Se guardaron logs nuevos de prueba, análisis y CI; los logs originales y el bundle histórico siguen faltantes. A-EXT-06 queda aclarado en HANDOFF con los refs locales comprobados.

**Toolchain:** `flutter` resolvía inicialmente a `/home/kyouma/flutter/bin/flutter` y `flutter analyze` terminó con exit 255 por `FormatException` en el analysis server al recibir una trama JSON incompleta bajo la ruta UTF-8. El SDK de proyecto `.ai-local/toolchains/flutter-3.47.9` (mismo framework revision `c197ca5199`, canal `[user-branch]`) pasó `flutter analyze --no-pub`; CI completa también pasó al anteponer ese SDK a `PATH`. No se modificó el SDK externo/global ni se deshabilitó el analizador.

**Frase informada:** `No se encontró un servidor HTTP disponible` permanece `UNATTRIBUTED / NOT_REPRODUCED`. La auditoría anterior registró una búsqueda del código/bundle, pero el bundle no está en el ZIP independiente y no se conserva traza del incidente. No se afirma que el origen esté localizado ni que esté corregido; ver el [registro de incidente](../incidents/PLAYBACK-HTTP-ERROR-UNATTRIBUTED-2026-11-15.md).

**Auditorías:** la revisión externa del ZIP halló A-EXT-01 P1, A-EXT-02/03/04 P2 y A-EXT-05 P3. Tras los cambios se hizo una segunda pasada adversarial local más CI/análisis y regresiones; no constituye una auditoría independiente nueva. El revisor externo no examinó el checkout post-fix. No existe una prueba E2E automatizada del ciclo nativo completo de `VideoController`.

**Trabajo S0:** AnimeAV1/TioAnime/AnimeGG continúan sin reproducción externa confirmada. El ciclo nativo completo de `VideoController` aún no tiene prueba end-to-end automatizada; esta ejecución no cubrió la ventana gráfica del proveedor.

## Registro breve de ejecuciones

| Fecha UTC | Bloque | Tareas | Comandos/exit | Archivos | Resultado |
|---|---|---|---|---|---|
| 2026-11-15 | A | T00–T03 | `scripts/ci.sh` exit 0: 40 Python, 262 Flutter, 6 opt-in omitidas; `flutter analyze --no-pub` y `dart analyze lib test` sin issues; import checker (30 player/34 domain), formato, `memory.py check` y `git diff --check` exit 0. Focalizadas 18/18; dos pruebas nativas afectadas 1/1 cada una; fixture libmpv local 1/1. Intento de dos aperturas nativas agotó 45 s, no aprobado. | Código de mensajes/opciones/ruta/lease, regresiones, READMEs, arquitectura, progreso, testing, memoria y auditoría A. Se restauró el lockfile al resolver offline. | G1 DONE; publicación autorizada a `origin/main` privado; detenerse antes de T04/B |
| 2026-11-15 | A | A-EXT-01–06 | Reevaluación inicial: 42 pruebas focalizadas, analyze pasan; CI detectó una importación UI→data. Se corrigió la frontera; conservar `ci.log` como evidencia de fallo corregido. | Ruta/player/engine/options, pruebas, READMEs, incidente HTTP, STATUS/HANDOFF y auditoría de reevaluación. | CI final en fila siguiente |
| 2026-11-15 | A | A-EXT-01–06 | 43 focalizadas; prueba libmpv single-owner 1/1; `scripts/ci.sh` exit 0: 40 Python, 269 Flutter y 6 opt-in omitidas; Flutter/Dart analyze, formato, casos positivos/negativos del checker, memoria pasan. Logs crudos en `.ai-local/review/block-a-reassessment-2026-11-15/`. `pubspec.lock` se restauró y hash coincide con el backup previo. | Correcciones de startup/cierre, frontera UI, defaults, regresiones, READMEs, incidente, PROGRESS/TESTING/memoria, estado/handoff y auditoría post-fix. | Criterios técnicos de G1 pasan; AUDITING hasta aceptación propietaria. T04/B no ejecutado |
| 2026-11-15 | S0 | AnimeGG + probe KickAssAnime | Flutter analyze limpio; provider fixtures 7/7, domain 6/6, manager 16/16, coordinator 28/28; integración local Referer/libmpv 1/1. AnimeGG smoke: 5 variantes, 5 fallos `network`, exit 1. KickAssAnime: búsqueda/detalle/episodio/servidor públicos; CatStream sin manifiesto/URL directo reconocible. | Adaptador AnimeGG, cabecera limitada Referer, pruebas, READMEs, evidencia S0 y memoria. | 3 adaptadores; 0 playback externo; 10 bloqueados externos; seguir con AniZone; sin CI completa, commit ni push |
| 2026-11-15 | S0 | Resolver reusable de hosts y live recheck; inspección documental adicional de FlixCloud | 41 pruebas contratos/resolver + 35 de route/coordinator pass; 3 live omitidas por defecto; integración local Referer/libmpv 1/1; Flutter/Dart analyze limpios. Live TioAnime: cinco hosts recorridos, cero URI actual; AnimeGG: URI vidcache, 5311 ms y audio, sin dimensiones de video; AniZone: 404 Range/GET y 419 Livewire. La referencia upstream de ReAnime muestra token/stream por API y segmentos XOR en proxy; no hubo probe live ni se adaptó. | Contratos domain/manager, `PublicSiteHttp`, resolver común, pruebas, READMEs, informe S0, memoria, STATUS/HANDOFF y auditoría de hosts. | Sin reproducción de video externa (0/70); 11 bloqueados externos; FlixCloud sigue `INVESTIGATING`; S0 activa; sin CI completa, commit ni push |
| 2026-11-15 | S0 | Limpieza de adaptadores y transporte obsoletos | Flutter analyze y Dart analyze sin issues; suite Flutter completa 267 pass/6 optativas omitidas; búsqueda Dart sin referencias a las clases retiradas. | Se retiraron AnimeAV1/TioAnime/AnimeGG, `PublicSiteHttp`, resolver estático y test específico; composition root queda vacío; contratos, manager, source switch y engine conservados; READMEs, memoria y auditoría actualizados. | Sin providers/resolvers activos y sin playback externo; S0 incompleta, en pausa hasta el siguiente prompt; no commit ni push |
| 2026-11-15 | S0-A | Port Anilili/Miruro + auditoría profunda | `scripts/ci.sh` exit 0: 40 Python, 288 Flutter, 7 optativas skip; Dart/Flutter analyze, formato, checker y memoria pasan. Smoke real de config/lookup: 403 → `unauthorized`; sin episodio/media/playback. | Provider Miruro, API Dio, resolver HLS/MP4, tests, READMEs, S0 reports, STATUS/HANDOFF/plan, PROGRESS/TESTING y memoria. | Provider/resolver conectados pero no verificados funcionalmente; Anivexa pendiente; playback 0/70, gate S0 abierto; sin commit ni push |
| 2026-11-15 | S0 | Limpieza de seguimiento tras S0-A | 24 pruebas focalizadas y suite Flutter completa 268 pass/6 optativas omitidas; Dart/Flutter analyze, 40 Python, checker de imports, formato, memoria y `git diff --check` pasan. `flutter pub get`, build y requests live no se ejecutaron. | Retirados provider, API Dio, resolver directo y tests ejecutables Miruro; fuentes de pruebas archivadas como `.dart.txt`; README, arquitectura, STATUS, HANDOFF, PROGRESS, TESTING y memoria actualizados. Contratos, manager, source switch, mock y engine conservados. | Runtime sin providers/resolvers concretos; playback externo 0/70; S0 incompleta; esperar siguiente prompt; sin commit ni push |

## Evidencia histórica de proveedores

La siguiente matriz describe intentos anteriores a la limpieza y no representa
adaptadores registrados en el runtime actual.

| ID proveedor | Búsqueda | Episodios | Fuentes | libmpv real | Idiomas confirmados | Última prueba | Estado |
|---|---|---|---|---|---|---|---|
| animeav1 | búsqueda/episodio probados | Shingeki no Kyojin 1 | public embed | `unauthorized`; no abre | japonés (etiqueta del adaptador) | 2026-11-15 | `RESOLVING` |
| tioanime | título exacto probado | Shingeki no Kyojin 1 | 5 hosts distintos | última prueba: 3 unsupported, timeout, error de red; corrida histórica URI sin playback | español (etiqueta del adaptador) | 2026-11-15 | `RESOLVING` |
| animegg | búsqueda exacta probada | One Piece 1 | `vidcache.net`; calidad/idioma no contados como host | 5311 ms, audio detectado, video `nullxnull` | subbed/dubbed | 2026-11-15 | `RESOLVING` |
| anizone | búsqueda estática; episodio vía Livewire | no recorrido por bloqueo | `vid-cdn.xyz` | manifiesto 404 por Range y GET; acción pública 419 | — | 2026-11-15 | `BLOCKED_EXTERNAL` |

Agregar nuevos proveedores solo con datos observados. No convertir nombres de una lista en proveedores funcionales.

## Evidencia 70 animes

Ubicación recomendada al ejecutarse T21: `docs/ai-system/missions/evidence/70-animes.csv` y `70-animes.md`. No vienen rellenados para no inventar resultados. Contador aprobado = filas únicas con `status=PASS`, primer frame y avance verificados.
