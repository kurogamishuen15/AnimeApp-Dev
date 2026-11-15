# F2.8 — OpenSubtitles

Fuente: código, pruebas locales, documentación oficial y auditoría independiente secuencial
Fecha: 2026-11-11
Módulo: player / external subtitles
Estado: implementada y verificada técnicamente; aceptación pendiente del propietario
Decisión: continuar operación autorizada F2.3–F2.10 sin aceptar fases automáticamente
Evidencia: CI completa, build Linux release, pruebas HTTP fake y libmpv real, análisis y auditoría F2.8

## Cambios y verificaciones

El contrato domain valida búsquedas y candidatos, representa IMDb padre,
archivos multipart, errores y `Retry-After`. El adaptador Dio limita y valida
descargas locales, restringe redirects, separa credenciales de enlaces de
descarga, cancela bodies no utilizados, conserva temporales ajenos ante
colisión y mapea errores del directorio de soporte. Application bloquea
hardsub confirmado y solo entrega URI `file:` al coordinator. La UI impide
búsqueda y descarga reentrantes. Composition rollback también cierra catálogo
si falla la creación/apertura del reproductor.

- 24 pruebas focalizadas de domain/data/application/widget: exit 0.
- Integración HTTP fake → storage temporal → service/coordinator → libmpv real:
  1/1, exit 0; se observó la pista externa seleccionada. No confirma glifos
  renderizados por compositor.
- `flutter analyze --no-pub`: exit 0.
- `flutter build linux --release --no-pub -t lib/main_player_spike.dart`:
  exit 0.
- `bash scripts/ci.sh`: exit 0; 40 pruebas de infraestructura y 175 Flutter,
  formato, análisis, imports y memoria.
- Toolchain aislada Flutter 3.47.9/Dart 3.13.7. No se cambió Flutter global.

La auditoría independiente corrigió seis hallazgos iniciales (incluidos dos
riesgos), detectó luego dos P2 —`Retry-After` del GET 429 y búsqueda concurrente
vía Enter— y confirmó ambas correcciones en una segunda pasada. No quedan
hallazgos P0/P1 conocidos en el alcance F2.8. No había credenciales: no se
consultó API live ni se gastó cuota. Fontconfig emitió avisos de caché no
escribible durante libmpv, sin impedir las pruebas.

Ver [auditoría F2.8](../../ai-system/audits/F2.8-audit-2026-11-11.md),
[README data](../../../app/lib/data/opensubtitles/README.md), logs nuevos en
`.ai-local/f2.8/evidence/` y [PROGRESS](../../../PROGRESS.md).

## Próximo paso

Investigar F2.7: media_kit 1.2.6 expone `Player.stream.error` como `String`,
sin identidad de fuente. Antes de F2.9/F2.10, buscar una política demostrable
para errores tardíos A/B; no considerar suficiente el contador de generación
Dart. F2.8 espera aceptación formal del propietario.
