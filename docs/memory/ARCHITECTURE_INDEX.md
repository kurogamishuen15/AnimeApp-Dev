# Índice arquitectónico

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001
Evidencia: tools/ai/memory.py y pruebas de recuperación

## Fuentes canónicas
- [Arquitectura de memoria](../ai-system/MEMORY_ARCHITECTURE.md).
- [Decisiones](DECISIONS.md).
- [Módulos](MODULE_INDEX.md).
- [Permisos y autonomía](../ai-system/AUTONOMY_POLICY.md).

## AnimeApp
La ficha de catálogo reutiliza `CatalogService` y se monta dentro del área de contenido del shell existente; la cabecera/tab strip se documentan en [`app/catalog/detail`](../../app/lib/app/catalog/detail/README.md). Metadata visible llega por `ProviderAnimeMetadata`; AniList DTO/GraphQL no cruza a presentación. La ruta de playback conserva manager y player existentes. El composition root registra AnimeHeaven y su resolver MP4; `cx`, `ct` y `ck` llegaron al player, pero ninguno mostró imagen, por lo que no cuentan como reproducción confirmada. Ver el [README de providers](../../app/lib/data/player/providers/README.md) y el [reporte S0](../ai-system/missions/S0-REAL-PLAYBACK-REPORT.md). Reparto, galería de terceros y relaciones conservan sus estados según metadatos disponibles.

La arquitectura F1.3 aprobada (núcleo Dart compartido, Fedora/Linux primero, adaptadores progresivos) está documentada en [ARCHITECTURE.md](../../ARCHITECTURE.md) y [ADR-015](../adr/ADR-015-arquitectura-core-linux-first.md). El catálogo local offline está implementado en `app/lib/domain/catalog`, `app/lib/application/catalog`, `app/lib/data/metadata`, `app/lib/data/local_db` y `app/lib/app/catalog`; su recorrido local de pruebas usa un fake sintético; la composición principal conecta además providers reales de reproducción. El dominio sigue siendo Dart puro. F2.2 añadió un spike en `app/lib/{application,data,app}/player`; la ficha reutiliza su player para providers reales, sin crear una segunda instancia de engine. La superficie omite controles adaptativos, la UI coalescea seek y Stop espera el activo, y el runner GTK tiene un watchdog de retry que no cancela cleanup. El propietario aceptó F2.2 el 2026-11-10 tras validar manualmente video/audio, controles, ciclos Stop→Play y cierre GTK; CI (99 tests) y build release pasan. Se conserva el parche local UTF-8 del SDK Flutter. Limitación: no hay test automatizado end-to-end del lifecycle nativo del VideoController. F2.3 añade atajos scoped para Play/Pause, seek y volumen, además de solicitudes fullscreen GTK con estado confirmado por evento nativo. Su CI (40 pruebas IA + 116 Flutter), análisis y build release pasan; F23-A1 fue corregido y reevaluado independientemente. La revisión visual de fullscreen/compositor y foco Fedora sigue pendiente; F2.3 está abierta/no aceptada. Ver el [informe F2.2](../player/F2.2-spike-report-v2.md), las [auditorías F2.2](../ai-system/audits/F2.2-audit-2026-11-10.md) y [F2.3](../ai-system/audits/F2.3-audit-2026-11-10.md), y [PROGRESS.md](../../PROGRESS.md). Límites y checker están en [`app/README.md`](../../app/README.md) y [`scripts/README.md`](../../scripts/README.md). Android, Android TV y Windows son destinos futuros sin código específico. La auditoría del entorno está en [F0.1 Fedora](../environment/F0.1-FEDORA.md).

Requisitos y trazabilidad del MVP/núcleo, aprobados formalmente el 2026-11-08: [F1.1](../requirements/F1.1-CORE-REQUIREMENTS.md). Las 14 selecciones de referencia aprobadas y sus validaciones pendientes, además de ADR adicionales preservados: [ADR de F1.2](../adr/README.md). La aprobación documental no implica implementación.

## Infraestructura de IA
La arquitectura confirmada aquí es Markdown → índice SQLite derivado → fragmentos acotados y herramientas Python sin dependencias externas. No inferir módulos de producto ni tratar planificación como implementación.
