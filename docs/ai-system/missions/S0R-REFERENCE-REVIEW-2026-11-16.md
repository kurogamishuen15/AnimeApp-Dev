# S0-R — revisión de referencias y accesibilidad de fuentes

**Fecha:** 2026-11-16<br>
**Gate:** 1 — referencias, licencias y selección de fuente<br>
**Estado:** `PARTIAL / NO_PLAYABLE_SOURCE_VERIFIED`<br>
**Reproducción externa en Kongroo:** `0/70`

## Resultado

Se revisaron los contratos, parsers y mecanismos de resolución de Anilili
Android/Desktop, Aimi y varios clientes CLI. No se copió código de esos
repositorios. Las referencias confirmaron separaciones útiles entre catálogo,
resolución de host y motor, pero las rutas examinadas dependen en parte de
fuentes que no respondieron a GET público simple en este entorno, o requieren
autenticación, desafíos, decodificación específica o técnicas excluidas por la
misión.

La revisión inicial no integró proveedores. Después, en la ejecución S0-R del
16 de noviembre, se integraron AnimeHeaven y su resolver MP4 a partir de una
implementación independiente de la descripción upstream con licencia MIT-0.
La búsqueda pública de One Piece/episodio 1 y la ruta hasta el player
funcionaron; `mirror-cx`, `mirror-ct` y `mirror-ck` produjeron el mismo error
genérico y ningún frame. El
provider está implementado pero no operativo; Gate 1 y Gate 2 siguen parciales,
playback externo 0/70. Los probes de cada candidato son evidencia solo del
método, host y ruta exactos probados.

## Referencias inspeccionadas

Las revisiones de código apuntan a commits concretos; el idioma es una
capacidad declarada/observada en la implementación upstream, no disponibilidad
live en Kongroo.

| Proyecto / revisión | Licencia upstream | Aporte técnico y capacidades declaradas | Decisión para Kongroo |
|---|---|---|---|
| [Anilili Android, `d7b80f1`](https://github.com/sanilili/Anilili/tree/d7b80f1f5b6c3d014317af471a8565749947397d) | MIT-0 | Catálogo Miruro por AniList ID; episodios y alternativas por separado; distingue medios HLS nativos, embeds, variantes hard/soft-sub; lee una página embed una vez y conserva fallback tipado. | Referencia directa para contratos y pruebas. GET de `/api/config` en `www.miruro.cx` devolvió 403; sin integración. No se adaptó el cuerpo XOR/gzip ni se siguieron mirrors. |
| [Anilili AnimeHeaven provider, `d7b80f1`](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeHeavenProvider.kt) | MIT-0 | Catálogo público, episodio/gate por key de fila, alternativas MP4 y mirrors; upstream declara subtitulado. | Adaptador Kongroo independiente registrado; `cx`, `ct` y `ck` llegaron a libmpv y fallaron sin frame. No se copió código. Idioma concreto no verificado. |
| [Anilili Desktop, `e1c84db`](https://github.com/sanilili/desktoprepo1/tree/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd) | MIT-0 | Contratos de fuente, allowlist, aislamiento WASM y carga con mpv; Tauri/Rust/WASM es infraestructura específica del producto. Algunas rutas publicadas usan `browser-fetch` para superar desafíos. | Se conserva como referencia de límites y política. No se portan Tauri/WASM ni la capacidad de superar desafíos. |
| [Aimi, `c89ba5f`](https://github.com/brokiem/aimi/tree/c89ba5f5767972f3125191ceb5802e64f6af4087) | GPL-2.0 | Flutter/Dart y media_kit; separa metadata de streaming. Su adaptador Anizone busca, lista episodios y lee `media-player[src]`; AnimePahe identifica sub/dub y sigue un embed. | Referencia arquitectónica solamente mientras la licencia del proyecto no esté resuelta. No se copió código ni se integró el flujo con cookie/embed de AnimePahe. |
| [ani-cli, `8527f18`](https://github.com/pystardust/ani-cli/tree/8527f185a12c6b5d0247a30b2217000dd65457fe) | GPL-3.0 | Flujo CLI hacia mpv; la ruta vigente inspeccionada incluye manejo de payload/cipher y recomendaciones de `curl-impersonate` frente a challenges. | No adaptar esa ruta porque implicaría técnicas de evasión de acceso. |
| [anipy-cli, `6d590c4`](https://github.com/sdaqo/anipy-cli/tree/6d590c4b23e04dec1765481ccbf80ebc54267530) | GPL-3.0 | API desacoplada de CLI; incluye AnimeHub, AniDBApp y AnimeKai. El código AnimeKai descarga una función remota para decodificar datos de iframe; AnimeHub sigue una cadena de player que requiere endpoints auxiliares. | Arquitectura estudiada, código no copiado. No adoptar la decodificación de iframe ni una fuente que no respondió al GET básico. |
| [anime-sh, `c7bd2c5`](https://github.com/Anime123450/anime-sh/tree/c7bd2c576877f99cc7323a711ffb54b2b787ea48) | MIT | Módulos separados `providers/` y `resolvers/`; AniZone declara HLS directo y solo subtítulos en inglés; Anikoto declara sub/dub pero su propio comentario informa payload cifrado desde 2026-09-13; Hianime indica challenge; Filemoon/Streamwish extraen HLS de páginas player. | Aporte de modularidad. AniZone resultó 403 en un GET de búsqueda; no se intenta variar agente. Anikoto/challenge quedan fuera. No se copió código. |
| [GoAnime, `125eaaf`](https://github.com/alvarorichard/GoAnime/tree/125eaafe65cab66864fedafd9ae7f78f7ec5aca4) | MIT | Registro de fuentes, clasificación de fallos, cancelación, límites por request y pruebas de fixture/live. Incluye AnimeFire, Goyabu, AnimesDigital y AnimeDrive, centrados en portugués de Brasil. Goyabu está explícitamente deshabilitado upstream por Cloudflare Managed Challenge. | Referencia útil para health, fallback y pruebas. AnimeFire, AnimesDigital y AnimeDrive devolvieron 403 en sus probes de portada. No se copió código ni se probó Goyabu por su challenge declarado. |
| [anime1v-api, `7ae834e`](https://github.com/FxxMorgan/anime1v-api/tree/7ae834e05517e6f4de738a520d88dd963ab80b10) | MIT (con atribución/firma requerida por el README) | Declara AnimeAV1, AnimeFLV, TioAnime, JKAnime y otros; API documentada requiere `X-API-Key` o `apiKey`. Incluye Puppeteer/ytdlp y menciona bypass de HLS. | No cumple el límite de no añadir autenticación ni mecanismos de bypass. No se usó su API ni se copió código. |
| [AniWorld-Downloader, `22ad0e7`](https://github.com/phoenixthrush/AniWorld-Downloader/tree/22ad0e79900ebc505e500a1e5162eae2c4866aa2) | MIT | Implementa búsqueda/catálogo alemán y extractores para VOE, Doodstream, Filemoon y Vidmoly. También incluye resolución de CAPTCHA, impersonación/DoH y descifrado Filemoon. | Se reutiliza solo como referencia de nombres de host y estructura. No se adaptan CAPTCHA, impersonación, DoH, descifrado ni código de esos extractores. El catálogo público de AniWorld respondió; los hosts probados no entregaron una fuente accesible. |

La fuente [`RareAnimesProvider.kt` de Anilili](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/RareAnimesProvider.kt)
declara audio doblado en hindi, tamil y telugu. Describe una cadena CodeDew →
embed Argon/JW Player y explica que el HLS está protegido por una sesión de
reproductor con token y endpoint `/ping`; por eso el cliente conserva el embed
para reproducirlo dentro del player web y no entrega el HLS directo. No se
portó el decodificador de la página ni se hizo un probe live: esa vía requiere
una sesión del player y no alimenta el engine libmpv con una fuente directa.

Las referencias [`AnimeOnsenProvider.kt`](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeOnsenProvider.kt)
y [`AniChanProvider.kt`](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AniChanProvider.kt)
describen dos salidas directas. AnimeOnsen declara DASH/subtítulos, sin
doblaje, y nueve idiomas de subtítulos; su API usa un grant OAuth
`client_credentials` y la landing de búsqueda devolvió 403 aun con el
Referer/Origin públicos descritos por ese cliente. No se obtuvo ni usó token.
AniChan declara HLS y subtítulos etiquetados; su catálogo de episodios es un GET
público, pero la referencia emite una cookie desde `/api/watch/session` para
pedir servidores y advierte que, si se activa Turnstile, necesitaría resolverlo.
El GET público de episodios devolvió 403. No se solicitó la cookie ni se
automatizó el posible desafío.

Anilili Android tampoco se porta como bloque de código: su [`AnivexaClient`](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnivexaClient.kt)
construye un cliente con `CloudflareInterceptor` y documenta reintento tras un
challenge resuelto. Ese flujo queda fuera del alcance permitido; no se copió
ni ejecutó.

Las revisiones upstream citadas se obtuvieron con `git ls-remote`/API de GitHub
y lectura de archivos de esos repositorios. El proyecto Kongroo no tiene un
`LICENSE` raíz; por eso no se incorporó código de licencias GPL/AGPL ni se
cambió la licencia del producto. No se ejecutaron scripts ni binarios upstream.

## Idioma declarado por los candidatos

Esto resume capacidades descritas por los repositorios o proveedores
históricos. No representa disponibilidad real ni pistas observadas en Kongroo.

| Cobertura candidata | Proveedores referenciados | Resultado en Kongroo |
|---|---|---|
| Español | AnimeAV1 y TioAnime en el inventario histórico del proyecto | No hay adaptadores activos ni reproducción verificada. |
| Subtítulos en inglés | AniZone según el comentario del adaptador de anime-sh | Proveedor no integrado; la búsqueda GET probada recibió 403. |
| Sub y doblaje en inglés | HiAnime, Anikoto y AnimePahe en sus respectivos adaptadores de referencia | No integrados; Anikoto declara payload cifrado y AnimePahe sigue un embed con cookie. |
| Portugués de Brasil (legendado/dublado) | AnimeFire, AnimesDigital y AnimeDrive en GoAnime; AnimeHub separa variante dub/sub en anipy-cli | No integrados; las portadas de AnimeFire, AnimesDigital, AnimeDrive y AnimeHub respondieron 403 en los probes anotados. |
| Variantes múltiples sub/dub, hard/soft-sub | Miruro según catálogo Anilili | No integrado; la configuración consultada en el espejo probado respondió 403. Las variantes no se cuentan como proveedores separados. |
| Alemán doblado; japonés con subtítulos alemanes o ingleses | AniWorld, según su modelo de episodios y las etiquetas observadas | Búsqueda, ficha y episodio públicos respondieron; no hubo host reproducible. No ofrece español en la muestra examinada. |
| Hindi, tamil y telugu doblados | RareAnimes en el provider de Anilili | Referencia upstream; no integrado ni probado live. La salida observada por el código es un embed con sesión, no un HLS directo elegible. |
| Japonés/sub con subtítulos multilenguaje (9 idiomas declarados) | AnimeOnsen, según Anilili | No integrado; landing pública devolvió 403 y la API posterior usa OAuth de cliente. No se obtuvo token ni stream. |
| Subtítulos multilenguaje y posibles pistas sub/dub | AniChan, según etiquetas/categorías de su API en Anilili | No integrado; GET público de episodios devolvió 403. La ruta de servidores depende de una cookie de sesión; no se solicitó. |

**Conteo operativo actual: 0 proveedores externos reproducibles.** AniWorld es
un proveedor candidato adicional investigado, no integrado. Los nombres de
upstream, variantes de idioma y aliases de servidores no incrementan el conteo.

## Probes públicos de esta ejecución

Los seis primeros probes de esta tabla fueron solicitudes individuales el
2026-11-16 y no se repitieron. No se enviaron cookies, Authorization, claves,
credenciales ni desafío/respuesta CAPTCHA. No se usó navegador autenticado,
proxy, `curl-impersonate` ni User-Agent alternativo. En AniWorld se hicieron
solicitudes separadas de catálogo/episodio y un único follow-up con
`Referer: https://aniworld.to/` para modelar el origen público del embed
Vidmoly; el 403 persistió y no hubo más intentos al host.

| Etapa / fuente | Solicitud observada | Resultado | Límite de la conclusión |
|---|---|---|---|
| AniZone | `GET https://anizone.to/anime?search=Death%20Note`, agente estándar `Python-urllib/3` | HTTP 403, HTML | No prueba el estado de otras rutas o de un cliente distinto. No se reintentó. |
| Miruro REST | `GET https://www.miruro.cx/api/config`, con el conjunto normal de cabeceras descrito por el cliente Anilili (sin cookie) | HTTP 403, `text/html` | Solo ese espejo y ruta. No se probaron otros mirrors ni se repitió el probe histórico de `www.miruro.to`. |
| AnimeFire | `GET https://animefire.io/`, agente estándar | HTTP 403, HTML | Solo la portada. No se modificaron cabeceras ni se usó otro dominio. |
| AnimeHub | `GET https://123animehub.cc/`, agente estándar | HTTP 403, `text/plain` | Solo la portada. No se siguieron las etapas de player. |
| AnimesDigital | `GET https://animesdigital.org/`, agente estándar | HTTP 403, `text/plain` | Solo la portada. No se probaron búsquedas o páginas de episodio. |
| AnimeDrive | `GET https://animesdrive.cloud/`, agente estándar | HTTP 403, `text/plain` | Solo la portada. El upstream ya describe el dominio como intermitente; no se probó override de dominio. |
| AniWorld catálogo | `GET https://aniworld.to/`, después `POST /ajax/search` con consulta pública `One Piece` | HTTP 200 HTML; HTTP 200 JSON con 64 coincidencias | Solo la respuesta pública actual de búsqueda. No equivale a acceso a video. |
| AniWorld episodio | `GET /anime/stream/one-piece`, su temporada 1 y episodio 1 | HTTP 200 en ficha, temporada y episodio | Se observaron cuatro familias de hoster en alternativas del episodio. No se integró adaptador. |
| AniWorld → Vidmoly | Solicitud manual a `/redirect/...` sin seguir automáticamente | HTTP 301 a `vidmoly.net`; el GET del embed dio 403, también con el Referer público de AniWorld | No se probaron otros agentes, cookies ni rutas alternativas. |
| AniWorld → Doodstream | Solicitud manual a `/redirect/...` | HTTP 301 a `do7go.com`; GET del embed dio 403 | Solo el host y embed de One Piece ep. 1 probados. |
| AniWorld → Filemoon | Solicitud manual a `/redirect/...` | HTTP 301 a `bysezejataos.com`; GET del embed dio 403 | Solo el host y embed de One Piece ep. 1 probados. |
| AniWorld → VOE | Solicitud manual a `/redirect/...` y GET del embed | HTTP 301 a `voe.sx`; HTTP 200 HTML de 755 bytes | HTML estático sin referencia MP4/HLS/DASH. JavaScript opcionalmente añade `localStorage.permanentToken` antes de redirigir; no se ejecutó ni se leyó/creó token y no se siguió ese destino. Esto no prueba ausencia de medios en otras rutas. |
| AnimeOnsen landing | `GET https://www.animeonsen.xyz/` con cliente HTTP estándar; una solicitud adicional usó solo el Referer/Origin públicos indicados en el código upstream | HTTP 403 en ambas | Sin User-Agent alternativo, token OAuth ni credencial de cliente. No se continuó a la API. |
| AniChan episodios | `GET https://anichan.to/api/watch/episodes?anilistId=21`, `Accept: application/json` y Referer público | HTTP 403 | Sin cookie/sesión. No se solicitó `/api/watch/session` ni la ruta de servidores. |

El cliente local y el entorno pueden ser rechazados por políticas de los hosts.
La evidencia no autoriza a evadir esa respuesta. Se clasifica cada intento como
`ACCESS_RESTRICTED` para la ruta/método probados, no como indisponibilidad
universal del proveedor. El 200 de AniWorld acredita solo el catálogo público;
el HTML de VOE no es una fuente de video ni una autorización para automatizar
su estado de navegador.

## Hosts y formatos

- AniWorld publicó cuatro hosters en el episodio inspeccionado, pero no se
  obtuvo una URL multimedia: Doodstream, Filemoon y Vidmoly devolvieron 403;
  VOE publicó una redirección JavaScript con lectura opcional de
  `localStorage`, sin exponer medio en HTML estático; no se siguió ese destino.
- Las referencias de AnimeOnsen y AniChan describen salidas nativas DASH/HLS,
  pero sus rutas live probadas devolvieron 403. La API posterior de AnimeOnsen
  requiere OAuth de cliente; AniChan solicita una cookie emitida por su
  endpoint de sesión. Ninguno produjo una fuente para Kongroo.
- HLS directo de AniZone es una capacidad descrita en el código upstream, no
  una fuente comprobada ahora.
- Filemoon y Streamwish aparecen como resolutores de páginas player en
  `anime-sh`; no hubo endpoints live que inspeccionar ni resolver aquí.
- No se observaron FileStream, Bee o Goma en esta ejecución. Su ausencia en
  estos requests no permite concluir que no existan.
- El árbol actual de Kongroo conserva `PlaybackProviderManager`,
  `PlaybackVideoHostResolver`, `PlaybackSourceSwitchService` y el engine
  media_kit/libmpv único. El composition root permanece vacío. Ningún cambio de
  código funcional se realizó en Gate 1.

## Verificación y restricciones locales

- `mpv` CLI no está instalado (`command -v mpv` no devolvió ruta); no se instaló.
  La prueba diferencial CLI/mpv no se ejecutó.
- No se obtuvo episodio, manifiesto, pista de video ni primer cuadro externo.
- El baseline de Gate 0 sigue aplicando; no se midió rendimiento de un proveedor.
- Los resultados de analyze/suites mencionados están en
  [`S0R-BASELINE.md`](S0R-BASELINE.md) y preceden a esta revisión. No se
  volvieron a ejecutar pruebas Flutter porque no se modificó código.
- Git sigue con cambios previos ajenos a esta misión; no se restauraron ni
  prepararon. No hubo commit, push, cambio de rama ni instalación.

## Continuación

1. Mantener Gate 1 parcial y S0 abierta; no declarar proveedor operativo ni
   cerrar ningún gate.
2. No repetir los seis probes iniciales ni los hosters AniWorld ya probados.
3. Próxima exploración permitida: seleccionar un proveedor no probado de las
   referencias mantenidas, inspeccionar licencia y ruta de extracción, y
   ejecutar como máximo una solicitud pública ordinaria si su implementación
   no requiere challenges, autenticación, descifrado ni impersonación. Si
   responde 401/403/challenge, registrar el resultado y pasar a otra fuente sin
   eludirlo.
4. Cuando una ruta responda públicamente, seguir con fixture/parser, adaptador
   de catálogo, resolver reusable y el mismo manager/player; activar solo tras
   vídeo externo visible en Kongroo.
