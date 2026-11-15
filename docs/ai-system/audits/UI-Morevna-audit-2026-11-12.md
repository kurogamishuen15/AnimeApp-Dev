# Auditoría focalizada UI y medios Morevna

## Alcance y criterio

Corrección de controles del DEMO y validación con contenido real. Revisión independiente de código por auditor_codigo, con una segunda revisión de las correcciones y ejecuciones del coordinador. Resultado de aceptación técnica: parcial. Las capturas del compositor muestran el resultado visual. La interacción con ratón/teclado real permanece bloqueada.

## Inventario y fuentes

El [inventario, grafo y contratos](../../player/demo-morevna.md) cubren presentación, aplicación, dominio, integraciones, GTK y herramientas de medios. Revisados SpikePlayerPage, PlayerVideoLayout, PlayerDemoPanel, PlayerSubtitlePanel, AudioTrackSelector, PlayerNerdPanel, PlayerDemoSession, SpikePlayerCoordinator, ExternalSubtitleService, MediaKitVideoSurface, MediaKitSpikeEngine, el launcher y el preparador. Existe un Player y VideoController por módulo. Los paneles consumen snapshots y comandos. No se identificó un coordinador de reproducción paralelo. El checker comprueba dirección de dependencias. No realiza análisis general de ciclos transitorios.

Fuentes consultadas el 12 de noviembre de 2026: [Morevna 3](https://morevnaproject.org/anime/episode-3/), [Morevna 4](https://morevnaproject.org/anime/episode-4/), [Gumroad](https://morevnaproject.gumroad.com/l/morevna-episode-3), [Sintel](https://durian.blender.org/download/), [licencia Sintel](https://durian.blender.org/sharing/), [Anilili Android](https://github.com/sanilili/Anilili), [desktop](https://github.com/sanilili/desktoprepo1), [Flutter Material](https://docs.flutter.dev/ui/widgets/material), [Material 3](https://m3.material.io/components) y [media_kit](https://pub.dev/packages/media_kit). El patrón adoptado separa la barra habitual de paneles contextuales. No se copiaron recursos de las interfaces consultadas.

## Hallazgos

| ID | Severidad | Evidencia y reproducción | Corrección y resultado |
|---|---|---|---|
| UI-01 | P1 | La captura release inicial presentaba iconos erróneos. El OTF de 2472 bytes no incluía las nuevas posiciones Unicode de la barra. | El launcher compila con --no-tree-shake-icons. fc-query confirma la fuente completa. Capturas posteriores muestran seek, servidores, audio y CC legibles |
| UI-02 | P1 | tools/player/prepare_real_player_demo.py, prepare_real_demo. probe-1.json podía ser un symlink. La escritura directa seguía su destino. | Se rechaza el enlace y se escribe en temporal antes del reemplazo. Prueba con un sentinel en un directorio aislado confirmó que no se modifica |
| UI-03 | P2 | spike_player_page.dart, _drainSeekQueue. Un destino coalescido podía ejecutarse sobre el capítulo siguiente al terminar una espera. | Captura de generación del gesto y comprobación en la cola del coordinador. Suite de seek y Stop pasa. Repro dedicada de cambio de episodio con seek pendiente queda por añadir |
| UI-04 | P2 | external_subtitle_service.dart, downloadAndLoad. Una descarga iniciada antes del cambio podía llegar a otra fuente. | Generación de la fuente pasa del servicio al loader y se valida dentro de la cola. CI pasa. Falta caso dedicado con HTTP diferido |
| UI-05 | P2 | spike_player_coordinator.dart, switchSource y _restoreSource. Un rollback podía perder pista explícita. El idioma por sí solo podía seleccionar una pista ambigua. | Se conserva identidad con metadatos concordantes y solo se usa una coincidencia por idioma si es única. Prueba HTTP real de A→B y 503 comprobó inglés y español conservados. Restaurar subtítulo externo en espejo queda pendiente |
| UI-06 | P2 | player_subtitle_panel.dart, ajustes. Los valores podían anunciarse antes de confirmar el adaptador. | Se confirma primero y se conserva el último valor aplicado. CI de controles y pruebas nativas de estilo/delay pasan. Falta caso específico de rechazo del adaptador |
| UI-07 | P2 | player_video_layout.dart, barra extrema. Varias filas podían consumir la altura del vídeo. | Altura de barra limitada y scroll. Tests sin overflow en 1280×720, 1366×768 y 1920×1080. En normal se reserva altura para que la barra no cubra el subtítulo. Fullscreen usa overlay y mantiene la superficie montada |
| UI-08 | P1 abierto | Material original ep3 inglés y ruso con desfase variable. Decodificación H.264 del entorno devolvió Unable to create decoder. | Se usa OGV Theora/Vorbis verificado y cada edición conserva su propio audio. Selección entre dos doblajes de una misma edición y comprobación auditiva pendientes |
| UI-09 | P1 abierto | KDE Wayland. ydotool.service inactivo y socket ausente. El portal publicó la interfaz en introspección, pero CreateSession devolvió org.freedesktop.DBus.Error.UnknownMethod. El PID de Kongroo no se registró en AT-SPI y el runner informó atk_socket_embed, plug_id NULL. | Capturas de Spectacle disponibles. No hubo envío efectivo de teclas o clics. Repetir secuencia manual en la ventana cuando haya entrada efectiva |
| UI-10 | P2 abierto | El callback del plugin se basa en cambios de rect/texture y el observador anterior se suscribía a Playing después de un posible autoplay. First frame pending no era medición de compositor. | Se retiró el overlay y el observador redundante. Modo Nerd indica que no dispone de métrica de primer frame. Las capturas prueban imagen presentada |

## Niveles de evidencia

| Función | Código | Tests | Motor | Compositor/interacción | Estado |
|---|---|---|---|---|---|
| Morevna real | Sí | Sí | Theora/Vorbis | Imagen y progreso observados | Verificado para imagen |
| Audio hablado multiidioma | Una voz por episodio | Multipista sintético | Confirmación de pista inglesa al cambiar espejo | Sin verificación auditiva | Bloqueado |
| Subtítulos ES/EN | Sí | Sí | Selección y desactivación | Capturas de la misma escena con ES y EN por opción de arranque | Parcial |
| Estilo y delay | Sí | Sí | Propiedades mpv verificadas | Comparación visual pendiente | Parcial |
| Servidores y posición | Sí | Clics de widgets | A→B, <=2 s, C 503, retorno a B | Clics de escritorio pendientes | Parcial |
| Play/Pause, Stop, seek ±10 y slider | Sí | Widgets | Operaciones reales cubiertas | Reproducción visible, clics pendientes | Parcial |
| Volumen/mute | Sí | Widgets | Comando y estado de volumen | Escucha y clics pendientes | Parcial |
| Episodios | Sí | Siguiente/anterior con UI fake | Dos medios preparados, continuidad real probada por espejo | Navegación manual pendiente | Parcial |
| Fullscreen | Sí | Widget y menú en tres tamaños | Control GTK conectado | F/Escape y overlay pendientes en esta corrida | Parcial |
| Nerd y logs | Sí | Abrir/cerrar diálogo en widget | Lectura de snapshot y RSS | Diálogo real pendiente | Parcial |
| Rendimiento | Sí | 20 aperturas/Stop con Morevna | Lease liberado | RSS/PSS y CPU en ventana, resto pendiente | Parcial |

## Ejecución y rendimiento

Fedora 44 KDE Wayland, x86_64, Flutter 3.47.9, Dart 3.13.7, media_kit 1.2.6 y mpv-libs 0.41.0. El proyecto pasó CI con 204 Flutter, 40 infraestructura y un caso Morevna omitido por defecto. Ese caso, continuidad HTTP con pistas preservadas y 20 ciclos Morevna pasaron juntos al habilitar el corpus real. Build Linux release y launcher con subtítulos publicados ejecutados. Logs de la corrida en .ai-local/player-demo/evidence/ui/. Memoria y git diff --check exit 0.

Muestra normal con reproducción Morevna 534×300, audio habilitado y subtítulos ES seleccionados: 297624 KiB RSS, 248972 KiB PSS y 22% de un núcleo en 2 s. Pausa con EN: 292992 KiB RSS y 245262 KiB PSS. El primer RSS equivale a 304,8 MB decimales y 290,6 MiB. No acredita un techo de 300 MB ni hardware de 4 GB. Render de la superficie por software según el plugin. No se midieron tiempo a primer frame, fullscreen, costo incremental Nerd, GPU ni veinte cierres gráficos. El proceso flutter_tester muestreó 359022592 bytes antes de 20 aperturas, 401915904 máximo observado tras Stop y 382775296 después de Dispose. Es una medición del proceso de pruebas y no una prueba de fuga. El cierre de las corridas gráficas se hizo por señal dirigida al PID de prueba, por lo que no acredita la ruta GTK.

Para completar la aceptación: ejecutar con ratón real Play, +10, −10, Audio, Subtítulos ES/EN/Off y estilo, A/B/C, Siguiente/Anterior, F/Escape, Nerd y cerrar. Registrar posición, pista y servidor observado, capturar los paneles y verificar cierre GTK. No hay equivalencia demostrada entre los doblajes de 3.0.2. La validación en 4 GB y las consultas reales a OpenSubtitles quedan pendientes.

### Reevaluación de entrega

El auditor volvió a inspeccionar las correcciones de rutas, generación, pistas, layout y confirmación de preferencias. No encontró nuevos P0/P1 en esos cambios. Permanecen el subtítulo externo ya cargado que no se reabre al cambiar de espejo y la ventana de carrera al cerrar y reabrir ajustes durante una operación pendiente. Son P2 acotados y no equivalen a los bloqueos de interacción y audio hablado.

La corrida real final añadió episodio 3 → 4 → 3, verificó el cambio de pista disponible inglesa/rusa según el contenido, y abrió el tráiler Sintel OGV como medio local con seek. Pasaron tres casos nativos. Se conservan ci-delivery.log y real-native-complete.log. El caso de 20 aperturas en esa corrida muestreó 366792704 bytes antes, 389832704 máximo tras Stop y 383934464 después de Dispose. Es RSS de flutter_tester.

La primera captura del arranque en pausa a cero mostró negro. El launcher real sin argumentos inicia ahora Morevna automáticamente desde 0. --paused permite esperar a Play. La corrida posterior sin argumentos muestra créditos y posición avanzando en default-playing.png.
