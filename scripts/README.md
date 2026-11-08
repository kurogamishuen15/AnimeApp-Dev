# Scripts de calidad

Estos scripts se ejecutan desde la raíz del repositorio y resuelven `app/` de forma relativa a su propia ubicación. No configuran servicios ni alteran Git.

## CI local

```bash
bash scripts/ci.sh
```

El script ejecuta todas las comprobaciones aun cuando alguna falle y devuelve un código distinto de cero al final si hubo errores. Aísla Pub cache en `.ai-local/pub-cache`, valida memoria, ejecuta las pruebas IA y casos sintéticos del comprobador, revisa formato Dart, `flutter pub get`, análisis Flutter, pruebas Flutter y verifica imports. No oculta salidas de error.

## Límites de imports

```bash
dart scripts/check_imports.dart --root .
bash scripts/test_check_imports.sh
```

El checker tokeniza comentarios y literales Dart antes de reconocer `import` y `export`, incluyendo alias y directivas multilínea. En `app/lib/domain/` prohíbe Flutter/`dart:ui` y dependencias hacia carpetas de presentación o infraestructura (`data`, `providers`, `adapters`, `platform`, `downloads`, `sync`). Si el directorio domain aún no existe, informa que no hay fuentes que revisar. La prueba crea un fixture aislado bajo `.ai-local/`, verifica un caso válido y casos prohibidos (Flutter y presentación) y limpia únicamente su directorio temporal comprobado.

Al agregar módulos prohibidos, actualiza `_violation` y sus fixtures. No debilites reglas para obtener CI verde.

## Estado verificado

Resultados reales, incluido el bloqueo de `flutter analyze` por excepción LSP en esta ruta, se registran en `PROGRESS.md` y el informe de sesión F0.3–F0.6. La ejecución de CI debe repetirse al cierre de cada cambio de estas herramientas.

## Medición inicial

Consulta [../docs/perf/README.md](../docs/perf/README.md) para compilar el bundle release y ejecutar `bash scripts/measure.sh`. La salida TSV no se sobrescribe; deja registrados versión, entorno, PID verificado, tiempo al primer frame rasterizado, RSS, CPU de reposo y estado de observabilidad de ventana. Las corridas parciales se marcan y no se consideran completas.
