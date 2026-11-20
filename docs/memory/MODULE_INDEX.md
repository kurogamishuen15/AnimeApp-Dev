# Índice de módulos responsables

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

## Corrección del catálogo binario de Miruro · 2026-11-17

Se reprodujo y corrigió un P1 en `PublicPlaybackHttp.readBytes`: la
decodificación UTF-8 previa rechazaba el catálogo XOR+gzip. Miruro adjunta
ahora el Referer del origen en cada petición. La prueba del manager recorre
título, configuración y episodio con cuerpos binarios. Pasan 32 pruebas de
providers y el análisis queda limpio con Flutter 3.50.0-0.4.pre del proyecto.
La ejecución posterior del manager real para AniList 100240, episodio 9,
devuelve `forbidden stage=anime status=403` en Miruro. No hay reproducción
de ese episodio. Un auditor independiente verificó la corrección interna.
[Auditoría y evidencia](../ai-system/audits/OC04-BINARY-TRANSPORT-audit-2026-11-17.md).

## Estado vigente · alternativas ante HTTP 403 · OC-04 · 2026-11-17

La ficha muestra y permite copiar enlaces HTTPS externos publicados por AniList
cuando están presentes; no los convierte en fuentes para el reproductor. Un
provider configurado que devuelve 403 no impide consultar el siguiente, pero
la cobertura real depende de que haya otro provider habilitado. Ninguna fuente
para el flujo Miruro/AniList 100240 ha sido confirmada en libmpv. Wikimedia
conserva evidencia histórica opt-in de Namakura Gatana, separada de este flujo.
Ver [AniList](../../app/lib/data/anilist/README.md),
[detalle](../../app/lib/app/catalog/detail/README.md) y la
[auditoría](../ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md).

## Snapshot anterior · estado providers OC-03 · 2026-11-17

El runtime registra Miruro catalog + `DirectMediaHostResolver`, Wikimedia
opt-in y `user_sources` opcional. Los adapters/profiles experimentales
anteriores fueron retirados; el manager, source switch y media_kit/libmpv siguen
siendo los componentes únicos. GET ordinario de Miruro devolvió 403 antes de
episodios/media: no hay reproducción externa de anime confirmada. Ver
[`data/player/providers`](../../app/lib/data/player/providers/README.md),
[`miruro`](../../app/lib/data/player/providers/miruro/README.md) y la
[auditoría](../ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md).

## Snapshot pre-migración · Comparación de Anilili con Kongroo · 2026-11-17

El episodio de referencia fue Tokyo Ghoul:re 9 (AniList 100240), que el
usuario reprodujo en Anilili con `bee`. En el código de escritorio `bee`
es AniKoto a través de Miruro. Kongroo carece de ese registro activo y
los GET directos de configuración e identificación devolvieron HTTP 403
de Cloudflare en dos orígenes de Miruro, antes de obtener el episodio o el
medio. Anilili implementa emulación de Chrome en ese transporte. No se
confirmó qué condición originó la denegación ni que ese episodio se vea
en Kongroo.
[Comparación y pruebas](../ai-system/audits/OC03-ANILILI-BEE-audit-2026-11-17.md).

## Snapshot pre-migración · OC-03 · Limpieza de proveedores · 2026-11-17

Ambas herramientas de AnimesDigital usan el registro de producción y se
retiraron comprobaciones redundantes del adaptador. Los resolutores de
MP4Upload y YourUpload siguen compartiendo una implementación con perfiles
separados. Antes y después de la limpieza, la suite aprobó 348 pruebas y
omitió 10. El análisis quedó limpio. Está pendiente comparar un episodio y
servidor concretos de Anilili con Kongroo.
[Inventario, validación y auditoría](../ai-system/audits/OC03-CLEANUP-audit-2026-11-17.md).

## Snapshot pre-migración · OC-03.2 · Hosts de anime · 2026-11-17

AnimeAV1 y TioAnime alcanzan sus embeds. Los CDN devolvieron 403 para
MP4Upload y 500 para YourUpload (HEAD y Range). Se verificaron los errores
por etapa y se añadieron el HEAD MP4 por perfil, UA compartido por sonda y
medio, Retry-After por origen, aislamiento de cabeceras y preservación del
error al reabrir. Los dos hosts siguen experimentales y sin cuadros visibles.
Wikimedia conserva la validación anterior. HLS local pasó con segmento
relativo y distinguió el 403 de segmento pese a playlist 200.
[Checkpoint](../ai-system/missions/OC03-2-ANIME-TRANSPORT-2026-11-17.md)
y [auditoría](../ai-system/audits/OC03-2-ANIME-TRANSPORT-audit-2026-11-17.md).


## Snapshot histórico · OC-03.1 · Transporte remoto · 2026-11-16

Wikimedia 480p dio HTTP 429 a ffprobe con UA `libmpv` y abrió con el UA de
Kongroo en un A/B controlado. Fedora mostró cuadros remotos de *Namakura
Gatana* desde el módulo de producto en el lanzador de diagnóstico, con seek
confirmado a 20 s. Se verificó el UA en la red local, ausencia de fuga al
cambiar de medio y reutilización de los derivados. La API respeta
Retry-After y el producto registra perfiles de host en datos. MP4Upload
devolvió 403 a HEAD y YourUpload 500, ambos experimentales. La segunda
fuente externa y la prueba integrada de progreso remoto siguen abiertas.
[Checkpoint de transporte](../ai-system/missions/OC03-1-REMOTE-TRANSPORT-2026-11-16.md)
y [auditoría](../ai-system/audits/OC03-1-TRANSPORT-audit-2026-11-16.md).


## Snapshot histórico · OC-03.1 · 2026-11-16

Wikimedia Commons se registra para *Namakura Gatana* (AniList 6654). AnimeAV1
y TioAnime descubren medios mediante los resolutores compartidos de MP4Upload
y YourUpload con pruebas de red aprobadas. Ambos y AnimesDigital se habilitan
por separado. La reanudación requiere confirmación de libmpv y el progreso
se escribe por episodio para identidades locales. En Fedora se recorrió
ficha → episodio Kitsu → selector → player → alternativa → ficha. El video
remoto falló en el motor. Se comprobó HTTP 429 en ffprobe remoto y un cuadro
decodificado con FFmpeg desde la descarga íntegra de control. J5 permanece
parcial. [Checkpoint](../ai-system/missions/OC03-1-EXECUTION-STATUS.md) y
[auditoría](../ai-system/audits/OC03-1-audit-2026-11-16.md).


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
| Player opt-in F2.2–F2.8 | `app/lib/domain/player`, `app/lib/application/player`, `app/lib/data/player/engine`, `app/lib/data/opensubtitles`, `app/lib/app/player`, `app/linux/runner`; READMEs por capa y auditorías F2.5–F2.8 | F2.2 aceptada por propietario. F2.3–F2.6 implementadas con aceptación pendiente; SRT visible en Wayland, ASS no inspeccionado visualmente. F2.7 conserva riesgo de `Player.stream.error` sin identidad de fuente. F2.8 integra HTTP fake/UI/service con carga de pista descargada en libmpv real; 24 tests focalizados, CI exit 0 (40 Python + 175 Flutter), análisis y build del spike pasan, auditoría presente; sin credenciales para API live. **Estado vigente OC-03:** Miruro está integrado, pero sus GET live dieron 403; no hay reproducción externa de anime confirmada. AnimesDigital pertenece al snapshot S0-S anterior y su código fue retirado. El smoke HLS de prueba avanzó 2 s en libmpv, pero no mostró frame ni cuenta como episodio. Lifecycle nativo completo de `VideoController` aún no automatizado. Ninguna fase F2.3–F2.8 aceptada automáticamente; el progreso sigue sin conectar al player. |
| Providers de playback | `app/lib/domain/player/providers`, `app/lib/application/player/providers`, `app/lib/application/player/source_switching`, `app/lib/data/player/providers`; [guías Domain](../../app/lib/domain/player/providers/README.md), [manager](../../app/lib/application/player/providers/README.md), [data](../../app/lib/data/player/providers/README.md), [Miruro](../../app/lib/data/player/providers/miruro/README.md), [resolvers](../../app/lib/data/player/providers/hosts/README.md), [auditoría OC-03](../ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md) | El root registra `MiruroCatalogPlaybackProvider` y el normalizador genérico `DirectMediaHostResolver`; Wikimedia y `user_sources` son opt-in. Los adapters/profiles anteriores fueron retirados del runtime y sus READMEs/hallazgos quedan archivados. Manager único conserva source switch y media_kit/libmpv. GET público Miruro devolvió 403 antes de episodios/media; no se confirma reproducción externa de anime. Android/Windows y el equipo objetivo de 4 GB siguen pendientes. |
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
