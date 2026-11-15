# F3 — Refinamiento de interacciones del Home

Fecha: 2026-11-14
Estado: implementación lista para revisión manual; no aceptar fase ni cambiar de pantalla.
Alcance: actualización aprobada del Home existente, sus tarjetas/menús/banner, empty states y appearance tokens.

## Resumen y recomendación

Se mantuvo el Home AMOLED aprobado y se añadieron el zoom hover recortado, menú contextual PC, menú compartido para PC/móvil/TV, marcador de estado, quitar membership/copy link, score badge y puntos seleccionables del banner. Las filas personales vacías ya no aparecen. Iconos outline y estilos tipográficos se centralizaron para conservar opciones de tema futuras. Análisis, suite completa y build Linux pasan. Recomiendo mantenerlo en revisión del propietario: la herramienta de entrada/captura Wayland devolvió `Transport closed`, así que falta observación visual real del hover y menú PC; Android/TV físicos no estaban disponibles. La decisión de aceptación queda al propietario.

El CTA `Watch now` es visible pero deshabilitado: no existe fuente de video conectada a Home. El banner y las acciones de biblioteca siguen usando metadatos e IDs públicos reales; no se añade progreso personal ficticio.

## Entorno y fuentes

- Raíz Git: `/home/kyouma/Vídeos/PROYECTO ANIME`.
- Flutter 3.47.9 / Dart 3.13.7 aislados en `.ai-local/toolchains/flutter-3.47.9`.
- No se añadieron paquetes ni se consultaron fuentes externas.
- Base SQLite de prueba/ejecución: `.ai-local/home/home-interactions-review.sqlite`.

## Implementación revisada

- `home_sections.dart`: escala de portada 1.035/160 ms solo para la imagen; `ClipRect` conserva el marco y el tamaño del layout. Hover/foco no cambia constraints. Clic secundario abre el menú completo en la posición del puntero. Android/TV mantienen solo tres puntos en la parte inferior.
- `home_card_actions.dart`: permisos/contratos compartidos. PC/TV usa menú compacto; teléfono usa hoja táctil desplazable. Presenta detalles, los seis estados locales, estado actual marcado, quitar de la biblioteca y enlace AniList copiable.
- `CatalogHomePage` y `CatalogService`: ejecutar cambios de estado/remove, copiar URL AniList y mantener la confirmación al marcar Completed.
- `home_score_badge.dart`: porcentaje de `averageScore` más estrella; sin dato no dibuja badge.
- `home_data.dart`, `home_hero.dart`, `home_screen.dart`: metadatos reales, hasta cinco banners con puntos de selección, sección Continue watching/Currently watching omitida cuando no hay registros.
- `home_icons.dart`, `home_typography.dart`, `home_appearance.dart`: iconos outline uniformes y tokens de peso/tracking/escala/familia del sistema, sin fuente propietaria.
- READMEs afectados: `app/lib/app/home/README.md`, `docs/ui/HOME.md`.

## Revisión y resultados

Un `auditor_codigo` independiente, secuencial y de solo lectura no encontró defectos estáticos demostrables en el alcance. Revisó permisos y estados del menú, focus TV, ubicación dentro de tarjeta, badge y visibilidad condicional. No ejecutó las pruebas por separado.

- `dart analyze lib test`: sin problemas.
- `flutter test --no-pub`: 235 aprobadas, 3 omitidas.
- `flutter build linux --release --no-pub`: completado.
- Ejecución Fedora: ventana release de Kongroo en Home; RSS observado 228068 KiB a 41 s, con DB aislada. No equivale a un perfil en equipo de 4 GB.
- Captura real disponible solo del estado normal: `.ai-local/home/home-interactions-final-normal.png` (1370×858). Se observa banner, estrellas/score, destacadores y ausencia de las dos filas personales vacías.
- Widget tests cubren clic derecho, hover/escala/clipping, badge real, metadata/dots, empty sections, menú PC, hoja Android y D-pad/Escape/foco restaurado. No son evidencia de interacción en dispositivos físicos.

## Hallazgo de cobertura pendiente

**F3-HOME-01 — P2, verificación de plataforma pendiente.** No se pudo operar el puntero/teclado ni capturar el menú sobre la app Fedora: `mcp__wayland__describe_environment` terminó con `Transport closed`. No se dispuso de móvil o mando TV físico. Reproducción: abrir la ventana release actual, activar una portada con mouse hover/clic derecho, después repetir con dispositivo Android y mando TV. Consecuencia: las pruebas widget no acreditan la posición/rendimiento visual final ni el comportamiento nativo de Back/D-pad. Siguiente acción: revisión manual del propietario con esa evidencia. No requiere un cambio de código basado en los datos disponibles.

No se detectaron hallazgos P0/P1 estáticos. La falta de captura de los estados solicitados es limitación de verificación esencial; no recomendar aceptación automática ni marcar fase completa.
