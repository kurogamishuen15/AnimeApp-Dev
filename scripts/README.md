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

El checker recorre recursivamente los `.dart` físicos bajo `app/lib/` sin seguir symlinks y protege cualquier archivo dentro de una carpeta `domain`, incluida `features/<feature>/domain/`. Tokeniza comentarios y strings para identificar imports/exports, incluidos alias, directivas multilínea y URIs condicionales. Resuelve imports relativos y `package:<nombre-del-paquete>/...` propios usando la ubicación real del archivo; así los imports relativos no eluden los límites.

En código de dominio prohíbe Flutter/`dart:ui`, APIs del sistema `dart:io` y `dart:ffi`, composición bajo `app/`, carpetas de presentación/UI, infraestructura (`data`, `providers`, `adapters`, `infrastructure`, `integrations`, `platform`, `downloads`, `sync`), plugins conocidos de Flutter/plataforma y referencias locales que escapen de `app/lib`. El checker rechaza symlinks en `app/`, en la raíz `app/lib` y dentro de `app/lib`: no sigue ni raíces, fuentes ni carpetas enlazadas, para evitar omitir dominios futuros. Los imports Dart puros y rutas locales de dominio/core que permanezcan dentro de `app/lib` se permiten.

Las pruebas de `scripts/test_check_imports.sh` confirman un import permitido y diez violaciones: Flutter, presentación, integración, dominio anidado de feature, evasión hacia composición por ruta relativa, plugin de plataforma, archivo Dart enlazado, carpeta `domain` enlazada y raíces `app/lib` y `app` enlazadas; también comprueban el árbol real. Los fallos esperados deben devolver exit 1; un fixture permitido y el proyecto devuelven exit 0. El script crea su fixture exclusivamente bajo `.ai-local/import-check.*` y elimina únicamente esa ruta comprobada.

Limitaciones: es un checker estático de directivas lexicales, no reemplaza `dart analyze` ni el grafo semántico de `package:analyzer`; no detecta dependencias indirectas por APIs generadas/reflexión, ni identifica automáticamente todo paquete externo desconocido como plugin. La lista de plugins vetados se mantiene explícita en `scripts/check_imports.dart`; al aprobar una nueva integración, revisar si debe añadirse. El control protege dependencias directas de archivos Dart fuente, no el contenido transitivo de paquetes.

Al agregar módulos prohibidos, actualiza `_violation` y sus fixtures. No debilites reglas para obtener CI verde.

## Estado verificado

Resultados reales, incluido el bloqueo de `flutter analyze` por excepción LSP en esta ruta, se registran en `PROGRESS.md` y el informe de sesión F0.3–F0.6. La ejecución de CI debe repetirse al cierre de cada cambio de estas herramientas.

## Medición inicial

Consulta [../docs/perf/README.md](../docs/perf/README.md) para compilar el bundle release y ejecutar `bash scripts/measure.sh`. La salida TSV no se sobrescribe; deja registrados versión, entorno, PID verificado, tiempo al primer frame rasterizado, RSS, CPU de reposo y estado de observabilidad de ventana. Las corridas parciales se marcan y no se consideran completas.
