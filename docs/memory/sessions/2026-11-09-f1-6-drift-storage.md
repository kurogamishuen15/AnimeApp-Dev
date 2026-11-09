# F1.6 — Persistencia local Drift

Fecha: 2026-11-09
Estado: completada; validaciones de plataforma/rendimiento aún pendientes
Commit: pendiente de registrar
Fuente: implementación y validaciones locales de F1.6
Módulo: data/local_db
Decisión: Drift/SQLite schema v2, con migración no destructiva desde v1
Evidencia: `app/lib/data/local_db`, tests, `scripts/ci.sh`

## Alcance realizado

- Se añadieron Drift, `path_provider`, `sqlite3`, `drift_dev` y `build_runner` con lockfile.
- `AppDatabase` usa Drift con schema version 2, abre un archivo bajo application support y permite inyectar archivo para pruebas.
- Schema v1 conserva ajustes en envelopes JSON. La migración no destructiva v1→v2 agrega documentos opacos de progreso; no define semántica funcional que corresponde a F1.10/F1.11.
- Se versionó el snapshot histórico [schema_v1.sql](../../../app/drift_schemas/schema_v1.sql).
- Tres pruebas usan SQLite sobre archivo real y comprueban CRUD tipado, migración con datos existentes, persistencia tras cerrar/reabrir y rollback transaccional. El cleanup está limitado a `.ai-local/test-db/f1_6` bajo el proyecto y exige ejecutar desde `app/`.
- README de módulo registra portabilidad Linux, codegen, ciclo de vida pendiente de integración y validaciones futuras.

## Evidencia de validación

Toolchain seleccionado explícitamente: Flutter 3.50.0-0.4.pre / Dart 3.14.0 beta aislado en `.ai-local/toolchains/flutter`.

- `dart run build_runner build`: exit 0; generó Drift.
- `flutter test --no-pub test/data/local_db/app_database_test.dart`: 3 tests, exit 0.
- `dart analyze lib/data/local_db test/data/local_db`: sin issues, exit 0.
- `flutter analyze --no-pub`: sin issues, exit 0.
- `dart format --output=none --set-exit-if-changed app/lib app/test scripts/check_imports.dart`: sin cambios, exit 0.
- `bash scripts/ci.sh`: exit 0; 40 pruebas de IA, checker positivo y diez negativos, analyzer Dart/Flutter, ocho pruebas Flutter y límites de imports.
- `python3 tools/ai/memory.py check`: sin conflictos.

La hook de SQLite recibió HTTP 504 descargando el precompilado. Se obtuvo el mismo artefacto desde el asset oficial de release y se verificó SHA-256 `0a65852703763619a7a34633b4959b3b86c4103804a4dfe4e8b27b5de1c0647b`, igual al hash publicado por el paquete. La biblioteca quedó solo en caché ignorada; no se modificó SDK ni sistema.

## Revisión independiente

Auditoría de datos detectó que el test podía derivar `.ai-local` fuera de la raíz si se lanzaba desde otro directorio y que duplicaba el DDL del snapshot. Se añadió una guarda de directorio y el test ahora ejecuta el snapshot versionado. Repruebas específicas pasaron.

## Pendientes

- Conectar el ciclo de vida de `AppDatabase.open()` con composición/store en F1.5.
- Medir latencia, memoria y carga en el hardware objetivo; los números de rendimiento siguen siendo preliminares.
- Completar validación de licencia y empaquetado Linux/Flatpak antes de distribuir.
- Flutter stable 3.47.9 conserva el fallo LSP de F0.5; la suite solo se declara verde con el SDK beta aislado explícitamente.
