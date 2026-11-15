# Integración local del catálogo — 2026-11-09

Fuente: solicitud autorizada “KONGROO — Siguiente subfase: auditoría e integración local del catálogo” y anexo A adjunto.
Fecha: 2026-11-09
Módulo: catálogo, identidad local, biblioteca, progreso y UI Fedora/Linux
Estado: recorrido demo local implementado y validado; providers reales pendientes
Decisión: conservar capas F1.3; ADR-A14 permanece propuesta; status/demo episode no aprobados como reglas de producto
Evidencia: pruebas Flutter/SQLite, análisis, checker y build detallados abajo

## Alcance y límites

Se integró la infraestructura ya existente sin recrear biblioteca/progreso ni acoplar dominio a Flutter, AniList, Drift o reproductor. `FakeMetadataProvider` usa tres records sintéticos; no hubo solicitudes HTTP en la UI. El alta explícita usa identidad UUIDv4 local/crosswalk exacto, el repositorio Drift de biblioteca y el progreso F1.10. El episodio `episode:1`, el campo `positionMs` introducido por segundos y los estados `planned/watching/completed` con default `planned` son valores de demostración. No representan una regla de producto aprobada. No se implementó OAuth, AniList/TMDB/Kitsu, Supabase, player, sync, ni código Android/TV/Windows.

`VerifiedExternalAnimeReference` es una afirmación del caller y no prueba el origen de la evidencia; la documentación limita su creación a adaptadores confiables o confirmación del usuario. Las claves únicas/foráneas de SQLite evitan duplicar crosswalk/membership y referencias huérfanas. La migración v5→v6 añade status con default y check; JSON legado permanece intacto.

La app instalada usa su base app-owned en Application Support por defecto. Todos los tests usan archivos bajo `.ai-local/test-db`; el arranque real del binario se hizo con `KONGROO_DATABASE_PATH` dentro de `.ai-local/`. No se abrió ni modificó la DB personal del desarrollador. El `ANIMEAPP_FIRST_FRAME_MARKER` demuestra que se rasterizó una trama; no demuestra por sí mismo presentación por el compositor.

## Auditoría

- Revisión de arquitectura read-only: no duplicar tabla/repositorio, reutilizar `LocalLibraryRepository` y `PlaybackProgressRepository`, agregar status en una migración versionada, mantener status provisional. `VerifiedExternalAnimeReference` tiene límite de confianza explícito.
- Auditoría de código read-only: no halló defecto bloqueante de persistencia ni duplicación. Señaló como límite que el arranque normal persiste en Application Support; validación aislada usa override local y no toca DB personal. Este comportamiento del runtime instalado se mantiene para persistencia de usuario.
- Auditoría QA read-only: confirma que widget/SQLite son físicos, `HttpOverrides` rechaza HTTP, las altas duplicadas quedan en una fila y las migraciones usan snapshots reales. Hueco menor: el test UI de reopen no revisa los objetos del crosswalk directamente; la recuperación del título demuestra su uso, y el repositorio lo verifica de forma directa.
- ADR-A14 fue actualizado con el flujo actual y schema v6, sin marcarlo aceptado. Faltan decisión propietaria de estados/ADR y revisión de elegibilidad/retención antes de conectar cualquier provider.

## Evidencia de ejecución

Toolchain: Flutter `3.50.0-0.4.pre`, revision `368ac9e40b`; Dart `3.14.0-315.3.beta`. Se quitó `FLUTTER_ROOT` en comandos y se usaron el SDK aislado y `PUB_CACHE` bajo `.ai-local/`.

| Comprobación | Resultado | Código |
| --- | --- | ---: |
| Drift `build_runner build --delete-conflicting-outputs` | Build terminado; Drift indicó 0 outputs nuevos; tests/compilación validaron schema v6 | 0 |
| `dart format --output=none --set-exit-if-changed lib test` | 72 archivos, 0 cambios | 0 |
| `dart analyze lib test` | Sin issues | 0 |
| `flutter analyze --no-pub` | Sin issues | 0 |
| Tests focalizados `app_database_test`, `catalog_identity_repository_test`, `widget_test` | 9 pasaron | 0 |
| Suite completa `flutter test --no-pub` | 62 pasaron | 0 |
| Migraciones SQLite reales | v1→v6, v2→v6, v3→v6, v4→v6, v5→v6; conservación de datos | 0 (tests focales) |
| `dart scripts/check_imports.dart --root .` | 22 archivos domain válidos | 0 |
| `bash scripts/test_check_imports.sh` | positivo y diez negativos esperados | 0 |
| `flutter build linux --debug --no-pub` | Bundle Linux debug construido | 0 |
| Arranque real de bundle Fedora | Ejecutado 12 s, marker presente; timeout controlado exit 124 | 124 esperado |
| SQLite del arranque | schema 6; `integrity_check=ok`; 0 filas de biblioteca y progreso; tablas locales esperadas presentes | 0 |
| `bash scripts/ci.sh` | Completa: 40 pruebas IA, fixtures/checker, formato, Dart/Flutter analyze, pub get, 62 pruebas Flutter y límites de imports | 0 |

El primer intento de ejecución real se rechazó correctamente porque el path de prueba contenía `..`; salió sin crear DB/marker. El segundo usó path absoluto aceptado, abrió SQLite v6, produjo marker y luego fue detenido por timeout. En el arranque se observaron advertencias GTK/ATK del entorno; no impidieron el primer frame ni apertura SQLite. La suite de widget además reemplaza `HttpOverrides` por un handler que lanza si se crea cualquier `HttpClient`.

El archivo DB y marker de la prueba real se eliminaron después de verificar schema/integridad; no se limpiaron otros archivos de `.ai-local/`.

## Archivos y documentación

- Código: `app/lib/application/catalog/`, `app/lib/data/metadata/`, `app/lib/app/catalog/`; composición en `app/lib/main.dart`/`app/lib/app/anime_app.dart`.
- Persistencia: `app/lib/data/local_db/app_database.dart`, generado Drift y `library_entries.dart`; repositorios de identidad/biblioteca; snapshot v5.
- Tests: widget integration, repositorio de identidad y migración v5→v6; se actualizaron dos expectativas de schema obsoletas en tests de progreso de v5 a v6.
- Documentación: `ROADMAP.md`, `PROGRESS.md`, `TESTING.md`, `CHANGELOG.md`, `TECH_DECISIONS.md`, `README.md`, READMEs de dominio/aplicación/datos/progreso/UI; `docs/architecture/catalog-system.md`, `catalog-failure-scenarios.md`, `catalog-system-audit.md`, `docs/development/catalog-testing.md`, ADR-A14, `PROJECT_STATE.md`, `AI_HANDOFF.md`, `MODULE_INDEX.md`, `DECISIONS.md` y este episodio.
- Se preservaron cambios concurrentes ajenos y la diferencia previa en `AGENTS.md`, `.codex/agents/` y `docs/ai-system/`. No se hizo commit ni push por instrucción explícita.

## Reproducción

Desde la raíz del proyecto, seleccionar el SDK local:

```bash
unset FLUTTER_ROOT
export PATH="$PWD/.ai-local/toolchains/flutter/bin:$PATH"
export PUB_CACHE="$PWD/.ai-local/pub-cache"
cd app
flutter test --no-pub test/data/local_db/app_database_test.dart test/data/local_db/catalog_identity_repository_test.dart test/widget_test.dart
flutter test --no-pub
flutter build linux --debug --no-pub
cd ..
bash scripts/ci.sh
```

Para ejecutar el bundle en una DB temporal, se usa una ruta absoluta sin `..` dentro de `.ai-local/`; no omitir el override durante validación aislada. La próxima revisión propietaria debe aceptar/ajustar ADR-A14 y los estados antes de ampliar reglas de biblioteca; providers reales permanecen deshabilitados hasta resolver su elegibilidad y retención.
