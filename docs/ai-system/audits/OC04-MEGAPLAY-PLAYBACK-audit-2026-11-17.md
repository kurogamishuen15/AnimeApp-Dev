# OC-04 · Reproducción real de Tokyo Ghoul:re 9

Verificado en la ventana de Kongroo, Fedora Linux, usando el backend directo
de `bee` que implementa Anilili como MegaPlay. La interfaz parte de `main()`:
búsqueda, ficha AniList 100240, episodio 9, descubrimiento y selección de fuente,
player media_kit/libmpv, pausa, seek, reanudación, progreso y retorno a la ficha.
La fase general OC-03 conserva pendientes para otros hosts y plataformas.

## Cambios y causas comprobadas

| Hallazgo | Evidencia | Corrección |
| --- | --- | --- |
| MP-01 · P1 · Faltaba el acceso directo al backend de bee. | Anilili Desktop publica `providers/megaplay/src/lib.rs`, que recibe AniList y episodio. El catálogo Miruro sigue respondiendo 403. | `MegaPlayPlaybackProvider`, registrado junto a Miruro, adapta esa ruta a los contratos existentes y reutiliza el resolver directo. |
| MP-02 · P1 · El códec H.264 del sistema es una sustitución. | `rpm -qf /lib64/libopenh264.so.8` devuelve `noopenh264-2.6.0-4.fc44.x86_64`. Con ese mismo libmpv hay audio/posición y no existen propiedades de salida de video. | OpenH264 oficial de Cisco descargado separadamente dentro del proyecto, seleccionable por proceso mediante el lanzador. Con él, el mismo libmpv entrega 1920×1080. |
| MP-03 · P1 · Callback GTK usa memoria liberada al cerrar. | GDB confirmó el hilo principal bloqueado en `video_output.cc:280`, con `VideoOutput.ref_count=0` y mutex corrupto. | CMake compila una copia generada con `gdk_threads_add_idle_full`, una referencia al objeto y liberación mediante destroy-notify. No se modifica el caché del paquete. El recorrido pausa→seek→play→cierre pasó después. |
| MP-04 · P2 · Contexto HTTP incompleto. | MegaPlay declara Referer y Origin para el medio y X-Requested-With para su endpoint AJAX. | Origin HTTPS público validado en el contrato, contexto por petición y comprobación nativa de propagación y aislamiento. |

El provider lee el ID de archivo del embed y las rutas publicadas por el
script de MegaPlay. Su respuesta puede ser JSON claro o AES-256-CBC/PKCS7 con
base64url sin padding. Usa `cryptography 2.9.0`, revisado independientemente,
con las longitudes y límites del protocolo. Los parámetros son públicos y
proceden del cliente del servicio. Los 403/challenges se propagan como errores.
Los títulos y episodios se cruzan por AniList, sin búsqueda difusa.

El source de referencia, bajo MIT-0, es Anilili Desktop
`e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd`.
[MegaPlay de Anilili](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/providers/megaplay/src/lib.rs),
[contrato GTK](https://docs.gtk.org/gdk3/func.threads_add_idle_full.html).
Las licencias y el control del códec están en
[PLAYBACK-DEPENDENCIES.md](../../third-party/PLAYBACK-DEPENDENCIES.md).

## Evidencia ejecutada

- **Pruebas automatizadas**. Suite completa secuencial, con las pruebas opt-in
  HTTP y HLS local: **350 aprobadas, 8 omitidas**. Se comprobó que libmpv envía
  Origin/Referer/UA en replay y los limpia al cambiar a otra fuente.
- **Red**. Embed por AniList 100240/9, script de rutas, respuesta de fuentes,
  manifiesto HLS, variante y segmento devolvieron 200. El segmento tiene
  extensión de imagen y contenido MPEG-TS. `ffprobe` abrió con la política de
  extensiones explícita del diagnóstico y el códec local: H.264 1920×1080,
  AAC y duración **1449,629960 segundos**.
- **Ventana real**. `integration_test/anime_playback_live_test.dart` ejecuta
  `main()` y eventos de puntero del framework, sin providers fake. Las
  capturas del compositor muestran fotogramas diferentes a 00:56 y 01:03.
- **Reanudación y cierre**. La ejecución final aprobó en 28 segundos.
  Reanudó desde **120870 ms**, confirmó frame a **124249 ms**, seek en pausa
  a **134332 ms**, guardó **143351 ms** y regresó a la ficha. La base SQLite
  aislada conserva `episode:9`, posición **143351**, duración **1449629**.
- **Compilación y análisis**. Flutter 3.50.0-0.4.pre y Dart 3.14.0 del
  proyecto. Se comprueba la compilación normal `lib/main.dart` además de la
  ejecución de dispositivo. El Ninja generado enlaza exclusivamente
  `kongroo_video_output.cc.o` para esa traducción del plugin.

Evidencia local ignorada por Git en `.ai-local/bee-fix/`: `gui-live.log`,
`gui-final-live.log`, `full-tests-final.log`, `megaplay-ffprobe-codec.log`,
`native-close-mutex.log` y `kongroo-tokyo-ghoul-re-9-frame1.png`/`frame2.png`.
Las URLs temporales no se incorporan al código ni a la documentación.

Hubo pruebas anteriores interrumpidas y un timeout durante saturación de
memoria. Se repitieron secuencialmente y no se cuentan como aprobadas.
Dos fallos del nuevo test al localizar controles se corrigieron esperando
controles pulsables y desplazando el índice perezoso de episodios.

## Revisión y límites

Auditor independiente de solo lectura revisó dependencias, contratos,
provider, lanzador y vida útil del callback. Se corrigieron dos P2 del
lanzador: descompresión sin límite y temporales que sobrevivían a `exec`.
El seek del test se verifica en pausa para impedir un pase por avance natural.
El lanzador se probó descargando, verificando hash y retirando temporales.

Miruro continúa denegando el acceso. La reproducción usa el backend directo
publicado por Anilili. Solo este título/episodio/backend se acredita en esta
prueba. Otros hosts, Android/Windows y rendimiento en un equipo de 4 GB siguen
pendientes. No se hicieron commits ni pushes ni cambios de configuración global.
