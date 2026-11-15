# Transferencia a otra IA

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-11
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Herramientas, docs y resultados reproducibles

### Handoff: fidelidad visual de la cabecera de ficha — 2026-11-15

El propietario ordenó comparar todas las capturas aprobadas y corregir solo la
cabecera antes de detenerse. Las once rutas originales se registraron en
[`docs/ui/ANIME_DETAIL.md`](../ui/ANIME_DETAIL.md), pero los PNG temporales ya
no estaban disponibles. La cabecera ahora diferencia composición amplia y
móvil, integra carátula, metadata, acciones y sinopsis sobre el banner y funde
hacia AMOLED sin panel intermedio. No se tocaron navegación, tabs, secciones,
datos, biblioteca ni player.

El analyze del archivo pasa; los dos widget tests focalizados pasan y fijan las
geometrías 400/188×300 en escritorio y 350/96×154 en teléfono; build Linux
release correcto. La app real está abierta en Home con base aislada
`.ai-local/fase05/detail-fidelity-review.sqlite`. Captura disponible en
`.ai-local/fase05/detail-fidelity-header-review.png`, todavía del Home: Wayland
captura con Spectacle pero no tiene puntero/teclado para abrir la ficha. No
declarar fidelidad visual final ni continuar otras secciones hasta que el
propietario abra la ficha, vuelva a adjuntar referencias si exige comparación
píxel a píxel y apruebe manualmente la cabecera.

### Handoff: proveedores reales de reproducción — 2026-11-14

AnimeAV1/TioAnime están implementados y registrados. La ficha AniList crea un
`PlaybackEpisode` tipado y abre el player media_kit existente por el selector de
fuente; source switch conserva `PlaybackSourceSwitchService`. La prueba real de
TioAnime halló 5 servidores del episodio 1 pero ninguno reprodujo con libmpv.
AnimeAV1 llega al iframe y recibe 403. Ninja y JKAnime devolvieron 403; AnimeJara
no tiene ruta confirmada. Sin episodio playable, no marcar proveedor ni flujo
de producto como operativo. Límites y resultados en [auditoría de
implementación](../ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md)
y guías específicas bajo `app/lib/data/player/providers/`.

Toolchain del proyecto `.ai-local/toolchains/flutter-3.47.9`: `flutter analyze
--no-pub` limpio y 25 pruebas focalizadas de provider/domain/manager pasan. La
prueba opt-in real falla de forma intencional si ningún servidor abre/reproduce;
se mantiene como gate de regresión para futuras fuentes. No se cambió Flutter
global ni se deshabilitó el analizador. No se hizo prueba visual de la ficha.
Suite completa: 250 pass, 6 opt-in omitidas; build Linux release exitoso.
`scripts/ci.sh` ejecutó 40 pruebas IA, análisis Dart/Flutter y 250 Flutter, pero
terminó exit 1 por el checker de imports: `app/lib/app/player/spike_player_page.dart`
importa `dart:io` desde UI. Ese hallazgo es ajeno a esta integración y queda
pendiente de corregir por separado.

### Ficha: corrección de episodios — 2026-11-14

La ficha no mostraba capítulos porque 05.1 había dejado esa pestaña como estado
vacío y `AniListClient` no pedía `streamingEpisodes`. Ya se mapean título,
miniatura HTTPS y sitio como metadatos no reproducibles, junto al total. La
cuadrícula usa `SliverGrid` lazy y completa huecos solo con `Episodio N` derivado
del total real. Las fichas cacheadas con el formato previo se refrescan una vez;
no se borra la base. Analyze focalizado, 26 pruebas reproducibles, 3 pruebas
live y build Linux pasan. La auditoría independiente halló un P2 del marcador
de caché y un P3 de validación URI; ambos quedaron corregidos con regresiones.
La app release está abierta sobre `.ai-local/fase05/detail-review.sqlite` y la
captura actual del Home está en `.ai-local/fase05/episodes-open.png`. Wayland no
tiene entrada; falta revisión manual de la ficha. Informe:
[F05 episodios](../ai-system/audits/F05-episodes-audit-2026-11-14.md).

### Fichas públicas sin cuenta — 2026-11-14

El ID ya llegaba desde Home. El lookup por ID omitía SQLite y el resumen de
AniList no incluía reparto ni relaciones. Drift v8 añade caché bajo demanda por
ID con 64 registros y frescura de 24 h. La ficha muestra el registro local
antes de refrescar y Catálogo puede reencontrarlo por título sin red. AniList
responde sin OAuth y la biblioteca conserva su persistencia independiente.
Pruebas focalizadas y límites en [auditoría](../ai-system/audits/F05-detail-offline-audit-2026-11-14.md).
Pendiente revisión manual, sin avanzar de fase.

## Ficha de anime — corte 05.1 pendiente de revisión — 2026-11-14

Implementada solo cabecera + navegación interna. Sigue usando `CatalogService` / `ProviderAnimeMetadata` y el shell de navegación existente. AniList adapter conserva el romaji y se usa año final que ya venía en `AnimeSummary`; no se amplió GraphQL a episodios, cast, trailers, galería de terceros o relaciones. La cabecera tiene score, banner/póster y campos disponibles; acciones de player/descarga desactivadas sin fuente. Información, títulos alternativos, galería limitada a imágenes reales y estados vacíos explícitos. Los seis status locales y confirmación Completed permanecen.

Pruebas focalizadas de integration/service/anilist 21 pasaron, analyze focalizado limpio y Linux release build exit 0 con Flutter 3.47.9/Dart 3.13.7 aislado. Widget prueba teléfono aislada 390×844; test de shell desktop verifica menú y back del detalle. Fedora app está abierta en Home con AniList real y DB separada `.ai-local/fase05/detail-review.sqlite`; captura Home: `.ai-local/fase05/fedora-kongroo-home.png`. Wayland MCP devuelve `Transport closed` en capture y describe, input también; no se pudo navegar ni capturar pantalla detail. No afirmar revisión visual real de detalle ni medición de recursos. Auditoría y evidencia en [F05.1](../ai-system/audits/F05.1-audit-2026-11-14.md), sesión [detail](sessions/2026-11-14-fase05-1-detail.md). Detenerse para aprobación del propietario antes de 05.2.

## Inicio — 2026-11-14

Último Home para revisión manual: layout conservado. Hover escala la portada recortada 1.035 y usa cápsulas translúcidas; PC abre menú de escritorio refinado con clic derecho; móvil/TV conserva tres puntos y el contrato común. Badge de score usa estrella vectorial dorada y valor real. El hero avanza cada 6 s; selección manual reinicia, y movimiento reducido, ventana/ruta inactiva o hero fuera del viewport pausan autoplay. Las filas aceptan rueda vertical mapeada horizontalmente y delta de trackpad; en los bordes la señal pasa al scroll vertical. `Continue watching` y `Currently watching` se omiten sin datos locales. Análisis Home Dart/Flutter limpios, Home tests 13/13 y build release Linux exitoso con SDK aislado. Capturas Fedora: `.ai-local/home/home-polish-final-normal.png` y `.ai-local/home/home-polish-final-autoslide-2.png` muestran score y avance Attack on Titan → Demon Slayer. MCP Wayland devolvió `Transport closed`; XTest abrió el consentimiento KDE de control remoto, no concedido, y no se usó para interacción. Hover/menú no tienen captura real; widget tests cubren sus acciones y apariencia. Android/TV físicos no probados. La app release sigue en Home con DB aislada `.ai-local/home/home-polish-review.sqlite`. Detenerse para revisión manual; fase no aceptada. Informe: [auditoría quirúrgica](../ai-system/audits/F3-home-surgical-adjustment-audit-2026-11-14.md).

## Estado actual — operación autónoma F2.3–F2.10

F2.2 fue aceptada/cerrada por el propietario; queda la limitación histórica de no tener prueba automatizada end-to-end del lifecycle nativo de `VideoController`. F2.3–F2.10 y rendimiento están autorizadas para trabajo autónomo, pero ninguna fase se acepta sin decisión del propietario. F2.8 tiene implementación y auditoría independiente focalizada: 24 tests domain/data/application/widget, una integración de descarga fake HTTP→storage→coordinator→libmpv real, Flutter/Dart analyze, build Linux release del entrypoint específico y CI completa exit 0 (40 pruebas Python + 175 Flutter). La auditoría corrigió protección `.part`, rollback de composición, mapeo multipart, storage failure, redirect API allowlisted, búsqueda por IMDb padre, `Retry-After` del GET y submits concurrentes; la reevaluación final no encontró nuevos hallazgos. No hay credenciales para API live ni se gastó cuota. Toolchain Flutter 3.47.9/Dart 3.13.7 aislada; parche UTF-8 local conservado. F2.7 mantiene riesgo real: `Player.stream.error` carece de identidad de fuente, así que no afirmar correlación A/B solo por generación Dart. Próxima acción: abordar F2.7 antes de funciones dependientes y preservar estos resultados como evidencia actual. No implementar F2.11/F3 ni marcar fases aceptadas. Ver [F2.8](../ai-system/audits/F2.8-audit-2026-11-11.md), [F2.6](../ai-system/audits/F2.6-audit-2026-11-10.md), [reevaluación F2.3](../ai-system/audits/F2.3-fullscreen-reevaluation-2026-11-10.md), [estado](PROJECT_STATE.md), [PROGRESS](../../PROGRESS.md) y [ROADMAP](../../ROADMAP.md).

## Contexto mínimo
Las instrucciones del usuario en chat son directas. Los adjuntos expresamente enviados por el propietario pueden leerse en solo lectura desde la ruta de plataforma proporcionada, sin explorar archivos vecinos. La inspección y modificación de archivos del proyecto se limita a esta raíz Git; cambios de código permanecen dentro del repositorio. No explorar documentos personales no autorizados ni seguir symlinks externos. Respetar el sandbox.

Trabajas en la carpeta PROYECTO ANIME dentro de Vídeos. El alcance inicial de infraestructura IA fue supersedido por autorizaciones posteriores del propietario, incluida F2.3. Seguir el alcance explícito vigente; no acceder a otro repositorio ni configuraciones personales.

## Modelo de subagentes

### Modelo de subagentes — 2026-11-09

Los 21 perfiles omiten modelo/esfuerzo y la configuración local no define defaults; los subagentes heredan ambos del chat principal. Revisar `.codex/agents/`, `.codex/config.toml` y [registro](../ai-system/AGENT_REGISTRY.md) si cambia esta política.

## Context7 MCP — 2026-11-09

Context7 quedó configurado en `.codex/config.toml` como remoto, con allowlist de solo `resolve-library-id` y `query-docs`; no instala dependencias de la app. Para ver las herramientas en Codex hay que recargar la configuración/abrir una sesión nueva. No enviar código privado ni secretos en consultas.


## Protocolo de auditoría KONGROO

La política permanente para todo el repositorio está en `AGENTS.md`; el procedimiento detallado está en `.agents/skills/kongroo-deep-audit/SKILL.md`. Informes en `docs/ai-system/audits/`. Muestra F2.2: [informe](../ai-system/audits/F2.2-audit-2026-11-09.md); halló un P1 y tres P2, sin corregir código ni aceptar F2.2. Usar `$kongroo-deep-audit` o delegación automática pertinente; auditoría independiente secuencial.

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

### F1.10 — 2026-11-09

`ProgressDraft`/`ProgressDocument`/`ProgressRepository` puros; `LocalProgressRepository` persiste JSON opaco en Drift, por identidad caller-owned y timestamp técnico UTC generado al guardar. 3 tests SQLite cubren cierre/reapertura, reemplazo exact-key, ausencia/JSON inválido. Revisión de datos pidió separar draft del read model y corregir el nombre de prueba; quedó atendida. F1.10 parcial: FR-03/FR-18 requieren definición propietaria de identidad anime/episodio y campos; no inventar posición, duración, porcentaje, finalización o precedencia. Ver sesión F1.10. Próximo F1.11 contract/FakeRemote; no real Supabase.

### F1.12 — 2026-11-09

`test/core/core_integration_test.dart` comprueba local-first: FakeSyncRemote falla y el progreso SQLite permanece. `bash scripts/ci.sh` exit 0 con Flutter 3.50.0-0.4.pre/Dart 3.14.0 beta: 40 IA, checks sintéticos, 36 Flutter, análisis y 8 archivos domain pasan. Stable 3.47.9 sigue fallando LSP Unicode; no decir universalmente CI verde. F1.9–F1.11 tienen límites/decisiones pendientes documentadas. No iniciar F2. Ver sesión F1.12.

### F1.11 — 2026-11-09

`domain/synchronization/SyncRemote` acepta un envelope JSON opaco y retorna un recibo. `FakeSyncRemote` registra deep snapshots inmutables, permite callback de respuesta y no deduplica, persiste, resuelve conflictos, reintenta ni usa Supabase. Cuatro pruebas; auditor contractual encontró aliasing anidado y se corrigió. F1.11 parcial hasta definir protocol identity/idempotency/conflict/order/delete/retry. Ver ADR-A11 y sesión.

### Auditoría real F1.5–F1.12 — 2026-11-09

Informe verificable: [`docs/validation/2026-11-09-f1-5-f1-12-real-tests.md`](../../docs/validation/2026-11-09-f1-5-f1-12-real-tests.md). Focaliza trabajo posterior en decisiones propietarias: elegibilidad AniList, TTL/retención de búsquedas, catálogo de preferencias, OAuth/keyring, esquema de progreso y protocolos sync. No hacer request público ni activar keyring sin que se resuelvan sus condiciones. 44 pruebas Flutter, analyze, Linux release y CI exit 0 con SDK beta aislado; stable 3.47.9 sigue con la falla LSP Unicode. No confundir el flujo de integración entre adaptadores con una función de producto conectada a UI. No iniciar F2.

### Catálogo local — estado vigente, 2026-11-09

La UI mínima conecta fake sintético → `CatalogService` → identity/library/progress existentes → Drift v6. Búsqueda, detalles, alta idempotente, status provisional, progreso y recuperación tras cerrar/reabrir se cubren en `test/widget_test.dart`; `HttpOverrides` rechaza HTTP. No se habilitan AniList/TMDB/Kitsu, OAuth, sync de cuenta ni reproductor. ADR-A14 continúa propuesta/no aceptada; `planned/watching/completed` son provisionales. La auditoría independiente no detectó duplicados de repositorios/tabla ni defecto de persistencia; señaló que el runtime instalado usa su Application Support por defecto. La prueba real utilizó `KONGROO_DATABASE_PATH` dentro de `.ai-local/`, no tocó la base personal y verificó schema v6 + `integrity_check=ok`. Ver [sesión](sessions/2026-11-09-catalog-local-integration.md), [arquitectura](../architecture/catalog-system.md), [ADR](../adr/additional/ADR-A14-catalog-providers-identity.md).

Toolchain reproducible: Flutter `3.50.0-0.4.pre`, Dart `3.14.0-315.3.beta`; ejecutar con `FLUTTER_ROOT` removido, `.ai-local/toolchains/flutter/bin` al inicio de PATH y `PUB_CACHE=.ai-local/pub-cache`. La suite completa vigente fue 62 pruebas Flutter; análisis/formato/checker/build Linux y `bash scripts/ci.sh` pasan (40 pruebas IA + 62 Flutter en CI). No se hizo commit/push por instrucción. Siguiente decisión propietaria: aceptar/cambiar los estados y ADR-A14 y resolver elegibilidad/retención antes de conectar un provider real. No avanzar a F2 ni añadir plataformas futuras durante esta integración.

### F2.1/F2.2 — corte previo a matriz v2 — 2026-11-09 (histórico)

Evaluación documental disponible en [`F2.1-player-evaluation.md`](../architecture/F2.1-player-evaluation.md). El spike F2.2 permanece aislado bajo `app/lib/{application,data,app}/player`; el fixture sintético está en `.ai-local/f2.2/fixtures/`. Se corrigieron F22-001–F22-004, se cerraron los detalles detectados en revisión adversarial y se completó la reevaluación independiente. 11 pruebas focalizadas, CI (40 IA + 73 Flutter) y build Linux release pasan con Flutter 3.50.0-0.4.pre / Dart 3.14.0-315.3.beta. Si falla `Player.dispose()` nativo, la política mantiene el lease en cuarentena y requiere reiniciar el proceso antes de crear otro Player; no se repite dispose. F2.2 sigue no aceptada/no cerrada; faltan primer frame visible y revisión de artefactos/licencias. No avanzar a F2.3. Ver [`reevaluación`](../ai-system/audits/F2.2-audit-reevaluation-2026-11-09.md).

### F2.2 — estado vigente tras reevaluación de correcciones — 2026-11-09

Las correcciones v2 cubren slider final/coalescing, close gate GTK, validación local, stop/reopen, casos negativos/recuperación, stream en fallo de dispose, protección contra symlinks padres del fixture y referencias documentales. `tools/player/generate_f2_2_fixture.sh` genera el medio bajo `.ai-local/`; `player_test_fixture.dart` lo genera si falta. La suite pasó con el fixture temporalmente ausente y generado automáticamente; se restauró el fixture original con el mismo SHA-256. El entrypoint deriva la ruta desde `KONGROO_PROJECT_ROOT`, no desde cwd. La suite player pasó 25 pruebas y la suite Flutter completa pasó 87; Flutter analyze y build Linux release del entrypoint explícito también pasaron con `.ai-local/toolchains/flutter/bin/flutter`. `dart analyze`, formato, checker de imports, memory check y diff check pasaron. El `flutter` resuelto por PATH produjo un error LSP durante analyze y una compilación framework/engine incompatible durante build; por reproducibilidad, el informe da los comandos exactos del SDK local explícito, que pasaron. Un intento de test de VideoController con canal simulado quedó bloqueado esperando `platform.future` y se retiró; no hay lifecycle nativo automatizado. La UI diferencia estado de controller, ID de textura y primer frame procesado, pero la evidencia visual en compositor y gesto GTK siguen pendientes; SIGTERM del harness no cuenta como cierre correcto. El archivo externo v2 no apareció tras la verificación solicitada; se contrastaron los doce hallazgos pegados y la primera auditoría distinta dentro de `docs/ai-system/audits/`. La reevaluación independiente confirmó R1/R2 corregidos y pidió actualizar los resultados del informe/traspaso; el informe se actualizó. R1 tiene prueba automatizada del helper y verificación manual del launcher; el auditor recomendó automatizar además la protección shell. F2.2 sigue abierta/no aceptada; no iniciar F2.3. Ver [informe v2](../player/F2.2-spike-report-v2.md).

### F2.2 — Controles y primer intento de revalidación — 2026-11-10 (histórico; ver nota vigente)

Se confirmó en el source de `media_kit_video 2.0.1` que `Video` usa adaptive controls por defecto; el surface pasa `NoVideoControls as VideoControlsBuilder?`, valor `null` que omite el overlay. Play/Pause sigue el snapshot; el slider actualiza local y coalescea. Auditoría independiente encontró un seek pendiente que podía quedar después de Stop: la UI ahora elimina el destino pendiente, espera el seek activo y luego manda Stop. Se añadió regresión que exige orden `seek, stop`; revisión estática la aprobó.

El close gate Dart conserva watchdog de 15 s y el cleanup Future no se cancela. GTK añade watchdog GLib nominal de 20 s e invalida respuestas tardías. Si la invocación original no responde, nuevas solicitudes no duplican el MethodChannel; cuando vuelve su callback, un gesto posterior puede reintentar. Si nunca vuelve, se conserva la ventana. Usa `GWeakRef` y una generación como `user_data`, de modo que no se acumulan refs fuertes por gesto. Depende de un GTK main loop responsive; el objeto C++ de `my_application.cc` se compiló con las flags del build graph. En el primer intento, Flutter beta 3.50.0-0.4.pre falló tests/build antes de app por mismatch framework/engine (`SemanticsRole.slider`); esto quedó superado para tests/build por la stable 3.47.9 aislada descrita en la nota vigente. Una corrida accidental previa con Flutter de PATH sigue sin usarse como evidencia.

Broadway aislado se ejecutó con runtime dentro de `.ai-local`; GTK no pudo crear EGL/OpenGL y Flutter no creó platform view. El plugin reportó texture ID/software rendering; no se verificaron primer frame, píxeles/audio actuales, controles con ratón, resize, VideoController ni delete-event. El proceso se paró con Ctrl-C, no mediante cierre GTK. No se usó el escritorio principal. F2.2 permanece abierta/no aceptada; consultar el [informe](../player/F2.2-spike-report-v2.md) y la [auditoría](../ai-system/audits/F2.2-audit-2026-11-10.md); no iniciar F2.3.

### F2.2 — Revisión final de cierre — 2026-11-10

La instrucción solicitada en `docs/ai-system/audits/entrada/Operacion-cierre-F2.2.txt` no existe con `entrada/`; se leyó el documento homónimo en `docs/ai-system/audits/Operacion-cierre-F2.2.txt` íntegro (817 líneas). Dos widget tests confirman el aviso de cleanup ante startup fallido/pendiente y el gate permite cerrar tras `module.close()` o rollback exitoso. Con Flutter 3.47.9/Dart 3.13.7 aislado pasaron el test focused 2/2, los 32 tests player, los 94 tests Flutter y el build release del entrypoint `-t lib/main_player_spike.dart`; `pub get --offline --enforce-lockfile` conservó el lock. `dart analyze` exit 0 con ocho infos. `scripts/ci.sh` termina exit 1 solo por Flutter analyze (255), bloqueado por LSP UTF-8 en la ruta Unicode. No hay prueba GTK real, compositor visible ni lifecycle Linux de VideoController. F2.2 sigue pendiente/no aceptada; no iniciar F2.3. Ver [auditoría](../ai-system/audits/F2.2-audit-2026-11-10.md), [informe](../player/F2.2-spike-report-v2.md) y `TESTING.md`.


### F2.2 — Últimas comprobaciones — 2026-11-10

Flutter 3.47.9 aislado usa backport reproducible del arreglo upstream LSP de Content-Length UTF-8; herramienta reconstruida, analyze y CI completa exit 0 (40 Python, 94 Flutter). Ocho infos se resolvieron con bindings `final`. El propietario verificó manualmente video/fotogramas visibles, audio, controles exclusivos, Play/Pause y seek adelante/atrás; no son pruebas automatizadas. El helper `tools/player/capture_f2_2_owner_close.sh` registra cleanup Dart, handshake GTK y exit del launcher. Su recorrido Stop/cierre sigue pendiente de ejecución del propietario; no se abrió una ventana. Sin lifecycle real de VideoController Linux. F2.2 abierta/no aceptada; no iniciar F2.3.

Follow-up de auditor_codigo, solo lectura: no quedan defectos estáticos en el alcance revisado tras corregir la descripción del watchdog y endurecer las guardas de symlink/tee. Sin GUI ni pruebas; el recorrido de cierre real continúa pendiente.


### F2.2 — Stop → Play, handoff — 2026-11-10

Último cambio en el adaptador media_kit: mantener fuente lógica y distinguir snapshot `stopped`; Play después de Stop reabre la URI en el mismo Player/VideoController, mientras Pause→Play reanuda. Integración libmpv cubre Pause→Play, Stop repetido y dos reinicios desde <1s, fuente ausente/recuperación; pruebas focalizadas 14/14. `bash scripts/ci.sh` exit 0 (40 infraestructura, 99 Flutter, análisis/formato/import checker); Linux release entrypoint spike exit 0. Revisión `auditor_codigo` de solo lectura: sin defecto demostrado de cola/capas; falta confirmar visualmente imagen tras Stop→Play en Fedora debido posible issue #957. No se manipuló escritorio, no se afirma observación de compositor/GTK. Validación del propietario requerida para Stop, Play, imagen/audio, repetición y cierre. Evidencia `.ai-local/f2.2/evidence/stop-play-*`; detalle `docs/ai-system/audits/F2.2-stop-play-audit-2026-11-10.md`. Mantener fase abierta/no aceptada, no F2.3.


### F2.2 — aceptada y cerrada por el propietario — 2026-11-10

El propietario confirma Fedora: video/audio visibles, controles únicos, Play/Pause, Seek, dos ciclos Stop → Play con recuperación de imagen/audio y cierre normal de ventana/proceso. CI local exit 0 con 40 pruebas de infraestructura y 99 Flutter; build Linux release `-t lib/main_player_spike.dart` exit 0. El SDK Flutter 3.47.9 aislado conserva el backport Unicode documentado en `tools/flutter/` y `TESTING.md`; no se tocó Flutter global. Única limitación de aceptación anotada: no hay prueba automatizada completa del lifecycle nativo de VideoController. En la fecha de ese registro F2.3 aún no estaba autorizada; la autorización posterior y el estado vigente aparecen al inicio de este handoff. Ver [estado](PROJECT_STATE.md), [PROGRESS](../../PROGRESS.md), [informe](../player/F2.2-spike-report-v2.md) y [auditoría Stop → Play](../ai-system/audits/F2.2-stop-play-audit-2026-11-10.md).

## Handoff de la operación extendida

Continuar desde [el DEMO y su matriz](../player/operacion-extendida.md). El launcher genera fixtures originales y sirve espejos efímeros. La integración real comprueba selección de audio mediante mpv, continuidad HTTP y restauración tras 503. Revisar .ai-local/player-demo/evidence. Priorizar entrada externa con control de destinos, preferencias de pista y búsquedas por episodio. La atribución de errores nativos tardíos sigue abierta.

## Corrección de interfaz con Morevna

El [DEMO real](../player/demo-morevna.md) arranca con Morevna 3.0.2, ofrece episodio 4.0.1 y preserva las pistas equivalentes al cambiar de espejo. Español visible en la captura de Fedora y pruebas nativas separadas. Las versiones inglesa y rusa de 3.0.2 mostraron desfase variable y no se remultiplexaron. Entrada gráfica no operativa en esta sesión. Continuar desde el informe de auditoría focalizada, sin inferir aceptación.

### Estabilización del cambio de fuente — 2026-11-12

La regresión visible `Playback command failed.` fue reproducida en widget tests cuando una opción de audio vieja persistía en PopupMenu después de cambiar el medio; el callback estaba emparejando su ID nativo con el contexto nuevo. Menú y coordinator ahora validan generación + `mediaContextRevision`, adelantada síncronamente al pedir `open`, `switchSource` o Stop. La prueba reproduce una cola con seek bloqueado y selección vieja, además Stop pendiente. Auditor `auditor_codigo`, dos pasadas secuenciales de solo lectura, confirma sin P1/P2 en ese límite. Integración Morevna/libmpv a 00:40 valida cambios repetidos A/B, pausa, reanudación, seeks y rollback 503 con posición dentro de 2 s. En esta sesión: 94 player tests + 1 opcional omitida; suite Flutter 206 + 1 omitida; CI y build release específicos pasan. Logs actuales en `.ai-local/player-demo/evidence/ui/server-switch-*`. Wayland no ofrece input backend; captura MCP quedó colgada y terminó sin screenshot. No se demostró clic manual, compositor ni cierre GTK en este corte. No cerrar la fase: repetición gráfica pendiente y riesgo separado de `Player.stream.error` sin identidad de fuente continúa en F2.7. Informe: [auditoría](../ai-system/audits/F2.7-server-switch-audit-2026-11-12.md).

### Selector de calidad de video — 2026-11-12

El panel lee solo `VideoTrackInfo` de la fuente activa. Resoluciones estándar se rotulan a partir de dimensiones nativas; una pista aparece como fija y no genera Auto. Con varias pistas aparece Auto (pista predeterminada de media_kit, no ABR) y las pistas reportadas. `SpikePlayerCoordinator.selectVideoTrack` serializa y valida fuente/ID/generación; el adaptador verifica `vid` sin reabrir el medio. Auditoría de `auditor_codigo` alineó la regla de Auto entre snapshot y media_kit para contar pistas reales, excluyendo pseudo-pistas `auto/no`. Pruebas focused: widget de panel/página, integración real libmpv con dos streams 320×180/160×90, y Morevna (534×300 fija). Se verificó la posición pausada y que IDs de audio/subtítulos no cambian. No hubo observación gráfica manual. HLS/DASH/manifest y variantes remotas no están conectados en el flujo actual; no afirmar selección ABR ni calidad remota. Ver [auditoría](../ai-system/audits/PLAYER-QUALITY-audit-2026-11-12.md).

### Mantenimiento documental modular — 2026-11-12

README añadidos a submódulos previamente sin guía en `app/lib/core`, `app/lib/data/local_db/tables`, `app/lib/data/testing` y subcarpetas application/domain/data del reproductor. El índice se actualizó en `MODULE_INDEX.md`. Sin cambios funcionales. `spike_player_page.dart` y `spike_player_coordinator.dart` son archivos grandes, pero no se refactorizaron al no haber defecto aislado demostrado ni autorización de cambio de comportamiento.
