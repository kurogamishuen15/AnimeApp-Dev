# OC-03.1 · Estado de ejecución

**Seguimiento vigente.** El [checkpoint de transporte](OC03-1-REMOTE-TRANSPORT-2026-11-16.md)
registra un A/B del UA, cuadros remotos visibles en Wikimedia 480p, seek
a 20 s y reapertura. La tabla de abajo conserva la ejecución anterior
al cambio de UA.

16 de noviembre de 2026. Fedora 44 con KDE y GTK bajo XWayland para la
verificación interactiva. HEAD de partida y cierre de esta ejecución
`6cc3e5e`. Se preservaron los cambios pendientes de OpenCode. Toolchain local
Flutter 3.47.9, Dart 3.13.7, Dio 5.11.1 y media_kit 1.2.6.

| Gate | Estado | Evidencia |
|---|---|---|
| Auditoría y baseline | PASS | Revisión independiente de Home, AniList, Kitsu, Drift y progreso. Baseline 326 Flutter aprobadas y 9 omitidas. |
| Descubrimiento y resolución | PASS para 2 canarios | Naruto 1 → TioAnime → YourUpload y One Piece 1 → AnimeAV1 → MP4Upload. Los tests en red usaron la cadena del manager hasta obtener la URL, sin descargar esos medios. Ambos conectores quedan desactivados por defecto. |
| Fuente con catálogo y permiso documentado | Implementada | Wikimedia Commons se registra en el producto. Su cruce exacto con AniList 6654 abarca *Namakura Gatana*, película completa de dominio público. La API publicó 240p y 480p. Kitsu entregó el episodio 1. |
| Transporte/decodificación | PARCIAL | Rango de 480p y original HTTP 206 por curl. Descarga normal de 480p HTTP 200, 27.732.189 bytes. La copia íntegra abre en ffprobe como VP9/Opus 612×480, 258,8 s. FFmpeg extrajo un cuadro real a 20 s. El mismo 480p remoto devolvió HTTP 429 a ffprobe aun sin ICY y con seek remoto desactivado. Curl también obtuvo HTTP/1.1 200 en HEAD. Las diferencias de transporte son reproducibles. La regla exacta del servidor sigue sin determinarse. |
| Fedora, de la ficha al player | PARCIAL | Se buscó *The Dull Sword*, se abrió la ficha, se indexó el episodio, se mostraron 240p/480p, se seleccionó 480p, se intentó 240p y se regresó a la ficha. libmpv quedó en 00:00 con error y pantalla negra en ambas alternativas. El log muestra render por software. El motor y su configuración permanecen protegidos. |
| Reanudación y progreso | PARCIAL | Pruebas de duración tardía/desconocida, seek sin confirmación, cancelación y cambio de contexto. Seek a 3 s confirmado por libmpv con el fixture local. El producto guarda por identidad local y episodio durante reproducción, pausa o cierre. La sesión en red fallida no pudo generar progreso positivo. |
| Cierre y plataformas | PARCIAL | Retorno gráfico a la ficha y prueba local de reanudación. Android, Windows, audio visible/audible y medición de recursos siguen pendientes. |

## Reproducción de verificaciones

- `.ai-local/oc03-baseline.log` contiene el baseline. `.ai-local/oc03-final-tests.log`
  registra 334 aprobadas y 11 omitidas. La corrida posterior y focalizada
  `.ai-local/oc03-verified-targeted.log` registra 39 aprobadas con los dos canarios
  de red y la reanudación nativa habilitados.
- `.ai-local/oc03-analyze-verified.log` registra análisis estático limpio.
  `.ai-local/oc03-build-final.log` registra el build Linux usado en Fedora.
- Las capturas `provider-picker.png`, `provider-open.png`, `provider-fallback.png`
  y `provider-return.png` están en `.ai-local/oc03-fedora/`. Ese directorio
  también contiene la base aislada de la prueba, logs de transporte y el
  control local `commons-control-decoded.png`. El cuadro proviene de FFmpeg
  local y el player de producto reportó error remoto.

## Servicios pendientes

AnimeGG, AniZone y AnimeHeaven dieron respuestas de página en las sondas. Falta
validar correspondencia, host y medio autorizados en esas cadenas. El dominio
consultado de KickAssAnime devolvió 410. AnimesDigital sigue con el adaptador
experimental existente. La portada devolvió 301 y se conserva la evidencia
previa de HLS sin cuadros. Zilla devolvió 403 y StreamSB agotó 8 s. Mega,
OK.ru y Netu aparecieron como candidatos de TioAnime. FileStream, Bee, Goma File
Stream, Filemoon y StreamWish quedan sin contrato de resolución validado
para esta composición.

La configuración experimental requiere una ruta de acceso autorizada en la
instalación que la habilite. El anexo anterior propuso técnicas de evasión y
Media3. OC-03.1 establece el límite vigente sobre controles de acceso y
preserva media_kit/libmpv. Los diagnósticos publican host, código HTTP y
`Server` saneado. Los primeros 200 bytes de fallos solo se examinan en
memoria para clasificar señales conocidas. Ver la
[auditoría técnica](../audits/OC03-1-audit-2026-11-16.md).
