# Pruebas de AnimeApp

Esta guía distingue pruebas disponibles de las previstas. Nunca marques una comprobación como aprobada si no se ejecutó en el entorno y versión registrados.

## Infraestructura de IA disponible

Desde la raíz del repositorio:

```bash
python3 tools/ai/memory.py check
python3 -W error::ResourceWarning -m unittest discover -s tests/ai -v
```

Estas pruebas validan las herramientas de memoria, evaluación y ejecución aislada; no prueban la app Flutter ni reproducción de video. Para repetir evaluación de recuperación, consulta `docs/ai-system/EVALUATION.md`.

Los controles integrados se describen en [scripts/README.md](scripts/README.md); la ejecución completa usa `bash scripts/ci.sh`.

## Aplicación Flutter

### SDK, causa y estado del arreglo LSP

Diagnóstico repetido el 2026-11-08 desde `app/`: Flutter 3.47.9 stable (`c197ca5199e9ee5661e865596c9c07294dfab51c`), Dart 3.13.7. `dart analyze lib test` pasa; `flutter analyze --no-pub` falla con exit 255 y `FormatException: Unexpected end of input` en `LspByteStreamServerChannel._readMessage`, leyendo truncado el mensaje LSP `initialize`. `flutter doctor -v` confirma toolchain Linux; Android SDK falta y no forma parte del destino F0.

La causa quedó confirmada en el código, no inferida solo del estado de las incidencias: el SDK instalado contiene `Content-Length: ${message.length}` en `packages/flutter_tools/lib/src/dart/analysis.dart`. La longitud de caracteres no equivale a la longitud de bytes UTF-8 exigida por LSP. El PR oficial #191377 cambia el cálculo a `utf8.encode(message).length`; la stable 3.47.9 conserva el código anterior. El manifiesto oficial consultado el 2026-11-08 identifica 3.47.9 como stable y 3.50.0-0.4.pre como beta. Fuentes: [issue #191309](https://github.com/flutter/flutter/issues/191309), [issue #192079](https://github.com/flutter/flutter/issues/192079), [PR #191377](https://github.com/flutter/flutter/pull/191377), [manifiesto de releases](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json).

Reproducción controlada en dos proyectos mínimos bajo `.ai-local/diagnostics/`: stable 3.47.9 devuelve 255 en ambas carpetas; Dart analyze pasa. La carpeta llamada `ascii` aún hereda el ancestro Unicode `Vídeos`, así que no representa una ruta absoluta ASCII y no se afirma que sea un control ASCII válido. Con beta 3.50.0-0.4.pre ambos proyectos pasan `flutter analyze --no-pub`; la ruta Unicode incluida en AnimeApp también pasa. La causa queda respaldada además por la reproducción del proyecto y por el código fuente exacto.

La beta se clonó del tag oficial en `.ai-local/toolchains/flutter` (revisión `368ac9e40bad0566927cc9428a42461152652c12`, Dart 3.14.0). Es una herramienta de validación aislada temporal; no sustituye ni modifica la stable global. A la fecha de esta verificación no hay stable publicada con el fix, por lo que el entorno stable predeterminado aún reproduce el fallo y **la incidencia no se declara resuelta de forma permanente**.

Para repetir la validación con ese tag (requiere red para bootstrap de Dart y artefactos Linux):

```bash
git clone --depth 1 --branch 3.50.0-0.4.pre https://github.com/flutter/flutter.git .ai-local/toolchains/flutter
export PATH="$PWD/.ai-local/toolchains/flutter/bin:$PATH"
export PUB_CACHE="$PWD/.ai-local/pub-cache"
bash scripts/ci.sh
```

La selección del SDK es explícita y local a esa terminal; `scripts/ci.sh` sigue usando `flutter` y `dart` del `PATH`, sin rutas personales ni saltos de validación. La ejecución normal con la stable actual continúa fallando hasta que una stable oficial incluya el arreglo.

La base del entorno y sus límites están en [F0.1 Fedora](docs/environment/F0.1-FEDORA.md). El scaffold Linux y sus pruebas son mínimos; desde `app/`, con el SDK seleccionado:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build linux --release --no-pub
```

Para esta reparación se corrigió `analysis_options.yaml` moviendo `strict-casts`, `strict-inference` y `strict-raw-types` a `analyzer.language`, su ubicación documentada. También se cambió el scaffold a la librería oficial `material_ui` 1.10.0: el analyzer de Flutter 3.50 reportaba como issue import el API `flutter/material.dart` deprecado y `flutter analyze` devolvía 1. Esta migración no debilita lints y fue comprobada tanto con Flutter 3.50 beta como con Flutter 3.47.9 stable en test/build; el análisis Flutter stable sigue bloqueado antes por el fallo LSP.

Resultados posteriores con el SDK beta seleccionado: `flutter pub get`, format, Dart analyze, Flutter analyze (sin issues), widget test, build Linux release, checker y CI completa pasan. La compilación y test también pasan con la stable global; solo `flutter analyze` stable continúa en exit 255. La prueba negativa temporal introdujo un import Flutter dentro de `domain`; CI salió 1 por el fixture de arquitectura y por los límites de imports, y el archivo se retiró. `pubspec.lock` conserva una resolución obtenida con Flutter stable, evitando pins transitorios exclusivos de la beta.

## Rendimiento y pruebas manuales

La [línea base release final](docs/perf/measure-20261108T133341Z-15982.tsv) registra tres primeras tramas rasterizadas (mediana 462 ms), RSS (140096 KiB tras frame; 145284 KiB tras reposo a 5 s) y CPU media en reposo de 0.60% de un núcleo. Su método y límites están en [docs/perf/README.md](docs/perf/README.md). La ventana tiene evidencia visual, pero no latencia numérica; la app no reproduce medios y la prueba no cubre fugas prolongadas.

Registrar entorno, modo, repeticiones y limitaciones para cada nueva línea base. RSS del proceso no equivale a memoria total del sistema. Los checklists manuales por plataforma se incorporarán cuando existan esas plataformas.

## F1.7 — Result, errores y logger

Desde `app/`, con el SDK Flutter beta aislado seleccionado según la sección anterior:

```bash
flutter test test/core
dart analyze lib/core test/core
```

La suite comprueba transformaciones/propagación de `Result`, redacción anidada, bearer, cabeceras, query/path/fragment/userinfo de URI, múltiples sinks y dispose. El análisis de seguridad fue estático; no equivale a un pentest ni garantiza detección de cadenas secretas arbitrarias que no estén etiquetadas como sensibles. La CI completa actual se ejecuta mediante `bash scripts/ci.sh` con el SDK aislado en PATH; la stable global sigue fallando en `flutter analyze` por el defecto LSP ya documentado.

## F1.5–F1.6 — Ajustes y persistencia

Desde `app/`, con el SDK Flutter aislado seleccionado según la sección de
toolchain:

```bash
dart run build_runner build
dart format lib test
dart analyze lib/settings test/settings lib/data/local_db test/data/local_db
flutter test --no-pub test/settings/settings_store_test.dart
flutter test --no-pub test/data/local_db/app_database_test.dart
```

Los tests de storage usan archivos SQLite reales solo en
`../.ai-local/test-db/`, verifican el marcador de raíz antes de crear/borrar y
requieren ejecutarse desde `app/`. F1.6 prueba el snapshot v1 versionado, la
migración v1→v2 con datos, reapertura y rollback; F1.5 prueba defaults,
validación, lectura/escritura, watch, errores tipados y reinicio. No se usa la
base de la aplicación real. Las pruebas solo tienen definiciones sintéticas;
no implican un catálogo de ajustes aprobado.

`sqlite3` 3.x carga un asset nativo; la configuración estándar lo obtiene del
release oficial de su paquete y valida SHA-256. En el entorno de esta ejecución
el hook recibió HTTP 504, por lo que se obtuvo el mismo asset oficial y se
comparó con el hash que fija el paquete; la caché permanece en `.ai-local/` y
no está versionada. Una instalación limpia necesita acceso al release oficial.

El análisis y la CI completa de estas subfases pasaron con Flutter 3.50.0-0.4.pre
/ Dart 3.14.0 beta aislado. Flutter stable 3.47.9 mantiene la incidencia LSP
documentada arriba; no se declara verde con esa versión.

## F1.8 — Cliente AniList local

Desde `app/`, los tests de `test/data/anilist/` levantan un servidor HTTP solo
en loopback. Cubren POST GraphQL de lectura, request variables, mapeo al modelo
de dominio, campos ausentes, errores GraphQL/HTTP, timeout, 429/Retry-After,
rate gate entre clientes, cache de una sola búsqueda, fallback offline y
migración v2→v3. No hay prueba de carga ni request a `graphql.anilist.co`.

El uso en producción permanece desconectado hasta revisar los términos de
AniList para el alcance de AnimeApp. La caché implementada reemplaza una sola
búsqueda explícita y nunca hace scraping/prefetch/bulk. Ver [documentación del
adaptador](app/lib/data/anilist/README.md).

## F1.9 — Almacenamiento seguro

`flutter test --no-pub test/data/secure_storage` ejecuta cuatro pruebas contra un fake manual: guardar/leer/borrar, rechazo de token vacío, ausencia de token y errores genéricos que no revelan excepciones del backend. No contactan el keyring. `flutter build linux --debug` comprueba compilación del plugin Linux `flutter_secure_storage_linux`; no ejecuta operaciones de runtime. La prueba real de Secret Service debe realizarse en un entorno autorizado y aislado antes de habilitar cuentas. OAuth sigue pendiente de decisión y no tiene pruebas de flujo/callback.

## F1.10 — Progreso local

`flutter test --no-pub test/data/local_db/local_progress_repository_test.dart` ejecuta tres pruebas con SQLite temporal bajo `.ai-local/`: guardar y recuperar después de cierre/reapertura, reemplazo por identidad exacta, y ausencia de fila/validación JSON. No prueba campos de progreso de producto, reanudación, sincronización, escritura interrumpida ni rendimiento; esos contratos siguen pendientes de definición en ADR-A10/FR-03/FR-11.
