# Transferencia a otra IA

## Misión de los 9 proveedores · 2026-11-18 (GLM-5.3)

Leer la [misión del día](../ai-system/missions/ANILILI-9PROVIDERS-2026-11-18.md)
y la **documentación maestra** exigida:
[`app/lib/data/player/providers/README.md`](../../app/lib/data/player/providers/README.md)
(KONGROO — Proveedores y servidores de reproducción, 8 secciones).

Estado de los 9 registros automáticos:

- **animeav1 — RESUELTO (N4):** bug crítico arreglado (faltaba
  `sourceAlternatives`: el manager rechazaba sus fuentes multi-servidor con
  `invalidResponse` sistemático; tests previos no pasaban por el manager).
  VOE resuelto en vivo (`VoeVideoHostResolver` → HLS cloudwindow-route
  720p) y **motor verificado** con captura. Regresión por manager añadida.
- **allanime/-dub — protocolo client-crypto completo (N2 protocolo):** API
  migrada a `mkissa.to/api.mkissa.net`. Reconstruido con el módulo real del
  sitio ejecutado en Node: bootstrap (`x-aa-boot` = doble HMAC sobre máscara
  de build), `aaReq` AES-GCM con clave `partB^máscara`, hash de query
  actual `670bbf38...`, `tobeparsed` AES-GCM con clave dinámica. **El
  servidor aceptó el token reconstruido y se descifraron sourceUrls reales
  sub+dub (MP4 `Yt-mp4` 206/370 MB verificado).** Tras el volumen de la
  investigación la API exigió `NEED_CAPTCHA` (Turnstile) desde esta IP:
  clasificado `challenge` sin evasión (regresión dedicada); reproducción
  N4 pendiente de ventana sin captcha. Materiales por build en
  `AllAnimeBootMaterials` (build 190). `PlaybackRequestHeaders` acepta
  ahora `x-build-id`/`x-aa-boot` públicos validados.
- **miruro-catalog — bloqueo externo re-verificado:** 403 Cloudflare
  (`cf-mitigated: challenge`) en REST y pipe de los 4 orígenes; Anilili usa
  WebView real (prohibido). Sin acción legítima.
- **Los 5 operativos revalidados con motor** (SEEK-RESTORE 20 s → FRAME →
  ADVANCE → REOPEN): megaplay, megaplay-dub, anizone, animegg (espejo sub
  227251), animegg-dub (espejo dub 226001).
- **Regresión:** suite completa **401 aprobadas / 10 omitidas**;
  `flutter analyze` **0 hallazgos**. Sin commits ni pushes (HEAD `6cc3e5e`).
- Niveles finales: megaplay/megaplay-dub/anizone/animegg/animegg-dub/animeav1
  = **N4/N5**; allanime/allanime-dub = protocolo verificado con descifrado
  real, reproducción pendiente de captcha; miruro = N0 externo documentado.

## Integración de proveedores Anilili · 2026-11-17 (misión ANILILI, GLM-5.3)

Leer [la misión completa](../ai-system/missions/ANILILI-PROVIDERS-2026-11-17.md)
antes de tocar providers. Resumen del estado tras la misión:

- **MegaPlay/bee sigue operativo y MEJORADO**: misma prioridad y variante
  sub/dub, más fallback a la ruta `/stream/mal/{malId}/...` cuando la ruta
  AniList falla (404/403/sin data-id) y la identidad publica `idMal`; verificado
  en vivo (ruta MAL devuelve data-id y getSources completo) y con regresión
  dedicada (12/12 megaplay). 2Dhive solo embebe MegaPlay: no se duplicó su host.
- **AniZone integrado y verificado con motor** (N4): marcado actual Livewire
  (JSON escapado `\u0022`/`\/` en x-data/wire:snapshot y kPlayer), HLS directo
  `seiryuu.vid-cdn.xyz`, subtítulos solo `.ass` (el contrato VTT los descarta).
- **AnimeGG integrado y verificado con motor** (N4): pestañas
  `data-toggle="tab"` (sub/dub), MP4 progresivos jwplayer y HLS de embeds.
  **Hallazgo real**: vidcache throttlea por UA (~28 KB/s con UA de biblioteca);
  los candidatos llevan UA de navegador (A/B documentado). Seek en
  MP4 progresivo: `restoreStartPosition` pre-apertura falla
  (`PlaybackResumeFailure`, ya conocido de Commons); el seek se verifica
  durante la reproducción.
- **AllAnime integrado (N1/N2-búsqueda)**: búsqueda GraphQL en vivo OK con
  crosswalk `malId` (la API lo entrega como cadena) o título exacto. **Fuentes
  bloqueadas**: la API exige desde julio 2026 el token anti-scraping `aaReq`
  (GCM + clave rotativa epoch/partB+mask en bundle ofuscado 1,1 MB; valida
  lane/build/ventana). Respuesta live `AA_CRYPTO_MISSING` reproducida como
  regresión; el adaptador la traduce a `noSources` y el fallback continúa.
  ani-cli abandonó AllAnime en v5 por lo mismo; no se evadió el control.
- **Bloqueos demostrados (evidencia en la misión)**: ReAnime (HLS solo por
  flixcloud WASM/JS en WebView), AniNeko y AnimeKai (hosts caídos: TLS sin
  datos / timeout TCP en todos los mirrors), 2Dhive (sin contenido propio;
  su API `/api/hianime` responde "No streamable video playlist" para todos
  los títulos probados, incl. One Piece/Bleach), Miruro (Cloudflare 403, sin
  cambios), Senshi/AniBD/KickAssAnime/RareAnimes (no existen en el ZIP).
- **Infraestructura**: `PublicPlaybackHttp` ganó POST JSON acotado (search de
  AllAnime); `html_playback_parsers.dart` porta `NativeProviderParsers.kt`
  (attr/decodeEntities/titleScore bigram-Dice/absoluteUrl/hlsUrls/
  decodeJsonEscapes) compartido por los scrapers.
- **Arsenales de verificación**: `tool/anilili_live_player_app.dart`
  (motor real paramétrico: resolve → play → frame → advance → seek → shot →
  stop/reopen; usa `KONGROO_LIVE_SHOT`/`KONGROO_LIVE_SEEK`) y runners N2
  `tool/allanime_live_check.dart` + `tool/anizone_live_check.dart`. Capturas
  en `.ai-local/anilili-live/` (megaplay/anizone/animegg, 1920×1080).
- **Suite**: **398 aprobadas / 10 omitidas** (25 pruebas nuevas), analyze
  limpio salvo 3 infos/1 lint PREEXISTENTES (voe_video_host_resolver ×2,
  public_playback_http_test ×1). Build Linux debug de `lib/main.dart`
  restaurado como bundle actual. Sin commits ni pushes.
- Diagnósticos de cadena en vivo (manager): miruro=forbidden,
  animeav1=missingId→invalidResponse (según idMal), allanime=noSources,
  resto OK — el fallback del manager se comporta según diseño.
- **Correcciones tras el informe (2026-11-18, PASO 7 de la misión):**
  `restoreStartPosition(20 s)` sobre MP4 progresivo verificado en el motor
  (SEEK-RESTORE 20000 ms → FRAME → ADVANCE) — la causa raíz era el
  throttling por UA ya corregido, no el coordinador; `flutter analyze` ahora
  **0 avisos** (corregidos los 3 infos preexistentes de Codex en
  `voe_video_host_resolver.dart` ×2 y `public_playback_http_test.dart` ×1);
  documentada la varianza de red del presupuesto de 6 s (GET frío ~5-7 s;
  sonda `tool/animegg_timing_probe.dart`, 3/3 OK sin motor).
- **Pendiente para la próxima misión (MODULARIZACIÓN)**: duplicación de
  `_read/_check/validMatch` entre adapters (plantilla pendiente);
  `html_playback_parsers` debería moverse a un módulo compartido con los
  parsers de AnimeAV1 (devalue) y MegaPlay (AES); los tres scrapers repiten
  el patrón de bucles de títulos idéntico; prioridades 110→50 repartidas sin
  ADR propio; `direct_media_host_resolver.dart` concentra validación de URL
  que convendría fragmentar por criterio; los tres runners tool/ comparten
  composición duplicable; falta N4 con la UI real (ficha→selector) para
  anizone/animegg (el motor se verificó por SpikePlayerModule, la ficha solo
  cambió el registro, no el flujo); Android sigue sin validar.

## Variantes y subtítulos del proveedor · 2026-11-17

MegaPlay registra sub/dub con un único adapter/resolver y transporte compartido
para Retry-After. Se verificó Tokyo Ghoul:re 9 en dub con texto inglés visible y
Attack on Titan 1 (AniList 16498) en sub con Spanish VTT superpuesto. Ambas
ventanas mostraron 1920×1080; seek, progreso y retorno pasaron. El recorrido
español final guardó 68818 ms y valida también un seek hacia atrás.
Los subtítulos publicados viajan por el contrato ProviderSubtitle; los IDs
caducan al cambiar fuente/Stop, y Stop→Play restaura catálogo. AudioLanguage
sigue unknown cuando el servidor no publica ISO; sub/dub son variantes anunciadas.
**Audio español pendiente**: AnimeAV1 declara DUB latino pero su único GET de
catálogo devolvió 403; AnikenTV/Zangetsu/KickAssAnime no aportaron otra ruta ES
verificable. No se reintroducen resolutores experimentales ni se cierran OC-03
ni la petición completa de audio/subtítulos en tres idiomas.
Suite final: **357 aprobadas / 7 omitidas**, incluidas HTTP/HLS/reanudación local.
Análisis limpio y build Linux debug normal de lib/main.dart aprobado.
Evidencia y pruebas finales: [auditoría de idiomas](../ai-system/audits/OC04-LANGUAGES-audit-2026-11-17.md).
Lanzador: `tools/player/run_kongroo_linux.sh --debug --openh264`.
Sin commits, pushes o cambios globales.


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

## Intento manual de episodio · 2026-11-17

La build actual Linux debug se compiló y abrió. La ventana mostró Home (captura
local `.ai-local/review/kongroo-episode-test-rebuilt.png`); en el primer arranque
se vio One Piece con 20/1410 episodios y estado “fuentes sin verificar”. No se
pudo pulsar: `mcp__wayland__describe_environment` indica Spectacle para captura,
pero sin backend de teclado/puntero, portal remoto no disponible y `ydotool` sin
acceso a `/dev/uinput`; el intento de clic devolvió `no usable pointer backend`.
Por tanto, el intento de UI no abrió un episodio. No cambiar permisos ni instalar
herramientas; el recorrido visual desde ficha queda pendiente de entrada gráfica
autorizada. La ventana principal se cerró antes del runner por CLI.

Verificación directa posterior: se ejecutó un runner temporal sin seek inicial,
basado en `app/tool/commons_live_player_app.dart`, mediante Flutter CLI. El
manager resolvió Wikimedia 480p para el único episodio catalogado de *Namakura
Gatana* (1917; película completa de dominio público); `media_kit` confirmó primer
cuadro y, a los 25 s, posición 23.233 s / duración 258.800 s / `error=null`.
Esto demuestra cuadro remoto y avance en el motor real, no el flujo desde la
ficha ni audio. La ejecución original con seek de 20 s falló con
`PlaybackResumeFailure`; no se depuró ni modificó el player. No valida Miruro/
`bee` y no resuelve su 403. El runner cerró automáticamente; el temporal está en
`.ai-local/review/commons-live-no-seek.dart` (ignorado por Git).

## Handoff vigente · OC-04 alternativa ante HTTP 403 · 2026-11-17

Leer la [auditoría OC-04](../ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md),
el estado de Git y los README de AniList y ficha. Miruro sigue devolviendo 403
según la evidencia anterior; no se volvió a solicitar ni se intentó eludir. La
ficha permite copiar URLs HTTPS públicas de `streamingEpisodes` para abrirlas en
el servicio externo; nunca se pasan a libmpv. El manager sigue con providers
registrados tras error, cubierto por prueba fake, pero no hay provider alterno
real confirmado. 47/47 tests focalizados, analyze y build Linux debug pasaron.
Suite completa: 336 pass, 10 skip, 2 timeouts nativos; ambos casos pasaron
aislados. No hubo prueba live, verificación manual de clipboard ni playback
del flujo Miruro (0 fuentes confirmadas para AniList 100240). La reproducción
histórica opt-in de Namakura Gatana con Wikimedia es un caso independiente.
Android/Windows y equipo 4 GB pendientes. Engine intacto. No commit/push. Antes
de afirmar solución integral, se requiere autorización del operador del origen o
un provider independiente accesible por protocolo normal, y reproducción real
desde la ficha.

Hallazgo de Anilili añadido el 2026-11-17: el selector DoH corrige DNS local sin
respuesta/sinkhole, no un HTTP 403 ya servido por Cloudflare. `MiruroCatalogApi`
de Android y el cliente desktop de Anilili paran en respuestas 4xx; los mirrors
no son fallback para 403. Anilili maneja Cloudflare aparte con emulación de
cliente navegador y estado de clearance de WebView; no portarlo, según la regla
del propietario contra evadir challenges/controles. Kongroo ya lista los
orígenes Miruro y no debe probar aliases como workaround. Solución permitida:
operador autoriza/corrige ruta o usar otro provider público que funcione con
protocolo ordinario; fallback AniList externo sigue siendo copia/apertura manual.
Ver el anexo DNS de la auditoría OC-04.

Addendum de comparación: el ZIP Android adjunto muestra que el cliente Miruro
usa GET ordinario sin el interceptor Cloudflare; su nota de cinco respuestas
200 es de 2026-10-03. Anilili desktop usa `wreq` con perfil TLS/HTTP2 de Chrome,
posible diferencia con Dio de Kongroo, pero no hay A/B que confirme causalidad.
Las cachés de fuentes de Anilili pueden conservar brevemente una URL ya resuelta.
El log de Kongroo solo tiene 403/HTML/Cloudflare: no prueba CAPTCHA ni su regla
concreta. No hacer nuevas sondas ni reutilizar challenge/clearance; seguir solo
con autorización del operador o provider alternativo ordinario. Ver addendum en
OC04.

Petición posterior de integrar el método Android: la comparación confirmó que
ya están portados endpoints/parámetros, decode XOR+gzip, parseo de `/play` y
entrega al manager. No hay un cambio de protocolo seguro pendiente que resuelva
el 403. No modificar fingerprint/contexto para pasar la denegación ni repetir
la sonda. Pruebas focalizadas actuales: 20/20 (provider Miruro, transporte HTTP,
composition root), solo fixtures/fakes; no prueban acceso live. Esperar ruta o
permiso documentado del operador, o continuar con otro provider de acceso público
ordinario; ver follow-up del informe OC-04.

## Snapshot anterior · OC-03 migración de proveedores · 2026-11-17

Leer primero la [auditoría de migración](../ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md),
los README de providers y el estado de Git. El runtime retira adapters
experimentales antiguos e integra `MiruroCatalogPlaybackProvider` en el manager
existente con `DirectMediaHostResolver`; Wikimedia y fuentes manuales siguen
opt-in. El engine media_kit/libmpv permanece único. No reactivar el código
antiguo. Los GET públicos Miruro para AniList 100240 dieron 403 en dos orígenes
antes de episodios/media; no repetir ni evadirlo sin evidencia nueva. Playback
externo de anime no está confirmado (0). Flutter focalizado pasó 62/62; suite
completa pasó 334 y omitió 10 opt-in; Flutter analyze y build Linux debug
pasaron. Home rasterizó primer frame, pero Wayland no dejó interactuar. Se
corrigió el límite HTTP configurable >2 MiB y su loopback de 3 MiB pasó. La
regresión local del engine reportó RSS 251,928,576 B antes / 396,959,744 B pico
tras Stop / 377,868,288 B tras dispose; no equivale a perfil de stream ni a
prueba de fugas. Comprobaciones finales: memoria `[]`, 40 tests Python,
checker de imports (fixtures y árbol real), formato sin cambios, enlaces
Markdown en 20 documentos y `git diff --check` pasaron. Android/Windows y
hardware de 4 GB siguen sin validar. No commit ni push.

## Snapshot anterior · Comparación de Anilili con Kongroo · 2026-11-17

El episodio de referencia fue Tokyo Ghoul:re 9 (AniList 100240), que el
usuario reprodujo en Anilili con `bee`. En el código de escritorio `bee`
es AniKoto a través de Miruro. Kongroo carece de ese registro activo y
los GET directos de configuración e identificación devolvieron HTTP 403
de Cloudflare en dos orígenes de Miruro, antes de obtener el episodio o el
medio. Anilili implementa emulación de Chrome en ese transporte. No se
confirmó qué condición originó la denegación ni que ese episodio se vea
en Kongroo.
[Comparación y pruebas](../ai-system/audits/OC03-ANILILI-BEE-audit-2026-11-17.md).

## OC-03 · Limpieza de proveedores · 2026-11-17

Ambas herramientas de AnimesDigital usan el registro de producción y se
retiraron comprobaciones redundantes del adaptador. Los resolutores de
MP4Upload y YourUpload siguen compartiendo una implementación con perfiles
separados. Antes y después de la limpieza, la suite aprobó 348 pruebas y
omitió 10. El análisis quedó limpio. Está pendiente comparar un episodio y
servidor concretos de Anilili con Kongroo.
[Inventario, validación y auditoría](../ai-system/audits/OC03-CLEANUP-audit-2026-11-17.md).

## OC-03.2 · Hosts de anime · 2026-11-17

AnimeAV1 y TioAnime alcanzan sus embeds. Los CDN devolvieron 403 para
MP4Upload y 500 para YourUpload (HEAD y Range). Se verificaron los errores
por etapa y se añadieron el HEAD MP4 por perfil, UA compartido por sonda y
medio, Retry-After por origen, aislamiento de cabeceras y preservación del
error al reabrir. Los dos hosts siguen experimentales y sin cuadros visibles.
Wikimedia conserva la validación anterior. HLS local pasó con segmento
relativo y distinguió el 403 de segmento pese a playlist 200.
[Checkpoint](../ai-system/missions/OC03-2-ANIME-TRANSPORT-2026-11-17.md)
y [auditoría](../ai-system/audits/OC03-2-ANIME-TRANSPORT-audit-2026-11-17.md).


## OC-03.1 · Transporte remoto · 2026-11-16

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


## OC-03.1 · 2026-11-16

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
Fecha: 2026-11-16
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Herramientas, docs y resultados reproducibles

### Handoff histórico: OC-02 continuación (Home, episodios, Continuar viendo, R0, R4 control) — 2026-11-16

Checkpoint: `docs/ai-system/missions/OC02-EXECUTION-STATUS.md`; inventario R0:
`docs/ai-system/missions/OC02-R0-INVENTORY.md`. Base sin commit en `6cc3e5e`.
Hecho y probado: timeouts por sección (sin 12 s globales); caché acotada de
populares/tendencias (esquema v9); diagnóstico de imagen sin URL; campos AniList
opcionales inválidos anulan solo el campo; índice de episodios Kitsu (AniList→Kitsu,
sin cuenta) conectado a la ficha; Continuar viendo desde progreso local. Fedora:
Home con banners y carátula reales (capturas en `.ai-local/oc02-fedora/`); video
visible con `media_kit/libmpv` y fixture local (control R4). Suite 320 pasan /
8 opt-in omitidas; analyze y formato limpios; reproductor sin cambios; lock intacto.
Pendiente: 0 fuentes externas verificadas (R3/R4 externo), captura de la ficha y
de filas inferiores de Home, decisión sobre AnimesDigital, persistencia de caché
de episodios, Android/Windows no ejecutados. Sin commit ni push.

### Handoff anterior: S0-S — source-first/host-first — 2026-11-16

La limpieza retiró AnimeHeaven y archivó READMEs/evidencias anteriores. El root
registra `AnimesDigitalPlaybackProvider` v1.0.0 como candidato y
`DirectMediaHostResolver` genérico HTTPS MP4/HLS/DASH. One Piece ep. 1180
entregó manifiesto 200/4,998 B (142 segmentos) y primer TS 200/67,258 B; ep. 1
también entregó HLS/segmento por HTTP. Las dos capturas libmpv muestran negro y
“The media could not be opened or decoded”; no hay reproducción confirmada. El
único manager conserva registro SemVer, caché LRU de 128 y circuitos de host
limitados a 128. Domain separa identidad, match, episodios y el adapter de tres
fases. Ficha→manager→selector→ruta está cableado en código, sin clic/retorno
gráfico validado. Engine/UI y dependencias del player no se tocaron.

Provider test 7/7; suite Flutter más reciente 300 aprobadas/7 optativas omitidas; Dart
analyze y Flutter analyze sin issues. Se cambió el timeout por petición a un
presupuesto total de 20 s por operación, cubierto por prueba loopback. La
auditoría independiente post-fix confirmó requestKey, límites HTML y deadline
individual; advirtió la multiplicación del timeout, ya corregida con presupuesto
total por operación. Checker de imports, sus tests, 40 tests Python,
`memory.py check`, formato, build Linux y `git diff --check` pasaron. La ruta
productiva espera `Player.open()` antes de montar superficie, mientras el
harness la montó primero; falta regresión para aislar causalidad. No se midió
rendimiento del provider. Android/Windows, mpv CLI y equipo de 4 GB no
validados. S0-S sigue parcial. Ver la
[auditoría](../ai-system/audits/S0S-audit-2026-11-16.md), README de AnimesDigital
y el [baseline S0-S](../ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).
Sin staging, commit ni push.

Continuación: `KONGROO_LIVE_FFPROBE=1` reportó una referencia HLS `.webp`
rechazada por el filtro de extensiones de FFmpeg; no es diagnóstico libmpv
confirmado. Una petición posterior agotó el timeout. El harness fue analizado
con `dart analyze` y los tests offline pasaron 3/3; no se amplió la lista de
extensiones ni se modificó el engine. S0-S continúa parcial.

Ver [baseline/informe S0-S](../ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

### Handoff histórico: S0-R AnimeHeaven live — 2026-11-16

El snapshot anterior registró AnimeHeaven y los mirrors `cx`, `ct`, `ck` que
fallaron sin frame. El código y el harness fueron retirados durante S0-S; la
evidencia quedó archivada. No reactivar ni repetir sin evidencia nueva.

### Handoff histórico: S0-R Gates 0–1 — 2026-11-16

El Gate 0 y sus medidas locales están en
[S0R-BASELINE](../ai-system/missions/S0R-BASELINE.md). Gate 1 revisó
referencias de Anilili, Aimi y clientes CLI, más un candidato AniWorld. Seis
GET iniciales devolvieron 403; AniWorld dio búsqueda/ficha/episodio públicos,
pero Doodstream, Filemoon y Vidmoly dieron 403 y VOE publicó una redirección
con lectura opcional de `localStorage`, sin exponer media estática. No se usó
sesión, cookie, challenge, cambio de agente ni automatización de JS. No se copió código ni se integró
proveedor: en ese corte, runtime 0 y reproducción externa 0/70. Ver
[S0R-REFERENCE-REVIEW](../ai-system/missions/S0R-REFERENCE-REVIEW-2026-11-16.md).

**Siguiente paso histórico:** inspeccionar licencia/protocolo de una fuente
independiente no probada; hacer una solicitud ordinaria solo si no requiere
challenge, autenticación, descifrado o impersonación. Este handoff fue
reemplazado por la entrada vigente AnimeHeaven de arriba.

### Handoff histórico: Gate 0 baseline — 2026-11-16

La orden vigente es el adjunto S0-R indexado en
[`S0R-MASTER-MISSION.md`](../ai-system/missions/S0R-MASTER-MISSION.md). Gate 0
quedó `PARTIAL`: libmpv pasó pruebas locales y una demo sintética con imagen en
movimiento/subtítulo se observó en Wayland. No se probó fuente externa (`0/70`).
El proceso release midió 245,708–258,440 KiB RSS y 28.84% de un núcleo durante
8 s con 480×270/24 fps de archivo, pero en host de 7.5 GiB, no 4 GB; el render
fue software. 268 Flutter y 40 tests Python, analyze, formato, checker y
memoria pasaron. `scripts/measure.sh` no produjo una medida completa para el
entrypoint spike y su TSV quedó marcado incomplete. Ver
[`baseline`](../ai-system/missions/S0R-BASELINE.md),
[`STATUS`](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[`HANDOFF`](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

**Siguiente acción:** Gate 1; verificar commits/licencias actuales y técnicas
concretas en Anilili Android/Desktop, Aimi y dos herramientas CLI, elegir una
vía legítima para integrar y documentar matriz. No iniciar con stubs ni afirmar
provider operativo; conservar todo el estado Git sucio y no hacer commit/push.

### Handoff histórico: limpieza posterior a S0-A — 2026-11-15

Se retiraron el provider Miruro, su cliente Dio y el resolver directo. Los GET
públicos previos devolvieron 403; no hubo episodio, media ni reproducción
externa (`0/70`). El composition root actual tiene cero providers externos y
cero resolutores concretos. Las pruebas específicas se archivaron como
`.dart.txt`; solo continúa activo el test del composition root vacío y las
pruebas genéricas del manager/contratos. Se ejecutaron 24 tests focalizados y
la suite Flutter completa (268 pass, 6 optativas omitidas), Flutter/Dart
analyze, 40 tests Python, checker, formato, memoria y diff check; todo pasó.

Se preservaron `PlaybackSourceProvider`, `PlaybackVideoHostResolver`, el manager
y su fallback/circuit breakers, `PlaybackSourceSwitchService`, el motor único
media_kit/libmpv, los READMEs y las evidencias previas. No se cambió `pubspec`:
`dio` todavía tiene consumidores en AniList, AniSkip y OpenSubtitles. S0 sigue
incompleta; G1/T03 no se acepta ni F1 se inicia. La próxima acción es esperar
el siguiente prompt de integración. Ver la
[auditoría de limpieza de seguimiento](../ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

### Handoff histórico: misión S0-A Anilili/Miruro — 2026-11-15

Se portó el catálogo Miruro de los commits fijados de Anilili a un provider y
resolver modulares conectados al manager y engine existentes. Miruro respondió
403 a config/lookup con requests públicos ordinarios; no se evadió el bloqueo,
no hubo episodios/URI accesible ni reproducción libmpv. Anivexa sigue pendiente;
S0 continúa incompleta y playback externo permanece `0/70`.

Con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislado, `scripts/ci.sh` pasó 40 pruebas
Python, 288 Flutter y 7 optativas omitidas. Análisis, formato, checker y memoria
pasaron. No se probó UI Wayland, fuente externa, ni rendimiento de este provider
en equipo de 4 GB. La segunda pasada local detectó y corrigió el filtro IPv6 de
direcciones especiales; DNS TOCTOU permanece. No hubo commit ni push.

Continuar revisando estáticamente el alcance Anivexa y probar solo accesos
públicos ordinarios; no repetir los GET 403 sin evidencia nueva. Para retomar,
leer [S0-A](../ai-system/missions/S0-ANILILI-PORT-REPORT.md), [auditoría](../ai-system/audits/S0-ANILILI-port-audit-2026-11-15.md), [STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y [HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

### Último handoff: reconstrucción Kongroo Bloque A — 2026-11-15

La reevaluación externa A-EXT-01–06 terminó con los criterios técnicos de
Bloque A/G1 pasando; G1 queda `AUDITING` hasta aceptación propietaria. No se
inició T04/B.
Rama `main`; base `33ceaef5b996c55577524c3448bbb4bee5363952`; HEAD continúa
`b1bd952ac03c8711ce50cf22d249fa448d2e2880`. El propietario autorizó commit/push
del Bloque A original al repositorio privado; esta reevaluación quedó sin
commit/push. CI final pasó con Flutter 3.47.9 aislado: 40 pruebas Python y 269
Flutter; 6 opt-in omitidas. También pasan analyze, formato, checker, memoria y
diff. La revisión externa fue anterior a los fixes; la segunda pasada post-fix
fue local, no independiente. El intento de dos aperturas nativas agotó 45 s y
sigue sin aprobar; la prueba controlada de libmpv reprodujo con un único Player
y rechazó un segundo constructor. El ciclo E2E completo de `VideoController`
sigue sin prueba automatizada. A-EXT-03 permanece
`UNATTRIBUTED / NOT_REPRODUCED`; los logs originales y bundle histórico faltan,
y los logs nuevos están en `.ai-local/review/block-a-reassessment-2026-11-15/`.
No hubo reproducción externa, conteo `0/70`. Preservar ZIP y misión sin
seguimiento. Detalle reproducible en
[`STATUS`](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md),
[`HANDOFF`](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md) y la
[auditoría de reevaluación](../ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md).

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

### Handoff: limpieza S0 de providers — estado 2026-11-15

S0 permanece incompleta; la implementación externa está en pausa hasta el
siguiente prompt del propietario, sin cerrar G1/T03. El informe con la matriz
histórica de 22 candidatos es
[`S0-REAL-PLAYBACK-REPORT.md`](../ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).
No hay providers externos ni resolutores concretos activos; los adaptadores
AnimeAV1/TioAnime/AnimeGG y el resolver estático anterior se retiraron. La
arquitectura conserva contratos `AnimeProvider`, `VideoHostResolver`, el manager
y la reproducción con el `PlaybackEngine` existente. Playback externo sigue
0/70.
AnimeGG/vidcache avanzó 5311 ms y detectó audio, sin dimensiones de video;
TioAnime recorrió Mega, StreamSB, YourUpload, OK.ru y Netu sin fuente válida;
AnimeAV1/Zilla fue `unauthorized`; AniZone/vid-cdn devolvió 404 por Range y GET,
y 419 en Livewire. FileStream/Bee/Goma no aparecieron en las fuentes revisadas.
FlixCloud tiene referencia upstream a token/stream por API y segmentos XOR en
proxy local; no se verificó ni implementó un flujo directo. Las pruebas y logs
de los adaptadores ya retirados son evidencia histórica, no checks del árbol
actual. Ver la [auditoría de limpieza](../ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md),
[auditoría de hosts](../ai-system/audits/S0-video-host-audit-2026-11-15.md),
[STATUS](../ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md) y
[HANDOFF](../ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

Tras la limpieza se ejecutaron Flutter analyze, Dart analyze y la suite Flutter
completa con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislados: 267 pasaron y 6
optativas se omitieron. No se hicieron solicitudes a proveedores en esta
ejecución. El runtime está preparado para recibir una arquitectura nueva, pero
S0 sigue sin reproducción externa.

### Handoff histórico: proveedores reales de reproducción — 2026-11-14

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

## 2026-11-16 — OC-03 continuación (Continuar viendo)
- Continuar viendo reanuda por el flujo de fuentes existente; sin fuente muestra mensaje y conserva progreso. Posición inicial aún no conectada (archivos protegidos).
- Suite 322/8/0, análisis limpio, `memory.py check` = `[]`. No commit ni push.
- Detalle: `docs/ai-system/missions/OC02-EXECUTION-STATUS.md` (checkpoint OC-03).
- 2026-11-16 (OC-03): posición de reanudación conectada; seek validado en motor real con fixture local (opt-in). Suite 322/9/0. Sin fuente externa legítima.
- 2026-11-16 (OC-03): proveedor `user-defined` (URLs https registradas por el usuario vía `KONGROO_USER_SOURCES`). Suite 326/9/0. Sin fuentes de terceros.
