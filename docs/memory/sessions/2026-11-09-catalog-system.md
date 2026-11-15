# Catálogo independiente, identidad y biblioteca local — 2026-11-09

Fuente: ejecución autorizada de la misión de catálogo adjunta
Fecha: 2026-11-09
Módulo: dominio de catálogo, identidad local y persistencia Drift
Estado: implementado parcialmente; fuentes externas inactivas
Decisión: ADR-A14 propuesta, aceptación formal pendiente
Evidencia: pruebas Flutter, SQLite físico, CI y build Linux documentados abajo

## Alcance

Se leyó el archivo adjunto autorizado como instrucciones de misión; no se modificó ni copió. El trabajo quedó dentro del repositorio. Se preservaron cambios locales ajenos en `AGENTS.md`, `.codex/agents/`, `docs/ai-system/` y memoria previa. No se hizo commit, push, request pública a proveedores, ni se usaron credenciales.

La misión pidió un diseño provider-neutral, identidad anime local, catálogo/biblioteca local-first, manejo de fallos, plan de pruebas y revisión de condiciones de AniList, TMDB y Kitsu Anime. La propuesta de arquitectura se registra como ADR-A14 y requiere aceptación formal. El nombre/carpeta/paquete del producto no se renombró: continúan AnimeApp/`anime_app`.

## Implementación

- Dominio Dart puro en `app/lib/domain/catalog/`: `AnimeId`, IDs externos namespaced, evidencia y relaciones, procedencia, modelos de anime/episodio, resultados de provider, registry, puertos de identidad/biblioteca y resolución conservadora exacta.
- Registry inhabilitado por defecto; configura providers explícitamente y captura las capacidades declaradas como sets inmutables al registrarlos.
- `AnimeIdentityResolver` devuelve resuelto/no resuelto/ambiguo; no combina por similitud de título. `VerifiedExternalAnimeReference` es una afirmación del código llamador, no una prueba criptográfica. Solo adapters confiables o confirmaciones explícitas deben crearla.
- Persistencia Drift v5 agrega identidad interna UUIDv4, crosswalk `(provider_id, external_id)`, relaciones explícitas y membership de biblioteca. Quitar membership no elimina identidad ni progreso.
- Migración preserva las tablas previas, incluidos progreso tipado y el documento opaco heredado; no interpreta ni borra el JSON antiguo.
- AniList legado no se adaptó ni conectó al nuevo registry. No se implementaron adapters TMDB/Kitsu, aggregator, cache multiproveedor, OAuth/sync de cuenta, UI o código de plataformas futuras.

## Fuentes y decisiones pendientes

Las fuentes oficiales revisadas se enlazan en `docs/architecture/metadata-providers.md`. Los términos de AniList crean una incertidumbre de elegibilidad para una aplicación con biblioteca/seguimiento propios; no se hizo una interpretación legal ni una request. TMDB necesita credenciales/aceptación de términos y atribución; no hay decisión de licencia/comercialidad. La documentación Kitsu Anime consultada no confirmó condiciones vigentes completas de cuota y retención. `media-index` se consultó solo como referencia de README; no se importaron código, datos, CDN ni scraping. Ningún provider fue habilitado.

Pendiente del propietario: elegibilidad/permiso de proveedores; cuotas, atribución, retención y uso offline; aceptación formal de ADR-A14; estados de biblioteca antes de añadir reglas/UI. F1.9 OAuth/keyring y F1.11 sync siguen en su alcance independiente y no fueron implementados aquí.

## Validación ejecutada

Herramienta: SDK aislado dentro de `.ai-local/toolchains/flutter`, Flutter `3.50.0-0.4.pre`, revisión `368ac9e40b`, Dart `3.14.0-315.3.beta`; caché Pub en `.ai-local/pub-cache`. Para que la configuración Flutter quedara asociada a este SDK se quitó `FLUTTER_ROOT` solo en la ejecución y se regeneró `app/.dart_tool/package_config.json` offline. El lockfile se restauró después de que un build ajustara dependencias transitorias; el archivo final no cambió.

| Comprobación | Resultado | Código |
| --- | --- | ---: |
| `dart format --output=none --set-exit-if-changed lib test` | 65 archivos al inicio y 66 durante CI; 0 cambios requeridos | 0 |
| `dart analyze lib test` | Sin issues con SDK beta aislado | 0 |
| `flutter analyze --no-pub` | Sin issues con SDK beta aislado | 0 |
| Focales de catálogo + DB (`catalog_contracts_test.dart`, `catalog_identity_repository_test.dart`, `app_database_test.dart`) | 16 pruebas pasaron | 0 |
| `flutter test --no-pub` | 61 pruebas pasaron | 0 |
| Migraciones SQLite | v1→v5, v3→v5 y v4→v5; conservación de cache/progreso, reopen e integridad comprobadas | 0 |
| `dart scripts/check_imports.dart --root .` | 22 archivos domain permitidos | 0 |
| `bash scripts/test_check_imports.sh` | Positivo real y 10 negativos sintéticos esperados pasan | 0 |
| `bash scripts/ci.sh` | 40 pruebas de infraestructura, formato, análisis, 61 Flutter y límites de imports; completa | 0 |
| `flutter build linux --debug --no-pub` | Bundle Linux debug generado | 0 |
| Revisión independiente de código | Sin defectos bloqueantes; dos límites de contrato documentados y uno endurecido con snapshot de capacidades | — |
| `git diff --check` | Sin errores de whitespace en la revisión final | 0 |

El build inicial actualizó `app/pubspec.lock` con una diferencia transitiva (retiró `listen` y cambió `test_api`); al confirmarse que el archivo estaba limpio antes, se restauró únicamente esa modificación accidental. No se alteró `pubspec.yaml` ni se añadió dependencia.

## Cambios de documentación

Se crearon `docs/architecture/catalog-system-audit.md`, `catalog-system.md`, `metadata-providers.md`, `anime-identity.md`, `optional-auth.md`, `catalog-failure-scenarios.md`, `docs/development/catalog-testing.md` y `docs/adr/additional/ADR-A14-catalog-providers-identity.md`. Se actualizaron `README.md`, `TECH_DECISIONS.md`, `ROADMAP.md`, `PROGRESS.md`, `CHANGELOG.md`, `TESTING.md`, los READMEs de catálogo, persistencia, progreso y AniList, índices de memoria, decisiones, `PROJECT_STATE.md` y este `AI_HANDOFF.md`.

## Reproducción

Desde la raíz del proyecto:

```bash
unset FLUTTER_ROOT
export PATH="$PWD/.ai-local/toolchains/flutter/bin:$PATH"
export PUB_CACHE="$PWD/.ai-local/pub-cache"
cd app
flutter pub get --offline
flutter test --no-pub test/domain/catalog/catalog_contracts_test.dart test/data/local_db/catalog_identity_repository_test.dart test/data/local_db/app_database_test.dart
dart analyze lib test
flutter analyze --no-pub
flutter test --no-pub
cd ..
bash scripts/ci.sh
```

Los resultados verifican contratos locales, migraciones y build, no una fuente de metadatos externa ni el producto conectado a UI.
