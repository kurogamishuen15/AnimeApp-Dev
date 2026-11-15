# Auditoría focalizada: selector de calidad de video

**Fecha:** 2026-11-12
**Estado:** implementado para pistas de video que media_kit reporta; no equivale a selector ABR de manifests.
**Recomendación:** conservar el alcance nativo multitrack demostrado y no anunciar calidades HLS/DASH remotas hasta integrar sus variantes.

## Alcance y entorno

Se revisaron el modelo `VideoTrackInfo`, el panel, la conexión de botones, la validación del coordinador, la traducción en `MediaKitSpikeEngine`, las pruebas y los README de dominio/aplicación/adaptador/UI. Se conservaron los cambios preexistentes del árbol de trabajo. No se modificaron dependencias, catálogo, configuración global ni agentes.

Toolchain local: Flutter 3.47.9, Dart 3.13.7; `media_kit` 1.2.6 y `media_kit_video` 2.0.1 según `app/pubspec.lock`.

Fuentes primarias consultadas el 2026-11-12:

- [media_kit 1.2.6](https://pub.dev/packages/media_kit/versions/1.2.6): `Player.state.tracks.video`, `Player.stream.tracks` y `Player.setVideoTrack`; la guía documenta `VideoTrack.auto()` como selección automática de la primera pista, no como adaptación ABR.
- [Manual oficial de mpv](https://mpv.io/manual/stable/): `track-list` expone dimensiones y bitrate como pistas/metadatos indicados por el contenedor; `use_manifests` está desactivado por defecto y `hls-bitrate` controla selección inicial de streams HLS. Estas opciones no se han habilitado ni se interpretan como prueba de cambio ABR en Kongroo.

## Implementación revisada

| Archivo | Responsabilidad auditada | Evidencia |
|---|---|---|
| `app/lib/domain/player/video_track_info.dart` | Normaliza etiqueta desde dimensiones, bitrate, códec y título; no genera alturas conocidas si no coinciden con el metadato | `label`/`_resolutionLabel`, líneas 24–56 |
| `app/lib/app/player/player_quality_panel.dart` | Muestra solo las pistas del snapshot; una pista se etiqueta fija; con varias muestra pistas y Auto del motor | `build`, líneas 24–69 |
| `app/lib/app/player/spike_player_page.dart` | Renderiza botón Calidad y envía selección al coordinator con generación y revisión del contexto | controles, líneas 700–728 |
| `app/lib/application/player/playback_spike_contract.dart` | Expone pistas y capacidad opcional de selección, sin importar media_kit | `PlaybackVideoSelection` y snapshot |
| `app/lib/application/player/spike_player_coordinator.dart` | Serializa, valida fuente/ID/generación y limita Auto a más de una pista real | `selectVideoTrack`, líneas 358–378 |
| `app/lib/data/player/engine/media_kit_spike_engine.dart` | Lee `Player.state.tracks.video`, invoca `setVideoTrack`, lee `vid` y publica la selección efectiva | líneas 625–703 |
| `app/test/player/player_quality_test.dart` | Widget del menú, integración nativa multitrack y prueba opcional del archivo Morevna | pruebas de calidad |
| `app/test/player/spike_player_page_test.dart` | Clic sobre el control de página y selección del ID listado | `quality control selects the actual listed video track` |
| `app/test/domain/video_track_info_test.dart` | Etiquetas standard/no standard y bitrate observado | dos pruebas de modelo |

## Hallazgos

### Q1 — P2, pendiente de alcance: variantes de proveedor y manifiestos HLS/DASH

**Evidencia:** `MediaKitSpikeEngine._validateSource`, `app/lib/data/player/engine/media_kit_spike_engine.dart:302–319`, solo acepta archivos locales o el mirror HTTP loopback exacto; el modelo/resumen del selector recibe `VideoTrackInfo` nativo y no un catálogo de variantes.
**Reproducción:** entregar una URI de master playlist HLS/DASH o un proveedor con URIs 360p/720p distintas al flujo actual; no puede abrirse/representarse como opciones desde el menú.
**Consecuencia:** calidad manual para pistas que el engine ya expone, pero no para niveles de servidor independientes; no hay ABR remoto.
**Corrección recomendada:** discovery tipado de variantes en provider/application y cambio mediante la transacción del coordinator, preservando el contexto; nunca abrir URIs desde el widget.
**Regresión pendiente:** fixture HLS/DASH local con al menos dos variantes verificadas, comprobar lista exacta, Auto cuando esté soportado, selección, resolución efectiva y posición/audio/subtítulos preservados. No es una regresión nueva del cambio actual, sino una limitación conocida del flujo fuente.

### Q2 — Corregido durante la auditoría: regla de Auto alineada entre capas

La primera revisión independiente señaló que el coordinator contaba pistas nativas normalizadas, mientras el adaptador inicialmente contaba también sentinels internos `auto/no`. Se alineó el adaptador a `_videoTrackInfo().length`; ambas capas ofrecen Auto únicamente cuando hay más de una pista seleccionable real. La integración usa Auto con dos pistas; la prueba Morevna rechaza Auto con una sola pista. El auditor no reprodujo un fallo nativo en el caso original; fue una diferencia de reglas que podía producir rechazo ante estados inconsistentes.

### Riesgos comprobados / límites

- Cambiar una pista de video no reabre la fuente ni crea otro Player. La prueba libmpv verifica ID efectivo, posición dentro de 1 s, estado pausado y IDs de audio/subtítulos sin cambios.
- La selección Auto significa la pista predeterminada que el motor elige; no se llama “auto bitrate” ni “ABR”.
- No se hizo clic en una ventana Fedora ni se inspeccionó una transición visual de calidad. La interacción está cubierta por widget tests y la selección nativa por integración libmpv.
- Morevna DEMO expone una sola pista Theora 534×300; se presenta como calidad fija. No existen dos variantes remotas en esa fuente.

## Verificaciones ejecutadas en esta intervención

| Comando | Resultado |
|---|---|
| `flutter test --no-pub test/domain/video_track_info_test.dart test/player/player_quality_test.dart test/player/spike_player_page_test.dart` | Exit 0: 30 pruebas aprobadas, 1 prueba opcional Morevna omitida por no establecer `KONGROO_TEST_REAL_DEMO=1` |
| `KONGROO_TEST_REAL_DEMO=1 flutter test --no-pub test/player/player_quality_test.dart --plain-name 'Morevna reports its single source resolution as fixed quality'` | Exit 0: 1 aprobada sobre el archivo DEMO real; metadatos 534×300 y rechazo de Auto para pista única |
| Integración incluida en `player_quality_test.dart` | Exit 0 dentro del comando focalizado: fixture `.ai-local/player-quality/two-video-audio-subtitle.mkv`; ffprobe observó MPEG-4 320×180 y 160×90, AAC inglés y SRT inglés; libmpv seleccionó audio/subtítulo y luego cambió de video |
| `flutter analyze --no-pub` | Exit 0: no issues found |
| `dart analyze lib test` | Exit 0: no issues found |
| `dart format --output=none --set-exit-if-changed` sobre ocho archivos del cambio | Exit 0: cero archivos por formatear |
| `flutter build linux --release --no-pub -t lib/main_player_spike.dart` | Exit 0: bundle Linux release generado |
| `git diff --check` | Exit 0 |
| Checker actual de límites de imports | Exit 1, una violación ya presente al iniciar este trabajo: `app/lib/app/player/spike_player_page.dart` importa `dart:io` para leer flags de entorno. La restricción estaba en `scripts/check_imports.dart` (también modificado antes de esta tarea); el selector no añadió ese import. Se deja fuera de este cambio para no modificar controles de diagnóstico ajenos. |
| `bash scripts/ci.sh` / suite completa | No ejecutados. El script ejecuta `flutter pub get` y podría reescribir los `pubspec`/lock que ya estaban modificados antes de este trabajo; se ejecutaron pruebas focalizadas, análisis y build sin resolver dependencias. |

## Segunda revisión independiente

`auditor_codigo` realizó revisión de solo lectura del selector y módulos afectados. No encontró defectos demostrados de generación/revisión, selección manual, continuidad o preservación de pistas. Señaló la diferencia de conteos de Auto descrita en Q2; quedó alineada y cubierta por pruebas. No realizó prueba gráfica ni prueba HLS/DASH.

## Conclusión

La selección de pistas de video reportadas por media_kit está implementada y verificada con un fixture de dos resoluciones. El DEMO real con una sola pista muestra calidad fija. La integración general de manifest/provider y ABR queda pendiente; no se certifica cambio de calidad remoto.
