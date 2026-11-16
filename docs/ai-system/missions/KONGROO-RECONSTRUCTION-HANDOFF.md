# KONGROO — HANDOFF DE RECONSTRUCCIÓN

> Estado histórico actualizado el 2026-11-15. El punto vigente de reanudación S0-R está primero; los bloques siguientes conservan handoffs históricos.

## Punto actual de reanudación — S0-R AnimeHeaven — 2026-11-16

- **Resultado:** `AnimeHeavenPlaybackProvider` y `AnimeHeavenMp4Resolver` están
  registrados en `PlaybackProvidersModule`, usando `PlaybackProviderManager`,
  la ruta y el único motor libmpv existentes. One Piece ep. 1 publicó tres
  mirrors (`cx`, `ct`, `ck`); los tres llegaron al player por separado y
  mostraron error de apertura/decodificación sin imagen.
  Conteo: 1 provider implementado, 0 reproducibles, 0/70.
- **Evidencia:** `.ai-local/review/s0r-animeheaven-visible.png` y
  `s0r-animeheaven-mirror-switch.png` muestran `ct`; `s0-animeheaven-mirror-cx.png`
  y `s0-animeheaven-mirror-ck.png` muestran los otros dos intentos. No hay log
  nativo persistido. El propietario respondió «Autorizar manualmente en KDE»;
  una captura posterior no mostró el diálogo, aunque Wayland MCP siguió con
  `Transport closed`. No se simuló entrada y no se guardaron URIs efímeras.
- **Validación del código actual:** 13/13 pruebas focalizadas y 48/48
  regresiones focalizadas de provider/manager/route pasaron; Flutter analyze
  completo y Dart analyze de provider/resolver/tests/harness no reportan issues.
  El test live bajo `flutter test` no sirve porque el binding intercepta
  HTTP y responde 400; la ventana/harness es la prueba live apropiada.
- **Módulos:** `app/lib/data/player/providers/animeheaven/` y
  `app/tool/animeheaven_live_harness.dart`; guía en sus README. Para repetir,
  leer primero `app/tool/README.md` y usar el SDK ya aislado del proyecto.
- **Siguiente acción:** los tres mirrors publicados por este episodio ya están
  agotados y no deben repetirse sin evidencia de cambio. Los otros nombres de
  la allowlist no se ofrecieron y no se deben construir a mano. En las rutas
  live ya probadas no queda una fuente elegible con media estática. Esto no
  significa que todo el inventario esté agotado: la revisión upstream de
  Anivexa documenta 28 candidatos y solo sondeó AniChan, AniPM y Zoko. El
  siguiente paso seguro es revisar estáticamente un candidato no probado y
  continuar solo si documenta un host distinto y una ruta pública ordinaria;
  como máximo se hará un GET ordinario y se detendrá ante 403, sesión,
  autenticación, challenge o transformación protegida. Para éxito, libmpv debe
  mostrar frame, dimensión y avance; un probe HTTP no basta.
- **Rendimiento:** no medido con esta integración; la medición previa se hizo en
  host de 7.5 GiB y no valida el objetivo Fedora de 4 GB.
- **Diagnóstico diferencial pendiente:** `mpv` CLI no está disponible en PATH
  (`mpv --version` no se pudo ejecutar). No instalar binarios en el sistema;
  continuar ese A/B solo si el propietario habilita un ejecutable aislado o
  aparece uno ya instalado.
- **Git:** preservar todo el estado sucio, sin staging, commit ni push. Rama
  `main`, HEAD `b1bd952ac03c8711ce50cf22d249fa448d2e2880`.
- **Auditoría:** `docs/ai-system/audits/S0R-ANIMEHEAVEN-audit-2026-11-16.md`.

### Handoff histórico — S0-R Gates 0–1 — 2026-11-16

- **Gate:** 0 `PARTIAL`; el player local se abrió con libmpv y el test sintético
  release fue visible en Wayland a 00:00:02.458. No se reprodujo media externa:
  S0 permanece `0/70`.
- **Pruebas actuales:** Flutter suite 268 pass/6 optativas omitidas; 40 Python;
  Flutter/Dart analyze, formato, checker y memory check pasaron. Los logs
  detallados están en `.ai-local/review/s0r-baseline-2026-11-16/`.
- **Métricas locales:** release sintético 480×270/24 fps de archivo, 8.010 s,
  CPU 28.84% de un núcleo, RSS 245,708–258,440 KiB. Esta máquina tiene 7.5 GiB,
  no 4 GB; media_kit registró `S/W rendering`. No hay FPS de salida ni frame
  drops confirmados. El RSS del proceso headless subió luego de veinte ciclos,
  sin demostrar una fuga.
- **Cambios de esta ejecución:** `docs/ai-system/missions/S0R-BASELINE.md`,
  índice `S0R-MASTER-MISSION.md`, STATUS/HANDOFF y memoria del proyecto;
  evidencia local ignorada en `.ai-local/review/s0r-baseline-2026-11-16/`.
  Ningún código de provider o engine se cambió en Gate 0.
- **Git:** `main` en `b1bd952ac03c8711ce50cf22d249fa448d2e2880`; preservar los
  cambios sucios preexistentes. No staged, no commit ni push.
- **Próximo paso exacto:** inspeccionar código/licencia de una fuente
  independiente no probada que no requiera challenges, autenticación,
  descifrado ni impersonación. Solo hacer una solicitud pública ordinaria si
  el protocolo es elegible. No repetir los seis probes iniciales ni los cuatro
  hosters AniWorld ya observados. Ver
  `S0R-REFERENCE-REVIEW-2026-11-16.md`.
- **Actualización Gate 1:** AniWorld aceptó búsquedas/ficha/episodio públicos
  de One Piece. Los hosters Doodstream, Filemoon y Vidmoly dieron 403; VOE
  publicó una redirección JavaScript con lectura opcional de
  `localStorage.permanentToken`, sin media estática. No se siguió el destino,
  no se automatizó JavaScript, no se copió código y no se añadió adapter. STATUS,
  el índice maestro, el informe de reproducción y memoria ya registran esto.
- **Límite actual:** captura/sesión sin entrada de teclado y puntero; baseline
  visible fue capturado con Spectacle, pero la medida de `scripts/measure.sh`
  quedó incompleta porque el entrypoint spike no emite su marca de main app.
  Ver [`S0R-BASELINE.md`](S0R-BASELINE.md).

## Snapshot histórico — limpieza de providers S0

- **Resultado:** el provider y resolver Miruro fueron retirados; el GET público
  previo devolvió 403 y no produjo episodio, media ni reproducción. En ese
  corte el runtime no registraba providers externos ni resolutores concretos.
- **Conservado:** `PlaybackProviderManager`, sus contratos/validaciones,
  `PlaybackVideoHostResolver`, `PlaybackSourceSwitchService`, el mock y el único
  engine media_kit/libmpv. No se modificaron el engine ni la UI funcional.
- **Pruebas:** las suites Miruro se copiaron como `.dart.txt` no ejecutable a
  [`archivo S0-A`](../../ai-system/archive/S0-A-miruro-tests-2026-11-15/); la
  prueba activa de composición ahora exige cero adapters externos. La limpieza
  se valida en la auditoría de seguimiento enlazada abajo.
- **S0:** permanece incompleta, `0/70`, sin cierre de G1/T03 ni avance a F1.
  AnimeAV1, TioAnime, AnimeGG, `PublicSiteHttp` y `PublicMediaVideoHostResolver`
  ya se habían retirado en una limpieza anterior; sus resultados y logs siguen
  archivados.
- **Siguiente tarea:** esperar el próximo prompt de integración. No reactivar
  Miruro ni implementar proveedores/servidores por iniciativa propia.
- **Informe:** [auditoría de seguimiento](../audits/S0-provider-cleanup-followup-audit-2026-11-15.md),
  [estado S0](KONGROO-RECONSTRUCTION-STATUS.md), [informe histórico S0-A](S0-ANILILI-PORT-REPORT.md).

## Registro histórico — implementación S0-A de Miruro

> El estado y la siguiente tarea descritos en este snapshot quedaron
> reemplazados por la limpieza de seguimiento de la cabecera. Este bloque
> conserva únicamente el registro de la implementación retirada.

- **Alcance completado en esta ejecución:** adaptación del catálogo Miruro de
  Anilili, provider y resolver directo conectados al manager y al `PlaybackEngine`
  existente; no se añadió otro reproductor. Los módulos y README están en
  `app/lib/data/player/providers/miruro/`.
- **Estado del provider:** implementado, no funcionalmente confirmado. Los GET
  ordinarios a config/lookup devolvieron 403. No obtuvo episodios ni media; no
  se reprodujo video externo. Conteo real permanece `0/70`.
- **Seguridad:** sin cookies, auth, challenges, perfil de navegador ni
  reintentos/mirrors tras 403. El resolver bloquea redirects y destinos DNS no
  globales; el filtro IPv6 es conservador y tiene prueba de prefijos especiales.
  Queda DNS TOCTOU porque libmpv resuelve de nuevo. HLS no se valida por GET ya
  que no se recibió un manifiesto accesible.
- **Verificación:** `scripts/ci.sh` pasó el 2026-11-15 con Flutter
  3.50.0-0.4.pre/Dart 3.14.0 aislado: 40 Python, 288 Flutter y 7 optativas
  omitidas; análisis, formato, checker y memoria pasaron. `flutter build linux
  --release --no-pub` también pasó. El smoke live con el
  cliente real clasificó 403 como `unauthorized`, no como éxito.
- **Sin evidencia:** playback externo, revisión de ventana Wayland, rendimiento
  en Fedora de 4 GB y mediciones de consumo/fugas durante streaming.
- **Siguiente tarea:** revisar estáticamente las implementaciones Anivexa
  requeridas por la misión; solo probar rutas GET públicas ordinarias. No
  reiterar el 403 de Miruro sin cambio observable en disponibilidad. No iniciar
  el siguiente bloque de reconstrucción ni marcar G1/Fase 1 como cerrados.
- **Informe:** [S0-A](S0-ANILILI-PORT-REPORT.md), [auditoría](../audits/S0-ANILILI-port-audit-2026-11-15.md), [STATUS](KONGROO-RECONSTRUCTION-STATUS.md).

## Snapshot histórico previo: primera limpieza S0

## Punto de reanudación histórico: limpieza previa S0

- **Prioridad actual:** limpieza S0 verificada; integración de providers en pausa hasta el siguiente prompt del propietario. No iniciar Miruro, Anivexa ni otros servidores todavía.
- **Estado formal del plan:** Bloque A/T03 y G1 siguen `AUDITING` hasta aceptación propietaria. La orden S0 autoriza continuar con proveedores, pero no acepta G1 retroactivamente.
- **Última tarea S0:** retirada controlada de AnimeAV1, TioAnime, AnimeGG, `PublicSiteHttp` y `PublicMediaVideoHostResolver`. Se conservaron los contratos, manager, circuit breakers, source switching, mock y engine.
- **Siguiente tarea elegible:** esperar el siguiente prompt del propietario. No registrar ni implementar providers antes de esa instrucción.
- **Estado S0:** incompleta y en pausa. La app registra 0 providers externos y 0 resolutores concretos; la matriz histórica contiene 22 candidatos y 0/70 reproducciones confirmadas.
- **Auditorías S0:** [proveedores](../audits/S0-provider-audit-2026-11-15.md), [hosts](../audits/S0-video-host-audit-2026-11-15.md) y [limpieza previa](../audits/S0-provider-cleanup-audit-2026-11-15.md). El P1 de reproducción externa sigue abierto.
- **Rama:** `main`; base de Bloque A `33ceaef5b996c55577524c3448bbb4bee5363952`. HEAD y referencia local `origin/main` al inicio de esta reevaluación: `b1bd952ac03c8711ce50cf22d249fa448d2e2880`.
- **Cronología Git:** el commit `b1bd952` materializó Bloque A después de una autorización explícita de commit/push. La tarea posterior de exportar el ZIP no cambió código ni Git; su respuesta “sin commit/push” describía esa exportación. En esta reevaluación las correcciones son locales, sin commit ni push. La igualdad local `HEAD == origin/main` no sustituye una consulta remota en vivo.
- **Cambios preexistentes al comenzar:** `KONGROO_RECONSTRUCCION_CODEX_T00-T24.zip` y `docs/ai-system/missions/KONGROO-RECONSTRUCTION-AUTOMATION.md` sin seguimiento; ambos se preservaron. El proceso existente `anime_app` PID 8241 permaneció abierto en Home y no se inició otra ventana.
- **CI de Bloque A original:** exit 0 con Flutter 3.47.9 aislado; 40 pruebas Python y 262 Flutter pasaron, 6 opt-in omitidas. Es un resultado histórico, no valida los cambios locales de esta reevaluación.
- **Auditoría externa:** A-EXT-01/02 se corrigieron con pruebas; A-EXT-05 con precedencia explícita y test. A-EXT-03 queda `UNATTRIBUTED / NOT_REPRODUCED`; el intento de dos aperturas nativas a 45 s sigue no aprobado. El revisor externo no examinó el checkout post-fix; el coordinador hizo una segunda pasada local adversarial, no independiente.
- **Pruebas focalizadas de reevaluación:** 43/43 pasan con Flutter 3.47.9 aislado: ruta, module, página, limpieza del engine y distinción entre cleanup auxiliar y lease nativo.
- **Pruebas actuales de S0:** 41 pruebas focalizadas pass, 3 smokes omitidas; Flutter/Dart analyze limpios; integración Referer/libmpv loopback 1/1. Los smokes live actuales de TioAnime y AnimeGG fallan por ausencia de video. Ver [auditoría de hosts](../audits/S0-video-host-audit-2026-11-15.md).
- **Verificación posterior a la limpieza:** `flutter analyze --no-pub` y `dart analyze lib test` sin issues; `flutter test --no-pub` pasó con 267 pruebas y 6 optativas omitidas. No se ejecutaron solicitudes live nuevas. Detalle en [auditoría de limpieza](../audits/S0-provider-cleanup-audit-2026-11-15.md).
- **Análisis y CI de reevaluación:** `flutter analyze --no-pub`, `dart analyze lib test` y `scripts/ci.sh` pasan. CI: 40 tests Python, 269 Flutter; 6 opt-in omitidas. Checker, formato, integridad de memoria y diff pasan.
- **Logs:** salidas crudas en `.ai-local/review/block-a-reassessment-2026-11-15/`; `ci.log` conserva el fallo del checker encontrado y corregido; `ci-after-layer-fix.log` es el resultado final.
- **Límite de prueba:** un intento real de abrir dos `SpikePlayerModule` concurrentemente con libmpv terminó en timeout a 45 s; se retiró el test y no se declara aprobado. El test de integración controlado mantiene un solo Player nativo y verifica que un segundo constructor se rechaza antes de crear otra instancia.
- **Reproducción externa verificada antes de S0:** `0/70`; esa reevaluación de Bloque A no probó streams. En S0 ya se intentó libmpv con TioAnime y falló; AnimeAV1 no entregó URI al resolver.
- **Cierre de lockfile:** `pub get --offline` modificó transitoriamente la selección de `listen`/`test_api`; `app/pubspec.lock` fue restaurado al backup anterior y el SHA-256 coincide.

## Procedimiento de reanudación obligatorio

1. Lee este HANDOFF y `KONGROO-RECONSTRUCTION-STATUS.md`.
2. Lee las secciones de plan correspondientes al primer bloque incompleto; no vuelvas a hacer una investigación ya aceptada salvo evidencia de cambios.
3. Verifica con Git los archivos que cambiaron desde la última ejecución, sin sobrescribir trabajo ajeno.
4. Si hay un proceso paralelo trabajando sobre los mismos archivos, no comiences una edición concurrente.
5. Ejecuta únicamente el alcance confirmado por el propietario; por ahora S0 espera el siguiente prompt y G1/B–F mantienen su estado formal.
6. Actualiza STATUS y este HANDOFF antes de finalizar.
7. **No commit ni push** sin autorización expresa.

## Registro de decisiones (actualizar)

| Fecha | Decisión | Motivo/Evidencia | Implicaciones |
|---|---|---|---|
| Inicial | Mantener núcleo F1 y motor actual mientras sean válidos | Auditoría de lectura | Refactorización quirúrgica, no borrado indiscriminado |
| Inicial | Separar búsqueda, episodio, resolución y reproducción | Diferentes contratos y pruebas | Evitar falsos positivos HTTP 200 |
| Inicial | Ejecutar un bloque por corrida | Dependencias entre contratos y consumidores | Evitar avance no verificado |
| 2026-11-15 | El análisis de esta misión usa `.ai-local/toolchains/flutter-3.47.9` | El Flutter original de PATH falló con una trama LSP JSON incompleta; el SDK aislado terminó CI exit 0 | No tocar SDK externo/global ni reducir reglas |
| 2026-11-15 | La pantalla recibe opciones de diagnóstico tipadas desde composición | El checker detectó lectura directa de `Platform.environment`/`dart:io` en `SpikePlayerPage` | Mantener acceso al proceso únicamente en el composition root; overrides opcionales preservan preferencias inyectadas |
| 2026-11-15 | Cancelar startup es cooperativo | Una operación nativa pendiente no es cancelable con seguridad desde Flutter | La ruta puede volver, pero el Future queda supervisado y el lease no se libera hasta cleanup confirmado; reiniciar si no responde |
| 2026-11-15 | La UI distingue propiedad nativa de cleanup secundario | A-EXT-02 encontró que cualquier error de cleanup bloqueaba navegación | Solo mantener el bloqueo si `nativePlayerStillOwned`; avisar si falló cleanup no nativo |
| 2026-11-15 | La contención del lease se expresa mediante `ActivePlayerLeaseInUse extends StateError` | El route reconoce contención sin tratarla como rollback fallido; consumidores previos esperan `StateError` | Conservar el error tipado y compatibilidad del contrato existente |
| 2026-11-15 | La ruta recibe `PlaybackRoutePlayerBusy`; el módulo traduce `ActivePlayerLeaseInUse` | Checker de imports encontró dependencia UI→data durante el primer rerun de CI | Mantener el panel independiente de la implementación del lease; no ocultar el gate |

## Cambios y pruebas de última corrida

```text
fecha_utc: 2026-11-15
rama: main
head_antes: 33ceaef5b996c55577524c3448bbb4bee5363952
head_commit_bloque_a: b1bd952ac03c8711ce50cf22d249fa448d2e2880
head_actual_reevaluacion_inicio: b1bd952ac03c8711ce50cf22d249fa448d2e2880
head_final: b1bd952ac03c8711ce50cf22d249fa448d2e2880 (sin commit de reevaluación)
bloque: A
tarea: A-EXT-01–06; evidencia técnica G1 pasa; estado AUDITING hasta aceptación propietaria; T04/B no ejecutado
archivos: ruta/sesión/player, engine/lease, opciones, pruebas player, README app/player y engine, registro de incidente T01, PROGRESS/TESTING/memoria, STATUS/HANDOFF y auditoría de reevaluación
comandos_y_exit: 43 pruebas focalizadas exit 0; prueba libmpv single-owner 1/1; flutter analyze exit 0; dart analyze lib test exit 0; scripts/ci.sh exit 0 (40 Python + 269 Flutter, 6 opt-in omitidas); checker/formato/memoria/diff check exit 0
logs: .ai-local/review/block-a-reassessment-2026-11-15/; `ci.log` primer rerun fallido por import UI→data y `ci-after-layer-fix.log` CI final verde
timeout_45s: intento histórico de dos módulos libmpv simultáneos no aprobado; no repetido; test de contención controlada mantiene un Player y rechaza un segundo constructor
hallazgos: A-EXT-01/02/05 corregidos; A-EXT-03 continúa UNATTRIBUTED/NOT_REPRODUCED; A-EXT-04 logs originales históricos no disponibles pero evidencia actual capturada; A-EXT-06 cronología aclarada; segunda pasada local no independiente
git: sin commit/push; HEAD no cambió; ZIP y AUTOMATION.md sin seguimiento se preservan; pubspec.lock restaurado al hash previo
siguiente_tarea: ninguna en esta ejecución; solicitar aceptación propietaria de G1. T04–T08 quedan sin iniciar
```

## Reglas de cierre

- No marcar éxito sin evidencia del criterio de aceptación.
- No borrar cambios de otro agente ni utilizar operaciones Git destructivas.
- No copiar a la nueva sesión tokens, URLs temporales o registros sensibles.
- Si el bloque queda `BLOCKED`, conservar evidencia e indicar exactamente qué depende de él.
- Si todos los gates realmente están `DONE`, comunicar finalización y no volver a ejecutar la reconstrucción.

## Snapshot histórico S0 — estado inmediatamente posterior a la limpieza

```text
fecha: 2026-11-15
raiz: /home/kyouma/Vídeos/PROYECTO ANIME
rama: main
head: b1bd952ac03c8711ce50cf22d249fa448d2e2880 (sin commit)
prioridad: limpieza S0 completada; integración de providers en pausa hasta el siguiente prompt; G1/T03 sigue AUDITING, sin aceptar
inventario: 22 candidatos históricos; cero providers externos y cero resolutores concretos registrados; 0/70 playback externo
reproduccion: 0 proveedores; 0/70 títulos; no se confirmó video externo
arquitectura: contratos AnimeProvider/VideoHostResolver, manager, breakers, source switch y PlaybackEngine existentes conservados; composition root vacío
pruebas_anteriores: 41 suite resolver/providers+manager/domain y 35 route/coordinator; integración Referer/libmpv local 1/1; analyze limpio; smokes Tio/AnimeGG fallaron aceptación. No describen el árbol actual
pruebas_limpieza: Flutter analyze exit 0; Dart analyze exit 0; suite Flutter exit 0 (267 pass, 6 optativas skip); formato, enlaces locales (17 documentos), memory.py check y diff checks exit 0; ver auditoría de limpieza
live_tioanime: 5 alternativas: Mega/OK.ru/Netu unsupported, StreamSB timeout, YourUpload network; ninguna URI/libmpv
live_animeav1: lookup entregó fuente; resolver devolvió unauthorized; no se eludió la denegación
live_animegg: One Piece episodio 1, cinco variantes de idioma/calidad (no cinco hosts); variante preferida resolvió vidcache, libmpv avanzó 5311 ms y detectó audio, video=nullxnull
live_anizone: host vid-cdn observado; manifiesto devolvió HTTP 404 tanto por Range como por GET normal; acción Livewire pública 419
inventario_host: Mega, StreamSB/embedsb, YourUpload, OK.ru, Netu/HQQ, AnimeAV1/Zilla, vidcache, vid-cdn, CatStream, FlixCloud y MegaPlay; CatStream sin URI estática; fuente upstream de FlixCloud indica token/stream vía enc-dec.app y segmentos XOR transformados por proxy local (sin verificar flujo directo ni implementar); MegaPlay con etapa crypto no ejecutada; FileStream/Bee/Goma sin evidencia de aparición
kickassanime: kaa.lt búsqueda/detalle/lenguaje/episodio/CatStream públicos; página CatStream sin manifiesto/URI estática; upstream usa firma/AES para servidores legacy, no adaptado
sondeos: Ninja ww3/ww4, JKAnime, AnimeJara /catalogo/ y Latanime 403; Henaojara 301 hacia AnimeJara (no seguido); AnimeKai .to/.fi/.gs sin DNS; AllAnime allmanga.to raíz 200 sin rutas parseables (no se siguió el flujo Cloudflare); Animeflv.one portada/búsqueda/2 fichas 200 pero sin rutas de episodio; animeflv.net y anime1v.com HTTP 000; anime1v-api corresponde a scraper para AnimeAV1.com y requiere API key
logs: .ai-local/review/s0-real-playback-2026-11-15/ (salidas de smoke sanitizadas, sin URLs ni cookies)
documentos: S0-REAL-PLAYBACK-REPORT.md y auditorías previas conservadas; auditoría de limpieza; READMEs y TESTING actualizados
no_hecho: ficha AniList E2E live, primer frame externo, audio audible, seek y source switch con proveedor real; solo se probó fallback con fake y cambio de fuente libmpv con fixture local; 7 candidatos siguen en investigación parcial y AnimeV1 pendiente
git: cambios locales sin stage/commit/push; preservar ZIP, AUTOMATION.md y cambios previos del Bloque A
siguiente: esperar el siguiente prompt del propietario; no reactivar ni añadir providers por iniciativa propia
```
