# Línea base vigente — 2026-11-20

Raíz `/home/kyouma/Vídeos/PROYECTO ANIME`, rama `refactor-modular`.
SDK exclusivo: `/home/kyouma/Vídeos/PROYECTO ANIME/.ai-local/toolchains/flutter-3.47.9/bin/flutter`
(Flutter 3.47.9 / Dart 3.13.7). No usar Flutter beta ni SDK externo al proyecto.

Desde `/home/kyouma/Vídeos/PROYECTO ANIME/app`:

```bash
unset FLUTTER_ROOT
export PUB_CACHE='/home/kyouma/Vídeos/PROYECTO ANIME/.ai-local/pub-cache'
export PATH='/home/kyouma/Vídeos/PROYECTO ANIME/.ai-local/toolchains/flutter-3.47.9/bin:'"$PATH"
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --timeout 15s --reporter expanded test/core
flutter build linux --debug --no-pub
flutter test --no-pub --reporter expanded test/refactor test/data/player/providers/refactor_characterization_test.dart
```

Tests separados por carpetas: core, data, settings, domain, player, application,
home, catalog, más widget_test.dart. Runner reproducible en logs/run_baseline.sh.
Límite externo 90 s por carpeta; casos con --timeout 15s; no reintentos en bucle.
La suite completa previa se interrumpió; los logs por carpeta son la evidencia
vigente. No ejecutar carpeta vacía test/tool: Flutter hace fallback a toda la suite.

## Respaldo GitHub verificado antes de continuar

Remoto origin: `https://github.com/kurogamishuen15/AnimeApp-Dev.git`.
Commit de producto previo: `507368b177a1b096ae4cfae9f3c0094f658693c8`.
Rama `refs/heads/refactor-modular` y etiqueta `refs/tags/respaldo-pre-refactor`
subidas por push normal y verificadas con `git ls-remote origin` el **2026-11-20**.
No se alteraron contenidos de producto para ese commit. Revisión de secretos de
613 rutas versionadas/no ignoradas: cinco coincidencias, todas literales ficticios
de tests; sin archivo sensible identificado para excluir. No se reescribió historial.
La revisión se limita a árbol actual y archivos añadidos, no garantiza todo el
historial antiguo; no se afirma auditoría criptográfica del repositorio.

## Resultados

| Comprobación | Resultado | Evidencia |
| --- | --- | --- |
| pub get --enforce-lockfile | exit 0; manifiestos/lock sin cambios | SDK local compatible, log previo local continuation/pub.log |
| analyze | exit 1; 142 incidencias previas | logs/analyze_baseline.txt |
| tests | resultados por carpeta, varios fallos previos de carga; player timeout | logs/test_baseline.txt y RESULTADOS_TESTS.md |
| build Linux debug | exit 1, Dart: miruroProxy y errores de manager/JKAnime/registry | logs/build_linux.txt |
| golden nuevos | consultar resumen final abajo; AllAnime firma exacta omitida por B0-09 | logs/golden_all.txt |
| análisis de tests nuevos | sin incidencias al cerrar | logs/analyze_new_tests.txt |

No se corrigieron errores previos ni librerías del sistema. No atribuir los fallos
Dart del build a paquetes de Fedora. Un analyze fallido no demuestra ausencia de
regresiones: en fases posteriores comparar regla, severidad, ruta y línea.

## Clasificación de analyze

94 **errores**, 20 **warnings**, 28 **infos** = 142. Tabla completa por severidad,
regla y carpeta en [CLASIFICACION_ANALYZE](CLASIFICACION_ANALYZE.md).
Destacan sintaxis/contratos del manager, JKAnime, registry, named parameters de
bootstrap/proxy; no se alteraron para hacer verde la línea base.

# Clasificación de analyze previo

{'error': 94, 'warning': 20, 'info': 28}; total 142

| Severidad | Regla | Carpeta | Cantidad |
| --- | --- | --- | --- |
| error | argument_type_not_assignable | lib/data/player | 1 |
| error | body_might_complete_normally | lib/application/player | 1 |
| error | concrete_class_with_abstract_member | lib/application/player | 1 |
| error | expected_class_member | lib/application/player | 1 |
| error | expected_executable | lib/application/player | 1 |
| error | expected_identifier_but_got_keyword | lib/application/player | 1 |
| error | expected_token | lib/application/player | 2 |
| error | expected_token | lib/data/player | 6 |
| error | extra_positional_arguments_could_be_named | lib/data/player | 3 |
| error | extraneous_modifier | lib/application/player | 3 |
| error | invalid_assignment | lib/data/player | 6 |
| error | invalid_constant_pattern_generic | lib/application/player | 1 |
| error | list_element_type_not_assignable | lib/data/player | 1 |
| error | missing_identifier | lib/application/player | 1 |
| error | missing_identifier | lib/data/player | 3 |
| error | missing_required_argument | lib/data/player | 6 |
| error | missing_statement | lib/application/player | 1 |
| error | non_abstract_class_inherits_abstract_member | lib/data/player | 1 |
| error | return_of_invalid_type | lib/data/player | 1 |
| error | return_of_invalid_type_from_closure | lib/application/player | 1 |
| error | return_of_invalid_type_from_closure | lib/data/player | 1 |
| error | undefined_class | lib/application/player | 3 |
| error | undefined_class | lib/data/player | 3 |
| error | undefined_enum_constant | lib/data/player | 2 |
| error | undefined_function | lib/application/player | 5 |
| error | undefined_identifier | lib/application/player | 23 |
| error | undefined_identifier | lib/data/player | 1 |
| error | undefined_method | lib/data/player | 2 |
| error | undefined_named_parameter | lib/data/player | 6 |
| error | undefined_named_parameter | lib/main.dart | 1 |
| error | undefined_named_parameter | test/player | 1 |
| error | undefined_named_parameter | tool/oc07_proxy_probe.dart | 1 |
| error | unexpected_token | lib/application/player | 1 |
| error | unexpected_token | lib/data/player | 1 |
| error | unterminated_string_literal | lib/data/player | 1 |
| info | avoid_dynamic_calls | lib/application/player | 3 |
| info | avoid_dynamic_calls | lib/data/player | 5 |
| info | avoid_types_as_parameter_names | lib/application/player | 1 |
| info | directives_ordering | lib/data/player | 3 |
| info | directives_ordering | lib/main.dart | 2 |
| info | empty_statements | lib/application/player | 1 |
| info | non_constant_identifier_names | lib/application/player | 1 |
| info | prefer_final_locals | lib/data/player | 1 |
| info | prefer_final_locals | test/data | 2 |
| info | strict_top_level_inference | lib/application/player | 2 |
| info | type_literal_in_constant_pattern | lib/application/player | 1 |
| info | unawaited_futures | lib/main.dart | 1 |
| info | unnecessary_brace_in_string_interps | lib/data/player | 1 |
| info | unnecessary_string_escapes | lib/data/player | 2 |
| info | valid_regexps | lib/data/player | 2 |
| warning | constant_pattern_never_matches_value_type | lib/application/player | 1 |
| warning | dead_code | lib/application/player | 1 |
| warning | dead_null_aware_expression | lib/application/player | 1 |
| warning | inference_failure_on_collection_literal | lib/data/player | 1 |
| warning | inference_failure_on_function_invocation | lib/application/player | 1 |
| warning | inference_failure_on_function_return_type | lib/application/player | 1 |
| warning | inference_failure_on_instance_creation | lib/data/player | 2 |
| warning | inference_failure_on_untyped_parameter | lib/application/player | 3 |
| warning | unused_element | lib/data/player | 3 |
| warning | unused_element | lib/main.dart | 1 |
| warning | unused_import | lib/data/player | 1 |
| warning | unused_local_variable | lib/data/player | 4 |

## Plataformas y límites

- Aquí pueden ejecutarse analyze, tests unitarios/widget y build Linux. Linux
  actualmente NO compila por errores del código previo; no hay prueba GUI/native
  actual de producto. No instalar librerías ni corregir producto en esta sesión.
- Android NO verificado: falta SDK y no hay scaffold Android en esta captura.
  El propietario deberá preparar/validar manualmente después.
- Windows NO verificado: sin scaffold/toolchain Windows en este entorno.
- macOS/iOS/web NO preparados ni verificados; no ampliar alcance automáticamente.
- Perfil RSS/jank/arranque/10 minutos de reproducción: NO medido.
- Test golden offline valida fixtures, no disponibilidad actual de servidores.

## Comparación con el intento anterior

El intento beta proponía listen/test_api nuevos y produjo SemanticsRole.slider;
se sustituyó solo la invocación del SDK. pubspec y lock se conservaron por cmp.
Los 144 diagnósticos antiguos no son baseline de comparación: el registro correcto
con el SDK compatible tiene 142. No se ejecutó format global sobre código previo.

## Cierre de comprobaciones de esta entrega

Golden offline: **11 aprobados, 1 omitido**, exit 0 en logs/golden_all.txt.
Omitido: petición completa temporal de AllAnime (B0-09); su salida de fuentes
sí pasa con golden independiente. JKAnime sigue SIN GOLDEN. No equivale a
cobertura total de todas las fuentes ni a suite global verde.
Tests nuevos: dart analyze sin incidencias. memory.py check devuelve [];
git diff --check limpio. Hashes de los 223 archivos originales intactos.
No se observaron flujos gráficos ni reproducción native en esta sesión.

Los logs conservan todos los mensajes; solo se retiró whitespace final de líneas
para superar git diff --check. No se filtraron errores ni se alteraron resultados.
