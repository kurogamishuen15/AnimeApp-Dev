# F2.3 — Controles básicos por teclado y fullscreen GTK

Fuente: autorización directa del propietario y operación integral F2.3–F2.10.
Fecha: 2026-11-10
Módulo: reproductor opt-in `app/`
Estado: implementación y verificaciones ejecutadas; aceptación del propietario pendiente
Decisión: Player único, controles pasan por coordinator, GTK window controller
separado de la sesión de playback; continuar F2.4 bajo autorización vigente.
Evidencia: [reevaluación de fullscreen](../../ai-system/audits/F2.3-fullscreen-reevaluation-2026-11-10.md),
[README app/player](../../../app/lib/app/player/README.md),
[PROGRESS](../../../PROGRESS.md), [TESTING](../../../TESTING.md).

## Resultado

- Espacio/K alternan Play/Pause mediante el coordinator.
- Flechas izquierda/derecha hacen seek relativo de 10 segundos; arriba/abajo
  ajustan volumen del Player en 5 puntos con límites 0–100.
- F y el botón fullscreen comparten `_toggleFullscreen`; Escape sale solo tras
  observar fullscreen GTK.
- Se reprodujo el defecto F/F en Fedora KDE Wayland. GTK enviaba la confirmación
  correcta, pero el valor booleano instantáneo devuelto por el método de orden
  podía llegar tarde y revertir el estado. `setFullscreen` devuelve ahora null
  y solo `fullscreenChanged` confirma el estado real.
- `_dispatchGeneration` permite una transición nueva tras la observación nativa
  e invalida Futures antiguos para que no toquen la transición posterior.
- No se comprobó la salida de audio con loopback acústico ni el foco de la
  ventana después de hacer clic en un control real.

## Verificación

- Flutter window/page focalizados: 20 pruebas, exit 0.
- CI local con Flutter 3.47.9/Dart 3.13.7 aislado: exit 0; 40 pruebas Python,
  format/analyze/import checks, Flutter analyze sin issues y 118 pruebas
  Flutter.
- Build Linux release `-t lib/main_player_spike.dart`: exit 0.
- Capturas Fedora KDE Wayland: F entra, F sale, F reentra, Escape sale;
  reproducción muestra progreso y fotogramas cambiantes fullscreen. Cierre
  desde fullscreen produjo cleanup Dart, aceptación GTK y salida del proceso.
- Auditor `auditor_codigo` revisó secuencialmente el fix y su test. Confirmó
  que la generación invalida la respuesta antigua; no ejecutó GUI ni build.
- En salida aparece un aviso Flutter embedder `FlutterEngineRemoveView ...
  kInvalidArguments` después del handshake normal. Se conserva como observación,
  sin evidencia de proceso o recurso que siga activo.

## Siguiente

F2.3 está implementada y verificada, no formalmente aceptada. La autorización
integral permite continuar a F2.4. Inspeccionar y extender el coordinador
existente antes de modificar contratos; cubrir la matriz de estados y casos
concurrentes con FakeEngine determinista. No iniciar módulos dependientes si
F2.4 deja transiciones esenciales sin verificar.
