# F1.10 — Persistencia local de progreso

Fuente: implementación local y baseline aprobado de requisitos
Fecha: 2026-11-09
Módulo: domain/progress y data/local_db
Estado: persistencia genérica implementada; FR-03 funcional requiere definición propietaria
Decisión: conservar identidad/payload opacos; no fijar campos ni reglas de negocio faltantes
Evidencia: pruebas con SQLite real bajo `.ai-local/test-db/`, análisis y revisión de datos

## Implementación

- Se añadió un puerto Dart puro `ProgressRepository`, un `ProgressDraft` de escritura y un `ProgressDocument` persistido con identidad exacta, mapa JSON opaco y timestamp técnico generado por el adaptador.
- `LocalProgressRepository` guarda y consulta mediante la tabla `progress_documents` de Drift. Guardar de nuevo la misma identidad reemplaza su payload; identidades distintas permanecen separadas. No hay red ni sincronización.
- El adaptador asigna `updatedAt` a un instante técnico `DateTime.now().toUtc()`. No representa un evento del usuario ni fija orden/conflicto remoto. Payloads no JSON-compatible e identidad vacía retornan errores de validación.
- Tres pruebas con archivo SQLite real verifican guardado/cierre/reapertura con offset convertido a UTC, reemplazo por identidad exacta y ausencia/entrada inválida.
- Revisión independiente recomendó separar el draft de escritura del modelo leído y no llamar “idempotencia” a un upsert; ambos cambios quedaron aplicados antes de validar.
- No se agregaron identidad anime/episodio, posición, progreso temporal, porcentaje, completado, regla de reanudación o política de conflicto. FR-03 no se declara funcionalmente cerrado.

## Verificación

Con Flutter 3.50.0-0.4.pre / Dart 3.14.0 beta:

- `dart analyze lib/domain/progress lib/data/local_db/local_progress_repository.dart test/data/local_db/local_progress_repository_test.dart`: exit 0.
- `flutter test --no-pub test/data/local_db/local_progress_repository_test.dart`: exit 0, 3 pruebas.
- `scripts/check_imports.dart` y CI completa se ejecutarán al cerrar F1.12.

## Pendiente del propietario

Definir identidad estable anime/episodio, campos mínimos para continuidad, qué posición/tiempo significan y cuándo se consideran persistidos antes de completar FR-03 y reanudación FR-18. Definir necesidades de recuperación ante escritura interrumpida y medir volumen/latencia antes de presupuestos. FR-11 conserva semántica por campo pendiente. La sincronización se define separadamente en F1.11.

## Commit

- Commit F1.10: pendiente al momento de redactar esta sesión.
