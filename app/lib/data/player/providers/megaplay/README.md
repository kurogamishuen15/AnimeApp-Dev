# MegaPlay directo

`MegaPlayPlaybackProvider` adapta el backend público de `bee` de Anilili a
`EpisodeSourceAdapter` y `DirectMediaHostResolver`, sin otra ruta de reproducción.
El endpoint contiene exactamente el ID AniList y episodio solicitado; esta
identidad es evidencia del contrato del endpoint, no metadatos de una búsqueda.
**Fallback MyAnimeList (2026-11-17):** si la ruta `/stream/ani/{anilistId}/...`
falla (404/403/página sin `data-id`) y la identidad publica `idMal`, el adaptador
prueba `/stream/mal/{malId}/...`, igual que el `anikoto` de Anilili y que el
embed que 2Dhive publica hoy (verificado en vivo: la ruta MAL responde con su
propio `data-id` y un `getSources` completo). Las políticas del transporte se
conservan: cooldowns, challenges y rate-limits del origen no se reintegran;
solo 404/403 o ausencia de `data-id` activan el fallback.
La existencia se comprueba en el embed (`data-id` alfanumérico en div/span).
No publica un índice inventado: `listEpisodes` responde unsupported. Las variantes
`sub` y `dub` usan el mismo adapter con IDs de registro `megaplay` y
`megaplay-dub`, y comparten un transporte para respetar Retry-After por origen.
El selector conserva la denominación anunciada: Original (sub) y Doblaje (dub).
No inventa un código ISO del audio cuando el servicio no lo publica.

Los `tracks` captions/subtitles de esa respuesta se propagan como
`ProviderSubtitle` por el resolver existente hasta el motor. Solo acepta VTT
HTTPS público, hasta 32 pistas, conservando etiqueta, idioma anunciado y default;
ignora thumbnails, duplicados y pistas opcionales inválidas. El menú de
subtítulos permite seleccionar las pistas mediante media_kit/libmpv sin descargar
a otro proveedor ni reutilizar archivos de otro corte. Las URLs temporales no
se persisten. Inglés, español, japonés y portugués se normalizan solo cuando la
etiqueta los declara; otros idiomas conservan etiqueta e idioma unknown.
La distribución de idiomas depende del título: el episodio 9 de Tokyo Ghoul:re
publica English/English 2; Attack on Titan 1 publica también Spanish.

Procedencia: port de `providers/megaplay/src/lib.rs` de
[sanilili/desktoprepo1](https://github.com/sanilili/desktoprepo1), commit
`e1c84d`, licencia MIT-0; referencia local inspeccionada
`.ai-local/bee-fix/anilili-megaplay.rs` y cliente público de MegaPlay.
El adaptador reproduce su clave/IV públicos AES-256-CBC (clave con padding cero,
PKCS7 y base64/base64url), no credenciales. No ejecuta scripts ni obtiene tokens
externos, cookies o autenticación. El código upstream y su licencia deben
conservarse en el inventario de terceros del repositorio.

Las peticiones usan `PublicPlaybackHttp`: HTTPS, host exacto configurado,
cancelación, deadline de 6 s y límite de cuerpo. Se permite un único iframe de
la misma familia y origen. Las rutas extraídas del script se limitan a la
familia `stream/getSources...`, hasta tres incluyendo fallback. 403/challenge
se devuelven inmediatamente; no hay rotación de identidad ni reintentos.
No se guardan URLs firmadas, respuestas o rutas en caché en este módulo.

El candidato HLS directo conserva Referer y Origin del origen conocido,
nunca cabeceras del cuerpo remoto. El resolver valida sintaxis pública HTTPS;
esto no verifica DNS, manifiesto, decodificación, primer frame ni audio.
La validación de red previa del coordinador para AniList 100240 episodio 9
observó respuestas del embed, sources, manifiesto y segmentos; no sustituye
una prueba de vídeo. Los tests son fixtures de transporte, AES y manager.
El 17 de noviembre de 2026 se verificó la cadena desde `main()` de Kongroo:
búsqueda por la interfaz, ficha de AniList 100240, episodio 9, selector de
MegaPlay, textura de 1920×1080, seek de 10 segundos, persistencia y retorno.
Dos capturas del compositor muestran fotogramas diferentes. La reanudación
se verificó desde el progreso local guardado. Esto acredita este episodio y
backend en Fedora, con el códec H.264 local opcional. Miruro conserva su 403.
Las pruebas de otras plataformas y episodios permanecen pendientes.

La implementación usa `cryptography 2.9.0` para el formato del payload. Los
avisos y el lanzamiento Linux con el códec opcional están en
[PLAYBACK-DEPENDENCIES.md](../../../../../../docs/third-party/PLAYBACK-DEPENDENCIES.md).

# Estado de disponibilidad (2026-11-19)

Una prueba en vivo detectó una regresión del engine: al abrir una fuente con
captions remotas, el marcado `default` hacía que Kongroo las cargara durante
`open()`. libmpv emitía un error nativo por esa pista y el coordinador lo
trataba como fallo del medio, aunque el HLS hubiera mostrado el primer frame.
La prueba A/B del 19-11 aisló el problema: sin auto-cargar la pista externa, el
episodio 9 de Tokyo Ghoul:re completó
`FRAME → ADVANCE → SEEK → REOPEN → LIVE-ENGINE-OK` en Fedora. MegaPlay vuelve a
estar verificado en ese recorrido en **sub y dub**. Ambos completaron frame,
avance, seek a 20 s, reapertura y cierre limpio en la prueba del 19-11. Las
captions VTT siguen disponibles para selección explícita desde el menú.

El módulo de medios también registra una denegación 403 histórica del CDN en
otras comprobaciones. Esa observación no explica la regresión reproducida
aquí; el recorrido N5 actual de ambas variantes avanzó correctamente.
