# Auditoría focalizada — Home: pulido y desplazamiento — 2026-11-14

## Resumen

Se mantuvo el layout del Home. El corte conserva las acciones sobrepuestas translúcidas y el menú de escritorio propio, usa una estrella vectorial dorada que sí aparece en release, y agrega autoplay de 6 s con pausas por movimiento reducido/visibilidad, además del scroll horizontal por rueda/trackpad. Las capturas reales muestran el badge corregido y el avance Attack on Titan → Demon Slayer. No hay hallazgo funcional reproducible en el alcance probado. La inspección visual real de hover/clic derecho queda pendiente: MCP Wayland devolvió `Transport closed`; XTest abrió el consentimiento KDE de control remoto y no se concedió.

## Alcance y entorno

- Raíz confirmada: `/home/kyouma/Vídeos/PROYECTO ANIME`.
- Solo: `app/lib/app/home/{home_appearance,home_hero,home_screen,home_sections,home_score_badge}.dart`, `app/test/home/home_screen_test.dart`, README visual del Home y estado/handoff.
- Flutter 3.47.9 / Dart 3.13.7 del toolchain aislado `.ai-local/toolchains/flutter-3.47.9`.
- No se consultaron fuentes externas ni se añadieron dependencias.

## Revisión de cambios y segunda pasada

- El overlay usa controles separados translúcidos y sin `BackdropFilter`; el hover sigue transformando la portada con `ClipRect` y sin alterar constraints.
- Menú PC/TV conserva comandos, estado seleccionado, límites de posición y cierre/dismiss del dialog route; está dibujado con una superficie oscura propia. Móvil sigue usando el menú táctil existente. No se cambió la lógica compartida de biblioteca.
- El score continúa viniendo del modelo del catálogo; `null` no dibuja badge. El screenshot release del primer corte mostró que el icon font star no dibujaba píxeles. Se reemplazó por una estrella de cinco puntas `CustomPainter` pequeña, local y dorada. La captura final confirma el glifo visible.
- El timer de HomeHero se rearma al cambiar selección y se cancela al disponer. `WidgetsBindingObserver` se retira al disponer. El banner pausa en movimiento reducido, ventana/ruta inactiva, puntero/foco sobre el hero o cuando deja el viewport.
- El listener del carrusel solo registra `PointerScrollEvent` si el offset puede avanzar. En una señal vertical ejecuta una animación breve; el delta horizontal se conserva con desplazamiento directo. Al llegar al extremo no registra la señal, permitiendo al scroll vertical padre resolverla. No toca clics.
- El `ScrollController` vertical del Home se libera al disponer; la comprobación del hero se coalesce a un callback por frame.
- Segunda pasada propia (sin revisor independiente): se revisó cancelación/reanudación del timer, remoción del observer/controller, Scrollable/PointerSignalResolver y los bordes del carrusel. No se encontró un defecto reproducible en esta inspección limitada.

## Verificación ejecutada

| Comprobación | Resultado |
| --- | --- |
| `dart analyze lib/app/home test/home` | Sin problemas |
| `flutter analyze lib/app/home test/home` | Sin problemas |
| `flutter test test/home/home_screen_test.dart` | 13/13 pasan; incluye menú/clic derecho, hover/clip, score, autoplay/selección, reduced motion, viewport, rueda/trackpad, Android y TV simulado |
| `flutter build linux --release --no-pub` | Build correcto, ejecutado una vez tras los cambios de código |
| Ejecución real Fedora | Binario release abre Home con DB aislada `.ai-local/home/home-polish-review.sqlite` |
| Capturas reales | `.ai-local/home/home-polish-final-normal.png` y `.ai-local/home/home-polish-final-autoslide-2.png`; se observa badge y Attack on Titan → Demon Slayer |
| MCP Wayland | No disponible (`Transport closed`) |
| Hover/clic derecho y menú con puntero real | No comprobados: el intento XTest produjo el consentimiento KDE de control remoto; no se aprobó |

La suite completa no se repitió en este ajuste limitado; la corrida previa, anterior a rueda/viewport, reportó 236 aprobadas y 3 omitidas, y no es evidencia de este corte. Tampoco se probaron dispositivos Android/TV, mando real ni RAM total de 4 GB.

## Hallazgos y pendientes

- **P2 — evidencia visual de hover/menú pendiente.** No se pudo comprobar sobre la ventana real el aspecto de hover ni el menú por clic derecho; sí quedó capturado el slide automático, la metadata y el badge final. La reproducción de widget tests no sustituye la interacción del compositor. El propietario debe revisar esas dos interacciones en Home.
- Sin defecto P0/P1 demostrado en el alcance actual. Este informe no es una auditoría del resto de Kongroo ni una aceptación de fase.

## Archivos de documentación sincronizados

- `app/lib/app/home/README.md`
- `docs/ui/HOME.md`
- `docs/memory/PROJECT_STATE.md`
- `docs/memory/AI_HANDOFF.md`
- `docs/memory/sessions/2026-11-14-home.md`
