# KONGROO — OC-02: MISIÓN AUTÓNOMA DE RECUPERACIÓN Y ARQUITECTURA REAL DE FUENTES/HOSTS

**Versión:** 1.0 · 16 de noviembre de 2026  
**Destinatario:** agente principal de OpenCode, con capacidad para leer/editar/ejecutar en el proyecto local **únicamente dentro de las autorizaciones del propietario**.  
**Orden:** **EJECUTAR**, no redactar otra propuesta. Prioridad máxima: reparar catálogo, carátulas y episodios; después obtener reproducción real sin destruir el reproductor de Kongroo.  
**Proyecto:** Kongroo, aplicación Flutter/Dart, catálogo AniList opcional, persistencia Drift, motor existente media_kit/libmpv.  
**Plataformas objetivo del núcleo:** Linux, Android, Windows. Fedora Linux es el entorno inicial de ejecución gráfica.

> Esta misión reemplaza las instrucciones experimentales anteriores que contradigan sus prioridades. Preserva `AGENTS.md`, las políticas de seguridad y de auditoría del proyecto y las decisiones aprobadas que no se hayan sustituido explícitamente. Ninguna frase de «autonomía» autoriza evadir controles de acceso, hacer push sin autorización, borrar datos ni modificar el SO global.

---

## 0. Instrucción ejecutiva — lo que el propietario espera

Durante varias sesiones, Kongroo acumuló tests verdes y documentación, pero el producto sigue sin funcionar correctamente: faltan carátulas, capítulos y reproducciones externas reales. El nuevo agente no debe reproducir este patrón.

Tu trabajo es **diagnosticar y corregir el código ejecutándolo en el entorno Fedora de Kongroo**, manteniendo como prioridad estricta que la aplicación siga funcionando y que el reproductor actual no sea reemplazado ni dañado. Utiliza soluciones ya probadas por aplicaciones abiertas, adaptándolas al proyecto, en vez de desarrollar una sucesión de extractores frágiles para páginas de catálogo.

### Condiciones de aceptación de alto nivel

1. En la app real se muestran metadatos y carátulas de títulos públicos reales, sin obligar a vincular cuenta AniList, y las rutas de error/caché son correctas.
2. En una ficha se muestran datos de episodios honestos: conteos de catálogo no se presentan como capítulos/servidores verificados; existe una ruta funcional para pedir fuentes del episodio seleccionado.
3. El núcleo distingue `Anime metadata`, `episode index`, `Source provider`, `Video host resolver` y `Playback engine`. No necesita navegar por portales de anime si puede obtener índice y medios por interfaces públicas y permitidas; tampoco presupone que un hostname de video conoce por sí solo qué capítulo es.
4. El motor **único** sigue siendo `media_kit/libmpv` para media nativo y se mantienen controles, fullscreen, subtítulos, persistencia y lifecycle. Si una fuente legítima solo es iframe, explora reproductor web **como adaptador de plataforma opcional**, no como sustitución destructiva del engine.
5. Una fuente solo se marca `PLAYABLE_CONFIRMED` después de observar **video real en la ventana**, reproducción temporal, audio si corresponde y cierre correcto. HTTP 200, URL, pista detectada o tiempo avanzando no son éxito.
6. Hay pruebas offline, integración real en Fedora, diagnóstico reproducible, y evidencia honesta de lo todavía no validado. Core preparado para Linux/Android/Windows sin acoplarlo a GTK, Media3, WebView2 ni otras APIs de sistema.

### Marco de autonomía

- **Autorizado**: inspeccionar el repositorio autorizado; consultar documentación pública y repositorios primarios; ejecutar comandos/test/build dentro del repo; crear o modificar Dart, tests, READMEs y fixtures; corregir bugs; ejecutar pruebas gráficas con herramientas realmente disponibles; tomar decisiones técnicas locales y repetir ciclos de depuración.
- **Sin pedir confirmación para cada paso de código**. Continúa después de cada hito hasta completar los gates que puedas ejecutar de forma segura en la sesión. Si una ruta bloquea, cambia a un objetivo independiente de la lista, no cierres toda la misión prematuramente.
- **No autorizado**: borrar trabajo ajeno, `git reset --hard`, `git clean -fd`, reescrituras de historial, commit/push/publicar sin orden explícita, crear remotos, introducir secretos, salir de la raíz del proyecto, instalar software global o cambiar permisos de KDE/root, suplantar sesiones, derrotar CAPTCHA/DRM/autenticación/Cloudflare u otros controles, ejecutar arbitrariamente scripts descargados, copiar código sin licencia compatible.
- No prometas funcionar tras apagar el PC ni continuar en segundo plano: si la sesión o recurso termina, guarda `STATUS/HANDOFF` y una orden de reanudación mínima. No realices bucles sin límite ni gastes horas repitiendo el mismo HTTP 403.
- Si detectas algo que requiere acción humana expresamente reservada (p. ej. diálogo KDE de autorización, nuevo sistema de paquetes, commit/push), **no lo simules**: documenta el requisito y continúa otros subtrabajos. Si no queda trabajo independiente, entrega el bloqueo concreto y la última evidencia.

---

## 1. Contexto obligatorio y estado de partida comprobado

Antes de escribir código:

1. Comprueba el directorio actual con `pwd`, `git rev-parse --show-toplevel`, `git status --short`, rama, `git log -n 8 --oneline`, `git remote -v`. La raíz comunicada por el proyecto es `/home/kyouma/Vídeos/PROYECTO ANIME`; **confirma la raíz real**. No busques carpetas fuera de ella ni sigas symlinks fuera.
2. Lee `AGENTS.md`, `ARCHITECTURE.md`, `docs/memory/PROJECT_STATE.md`, `docs/memory/AI_HANDOFF.md`, `docs/ai-system/AUTONOMY_POLICY.md` y los README de los módulos que vas a tocar. Consulta `.agents/skills/kongroo-deep-audit/SKILL.md` antes de modificaciones sustanciales.
3. Obtén el commit actual con `git rev-parse HEAD` y contrástalo con `origin/main` **sin sobreescribir el árbol local**. La revisión pública que originó esta misión corresponde a `6cc3e5e075760b845eac26fb48b1424cd38b5fa1` en `main`, del 16 de noviembre de 2026. Si tu local ya cambió, audita la diferencia y ajusta hipótesis.
4. Lee el **diagnóstico adjunto** `KONGROO_AUDITORIA_GITHUB_Y_ANIKENTV_2026-11-16.md` (el propietario debe colocarlo junto a este documento) y verifica cada hallazgo contra el código local. El diagnóstico es una **inspección estática**; no es prueba de reproducción.
5. Preserva cambios sin stage ajenos. Si se necesitan puntos de restauración, emplea copia de seguridad **dentro de `.ai-local/`** o diff de rutas específicas; sin snapshots de secretos ni repos anidados.
6. Verifica los ejecutables ya instalados y SDK disponible (`flutter --version`, `dart --version`, `ffprobe -version`, `mpv --version` solo si existen). No instales ni actualices programas globales. Usa el entorno SDK aislado **si ya existe en el proyecto**.
7. Registra inventario en `docs/ai-system/missions/OC02-EXECUTION-STATUS.md` incluyendo SHA, árbol sucio, versión Flutter/Dart, herramientas disponibles, pruebas base y problemas reportados por el propietario.

### Lo que YA se sabe del último push público

- `app/lib/app/catalog/catalog_module.dart`: proveedor de metadatos principal AniList.
- `app/lib/data/anilist/anilist_client.dart`: GraphQL público, sin login obligatorio; `browseAnime` y `searchAnime`; por ID obtiene detalle, número de episodios y `streamingEpisodes`.
- `app/lib/data/anilist/offline_first_anime_catalog.dart`: caché de búsqueda y detalle, pero `browseAnime` remite directamente al remoto.
- `app/lib/app/home/home_data.dart`: espera popular, trending y biblioteca; construye `episodes = []` sin llenarla.
- `app/lib/app/home/home_screen.dart`: timeout global de 12 s, que puede enmascarar cuál subrequest falló.
- `app/lib/app/home/home_artwork.dart`: `Image.network` con fallback silencioso.
- `app/lib/app/catalog/detail/anime_detail_tab_content.dart`: crea tarjetas 1..N del total conocido, aunque cada capítulo no tenga `EpisodeRef` ni metadata confirmada.
- `app/lib/data/player/providers/playback_providers_module.dart`: un provider `AnimesDigital` y un `DirectMediaHostResolver`, registrados en `PlaybackProviderManager`. No son dos hosts independientes.
- `docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md`: tests y análisis históricos pasan; fuente HLS externa entregó manifiesto/segmento, pero video negro con error de decodificación; la imagen externa **NO** fue verificada.
- `app/test/data/anilist/anilist_live_smoke_test.dart`: smokes de AniList **opt-in** y omitidos en la ejecución predeterminada.
- En el árbol público `app/` solo hay runner `linux/`. No afirmes builds Android/Windows sin comprobar infraestructura.

**Prohibido concluir “es copyright” o “son codecs” sin traza.** Identifica el punto exacto de fallo. Un problema de codec de video no explica, por sí solo, que `Image.network` no cargue carátulas.

---

## 2. Modelo mental correcto: cómo funcionan AnikenTV, Anilili, Zangetsu y Kuroko

### A. No confundir categorías

- **Metadata catalog**: título, poster, banner, sinopsis, estudios, relaciones, conteo; puede venir de AniList, sin exigir OAuth para lectura pública. No es host multimedia.
- **Episode index**: relación `anime id ↔ temporada/entrada ↔ capítulo real ↔ external episode id` y etiquetas sub/dub/idiomas observados. Puede venir de una API, un índice público o un provider.
- **Source provider**: entiende dónde buscar episodios y obtiene los servidores/candidatos de un episodio. No reproduce nada.
- **Video host resolver**: toma un candidato (embed/URL/manifest/identificador) y, cuando esté públicamente permitido, lo normaliza a medio HLS/MP4/DASH, headers legítimos, subtítulos, variantes y fecha de expiración; o lo tipa como `embed`. No inventa episodios.
- **Playback engine**: recibe una `PlayableSource` ya tipada; abre, decodifica y presenta el video. En Kongroo es el motor existente `media_kit/libmpv` para medios nativos.
- **Platform embed renderer** (opcional): usa el WebView del sistema cuando una fuente realmente es un reproductor web. Debe ser reemplazable y desactivable, y no se convierte en un extractor que eluda permisos.

### B. AnikenTV — evidencia del ZIP del propietario

El archivo `anikentv-release.zip` contiene `anikentv-release/app/src/main/java/com/miruronative/`. Aunque el nombre del ZIP dice AnikenTV, su README se titula `Anilili` y describe una implementación Android/Kotlin/Media3.

- `data/MiruroRepository.kt` usa `miruroEpisodes` + `anivexaEpisodes` y los combina; la resolución usa `provider` y `category` para pedir la fuente a la familia correcta.
- `data/MiruroRepository.kt::resolveSources` prueba el proveedor preferido y luego alternativas, en un presupuesto limitado de intentos. Ejemplo de **selección/fallback de backend**, no un sitio web fijo por episodio.
- `data/ProviderCatalog.kt` diferencia Miruro y Anivexa, así como HLS nativo y embeds tipo iframe.
- `data/remote/AnivexaClient.kt::getSources` hace dispatch entre implementaciones de cada proveedor. Ojo: su `getEpisodes` puede sintetizar filas con conteo AniList, sin demostrar disponibilidad. **No heredar esa falsedad de inventario**.
- `data/remote/PipeBridge.kt` depende de Android WebView para una operación de contexto de página. Esto demuestra que no todo se obtiene directamente del CDN. No portar el puente Android a Linux sin una alternativa autorizada y un adaptador de plataforma.
- `ui/watch/WatchViewModel.kt` junta episodios, decide el capítulo activo, busca una fuente viable, recuerda posición y cambia de servidor. La reproducción final es una responsabilidad independiente.

**Restricción de vigencia:** ese ZIP usa un protocolo Miruro de tipo pipe. El Anilili público posterior documenta `MiruroCatalogApi.kt` y API REST distinta. Usa ambos para comprender el diseño, pero **verifica la especificación actual de cualquier endpoint**. No vuelvas a portar una ruta histórica sin test.

### C. Zangetsu — separación de extensiones y extractores

Proyectos públicos:

- https://github.com/Spyou/Zangetsu
- https://github.com/Spyou/zangetsu-providers

Un repositorio de fuentes publica un manifiesto `index.json` con ID, nombre, tipo, idioma, versión y archivo por provider. Dentro de la aplicación, `extractors/` contiene resolutores por hostname como `mp4upload`, `okru`, etc.; el modelo diferencia **qué portal conoce el episodio** y **qué host entrega el medio**. En `lib/core/di/injector.dart` se registran extractores antes que fuentes.

**Adaptación:** registrar metadatos estáticos y módulos Dart (o un sistema futuro de plugins cuidadosamente aislado) con una interfaz estable. **No instalar ni ejecutar JS remoto automáticamente**; hacerlo requiere sandbox, firma/verificación de origen, permisos, política de red, revocación y pruebas de supply chain. Comprueba licencia antes de reutilizar contenido.

### D. anime-sh, anipy-cli, ani-cli, GoAnime — la lección de la terminal

- https://github.com/Anime123450/anime-sh — providers/resolvers, health y canary, mpv por separado; una fuente caída no debería derribar toda la aplicación.
- https://github.com/sdaqo/anipy-cli — contrato de `ProviderStream` con URL, idioma, resolución, subtítulos, referer.
- https://github.com/pystardust/ani-cli — orquestación desde shell y entrega a reproductor; usar como lectura de referencia, sujeto a licencia.
- https://github.com/alvarorichard/GoAnime — clientes de fuente, gestión de proveedores, pruebas y health.

No es requisito instalar esas aplicaciones ni copiar sus códigos. Reutiliza **patrones** y crea test A/B: un medio de prueba compatible reproducido por mpv CLI, si ya existe, comparado con el mismo recurso dentro de Kongroo. Si no existe CLI, utiliza harness Dart/libmpv y no inventes que el control se ejecutó.

### E. Kuroko.cc — coordinación de fuentes, no API ajena reutilizable

La documentación pública https://kuroko.cc/help describe un endpoint propio `api.stream`, fan-out por proveedores y media por proxy firmada `/media/<token>`. Esto es un **modelo conceptual de backend/orquestador**, no una API de libre uso para Kongroo: sus tokens, URLs firmadas, controles de acceso y recursos no son compartibles por deducción. No uses el backend privado de otra app para evitar desarrollar integración propia.

### F. Regla de eficiencia de investigación

**No comiences por visitar a ciegas 30 portales**. Sigue este orden:

1. Inspecciona implementaciones open source concretas y su código de contratos/provider/host.
2. Identifica una API o índice público vigente, documentado o realmente observado; comprueba su política de uso.
3. Verifica una ruta concreta y mínima de catálogo → episodio real → servidor antes de implementar 600 líneas.
4. Si el proveedor ya publica URL de medio, no vuelvas a resolver su portal; identifica el host y valida un HLS/MP4 legítimo.
5. Si publica iframe, conserva `kind=embed` y decide si un adaptador web soportado puede manejarlo; no uses esa URL como MP4.
6. Si HTTP 403/401/402, CAPTCHA, DRM o challenge bloquea el recurso, registra el estado, **no evadas la medida** y evalúa otro proveedor/host independiente con protocolo permitido.
7. Evita falsas cantidades: un mismo host con sub/dub/varias resoluciones no son proveedores independientes.

---

## 3. ARQUITECTURA OBLIGATORIA DEL NUEVO NÚCLEO

Respeta primero las carpetas y contratos reales existentes. Este esquema es **conceptual**: no dupliques un directorio solo porque otro proyecto lo usa.

```
UI catálogo / UI reproductor
    ↓                         ↑ estados tipados
CatalogService              PlaybackProviderManager
    ├─ MetadataProvider        ├─ EpisodeSourceAdapter registry
    │     └─ AniList           │    ├─ provider_a/
    └─ EpisodeIndexService     │    └─ provider_b/
          └─ Merge/availability├─ VideoHostResolver registry
                               │    ├─ direct_media/
                               │    ├─ host_specific/
                               │    └─ embed_support/
                               ├─ source ordering / circuit breaker / cache
                               └─ PlayableSource → Player adapter existente
                                                    └─ media_kit/libmpv
                                   └─ (opcional) PlatformWebEmbedAdapter
                                      Linux / Android / Windows
```

### Contratos que debes mantener/evolucionar, no destruir

- `app/lib/domain/player/providers/anime_identity.dart`: identidad externa, alias, resultado de matching y evidencia; reconciliar AniList/MAL/ID de fuente conservadoramente, sin colisiones.
- `app/lib/domain/player/providers/episode_source.dart`: `SourceAnimeMatch`, `EpisodeRef` y adaptadores; un `EpisodeRef` no es un URL de reproducción.
- `app/lib/domain/player/providers/playback_provider_contract.dart`: capacidades, errores y cancelación.
- `app/lib/domain/player/providers/playback_source.dart`: candidatos, formatos, headers, idioma, serverId y procedencia.
- `app/lib/application/player/providers/playback_provider_manager.dart`: priorización, circuit breakers, caché, deduplicación, orden de fuente y fallback.
- `app/lib/data/player/providers/playback_providers_module.dart`: composition root central para registrar providers y resolvers versionados.
- `app/lib/data/player/engine/media_kit_spike_engine.dart`, `app/lib/app/player/provider_playback_route.dart`: protegidos por regresiones, sin segundo `Player` ni nueva state machine.

### Separación de estados

`catalog_item_found` ≠ `episode_announced` ≠ `episode_indexed` ≠ `source_candidate_found` ≠ `host_resolved` ≠ `network_200` ≠ `manifest_valid` ≠ `decoder_initialized` ≠ `first_video_frame_presented` ≠ `playable_confirmed`.

No conviertas un estado en otro por inferencia. El origen de cada metadato, idioma, quality y fecha debe poder explicarse.

### Contrato sugerido de disponibilidad (extender el existente)

```
EpisodeAvailability {
  episodeIdentity,        // id estable dentro de anime/temporada
  sourceEpisodeRefs[],   // filas confirmadas por un índice de episodios
  metadata,              // AniList u otra fuente de metadatos, si existe
  state,                 // announced | indexed | hasCandidates | confirmedPlayable | blocked | unknown
  lastCheckedAt,
  evidence,
}
```

No añadas estados desproporcionados si ya existe un equivalente; utiliza tipos exhaustivos y tests.

### Portabilidad Linux/Android/Windows

- `domain` y `application` deben ser Dart multiplataforma sin imports GTK/Win32/Android.
- `data` puede usar transporte HTTP portable (`Dio`, `dart:io` con controles apropiados) sin asumir filesystem Linux; SQLite/Drift detrás de contratos existentes.
- UI y reproductor deben consumir modelos neutrales; si WebView es necesario, implementa `PlatformEmbedView` como puerto con adaptadores Linux (WebKitGTK), Windows (WebView2), Android (Android WebView), según dependencias realmente mantenidas y ensayadas. **No instalar plugin a ciegas ni asumir que el paquete soporta las tres plataformas en esta versión**.
- Existen actualmente archivos runner Linux en el repositorio; Android/Windows necesitan un plan de generación controlada y pruebas cuando haya toolchain. Nunca marques `TESTED` lo que no se compiló.
- Compatibilidad arquitectura ≠ éxito de compilación ≠ funcionamiento real en dispositivos.
- Presupuesto de hardware: minimizar requests, caché con TTL, layouts lazy, no mantener WebView/capturas/navegadores residentes si no están usándose, evitar polling constante y múltiples player instances. Medir CPU/RSS/latencia primero en Fedora y posteriormente en hardware limitado.

---

## 4. FASE R0 — BASELINE Y LIMPIEZA CONTROLADA, NO OTRA DEMOLICIÓN

1. Ejecuta las suites disponibles de catálogo, home, source-manager, rutas del reproductor y engine **sin hacer `flutter pub get` si no se necesita**. Registra exit code y número de PASS/SKIP; usa `--no-pub` si el repo lo requiere.
2. Obtén una captura de Home y, si es posible, una de la ficha. Si Wayland MCP no está disponible, evalúa métodos del proyecto ya autorizados. **No cambies socket/permisos ni aceptes diálogos KDE por el usuario**. Si no hay captura, anota `GRAPHICS_NOT_VERIFIED`.
3. Haz un inventario de archivos activos y archivos archivados de las misiones S0, S0-R y S0-S. El commit público de referencia ya eliminó AnimeHeaven y conserva documentación histórica. No vuelvas a borrar pruebas útiles o fakes necesarios.
4. Identifica imports muertos, registros inaccesibles, proveedores duplicados, código aislado, métodos sin caller y dependencias de versiones antiguas. **Eliminar exclusivamente lo demostrado obsoleto**, después de probar y documentar. El saneamiento de artefactos es diferente del saneamiento de source code; no borrar documentación histórica que explica fallos.
5. Evita editar `media_kit_spike_engine.dart` y `SpikePlayerPage` en R0. No modifiques `pubspec.lock` salvo cambio imprescindible con análisis de compatibilidad.
6. Crea tabla `conservar / reparar / retirar / archivar` con rutas y evidencia. Finaliza R0 antes de agregar nuevos proveedores.

**Gate R0:** baseline reproducible, inventario, runtime sin duplicados, cambios existentes preservados y ni un test del player empeorado por limpieza.

---

## 5. FASE R1 — REPARAR CARÁTULAS, HOME Y CATÁLOGO (PRIORIDAD ABSOLUTA)

### R1.1 Reproducción del fallo actual

Instrumenta una ejecución real de `flutter run -d linux` con el entrypoint `app/lib/main.dart` sin alterar la BD del usuario; usa override a `.ai-local/` cuando sea útil y permitido. Registra de forma segura por cada capa:

- GraphQL AniList: operación (`BrowseAnime`, `SearchAnime`, `AnimeById`), HTTP status, duración, `errors[]` sanitizados y cantidad de resultados.
- Parsing: ID, título, existencia de cover/banners, esquema/campo faltante y recuentos; no registrar información privada.
- Download poster/banner: URI normalizada sin query sensible, status, tipo MIME, tamaño de bytes, decodificación Flutter, error de imagen, dimensiones obtenidas, cache hit/miss.
- Home: tiempos separados de populares, tendencias, biblioteca, lectura local y tiempo total frente al timeout actual.
- Widget: ¿hay resultados con URLs? ¿están en pantalla? ¿se vuelve negro por errorBuilder? ¿la red falla o la imagen es incompatible?

No confundir `flutter_test` con pruebas HTTP reales: el entorno de widgets puede interceptar HTTP. Usa un harness Dart puro o una prueba de integración realmente conectada a la red, opt-in, y mantén unit tests deterministas.

### R1.2 Correcciones necesarias según evidencia

- Verifica que `AniListClient` mapea `coverImage.extraLarge` y `bannerImage` vigentes; si hay respuestas malformadas, evita que una entrada dañada suprima todo el feed y registra la causa con tipo.
- Cambia Home para que no dependa de que **todas** las solicitudes finalicen satisfactoriamente. Permite render parcial y estados visibles por sección. Un fallo de biblioteca no debe ocultar un feed de AniList que sí fue devuelto.
- Reemplaza el timeout global de 12 s como único diagnóstico por presupuestos por recurso, cancelación y reintentos limitados. No agregues esperas indefinidas.
- Implementa un cache real del browse público en Drift o cache disponible de forma bounded con TTL y stale-while-revalidate. Mantén etiquetas `offline`, `stale`, `loading`, `error`, y botón de reintento. No inventar carátulas de títulos no cacheados.
- Instrumenta `HomeArtwork`/otras `Image.network` con fallbacks coherentes y contadores de fallo. Usa cacheWidth/Height sensatos para equipos modestos y comprueba memory budget. No usar imágenes stock como sustituto silencioso.
- Revisa `loadLibrary`: si refresca N títulos serialmente, no debe bloquear el render inicial ni saturar el rate limiter de AniList.
- Comprueba que la cuenta AniList **no** sea obligatoria para leer catálogo público. OAuth seguirá completamente opcional.
- Si detectas bloqueo de la API/CDN, distingue conectividad, rate-limit, URL, TLS, redirect y políticas del servicio; implementa fallback **permitido** de caché o metadata provider alternativo solo si tienes licencia/acceso/contrato demostrado.

### R1.3 Pruebas de regresión

- `browse` correcto con cover URL, con banner ausente y con una entrada con imagen inválida.
- Popular responde y trending falla; biblioteca falla y popular funciona; red cae con caché previa y sin caché.
- Carga lenta >12s: la UI presenta contenido parcial o recuperación y no se bloquea para siempre.
- `Image.network` HTTPS responde imagen válida (smoke opcional), error HTTP y MIME HTML; error no oculta toda la página.
- 1, 20 y 100 entradas sin jank extremo y sin carga agresiva en background.
- Evidencia gráfica en Fedora con varios títulos reales; si no se logra por falta de control gráfico, no marcar gate visual como superado.

**Gate R1:** Home muestra posters y al menos un título público real visualmente comprobado; detalles y búsqueda siguen vivos; degradación offline y errores tienen comportamiento correcto y probado. Si falla un servicio externo, conservar estado honesto y seguir con trabajo seguro independiente.

---

## 6. FASE R2 — LISTAS DE EPISODIOS VERDADERAS Y NAVEGACIÓN COMPLETA

### Diagnóstico y refactorización quirúrgica

- La fuente de metadatos AniList indica conteo y `streamingEpisodes` (a menudo parcial o de un sitio específico). No es una base de datos exhaustiva de episodios reproducibles.
- `AnimeDetailTabContent._EpisodesTab` genera tarjetas numéricas `1..N` aunque no exista `EpisodeRef`, y los botones se vinculan a `_playEpisode(number)`; es una política de UI, **no una verificación de fuentes**.
- `CatalogHomeSource.load` retorna `episodes` vacío siempre; `HomeSections.showResume` es diálogo placeholder. Reparar la capacidad conforme a progreso local real y fuentes disponibles; no reemplazar por datos falsos.

### Implementa

1. `EpisodeIndexService` / agregador existente que reciba ID AniList, títulos/alias, IDs externos y realice matching conservador con proveedores. No unir anime distintos por títulos parecidos; probar especiales, temporadas, películas, títulos romaji/inglés.
2. Modelo unificado que diferencie `episodeCount metadata`, `episode number`, `episode indexed` y `availability` del proveedor. La UI puede mostrar episodio anunciado pero **debe diferenciarlo** de uno con fuente y uno reproducible confirmado. No inventar thumbnail, idioma, calidad, dub o existencia de stream.
3. Carga incremental: primer conjunto/temporada; paginación lazy sin descargar 1000 capítulos antes de mostrar ficha. Maneja episodios especiales, números decimales y duplicados según contratos existentes.
4. Play desde ficha → `PlaybackEpisode` con identity → `PlaybackProviderManager` → fuentes reales o error tipado. Fuente no disponible: botón visiblemente inhabilitado o indicación contextual según el diseño aprobado; no simular éxito.
5. `Continuar viendo`: lectura real del repositorio de progreso y relación a episodio; al pulsar, pedir fuentes actualizadas y reanudar si son válidas. Si no hay fuente, mensaje y conservación del progreso.
6. Restaurar scroll, selección, posición y foco al regresar del reproductor, sin rutas duplicadas.
7. No bloquear ficha sin fuentes: **un anime puede tener metadatos sin episodios reproducibles**; la ficha debe seguir siendo usable.

**Gate R2:** fichas, episodios y carátulas funcionan con datos reales; statuses correctos, sin episodios falsamente confirmados; navegación/retorno y lista de progreso verificables; pruebas con series cortas, largas, sin capítulos, solo SUB, solo DUB y película.

---

## 7. FASE R3 — MOTOR DE PROVEEDORES Y HOSTS COMO EN APLICACIONES MADURAS

### Regla principal

**No metas 30 webs bloqueadas al código.** Para cada candidata, revisa primero la implementación upstream (Anilili actual, Zangetsu, anime-sh, GoAnime, anipy-cli) y valida un camino **públicamente permitido** hacia el índice de capítulos y los hosts. Prioriza APIs oficiales o publicadas y manifests directos cuando existan. Una URL firmada de otro servicio no se reutiliza sin permiso.

### Ciclo de incorporación de UN proveedor

1. Identifica contrato y metadatos: `id`, versión, idioma **declarado, no asumido**, categoría, capacidades, estado, base URI permitida, familia de backend y límites.
2. Comprueba protocolo actual y licencia de referencia; usa fixture de respuesta pública sin tokens ni datos personales. No copiar código GPL u otro sin revisión de compatibilidad de la licencia de Kongroo.
3. Implementa `searchAnime` → `listEpisodes`/`findEpisode` → `findEpisodeSources` como adapter **solo en carpeta específica**; no mezcles resolver de host ni engine.
4. Si hay source direct HLS/MP4/DASH, genera candidato `kind=media`. Si hay iframe, `kind=embed`. No infieras formato por respuesta HTML ni por nombre de archivo `.webp` sin inspección real.
5. Ejecuta contract tests, errores, nulos, cancellation, stale URL, headers, límites, normalización, 429, 403, 404, cambios de esquema, inputs maliciosos.
6. Registra el módulo en `PlaybackProvidersModule`, con versionado y health. No elimines adapters útiles porque el proveedor externo falló temporalmente; distínguelos de runtime roto o muerto.
7. Integra con UI existente y documento README con rutas exactas y evidencia.
8. Solo informa `PLAYABLE_CONFIRMED` si se completó la prueba real del gate R4. La inscripción del provider no es éxito de media.

### Ciclo de incorporación de UN resolver host

1. Recibe `SourceCandidate`, host, formato anunciado y headers autorizados. Verifica `supports` explícito.
2. Comprueba URI/allowlist/redirects/DNS/HTTPS, tamaños, MIME, vencimiento, loop y errores; evita SSRF e inyección en log.
3. Entrega `PlayableSource` y pistas/subtítulos confirmados sin reproducir nada. Distingue media nativo vs embed.
4. Comparte resolver entre **todos** los proveedores que utilicen el mismo host. Un host no es un proveedor de catálogo.
5. Tests con fixtures de medios, query strings, master/media playlists, redirects, IP privada, URLs temporales, segment paths y componentes rotos. Nunca resolver URLs no solicitadas dentro de la LAN.
6. No introduzcas un backend/proxy persistente por defecto; un proxy propio solo si existe necesidad técnica probada, política de acceso permitida, controles SSRF, costes, límites, pruebas y autorización para su despliegue.

### Alternativas cuando falla la vía principal

A. Provider público con API de episodio/servidor → resolver directo del host.

B. Índice público que ya devuelve manifiesto HLS/MP4 → normalizador de media y engine; no abrir páginas intermedias de más.

C. Provider devuelve iframe y el acceso web es legítimo → conservar `embed` y realizar spike de `PlatformEmbedView` aislado con permisos, memoria, seguridad y tres plataformas; sin romper player nativo.

D. Provider inaccesible/403/DRM → registrar motivo tipado, cooldown, alternativa independiente. No repetir la misma ruta hasta tener cambio observable (actualización upstream, disponibilidad externa o permiso).

E. Si hay fuentes de prueba autorizadas (mismo HLS que abre en otro reproductor), ejecutar A/B con `mpv` o `ffprobe` y Kongroo para diferenciar deficiencia del engine de contenido defectuoso.

F. Si no hay fuente autorizada reproducible en el entorno, continúa corrigiendo R1/R2, diseñando contracts/tests, y demuestra un pipeline con fixture controlado; **no falsifiques éxito externo**. Registra con precisión qué impide aceptar el gate y qué evento permitiría reanudarlo.

### Estrategia de selección/fallback

- Orden definido por preferencia explícita, salud real, compatibilidad de medio, idioma y calidad medidos, latencia, no por duplicar etiquetas.
- Un error de un host no debe deshabilitar 10 proveedores que lo usan, ni viceversa. Circuit breaker por origen apropiado, TTL y revalidación de URLs efímeras; cancelar requests previos al cambiar capítulo.
- Si un host falla tras iniciar playback, seguir con otro candidato real conservando posición dentro de tolerancia razonable, pausas y subtítulos; detectar loops y cerrar recursos de la sesión anterior.
- Una selección manual de servidor debe mostrar alternativas reales y no inventar idiomas de usuario por defecto.
- No cachear URLs firmadas pasado su vencimiento, ni guardarlas en logs persistentes.

**Gate R3:** arquitectura y registro limpios; mínimo dos adaptadores o familias de fuentes independientes y al menos un resolver reusable donde el acceso lo permita; tests completos; no contar nombres inventados o fakes como fuentes reales operativas. Si solo hay una viable, registrar estado parcial sin destruirla.

---

## 8. FASE R4 — LIBMPV: DIAGNÓSTICO DE VIDEO NEGRO SIN REESCRIBIR EL PLAYER

### Hechos existentes

En el commit inspeccionado, AnimesDigital logró un HLS real y un segmento MPEG-TS con HTTP 200 en ejecución reportada, pero libmpv no mostró frame y la UI reportó «The media could not be opened or decoded». `ffprobe` detectó una referencia HLS con extensión `.webp` rechazada por `allowed_segment_extensions`, sin demostrarse que sea la causa de libmpv. Además, la ruta de producto puede abrir la fuente antes de montar la superficie Flutter. **Ambas son hipótesis, no diagnóstico final**.

### Experimento obligatorio por capas

1. **Control local**: fixture reproducible dentro `.ai-local/`, con video realmente visible y audio esperado; valida apertura/seek/pause/cierre con el Player existente; conserva el baseline.
2. **Fuente externa**: capturar con seguridad status de manifiesto, content-type, lista de segmentos y firmas MIME, rangos HTTP autorizados y redirects; separar GET del manifiesto de fetch de segmento; no registrar tokens completos.
3. **Demux**: comparar mismos bytes/manifest en `ffprobe` si existe, `mpv` CLI si está instalado y el engine actual. Distinguir problemas de formato HLS, MIME, extensión, contenido HTML disfrazado y referencia no-media.
4. **Codecs**: leer `codec`, `video-params`, `videoWidth/Height`, lista de tracks, `hwdec`, logs de demuxer/decoder y errores nativos; no asumir que todos los H.264 son decodificables sin verificar perfil/pixel format.
5. **Render**: capturar `VideoController`, evento de primer frame, tamaño de textura y la ventana bajo Wayland; un evento interno no basta si la captura muestra negro. Probar orden de creación: attach antes de open vs open antes de attach, con **mismo archivo y código de comparación controlado**.
6. **Headers**: verificar que los headers del stream se transmitan al motor y sean válidos también para sub-playlists/segmentos autorizados; no sustituir cabeceras mediante spoofing ni inventar cookies.
7. **Cierre**: si el playback falla, confirmar dispose del Player y lease. Cambio de servidor conserva posición y no deja decodificador anterior vivo.
8. **Corrección mínima**: modifica un único punto causal si se demuestra. No desactives globalmente seguridad de FFmpeg ni relajes filtros de extensiones/HLS por un caso aislado sin verificar los segmentos. Toda opción de media debe ser configurable por fuente, validada y documentada.
9. **Reproducción gráfica**: captura donde se identifique una escena del archivo externo; observa segundos de movimiento y, cuando corresponda, audio. Registra fuente, fecha, plataforma, error previo/posterior, sin redistribuir material protegido ni subir screenshots/archivos a servidores externos.

**Gate R4:** al menos una reproducción externa de video visualmente confirmada dentro de Kongroo con cierre seguro; después segunda alternativa/fallback real cuando esté disponible. Todos los tests preexistentes de playback siguen pasando. No aceptar audio solo/avance o HTTP 200 como frame.

---

## 9. FASE R5 — INTEGRACIÓN DE PRODUCTO Y REGRESIONES

Verifica en la app Fedora real, sin modo demo:

- Inicio abre, muestra títulos reales, banners/carátulas y navegación; errores de red son localizados por sección.
- Búsqueda de título funciona con y sin cuenta AniList.
- Ficha muestra carátula, información, episodios y etiquetas honestas; sin filas falsas marcadas `Disponible`.
- Selección de episodio, consulta de candidatos, selector de servidor y reproducción en el motor **único**.
- Cambiar servidor conserva la posición y cierra correctamente recursos; fallback desde un host que falla; no pérdida silenciosa de audio/subtítulos.
- Volver a ficha recupera scroll y contexto; reentrar al reproductor no obtiene `PlayerBusy` por fugas.
- Biblioteca local y progreso siguen persistiendo; Home `Continuar viendo` se alimenta desde datos reales, no diálogo placeholder.
- Carga de carátulas y navegación sin sobrecarga: mediciones de tiempos de carga, picos RSS, CPU, memory-cache, actividad de red, jank y drops cuando puedan ser medidos correctamente.
- Pruebas negativas: sin conexión, DNS falla, HTTP 429, URL expirada, embed no soportado, subtítulo inexistente, episodio no publicado, ventana redimensionada, cerrar mientras carga, volver con back y cancelaciones concurrentes.

Mantén READMEs de carpeta con tabla de archivos, contratos, dependencias, pruebas y pasos para extender nuevos proveedores/hosts; actualiza `docs/memory/PROJECT_STATE.md`, `docs/memory/AI_HANDOFF.md`, `docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md`, sin inflar documentos repetidos.

---

## 10. Estrategia de pruebas y reportes (verificación, no «verde» por un mock)

### Tipos y evidencia

| Nivel | Propósito | ¿demuestra producción? |
|---|---|---|
| Unit tests | parsing, matching, estados, errores, cancelación | No, prueba contratos aislados |
| Contract tests | provider/resolver/manager/engine separados | No, permite refactors seguros |
| Integration test local | BD real, conexión UI, fixture mpv local | Parcial, valida partes internas |
| Live HTTP smoke opt-in | API pública, manifest, imágenes | No, valida transporte y esquema actuales |
| Video window live | cuadro presentado, movimiento, audio y cierre | Sí para esa fuente/entorno concreto |
| Full user journey | Home→ficha→capítulo→servidor→player→retorno | Sí para ese recorrido/entorno concreto |
| Android/Windows build/run | multiplataforma real | Pendiente hasta contar con SDK/dispositivos/herramientas |

**No transformar pruebas omitidas en éxitos.** La suite `anilist_live_smoke_test.dart` requiere habilitación explícita; el agente debe ejecutarla en entorno con red, registrar las solicitudes y respetar límites, o señalar la imposibilidad exacta. Para pruebas de imagen, comprobar HTTP + decodificación; una URL que comienza por `https` no es un poster visible.

### Orden sugerido de comandos (verificar flags/versiones locales)

- `git status --short`, `git diff --check`, `git diff --name-only`.
- `cd app && flutter analyze --no-pub`.
- `cd app && flutter test --no-pub test/data/anilist test/home test/catalog test/player`.
- Pruebas de integración/local opt-in siguiendo README del repo (no ejecutar endpoints de terceros en bucles ni subidas).
- `dart run ../scripts/check_imports.dart` **solo si esa invocación coincide con `scripts/README.md`**; preferir el comando documentado real.
- `python3 tools/ai/memory.py check` desde la raíz.
- `bash scripts/ci.sh` solo después de revisar si `pub get`/instalaciones están autorizados; las pruebas que requieren toolchains ausentes deben registrarse como `NOT_RUN`.

Registra **comando, exit status, timestamp, pass/fail/skip, artefactos y limitaciones**. Los resultados históricos no sustituyen corridas nuevas.

---

## 11. Protección de Git, documentación y portabilidad

- Jamás tocar indiscriminadamente `main` o el historial. Si el propietario quiere commits, pedir orden explícita; el permiso de lectura/escritura del código **no** es autorización de push.
- No copiar todo Anilili, Zangetsu o paquetes externos en el proyecto; adapta módulos necesarios de acuerdo con licencias verificadas. Una fuente de referencia no autoriza depender de APIs privadas.
- Mantener licencia/atribución de piezas realmente copiadas, si están permitidas, y licencias transitivas de medios/codec en empaquetado.
- Mantener los siete grupos modulares existentes y sus contratos públicos. Evitar archivo monolítico que concentre búsqueda, hosts, transporte, UI, caché, logs y engine. Para AnimesDigital, examinar el archivo de 661 líneas y separar responsabilidades **solo con tests de comportamiento**, no por estética.
- Restringir red a destinos públicos legítimos; validar redirects y DNS cuando se resuelven hosts externos; limitar tamaño de respuestas y requests; no permitir URL de red local o esquema arbitrario en manifests sin controles.
- Evitar log de cookies, tokens, rutas firmadas completas, contraseñas, historial personal o datos privados del usuario. Redacción por defecto.
- Preservar opción sin cuenta AniList. No crear flujo OAuth obligatorio ni introducir dependencia nueva a Supabase para cargar posters.
- Para Windows/Android, documentar las plataformas realmente cubiertas por los paquetes elegidos y adjuntar plan de runner/CI/hardware; no cambiarlo como excusa para retrasar la recuperación de Fedora.

---

## 12. Gestión de autonomía, tiempo, fallos y salida

### Bucle de trabajo obligatorio

```
Revisar estado real del repo
  → reproducir un defecto concreto
  → formular hipótesis medible
  → establecer prueba que falle / instrumentación
  → parche mínimo y modular
  → probar caso corregido + regresiones
  → registrar evidencia y decisiones
  → siguiente defecto sin volver al principio
```

Si una hipótesis falla, no repitas exactamente el mismo probe. Cambia una variable controlada, compara contra baseline y limita reintentos razonablemente. No dediques toda la ejecución a producir un nuevo informe sin reparación. No declares una fuente funcional si no produjo cuadro real.

### Documento de checkpoint obligatorio

`docs/ai-system/missions/OC02-EXECUTION-STATUS.md` debe contener después de cada milestone:

- Fecha, rama y SHA, archivos editados, estado del árbol, riesgos.
- Qué funciona **antes y después** con evidencia exacta.
- Pruebas corridas (pass/fail/skip), capturas/logs en `.ai-local/` cuando corresponda.
- Bloqueos externos versus defectos corregibles, última hipótesis comprobada.
- Próxima **acción técnica ejecutable**, con archivo y test específico para continuar.
- Mapa de fuentes: `registered`, `can_list_episodes`, `can_resolve_host`, `media_http_ok`, `frame_confirmed`, `unavailable`, `blocked`.

Al cerrar la sesión deja `AI_HANDOFF.md` actualizado con un comando de arranque para retomar **el siguiente paso**, no empezar toda la investigación otra vez. No afirmar que seguirás trabajando cuando la sesión ya terminó.

### Definición de éxito

**SUCCESS:** gates R0/R1/R2/R4/R5 con evidencia de producto real, player protegido, estado de modularidad y contratos de fuentes/hosts probado; plataformas no ejecutadas claramente diferenciadas, sin P0/P1 abiertos. R3 debe demostrar integración modular y diversidad de alternativas según accesibilidad real.

**PARTIAL (honesto, no aceptado):** uno o más gates incumplidos, por ejemplo posters sin verificación gráfica, episodios sin índice real o fuente de video sin frame. La existencia de impedimento externo no habilita declarar finalización.

**BLOCKED:** no existen pasos técnicos seguros restantes dentro de permisos/entorno; detalla exactamente el prerequisito y deja pruebas/informe. Evita seguir sin propósito.

El objetivo es calidad de proyecto grande: **código correcto, comportamiento observable, interfaces estables, seguridad, portabilidad, pruebas adversariales, rendimiento medido, documentación operacional y mantenimiento posible**.

---

## 13. Referencias y lectura priorizada (no investigación infinita)

| Prioridad | Fuente | Archivo/área que debes leer | Pregunta que debe contestar |
|---|---|---|---|
| P0 | Código Kongroo local | `app/lib/app/home/home_data.dart`, `home_screen.dart`, `home_artwork.dart` | ¿Por qué Home no muestra carátulas y progreso? |
| P0 | Código Kongroo local | `anilist_client.dart`, `offline_first_anime_catalog.dart`, `anilist_metadata_provider.dart` | ¿Quién responde 200/429/403 y qué falla al mapear/cargar la imagen? |
| P0 | Código Kongroo local | `anime_detail_tab_content.dart`, `anime_detail_page.dart` | ¿Qué filas de episodio son reales y cuáles placeholders? |
| P0 | Código Kongroo local | `playback_providers_module.dart`, `playback_provider_manager.dart` | ¿Qué adapters siguen operativos y qué limita el flujo? |
| P1 | ZIP AnikenTV o el análisis adjunto | `MiruroRepository.kt`, `ProviderCatalog.kt`, `AnivexaClient.kt`, `WatchViewModel.kt` | ¿Cómo separa índice, selección, hosting y playback? |
| P1 | Anilili actual | `MiruroCatalogApi.kt`, `MiruroCatalog.kt`, `ProviderCatalog.kt`, `AnivexaClient.kt` | ¿Qué protocolo/vía pública está vigente y qué es histórico? |
| P1 | Zangetsu | `index.json`, `extractors/_template.js`, `lib/core/di/injector.dart` | ¿Cómo se registra 1 host para muchos proveedores? |
| P1 | anime-sh | `src/anime_sh/providers`, `src/anime_sh/resolvers`, `tests` | ¿Cómo se hace smoke real, health y fallback sin acoplar mpv? |
| P2 | Kuroko help | Documentación `/help` | ¿Cómo funciona conceptualmente un fan-out y un proxy firmado? |
| P2 | Paquetes WebView | documentación oficial y plataforma concreta | ¿Hay plugin realmente mantenido compatible con Fedora/Windows/Android? |

**No investigues centenares de repositorios sin aplicarlos**: limita el primer barrido a estas fuentes. Añade otras solo cuando una hipótesis de implementación real lo exija, y documenta por qué.

---

## 14. ORDEN FINAL AL AGENTE

> Lee ambos documentos y la memoria local; confirma Git y protege al reproductor. Primero reproduce, diagnostica y repara **carátulas, Home, caché y episodios**, y limpia de manera controlada el runtime viejo de servidores. Después implementa una infraestructura modular de índices, providers y host resolvers basada en contratos probados de AnikenTV/Anilili/Zangetsu/anime-sh, no en visitas arbitrarias a portales. Integra fuentes nativas y, cuando sea necesario y permitido, modalidad iframe aislada por plataforma. Comprueba un **video realmente visible** con el reproductor `media_kit/libmpv` existente, validando cierre y regresiones; no inventes reproducción. Continúa autónomamente con el siguiente punto viable mientras la sesión y permisos lo permitan, actualizando los checkpoints, sin commit/push ni cambios globales no autorizados. No cierres la misión como completada hasta satisfacer los gates con evidencia verificable. **COMIENZA A EJECUTAR AHORA.**
