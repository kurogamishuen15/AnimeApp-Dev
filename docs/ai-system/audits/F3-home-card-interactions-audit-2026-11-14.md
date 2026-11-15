# F3 — Auditoría de interacciones responsivas del Home

Fecha: 2026-11-14
Alcance: acciones de tarjetas, persistencia de estados de biblioteca, documentación y validación del Home.
Estado: implementación para revisión manual; no aceptación de fase.
Revisión independiente: auditor_codigo secuencial, solo lectura, seguida de corrección del hallazgo.

## Cambios revisados

- `HomeCardActionPolicy` y callback compartidos entre escritorio, TV y teléfono. Acciones de detalle, alta y seis estados de biblioteca.
- Hover/foco de escritorio dentro de la carátula, sin transición de tamaño ni pérdida de hover entre botones; el teclado ofrece el mismo acceso.
- Foco direccional de TV con borde visible, botón de opciones, activación por OK/Enter y restauración de foco tras Escape.
- Android muestra solo tres puntos como acción secundaria, con objetivo de 48×48; tocar el póster abre detalle y la hoja contextual no propaga la activación a la tarjeta.
- Migración local de esquema v5/v6 a v7 para estados `planned`, `watching`, `rewatching`, `paused`, `completed`, `abandoned`; al marcar Completados se solicita confirmación.
- README de Home actualizado con estados, interacciones, accesibilidad, extensiones de acciones/tema, Lite/Minimalista, pruebas y rendimiento.

## Evidencia ejecutada

- `dart analyze lib test` con Flutter 3.47.9/Dart 3.13.7 aislados: sin problemas.
- `flutter test --no-pub`: todas las pruebas terminadas con 234 aprobadas y 3 omitidas. Incluye pruebas de widgets para hover, foco de teclado, separación de eventos entre controles, menú móvil, D-pad/OK/Escape y retorno del foco; además estados, confirmación y migraciones SQLite.
- `flutter build linux --release --no-pub`: build completado.
- Fedora: aplicación release abierta en Home con base aislada `KONGROO_DATABASE_PATH=.ai-local/home/home-interactions-review.sqlite`. Captura real de Home normal: `.ai-local/home/home-card-interactions-normal.png`.
- No se presentan datos personales inventados. Sin fuente de video conectada, las tarjetas no exponen una acción Play; Continuar viendo permanece vacío.

## Revisión independiente y límites

El auditor secuencial señaló que el botón Android quedaba en 40×40 por `VisualDensity.compact`, por debajo de los 48×48 documentados. Se cambió a densidad estándar con mínimos explícitos y la prueba ahora mide el rectángulo real. También se reforzó la prueba TV para comprobar foco primario en el control de opciones después de cerrar el menú. En su segundo pase sobre el cambio, el auditor no reportó otros defectos estáticos en el alcance; no ejecutó pruebas ni inspección GUI.

No fue posible capturar hover o menú en la aplicación Fedora ni validar con mando Android TV/teléfono físico: MCP Wayland devolvió `Transport closed` en consulta y captura y la superficie CUA no expuso aplicaciones nativas. Las pruebas de widget simulan estos estados y no sustituyen esa validación física. La captura real disponible acredita únicamente la ventana y el Home normal. `flutter analyze` estable no se usa como evidencia; el análisis Dart directo sí pasó.

## Resultado

Sin hallazgos P0/P1 confirmados en el pase estático disponible. La ausencia de prueba en dispositivos y la revisión visual manual pendiente son evidencia esencial faltante para recomendar aceptación. El propietario conserva la decisión; la sesión debe detenerse en Home para su revisión y no navegar a otra pantalla.
