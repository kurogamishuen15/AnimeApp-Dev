# OC-03 · Tokyo Ghoul:re 9 en Anilili y Kongroo

El propietario reprodujo el episodio 9 en la instancia de Anilili para
Fedora y comunicó el servidor `bee`. Corresponde a la primera temporada
de Tokyo Ghoul:re, [AniList 100240](https://anilist.co/anime/100240).
La captura de la ventana activa devolvió un archivo vacío. La observación
de reproducción en Anilili procede del usuario.

## Recorrido de código

Se inspeccionó Anilili Desktop en
`e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd`.

1. `catalog.rs` resuelve AniList en Miruro y combina sus alternativas con
   las de proveedores WebAssembly. El catálogo de Miruro identifica el
   título por AniList y resuelve el episodio por número.
   [Catálogo de escritorio](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src-tauri/src/catalog.rs).
2. `bee` es el nombre visible de AniKoto en Miruro. Su adaptador reúne
   configuración, respuesta del episodio, alternativas de medio y
   cabeceras. `net.rs` usa `wreq` con emulación de Chrome para este tipo
   de peticiones.
   [Etiquetas](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src/lib/providers.ts),
   [Miruro](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/miruro.rs),
   [transporte](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/net.rs).
3. `watch.rs` elige el servidor y el medio y envía la solicitud a
   `player.rs`, que llama a `loadfile` de libmpv con el contexto de la
   fuente. Hay una ruta condicional por proxy. No se verificó que la
   instancia instalada usara ese proxy en este episodio.
   [Selección](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src-tauri/src/watch.rs),
   [reproductor](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src-tauri/src/player.rs).

## Diferencia comprobada

`PlaybackProvidersModule` registra AnimeAV1, TioAnime, AnimesDigital,
Wikimedia y fuentes definidas por el usuario cuando corresponde. La
ruta Miruro/AniKoto está fuera del registro. El adaptador histórico de
Miruro se retiró antes de esta tarea y su intento de acceso directo ya
registraba 403. [Evidencia histórica](../missions/S0-ANILILI-PORT-REPORT.md).

Para separar la falta de registro de un problema de transporte,
se hicieron cuatro GET con la identidad de catálogo de Kongroo,
sin cookies, credenciales ni redirecciones. Resultados en Fedora:

| Origen | Configuración | Búsqueda por AniList 100240 |
| --- | --- | --- |
| `www.miruro.to` | HTTP/2 403, HTML, Cloudflare | HTTP/2 403, HTML, Cloudflare |
| `www.miruro.tv` | HTTP/2 403, HTML, Cloudflare | HTTP/2 403, HTML, Cloudflare |

La ruta directa se detiene antes de resolver el episodio y de entregar
medio a libmpv. La diferencia de transporte está demostrada en código,
pero no se aisló qué condición usó Cloudflare. No se empleó emulación
de navegador para intentar superar el 403. La licencia de Anilili
corresponde a su código; no aporta autorización del servicio para
el acceso de Kongroo. Se conserva la ruta fuera del registro.

## Validación

- Sondas de red en `.ai-local/anilili-comparison/bee-catalog-probe.log`.
  Solo se registraron códigos y tipo de contenido, sin cuerpos.
- Flutter del proyecto, suites de composición, proveedores públicos y
  transporte de medios: 18 aprobadas y 2 optativas de red omitidas.
- Sin cambios de producto. Queda pendiente comprobar vídeo en Kongroo
  si se obtiene acceso autorizado a esta ruta.
