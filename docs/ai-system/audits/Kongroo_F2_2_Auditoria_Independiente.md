# Kongroo — Auditoría técnica independiente F2.2

**Fecha de revisión:** 2026-11-09
**Objeto:** `Kongroo-F2.2-Auditoria.zip` recibido en la conversación.
**Dictamen:** **NO APROBADA PARA CIERRE**. El spike nativo es prometedor, pero existen defectos y pruebas pendientes.
**Método:** inspección estática de fuentes y documentación, verificación de SHA-256 de 34 archivos del inventario, `ffprobe` y decodificación completa del fixture con FFmpeg (salida 0). No se ejecutaron Flutter ni libmpv de Fedora en el entorno del revisor.

## Resumen ejecutivo

La arquitectura por capas es esencialmente correcta: `application/player` contiene un contrato temporal y un coordinador sin Flutter; `data/player/engine` traduce comandos a media_kit; `app/player` contiene composición, video y UI. Se respeta la separación con catálogo, Drift y progreso. Las versiones del lockfile documentadas son media_kit 1.2.6, media_kit_video 2.0.1 y media_kit_libs_video 1.0.7. El fixture presente incluye MPEG-4, AAC, 320×180, 24 fps y duración 8 s; su decodificación independiente con FFmpeg terminó sin errores.

Sin embargo, el conjunto de pruebas del reproductor consta de **3 tests de coordinación y 1 test nativo**. Las 66 pruebas Flutter reportadas corresponden a toda la aplicación. No existe evidencia de video visible en el compositor ni de salida de audio audible. El test nativo usa `withVideoSurface:false`, por lo que no prueba la ruta del VideoController. La auditoría local es estática; los resultados de CI son declaraciones del informe adjunto, no pruebas reejecutadas por este revisor.

## Hallazgos por prioridad

### A1. [ALTA] Doble reproductor posible durante `dispose` asíncrono

**Evidencia:** `app/lib/data/player/engine/media_kit_spike_engine.dart:12-24,111-120`.

La fábrica rechaza una instancia activa únicamente si `!active._disposed`. `dispose` cambia `_disposed=true` **antes** de esperar la cancelación de suscripciones y `await _player.dispose()`. Mientras este Future esté pendiente, una segunda llamada a la fábrica puede crear otro `Player` nativo. Además, si `_player.dispose()` falla, se omiten la limpieza de `_activeInstance` y el cierre de `_snapshots`.

**Acción:** introducir estado de cierre (`disposing` y `disposed`) y un `Future` de cierre compartido, mantener la exclusión hasta terminar la liberación, manejar `try/finally` cuidadosamente sin declarar liberación cuando el motor falló, y publicar errores diagnósticos recuperables. Añadir prueba de creación concurrente con cierre pendiente y prueba de excepción de liberación mediante un seam/fake de lifecycle, sin necesidad de añadir otro motor real.

### A2. [ALTA] Errores nativos efímeros

**Evidencia:** `media_kit_spike_engine.dart:134-149`.

`_copy` construye cada snapshot con `error: error`. En cualquier actualización `playing`, `position`, `buffering` o `duration`, el parámetro omitido es `null`, borrando el error anterior. La UI puede no mostrar el fallo o hacerlo solo un instante.

**Acción:** definir semántica explícita de error persistente o evento de error independiente; limpiar el error únicamente cuando comience una operación que lo resuelva (o haya reconocimiento explícito). Probar que un evento `position` posterior no lo borra.

### A3. [ALTA] El slider emite seek en cada cambio

**Evidencia:** `app/lib/app/player/spike_player_page.dart:79-89`, `spike_player_coordinator.dart:80-91`.

Cada actualización de arrastre llama al seek, que entra en una cola FIFO. Un arrastre rápido puede encadenar decenas de seeks, hacer que controles posteriores esperen y dejar una sensación de UI congelada. El informe lo reconoce como limitación del spike.

**Acción:** mantener posición visual temporal durante el arrastre; emitir una sola operación al soltar (`onChangeEnd`), o cancelar/confluir solicitudes de seek. Probar arrastre rápido, seek seguido de pausa y cierre durante una operación.

### A4. [ALTA] Cierre de la aplicación no observado ni comprobado

**Evidencia:** `app/lib/main_player_spike.dart:30-35` y `app/lib/app/player/spike_player_module.dart:34`.

El `State.dispose` invoca `unawaited(widget.module.close())`, sin observar resultado ni registrar fallo. Tampoco hay prueba de destrucción de ventana/proceso con ruta normal de cierre. El ciclo de vida de finalización del proceso puede no ejecutar ese método como se espera.

**Acción:** diseñar cierre ordenado explícito cuando sea posible, registrar o manejar fallos asíncronos y probar que una secuencia de salida cierra el recurso en condiciones normales. No prometer que terminación forzada del proceso invoque dispose.

### A5. [ALTA] Prueba del fixture no reproducible desde clon limpio

**Evidencia:** `app/test/player/media_kit_spike_integration_test.dart:10-12`; `docs/player/F2.2-spike-report.md:42-45,72-84`.

La prueba requiere `../.ai-local/f2.2/fixtures/spike.mp4`, mientras el informe declara que el fixture está excluido de Git. En un clon limpio, no está disponible y la prueba falla antes de crear Player. El ZIP de auditoría sí lo contiene, por lo que esta ejecución puntual es reproducible a partir del paquete.

**Acción:** proporcionar un fixture sintético pequeño versionado bajo directorio de pruebas, con licencia y SHA, **o** un generador reproducible invocado por el runner de pruebas con prerequisitos documentados. No depender de un archivo ignorado e invisible para CI.

### A6. [MEDIA] `stop` no verifica sus efectos ni reutilización

**Evidencia:** `app/test/player/media_kit_spike_integration_test.dart:60-66`.

El test solo espera que `engine.stop()` retorne sin excepción. No comprueba descarga, estado posterior ni apertura de otro medio con el mismo Player. Los `dispose` repetidos tampoco prueban cierre entre dos instancias diferentes.

**Acción:** comprobar el estado/playlist según la API pública real; ejecutar open/play de nuevo tras stop; verificar ausencia de errores y luego disponer. Mantener tolerancias de tiempo documentadas.

### A7. [MEDIA] Pruebas de errores, concurrencia y visualización insuficientes

**Evidencia:** `app/test/player/spike_player_coordinator_test.dart:8-54` (3 tests), `media_kit_spike_integration_test.dart:7-68` (1 test); informe `docs/player/F2.2-spike-report.md:63-70`.

No aparecen tests de URI `file:` inexistente o archivo corrupto, error nativo persistente, inicialización fallida con limpieza, cierre durante apertura, errores de dispose, varias operaciones en cola ni widget/superficie `VideoController` real. El test nativo configura `withVideoSurface:false`, así que no prueba textura ni compositor.

**Acción:** añadir pruebas focalizadas (fake para fallos de coordinación; runtime real para recursos) y comprobación manual del video en Fedora. Es posible además usar `VideoController.waitUntilFirstFrameRendered` con timeout como evidencia **de renderizado del controlador**, pero no sustituye la captura/observación de la ventana visible en el compositor. Ver documentación oficial: https://pub.dev/documentation/media_kit_video/latest/media_kit_video/VideoController-class.html

### A8. [MEDIA] Validación del origen `file:` solo en coordinador

**Evidencia:** `spike_player_coordinator.dart:38-44`, `media_kit_spike_engine.dart:80-84`.

El adaptador es invocable directamente y acepta cualquier `Uri`, aunque el alcance oficial F2.2 prohíbe fuentes remotas. La composición actual usa el coordinador, pero el adaptador no impone esa frontera.

**Acción:** aplicar validación de URI local también en el adaptador o hacer su método inaccesible fuera del flujo autorizado; probar rechazo de `https:` sin crear conexión.

### A9. [MEDIA] La cola puede impedir cierre si la operación anterior no acaba

**Evidencia:** `spike_player_coordinator.dart:70-91`.

`dispose()` entra en la misma cola que `open/play/seek`; si una operación anterior no termina, el cierre tampoco comienza. No hay timeout/cancelación ni estrategia para operaciones nativas pendientes. No es prueba de bloqueo observado, pero sí una propiedad estructural.

**Acción:** documentar y probar la política de cancelación/timeout del spike; impedir que una operación estancada deje el cierre indefinidamente pendiente. Elegir un mecanismo compatible con el comportamiento real de media_kit, sin añadir una máquina de estados avanzada fuera de F2.2.

### A10. [MEDIA] Limpieza incompleta si `SpikePlayerCoordinator.dispose` lanza

**Evidencia:** `spike_player_coordinator.dart:70-78`.

Marca `_disposed` antes de `await _engine.dispose()`. Si este último falla, `_states.close()` no se llama y los siguientes `dispose()` no intentan limpiar. Debe tratarse conjuntamente con A1 y A4.

### A11. [BAJA/MEDIA] UI y documentación no coinciden del todo

**Evidencia:** `app/lib/app/player/README.md:16` afirma que únicamente el puente visual importa `media_kit_video`, pero `spike_player_page.dart:4` también lo importa. Además, `main_player_spike.dart:5` importa `media_kit`, pese a la regla de mantener el acceso al wrapper concentrado en infraestructura. Se puede reducir el acoplamiento haciendo que la página reciba un widget de superficie o un contrato de presentación pequeño; el entrypoint puede delegar la inicialización al adaptador, que ya la realiza. Documentar las excepciones si se preservan.

### A12. [BAJA/MEDIA] Fixture path depende del directorio de ejecución

**Evidencia:** `app/lib/main_player_spike.dart:12-17`.

La ruta relativa al `Directory.current.parent` funciona si se arranca desde `app/`, pero falla al ejecutar el bundle desde otro directorio. Permitir una ruta explícita de desarrollo (`--dart-define`, argumento u otra configuración aislada) y documentar la ejecución.

## Documentación y modularización

**Acertado:** separación en `application/player` / `data/player/engine` / `app/player` sin duplicar Drift ni catálogo; `PlaybackSpikeEngine` temporal evita anticipar F2.5; README por módulo con tablas y límites; informe de pruebas reconoce ausencia de prueba visual.

**Por corregir:** README del módulo de presentación contradice importaciones; agregar diagramas de stop/dispose y propagación de errores, semántica documentada de cierre concurrente, casos de fallo, guías reproducibles con fixture accesible y referencia explícita al flujo de presentación verificado. Registrar cada archivo real y sus límites, sin crear carpetas vacías.

## Matriz mínima de aceptación adicional

| Requisito | Evidencia exigida |
| --- | --- |
| Una sola instancia | Test donde se intenta construir otra durante un dispose pendiente y después de un dispose completado |
| Errores persistentes | El error permanece tras otro evento hasta política explícita de limpieza |
| Open inválido | Archivo ausente/corrupto: fallo observable y posterior recuperación documentada |
| Play / Pause / Seek | Eventos nativos y posición observada con tiempos acotados |
| Arrastre UI | Una operación por gesto o conflación, sin cola excesiva |
| Stop / re-open | Medio descargado, misma instancia reutilizada y nuevo open reproducido |
| Dispose | No reentrancia, resultado observable, limpieza aun ante fallos controlados |
| Video real | `VideoController` inicializado con textura y evidencia manual de frame visible en Fedora |
| Audio | Pista detectada; salida audible probada o limitación explicitada |
| Reproducibilidad | Fixture disponible automáticamente en clon limpio / CI |
| Arquitectura | UI sin imports del motor salvo puente documentado, checker pasa |
| Documentación | README congruentes con código y pruebas; diagramas/links vigentes |

## Recomendación operacional

1. No iniciar F2.3 ni registrar F2.2 como aceptada.
2. Corregir los defectos A1–A5 y A10 dentro del alcance F2.2.
3. Fortalecer las pruebas A6–A9 y cerrar los puntos documentales A11–A12.
4. En el Fedora real, ejecutar la UI, verificar video visible, controles y audio, y registrar evidencia fechada y versión exacta.
5. Repetir CI y pruebas nativas con el SDK aislado. No declarar cerradas pruebas que no se ejecutaron.
6. Separar la auditoría legal de distribución (posterior) de los requisitos de ejecución de F2.2; identificar runtime y licencias disponibles sin bloquear indefinidamente un spike de desarrollo.

**Estado final:** F2.2 sigue **implementada parcialmente y no aceptada**, a pesar del éxito de la prueba nativa básica reportado por Codex.
