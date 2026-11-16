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

### Estado actual de providers S0-S (2026-11-16)

El root registra `AnimesDigitalPlaybackProvider` v1.0.0 como candidato y un
`DirectMediaHostResolver` genérico. El provider obtiene el episodio público de
One Piece 1180, un HLS y su primer segmento (HTTP 200); al entregarlo a la
ventana real media_kit/libmpv, se mostró error de decodificación y pantalla
negra. No se acredita reproducción visible ni se cierra S0-S. `EpisodeSourceAdapter`
separa matching, episodios y fuentes y no acepta fuzzy matching automático.
Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub --concurrency=1 \
  test/domain/episode_source_adapter_test.dart \
  test/domain/playback_provider_contract_test.dart \
  test/application/playback_provider_manager_test.dart \
  test/application/playback_source_cache_test.dart \
  test/data/player/providers/animesdigital \
  test/data/player/providers/hosts/direct_media_host_resolver_test.dart \
  test/data/player/providers/playback_providers_module_test.dart
```

La prueba focalizada del provider AnimesDigital pasó 7/7, incluida la regresión
de presupuesto total compartido entre búsquedas lentas. La última suite Flutter
completa terminó con **300 aprobadas y 7 omitidas de forma optativa** mediante
`../.ai-local/toolchains/flutter/bin/flutter test --no-pub --concurrency=1`.
Dart analyze de `lib test tool` y
`flutter analyze --no-pub` no reportaron problemas. El log completo ignorado
por Git en `.ai-local/review/s0s-final-flutter-suite-2026-11-16.log` corresponde
a la ejecución anterior de 297/7; la última salida de 300/7 quedó en la consola,
no se guardó como log.
El harness HTTP live está descrito en [`app/tool/README.md`](app/tool/README.md).
Para ejecutar el smoke HLS técnico
previo de libmpv:

```bash
KONGROO_TEST_PUBLIC_HLS=1 ../.ai-local/toolchains/flutter/bin/flutter test \
  --no-pub --concurrency=1 test/player/public_hls_host_integration_test.dart
```

La fuente de prueba anterior devolvió HTTP 200 y libmpv avanzó 2038 ms, pero no
hubo frame/ventana/audio observados ni es un episodio. El live harness actual
comprobó en AnimesDigital el HLS 200/4998 bytes, 142 segmentos y un segmento TS
200/67258 bytes para el episodio 1180. Las ventanas de los episodios 1180 y 1
mostraron negro/error de decodificación. No se midió CPU/RAM del stream. La
baseline del player previa a S0-S es
[`S0-S-BASELINE-AND-IMPLEMENTATION.md`](docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).

La opción `KONGROO_LIVE_FFPROBE=1` añadió diagnóstico redacted: una corrida del
episodio 1 observó que libavformat rechazó una referencia HLS `.webp` por
`allowed_segment_extensions`; no demuestra que esa sea la causa del fallo de
libmpv. Una solicitud posterior del provider terminó en `timeout`. No se amplió
la lista permitida ni se almacenaron URLs firmadas. La herramienta analiza
transporte y metadatos; no sustituye una ventana con cuadro visible.
Las pruebas del resumen/redacción pasan 3/3 con el SDK aislado del proyecto;
`dart analyze` del harness y su test no reporta issues.

### Estado histórico de providers tras limpieza S0 (2026-11-15)

En el corte histórico del 2026-11-15, el runtime no registraba providers
externos ni resolutores concretos. Esa limpieza fue reemplazada en S0-S por el
registro del candidato AnimesDigital descrito arriba. Las pruebas que siguen
documentan solo ese corte histórico.

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/playback_providers_module_test.dart \
  test/application/playback_provider_manager_test.dart \
  test/domain/playback_provider_contract_test.dart
```

Los 22 tests deterministas y el smoke Miruro de la ejecución S0-A son evidencia
histórica. Sus fuentes se archivaron como `.dart.txt` no ejecutables en
[`docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/`](docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/);
el smoke ordinario obtuvo HTTP 403 y no acreditó episodio, media ni playback.
El reporte está en el [informe S0-A](docs/ai-system/missions/S0-ANILILI-PORT-REPORT.md)
y la [auditoría de limpieza posterior](docs/ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md).
No hay proveedores activos que probar en vivo; reproducción externa continúa
0/70.

### SDK, causa y estado del arreglo LSP

Diagnóstico repetido el 2026-11-08 desde `app/`: Flutter 3.47.9 stable (`c197ca5199e9ee5661e865596c9c07294dfab51c`), Dart 3.13.7. `dart analyze lib test` pasa; `flutter analyze --no-pub` falla con exit 255 y `FormatException: Unexpected end of input` en `LspByteStreamServerChannel._readMessage`, leyendo truncado el mensaje LSP `initialize`. `flutter doctor -v` confirma toolchain Linux; Android SDK falta y no forma parte del destino F0.

La causa quedó confirmada en el código, no inferida solo del estado de las incidencias: el SDK instalado contiene `Content-Length: ${message.length}` en `packages/flutter_tools/lib/src/dart/analysis.dart`. La longitud de caracteres no equivale a la longitud de bytes UTF-8 exigida por LSP. El PR oficial #191377 cambia el cálculo a `utf8.encode(message).length`; la stable 3.47.9 conserva el código anterior. El manifiesto oficial consultado el 2026-11-08 identifica 3.47.9 como stable y 3.50.0-0.4.pre como beta. Fuentes: [issue #191309](https://github.com/flutter/flutter/issues/191309), [issue #192079](https://github.com/flutter/flutter/issues/192079), [PR #191377](https://github.com/flutter/flutter/pull/191377), [manifiesto de releases](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json).

Reproducción controlada en dos proyectos mínimos bajo `.ai-local/diagnostics/`: stable 3.47.9 devuelve 255 en ambas carpetas; Dart analyze pasa. La carpeta llamada `ascii` aún hereda el ancestro Unicode `Vídeos`, así que no representa una ruta absoluta ASCII y no se afirma que sea un control ASCII válido. Con beta 3.50.0-0.4.pre ambos proyectos pasan `flutter analyze --no-pub`; la ruta Unicode incluida en AnimeApp también pasa. La causa queda respaldada además por la reproducción del proyecto y por el código fuente exacto.

La beta se clonó del tag oficial en `.ai-local/toolchains/flutter` (revisión `368ac9e40bad0566927cc9428a42461152652c12`, Dart 3.14.0). Es una herramienta de validación aislada temporal; no sustituye ni modifica la stable global. A la fecha de esta verificación no hay stable publicada con el fix, por lo que el entorno stable predeterminado aún reproduce el fallo y **la incidencia no se declara resuelta de forma permanente**.

Para repetir la validación con ese tag (requiere red para bootstrap de Dart y artefactos Linux):

```bash
git clone --depth 1 --branch 3.50.0-0.4.pre https://github.com/flutter/flutter.git .ai-local/toolchains/flutter
unset FLUTTER_ROOT
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
La auditoría F1.12 añade aislamiento entre claves y evita notificaciones por
escrituras equivalentes. El test detectó una emisión redundante causada por
actualizaciones de otra fila; el store compara el JSON tipado validado.

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
de dominio, campos ausentes, errores GraphQL/HTTP (400/401/403/429/5xx),
timeout, redirección rechazada, `Retry-After`, tasas 90/30 con reloj simulado,
caché de una búsqueda, datos corruptos, fallback offline y migración v2→v3.
No hay prueba de carga ni request a `graphql.anilist.co`.

El uso en producción permanece desconectado hasta revisar los términos de
AniList para el alcance de AnimeApp. La caché implementada reemplaza una sola
búsqueda explícita y nunca hace scraping/prefetch/bulk. Ver [documentación del
adaptador](app/lib/data/anilist/README.md).

## F1.9 — Almacenamiento seguro

`flutter test --no-pub test/data/secure_storage` ejecuta cuatro pruebas contra un fake manual: guardar/leer/borrar, rechazo de token vacío, ausencia de token y errores genéricos que no revelan excepciones del backend. No contactan el keyring. `flutter build linux --debug` comprueba compilación del plugin Linux `flutter_secure_storage_linux`; no ejecuta operaciones de runtime. La prueba real de Secret Service debe realizarse en un entorno autorizado y aislado antes de habilitar cuentas. OAuth sigue pendiente de decisión y no tiene pruebas de flujo/callback.

## F1.10 — Progreso local

`flutter test --no-pub test/data/local_db/local_progress_repository_test.dart` ejecuta tres pruebas con SQLite temporal bajo `.ai-local/`: guardar y recuperar después de cierre/reapertura, reemplazo por identidad exacta, y ausencia de fila/validación JSON. No prueba campos de progreso de producto, reanudación, sincronización, escritura interrumpida ni rendimiento; esos contratos siguen pendientes de definición en ADR-A10/FR-03/FR-11.

El progreso tipado F1.10 está en `app/lib/domain/progress/`. Suite focalizada:
`flutter test --no-pub test/data/local_db/playback_progress_repository_test.dart`
y `app_database_test.dart`: SQLite físico CRUD/reopen/integrity, 45:00,
migraciones históricas y carrera 15:00→45:00 con barrera sobre el writer Drift.
La prueba del modelo F1.10 se agregó cuando el schema era v4; el esquema actual
es v6 y conserva JSON heredado. El reloj es inyectado para checkpoints.

## Arquitectura de catálogo e identidad local

La [guía de pruebas](docs/development/catalog-testing.md) separa las pruebas
de contrato, SQLite y providers. Desde `app/`:

```bash
flutter test --no-pub test/domain/catalog/catalog_contracts_test.dart
flutter test --no-pub test/data/local_db/catalog_identity_repository_test.dart
flutter test --no-pub test/data/local_db/app_database_test.dart
dart analyze lib/domain/catalog lib/data/local_db test/domain/catalog test/data/local_db
```

Si el shell hereda `FLUTTER_ROOT`, quítalo antes de `flutter pub get` para que
`.dart_tool/package_config.json` apunte al SDK elegido por `PATH`. Verifica la
ruta `flutter` y `dart` con `command -v` desde la terminal seleccionada. Esta
misión validó Flutter 3.50.0-0.4.pre / Dart 3.14.0-315.3.beta; no modifica
configuración global ni el SDK estable.

Usan fakes manuales, IDs sintéticos y archivos SQLite físicos en
`.ai-local/test-db/`; cubren crosswalk/conflictos, relaciones tipadas,
biblioteca add/remove/status, progreso conservado, migraciones v1/v2/v3/v4/v5 a
schema v7, `integrity_check` y `foreign_key_check`. El widget test recorre UI,
reapertura y bloquea HTTP. No contactan AniList, TMDB ni Kitsu.
No verifican OAuth/keyring real, provider real, reproducción o rendimiento.

## F2.2 — Spike de reproducción real

El estado y la evidencia de esta subfase se actualizan en
[`docs/player/F2.2-spike-report-v2.md`](docs/player/F2.2-spike-report-v2.md).
Los resultados de suite/build con exit 0 que aparecen en el corte del
2026-11-09 son históricos. Para seleccionar una toolchain desde `app/`, no
uses el `flutter` que venga por defecto en `PATH`:

```bash
unset FLUTTER_ROOT
export PATH="../.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
export PUB_CACHE="../.ai-local/pub-cache"
```

El 2026-11-10 se usó Flutter 3.47.9 stable/Dart 3.13.7, checkout aislado
compatible con el mínimo del proyecto. Con él pasaron el test startup/cierre
(2), la suite player (32), la suite Flutter completa (94) y el build Linux
release del spike con `-t lib/main_player_spike.dart`. `dart analyze lib test`
terminó 0 sin errores y mostró ocho sugerencias informativas preexistentes.
`flutter analyze --no-pub` en esa stable sigue terminando 255 antes del análisis
por el error LSP de UTF-8 bajo la ruta Unicode `Vídeos`, descrito arriba. La
beta 3.50.0-0.4.pre pasa Flutter analyze pero sus tests/build fallan antes de
la aplicación porque `dart:ui` declara `SemanticsRole.slider` y el framework
no lo cubre exhaustivamente en `semantics.dart:164`.

`bash scripts/ci.sh` se ejecutó completo con Flutter 3.47.9 y terminó exit 1
por ese único paso fallido (`flutter analyze`, exit 255). Pasaron los 40 tests
Python de infraestructura IA, el checker positivo y sus diez casos negativos,
formato, Dart analyze (ocho infos), dependencias, 94 tests Flutter y límites de
imports. El build específico del spike también pasó por separado. Por tanto,
la CI aún no está completamente verde con la stable disponible.

### Actualización aislada — 2026-11-14

Para resolver el bloqueo de beta (`SemanticsRole.slider`) y de `flutter analyze`
en la ruta no ASCII, se usa Flutter 3.47.9/Dart 3.13.7 de `.ai-local`, con el
backport reproducible de Content-Length UTF-8 basado en el PR oficial #191377.
El SDK global y la app no se modificaron, no se excluyó analyze y el análisis
Flutter pasó. La suite completa pasó 250 pruebas y omitió 6 opt-in; el build
Linux release también pasó. `scripts/ci.sh` ejecutó 40 pruebas IA, formato,
Dart/Flutter analyze y las 250 pruebas Flutter, pero terminó exit 1 por el
checker de límites: `spike_player_page.dart` importa `dart:io` desde la capa
app. Esta violación es ajena al cambio de providers y permanece pendiente de una
corrección propia. La evidencia vigente está en la [auditoría de integración
de providers](docs/ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md).

La integración usa `MediaKitSpikeEngine` y libmpv reales; los fakes prueban la
coordinación y cierres controlados. Esta revalidación usa Flutter stable
3.47.9/Dart 3.13.7, no la beta incompatible,
`ffmpeg`/`ffprobe` y libmpv compatible en Fedora/Linux. Desde la raíz:

```bash
tools/player/generate_f2_2_fixture.sh
tools/player/run_f2_2_spike.sh
```

El generador produce video MPEG-4 320×180/24 fps más audio AAC 48 kHz por
8 segundos dentro de `.ai-local/f2.2/fixtures/`, con patrones sintéticos y sin
red. Rechaza symlinks y no sobrescribe medios existentes. Si falta el fixture,
`player_test_fixture.dart` llama al mismo generador durante la preparación de
las pruebas; por eso una copia limpia necesita `ffmpeg` disponible. La raíz se
deriva desde cwd del proyecto o `app/`, o se fija mediante
`KONGROO_PROJECT_ROOT`; no se busca arbitrariamente por directorios padres. El launcher deriva
las rutas de la ubicación del script, valida el fixture con `ffprobe`, fija
`KONGROO_F2_2_SPIKE=1` y `KONGROO_PROJECT_ROOT` y ejecuta el entrypoint separado.
El entrypoint deriva `.ai-local/f2.2/fixtures/spike.mp4`, rechaza symlinks en
`.ai-local/`, `.ai-local/f2.2/` y `fixtures/`, comprueba que los directorios y
el medio sean locales y regulares, y no depende de
`Directory.current` ni acepta una ruta de fixture externa.

Desde `app/`, con las variables anteriores, ejecuta:

```bash
flutter pub get --offline --enforce-lockfile
flutter test --no-pub test/player/main_player_spike_test.dart
flutter test --no-pub test/player
flutter analyze --no-pub
flutter build linux --release --no-pub -t lib/main_player_spike.dart
```

Regresión adicional del guard de symlinks y del watchdog seguro del cierre,
desde la raíz:

```bash
bash tools/player/test_f2_2_fixture_guards.sh
dart tools/player/verify_f2_2_close_gate.dart
```

La suite player contiene casos de drag/coalescing, control único Play/Pause,
formato de tiempo/layout estrecho, ausencia de controles adaptativos, rechazo
de symlinks en cada nivel del fixture, estados diferenciados de
controller/textura/primer frame, cierre con operación pendiente, fallo de
cierre, lease/cuarentena, apertura real, pause/seek/stop, stop→reopen,
fuente inexistente, medio inválido y recuperación. El ciclo de vida del
`VideoController` con el plugin Linux real sigue pendiente; una prueba
exploratoria con canal simulado no completó su Future de plataforma y se retiró.
Los watchdogs de pruebas no
cancelan Futures nativos: tras un timeout, esperan el Future original antes de
disponer el Player. El build y la integración headless no prueban compositor.
El 2026-11-10 se añadieron regresiones que comprueban que Stop descarta un seek
coalescido, espera el seek activo y conserva el orden. También se prueba
`SpikePlayerApp` con mensajes platform→Dart del MethodChannel para que el aviso
de cleanup permanezca visible si la apertura falla o queda pendiente. Las
regresiones y la suite player pasaron con stable 3.47.9. `dart analyze` termina
0; Flutter analyze stable sigue bloqueado por LSP UTF-8, no por el mismatch de
kernel de la beta. El runner `my_application.cc` incluye un
watchdog GTK nominal de 20 s que invalida respuestas tardías. Mientras la
llamada MethodChannel original siga pendiente, no duplica solicitudes y la
ventana se mantiene abierta; cuando llega el callback, otro gesto puede
reintentar. Su objeto C++ compiló, pero no se verificó el `delete-event` real.

Se intentó una sesión Broadway aislada con runtime y socket dentro de
`.ai-local/f2.2/`. GTK no pudo obtener EGL y Flutter no creó platform view; el
plugin registró un texture ID y reportó software rendering, lo cual no prueba
primer frame ni imagen visible. El proceso terminó por Ctrl-C, no mediante
cierre GTK. La sesión gráfica principal no se utilizó. Hay una confirmación
manual histórica del propietario de video y audio visibles, pero precede a
los cambios de controles. No se midió rendimiento actual. Ver la matriz y los
comandos exactos en el [informe F2.2 v2](docs/player/F2.2-spike-report-v2.md)
y la [auditoría profunda](docs/ai-system/audits/F2.2-audit-2026-11-10.md).
No es prueba de distribución, licencias de artefactos, estabilidad prolongada
ni rendimiento en hardware objetivo.

### Addendum F2.2 — Verificación focalizada — 2026-11-10

El SDK aislado Flutter 3.47.9 (`c197ca5199e9ee5661e865596c9c07294dfab51c`)
contenía el defecto upstream de LSP: declaraba `Content-Length` con unidades
de texto en lugar de bytes UTF-8. El [PR oficial #191377](https://github.com/flutter/flutter/pull/191377)
corrige ese cálculo; el [issue #191309](https://github.com/flutter/flutter/issues/191309)
documenta el fallo con rutas no ASCII. Se conserva el SDK aislado sin alterar
Flutter global. El backport reproducible está en
`tools/flutter/patches/flutter-3.47.9-lsp-content-length-utf8.patch` y se aplica
solo si coincide la revisión fijada:

```bash
tools/flutter/apply_flutter_3479_lsp_patch.sh
env -u FLUTTER_ROOT PATH="$PWD/.ai-local/toolchains/flutter-3.47.9/bin:$PATH" \
  PUB_CACHE="$PWD/.ai-local/pub-cache" bash scripts/ci.sh
```

El helper invalida `flutter_tools.stamp`; el siguiente uso de Flutter
reconstruye la herramienta desde el source parcheado. En esta ejecución,
`flutter analyze --no-pub` pasó en la ruta real bajo `Vídeos` con exit 0 y
`No issues found`. Las ocho infos `prefer_final_locals` que impedían el exit 0
se resolvieron declarando `final` los bindings señalados; no se cambiaron ni
silenciaron reglas. La CI completa terminó exit 0: 40 pruebas Python, checker
positivo y diez casos negativos, formato de 94 archivos, análisis Dart y
Flutter sin issues, dependencias, 94 pruebas Flutter y límites de imports.

**Verificación manual del propietario (no automatizada):** el propietario
confirma video visible con fotogramas cambiantes, audio, una sola interfaz de
controles sin barra automática adicional, Play/Pause y seek hacia adelante y
atrás. No se atribuyen estas observaciones a pruebas ejecutadas por Codex.

La integración automatizada con libmpv comprueba Stop y reapertura, pero no
crea un `VideoController` Linux nativo. El propietario confirmó después,
manualmente en Fedora, la recuperación de imagen/audio en dos ciclos Stop →
Play y el cierre normal de ventana/proceso. Esta aceptación no equivale a una
prueba automatizada end-to-end del lifecycle del `VideoController`, que sigue
siendo una limitación de cobertura. Los tests de superficie usan un fake. El
helper `tools/player/capture_f2_2_owner_close.sh` permanece disponible para
capturas instrumentadas futuras; no fue necesario para registrar la aceptación
manual reportada. F2.2 está aceptada/cerrada; F2.3 requiere autorización
explícita.

## F1.11 — Contrato local-first

`flutter test --no-pub test/data/testing/fake_sync_remote_test.dart` cubre ack, error configurable e ID vacío. El fake no tiene persistencia ni red. `dart scripts/check_imports.dart --root .` verifica que el dominio de sincronización no dependa de Flutter/infraestructura. Estas pruebas no acreditan idempotencia, conflicto, reintentos ni compatibilidad Supabase.

## F1.12 — Núcleo integrado

`flutter test --no-pub test/core/f1_12_real_integration_test.dart` recorre
ajustes → SQLite en archivo → HTTP loopback → caché persistente →
cierre/reapertura → conexión rechazada offline → recuperación con un segundo
servidor. Comprueba `PRAGMA integrity_check` después del cierre.
`core_integration_test.dart` comprueba aparte que una falla de `FakeSyncRemote`
no altera el progreso local; no existe coordinador de sincronización.

El informe, comandos, códigos y límites están en [validación real F1.5–F1.12](docs/validation/2026-11-09-f1-5-f1-12-real-tests.md). La suite Flutter completa terminó con 44 pruebas en Flutter 3.50.0-0.4.pre / Dart 3.14.0 seleccionados explícitamente; el resultado de CI completa y build Linux consta en el informe. La stable 3.47.9 todavía falla `flutter analyze` por el defecto LSP de ruta Unicode; no se declara CI verde con stable.

## Integración local del catálogo — 2026-11-09

Con Flutter 3.50.0-0.4.pre / Dart 3.14.0-315.3.beta seleccionado por PATH:

```bash
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter analyze --no-pub
flutter test --no-pub test/data/local_db/app_database_test.dart test/data/local_db/catalog_identity_repository_test.dart test/widget_test.dart
flutter test --no-pub
flutter build linux --debug --no-pub
```

La sesión documenta los códigos de salida, suite (62 tests), build y arranque
del bundle. En la prueba widget, `HttpOverrides` falla ante creación de HTTP;
Drift usa un archivo temporal. El binario Fedora se lanzó con
`KONGROO_DATABASE_PATH` dentro de `.ai-local/`, produjo primer frame
rasterizado y abrió schema v6 con `PRAGMA integrity_check=ok`. Ese marcador no
certifica que el compositor haya presentado una ventana. No abrir la base de
Application Support personal al validar.


### Aceptación formal F2.2 — 2026-11-10

El propietario aceptó y cerró F2.2 tras validar manualmente en Fedora imagen y
audio, controles únicos, Play/Pause, Seek, dos ciclos Stop → Play con recuperación
de imagen/audio y cierre normal de ventana/proceso. Codex registró CI exit 0
(40 pruebas Python de infraestructura y 99 pruebas Flutter) y build Linux
release con `-t lib/main_player_spike.dart` exit 0. La integración automatizada
con libmpv cubre posición, pausa, seek, Stop/reapertura y recuperación; no existe
una prueba automatizada completa del lifecycle nativo de `VideoController`.

El análisis CI de Flutter usa el toolchain aislado Flutter 3.47.9 con el
backport local del Content-Length UTF-8 upstream, aplicado mediante
`tools/flutter/apply_flutter_3479_lsp_patch.sh`. Se conserva el parche
`tools/flutter/patches/flutter-3.47.9-lsp-content-length-utf8.patch`; no modifica
Flutter global. CI repetible:

```bash
tools/flutter/apply_flutter_3479_lsp_patch.sh
env -u FLUTTER_ROOT PATH="$PWD/.ai-local/toolchains/flutter-3.47.9/bin:$PATH" \
  PUB_CACHE="$PWD/.ai-local/pub-cache" bash scripts/ci.sh
```

F2.2 está aceptada/cerrada. F2.3 fue autorizada el 2026-11-10 y permanece
abierta para revisión del propietario; las verificaciones de fullscreen real y
compositor deben hacerse manualmente en Fedora.

## F2.3 — Controles básicos por teclado

Toolchain seleccionada dentro del repositorio (sin cambiar Flutter global):

```bash
env -u FLUTTER_ROOT PATH="$PWD/.ai-local/toolchains/flutter-3.47.9/bin:$PATH" \
  PUB_CACHE="$PWD/.ai-local/pub-cache" bash scripts/ci.sh
```

Pruebas focalizadas y build del entrypoint que presenta el spike:

```bash
cd app
unset FLUTTER_ROOT
export PATH="../.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
export PUB_CACHE="../.ai-local/pub-cache"
flutter test --no-pub test/player/spike_player_page_test.dart
flutter test --no-pub test/player/spike_player_coordinator_test.dart
flutter test --no-pub test/player/player_window_controller_test.dart
flutter test --no-pub test/player/media_kit_spike_integration_test.dart
flutter test --no-pub test/player
flutter build linux --release --no-pub -t lib/main_player_spike.dart
```

Los tests de página envían eventos Flutter para el mapa, modificadores,
repetición, foco de `EditableText`, límites y secuencias rápidas. La integración
con libmpv observa el valor de volumen emitido por el `Player`. El test
`player_window_controller_test.dart` simula solicitudes y callbacks del canal;
no demuestra el cambio de estado de una ventana GTK ni la presentación en el
compositor. Esta corrida del entorno no instaló Xvfb y no abrió una ventana en
el `DISPLAY` personal.

### Protocolo manual GTK/Fedora requerido

En una sesión Fedora propia, ejecutar desde la raíz del repositorio:

```bash
tools/player/run_f2_2_spike.sh
```

Comprobar con el video y audio en reproducción: Espacio y K alternan una vez
Play/Pause incluso al mantenerlas; las flechas izquierda/derecha mueven el
tiempo en pasos aproximados de 10 s y respetan principio/final; arriba/abajo
cambian solo el volumen del reproductor en pasos de 5, entre 0 y 100; F entra
en fullscreen GTK y F vuelve a restaurar; Escape restaura si está fullscreen y
no genera error fuera de él. Verificar foco tras pulsar los botones y tras
volver a la ventana, que el video/audio siguen activos durante fullscreen,
Stop → Espacio vuelve a abrir la fuente, y cerrar por el marco de ventana
completa cleanup GTK/libmpv. Registrar por separado qué transiciones fueron
observadas; un mensaje de “solicitud enviada” no equivale a fullscreen
confirmado. No hay todavía confirmación manual de estos criterios en esta
subfase.

## Providers de reproducción desde ficha — 2026-11-14

Históricamente se ejecutaron smokes live de AnimeAV1/TioAnime. Esos adaptadores
y su archivo de pruebas se retiraron en la limpieza S0; los resultados/logs
anteriores se conservan en el informe y la auditoría. Esta sección ya no ofrece
comandos ejecutables para esos proveedores.

Para probar los contratos que permanecen desde `app/`:

```bash
unset FLUTTER_ROOT
export PATH="../.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
export PUB_CACHE="../.ai-local/pub-cache"
flutter analyze --no-pub
flutter test --no-pub test/data/player/providers/playback_providers_module_test.dart \
  test/domain/playback_provider_contract_test.dart \
  test/application/playback_provider_manager_test.dart
```

La corrida histórica de los adaptadores produjo 25 pruebas focalizadas
aprobadas y seis omitidas en la suite total de ese momento; esos conteos no
describen el árbol después de la limpieza. TioAnime listó cinco servidores y
ninguno reprodujo; AnimeAV1 fue denegado al resolver el iframe. Los logs y los
límites por host permanecen en
[`S0-REAL-PLAYBACK-REPORT.md`](docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md)
y [`S0-provider-cleanup-audit`](docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md).

El build Linux release de la app pasó con el SDK aislado. Para repetirlo:

```bash
flutter build linux --release --no-pub
```

La prueba live no verifica interacción gráfica en una ventana Kongroo ni
recorrido manual desde la ficha. Registrar esas comprobaciones por separado.

## Reconstrucción Kongroo T00–T03 — reevaluación 2026-11-15

La evidencia, los límites del diagnóstico y el siguiente punto de trabajo están
en [`KONGROO-RECONSTRUCTION-STATUS.md`](docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md)
y en la [auditoría de reevaluación](docs/ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md).
La CI se ejecutó con el toolchain aislado del proyecto
`.ai-local/toolchains/flutter-3.47.9` (framework revision `c197ca5199`) y
resolución de paquetes offline. El SDK externo/global no se modificó; la
stable 3.47.9 que resolvía originalmente por `PATH` mantiene el fallo LSP UTF-8
registrado arriba.

Para repetir CI sin una consulta de red a pub.dev:

```bash
unset FLUTTER_ROOT
export PATH="$PWD/.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
export KONGROO_FLUTTER_BIN="$PWD/.ai-local/toolchains/flutter-3.47.9/bin/flutter"
flutter() {
  if [[ "$#" -ge 2 && "$1" == "pub" && "$2" == "get" ]]; then
    shift 2
    "$KONGROO_FLUTTER_BIN" pub get --offline "$@"
  else
    "$KONGROO_FLUTTER_BIN" "$@"
  fi
}
export -f flutter
bash scripts/ci.sh
```

En la reevaluación, `scripts/ci.sh` terminó exit 0: 40 pruebas Python y 269
Flutter pasaron; 6 opt-in se omitieron. `flutter analyze --no-pub`, `dart
analyze lib test`, checker (30 archivos player/34 domain), formato e integridad
de memoria pasaron. Las 43 pruebas focalizadas cubren cancelación cooperativa,
cierre tardío, lease nativo retenido, limpieza auxiliar y preferencias
inyectadas. La prueba de integración libmpv single-owner pasó 1/1: abrió y
avanzó una fixture local, y rechazó construir un segundo Player. El primer CI
de reevaluación encontró una dependencia UI→data; se movió la traducción de
contención al composition root y el rerun completo pasó.

`pub get --offline` alteró temporalmente `pubspec.lock`; se restauró al archivo
previo y se comprobó el mismo SHA-256. El timeout histórico de 45 s con dos
aperturas no se repitió ni se aprueba. No se probaron proveedores externos:
`0/70`. Tampoco se automatizó el ciclo completo de `VideoController` con el
compositor. Los logs nuevos se guardaron en
`.ai-local/review/block-a-reassessment-2026-11-15/`; los logs originales del
timeout/incidente y el bundle histórico no estaban disponibles. Ver la
[auditoría de reevaluación](docs/ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md).

## Registro histórico de pruebas S0 — antes del port Anilili/Miruro — 2026-11-15

Este registro conserva resultados de la limpieza previa al prompt S0-A. En ese
corte se habían retirado los adaptadores y tests de red previos; el árbol
posterior registra el provider Miruro, descrito en la sección S0-A al inicio de
este documento. Los comandos de los adaptadores retirados ya no existen. El
manager y los contratos genéricos permanecen.

Desde `app/`, suite focalizada:

```bash
unset FLUTTER_ROOT
export PATH="$PWD/../.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
flutter test --no-pub test/application/playback_provider_manager_test.dart
flutter test --no-pub test/data/player/providers/playback_providers_module_test.dart \
  test/application/playback_provider_manager_test.dart \
  test/domain/playback_provider_contract_test.dart
flutter analyze --no-pub
```

La suite combinada final de esta ejecución pasó 22 pruebas y omitió los dos smokes
live por defecto; Flutter analyze pasó. La regresión fake de fallback y el
cambio de fuente con libmpv usando fixtures locales pasaron por separado (1/1
cada una); ninguno prueba un proveedor externo. Los smokes de TioAnime y
AnimeAV1 que produjeron esos resultados ya no son ejecutables tras retirar sus
adaptadores. No se repiten sin una nueva integración y evidencia de acceso.
Ninguna evidencia acredita primer frame visible, audio audible o seek. AnimeJara
`/catalogo/` y Latanime respondieron 403; Henaojara redirigió a AnimeJara sin
seguirla; Animeflv.one permitió buscar One Piece, pero dos fichas no expusieron
rutas de episodio. AnimeKai mirrors no resolvieron DNS; AllAnime raíz dio 200 sin
rutas parseables. Salidas sanitizadas en
`.ai-local/review/s0-real-playback-2026-11-15/` y el estado consolidado en
[informe S0](docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md). La auditoría
de calidad está en [S0-provider-audit](docs/ai-system/audits/S0-provider-audit-2026-11-15.md).

### Continuación de S0 — AnimeGG y KickAssAnime — 2026-11-15

Flutter 3.47.9 del toolchain del proyecto: `flutter analyze --no-pub` limpio;
provider fixtures 7/7, contrato domain 6/6, manager 16/16 y coordinator 28/28.
La integración opt-in local del `Referer` con libmpv pasó 1/1: vio la cabecera
en la solicitud HTTP inicial y tras Stop→Play, con tres requests loopback.
Esto valida transporte local, no una fuente AnimeGG.

El smoke histórico de AnimeGG se ejecutó una vez, con límite de tres minutos y
una resolución por servidor. One Piece episodio 1 mostró cinco variantes (subbed
1080/720/480/360p y dubbed 360p); las cinco terminaron en
`PlaybackProviderFailureKind.network`. El test salió 1 porque ninguna fuente
alcanzó libmpv. No hubo reintento adicional, primer frame externo, audio, seek
ni ventana gráfica. La prueba y el adaptador quedaron retirados; la salida
sanitizada permanece en `.ai-local/review/s0-real-playback-2026-11-15/`.

El probe de KickAssAnime `kaa.lt` verificó búsqueda, detalle, idioma, episodio 1
y un servidor CatStream con GET/POST públicos ordinarios. La página pública del
player devolvió 200 sin un manifiesto o URI estática reconocible; no se ejecutó
firma, AES, JavaScript de extracción ni otro método de evasión. Las evidencias
consolidadas y clasificación están en el [informe S0](docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).
CI completa y build release no se ejecutaron en esta continuación.

### Continuación de S0 — resolutores reutilizables de hosts — 2026-11-15

La herramienta usada en esta verificación fue el Flutter 3.50.0-0.4.pre y Dart
3.14.0 beta aislados bajo `.ai-local/toolchains/flutter`; no se cambió el SDK
global ni `pubspec.lock`. Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/playback_providers_module_test.dart \
  test/application/playback_provider_manager_test.dart \
  test/domain/playback_provider_contract_test.dart
KONGROO_TEST_HTTP_REFERER=1 \
  ../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/player/media_kit_spike_integration_test.dart \
  --plain-name 'libmpv preserves a public Referer across open and replay after Stop'
../.ai-local/toolchains/flutter/bin/flutter analyze --no-pub
../.ai-local/toolchains/flutter/bin/dart analyze lib test
```

Resultado actual: la suite resolver/proveedores+manager/domain dio **41 pass y
3 live omitidas**, y route/coordinator dio **35/35**;
la integración HTTP loopback + libmpv dio **1/1**, con `Referer` observado y
posición a 43 ms; Flutter/Dart analyze limpios. HLS usa GET acotado sin Range y
comprueba `#EXTM3U`; MP4 prueba Range y repite una sola vez con GET ordinario
ante 405/416/5xx. Fakes cubren redirecciones permitidas/no permitidas,
cabeceras, URLs expiradas, HLS inválido y SAMPLE-AES.

Los smokes live TioAnime y AnimeGG terminaron anteriormente con fallos de
aceptación; las pruebas se retiraron junto con los adaptadores. Los logs
sanitizados siguen en `.ai-local/review/s0-real-playback-2026-11-15/`.

TioAnime recorrió cinco hosts: Mega/OK.ru/Netu `unsupported`, StreamSB timeout
y YourUpload error de red. AnimeGG resolvió a `vidcache.net`; libmpv avanzó
5311 ms y detectó audio, pero no dimensiones de video. Ambas salidas live son
**fallos de aceptación**, no pruebas aprobadas. AnimeAV1/Zilla permaneció en
`unauthorized`; AniZone/vid-cdn devolvió 404 por Range y GET ordinario y 419 en
la acción Livewire. No repetir estos hosts sin evidencia nueva. Ver la
[auditoría de hosts](docs/ai-system/audits/S0-video-host-audit-2026-11-15.md).
No se ejecutó CI completa, build release ni recorrido visual externo.

### Verificación después de la limpieza — 2026-11-15

Con el mismo SDK aislado, desde `app/` se ejecutó la suite completa sobre el
runtime ya limpio:

```bash
../.ai-local/toolchains/flutter/bin/flutter analyze --no-pub
../.ai-local/toolchains/flutter/bin/dart analyze lib test
../.ai-local/toolchains/flutter/bin/flutter test --no-pub
```

Los dos análisis terminaron sin issues y la suite pasó con **267 pruebas y 6
optativas omitidas**. La composición registra cero providers externos. Esta
verificación no hizo requests a hosts ni acredita playback externo; la
integración queda pausada hasta el siguiente prompt. Ver el
[informe de limpieza](docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md).
