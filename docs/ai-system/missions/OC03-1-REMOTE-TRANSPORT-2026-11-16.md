# OC-03.1 · Transporte remoto Wikimedia y Anilili

Fedora 44, KDE/XWayland, Flutter 3.47.9, Dart 3.13.7, Dio 5.11.1,
media_kit 1.2.6, media_kit_video 2.0.1 y mpv-libs 0.41.0
(`libmpv.so.2.5.0`). El paquete del sistema ofrece la biblioteca. No se
encontró un ejecutable mpv CLI en PATH.

## Wikimedia · prueba en red

En la misma URL publicada del derivado WebM 480p, HEAD con el nuevo UA
respondió HTTP/2 200 y `video/webm`. A las 23:04:30 en Bogotá, ffprobe con
`Kongroo/1.0.0 (https://github.com/kurogamishuen15/AnimeApp-Dev/issues)`
obtuvo VP9, Opus y 258,8 s. Un segundo después, ffprobe con el UA
`libmpv` observado por el servidor local devolvió HTTP 429. No apareció
`Retry-After` en el diagnóstico capturado. La prueba terminó tras el 429.
La diferencia se reprodujo con la misma URL y el mismo comando cambiando
solo el UA. Wikimedia documenta otros 429 posibles para clientes identificados.

El endpoint público del contacto devuelve HTTP 200 con título
«Issues · kurogamishuen15/AnimeApp-Dev · GitHub» sin credenciales.
El UA se define una vez, se envía a la API de Commons y se propaga por
`SourceCandidate → PlayableSource → Media(httpHeaders)` al CDN.
Un receptor HTTPS local registró el GET de Dio con el UA completo.
La prueba con receptor HTTP local observó el UA completo en apertura y
Stop→Play, seguido de `libmpv` al cambiar a otro medio. Verificó avance
del clock en las tres etapas. media_kit 1.2.6 aplica esos campos durante
`on_load`, por lo que basta el mapa por medio.

La API de Wikimedia admite dos consultas simultáneas por instancia,
bloquea nuevas solicitudes durante `Retry-After` al recibir 429/503,
acepta delta-segundos y fecha HTTP y aplica 5–6 s cuando falta una espera
válida. Se cancela la descarga upstream en toda salida, incluidos errores
con cuerpo truncado. Las limitaciones de cuota no abren por sí mismas el
circuit breaker de 60 s. La UI muestra la espera restante. Se cachean los
derivados públicos 5 min y se prioriza 480p. La prueba de segunda selección
confirmó una sola consulta a la API mediante un adaptador HTTP de pruebas.

El reproductor posee una sola sesión nativa. libmpv gestiona internamente
sus conexiones Range. El cooldown implementado cubre las solicitudes que
hace Dio a la API. Quedan por verificar/implementar el control de
`Retry-After` de una respuesta 429 del CDN dentro del motor y un límite
global de conexiones que incluya las solicitudes internas de libmpv.

## Reproducción

El smoke `app/tool/commons_live_player_app.dart` usó el
`PlaybackProvidersModule` y el `SpikePlayerModule` reales con resolución
automática por AniList 6654. Con la red activa, seek confirmado en 20.000 ms,
primer fotograma renderizado, salida 612×480 y avance a 22.032 ms con
duración 258.800 ms. Las capturas consecutivas muestran cuadros distintos
a 00:53 y 00:54. En una segunda ejecución, Stop→Play volvió a abrir el mismo
medio remoto y avanzó a 267 ms sin volver al descubrimiento. El test del cache
hizo dos resoluciones separadas con una sola consulta a la API. El contenido es *Namakura Gatana* (1917), publicado como
dominio público. `ffprobe` detectó Opus. La audición no se verificó.

Evidencia local en `.ai-local/oc03-ua/` — `ab-final.log`, `visual.log`,
`commons-playing-frame.png`, `commons-playing-next-frame.png`,
`dio-wire.log`, `native-wire-final.log`, `reopen-visual.log`, `host-probe.log` y `provider-tests.log`.
La captura usa la ruta visual del módulo de reproducción a través del
lanzador de diagnóstico. El nuevo recorrido interactivo desde la ficha,
el guardado de progreso desde ese recorrido y una segunda plataforma
siguen sin evidencia en esta ejecución.

## Anilili y fuentes experimentales

GIO encontró `Anilili.desktop` y su binario `anilili-desktop` ELF x86_64.
La entrada no declara una versión y RPM no posee el ejecutable. Se inspeccionó
solo la metadata autorizada. El árbol del ZIP no se localizó dentro de la raíz
actual. Se usó la auditoría previa del ZIP y se contrastó con el fuente actual
de Anilili Android `d7b80f1` y Desktop `e1c84db`.

Desktop modela en WIT un `title` por AniList con número de episodio y
`server` con playback URL, cabeceras y subtítulos. `providers.ts` comparte
preferencias y nombres entre pantallas. `player.ts` recibe cabeceras por
fuente. Android separa catálogo y jerarquía de proveedores en
`ProviderCatalog.kt`, consultas en `AnivexaClient.kt` y contratos Miruro en
`MiruroCatalogApi.kt` y `MiruroEmbedResolver.kt`. Estos dos últimos nombres
se verificaron en el fuente actual. La auditoría del ZIP histórico describe
su generación anterior con PipeBridge/WebView.

Kongroo adoptó la separación aplicable mediante perfiles inmutables de
hosts `public_embed_host_profiles.dart`. Declaran origen, patrón, puertos,
extractor, formato y cabeceras por medio. El manager conserva las
observaciones de salud y el reproductor permanece ajeno al parser.
Los hosts siguen sujetos a allowlists de compilación. La jerarquía por
idioma de Android y la re-resolución puntual de enlaces efímeros son
referencias para una ampliación posterior. No se comparó reproducción en
Anilili con el mismo vídeo.

AnimeAV1 resolvió un MP4 de `a4.mp4upload.com`, cuyo HEAD devolvió 403.
TioAnime resolvió un MP4 de `vidcache.net`, cuyo HEAD devolvió 500.
Se conservaron los dos conectores experimentales y el fallback ante un
fallo de host se probó con transportes simulados. La segunda fuente
externa reproducible sigue pendiente.

Los proyectos de agregación propuestos documentan interfaces distintas
y no aportaron una ruta autorizada aquí para descifrar el payload interno
de AllAnime o intermediar controles de terceros. No se realizó la consulta
GraphQL viva solicitada, ni se desplegó un agregador, FlareSolverr, proxy de IP,
proxy HLS/llaves o cron. La evidencia HLS con manifiesto y seek permanece
pendiente. Los mecanismos de selección revisados son compatibles con
extender el registro cuando exista una fuente con condiciones verificadas.

## Referencias primarias

- [User-Agent de Wikimedia](https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy)
  y [cuotas](https://www.mediawiki.org/wiki/Wikimedia_APIs/Rate_limits).
- [Caso de HTTP 429](https://phabricator.wikimedia.org/T413570) y
  [archivo de Commons](https://commons.wikimedia.org/wiki/File:Kouichi_Jun%27ichi_-_Namakura_Gatana_(1917)_-_4-minute_restored_version.webm).
- [Propiedades de mpv](https://mpv.io/manual/stable/#options-user-agent),
  contrato de media_kit y fuente local 1.2.6.
- [WIT en Anilili Desktop](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/wit/provider.wit)
  y [catálogo Anilili Android](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/ProviderCatalog.kt).
