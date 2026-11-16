# Adaptador media_kit — F2.2–F2.6

## Propósito y responsabilidad

Encapsula una única instancia activa `Player`, su `VideoController`, comandos nativos y streams de estado. La fábrica rechaza la creación de un segundo adaptador mientras el anterior no haya dispuesto su Player. Es la única capa de aplicación F2.2 que importa `media_kit`. Implementa el puerto mínimo de `application/player`; no accede a catálogo, biblioteca, proveedores ni progreso persistido.

## Archivos

| Archivo | Propósito | Entrada/salida | Dependencias |
|---|---|---|---|
| `media_kit_spike_engine.dart` | Crea y libera Player/controlador, abre archivo local o URI HTTPS explícitamente confiada, traduce comandos y adapta eventos | comandos → Future; eventos → snapshots | `media_kit`, `media_kit_video`, puerto application |
| `active_player_lease.dart` | Reserva la única ranura de Player durante la limpieza; coalesca releases y conserva el callback de limpieza original para los reintentos | `acquire()` → lease; `release(cleanup)` → Future compartido | Dart `async`; módulo engine |
| `mpv_subtitle_properties.dart` | Selecciona la API nativa o stub por plataforma | propiedad mpv → operación | conditional export |
| `mpv_subtitle_properties_native.dart` | Escribe y vuelve a leer propiedades mpv en `NativePlayer` | Player + propiedad/valor → Future validado | API pública de media_kit |
| `mpv_subtitle_properties_stub.dart` | Informa explícitamente que las propiedades mpv no están disponibles | llamada → `UnsupportedError` | Dart |
| `README.md` | Inicialización, eventos, recursos y diagnóstico | guía técnica | ADR-002, F2.2 |

## Comportamiento y ciclo de vida

La fábrica llama `MediaKit.ensureInitialized()`, adquiere el lease único y crea un `Player`. La composición invoca `attachVideoSurface()` para crear un `VideoController` ligado a ese Player; el controller espera el primer frame de Flutter antes de crear la salida de textura. Si configuración/initialize/open falla, el caller puede esperar el dispose del engine y cleanup pendiente. `initialize()` instala observadores para `playing`, `buffering`, `position` y `duration`. `open(Uri, sourceGeneration:)` acepta archivos `file:` regulares sin symlink, mirrors HTTP loopback explícitos del DEMO o URI HTTPS exactas presentes en `trustedExternalSources`; no acepta una URL solo por cumplir el esquema. Los adaptadores de datos validan destinos HTTPS antes de confiarlos y el engine conserva la lista exacta durante la sesión. El proceso nativo puede seguir redirects/consultas internas del medio; no se afirma aislamiento DNS posterior. La generación proviene del coordinador y se añade a los snapshots; este filtra generaciones anteriores. `media_kit` 1.2.6 emite actualizaciones en streams broadcast asíncronos y actualiza `Player.state` antes de emitir los cambios de propiedades. Por ello, antes de aplicar una propiedad, el adaptador compara el valor del evento con el valor instantáneo actual; descarta eventos encolados que ya fueron superados. La suscripción `Player.stream.error` se renueva en cada apertura y captura su generación. Ese stream solo entrega `String` y no identifica la URI: un error nativo de A emitido tras instalar la suscripción de B no se puede distinguir. No está reproducido, pero limita la garantía de aislamiento completo hasta demostrar el contrato upstream o probar una solución. Esta validación en data complementa la del coordinator y protege llamadas directas al adaptador. Completar `open` solo acredita que el Future retornó; no demuestra decodificación, textura ni frame presentado.

`play`, `pause`, `seek` y `stop` traducen operaciones nativas. `stop` descarga el medio y deja reusable el Player; el adaptador conserva la URI que se abrió correctamente y marca el snapshot `stopped`, sin destruir Player ni VideoController. El siguiente `play` revalida el archivo y lo abre de nuevo en el mismo Player con reproducción desde el inicio. Si la validación/reapertura falla, la operación propaga el error y mantiene la fuente y el estado stopped para permitir reintentar. Play tras Pause solo llama a `Player.play()` y conserva la posición. La prueba libmpv cubre ambos contratos, ciclos Stop→Play repetidos, archivo retenido ausente y recuperación. La reapertura de la misma URI en Linux aún requiere confirmación de imagen en compositor: upstream mantiene abierta la issue [#957](https://github.com/media-kit/media-kit/issues/957), que informa pantalla negra para una secuencia similar; el test nativo comprueba estado/avance, no píxeles presentados. `dispose` hace el engine no utilizable y delega a `ActivePlayerLease`: llamadas concurrentes comparten Future. El lease representa solo la propiedad del Player nativo: se libera cuando `Player.dispose()` termina, aunque luego falle una limpieza auxiliar Dart. El engine reintenta de forma idempotente la cancelación de subscriptions/cierre del stream mediante su propio `dispose()`; no libera un Player nativo incierto. El dispose nativo es un intento único porque media_kit 1.2.6 cambia su indicador `disposed` antes de completar todo el teardown. Si ese Future falla, se conserva el lease y no se repite la operación. El error tipado `MediaKitSpikeEngineDisposeFailure` informa `nativePlayerStillOwned`; los fallos de subscriptions o del stream se marcan como auxiliares y no conservan el lease si el dispose nativo terminó. Un error de `Player.dispose()` también cierra el stream de snapshots; una prueba con fallo inyectado confirma `onDone`, aunque no simula internamente un fallo parcial de libmpv. Esta cuarentena requiere reiniciar el proceso antes de crear otro Player tras fallo nativo. `retryPendingDispose()` atiende exclusivamente un lease nativo huérfano o retenido y propaga su fallo. Si el Player ya se liberó y solo falló una etapa auxiliar, se reintenta llamando `dispose()` sobre el mismo engine mientras siga accesible. No desplaza un engine activo antes de dispose. `Player.stream.error` se publica como texto fijo sin rutas/detalles arbitrarios. Los errores de reproducción persisten a través de cambios no relacionados y solo se limpian en una recuperación de `open` sin un nuevo error.

Los streams resueltos pueden llevar `PlaybackRequestHeaders`, que actualmente
solo permite un `Referer` público HTTPS validado en domain. `MediaKitSpikeEngine`
lo entrega a `Media(httpHeaders: ...)` y lo conserva junto a la fuente lógica
para Stop→Play. El contexto se reemplaza con cada apertura/cambio de servidor y
el servicio de rollback restaura el contexto de la fuente previa; no se heredan
cookies, Authorization ni cabeceras arbitrarias. En AnimeGG, la integración
local prueba transporte de `Referer` sobre el servidor de test; no acredita la
resolución o reproducción de sus cinco medios públicos observados.

El `VideoController` está ligado a la vida del mismo Player. En la versión fijada `media_kit_video 2.0.1`, el release de la plataforma del Player elimina sus listeners/recursos; `VideoController` no expone `dispose()` público. La UI informa tres estados separables: `platform.future` completado (controller creado), `id` no nulo (textura registrada en Flutter) y `waitUntilFirstFrameRendered` resuelto (primer frame procesado/renderizado por el plugin). Ninguna señal demuestra que el compositor de escritorio presentó el frame; se requiere inspección visual independiente.

## Configuración y dependencias

| Opción | Valor F2.2 | Lugar | Efecto/limitación |
|---|---|---|---|
| autoplay de open | `false` | `open` | UI decide cuándo reproducir |
| URI aceptada | `file:` regular, mirror loopback exacto o HTTPS exacta en allowlist | coordinator y adaptador | evita apertura arbitraria de red; las fuentes provider deben venir resueltas |
| renderizado | default `VideoController` | constructor | no se fuerza hwdec; no implica decodificación hardware |

Versiones resueltas en `app/pubspec.lock`: media_kit 1.2.6, media_kit_video 2.0.1, media_kit_libs_video 1.0.7 y media_kit_libs_linux transitiva 1.2.1. No combinar con `media_kit_libs_audio`. Fedora del entorno expone `mpv-libs-0.41.0-5.fc44.x86_64`, libmpv 2.5.0 en `/lib64/libmpv.so.2`; el wrapper Dart y libmpv tienen licencias distintas. Esto no completa la auditoría de distribución.

## Diagnóstico y pruebas

Los scripts `tools/player/generate_f2_2_fixture.sh` y `tools/player/run_f2_2_spike.sh` crean/verifican el medio sintético en `.ai-local/` y establecen su ruta absoluta sin usar `Directory.current` en el entrypoint. En una copia limpia, el helper `app/test/player/player_test_fixture.dart` ejecuta el generador si falta el fixture; requiere `ffmpeg` y acepta solo cwd en la raíz/`app/` o `KONGROO_PROJECT_ROOT`. Desde `app/`, selecciona `.ai-local/toolchains/flutter/bin` al principio de `PATH`, elimina `FLUTTER_ROOT` y fija `PUB_CACHE=../.ai-local/pub-cache` antes de ejecutar los comandos; el `flutter` ambientado en `PATH` puede ser otra versión. `flutter test --no-pub test/player` cubre lease, error sticky, disposición, seek interactivo, close gate, entrada inválida, stop/reopen, recuperación y el adaptador real/libmpv. Las watchdogs de tests no cancelan operaciones; si una llamada nativa excede el límite, el test espera también el Future original antes de intentar dispose. El ciclo de vida del `VideoController` con plugin Linux real aún no está probado; una prueba con canal simulado no logró completar su Future de plataforma. Para presentación, ejecuta el launcher y prueba Play; la UI reporta textura registrada y primer frame del plugin. La ventana/compositor requiere evidencia visual aparte. Build exacto: `flutter build linux --release --no-pub -t lib/main_player_spike.dart`.

Si otro motor fuese necesario, crear otro adaptador fuera de dominio e implementar el puerto temporal; no cambiar la UI ni la API definitiva de F2.5 sin decisión propia. Opciones hwdec, pistas y estadísticas quedan fuera de F2.2.

## Volumen F2.3

El adaptador escucha `Player.stream.volume` y publica el valor en el snapshot;
durante `initialize()` también toma `Player.state.volume` para comenzar con la
configuración efectiva (media_kit 1.2.6 inicia en 100). `setVolume(double)`
rechaza NaN, infinitos y valores fuera de 0–100 antes de llamar a
`Player.setVolume`. La aplicación hace los pasos +/-5 dentro de su cola; el
adaptador no calcula atajos ni cambia la política del producto.

La prueba `real libmpv accepts player-local volume and emits the observed
value` inicializa el Player nativo, pide 42, espera el evento de volumen y
comprueba el snapshot; también verifica el rechazo sobre 100. Esto acredita la
API media_kit/libmpv, no el nivel acústico percibido por un dispositivo físico.
El volumen afecta solo a este `Player`, no al mezclador de Fedora.

## Selección de calidad/pista de video

`MediaKitSpikeEngine` enumera exclusivamente `Player.state.tracks.video` y
normaliza ID, dimensiones, bitrate, códec, título y FPS en `VideoTrackInfo`.
No consulta listas arbitrarias de extensiones ni inventa resoluciones. Una
fuente con una sola pista se presenta como calidad fija. Para varias pistas,
`selectVideoTrack` usa `Player.setVideoTrack` en el mismo `Player` y verifica
el ID efectivo de mpv; conserva posición, reproducción/pausa, audio y
subtítulos sin reabrir el medio. `VideoTrack.auto()` está disponible solo
cuando el motor expone más de una pista y significa seleccionar la pista
predeterminada del motor. No significa ABR ni adaptación continua de HLS/DASH.

La observación se actualiza con los streams de pistas del propio media_kit y se
limpia al abrir o detener otra fuente. No se parsean manifiestos HLS/DASH ni se
resuelve una escalera de variantes remotas en esta integración; el flujo de
fuentes actual del spike admite también una URI externa HTTPS ya resuelta por los proveedores públicos. Si un proveedor futuro resuelve variantes como pistas reales del
mismo medio, el adaptador las expondrá sin cambios en la UI. Si las variantes
son URIs independientes, deberán pasar por un contrato de fuente/coordinador
que conserve el contexto de reproducción, no por una apertura directa desde
la UI.

La regresión `test/player/player_quality_test.dart` genera en `.ai-local/` un
fixture corto sintético con dos resoluciones, audio AAC silencioso y una pista
SRT. ffprobe confirma las dimensiones y libmpv selecciona audio/subtítulo antes
de cambiar la pista de video durante pausa; la prueba comprueba posición,
generación y pistas seleccionadas. Ejecutar desde `app/` con la toolchain del
proyecto:

```bash
flutter test --no-pub test/player/player_quality_test.dart
```

F2.3 no crea nuevos Players ni VideoControllers. La superficie, el lease y el
ciclo de vida siguen siendo los de F2.2. El fullscreen no pertenece a este
adaptador: su canal GTK está documentado en
[`app/player/README.md`](../../../app/player/README.md) e implementado en
`app/linux/runner/my_application.cc`.

## Subtítulos F2.6

El motor se crea con `PlayerConfiguration(libass: true)` para procesar
subtítulos de texto. Los streams `tracks` y `track` se normalizan a
`SubtitleTrackInfo`; la presentación recibe IDs de la sesión activa, idioma,
codec, nombre y tipo (automático, desactivado, interno o externo). Los IDs de
media_kit solo son válidos para las pistas de la fuente actual: no se persisten
ni se tratan como identificadores universales. La selección valida que el ID
esté disponible; `auto` y `no` representan selección automática y
desactivación.

La integración real cubre Matroska con SubRip y ASS, pista sin idioma, pista
`mov_text` en MP4 y carga local SRT. El adaptador admite archivos externos
locales `.srt`, `.ass`, `.ssa` y `.vtt`, exige URI `file:` y archivo regular no
symlink, y delega la selección a `Player.setSubtitleTrack`; no obtiene
contenido de red. Hardsub confirmado bloquea la carga; si su estado es
desconocido, se permite con el resultado explícito `allowedWithUncertainty`.
No se infiere hardsub por ausencia de pistas.

`applySubtitleStyle` aplica y vuelve a leer `sub-ass-override`, `sub-font`,
`sub-font-size`, `sub-color`, `sub-bold`, `sub-outline-color`,
`sub-outline-size` y `sub-pos`. `setSubtitleDelay` aplica `sub-delay` con rango
de ±30 segundos. El dominio valida tamaño 12–96, números finitos, color
hexadecimal, fuente acotada, contorno 0–10 y posición 0–100. ASS conserva sus
estilos por defecto (`overrideAssStyles: false`); forzar su reemplazo puede
alterar posiciones y carteles. El estilo es efímero y no se persiste. El widget
del spike expone selección, tamaño, familia, color de texto/contorno, grosor
del contorno, negrita, posición, override ASS y delay ±250 ms; son controles
temporales de diagnóstico y no preferencias persistentes del producto.

Las pruebas reales con libmpv comprueban metadatos, selección/desactivación,
SRT externo, `mov_text`, escritura y lectura de propiedades, delay positivo y
negativo y rechazo del rango. No hay observación gráfica automatizada de
glifos: el test informa que Fontconfig no puede escribir `/var/cache/fontconfig`.
Esto no cambia el exit 0 del test ni acredita el aspecto visible. No se
modificaron permisos ni configuración del sistema. Subtítulos bitmap y
presentación visible aún requieren validación gráfica.

Desde `app/`, con Flutter 3.47.9 aislado:

```bash
flutter test --no-pub test/domain/subtitle_policy_test.dart
flutter test --no-pub test/player/media_kit_spike_integration_test.dart
```

No añadir protocolos de proveedor externo al engine. OpenSubtitles corresponde
a F2.8 y debe entregar una fuente local mediante un contrato; el motor no
conoce API ni credenciales.

### Referencias de API

Consultadas el 2026-11-10: [media_kit 1.2.6](https://pub.dev/packages/media_kit/versions/1.2.6)
documenta selección de pistas por los streams/estado `tracks` y `track`,
`setSubtitleTrack`, archivos externos mediante `SubtitleTrack.uri` y opciones
de estilo. La [referencia oficial de opciones mpv](https://github.com/mpv-player/mpv/blob/master/DOCS/man/options.rst)
describe `sub-delay` con valores negativos/positivos y advierte que aplicar
overrides a ASS puede producir renderizado incorrecto. La versión instalada
del wrapper está fijada en `app/pubspec.lock`; la página upstream sirve para
contrastar semántica, mientras los tests y el source local instalado prueban
el comportamiento exacto usado aquí.

### Evidencia gráfica manual F2.6

En KDE Wayland, el launcher del fixture F2.6 mostró la pista interna “English
SRT” sobre el video y el estado del widget marcó controller listo, textura
registrada y primer frame procesado. Véase
`.ai-local/f2.6/evidence/subtitle-playing.png` y `gui-player.log`. El motor
avisó de EGL inválido y cambió a renderizado software; se verificó salida
visible, no aceleración por hardware. El render de ASS y el ciclo de vida nativo
completo de `VideoController` no quedan demostrados por esta captura.

## Audio y transportes de la operación extendida

AudioTrackInfo se publica desde tracks y track junto con los subtítulos. La selección usa el ID nativo de la generación actual y confirma aid en mpv. El coordinador serializa la operación y rechaza selecciones atrasadas. Las entradas de red se limitan a URI HTTP loopback exactas del DEMO. El resto conserva la validación de archivo regular. Consultar la [guía de ejecución, fixtures y pruebas](../../../../../docs/player/operacion-extendida.md).
