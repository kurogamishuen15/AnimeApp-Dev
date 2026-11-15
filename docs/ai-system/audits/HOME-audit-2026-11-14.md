# Auditoría de Inicio · 2026-11-14

Alcance: Home, su integración con el shell local y regresión de búsqueda, ficha y biblioteca existentes. Fedora 44 KDE Wayland, Flutter 3.47.9/Dart 3.13.7 aislados, material_ui 1.10.0. Fuentes: especificación visual adjunta págs. 13–17, arquitectura y plan del repositorio, ADR-004/011 y fuente Flutter local `widgets/async.dart` y `widgets/indexed_stack.dart`. El plan reserva las funciones completas de catálogo para F4. El alcance explícito de la tarea autoriza la pantalla Home supervisada.

## Hallazgos y comprobaciones

La revisión independiente de solo lectura cubrió `app/lib/app/home`, `anime_app.dart`, el shell y los widgets de regresión. El coordinador aplicó las correcciones y amplió las pruebas.

| ID | Prioridad | Hallazgo, reproducción y corrección |
| --- | --- | --- |
| HOME-01 | P1 | `home_data.dart`: con biblioteca Completado y sin otro checkpoint, un título reaparecía en la fila demo. Se excluye por ID de proveedor al construir el fallback. El test SQLite marca Jardín orbital completado y comprueba la ausencia de su episodio demo. |
| HOME-02 | P1 | `catalog_home_page.dart` y `local_library_page.dart`: alta en ficha tras cargar el shell podía dejar vacía la biblioteca en la misma sesión. Al seleccionar el destino se refresca el listado y se descarta una respuesta anterior si compiten cargas. Se verifica el alta visible sin reiniciar. |
| HOME-03 | P2 | `home_screen.dart`: un reintento desde contenido offline permitía lanzar otra carga mientras seguía pendiente. El botón pasa a Actualizando y queda deshabilitado hasta la respuesta. Widget test con Future controlado. |
| HOME-04 | P2 | Evidencia de accesibilidad limitada: la prueba de teclado activa el CTA en Flutter y la prueba estrecha cubre 360 px y texto 1,7×. MCP Wayland tiene captura Spectacle disponible y reporta entrada no disponible. Pendientes teclado, puntero y tecnologías de asistencia en ventana real, además de Android/TV. |
| HOME-05 | P1, criterio de rendimiento pendiente | Medición de arranque en Fedora con 7,5 GiB. Falta ejecutar el scroll y verificar memoria en hardware de 4 GB. La prueba con 120 entradas confirma construcción diferida en una fila, sin medir estabilidad de fotogramas o paginación de proveedor. |

Las tarjetas de progreso local muestran el checkpoint del episodio 1 del catálogo provisional. La acción Continuar abre una demostración de la posición exacta y la disponibilidad. La especificación 03.04 requiere que una acción de reproducción de una serie completada ofrezca reiniciar, elegir episodio o cancelar. Home no ofrece reproducción de completadas mientras no existe conexión de fuentes ni lista de episodios. Recomendaciones, portada y condición de emisión usan fixtures explícitos. Aplican los límites descritos en el [README](../../../app/lib/app/home/README.md). Queda pendiente la revisión manual del propietario.

## Resultado automatizado

`flutter analyze --no-pub` sin hallazgos. `flutter test --no-pub` terminó con 223 pruebas aprobadas y 2 omitidas. Incluye las regresiones HOME-01 a HOME-03. Infraestructura IA: 40 aprobadas. Formato de archivos Dart tocados, `git diff --check` y `python3 tools/ai/memory.py check` sin hallazgos. El checker global y el paso final de su script de fixtures terminan con código 1 por el import preexistente de `dart:io` en `app/lib/app/player/spike_player_page.dart:2`. Ese archivo quedó fuera del alcance de Home.

Rendimiento preliminar del primer bundle release visible: primer frame Flutter 2.007 s, RSS 208636 KiB, PSS 163483 KiB aproximadamente seis segundos después de arrancar. Se observó luego RSS 107328 KiB alrededor de los 48 segundos. Una ejecución, base aislada, sin medición de scroll ni de GPU. El cambio de RSS no demuestra ni descarta fugas.

## Verificación visual

Build final `flutter build linux --release --no-pub` exit 0. Ventana real KDE Wayland en `1280×768` y `430×740` con decoración GTK, capturada con Spectacle bajo `.ai-local/home/home-fedora-{wide,narrow}.png`. El MCP Wayland capturó la sesión de escritorio como evidencia adicional. Se observa el banner con degradado, Continuar viendo sin desplazamiento y navegación superior o inferior según ancho. La captura estrecha corresponde a la app Linux redimensionada. Se deja la ventana en ancho de escritorio para la revisión. La app usa una base aislada.
