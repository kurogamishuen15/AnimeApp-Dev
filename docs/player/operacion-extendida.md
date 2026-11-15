# Operación extendida del reproductor

## DEMO en Fedora

Desde la raíz Git, ejecutar:

    python3 tools/player/run_player_demo.py

El launcher usa Flutter 3.47.9 aislado, compila el entrypoint Linux release, genera dos MKV con FFmpeg, reserva tres puertos dinámicos sobre 127.0.0.1 y espera el cierre del binario. La opción --autoplay inicia el primer episodio. No necesita cuenta. Los fixtures y la evidencia local se generan bajo .ai-local/player-demo/.

| Entrada | Ruta | Contenido y alcance |
|---|---|---|
| Archivo local | .ai-local/player-demo/episode-{1,2}.mkv | Fixture original de Kongroo, 24 s, MPEG-4, AAC, SRT. Reloj visible |
| Demo A y B | http://127.0.0.1:<puerto>/episode-{1,2}.mkv | Dos listeners independientes sobre los mismos bytes. GET, HEAD y Range simple |
| Demo C | Misma ruta en el tercer puerto | Responde 503 para probar la restauración |
| Recurso remoto | Pendiente | Requiere verificar licencia, disponibilidad y seguridad de todos los destinos |

Cada episodio contiene tonos sintéticos de 440, 550 y 660 Hz etiquetados como eng, spa y jpn, y seis SRT originales (eng, spa, jpn, por, zho, kor). Son materiales de prueba del proyecto. El DEMO permanece separado del catálogo de producción.

Pulsa Play y abre **Audio** para cambiar de tono. El selector de subtítulos permite elegir pista interna, desactivar y ajustar estilo y delay. En el selector de servidor, prueba A y B y luego C. **Siguiente** y **Anterior** cambian de episodio y conservan la posición en memoria durante la sesión. **Modo Nerd** habilita muestreo cada dos segundos y el icono de estadísticas abre un resumen que se puede copiar. Los accesos HTTP se imprimen en la terminal del launcher.

## Contratos y dependencias

| Módulo | Contrato y recursos |
|---|---|
| domain/player/audio_track_info.dart | Metadatos opcionales y etiquetas. El ID solo vale dentro de la fuente. Rol comentario y audiodescripción pendientes |
| application/player/spike_player_coordinator.dart | Cola única para selección, seek y cambio. Valida generación de audio y saltos. Separa la posición del nuevo episodio de la posición de recuperación del anterior |
| data/player/engine/media_kit_spike_engine.dart | Player único. Usa setAudioTrack y comprueba aid en mpv. HTTP limitado a la lista de URI loopback exactas del DEMO |
| app/player/player_demo_panel.dart | Dos episodios, selección explícita y posiciones efímeras. Bloquea selecciones solapadas |
| app/player/player_nerd_panel.dart | Lee el snapshot y RSS mediante ProcessInfo. Cancela el timer al ocultar o desmontar. La copia excluye URLs, rutas y secretos |
| application/player/source_switching/ | Alternativas mediante el manager existente. Rechaza reentrada. El DEMO reutiliza la transacción del coordinador para selección explícita |
| domain/player/skips/, application/player/skips/, data/aniskip/ | Rangos por episodio, caché de siete días y automatización optativa. El DEMO sintético carece de correspondencia MAL y no activa consultas AniSkip |
| tools/player/generate_player_demo.py y run_player_demo.py | FFmpeg y Python estándar. Puertos efímeros, dos rutas permitidas por espejo y cierre de listeners al salir |

## Anilili

| Función | Implementación observada | Equivalente Kongroo | Brecha, decisión y prioridad |
|---|---|---|---|
| Motor | Media3 y MediaSession en Android. mpv y GTK/OpenGL en escritorio | Flutter, libmpv y un Player | Conservar stack. Alta |
| Audio y fuentes | Android distingue sub/dub que recarga fuente de la pista interna. Escritorio ordena alternativas por idioma y prioridad y define un contrato WASM | Selector de audio, providers y manager | Adoptar distinción de conceptos. Sin plugins WASM ni resolvedores copiados. Alta |
| Subtítulos | Pistas internas y externas, estilo e importación. Búsqueda OpenSubtitles opcional | SRT, ASS, mov_text y búsqueda manual existente | Contexto de episodio e importación manual pendientes. Alta |
| Episodios y ventana | Escritorio define políticas de cuenta atrás y fullscreen. Android tiene foco adaptable para TV | Navegación DEMO y GTK | Autoplay siguiente y prueba de foco pendientes. Media |
| Diagnóstico | Android exporta ZIP y escritorio rota logs y distingue backends GDK | Panel DEMO, RSS y copia saneada | Eventos, CPU y PSS persistentes pendientes. Media |
| Metadatos | media-index publica anime, episodios y mapeos conservadores. Deja vacías correspondencias ambiguas | Identidades locales | Mantener metadatos y resolución de servidores separados. Alta |

Evidencia: [PlaybackService](https://raw.githubusercontent.com/sanilili/Anilili/main/app/src/main/java/com/anilili/playback/PlaybackService.kt), [PlayerSettingsSheet](https://raw.githubusercontent.com/sanilili/Anilili/main/app/src/main/java/com/anilili/ui/watch/PlayerSettingsSheet.kt), [desktop mpv](https://raw.githubusercontent.com/sanilili/desktoprepo1/main/src-tauri/src/player.rs), [backend Linux](https://raw.githubusercontent.com/sanilili/desktoprepo1/main/src-tauri/src/player_linux.rs), [contrato](https://raw.githubusercontent.com/sanilili/desktoprepo1/main/wit/provider.wit), [diagnósticos](https://raw.githubusercontent.com/sanilili/desktoprepo1/main/src-tauri/src/diagnostics.rs), [generador del índice](https://raw.githubusercontent.com/sanilili/media-index/main/scripts/konoha_build.py) y [guía comunitaria](https://anilili.app/features.html). Los tres repositorios declaran MIT-0 y el índice atribuye metadatos a sus fuentes. Revisión estática. media-index no devuelve servidores de streaming. La ejecución Wayland del backend Anilili no se verificó.

## Compatibilidad

| Candidatos | Evidencia de este corte |
|---|---|
| MKV | Matroska, MPEG-4, AAC y SRT. Libmpv confirma reproducción, selección de audio y seek con cambio entre espejos |
| MP4 | ISO BMFF, MPEG-4 y AAC. Fixture original con prueba nativa de reproducción |
| M4V, WEBM, MOV, AVI | Contenedores pendientes de verificación individual |
| MPEG, MPG, TS, M2TS, MTS | MPEG-PS / MPEG-TS pendientes |
| FLV, F4V, WMV, ASF, OGV | Contenedores pendientes |
| 3GP, 3G2, VOB, MXF, RM, RMVB | Contenedores pendientes |
| MP3, M4A, AAC, FLAC, OGG, OPUS, WAV, WMA | Pendientes como entradas autónomas. AAC se verificó dentro de MKV y MP4 |
| AIFF, AC3, DTS, AMR, APE, WV, MKA | Audio candidato pendiente |
| M3U | Lista de reproducción pendiente |
| M3U8/HLS, MPD/DASH | Manifiestos pendientes. Requieren control de destinos secundarios |
| HTTP | Loopback, Range 206 y restauración tras 503 |
| HTTPS, RTSP, RTMP | Pendientes. Capacidad RTMP de la compilación sin medir |
| Página HTML y DRM | Fuera de capacidades verificadas |

## Auditoría y handoff

Se corrigieron la reentrada que podía desincronizar la fuente mostrada, el prerrequisito F2.2 del arranque DEMO y la selección de un bundle de otro entrypoint. El launcher comprueba enlaces simbólicos y excluye proxies heredados. El coordinador invalida saltos encolados para otra generación y rechaza el cambio cuando el snapshot de seek tiene un error. El stream de errores de media_kit 1.2.6 carece de identidad de fuente. Los errores nativos tardíos aún pueden atribuirse al origen equivocado.

Pendientes: entrada de URL externa y rutas libres con política de seguridad, fixtures por familia, recursos remotos autorizados, preferencias de pista, búsqueda OpenSubtitles por contexto, AniSkip conectado a una identidad real, logs rotativos y perfil de veinte ciclos y 4 GB. La búsqueda OpenSubtitles existente conserva la entrada manual y las pruebas con fixtures.

### Fuentes públicas investigadas

- La [suite Matroska](https://github.com/ietf-wg-cellar/matroska-test-files#5-multiple-audiosubtitles) documenta test5.mkv como H.264, AAC y AAC+ con dos audios en inglés, uno de comentario, y subtítulos en siete idiomas. La copia GStreamer no se pudo recuperar con la herramienta de consulta. Tamaño, licencia de redistribución y pistas del binario específico quedan pendientes.
- La consulta a [Morevna, episodio 3](https://morevnaproject.org/anime/episode-3/) agotó el tiempo. No se incorporó ningún enlace de descarga sin confirmar.
- [Apple HLS](https://developer.apple.com/streaming/examples/) publica Bip Bop y Apple TV Trailer con variantes de códec, audio y WebVTT. Su disponibilidad y reproducción con Kongroo quedan por probar.
- El adaptador existente se contrastó con [OpenSubtitles REST](https://ai.opensubtitles.com/api-docs), incluidos GET /subtitles y POST /download. No hubo transacciones con una cuenta real.
- El modelo de pista usa las propiedades observables de [media_kit 1.2.6](https://pub.dev/packages/media_kit/versions/1.2.6) y lee aid de [mpv](https://mpv.io/manual/stable/). El panel Nerd actual no consulta fps observado, caché del demuxer ni hwdec-current.

## Evidencia gráfica y rendimiento

Fedora 44, KDE Wayland, Flutter 3.47.9 / Dart 3.13.7, media_kit 1.2.6. RAM total del sistema: 7 852 856 KiB. La captura demo-window-live.png muestra reproducción real del MKV en el compositor a 00:21 y el selector de audio visible. Otra captura de una ejecución previa muestra el reloj a 00:23.958. El overlay heredado reportó First frame: pending pese a que el fotograma era visible. Se conserva esa discrepancia como diagnóstico pendiente.

| Muestra | RSS KiB | PSS KiB | CPU de ps |
|---|---:|---:|---:|
| Release durante reproducción, 00:22 de proceso | 261032 | 205671 | 24.4% acumulado desde arranque |
| Release después de finalizar el clip, 01:44 | 245384 | 175619 | 5.9% acumulado desde arranque |

No son picos ni mediciones de CPU por intervalo. El plugin informó render de video por software. La sesión nativa ejecutó 20 ciclos de Open → duración observada → Stop y comprobó liberación del lease al disponer. La medición de esa prueba incluye flutter_tester. No equivale a 20 arranques/cierres GTK ni certifica uso en 4 GB. RSS y PSS del release se registraron en release-process.txt y release-process-end.txt.

El MCP seleccionó Spectacle para captura. Teclado y puntero no disponibles. ydotool.service inactivo y el socket /tmp/.ydotool_socket inexistente. La captura se limitó a la ventana de Kongroo. La finalización de la corrida de evidencia se hizo por señal al proceso de prueba y no cubre el cierre GTK. Fullscreen y cambios interactivos mediante el compositor requieren repetición.

### Validaciones de entrega

| Comprobación | Resultado | Evidencia local |
|---|---|---|
| CI completa con SDK aislado | Exit 0, 40 pruebas de infraestructura y 199 Flutter. Formato, Dart analyze, Flutter analyze, checker de imports y memoria pasaron | .ai-local/player-demo/evidence/ci-final-delivery.log |
| Linux release | Exit 0 con flutter build linux --release --no-pub -t lib/main_player_spike.dart | .ai-local/player-demo/evidence/build-delivery.log |
| Launcher sin argumentos | Build, tres listeners y arranque de textura 480×270 observados. El wrapper de prueba terminó con exit 124 al vencer su límite, sin dejar el proceso ni los listeners. No se probó aquí el cierre GTK por el gestor de ventanas | .ai-local/player-demo/evidence/launcher-default.log |
| Audio nativo | Selección spa durante Play y jpn/eng en Pause, confirmación aid, posición conservada, rechazo de ID inválido | CI y media_kit_spike_integration_test.dart |
| Servidores | Range 206 en A y B, reproducción nativa en A, cambio a B dentro de dos segundos y retorno a B tras 503 de C | CI y http-native.log |
| Veinte aperturas nativas | 20/20 Open → Stop y lease liberado. RSS del proceso de pruebas en bytes: 244850688 inicial, 390316032 máximo muestreado tras Stop y 383340544 después de Dispose | CI final |

Equipo x86_64 con Intel Core i5-1035G1 y ocho CPU lógicas. FFmpeg 8.1.3, mpv-libs 0.41.0 y GTK 3.24.52. Fedora proporciona mpv-libs, cuyo RPM declara licencias GPL, LGPL, BSD, ISC y MIT para sus componentes. GTK declara LGPL-2.0-or-later. No se preparó un artefacto de distribución.

La auditoría independiente detectó un P1 adicional en la restauración que podía anunciar éxito si Play o Pause publicaba error. Se agregó la comprobación simétrica y la CI se repitió. La ruta exacta del error tardío sin identidad sigue sin garantía. Los logs nativos incluyen avisos de Fontconfig en el entorno de pruebas y el compositor informó render por software. La reproducción del fixture se observó a pesar de esos avisos.

> Actualización del 12 de noviembre de 2026. El DEMO predeterminado y su UI se reemplazaron por [Morevna y los nuevos controles](demo-morevna.md). Esta página conserva los resultados de la corrida sintética anterior. Para reproducirla, usar el launcher con --synthetic.
