# Índice de módulos responsables

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001
Evidencia: Rutas de herramientas y sus tests

| Función | Responsable | Validación |
| --- | --- | --- |
| Inicio y composición Flutter Linux | app/lib/main.dart, app/lib/app/anime_app.dart; [README](../../app/lib/app/README.md) | tests Flutter; `dart analyze lib test` |
| Pantalla Inicio de Kongroo | app/lib/app/home (banner, score badge, tarjetas/menús, iconos, tipografía); [README](../../app/lib/app/home/README.md) | browse AniList, empty shelves, hover/clic derecho, menú móvil/TV/foco, widgets y revisión Fedora |
| Resultados, errores tipados y logging sanitizado | app/lib/core; [README](../../app/lib/core/README.md) | tests/core y `dart analyze lib/core test/core` |
| Persistencia local SQLite/Drift | app/lib/data/local_db; [README](../../app/lib/data/local_db/README.md) | archivo real, migración v1→v2, reapertura y rollback |
| Definición, catálogo y store local de ajustes | app/lib/settings; [README](../../app/lib/settings/README.md) | defaults, codec/validación, get/set/watch y reinicio |
| Contratos de catálogo, proveedor, identidad y biblioteca | app/lib/domain/catalog; [README](../../app/lib/domain/catalog/README.md) | contract tests e import checker; modelos Dart puros |
| Caso de uso de catálogo local | app/lib/application/catalog; [README](../../app/lib/application/catalog/README.md) | search/details, alta idempotente, estado provisional, progreso existente |
| Provider de metadata sintética | app/lib/data/metadata; [README](../../app/lib/data/metadata/README.md) | fake determinista, sin red; widget test bloquea HTTP |
| Composición y UI del catálogo/ficha | app/lib/app/catalog; [README](../../app/lib/app/catalog/README.md), [ficha](../../app/lib/app/catalog/detail/README.md), [referencias visuales](../ui/ANIME_DETAIL.md) | shell persistente, cabecera AMOLED con variantes amplia/móvil, tabs y cuadrícula lazy de episodios públicos; validación visual final requiere volver a disponer de los PNG aprobados |
| Player opt-in F2.2–F2.8 | `app/lib/domain/player`, `app/lib/application/player`, `app/lib/data/player/engine`, `app/lib/data/opensubtitles`, `app/lib/app/player`, `app/linux/runner`; READMEs por capa y auditorías F2.5–F2.8 | F2.2 aceptada por propietario. F2.3–F2.6 implementadas con aceptación pendiente; SRT visible en Wayland, ASS no inspeccionado visualmente. F2.7 conserva riesgo de `Player.stream.error` sin identidad de fuente. F2.8 integra HTTP fake/UI/service con carga de pista descargada en libmpv real; 24 tests focalizados, CI exit 0 (40 Python + 175 Flutter), análisis y build del spike pasan, auditoría presente; sin credenciales para API live. La ficha conecta AnimeAV1/TioAnime con el mismo player; aún no hay reproducción externa aprobada. Lifecycle nativo completo de `VideoController` aún no automatizado. Ninguna fase F2.3–F2.8 aceptada automáticamente; el progreso sigue sin conectar al player. |
| Providers de playback | `app/lib/domain/player/providers`, `app/lib/application/player/providers`, `app/lib/application/player/source_switching`, `app/lib/data/player/providers`; [guía](../../app/lib/data/player/providers/README.md), [auditoría de implementación](../ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md) | AnimeAV1/TioAnime adaptadores reales y UI conectada al player existente; en Fedora no se logró reproducir un episodio. Ninja/JKAnime 403; AnimeJara sin ruta confirmada. |
| Identidad/crosswalk y membership SQLite | app/lib/data/local_db/drift_anime_identity_repository.dart, drift_local_library_repository.dart; [README](../../app/lib/data/local_db/README.md) | SQLite real, reopen, conflicto, v1/v3/v4/v5→v6, FK/integridad |
| AniList GraphQL y cache acotada | app/lib/data/anilist; [README](../../app/lib/data/anilist/README.md) | browse/detalle público sin OAuth, episodios no reproducibles, caché Drift v8, transporte loopback, errores y rate limiter |
| Progreso tipado F1.10 | app/lib/domain/progress/{content_identity,playback_progress,playback_progress_repository,checkpoint_coordinator}.dart y app/lib/data/local_db/drift_playback_progress_repository.dart; [README](../../app/lib/domain/progress/README.md) | SQLite: guardar/reabrir, upsert por ProgressKey, validación y checkpoints; límites temporales/cross-device pendientes |
| Progreso opaco legacy | app/lib/domain/progress/{progress_document,progress_repository}.dart y app/lib/data/local_db/local_progress_repository.dart; mismo [README](../../app/lib/domain/progress/README.md) | Preserva payloads JSON antiguos; no convertir/migrar sin decisión de compatibilidad |
| Puerto y adaptador de credenciales seguras | app/lib/domain/auth y app/lib/data/secure_storage; [README](../../app/lib/data/secure_storage/README.md) | CRUD fake-backed, análisis y build Linux; runtime del keyring/OAuth pendientes |
| Identidad independiente del toolkit | app/lib/domain/app_identity.dart; [README](../../app/lib/domain/README.md) | test widget y checker recursivo de imports |
| Contrato remoto de sincronización | app/lib/domain/synchronization y app/lib/data/testing/fake_sync_remote.dart; [README](../../app/lib/domain/synchronization/README.md) | fake configurable, deep snapshot y errores; protocolo pendiente |
| Integración de contratos del núcleo | app/test/core/core_integration_test.dart; [sesión](sessions/2026-11-09-f1-12-core-tests.md) | fallo remoto fake preserva progreso SQLite local; ejecución dentro de `scripts/ci.sh` |
| Runner nativo Linux | app/linux | `flutter build linux --release` |
| CI local y límites de imports | scripts/ci.sh, scripts/check_imports.dart | prueba sintética y ejecución CI |
| Medición de rendimiento Linux | scripts/measure.sh | TSV en docs/perf; evidencia de PID y salida completa |
| Entorno base Fedora | docs/environment/F0.1-FEDORA.md | Flutter doctor y pkg-config |
| Recuperar conocimiento y búsquedas | tools/ai/memory.py | tests/ai/test_memory.py |
| Comprobar metadata y conflictos | tools/ai/memory.py check | fixtures con Claim y estado obsoleto |
| Preparar contexto para otra IA | tools/ai/memory.py handoff | prueba de estado y siguiente tarea |
| Ejecutar misión aislada y registrar métricas | tools/ai/autonomy.py | tests/ai/test_autonomy.py |
| Evaluar recuperación y regresiones | tools/ai/evaluate.py | EVALUATION.md y reporte JSON |
| Políticas de coordinación | AGENTS.md y .codex/agents | AGENT_REGISTRY.md |
| Requisitos, aceptación y trazabilidad del núcleo | docs/requirements/F1.1-CORE-REQUIREMENTS.md | Verificar por subfase al implementar |
| Decisiones tecnológicas originales y complementarias | docs/adr/ADR-001–ADR-014.md; docs/adr/additional/ | Correspondencia exacta del plan maestro y estado formal individual |
| Arquitectura compartida Linux-first de F1.3 | ARCHITECTURE.md; docs/adr/ADR-015-arquitectura-core-linux-first.md | F1.4 conserva el scaffold mínimo y verifica límites por imports |
| Checker global de límites de dominio | scripts/check_imports.dart; scripts/test_check_imports.sh | Un import permitido + diez violaciones negativas; protege todos los directorios domain bajo app/lib |

El catálogo local usa contratos domain, `CatalogService`, AniList público en el flujo normal, la fake solo opt-in para tests/demo y persistencia Drift de biblioteca/progreso. Home consume esos contratos y no contiene datos personales sintéticos. La ficha conecta la resolución de proveedores con `ProviderPlaybackRoute` y el `SpikePlayerModule` existente; el player no está conectado a Drift/progreso y aún no hay episodio externo reproducible acreditado. F2.2 fue aceptada por el propietario; F2.3–F2.8 siguen pendientes de aceptación. OpenSubtitles F2.8 entrega solo archivos locales al coordinator y no almacena la API key. Se mantiene una única superficie sin overlay adaptativo. Ver los README por capa y las auditorías [F2.5](../ai-system/audits/F2.5-audit-2026-11-10.md), [F2.6](../ai-system/audits/F2.6-audit-2026-11-10.md) y [F2.8](../ai-system/audits/F2.8-audit-2026-11-11.md).

### Guías de submódulos — 2026-11-12

READMEs de capas del player: [`app`](../../app/lib/app/player/README.md), [`application`](../../app/lib/application/player/README.md), [`domain`](../../app/lib/domain/player/README.md) y [`data/engine`](../../app/lib/data/player/engine/README.md). Guías específicas: [cambio de fuente](../../app/lib/application/player/source_switching/README.md), [proveedores](../../app/lib/application/player/providers/README.md), [subtítulos externos](../../app/lib/application/player/external_subtitles/README.md), [skip](../../app/lib/application/player/skips/README.md), [diagnóstico](../../app/lib/application/player/diagnostics/README.md), [políticas de subtítulos](../../app/lib/domain/player/subtitles/README.md) y [segmentos de skip](../../app/lib/domain/player/skips/README.md). La pantalla y coordinator son archivos grandes que se mantienen sin refactor en esta tarea; no se hizo análisis automático nuevo de duplicación global.

Índice de capas de código fuente: [`app/lib/README.md`](../../app/lib/README.md).
