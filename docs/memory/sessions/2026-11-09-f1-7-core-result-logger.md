# F1.7 — Result, errores tipados y logger seguro

Fuente: implementación y validaciones locales en `app/`
Fecha: 2026-11-09
Módulo: core/errors, core/result y core/logger
Estado: completada; revisión estática de seguridad sin hallazgos críticos
Decisión: errores de aplicación estables en Dart puro; no persistir logs
Evidencia: `app/lib/core/README.md`, tests y CI registrados abajo

## Código añadido

- `app/lib/core/errors/app_error.dart`: taxonomía Network, Timeout, RateLimit, Auth, Validation, Storage, NotFound, Unavailable y Unknown, evitando colisiones con clases del SDK.
- `app/lib/core/result/result.dart`: `Success<T>`/`Failure<T>`, `fold`, `map` y `flatMap`; fallos se propagan sin excepciones silenciosas.
- `app/lib/core/logger/safe_logger.dart`: eventos con nivel, código, UTC, correlation id, sinks inyectables, sanitización recursiva y `dispose`; `MemoryLogSink` tiene cierre propio.
- `app/test/core/core_test.dart`: transformaciones, errores tipados, claves y valores anidados, bearer, URI y cierre de múltiples sinks.
- `app/lib/core/README.md`: API real, límites, seguridad, dependencias, ciclo de vida y comandos.

El logger no usa `toString()` de excepciones u objetos arbitrarios. URI se reducen a origen con path genérico, omitiendo userinfo, path real, query y fragment. Campos sensibles conocidos se reemplazan desde la clave hasta el final del fragmento de texto. No se persisten logs. La sanitización cubre patrones identificables; no puede reconocer un token arbitrario en texto sin etiqueta/contexto.

## Verificación

- `flutter test test/core`: exit 0, 4 pruebas.
- `dart analyze lib/core test/core`: exit 0, sin issues.
- `flutter analyze --no-pub`: exit 0 con Flutter 3.50.0-0.4.pre/Dart 3.14.0 seleccionado explícitamente.
- `bash scripts/ci.sh`: exit 0, 40 pruebas de infraestructura, 10 negativos checker, tests app y todos los gates.
- CI ordinaria con Flutter stable 3.47.9 no se vuelve a considerar verde; reproduce exit 255 LSP descrito en `TESTING.md`.
- Auditoría estática de seguridad subagente: primera pasada indicó riesgo en URL, se endureció para eliminar todos los componentes variables de URI; re-revisión confirmó los puntos principales corregidos. El auditor no modificó archivos ni ejecutó tests.

F1.7 no implementa almacenamiento, red, UI, tokens ni OAuth. F1.6 precede a F1.5 por dependencias de la misión. La arquitectura, dominio puro y plataforma no cambian.
