# Progreso de AnimeApp

Fuente viva del estado de fases. Actualizar al terminar o bloquear una subfase; el plan no equivale a implementación.

Estados: Pendiente, En desarrollo, Completado, Bloqueado, Requiere revisión.

## F0 Preparación Fedora

| ID | Estado | Evidencia / resultado | Pendiente | Commit privado |
| --- | --- | --- | --- | --- |
| F0.1 | Completado | Flutter/Dart, toolchain Linux, GTK3, libsecret y libmpv verificados en Fedora 44. Detalle reproducible: [auditoría F0.1](docs/environment/F0.1-FEDORA.md). | Android SDK no instalado (fuera del destino Linux); validación del equipo objetivo 4 GB pendiente. | `2af0a4c` |
| F0.2 | Completado | Commit `84efbfb`; `main` subida a `AnimeApp-Dev` privado. Clone limpio; público `AnimeApp` vacío. Registro: [sesión F0.2](docs/memory/sessions/2026-11-07-f0-2-git.md). | Ninguno para el alcance F0.2. | `84efbfb`, `b18a79c` |
| F0.3 | Completado | README y otros siete documentos Markdown completos y enlazados; enlaces relativos verificados. | D3: decisión del propietario sobre archivo `LICENSE` antes de distribuir. No bloquea F0.3. | `2af0a4c` |
| F0.4 | Parcial | Linux scaffold, lints, `dart analyze lib test`, widget test y proceso de `flutter run -d linux` verificados. Marker release confirma primer frame rasterizado. Ventana visible/funcional no verificable por sesión Wayland y herramientas disponibles. `flutter analyze` falla por error LSP asociado a ruta no ASCII. | Toolchain Flutter con arreglo; comprobación de ventana visible en sesión observable; rendimiento en objetivo 4 GB. | `47a0e6e` |
| F0.5 | Parcial | `ci.sh`, checker Dart y prueba sintética (válido + Flutter + presentación) implementados. 40 tests IA, formato, Dart analyze, checker y Flutter widget test pasan. | CI no está verde: `flutter analyze --no-pub` sale con código 255 por bug LSP reproducible; corregir upstream/toolchain sin desactivar analyzer. | `2644ef7` |
| F0.6 | Parcial | Bundle release, marca de primer frame rasterizado y tres muestras completas. Medianas: primer frame 462 ms, RSS frame 140096 KiB, RSS tras 5 s 145284 KiB, CPU reposo 0.60% de un núcleo. Informe: [medición Linux](docs/perf/measure-20261108T133341Z-15982.tsv). | Ventana no observable en Wayland; verificar visibilidad en entorno compatible y repetir en equipo objetivo 4 GB. No es reproducción ni prueba de fugas prolongada. | `0569396` |

## F1–F7

Todas las subfases F1.1–F7.10 están pendientes. La lista y el orden están en [ROADMAP.md](ROADMAP.md); criterios por módulo en `PROJECT_PLAN.md` y la documentación propia de cada módulo cuando se incorpore.

## Registro de cambios

- 2026-11-08: F0.2 completada; commits `84efbfb` y actualización documental `b18a79c`, con push privado verificado.
- 2026-11-08: F0.1 y F0.3 completadas; D3/Licencia sigue pendiente y no bloquea F0.3.
- 2026-11-08: F0.4–F0.6 verificadas parcialmente. Build release y medición reproducible completados; CI conserva el fallo de Flutter analyze y no se acreditó ventana visible Wayland. Detalle reproducible en [sesión F0.1–F0.6](docs/memory/sessions/2026-11-08-f0-3-f0-6.md).
