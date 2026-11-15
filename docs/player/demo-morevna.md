# Kongroo DEMO con Morevna

## Inicio y reproducción

Desde la raíz Git:

    python3 tools/player/run_player_demo.py

El launcher prepara los recursos antes de ejecutar Kongroo y usa el Flutter 3.47.9 aislado. Requiere curl, FFmpeg/ffprobe y las dependencias Flutter del proyecto. Los medios permanecen en .ai-local/player-demo/real. Valida SHA-1 de las publicaciones OGV, limita descarga/redirects, valida los SRT de una revisión fijada mediante SHA-256, genera MKV por copia de streams y escribe el inventario ffprobe. Usa archivos ya descargados en ejecuciones posteriores. La opción --synthetic mantiene los fixtures de tonos para pruebas técnicas. Por ejemplo, para reproducir el fotograma con diálogo:

    python3 tools/player/run_player_demo.py --start-at 27 --subtitles spa

El comando sin opciones reproduce Morevna desde el inicio. Usar --paused para esperar a Play. Las opciones de escena o idioma abren en pausa y admiten --autoplay para reproducir desde la posición elegida. La zona de controles queda bajo el vídeo en ventana y se superpone en fullscreen. Servidores y Episodios abren paneles propios. Audio, Subtítulos y Modo Nerd se abren desde sus iconos.

## Obras, créditos y pistas verificadas

| Entrada | Fuente comprobada | Duración | Pistas |
|---|---|---:|---|
| Morevna 3.0.2 | [OGV inglés del autor](https://archive.org/download/morevna-ep3/morevna-3.0.2-en-hq.ogv) | 617,607 s | Vídeo Theora 534×300. Vorbis estéreo 44,1 kHz, voz inglesa. SRT inglés, español y ruso |
| Morevna 4.0.1 | [OGV ruso del autor](https://archive.org/download/morevna-ep4/morevna-4.0.1-ru-hq.ogv) | 628,077 s | Vídeo Theora 534×300. Vorbis estéreo 44,1 kHz, voz rusa. SRT inglés, español y ruso |
| Sintel, tráiler | [OGV 480p de Blender](https://download.blender.org/durian/trailer/sintel_trailer-480p.ogv) | 52,25 s | Theora, Vorbis estéreo 48 kHz. ffprobe y apertura con seek en libmpv ejecutados. Se conserva como muestra complementaria fuera del menú Morevna |

Verificación y obtención del 12 de noviembre de 2026. Morevna es obra de Morevna Project. La edición inglesa acredita a Duffy Weber y Marielena Alcaraz. Los créditos completos se conservan en los archivos. Las fichas oficiales de [episodio 3](https://morevnaproject.org/anime/episode-3/) y [episodio 4](https://morevnaproject.org/anime/episode-4/) declaran CC BY-SA 4.0. El registro de Archive del episodio 3 declara BY-SA 3.0 para el ítem archivado. Se mantiene esa distinción de procedencia. Las [traducciones](https://github.com/morevnaproject-org/subtitles-translation) declaran CC BY 4.0. Los SRT españoles acreditan a RJ Quiralta (3.0.2) y Raúl Castellanos (4.0.1). Se remultiplexaron las pistas y se añadieron etiquetas de idioma, sin recortar ni recodificar. Sintel se atribuye a Blender Foundation bajo [CC BY 3.0](https://durian.blender.org/sharing/).

Se comparó el OGV inglés y el OGV ruso de 3.0.2. Las duraciones de origen fueron 617,604 y 617,003 s. A cinco muestras por segundo, los mejores desplazamientos pasaron de 0 s a aproximadamente −0,6 s y después −1,4 s, según la zona. La correspondencia temporal no es constante. No se combinó el doblaje ruso con el montaje inglés. El ruso del episodio 4 conserva su propio vídeo. No se presenta el francés ni las muestras japonesas como pistas del DEMO. Los tonos sintéticos son otra prueba del motor.

La base de tiempo de pistas en los MKV es 1/1000. Los índices ffprobe 0/1 son vídeo/audio y 2/3/4 son SRT eng/spa/rus. Identificadores nativos de mpv se observan aparte y solo valen en la fuente activa. Los inventarios completos están en probe-1.json y probe-2.json del directorio real. Los análisis de comparación están en timeline-analysis.json y timeline-offset-windows.json.

El control **Calidad** enumera pistas/resoluciones reportadas por media_kit.
Estos dos medios Morevna tienen una sola pista Theora de 534×300, por lo que el
control informa calidad fija. La prueba de selección entre dos resoluciones usa
un fixture sintético separado bajo `.ai-local/player-quality/`; no representa
una escalera del servidor, un doblaje ni una variante remota. El launcher DEMO
no descarga ni inventa calidades alternativas.

## Servidores y arquitectura

A y B son listeners independientes que leen el mismo MKV. C responde 503. Los SHA-256 observados en esta corrida fueron ffb50b83649a3554bbfbc7c1fcd7749e2033f77a01a2b48df089bb0804eeda19 y 236323fd4329b1eaee4d5cf701a985ec0faa7e13c350f9e32fa014e3d34142ee. Se calculan tras la preparación. Una regeneración Matroska puede producir metadatos de contenedor distintos. El contrato de igualdad A/B se cumple usando el mismo archivo, sin depender de esos hashes históricos.

    main_player_spike → SpikePlayerModule → motor + coordinador + ventana GTK
    SpikePlayerPage → PlayerVideoLayout + controles
    PlayerDemoPanel → PlayerDemoSession → SpikePlayerCoordinator
    AudioTrackSelector / PlayerSubtitlePanel → SpikePlayerCoordinator
    ExternalSubtitleSearchPanel → ExternalSubtitleService → catálogo y loader
    SpikePlayerCoordinator → PlaybackSpikeEngine → MediaKitSpikeEngine → libmpv
    PlayerNerdPanel → snapshot y ProcessInfo

| Archivo o módulo | Responsabilidad y prueba |
|---|---|
| app/lib/app/player/spike_player_page.dart | Acciones compartidas, atajos, barra temporal y coalescencia de seek. La generación del gesto acompaña a la cola. Pruebas en spike_player_page_test.dart |
| app/lib/app/player/player_video_layout.dart | Mide barra y vídeo conservando el árbol de la superficie al variar fullscreen. Barra desplazable en tamaños extremos. Pruebas 1280×720, 1366×768 y 1920×1080 |
| app/lib/app/player/player_demo_panel.dart y app/lib/application/player/player_demo_session.dart | Presentación de fuentes/episodios frente a sesión, puntos de retorno y solicitud serializada. Los widgets no ejecutan HTTP ni recuperación nativa |
| app/lib/app/player/audio_track_selector.dart | Menú de pistas reales con estado marcado. Cada opción conserva ID nativo, generación de fuente y revisión de contexto; descarta IDs obsoletos antes del adaptador. Widget tests cubren cambio en cola y Stop pendiente; integración libmpv verifica selección en fuentes reales |
| app/lib/app/player/player_subtitle_panel.dart | Modal de pista, estilo, delay y búsqueda. Los ajustes se conservan tras confirmación y el panel libera su suscripción al cerrar |
| app/lib/application/player/external_subtitles/ y app/lib/data/opensubtitles/ | Catálogo, almacenamiento, cuota y loader. Al aplicar descarga se comprueba la generación capturada. No se hizo consulta con credenciales reales |
| app/lib/application/player/providers/ y source_switching/ | Descubrimiento y alternativas con contratos tipados. El catálogo local usa los espejos de la transacción del coordinador, no un segundo provider manager |
| app/lib/application/player/skips/ y app/lib/data/aniskip/ | Servicio y caché de segmentos. Los episodios Morevna carecen de mapeo MAL en el DEMO |
| app/lib/app/player/player_nerd_panel.dart | Timer de dos segundos mientras el diálogo está abierto, copia saneada y RSS. No controla Player ni realiza sondeo con el diálogo cerrado |
| app/lib/app/player/media_kit_video_surface.dart y app/lib/data/player/engine/ | Textura única, relación de aspecto, sin controles propios de media_kit. El adapter posee Player y VideoController. El callback de tamaño/primer frame del paquete no mide presentación del compositor |
| app/lib/app/player/player_window_controller.dart y app/linux/runner/my_application.cc | Solicitudes GTK y confirmación por estado de ventana. F, Escape y botón comparten las acciones del coordinador de ventana |
| tools/player/prepare_real_player_demo.py y run_player_demo.py | Descarga reproducible, protección de rutas, informe ffprobe, lanzamiento y cierre de los listeners A/B/C. Logs HTTP en terminal. Sin persistencia rotativa de logs |

El checker de imports revisa aplicación y presentación del player. Rechaza cliente HTTP desde panel y dependencia de aplicación hacia adaptadores o Flutter. Composición y textura tienen excepciones explícitas. Los casos negativos ejecutan el checker de verdad.

## Comandos de prueba

    export PATH="$PWD/.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
    bash scripts/ci.sh
    cd app
    flutter test --no-pub test/player/spike_player_page_test.dart
    KONGROO_TEST_REAL_DEMO=1 flutter test --no-pub test/player/media_kit_spike_integration_test.dart --name 'Morevna selects|uses DEMO HTTP|completes twenty opens'

Los fixtures reales se preparan con python3 tools/player/prepare_real_player_demo.py desde la raíz. El caso local requiere haberlos preparado. Las pruebas de widgets usan fakes. Las pruebas nativas verifican selección, continuidad y recursos, y la captura de la ventana verifica el resultado de presentación.

## Extensión

Una entrada de medios real requiere fuente oficial, licencia, SHA y probe. Un espejo debe apuntar a esos mismos bytes. La pista se descubre por metadatos del motor. Los proveedores externos se agregan por contrato y manager. Los estilos nuevos requieren un valor validado en dominio, aplicación real por libmpv y control en el diálogo. Las métricas nuevas del Modo Nerd deben leer un snapshot o consulta acotada y suspenderse al cerrar el diálogo.

## Evidencias y estado

Ver [auditoría de interfaz y medios](../ai-system/audits/UI-Morevna-audit-2026-11-12.md). Se conservaron capturas reales de la misma escena con SRT español e inglés, obtenidas mediante opciones de arranque. Los menús y sus acciones se probaron con widgets y los efectos del motor se probaron por separado. No se ejecutaron clics de escritorio en esta sesión.
