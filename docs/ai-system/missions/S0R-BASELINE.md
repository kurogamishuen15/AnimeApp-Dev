# S0-R — Baseline del reproductor

**Fecha:** 2026-11-16
**Gate:** 0 — congelar y medir antes de providers
**Estado:** `PARTIAL`
**S0:** abierta; reproducción externa `0/70`.

## Alcance y estado de Git

Se verificó la raíz Git `/home/kyouma/Vídeos/PROYECTO ANIME`, rama `main`,
HEAD `b1bd952ac03c8711ce50cf22d249fa448d2e2880`. El checkout ya estaba sucio
antes de esta misión: 52 archivos rastreados modificados/eliminados, más
archivos sin seguimiento y el adjunto. No había cambios staged. Entre los
cambios preexistentes están el contrato de playback, manager, route, coordinator,
engine, pruebas y documentación; este baseline valida el árbol de trabajo
actual, no un checkout limpio de HEAD. Se conservaron todos los cambios.

Durante Gate 0 no se editó código funcional del reproductor ni se activó un
provider. Flutter generó artefactos locales de compilación bajo `app/build/`.
La evidencia cruda y capturas se guardan en
`.ai-local/review/s0r-baseline-2026-11-16/`; las capturas incluyen el escritorio
de desarrollo y no deben copiarse a publicaciones públicas. No se realizaron
requests a proveedores externos ni se usó contenido de anime.

## Entorno observado

| Dato | Valor |
|---|---|
| Sistema reportado por el kernel | Fedora 44, Linux `6.19.10-300.fc44.x86_64` |
| Sesión | KDE Wayland, `wayland-0` |
| CPU/arquitectura | x86_64, 8 CPUs lógicas |
| RAM total visible | 7,852,856 KiB (aprox. 7.5 GiB) |
| Flutter aislado del proyecto | `3.50.0-0.4.pre`, revisión `368ac9e40bad0566927cc9428a42461152652c12` |
| Dart | `3.14.0-315.3.beta` |
| Reproductor | `media_kit`/`libmpv` ya fijados por el lockfile del proyecto |

Este host no es el equipo objetivo de 4 GB. Ninguna medición aquí acredita
rendimiento en ese hardware.

## Reproducción local

1. `test/player/media_kit_spike_integration_test.dart` pasó: 14 tests y 2
   optativos omitidos. Ejecutó el adaptador `media_kit`/`libmpv` real con
   fixture local y cubrió play/pause/seek/stop, cambio y reapertura, 20 ciclos
   Open/Stop y el transporte local de prueba. No prueba un provider externo.
2. Se abrió `lib/main_player_spike.dart` en una ventana Wayland. La captura
   `visible-player.png` muestra el primer frame del fixture MPEG-4 local en la
   superficie Kongroo, 320×180. La ventana quedó pausada en 00:00; los controles
   temporales se verificaron con los tests nativos, no mediante entrada gráfica.
3. Se compiló `main_player_spike.dart` como Linux release con el SDK aislado y se
   reprodujo la demo sintética local existente por HTTP loopback. La captura
   `gui-playback-measured.png` muestra `DEMO 1` en 00:00:02.458, imagen en
   movimiento, subtítulo y botón Pause activo. La fuente es fixture sintético
   local, no video externo. `ffprobe` del fixture original MP4 confirma
   MPEG-4, 320×180, 24 fps y AAC; el MKV de demo es MPEG-4/AAC y la captura
   acredita su presentación visual en la ventana.
4. El cierre automatizado mediante backend de entrada Wayland no estaba
   disponible. Se terminó únicamente el proceso de app que abrió esta misión y
   se verificó que no quedaran procesos `anime_app` ni `flutter run`.

## Medidas reales y límites

| Escenario | Resultado | Interpretación |
|---|---|---|
| Release, demo sintética visible, 8.010 s | CPU media 28.84% de un núcleo; RSS 245,708–258,440 KiB; inicio 253,772 KiB; fin 253,848 KiB | Medición del proceso `anime_app`, fuente local de 480×270/24 fps, este host de 7.5 GiB |
| Test de 20 aperturas libmpv | RSS del proceso de test: 250,081,280 B antes, pico observado 397,529,088 B, 377,446,400 B después de `dispose` | No demuestra fuga por sí solo: proceso de test, asignador nativo y cachés; requiere perfil sostenido/segundo ciclo comparable |
| Test `player_performance_integration_test.dart` | 3 muestras RSS: 361,381,888 / 362,336,256 / 362,872,832 B; audio `vorbis`; FPS, video codec y VO `null` | Test headless sin `VideoController`, según el propio test; no usarlo como FPS de salida ni como señal de render |
| FPS del archivo MP4 sintético | `ffprobe`: 24/1 nominal y promedio | Es metadata del archivo, no FPS decodificado ni presentado |
| Renderer | Log de `media_kit`: `EGL display or context is invalid`, `S/W rendering` | Render por software observado en esta sesión; no se cambió aceleración. Es riesgo de rendimiento previo, no regresión atribuida a S0-R |
| Inicio/primer frame | La captura visual confirma el frame; no hay latencia exacta | `scripts/measure.sh` requiere la marca de `app/lib/main.dart`, ausente en el entrypoint spike. Su salida `docs/perf/S0R-baseline-2026-11-16.tsv` termina `incomplete`; no contarla como medida válida |

Los logs de Fontconfig indican que no puede escribir en `/var/cache/fontconfig`;
no se cambiaron permisos del sistema. El RSS post-dispose permanece por encima
del inicial en la prueba de estrés; no se clasificó como fuga confirmada ni se
ocultó. No se midieron frame drops, FPS de salida, hwdec efectivo, CPU/RAM en
una reproducción larga, 4 GB, consumo del proveedor ni sincronía A/V externa.

## Verificaciones

Con Flutter 3.50.0-0.4.pre/Dart 3.14.0 del proyecto, sobre el checkout sucio
actual:

- `flutter analyze --no-pub`: sin issues.
- `dart analyze lib test`: sin issues.
- Formato: 180 archivos, 0 cambios.
- Checker de imports: árbol real válido; tests sintéticos, 2 positivos y 12
  negativos pasaron.
- `python3 tools/ai/memory.py check`: `[]`.
- Infraestructura IA: 40 tests pasaron.
- Suite Flutter completa: 268 pasaron, 6 optativas omitidas.
- `git diff --check`: se ejecutará tras registrar esta documentación; no hubo
  edición funcional durante Gate 0.

Logs: `.ai-local/review/s0r-baseline-2026-11-16/` (`native-player-test.log`,
`native-playback-metrics.log`, `flutter-analyze.log`, `dart-analyze.log`,
`dart-format.log`, `import-checker*.log`, `memory-check.log`, `python-tests.log`,
`flutter-tests.log`, `linux-release-build.log`, `gui-playback-measured.log` y
capturas). `measure.log` y el TSV referido arriba son corridas incompletas y se
mantienen marcadas como tales.

## Plan de reversión para gates posteriores

La composición vigente ya conserva el manager vacío y la ruta anterior. Todo
provider/resolver nuevo se incorporará detrás del registro S0-R; la reversión
consistirá en desregistrar/desactivar ese módulo en composición, dejando los
contratos genéricos y el engine existente intactos. Una ruta web, si llegara a
ser aprobada por sus pruebas, permanecerá bajo feature flag apagada por
defecto. No se editará el engine, coordinator ni presentación sin reproducir
un defecto atribuible, añadir prueba de regresión y pasar el gate de rollback
de la misión.

## Resultado Gate 0

El flujo local pasa en libmpv y se vio video sintético en la ventana. Gate 0
queda `PARTIAL` porque el primer frame no tiene tiempo exacto, no se obtuvo FPS
presentado ni frame drops, se observó render por software, la medida headless
no expone video, y el equipo de 4 GB no está disponible. Estos límites no
bloquean Gate 1; se reevalúan antes de activar fuentes y al comparar el mismo
recurso en el equipo objetivo.
