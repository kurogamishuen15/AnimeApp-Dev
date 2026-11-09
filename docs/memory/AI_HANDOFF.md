# Transferencia a otra IA

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Herramientas, docs y resultados reproducibles

## Contexto mínimo
Regla permanente: lee, busca e inspecciona solo esta raíz y sus subcarpetas. No explores Imágenes ni otras carpetas. No sigas enlaces fuera del proyecto. Si falta material fuera de aquí, documenta el bloqueo y pide que se coloque dentro del proyecto.

Trabajas solo en esta carpeta PROYECTO ANIME dentro de Vídeos. El alcance inicial de infraestructura IA no autoriza funciones del producto; la autorización posterior permitió únicamente documentación F1.1/F1.2. No implementar funcionalidades sin nueva instrucción. No acceder a otro repositorio ni configuraciones personales.

## Cómo continuar
Leer AGENTS.md, PROJECT_STATE.md y FINAL_REPORT.md; buscar memoria con tools/ai/memory.py. Python stdlib, FTS5, fuentes Markdown, caché local ignorada. Ver MODULE_INDEX.md y DECISIONS.md.

## Comandos y riesgos
python3 tools/ai/memory.py check
python3 -m unittest discover -s tests/ai -v
python3 tools/ai/autonomy.py doctor

Los tests no acreditan una ejecución de modelo nocturna. Revisar estado Git, imagen/broker y alcance antes de ejecutar. No publicar ni hacer push.

## Próxima tarea
F0.2 se completó: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, `main` activa y subida a `origin` privado; se conservó `ai/setup-autonomous-environment` en el commit inicial. `AnimeApp-Dev` es privado y el público `AnimeApp` continúa vacío. La clonación limpia, las 40 pruebas de IA y la verificación de memoria pasaron. Identidad de Git configurada solo localmente; no copiar sus datos a documentos. `.ai-local/` y `.codex/config.toml` están excluidos. Los informes `ENVIRONMENT_AUDIT.md` y `MCP_RESEARCH.md` son internos: el proceso público exige seleccionar archivos expresamente y excluye esos informes salvo aprobación de versiones revisadas y depuradas.

El plan original sitúa F0.1 antes de F0.2. F0.1/F0.3 están completas y F0.4–F0.6 siguen parciales. La autorización explícita del 2026-11-08 permitió completar documentalmente F1.1/F1.2 sin cerrar F0 ni implementar funcionalidades. media_kit está aprobado solo como motor de referencia para F2; no se instala ni implementa en F1. No instalar paquetes del sistema ni modificar configuraciones globales.

### F1.1/F1.2 — 2026-11-08

El propietario aprobó formalmente el 2026-11-08 F1.1 (18 FR + 13 NFR; FR-11 con semántica por campo pendiente y sin reglas inventadas; metas de rendimiento preliminares), las 14 selecciones ADR-001–ADR-014 como arquitectura de referencia y F1.3 (núcleo compartido, Fedora/Linux primero, adaptadores progresivos por necesidad). F1.1–F1.3 están completadas documentalmente; F1.4 está completada tras conservar el scaffold mínimo, documentar `app` y `domain`, y ampliar/probar el checker global de límites de dominio. F1.5–F1.7 implementadas en el alcance documentado; ver `PROGRESS.md`, READMEs y sesiones de fase. Las integraciones mantienen validaciones por fase; ADR-A01–A13 siguen como documentos complementarios, sin aprobación automática. El commit documental F1.3 es `e7bcde9`; commits de implementación F1.5–F1.7 se registran en progreso y Git. Cambios concurrentes ajenos en `AGENTS.md`, `.codex/agents/` y `docs/ai-system/` deben preservarse.

### Avance F0.1–F0.6 (2026-11-08)

F0.1/F0.3 completas; F0.4–F0.6 parciales. Entorno Fedora 44 con Flutter 3.47.9/Dart 3.13.7 y GTK3/libsecret/libmpv disponibles; ver `docs/environment/F0.1-FEDORA.md`. README y siete documentos Markdown requeridos están enlazados; D3/LICENSE pendiente, no bloquea F0.3. `flutter analyze` exit 255 en stable 3.47.9 reproduce fallo LSP; el código calcula Content-Length con caracteres y PR #191377 lo cambia a bytes UTF-8. Beta oficial 3.50.0-0.4.pre se instaló desde tag en `.ai-local/toolchains/flutter` y verificó con analyze/CI passing cuando se antepone explícitamente a PATH. No se adopta como permanente: stable aún falla. Modos strict de analysis_options quedaron bajo `analyzer.language`; la app usa `material_ui` oficial. Evidencia y comandos en `TESTING.md` y `sessions/2026-11-08-flutter-analyze-ci-repair.md`. Spectacle verificó visualmente la ventana Wayland: evidencia `docs/perf/wayland-window-20261108.png`; el TSV no tiene latencia numérica de ventana. Medición release: 462 ms al primer frame rasterizado, RSS mediano 140096 KiB/145284 KiB a 5 s, CPU reposo 0.60%; entorno 7.5 GiB, no objetivo 4 GB. Sin reproducción ni prueba prolongada de fugas. Cambios concurrentes en AGENTS.md, perfiles .codex y docs/ai-system permanecen ajenos; no mezclarlos ni revertirlos. No iniciar Fase 1.

### Reparación Flutter analyze/CI — 2026-11-08

Causa upstream reproducida y confirmada por lectura de código del SDK estable y código del PR #191377. Baseline stable: Dart analyze 0, Flutter analyze 255, widget test 0, checker y 40 pruebas IA pasan, CI 1 solo por Flutter analyze. El par de probes bajo `.ai-local/diagnostics` tiene ambos una raíz antecesora no ASCII (esta carpeta de trabajo está bajo `Vídeos`); por ello se registra la limitación y no se afirma un control ASCII real. Bajo Flutter 3.50.0-0.4.pre/Dart 3.14.0 ambos probes pasan. Se corrigió configuración de analyzer, se adoptó `material_ui` 1.10.0 por deprecación que resultaba en exit 1 bajo analyzer actualizado. Flutter analyze, widget test, Linux release build y CI completa pasan con SDK beta seleccionado; stable test y build pasan, pero stable analyze sigue 255. CI temporal de arquitectura con import Flutter en `domain` devolvió exit 1 esperado y el fixture se eliminó. No marcar F0.4/F0.5 como completas hasta stable corregida. Detalle: `TESTING.md`, `PROGRESS.md` y [`sesión de reparación`](sessions/2026-11-08-flutter-analyze-ci-repair.md).

### F1.7 — 2026-11-09

Implementados `core/errors`, `core/result` y `core/logger`, con README y pruebas unitarias. Revisión estática seguridad sin bloqueos críticos; logger no registra `toString()` de objetos desconocidos, omite path/query/fragment/userinfo de URI y no persiste logs. `flutter test test/core`, analyze y CI beta pasan. F1.7 completada. Siguiente: F1.6 SQLite/Drift real y migración v1→v2, después F1.5. Flutter stable 3.47.9 sigue con LSP 255; no afirmar CI stable verde. Cambios concurrentes de `.codex/agents`, `AGENTS.md`, `docs/ai-system` permanecen sin commit.

### F1.6 — 2026-11-09

Implementado `data/local_db` con Drift/SQLite schema v2, snapshot v1 y migración real v1→v2; las pruebas verifican conservación de filas, archivo persistente tras cierre/reapertura y rollback. Tres pruebas específicas, `dart analyze` y Flutter analyze pasan al seleccionar Flutter beta aislado. El hook intentó bajar el binario oficial y recibió HTTP 504; se descargó el asset de release oficial y se verificó SHA-256 contra el hash publicado. El binario está en `.ai-local`/`.dart_tool`, ambos locales e ignorados. No hay dependencia global ni SDK modificado. Rendimiento/Flatpak/licencia pendiente; sin reglas funcionales de progreso. Commits F1.6 `09b9f75` y refuerzo del cleanup `a0fbc6b`. Mantener intactos cambios concurrentes.

### F1.5 — 2026-11-09

Implementados `settings/registry` (definición tipada, default, propietario, codec JSON, validador, unicidad) y `settings/store` Drift local-first con `get/set/watch` y `Result`. Cinco pruebas reales pasan con Flutter beta. No se inventó catálogo: no hay preferencias concretas aprobadas. F1.5 está completa como infraestructura; decidir claves/defaults/alcance de sincronización sigue pendiente antes de introducir preferencias reales. Commit F1.5 `5a7bab2`; F1.6 `09b9f75` con follow-up `a0fbc6b`; F1.7 `7d550d1`.

### F1.8 — 2026-11-09

Cliente propio Dio GraphQL read-only, query de búsqueda mínima, parsing a dominio puro y errores tipados. Rate gate compartido entre instancias (default 30 req/min, luego `X-RateLimit-Limit`, Respeta Retry-After y no retry automático). Cache `latest_anime_search` reemplaza un solo resultado solicitado y hace fallback offline solo para query/page/tamaño idénticos, señalando fuente cache y refresh error. Drift v2→v3; 8 pruebas de cliente, 2 de cache, 4 de DB con fixtures loopback. Cero requests a AniList real. Las fuentes oficiales prohíben uso como backup/data storage y como servicio competidor no complementario; elegibilidad de AnimeApp no comprobada, adaptador sin conectar al startup/UI. Requiere revisión propietaria antes de producción. Commit F1.8: `669db74`. Próximo F1.9: ver sesión de secure storage; sin credenciales ni sesión real. Mantener trabajo concurrente ajeno fuera de commits.

### F1.9 — 2026-11-09

Puerto Dart puro `SecureCredentialStore` y adaptador `flutter_secure_storage 11.2.0` (Linux backend 3.0.3); CRUD, token vacío y error sanitizado pasan cuatro pruebas fake. Build Linux debug compila plugin. No se accedió al keyring. OAuth grant/callback/scope/expiración-refresh/revocación y runtime Secret Service pendientes; revisa sesión F1.9. No usar AniList en producto hasta revisión de elegibilidad.
