# Reevaluación externa de Kongroo — Bloque A

**Fecha:** 2026-11-15<br>
**Alcance:** respuesta a A-EXT-01–06; T00–T03/G1 únicamente.<br>
**Checkout:** `main`, `HEAD b1bd952ac03c8711ce50cf22d249fa448d2e2880`; base del Bloque A `33ceaef5b996c55577524c3448bbb4bee5363952`.<br>
**Resultado:** los criterios técnicos de G1 pasan; el gate queda `AUDITING` hasta aceptación propietaria. No se inició T04/B.<br>
**Git:** sin commit ni push de esta reevaluación.

## Resumen

Se corrigieron los problemas de cancelación/cierre de inicio, la clasificación
entre propiedad del Player nativo y limpieza auxiliar, y la precedencia de las
preferencias de pantalla inyectadas. El primer CI posterior a estos cambios
encontró que la vista importaba `ActivePlayerLease` desde `data`; se movió la
traducción de contención al composition root. El CI completo volvió a pasar.

La frase HTTP histórica sigue sin atribución y no se marca como corregida. Los
logs originales del incidente y del intento nativo de 45 s no están disponibles;
se guardaron logs crudos de esta reevaluación. El intento doble nativo no se
repitió. La prueba libmpv ejecutada crea un único Player, reproduce la fixture
local y verifica que un segundo constructor se rechaza antes de asignar otra
instancia.

## Respuesta a hallazgos externos

| Hallazgo | Estado | Evidencia / límite |
|---|---|---|
| A-EXT-01, P1 — ruta atrapada durante apertura pendiente | Corregido | Cancelación cooperativa, regreso al catálogo y supervisión del Future original. Si el Future entrega una sesión tarde, se cierra; no se cancela una llamada nativa ni se libera su lease antes de confirmar cleanup. Regresión en `provider_playback_route_test.dart`. |
| A-EXT-02, P2 — clasificación de cleanup | Corregido | Fallo de `Player.dispose()` conserva lease; fallo auxiliar después de dispose nativo confirmado no lo conserva. La ruta bloquea solo si `nativePlayerStillOwned`; test de limpieza auxiliar en `media_kit_spike_dispose_failure_test.dart` y cobertura de ruta. |
| A-EXT-03, P2 — mensaje HTTP sin atribución / bundle ausente | No reproducido; no corregido | `rg` actual no encuentra la frase en `app/lib` (`t01-source-search.log`). El log original y el bundle histórico no están disponibles; no se buscó atribuirlo a una versión o proveedor. Se mantiene `UNATTRIBUTED / NOT_REPRODUCED` en el [incidente](../incidents/PLAYBACK-HTTP-ERROR-UNATTRIBUTED-2026-11-15.md). |
| A-EXT-04, P2 — logs ausentes / intento de 45 s | Parcial con límite explícito | Los logs nuevos de pruebas focalizadas, libmpv y CI están guardados localmente en `.ai-local/review/block-a-reassessment-2026-11-15/`. El log histórico íntegro de 45 s no se halló; ese intento continúa fallido/no aprobado y no se repitió. La prueba nueva `libmpv-single-owner-contention.log` usa un solo Player y rechaza el segundo constructor. |
| A-EXT-05, P3 — defaults de pantalla sobrescriben display inyectado | Corregido | `initialFit` y `initialAspect` son overrides opcionales; las opciones por defecto conservan preferencias del controlador inyectado. Regresión en `spike_player_page_test.dart`. |
| A-EXT-06, P2 — cronología Git inconsistente | Corregido en documentación | STATUS/HANDOFF y memoria distinguen el commit/push autorizado del Bloque A original de la exportación ZIP posterior y de esta reevaluación sin commit. HEAD no cambió; la igualdad local con `refs/remotes/origin/main` no es una consulta remota en vivo. |

## Cambios examinados

- `ProviderPlaybackRoute` permite cancelar la espera de apertura y salir de la
  ruta mientras sigue observando el Future original. La sesión tardía se cierra
  en background; el lease nativo no se libera por temporizador.
- `SpikePlayerModule` separa la contención del lease de un fallo de cleanup y
  traduce `ActivePlayerLeaseInUse` a `PlaybackRoutePlayerBusy` para la ruta. La
  UI ya no importa `data`.
- `MediaKitSpikeEngine` libera el lease únicamente tras confirmar
  `Player.dispose()`, aunque la limpieza posterior de streams/subscriptions
  falle. No reintenta un dispose nativo cuyo resultado quedó incierto.
- `SpikePlayerPageOptions` deja ausente la selección de fit/aspect cuando el
  entorno no declara un override.
- READMEs de player/engine, incidente, PROGRESS, TESTING, PROJECT_STATE,
  AI_HANDOFF, STATUS y HANDOFF reflejan el comportamiento y los límites nuevos.

## Verificación ejecutada

Toolchain de proyecto `.ai-local/toolchains/flutter-3.47.9`, con paquetes Pub
resueltos offline. No se modificó el SDK externo/global.

| Comprobación | Resultado |
|---|---|
| Pruebas focalizadas de ruta, módulo, página y cleanup | 43/43 pasan; `layer-fix-focused-tests.log` |
| Prueba real libmpv single-owner | 1/1 pasa con fixture local; `libmpv-single-owner-contention.log` |
| `flutter analyze --no-pub` | Exit 0, sin issues; registro en `ci-after-layer-fix.log` |
| `dart analyze lib test` | Exit 0; registro en `ci-after-layer-fix.log` |
| `bash scripts/ci.sh` | Exit 0: 40 pruebas Python y 269 Flutter pasan; 6 opt-in omitidas |
| Checker positivo/negativo y límites reales | Exit 0; dos positivos y doce negativos; 30 archivos player y 34 domain comprobados |
| `dart format --output=none --set-exit-if-changed` | Exit 0; 183 archivos, 0 cambios de formato |
| `python3 tools/ai/memory.py check` | Exit 0, `[]` |
| `git diff --check` | Exit 0 al finalizar la reevaluación |

El primer log de CI (`ci.log`) conserva la violación UI→data detectada en el
primer rerun. Se corrigió esa frontera; el log final `ci-after-layer-fix.log`
termina con `CI local completada.` y exit 0. `flutter pub get --offline`
modificó temporalmente `app/pubspec.lock`; se restauró desde el backup local
previo y su SHA-256 coincide con `pubspec-lock.sha256.before`.

Las salidas crudas están bajo `.ai-local/review/block-a-reassessment-2026-11-15/`.
No contienen el log histórico original del timeout ni el bundle mencionado en
la revisión. No se generó evidencia retroactiva para esos archivos ausentes.

## Segunda pasada y gate

Hice una lectura adversarial post-fix del lifecycle, del contrato de errores, de
la frontera de imports y de las regresiones; la pasé por análisis, tests y CI.
No es una revisión independiente nueva. La auditoría independiente disponible
es anterior a estos fixes; dejo esta limitación explícita para quien revise el
checkout después de esta misión.

No quedan P0/P1 abiertos dentro de T00–T03. El incidente A-EXT-03 permanece
abierto como dato histórico no atribuido, y la falta de los logs originales no
se oculta. La evidencia satisface los criterios técnicos de G1 (código
analizable/CI, diagnóstico documentado y P0/P1 del bloque resueltos). El estado
formal queda **AUDITING hasta aceptación del propietario**; no se marca la fase
completada ni se avanza automáticamente. El intento con dos Players nativos a
45 s no se considera aprobado; no se repitió.

## Límites y trabajo no ejecutado

- T04/B no se inició; no es elegible hasta la aceptación propietaria de G1.
- No se hicieron requests a proveedores ni reproducción externa: `0/70`.
- No se midió rendimiento en hardware de 4 GB ni se validó una ventana gráfica
  como parte de esta reevaluación.
- Sigue faltando una prueba end-to-end automatizada del ciclo nativo completo de
  `VideoController` con el compositor.
- No hubo commit ni push; se preservaron los artefactos sin seguimiento previos.
