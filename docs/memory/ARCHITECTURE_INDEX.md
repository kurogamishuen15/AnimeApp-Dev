# Índice arquitectónico

## Variantes MegaPlay y VTT publicados · 2026-11-17

`ProviderSubtitle` se propaga source→resolver→medio autorizado→motor existente.
Sub/dub usan el mismo adapter y transporte; IDs de captions por revisión y
catálogos contradictorios rechazados. [Auditoría y evidencia](../ai-system/audits/OC04-LANGUAGES-audit-2026-11-17.md).
Audio español pendiente por 403 de AnimeAV1; Spanish VTT visible verificado.


## Reproducción real de anime · MegaPlay/bee · 2026-11-17

Tokyo Ghoul:re 9 (AniList 100240) funciona en Kongroo mediante el backend
directo de bee publicado por Anilili como MegaPlay. Se verificó desde main():
búsqueda, ficha, episodios Kitsu, selector, video visible 1920×1080, reanudación,
seek en pausa, progreso SQLite y retorno a la ficha. El último recorrido guardó
143351 ms de 1449629 ms. Las capturas muestran fotogramas diferentes.
El registro conserva Miruro y añade MegaPlay con el resolver directo existente.
Miruro mantiene su 403. Se corrigió un uso de VideoOutput liberado en el
callback GTK mediante una copia generada de la traducción del plugin Linux.
Fedora aporta noopenh264, así que esta reproducción usa el códec Cisco
descargado separadamente dentro del proyecto y elegido por proceso.
Lanzamiento desde la raíz: `tools/player/run_kongroo_linux.sh --debug --openh264`.
Suite final 350 aprobadas y 8 omitidas, análisis limpio y build Linux debug
normal aprobado. No hay commits ni pushes. Otros hosts/plataformas pendientes.
[Auditoría y evidencia](../ai-system/audits/OC04-MEGAPLAY-PLAYBACK-audit-2026-11-17.md)
y [licencias/control del códec](../third-party/PLAYBACK-DEPENDENCIES.md).

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
La ficha de catálogo reutiliza `CatalogService` y se monta dentro del área de contenido del shell existente; la cabecera/tab strip se documentan en [`app/catalog/detail`](../../app/lib/app/catalog/detail/README.md). Metadata visible llega por `ProviderAnimeMetadata`; AniList DTO/GraphQL no cruza a presentación. La ruta de playback conserva el manager y player existentes. El runtime de providers registra Miruro catalog y `DirectMediaHostResolver`; Wikimedia y `user_sources` son opt-in. GETs públicos Miruro para AniList 100240 devolvieron 403 antes de episodios o media, sin playback externo de anime confirmado. La caché de fuentes y el mapa de circuitos de host están acotados a 128 entradas cada uno. Ver el [README de providers](../../app/lib/data/player/providers/README.md), la [auditoría OC-03](../ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md) y los reportes S0 históricos. Reparto, galería de terceros y relaciones conservan sus estados según metadatos disponibles.

La arquitectura F1.3 aprobada (núcleo Dart compartido, Fedora/Linux primero, adaptadores progresivos) está documentada en [ARCHITECTURE.md](../../ARCHITECTURE.md) y [ADR-015](../adr/ADR-015-arquitectura-core-linux-first.md). El catálogo local offline está implementado en `app/lib/domain/catalog`, `app/lib/application/catalog`, `app/lib/data/metadata`, `app/lib/data/local_db` y `app/lib/app/catalog`; su recorrido local de pruebas usa un fake sintético. El dominio sigue siendo Dart puro. F2.2 añadió un spike en `app/lib/{application,data,app}/player`; la ficha conserva ese único player. OC-03 integra el adaptador Miruro en el registro existente, sin playback externo confirmado. La superficie omite controles adaptativos, la UI coalescea seek y Stop espera el activo, y el runner GTK tiene un watchdog de retry que no cancela cleanup. El propietario aceptó F2.2 el 2026-11-10 tras validar manualmente video/audio, controles, ciclos Stop→Play y cierre GTK; CI (99 tests) y build release pasan. Se conserva el parche local UTF-8 del SDK Flutter. Limitación: no hay test automatizado end-to-end del lifecycle nativo del VideoController. F2.3 añade atajos scoped para Play/Pause, seek y volumen, además de solicitudes fullscreen GTK con estado confirmado por evento nativo. Su CI (40 pruebas IA + 116 Flutter), análisis y build release pasan; F23-A1 fue corregido y reevaluado independientemente. La revisión visual de fullscreen/compositor y foco Fedora sigue pendiente; F2.3 está abierta/no aceptada. Ver el [informe F2.2](../player/F2.2-spike-report-v2.md), las [auditorías F2.2](../ai-system/audits/F2.2-audit-2026-11-10.md) y [F2.3](../ai-system/audits/F2.3-audit-2026-11-10.md), y [PROGRESS.md](../../PROGRESS.md). Límites y checker están en [`app/README.md`](../../app/README.md) y [`scripts/README.md`](../../scripts/README.md). Android, Android TV y Windows son destinos sin build validado. La auditoría del entorno está en [F0.1 Fedora](../environment/F0.1-FEDORA.md).

OC-04 añade únicamente un punto de presentación para copiar páginas externas HTTPS declaradas por AniList y una regresión de continuidad del manager tras 403. Conserva el límite provider → source → manager → player; URL externa no equivale a medio ni llega al engine. Miruro sigue bloqueado antes de episodios y no existe playback externo de anime confirmado. Ver [auditoría OC-04](../ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md).

Requisitos y trazabilidad del MVP/núcleo, aprobados formalmente el 2026-11-08: [F1.1](../requirements/F1.1-CORE-REQUIREMENTS.md). Las 14 selecciones de referencia aprobadas y sus validaciones pendientes, además de ADR adicionales preservados: [ADR de F1.2](../adr/README.md). La aprobación documental no implica implementación.

## Infraestructura de IA
La arquitectura confirmada aquí es Markdown → índice SQLite derivado → fragmentos acotados y herramientas Python sin dependencias externas. No inferir módulos de producto ni tratar planificación como implementación.
