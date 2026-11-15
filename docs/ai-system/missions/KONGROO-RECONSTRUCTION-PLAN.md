# KONGROO — PLAN MAESTRO DE RECONSTRUCCIÓN T00–T24

> Versión documental: 1.0 — 15 de noviembre de 2026.  
> Fuente: auditoría de lectura de `kurogamishuen15/AnimeApp-Dev`, rama `main`, commit de referencia `33ceaef5b996c55577524c3448bbb4bee5363952` y requisitos del propietario expresados en la conversación.  
> **Este archivo define trabajo por ejecutar, no certifica resultados.** Revalidar contra el árbol local antes de cambiar archivos.

## 0. Misión y criterios no negociables

**Objetivo de producto:** `Anime → correspondencia de identidad → episodio real → proveedor → servidor → fuente reproducible → media_kit/libmpv`, con selección multilingüe, cambio de fuentes, fallback, subtítulos, progreso por episodio y bajo consumo de recursos.

**Objetivo final solicitado:** comprobar mediante el reproductor un mínimo de **70 títulos de anime diferentes**. Un HTTP 200, un resultado de búsqueda, un manifiesto HLS o un test con fakes **no** cuentan como reproducción. Una prueba cuenta únicamente si identifica un título y episodio concretos, abre un medio adecuado, observa inicio de decodificación/video y avance real, y deja evidencia reproducible. Si no se alcanza 70, registrar el número exacto y dejar el gate abierto; jamás inventar éxitos.

**Alcance:** solo la raíz autorizada del repositorio local de Kongroo; Fedora Linux como banco inicial. Mantener futura separación PC/Android/TV, la UI AMOLED existente y la sincronización con AniList **opcional**. No ampliar esta misión a descargas de contenido ni rehacer todo el diseño visual.

**Límites:** no evadir DRM, CAPTCHA, autenticación o controles de acceso; no registrar secretos o URLs firmadas. Investigar referencias de terceros sin asumir que la licencia de un scraper cubre los derechos de los medios. Continuar con tareas independientes si un sitio externo está indisponible. Una comprobación autorizada de un servicio no demuestra disponibilidad permanente.

**Preservación:** no hacer `git reset --hard`, `git clean`, `push --force`, borrados masivos ni edición de archivos fuera de la raíz. No descartar cambios ajenos. No modificar agentes ni toolchains globales. **No commit ni push** sin autorización adicional. Las bases personales de Drift y las credenciales no deben utilizarse en pruebas.

**Pruebas:** diferenciar `tests unitarios con fakes`, `tests de contrato`, `HTTP loopback`, `libmpv con medios locales permitidos`, `smoke real externo` y `verificación gráfica Fedora`. No confundir estos niveles. Ejecutar pruebas focalizadas durante cambios; CI completa al gate del bloque y al final. No afirmar pruebas que no se ejecutaron.

## 1. Estado inicial constatado (revisar si cambiaron los archivos)

- Registro de producción: `AnimeAv1PlaybackProvider` y `TioAnimePlaybackProvider`; sin evidencia de episodio externo reproducido en la auditoría del 14–15/11/2026.
- AnimeOnline Ninja tiene documentación de bloqueo, no adaptador registrado.
- `PlaybackProviderManager._validateSources()` exige `sourceAlternatives` cuando un proveedor devuelve múltiples servidores; TioAnime no lo declara pese a devolver alternativas. Posible rechazo `invalidResponse` comprobable mediante test.
- La pestaña de episodios puede construir tarjetas desde el total informado por AniList, no desde disponibilidad confirmada.
- La ruta `ProviderPlaybackRoute` transmite una allowlist de URIs exactas y crea el módulo reproductor, pero carece de recuperación suficiente si falla la apertura inicial.
- `ResolvedPlaybackStream` es insuficiente para cabeceras HTTP, idioma, pistas y subtítulos; `MediaKitSpikeEngine` llama `Media(source.toString())` sin `httpHeaders`.
- La ruta externa no inyecta todos los servicios opcionales, como AniSkip y OpenSubtitles.
- Home construye `HomeContent.episodes` desde una lista vacía; «Continuar viendo» no refleja los checkpoints reales en ese flujo.
- La persistencia de progreso de catálogo utiliza un episodio fijo de demostración; falta identidad por episodio.
- `spike_player_page.dart` importa `dart:io` y `scripts/check_imports.dart` lo prohíbe en esa ubicación; documentación histórica informa fallo de CI.
- La pestaña «Enlaces» muestra relaciones como texto y no tarjetas navegables.
- Existen múltiples READMEs (40/40 carpetas Dart con README en el árbol auditado); algunos aún describen una composición anterior.
- `main.dart` y el módulo de catálogo ya integran más componentes de los que describen algunos documentos históricos. **El código local vigente prevalece sobre documentos antiguos.**

## 2. Orden de bloques y puertas de avance

| Bloque | Tareas | Objetivo | Gate de salida |
|---|---|---|---|
| A | T00–T03 | Línea base, fallo reproducido, CI, límites modulares | G1: código analizable/CI y diagnóstico probado; P0/P1 del bloque resueltos |
| B | T04–T08 | Contratos universales, catálogo de episodios, identidad, idiomas, ajustes | G2: contratos y casos complejos validados, compatibilidad de consumidores |
| C | T09–T13 | Gestor, HTTP, adaptadores reales y extensión modular | G3: tests de contratos/errores, adaptadores no ficticios, capacidades coherentes |
| D | T14–T17 | Apertura libmpv, cabeceras, fallback, cierre y cambio de fuente | G4: reproducción autorizada de extremo a extremo, fallback y cierre reproducibles |
| E | T18–T20 | Progreso real, Home, ficha y módulos avanzados | G5: flujo de usuario y persistencia sin dependencia de cuenta AniList |
| F | T21–T24 | 70 títulos, regresiones, rendimiento y auditoría independiente | G6: 70 éxitos documentados, CI y auditoría sin P0/P1 |

**No ejecutar bloques posteriores en una misma corrida automática.** Cada corrida selecciona el primer bloque elegible, trabaja ese bloque, audita, persiste estado y finaliza. Una ejecución posterior lee el estado y continúa. **Si una tarea esencial está `BLOCKED`, no simular un gate aprobado ni avanzar a un bloque que dependa de ella.**

### Estados, severidades y evidencias

Estados válidos: `PENDING`, `INVESTIGATING`, `IMPLEMENTING`, `TESTING`, `AUDITING`, `BLOCKED`, `DONE`. `DONE` exige evidencia concreta. Severidades: P0 (seguridad/pérdida datos), P1 (flujo principal roto), P2 (función incompleta/riesgo), P3 (secundario).

Para cada tarea, registrar en `KONGROO-RECONSTRUCTION-STATUS.md`: estado, commit base, cambios, pruebas con comando + exit code, defectos, hallazgos y motivo de cierre o bloqueo. Actualizar `KONGROO-RECONSTRUCTION-HANDOFF.md` al terminar cada corrida.

## BLOQUE A — Diagnóstico y estabilización

### T00 — Inventario completo del código y estado Git

**Prioridad:** P1. **Dependencias:** ninguna.  
**Inspeccionar:** `app/lib/**`, `app/test/**`, `app/pubspec.{yaml,lock}`, `scripts/ci.sh`, `scripts/check_imports.dart`, `docs/memory/**`, `docs/ai-system/audits/**`, `app/linux/**`.  
**Hacer:** registrar rama, HEAD, cambios preexistentes y remotos sin modificarlos; dibujar grafo de dependencias `app/application/domain/data/core/settings`; identificar contratos, rutas activas, fakes, código obsoleto, documentación desactualizada, cobertura real y dependencias nativas. Obtener línea base de test/CI sin tocar bases personales. Diferenciar código verificado, simulado, incompleto y no probado.  
**Entregable:** inventario de módulos/consumidores y matriz de defectos con archivo, función y severidad.  
**Aceptación:** corresponde al checkout real y señala expresamente desviaciones frente al commit de referencia.

### T01 — Localizar el error «No se encontró un servidor HTTP disponible» y demás fallos de apertura

**Prioridad:** P1. **Dependencias:** T00.  
**Recorrido:** Home → ficha → `PlaybackEpisode` → `PlaybackProviderManager.resolveCandidates` → `findSources` / `resolveServer` → `ResolvedPlaybackStream` → selector → `ProviderPlaybackRoute` → `SpikePlayerModule` → `SpikePlayerCoordinator` → `MediaKitSpikeEngine` → libmpv.  
**Hacer:** averiguar si la frase literal proviene del binario actual, un demo/launcher antiguo u otra ruta; diagnosticar búsqueda, matching, episodios, capabilities, `invalidResponse`, 403/404/429, parsing, embed vs medio, cabeceras, expiración, allowlist, apertura nativa y primeros frames. Agregar diagnósticos tipados, sin exponer URL privada ni secretos.  
**Pruebas:** mocks de cada fallo, HTTP loopback, fuente multimedia propia/licenciada; smoke externo autorizado únicamente si disponible.  
**Aceptación:** cada fallo reproducible tiene causa localizada, test de regresión y resultado visible; si el texto no existe en HEAD, registrar hipótesis de desfase de versión sin atribución falsa.

### T02 — Recuperar CI y proteger límites de capas

**Prioridad:** P1. **Dependencias:** T00.  
**Archivos:** `app/lib/app/player/spike_player_page.dart`, `scripts/check_imports.dart`, `scripts/test_check_imports.sh`, `scripts/ci.sh`.  
**Hacer:** investigar por qué la UI importa `dart:io`; mover funciones de plataforma a contrato/adaptador cuando corresponda. No simplemente desactivar reglas. Extender el checker para proteger las nuevas fronteras y ejecutar tests negativos. Aislar cualquier incompatibilidad de toolchain Flutter de errores de la app sin modificar SDK global.  
**Aceptación:** análisis, checker y CI pasan en toolchain compatible, o bloqueo de toolchain queda demostrado, sin bajar controles.

### T03 — Modularidad interna y responsabilidad única del player

**Prioridad:** P2. **Dependencias:** T00 y T02.  
**Inspeccionar:** `spike_player_page.dart`, `spike_player_coordinator.dart`, `playback_provider_manager.dart`, `media_kit_spike_engine.dart`, `spike_player_module.dart`.  
**Hacer:** identificar responsabilidades mezcladas (acciones UI, estado, comandos, errores, calidad, audio, subtítulos, fuentes, observación nativa). Refactorizar solo piezas justificadas y cubiertas por tests; mantener **un** Player/VideoController y ciclo de vida confiable. Documentar cada frontera.  
**Aceptación:** no hay duplicación de motor, comportamiento probado no se pierde y se preservan contratos neutrales.

## BLOQUE B — Contratos, episodios e idiomas

### T04 — Fuente de reproducción universal y tipada

**Prioridad:** P1. **Dependencias:** bloque A.  
**Archivos:** `domain/player/providers/playback_source.dart`, `playback_provider_contract.dart` y consumidores.  
**Hacer:** evolucionar de forma compatible modelos inmutables que representen anime interno/externo, episodio real y tipo de contenido, proveedor/fuente/servidor, protocolo (MP4/HLS/DASH/otro/desconocido), URI, headers acotados, expiración/renovación, audio, subtítulos, hardsub, calidad/resolución, procedencia y estado de disponibilidad; distinguir metadatos declarados de hechos medidos. No incluir Dio/Flutter/libmpv en domain.  
**Pruebas:** validación, sanitización de errores/URLs, identidades, alternativas y equivalencia de contratos.  
**Aceptación:** modelo capaz de describir fuente multilingüe y extensible, sin asumir 1080p o audio japonés cuando son desconocidos.

### T05 — Episodios reales frente a episodios catalogados

**Prioridad:** P1. **Dependencias:** T04.  
**Archivos:** `domain/catalog/**`, `application/catalog/**`, `app/catalog/detail/anime_detail_tab_content.dart`, adaptadores correspondientes.  
**Hacer:** distinguir cuatro niveles: conteo/metadatos AniList, episodios ofrecidos por proveedor, fuentes encontradas y reproducción comprobada. Añadir catálogo de episodios con identidad proveedor-específica, títulos, temporadas, películas, OVA/ONA/Special, numeración irregular, disponibilidad y resultados vacíos. No generar capítulos reproducibles solo desde `episodeCount`.  
**Aceptación:** las tarjetas muestran estado real, identifican episodios sin fuente y nunca presentan los títulos como prueba de reproducción.

### T06 — Correspondencias AniList ↔ proveedor con evidencia

**Prioridad:** P1. **Dependencias:** T04 y T05.  
**Archivos:** `domain/catalog/anime_identity*`, `data/anilist/**` y nuevos adaptadores de crosswalk.  
**Hacer:** usar IDs verificados, vínculos existentes en Drift y referencias de metadatos externas verificables. Emplear alias, romaji, inglés, japonés, año, formato, temporada como evidencias auxiliares. Distinguir `matched`, `unresolved`, `ambiguous`; no enlazar automáticamente por similitud débil. Investigar `media-index` solo como referencia de mapeos, no como resolver multimedia.  
**Pruebas:** remakes, secuelas, alias ES/EN/JP, mismo título distinto año, especiales y episodios ambiguos.  
**Aceptación:** matching auditable sin confundir series, temporadas ni películas.

### T07 — Contratos de idioma y subtítulos

**Prioridad:** P1. **Dependencias:** T04–T06.  
**Hacer:** distinguir idioma UI, catálogo, audio, subtítulos, región/español latino/castellano, hardsub y pistas sin idioma. Preferir etiquetas normalizadas (BCP 47 cuando exista evidencia); admitir español, japonés, inglés, ruso, portugués, francés, árabe, hindi y futuras opciones sin lista rígida. Preservar `unknown`. Exponer filtros y prioridades sin inventar doblajes.  
**Pruebas:** español latino, castellano, JP+sub ES, EN dub, ruso, multiaudio, audio desconocido y hardsub.  
**Aceptación:** API y UI no confunden idioma del sitio con audio o subtítulos.

### T08 — Preferencias persistentes sin cuenta obligatoria

**Prioridad:** P2. **Dependencias:** T04 y T07.  
**Archivos:** `settings/registry/**`, `settings/store/**`, composición del catálogo y presentación de ajustes existente.  
**Hacer:** permitir habilitar/deshabilitar proveedores, prioridad, idioma audio/sub, preferencia doblaje/subtitulado, selección auto/manual, calidad, último servidor y fallback; usar persistencia tipada. No crear segundo motor de settings.  
**Pruebas:** cambios, reinicio, defaults, valores inválidos, fallback cuando proveedor desactivado.  
**Aceptación:** preferencias operativas offline y sin login AniList.

## BLOQUE C — Gestor y proveedores

### T09 — Corregir contrato y validación del PlaybackProviderManager

**Prioridad:** P1. **Dependencias:** T02 y T04.  
**Archivos:** `application/player/providers/playback_provider_manager.dart`, `data/player/providers/tioanime/tioanime_playback_provider.dart`.  
**Hacer:** reproducir y corregir rechazo de múltiples servidores sin capability `sourceAlternatives`; revisar orden, matching, validación de identidad, deduplicación de solicitudes, cancelación cooperativa, breaker 3 fallos/60 s, prioridades, errores tipados y supervivencia ante otro proveedor caído.  
**Pruebas:** uno/muchos servidores, wrong episode, IDs duplicados, fallo/timeout/403, circuit half-open, cancelación, concurrentes, proveedor alternativo sano.  
**Aceptación:** alternativas válidas aceptadas, datos malformados rechazados y tests en verde.

### T10 — Infraestructura HTTP segura y formatos reproducibles

**Prioridad:** P1. **Dependencias:** T04.  
**Archivos:** `data/player/providers/public_site_http.dart` y servicios compartidos necesarios.  
**Hacer:** separar consultas de catálogo, páginas, resolución y comprobación de medios; aplicar límite de bytes, timeout, cancelación, redirects validados, protección de redes privadas (también IPv6 mapeado), seguridad de cabeceras y política por host. No considerar URI con extensión como única condición de compatibilidad, usar tipo y evidencia fiable cuando sea posible; no ejecutar JS arbitrario ni saltar desafíos de acceso.  
**Pruebas:** GET/HEAD falsos, URL sin extensión, 401/403/404/429/500, redirects, URL firmada, hostname privado, cancelación, MIME inesperado.  
**Aceptación:** fallos tipados, destinos validados y sin fuga de headers sensibles.

### T11 — Reparar proveedores actuales

**Prioridad:** P1. **Dependencias:** T09 y T10.  
**Archivos:** `data/player/providers/animeav1/**`, `tioanime/**`, `animeonline_ninja/**` si se verifica su acceso.  
**Hacer:** corregir parser SvelteKit/catálogo, título exacto, episodios reales, `videos`/servidores, capabilities, resolución, encabezados y respuestas no soportadas. Si Ninja sigue denegando acceso normal, documentar y dejar desactivado, sin bloquear T12. No tratar iframes como MP4.  
**Pruebas:** fixtures reproducibles, live smoke solo si posible y prueba real libmpv para afirmar `PLAYBACK_VERIFIED`.  
**Aceptación:** adaptadores implementados con contrato correcto; los no reproducibles quedan explícitamente no operativos.

### T12 — Extensión modular de proveedores

**Prioridad:** P1. **Dependencias:** T04–T11.  
**Hacer:** construir registro central, adaptadores independientes, infraestructura compartida (`HTTP`, parsing, validación, matching y diagnósticos), capacidades opcionales, READMEs y pruebas por proveedor. No crear carpetas vacías decorativas ni una implementación monolítica. Un nuevo provider no debe requerir editar libmpv/UI.  
**Prueba principal:** crear adaptador fake adicional que pase contrato y se registre sin modificar motor.  
**Aceptación:** extensión repetible y aislada entre proveedores.

### T13 — Inventario y ampliación de fuentes multilingües

**Prioridad:** P1 del objetivo, ejecutable por lotes. **Dependencias:** T10–T12.  
**Candidatos en español:** AnimeAV1, TioAnime, AnimeOnline Ninja, JKAnime, AnimeJara, AnimeV1, Latanime, Henaojara, AnimeFLV (verificar identidad/disponibilidad actual).  
**Internacionales de referencia:** Miruro, Senshi, AniBD, AniKoto, KickAssAnime, AllAnime, AnimeKai, ReAnime, AniZone, AnimeGG, AniNeko, 2DHive, RareAnimes. Recuperar además la lista anterior del propietario si está disponible en archivos; no inventar otros nombres.  
**Para cada uno:** documentar sitio vigente, naturaleza real (catálogo/agregador/host), idioma real, búsqueda, identidad, episodios, servidor, protocolo, estado HTTP, restricciones, reproducciones verificadas, tests y mantenimiento.  
**Estados:** `DISCOVERED`, `RESEARCHED`, `ADAPTER_IMPLEMENTED`, `SEARCH_WORKING`, `EPISODES_WORKING`, `RESOLVING`, `PLAYBACK_VERIFIED`, `UNAVAILABLE`, `BLOCKED`, `DEPRECATED`. **No declarar proveedor `PLAYBACK_VERIFIED` sin medio reproducido.**  
**Entregable:** matriz amplia de proveedores y número real de operativos.  
**Aceptación:** registro admite 24+ candidatos sin fabricar adaptadores; los efectivamente integrados superan sus tests y el objetivo de reproducción externa permanece abierto hasta prueba real.

## BLOQUE D — Motor, apertura y fallback

### T14 — Propagar contexto multimedia a media_kit/libmpv

**Prioridad:** P1. **Dependencias:** T04 y T10.  
**Archivos:** `application/player/playback_spike_contract.dart`, `data/player/engine/media_kit_spike_engine.dart`, `app/player/spike_player_module.dart`.  
**Hacer:** transportar fuente validada y cabeceras aplicables hasta `Media(..., httpHeaders: ...)` según versión instalada. Mantener compatibilidad con local files y HTTP loopback. Encapsular seguridad de orígenes, renovación y caducidad; no exponer tokens al UI/log. Respetar formatos HLS, MP4, DASH cuando estén realmente soportados.  
**Aceptación:** prueba local HTTP que requiera header y pruebe que libmpv puede abrir medio válido, sin conocimiento de proveedores en el motor.

### T15 — Fallback de la apertura inicial

**Prioridad:** P1. **Dependencias:** T09, T14.  
**Archivos:** `app/catalog/catalog_home_page.dart`, `app/player/provider_playback_route.dart`, `application/player/source_switching/**` o nuevo coordinador de apertura si se justifica.  
**Hacer:** `resolver → priorizar → intentar abrir → verificar video/avance → fallar tipadamente → siguiente alternativa`; respetar cancelación, pausas, preferencias, límite de reintentos y no duplicar Player. Evitar marcar éxito por solo HTTP 200; habilitar selección manual.  
**Pruebas:** primera válida, 403, 404, timeout, codec inválido, sin primer frame, segunda válida, todas fallan, cerrar mientras carga.  
**Aceptación:** segunda fuente probada funciona cuando primera falla; ninguna pantalla queda en estado indefinido.

### T16 — Rutas y cierre a prueba de fallos

**Prioridad:** P1. **Dependencias:** T15.  
**Archivos:** `app/player/provider_playback_route.dart`, `spike_player_module.dart`, `data/player/engine/active_player_lease.dart`.  
**Hacer:** asegurar salida incluso si `_moduleFuture` falla, `PopScope` no se queda bloqueado, dispose/cierre son idempotentes, errores no ocultan cleanup incierto, streams cancelados y la ruta ofrece reintentar/cambiar servidor/volver.  
**Pruebas:** inicialización fallida, excepción nativa, doble cierre, cancelación, módulo parcial, cambio de ruta, lease retenido por error real.  
**Aceptación:** ningún fallo de apertura impide volver de manera segura.

### T17 — Cambio de servidor, calidad y renovación de URI

**Prioridad:** P1. **Dependencias:** T14–T16.  
**Archivos:** `application/player/source_switching/playback_source_switch_service.dart`, coordinador, `app/player/player_quality_panel.dart`.  
**Hacer:** conservar posición (objetivo Δ≤2 s cuando los medios permiten seek comparable), Play/Pause, audio/subtítulo equivalente y estilo; validar nuevos medios renovados sin romper política de URI; manejar respuestas nativas tardías y fallos con rollback. Distinguir pista de video local, calidad de servidor y ABR HLS/DASH.  
**Pruebas:** A→B→A, pausa, seek pendiente, Stop durante cambio, fallos en orden, URL renovada, selección obsoleta, subtítulos, HLS adaptativo si disponible.  
**Aceptación:** no hay recursos duplicados ni estado de sesión perdido injustificadamente.

## BLOQUE E — Producto e integración

### T18 — Progreso de reproducción por episodio

**Prioridad:** P1. **Dependencias:** T05 y T15.  
**Archivos:** `application/catalog/catalog_service.dart`, `domain/progress/**`, `data/local_db/drift_playback_progress_repository.dart` y migraciones si necesarias.  
**Hacer:** sustituir dependencia lógica de `episode:1` demo por identidad de episodio real; guardar posición, duración, timestamp y revisión, recuperar tras reinicio, conservar datos legados y evitar overwrite de checkpoints nuevos por escrituras obsoletas. No persistir URLs firmadas.  
**Pruebas:** episodios 1/2 distintos, reanudación, varios coordinadores, completado, offline, migraciones compatibles.  
**Aceptación:** progreso por capítulo independiente y estable, sin login.

### T19 — Home, ficha, «Continuar viendo» y «Enlaces»

**Prioridad:** P2. **Dependencias:** T18.  
**Archivos:** `app/home/home_data.dart`, `app/catalog/detail/**`, shell y repositorios necesarios.  
**Hacer:** poblar realmente `HomeContent.episodes`; mostrar progreso, duración, CTA reanudar, omitir filas vacías; distinguir episodios catalogados/no disponibles; mostrar etiquetas proveedor/idioma/servidor/cualidad conocida. En «Enlaces» mostrar **animes relacionados** (precuelas, secuelas, películas, especiales y spin-offs) como carátulas compactas navegables, **no** URLs externas. Mantener AMOLED y acciones por dispositivo aprobadas.  
**Pruebas:** volver del player, historial real, biblioteca offline, TV D-pad, Android 3 puntos, desktop hover, fichas relacionadas.  
**Aceptación:** navegación coherente sin falsificar progreso ni disponibilidad.

### T20 — Opcionales del player en ruta externa

**Prioridad:** P2. **Dependencias:** T15–T19.  
**Archivos:** `app/player/provider_playback_route.dart`, `spike_player_module.dart`, `data/aniskip/**`, `data/opensubtitles/**`.  
**Hacer:** inyectar AniSkip cuando exista ID MAL verificado, OpenSubtitles si configuración válida, subtítulos externos/estilo/delay, pistas audio/video, modo Nerd, teclado/fullscreen, fallbacks, sin bloquear playback si el opcional está indisponible. No inventar IDs MAL ni API keys.  
**Pruebas:** componente no configurado, fuente hardsub, pista tras cambio, modo Nerd, reinicio, overlay, cierre.  
**Aceptación:** ruta productiva aprovecha las capacidades ya probadas en la demo sin duplicar motor.

## BLOQUE F — Evidencias, rendimiento y auditoría

### T21 — Matriz de 70 títulos distintos

**Prioridad:** P1 (gate final). **Dependencias:** T11–T20.  
**Hacer:** probar títulos variados (populares/antiguos/recientes, largos, temporadas, películas, OVA/especiales, títulos JP/romaji/EN, doblajes/subtítulos ES/EN/JP/RU cuando estén realmente disponibles) distribuidos entre proveedores verificados. **70 títulos únicos y 70 reproducciones efectivas**, no 70 episodios de un mismo anime. Validar identificación, episodio real, servidor, fuente, apertura, primer frame, avance, sonido si existe, cierre y errores; seek representativo. Limitar tasa para no sobrecargar orígenes.  
**Matriz de evidencia** (CSV y Markdown, sin URLs secretas): `title`, `AniListId`, `episode`, `provider`, `server`, `audioLanguage`, `subtitleLanguage`, `format`, `firstFrameObserved`, `positionAdvanced`, `audioObserved`, `closeResult`, `testDate`, `status PASS/FAIL/BLOCKED`, `evidencePath`.  
**Aceptación:** ≥70 PASS distintos; si menos, publicar conteo real y dejar T21 `BLOCKED` o `TESTING`, nunca `DONE`.

### T22 — Batería automática y regresiones

**Prioridad:** P1. **Dependencias:** todas las tareas funcionales relacionadas.  
**Hacer:** tests de domain (IDs/idiomas/episodios), application (breaker, fallback, concurrencia, progreso), data (HTTP, parsing, redirects, media con headers), motor (MP4/HLS/DASH si soportado, primeros frames, seek, error nativo), widgets (ficha, fuentes, estados, cierre, teclas, responsive). Separar suites deterministic/live; las pruebas online no deben hacer fallar de forma impredecible la CI ordinaria.  
**Aceptación:** suite focal y CI pasan; los tests reales no son sustituidos por fakes.

### T23 — Rendimiento y recursos

**Prioridad:** P2. **Dependencias:** camino de reproducción funcional.  
**Hacer:** medir RAM, CPU, FPS, frames perdidos, sincronía A/V, arranque, latencia búsqueda/episodios/fuentes/primer frame, cambio de servidor y dispose. Perfil de máquina modesta; caché acotada, deduplicación, cancelación, decodificación de imágenes al tamaño mostrado. No optimizar a ciegas ni agregar Chromium/procesos residentes por proveedor sin justificación.  
**Aceptación:** no regresión relevante sin explicación y comparación medida contra baseline.

### T24 — Auditoría profunda final y cierre del trabajo

**Prioridad:** P1. **Dependencias:** T00–T23.  
**Hacer:** auditor independiente siguiendo las reglas del proyecto. Revisar seguridad, arquitectura, modularidad, contratos, matching, episodios, proveedores, playback, fallback, URL/headers, cancelación, persistencia, UI/TV/Android preparación, rendimiento y docs. Corregir P0/P1 y reauditar. Actualizar índices, README, estado y handoff; registrar métricas reales, resultados de CI y 70 títulos.  
**Aceptación:** no P0/P1 abiertos, todos los gates demostrados y T21 realmente 70/70 o más. Si falta gate, no declarar cierre global.

## 3. Procedimiento mínimo para sustituir código

1. Identificar archivo y responsabilidades actuales.  
2. Identificar contratos, consumidores y pruebas.  
3. Reproducir el defecto.  
4. Diseñar reemplazo mínimo coherente.  
5. Añadir regresión antes o junto a corrección.  
6. Modificar implementación, preservar cambios ajenos.  
7. Ejecutar tests focalizados y análisis.  
8. Validar comportamiento nativo/GUI si corresponde.  
9. Auditar diferencia y dependencias.  
10. Retirar código obsoleto, documentar.  
11. Actualizar status y handoff.

## 4. Guía de verificaciones

Desde la raíz, y siempre tras comprobar el toolchain local vigente (los comandos son ejemplos, no resultados):

```bash
# Diagnóstico de archivos y diff
 git status --short
 git diff --check

# CI y límites de capas
 dart scripts/check_imports.dart --root "$PWD"
 bash scripts/ci.sh

# Tests clave (desde app/)
 cd app
 flutter analyze --no-pub
 flutter test --no-pub test/domain/playback_provider_contract_test.dart \
   test/application/playback_provider_manager_test.dart
 flutter test --no-pub test/data/player/providers/public_playback_provider_test.dart
```

Pruebas con medios externos, libmpv y GUI se ejecutan solo con entorno y fuentes disponibles/autorizadas; registrar comando, ruta de evidencia y resultado. Las pruebas de T21 requieren matriz de 70 títulos y validaciones observadas, no el simple éxito del comando.

## 5. Archivos de control

- `KONGROO-RECONSTRUCTION-PLAN.md`: este documento, fuente de tareas y gates.
- `KONGROO-RECONSTRUCTION-STATUS.md`: tablero de estados, evidencia, conteos y auditoría actual.
- `KONGROO-RECONSTRUCTION-HANDOFF.md`: punto de reanudación sin releer toda la historia.
- `KONGROO-RECONSTRUCTION-AUTOMATION.md`: prompt para configurar una automatización **en Codex**; no se ejecuta solo por existir.

La ejecución **se detiene después de un bloque**. Una nueva ejecución programada puede continuar tras leer el estado. Si la automatización no está habilitada en el cliente, lanzar manualmente el prompt. No prometer trabajo nocturno sin un proceso o automatización configurados realmente.
