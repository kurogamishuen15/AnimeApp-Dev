# Registro de cambios

Cambios notables por versión y subfase. Sigue Conventional Commits para el historial técnico. No se anuncian releases hasta que el propietario apruebe una versión.

## Sin publicar

### F1.10 — progreso tipado local

- Schema Drift v4 agrega `playback_progress_entries` con clave de contenido y
  episodio, conservando intactos los documentos JSON heredados.
- Añadidos IDs estables, progreso validado, CRUD local y coordinador de
  checkpoints con serialización de escrituras y reloj/writer inyectables.
- Pruebas SQLite físicas para migraciones, 45:00, reopen, integridad y carrera
  minuto 15→45; límites y evidencia en [`README de progreso`](app/lib/domain/progress/README.md).

### Auditoría de pruebas reales F1.5–F1.12

- Añadida integración de settings, SQLite persistente, HTTP loopback, cache,
  desconexión/reinicio y recuperación; verificación de integridad de SQLite.
- Corregidas emisiones redundantes de `SettingsStore.watch`, redirecciones
  reenviadas de AniList, mapeo de 401 y saneamiento de URL malformadas.
- Ampliadas pruebas para statuses HTTP/GraphQL, tasas con reloj simulado,
  cache corrupta y conexiones cerradas. La elegibilidad externa de AniList,
  keyring real/OAuth y los contratos funcionales de progreso/sync siguen
  pendientes o bloqueados.
- Informe detallado y limitaciones: [validación F1.5–F1.12](docs/validation/2026-11-09-f1-5-f1-12-real-tests.md).

### F1.7 — Core result, errores y logging

- Añadidos tipos de error de aplicación y `Result<T>` con transformaciones tipadas.
- Añadido logger estructurado con sinks inyectables, timestamps UTC, correlation id y sanitización de estructuras, credenciales y URI. No persiste mensajes.
- Pruebas unitarias y revisión estática de seguridad documentadas en [README core](app/lib/core/README.md) y [sesión F1.7](docs/memory/sessions/2026-11-09-f1-7-core-result-logger.md).

### F1.6 — Persistencia local Drift

- Añadido `AppDatabase` con Drift/SQLite, schema version 2, archivo en application support y migración v1→v2 no destructiva. El snapshot histórico y la implementación opaca de progreso no fijan reglas funcionales pendientes.
- Tres pruebas verifican archivo real, conservación al migrar, cierre/reapertura y rollback. Paquete y código generado documentados en [README local_db](app/lib/data/local_db/README.md).
- La versión de SQLite fue verificada por hash contra el paquete oficial y quedó en caché ignorada. Las pruebas pasaron con Flutter 3.50.0-0.4.pre/Dart 3.14.0; Flutter stable conserva la incidencia LSP registrada en TESTING.md.

### F1.5 — Registro y store tipado de ajustes

- Añadidos contratos de definición/registro con valor por defecto, propietario, codec JSON y validador; store SQLite local-first con `get`, `set` y `watch` reactivo. Resultados y errores usan los tipos de F1.7.
- Cinco pruebas reales cubren defaults, validación, tipo corrupto, registro único, actualización reactiva, errores del stream y persistencia al reabrir. No se inventaron claves/defaults de producto ausentes en los documentos aprobados; el registro productivo continúa vacío. Ver [README settings](app/lib/settings/README.md).

### F1.12 — Pruebas del núcleo

- Añadida prueba de integración local-first; CI beta aislada valida fakes, SQLite temporal, loopback, análisis y límites de imports. No requiere servicios externos.

### F1.11 — Contrato de sincronización

- Añadido puerto `SyncRemote` y `FakeSyncRemote` de pruebas con respuesta inyectable. No fija conflicto/idempotencia ni conecta backend.

### F1.10 — Persistencia local de progreso

- Añadido repositorio Drift de documentos opacos por identidad exacta, con timestamps técnicos UTC y tests SQLite de reapertura y reemplazo. No se eligieron campos de producto ni semántica temporal de progreso.

### F1.8 — AniList GraphQL de lectura

- Añadido cliente propio Dio sin codegen ni mutaciones, mapeo GraphQL a dominio, errores tipados, rate gate compartido y cache local replace-on-write limitada a una búsqueda solicitada. Drift migra v2→v3 y conserva snapshots históricos.
- Ocho pruebas de cliente y dos de cache usan un servidor HTTP loopback; no se hicieron requests externos. La integración productiva queda desconectada hasta revisar elegibilidad de AnimeApp frente a los términos actuales de AniList. Detalle en [README AniList](app/lib/data/anilist/README.md).


### Reparación de análisis y CI (F0.4–F0.5)

- Causa LSP confirmada en Flutter 3.47.9: longitud de contenido en caracteres en vez de bytes UTF-8. El arreglo upstream está en PR #191377; la stable publicada sigue sin incluirlo.
- Validación aislada con Flutter 3.50.0-0.4.pre/Dart 3.14.0: probes Unicode, Flutter analyze, widget tests, build Linux release y CI pasan con selección explícita de SDK. La CI continúa fallando con stable 3.47.9 por el error LSP; estado parcial hasta que exista stable corregida.
- Se ubicaron correctamente los modos strict en `analyzer.language` y se migró el scaffold a `material_ui` oficial para eliminar issues reales bajo el analyzer actualizado. `pubspec.lock` queda resuelto con stable.
- Detalle, limitaciones y reproducción: [TESTING.md](TESTING.md) y [sesión de memoria](docs/memory/sessions/2026-11-08-flutter-analyze-ci-repair.md).


### F0.1 Entorno Fedora

- Se verificaron Flutter/Dart, compiladores, GTK3, libsecret y libmpv sin instalar ni modificar configuración del sistema.
- `flutter doctor -v` confirma toolchain Linux; Android SDK queda ausente y fuera del destino F0.
- Evidencia y versiones: [auditoría F0.1](docs/environment/F0.1-FEDORA.md).

### F0.4 Esqueleto Flutter Linux

- Se creó una app mínima con Linux, identidad de dominio Dart puro, composición UI, lints y prueba widget.
- `pub get`, análisis Dart, widget test y `flutter run -d linux` pasaron; Spectacle verificó la ventana Wayland en [captura](docs/perf/wayland-window-20261108.png). `flutter analyze` queda bloqueado por error LSP.

### F0.5 Controles de calidad

- Se añadieron CI local y comprobador de imports Dart con pruebas sintéticas válidas y negativas.
- 40 pruebas IA, formato Dart, análisis Dart, checker de imports, resolución de dependencias y widget test pasaron. CI queda no verde porque `flutter analyze` terminó con error LSP; no se oculta el bloqueo.

### F0.6 Medición inicial

- Bundle Linux release compilado. Tres ejecuciones registraron 462 ms medianos al primer frame rasterizado, RSS de 140096 KiB tras el frame, 145284 KiB tras cinco segundos y CPU de reposo de 0.60% de un núcleo.
- La ventana se verificó visualmente con Spectacle, pero no hay latencia numérica (xdotool no observa Wayland). El entorno reporta 7.5 GiB RAM y no representa el objetivo de 4 GB. No se midió reproducción ni fugas prolongadas.
- Datos: [medición F0.6](docs/perf/measure-20261108T133341Z-15982.tsv); método: [docs/perf/README.md](docs/perf/README.md).

### F0.3 Documentación

- Se añadieron plan, arquitectura, hoja de ruta, progreso, decisiones técnicas y guía de pruebas como documentación de continuidad.
- Se completaron los ocho documentos Markdown requeridos. D3/Licencia queda pendiente y no bloquea F0.3; no se creó un archivo LICENSE sin decisión aprobada.

### F0.2 Repositorio

- Se preparó el repositorio privado de desarrollo, sus reglas Git y el proceso separado de publicación pública.
- Commit inicial: `84efbfb`; cierre documental: `b18a79c`.
