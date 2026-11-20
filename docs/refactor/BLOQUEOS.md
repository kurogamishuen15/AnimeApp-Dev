# Bloqueos — 2026-11-20

- B0-01: etiqueta `respaldo-pre-refactor` ausente. El árbol previo está respaldado
  localmente; el backup de Git HEAD por sí solo no representaría la línea base.
- B0-02: `flutter pub get --enforce-lockfile` exit 65; exige cambiar lock
  (aparece `listen 1.0.1`). No se actualizó deliberadamente ninguna dependencia.
- B0-03: análisis previo devuelve 144 incidencias, con errores en manager y
  parámetro `proxy` inexistente. No corregirlos como si fueran parte del refactor.
- B0-04: Flutter beta 3.50.0-0.4.pre / Dart 3.14.0 presenta incompatibilidad
  framework/engine: `SemanticsRole.slider` no cubierto en Flutter. Suite y golden
  no acreditan comportamiento mientras no compilen. No se modificó el SDK.
- B0-05: caracterización por todos los proveedores e inventario semántico aún
  incompletos. El golden inicial es una expectativa candidata sin ejecución verde;
  no puede usarse para certificar paridad ni considerarse una salida capturada.

No hubo mini-fase de producto fallida ni reversión de cambios ajenos. No se
avanza a movimientos de módulos con estas dependencias pendientes.

- B0-06: build Linux debug falla en compilación por contratos previos y
  SemanticsRole.slider; APK bloqueado por ausencia de Android SDK.

## Continuación: diagnóstico de pub get

Error exacto anterior: `Would change 2 dependencies.` seguido de
`Unable to satisfy pubspec.yaml using pubspec.lock.`
El solver propone `+ listen 1.0.1` y `test_api 0.7.14 (was 0.7.12)`.
Causa comprobada: flutter_test del SDK beta fija test_api 0.7.14;
el SDK local flutter-3.47.9 fija 0.7.12, igual al lock existente.
package_config generado apuntaba a un Flutter externo al proyecto.
Cambio mínimo a probar: ejecutar pub get con el SDK local compatible,
sin cambiar pubspec ni dependencias. Configuración generada y lock respaldados
en `.ai-local/refactor-baseline/continuation/`.

## Continuación de respaldo y planificación — estado vigente

- B0-01 RESUELTO: etiqueta creada sobre respaldo de producto `507368b`, subida y
  verificada junto con refactor-modular en origin el 2026-11-20.
- B0-02 RESUELTO: SDK local flutter-3.47.9 hace pub get --enforce-lockfile exit 0;
  lock y pubspec idénticos. No hubo cambio de dependencia ni commit de versiones.
- B0-04 RESUELTO para ejecución: usar siempre SDK 3.47.9; no usar el beta.
- B0-03/B0-06 ABIERTOS: analyze 94 errores, 20 warnings, 28 infos previos;
  Linux falla en contratos/sintaxis Dart. No se acreditó falta de librería del
  sistema ni se instaló nada. Android sin SDK ni scaffold; Windows no verificable.
- B0-07: tests por carpeta con timeout externo 90 s: player interrumpido;
  core/settings/domain/home/catalog terminan en verde; data/application/widget
  fallan por compilación previa. Ver RESULTADOS_TESTS, no afirmar suite verde.
  test/tool estaba vacío y Flutter ejecutó suite completa como fallback: timeout,
  no sumarlo ni repetirlo; runner corregido para excluir carpetas vacías.
- B0-08: JKAnime carece de fixture/test directo y no compila por sintaxis y
  contratos previos. SIN GOLDEN; no se reescribió, eliminó ni corrigió. Bloquea
  acreditar cobertura de todas las fuentes y cualquier movimiento de ese módulo.
- B0-09: AllAnime `_aaReq` usa DateTime.now (allanime_playback_provider.dart:498),
  firma cambiante por ventana temporal. Un golden exacto de TODA la petición pasó
  en la ventana de captura y falló al cambiar la ventana; eso no es regresión.
  Se conservó el JSON capturado sin modificar expectativas. Ese caso queda
  explícitamente omitido, no aprobado; nuevo test independiente compara solo
  salida completa de fuentes con el mismo golden. Los otros golden HTTP conservan
  comparación exacta. No se normalizan firmas ni se cambia el scraper.
  Para caracterizar firma exacta hace falta una decisión aparte sobre reloj
  inyectable; no introducirla durante este refactor protegido.
- B0-10: el parser AST detecta 23 diagnósticos previos. La lista de símbolos de
  esos archivos es recuperación sintáctica, no certificación semántica completa.

La entrega documental no cierra paridad funcional ni autoriza Fase 1. Mantener
estas limitaciones visibles incluso si los golden no bloqueados terminan verdes.
