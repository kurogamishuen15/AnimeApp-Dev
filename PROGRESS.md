# Progreso de AnimeApp

Fuente viva del estado de fases. Actualizar al terminar o bloquear una subfase; el plan no equivale a implementación.

Estados: Pendiente, En desarrollo, Completado, Bloqueado, Requiere revisión.

## F0 Preparación Fedora

| ID | Estado | Evidencia / resultado | Pendiente | Commit privado |
| --- | --- | --- | --- | --- |
| F0.1 | Completado | Flutter/Dart, toolchain Linux, GTK3, libsecret y libmpv verificados en Fedora 44. Detalle reproducible: [auditoría F0.1](docs/environment/F0.1-FEDORA.md). | Android SDK no instalado (fuera del destino Linux); validación del equipo objetivo 4 GB pendiente. | `2af0a4c` |
| F0.2 | Completado | Commit `84efbfb`; `main` subida a `AnimeApp-Dev` privado. Clone limpio; público `AnimeApp` vacío. Registro: [sesión F0.2](docs/memory/sessions/2026-11-07-f0-2-git.md). | Ninguno para el alcance F0.2. | `84efbfb`, `b18a79c` |
| F0.3 | Completado | README y otros siete documentos Markdown completos y enlazados; enlaces relativos verificados. | D3: decisión del propietario sobre archivo `LICENSE` antes de distribuir. No bloquea F0.3. | `2af0a4c` |
| F0.4 | Parcial | Linux scaffold, `dart analyze lib test`, widget test y `flutter run -d linux` verificados. Spectacle/KWin capturó la ventana Wayland activa: barra, título y pantalla AnimeApp visibles. Evidencia: [captura](docs/perf/wayland-window-20261108.png). `flutter analyze` aún falla por error LSP en ruta no ASCII. | Ejecutar con Flutter corregido y obtener `flutter analyze` limpio; evaluar rendimiento en equipo objetivo 4 GB. | `47a0e6e` |
| F0.5 | Parcial | `ci.sh`, checker Dart y prueba sintética (válido + Flutter + presentación) implementados. 40 tests IA, formato, Dart analyze, checker y Flutter widget test pasan. | CI no está verde: `flutter analyze --no-pub` sale con código 255 por bug LSP reproducible; corregir upstream/toolchain sin desactivar analyzer. | `2644ef7` |
| F0.6 | Parcial | Bundle release y tres muestras completas. Medianas: primer frame 462 ms, RSS frame 140096 KiB, RSS tras 5 s 145284 KiB, CPU reposo 0.60% de un núcleo. Captura manual confirma ventana visible, pero el script no obtuvo latencia numérica de ventana. Informe: [medición Linux](docs/perf/measure-20261108T133341Z-15982.tsv). | Repetir en el objetivo de 4 GB cuando esté disponible; no hay reproducción ni prueba de fugas prolongada. No extrapolar del entorno de 7.5 GiB. | `0569396` |

## F1–F7

| ID | Estado | Evidencia / resultado | Pendiente | Commit privado |
| --- | --- | --- | --- | --- |
| F1.1 | Completado documental (aprobado por propietario) | Baseline final 18 FR + 13 NFR; seis omisiones MVP añadidas; FR-12/NFR-12 incorporados; FR-11 delimita semántica y pendientes. [Especificación F1.1](docs/requirements/F1.1-CORE-REQUIREMENTS.md). | Definición de semántica por campo FR-11; metas de rendimiento siguen preliminares hasta medir objetivo 4 GB. Validaciones técnicas por fase. | — |
| F1.2 | Completado documental (14 selecciones aprobadas como referencia) | ADR-001–014 corresponden uno a uno con la lista del propietario. [Índice y condiciones ADR](docs/adr/README.md). Se preservaron 13 análisis adicionales aparte. | Compatibilidad, seguridad, licencias y rendimiento se validan en fase propietaria antes de integrar/distribuir. La aprobación no permite adelantar trabajo. | — |

F1.3–F7.10 siguen pendientes. La lista y el orden están en [ROADMAP.md](ROADMAP.md); criterios por módulo en `PROJECT_PLAN.md` y documentación propia de cada módulo cuando se incorpore. F0.4–F0.6 conservan sus estados parciales; la autorización del usuario inició F1.1/F1.2 sin cambiar esos resultados.

## Registro de cambios

- 2026-11-08: F0.2 completada; commits `84efbfb` y actualización documental `b18a79c`, con push privado verificado.
- 2026-11-08: F0.1 y F0.3 completadas; D3/Licencia sigue pendiente y no bloquea F0.3.
- 2026-11-08: F0.4–F0.6 verificadas parcialmente. Build release y medición reproducible completados; CI conserva el fallo de Flutter analyze y no se acreditó ventana visible Wayland. Detalle reproducible en [sesión F0.1–F0.6](docs/memory/sessions/2026-11-08-f0-3-f0-6.md).
- 2026-11-08 (F0-FINAL): captura Spectacle verificó ventana Wayland; analyzer estable 3.47.9 sigue fallando, beta aislada no se pudo descargar en tiempo razonable, y equipo 4 GB no disponible. F0.4/F0.5/F0.6 continúan parciales; no iniciar F1.
- 2026-11-08: propietario aprobó F1.1 (18 FR/13 NFR con condiciones FR-11, rendimiento preliminar, FR-12 y NFR-12) y las 14 selecciones F1.2 como arquitectura de referencia. Validaciones por fase siguen pendientes; 13 ADR adicionales permanecen separados y no aprobados automáticamente. F0.4–F0.6 siguen parciales.
