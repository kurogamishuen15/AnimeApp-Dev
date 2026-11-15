# Presentación del spike F2.3

## Propósito y límites

Muestra una salida de video local y los controles temporales del spike sin
incorporar una pantalla de producto ni modificar navegación, catálogo,
biblioteca, Drift o progreso. `SpikePlayerModule` es el composition root: crea
un engine y un coordinator, abre el fixture local y entrega la UI al estado y
al `VideoController` asociado al mismo `Player`.

La capa app contiene widgets, composición, mensajes de estado, controles,
foco y el handshake gráfico de cierre. No crea `Player`, no importa su API, no
accede directamente a `media_kit`, y no decide reglas de dominio. Las acciones
de reproducción pasan por `SpikePlayerCoordinator`.

## Archivos y contratos

| Archivo | Responsabilidad | Contrato | Dependencias |
|---|---|---|---|
| `spike_player_module.dart` | Composition root y cierre del grafo | fixture local → widget y `close()` | engine, coordinator |
| `spike_player_page.dart` | Estado, control único Play/Pause, Stop, seek, tiempo y errores | snapshots → UI; acción → coordinator | Flutter UI, stream application |
| `audio_track_selector.dart` | Presenta las pistas conocidas del snapshot activo | selección → ID nativo, generación de fuente y revisión de contexto | domain track info, Flutter UI |
| `player_quality_panel.dart` | Presenta resoluciones/pistas y opción automática solo para medios multipista | selección → ID, generación y revisión de contexto | `VideoTrackInfo`, `SpikePlayerCoordinator` |
| `external_subtitle_search_panel.dart` | Búsqueda inglesa, candidatos, descarga y feedback tipado de F2.8 | texto/candidato → `ExternalSubtitleService` | application, domain, Flutter UI |
| `media_kit_video_surface.dart` | Textura de video y señales diagnósticas | `VideoController` → imagen Flutter | `media_kit_video` |
| `player_window_controller.dart` | Puerto de ventana y adaptador GTK para pedir/observar fullscreen | solicitud → MethodChannel; evento GTK → snapshot | Flutter services, runner GTK |
| `spike_window_close_gate.dart` | Serializa solicitudes de cierre y aplica un watchdog de respuesta seguro | callbacks async → `Future<bool>` | Dart `async` |
| `README.md` | Límites, inventario y operación | guía de este módulo | módulos player, ADR-002 |

El panel externo solo se construye cuando el módulo recibe un
`ExternalSubtitleCatalog`. El entrypoint del spike lo configura con
`OpenSubtitlesClient`; su API key se lee de `OPENSUBTITLES_API_KEY` en el
entorno. Si no existe, el panel presenta un estado de configuración y no hace
requests. La búsqueda del panel es textual y en inglés. La UI consume
candidatos/resultados domain y no recibe API keys, JSON o enlaces temporales.
Mientras una búsqueda o descarga está pendiente, el panel bloquea el campo y la
acción; el handler también rechaza un submit reentrante para evitar respuestas
fuera de orden que sustituyan los candidatos actuales.

Al descargar, la página invoca `ExternalSubtitleService`, que aplica la
política hardsub y entrega únicamente el URI local al coordinator. El estado
desconocido muestra que la pista se cargó con incertidumbre; hardsub confirmado
bloquea antes de gastar cuota. El README de
[`data/opensubtitles`](../../data/opensubtitles/README.md) documenta transporte,
auth, formatos, límites, errores y ciclo de vida. Widget tests cubren la
interacción de búsqueda/candidato/resultado; un test de integración envía un
SRT HTTP fixture fake a almacenamiento temporal y luego lo carga en el libmpv
real. Este test no acredita API real ni que el compositor dibuje los glifos.

El entrypoint aislado [`main_player_spike.dart`](../../main_player_spike.dart)
construye `SpikePlayerApp` con el Future de apertura del módulo y la función de
retry del cleanup. La misma vista conserva visible el aviso de cierre pendiente
o fallido durante apertura, error de startup y reproducción; su watchdog es
configurable solo para pruebas.

La página no crea otro motor/controller durante una reconstrucción. El
snapshot distingue Pause de Stop y muestra un overlay informativo sobre la
misma superficie cuando está detenida; el botón Play permanece disponible y
solicita la reapertura mediante el coordinator. La superficie es el único
widget que importa `media_kit_video`. Distingue la
inicialización del controller, el ID de textura y la señal de primer frame
procesado por el plugin. Esa última señal no demuestra que el compositor haya
presentado píxeles; para ello hace falta evidencia gráfica independiente.
El badge sobre el video identifica estos estados y es un overlay diagnóstico
intencional.

## Exclusividad de controles

`Video` de `media_kit_video 2.0.1` usa `AdaptiveVideoControls` por defecto; en
Linux selecciona `MaterialDesktopVideoControls`. La superficie de Kongroo
configura `controls: NoVideoControls`. En la versión instalada,
`NoVideoControls` es `null`; `VideoState.build` solo monta el subtree de
controles si `videoViewParameters.controls != null`. Por tanto, el paquete no
monta su barra, `MouseRegion`, detector de gestos ni atajos asociados a ese
overlay. La prueba `media_kit_video_surface_controls_test.dart` comprueba la
configuración creada por el helper usado en producción; la rama condicional del
overlay se verificó en el source instalado de la versión fijada.

La página de Kongroo es propietaria de los controles F2.2: un solo botón
Play/Pause (icono y texto según `snapshot.playing`), Stop y un slider. El slider
actualiza el thumb de forma local en `onChanged`, envía seek al terminar, y
coalesce los destinos intermedios mientras el motor procesa uno. Si se pulsa
Stop durante un seek, la página elimina el único destino todavía no iniciado,
rechaza más cambios del slider, espera el Future del seek activo y solo después
envía Stop al coordinator. No afirma cancelar una operación nativa activa.
Los controles quedan deshabilitados durante esa barrera de orden. Una regresión
de widget comprueba el orden observable `seek, stop` y que el seek pendiente no
se ejecute después de Stop. Tiempo y duración usan `MM:SS` o `H:MM:SS`; el
slider expone un valor semántico legible.
El default adaptativo desactivado también retiraba fullscreen, volumen,
selección de pista/subtítulos, controles automáticos por hover y sus shortcuts.
Esas funciones no se reimplementan en F2.2: están fuera del spike y requieren
su fase o decisión arquitectónica correspondiente. F2.3 añade únicamente los
atajos básicos descritos a continuación; no reactiva el overlay adaptativo.

### Validez temporal del menú de audio

Cada opción del menú conserva una tupla `(id nativo, sourceGeneration,
mediaContextRevision)`. `PopupMenuButton` puede mantener el route de un menú
abierto aunque el medio subyacente cambie; por eso el ID nativo queda ligado al
contexto que lo enumeró. El coordinator incrementa `mediaContextRevision`
síncronamente al solicitar `open`, un cambio de fuente o Stop, antes de que la
operación ingrese a la cola del motor. La página compara la revisión y la
generación capturadas con el contexto vigente y descarta opciones obsoletas o
selecciones de una sesión detenida. Así, la selección inválida no llega a
libmpv ni se presenta como fallo de reproducción. Una opción válida sigue
usando `selectAudioTrack` del coordinator y el adaptador único. Los IDs nativos
no son preferencias y no se conservan entre fuentes.

## Controles básicos por teclado — F2.3

La UI traduce teclas mediante Flutter `Shortcuts`, `Actions` y un
`ShortcutManager` privado de la página. Cada acción de reproducción vuelve al
mismo `SpikePlayerCoordinator` que utiliza el botón Play/Pause. El adaptador
media_kit sigue siendo el único propietario de `Player`; no se crea otra
superficie ni otro controlador de reproducción.

| Tecla | Acción coordinada | Incremento F2.3 |
|---|---|---:|
| Espacio, K | Alternar Play/Pause; en estado stopped usa la reapertura F2.2 | — |
| Flecha izquierda | Seek relativo hacia atrás | 10 s |
| Flecha derecha | Seek relativo hacia adelante | 10 s |
| Flecha arriba | Subir volumen de este Player | 5 puntos |
| Flecha abajo | Bajar volumen de este Player | 5 puntos |
| F | Solicitar alternancia fullscreen de la ventana GTK | — |
| Escape | Solicitar salir de fullscreen cuando GTK lo observó activo | — |

La barra incluye un botón fullscreen con tooltip e icono que reflejan el último
estado confirmado por GTK. El botón y F llaman a `_toggleFullscreen`; ambos
quedan deshabilitados mientras el runner confirma una transición. Escape solo
se ofrece en el mapa de atajos mientras GTK reporta fullscreen.

Los incrementos están centralizados en `spike_player_page.dart` como
`spikePlayerKeyboardSeekSeconds` y `spikePlayerKeyboardVolumeStep`. Son
constantes del spike, no preferencias persistidas; una configuración futura
puede reemplazarlas sin mover las reglas del motor.

Space y K excluyen eventos `KeyRepeat`; mantenerlos pulsados genera una sola
acción. Flechas permiten repetición para ofrecer pasos incrementales. Los
`SingleActivator` requieren que no haya modificadores extra, así que Ctrl/Alt/
Shift/Meta más una tecla del mapa no dispara el atajo. Tab no está mapeado y
sigue la navegación estándar.

El manager consulta el foco primario en el momento de cada evento. Ignora sus
atajos si el foco salió de la página o pertenece a un `EditableText`; así deja
que Flutter procese el texto y sus atajos propios. No registra un listener
global de teclado. La página tiene un `FocusNode` con `autofocus`; la superficie
de video no introduce un detector que pueda robar el foco a un campo de texto.
Al pulsar un botón, el foco de Flutter permanece dentro del scope del
reproductor. El gestor de ventanas real sigue controlando el foco de la propia
ventana; no se escucha teclado global del sistema.

### Coordinación de seek y volumen

`seekBy(Duration)` calcula el destino al ejecutarse en la cola FIFO, sumándolo
al objetivo anterior si aún no llegó el snapshot nativo. El destino se limita a
cero y a la duración cuando esta es conocida; si la duración es desconocida no
se inventa un máximo. Una seek contra el estado stopped se rechaza. Fallos del
motor restauran el snapshot previo en lugar de dejar un objetivo optimista
atascado. El slider conserva su envío al finalizar el gesto y su coalescing de
pendientes.

`adjustVolumeBy` lee el objetivo/volumen más reciente en la misma cola y limita
el resultado a 0–100. `PlaybackSpikeSnapshot.volume` proviene de
`Player.stream.volume` y es volumen por instancia de media_kit; no cambia el
mezclador de Fedora ni otras aplicaciones. La UI muestra el porcentaje actual.
No se añaden controles visuales de audio ni preferencias de dispositivos.

### Fullscreen GTK

`GtkPlayerWindowController` usa el canal `kongroo/f2.3/window`, separado del
canal de cierre `kongroo/f2.2/window`. GTK recibe `setFullscreen(bool)` y llama
`gtk_window_fullscreen` o `gtk_window_unfullscreen`. El Future de esa llamada
solo confirma que el runner respondió; el estado se considera activo cuando el
evento nativo `window-state-event` informa
`GDK_WINDOW_STATE_FULLSCREEN`. El canal responde además a
`getFullscreenState` usando el estado efectivo de GDK. `setFullscreen` solo
acepta la solicitud y responde sin un estado; el resultado inmediato de GDK
puede ser anterior a la transición del compositor.

Por la misma razón, la respuesta de `setFullscreen` no se interpreta como
estado visible. Solo `fullscreenChanged` cambia el snapshot luego de una
solicitud. Cada transición confirmada libera el envío pendiente y avanza una
generación para que un Future anterior tardío no bloquee ni sobrescriba una
solicitud opuesta nueva.

Mientras espera el evento la UI mantiene una solicitud pendiente y evita
duplicar comandos. Si GTK no confirma el cambio en tres segundos, muestra un
error sin fingir éxito ni cancelar la solicitud nativa. Una transición tardía
posterior todavía actualiza el estado observado. Si la llamada MethodChannel
falla, el error se expone y se propaga a la UI. F alterna según el último estado
GTK observado; Escape se registra solo cuando fullscreen está activo. El
canal/adaptador se libera al cerrar el módulo.

Si vence el timeout, el controlador conserva la dirección de la solicitud no
confirmada. Mientras GTK no observe ese destino, rechaza una solicitud
opuesta; un evento tardío contradictorio no completa ni reemplaza la primera
solicitud. Así se evita que dos transiciones nativas sin identificadores de
correlación se crucen. Si GTK nunca notifica el estado solicitado, la dirección
opuesta queda bloqueada durante la vida de este controlador y la UI conserva el
error visible; no se interpreta el timeout como cancelación nativa.

La compilación prueba integración y contratos, no una transición del compositor.
La entrada real a fullscreen, restauración visual, video/audio durante el
cambio y foco tras recuperar la ventana requieren validación gráfica Fedora;
Broadway/Xvfb no se usaron como sustitutos de GTK de escritorio en esta
ejecución.

### Pruebas y extensión

Desde `app/`, con Flutter 3.47.9 aislado:

```bash
flutter test --no-pub test/player/spike_player_page_test.dart
flutter test --no-pub test/player/player_quality_test.dart
flutter test --no-pub test/player/spike_player_coordinator_test.dart
flutter test --no-pub test/player/player_window_controller_test.dart
flutter test --no-pub test/player/media_kit_spike_integration_test.dart
flutter build linux --release --no-pub -t lib/main_player_spike.dart
```

Los tests de página envían eventos Flutter reales para teclas, KeyRepeat,
modificadores y foco de texto. Los unit tests comprueban pasos acumulativos,
límites y rollback de errores; el test del adaptador usa libmpv y observa el
stream de volumen. `player_window_controller_test.dart` simula la frontera de
MethodChannel: distingue respuesta inmediata, confirmación GTK posterior,
rechazo y timeout. No simula un compositor ni acredita fullscreen real.

Para incorporar otra tecla, añadir un `Intent`, mapa de activadores y una
`CallbackAction` que invoque solo el coordinador o `PlayerWindowController`;
añadir test de evento, repetición, modificadores, foco y estados. Para cambiar
los pasos, editar las constantes centrales y sus expectativas. Mantener los
atajos de escritorio en esta capa; el coordinador y el puerto de motor siguen
reutilizables para futuras superficies Android/TV.

## Ciclo de vida y cierre

El entrypoint instala el handler `kongroo/f2.2/window`. El runner GTK
intercepta `delete-event` solo al ejecutarse con `KONGROO_F2_2_SPIKE=1`. La
ventana se destruye únicamente si Dart responde `true` después de que el cierre
real del módulo haya terminado, o de que un rollback de apertura fallida haya
liberado correctamente los recursos. Solicitudes simultáneas se coalescen.

El gate usa un watchdog de respuesta de 15 segundos. Si la limpieza sigue
pendiente, responde `false` para que GTK mantenga la ventana y muestra un aviso.
El watchdog **no cancela ni abandona** la operación de `Player` ni afirma que
libmpv la haya detenido. Una nueva solicitud espera el mismo Future; no inicia
un segundo dispose concurrente. Si el Future original concluye con cleanup
correcto, el siguiente intento puede cerrar. Un fallo de cleanup/reintento se
expone y mantiene la ventana abierta. `State.dispose()` solo retira el handler:
no hace cleanup async desde un callback síncrono. Un crash o terminación
externa sigue fuera de las garantías de `delete-event`. Si falla la apertura,
la pantalla de error conserva visible el aviso de limpieza pendiente o fallida;
el gate mantiene la ventana abierta hasta que la limpieza se complete. Si el
MethodChannel no responde en absoluto, el runner GTK tiene otro watchdog de 20
segundos: quita
el bloqueo local de cierre e invalida esa generación. Una respuesta tardía no
puede destruir la ventana ni cambiar otro intento. Mientras la invocación
MethodChannel original siga sin responder, nuevos gestos de cierre mantienen
la ventana abierta y no emiten invocaciones duplicadas; después de que la
respuesta llegue, un gesto posterior puede reintentar y compartir el Future
de cleanup que siga pendiente. Si la respuesta nunca llega, la ventana se
mantiene abierta por seguridad. El callback nativo usa una generación como
contexto y una referencia débil al application, para no retener otro objeto
por cada gesto repetido. El timeout de GLib es best-effort: depende de que el
main loop GTK siga procesando eventos y puede demorarse; no desbloquea un main
loop bloqueado. La llamada asíncrona Flutter que no responda puede seguir
pendiente hasta que llegue una respuesta o el proceso termine.

## Inicialización, ejecución y pruebas

Desde la raíz, con el SDK del proyecto y `ffmpeg`/`ffprobe` disponibles:

```bash
tools/player/run_f2_2_spike.sh
```

El launcher deriva rutas desde su ubicación, genera el fixture sintético si
falta y pasa `KONGROO_PROJECT_ROOT`. El entrypoint deriva el medio fijo bajo
`.ai-local/f2.2/fixtures/` y rechaza symlinks en sus directorios. No depende de
`Directory.current` para elegir la fuente. Para generar el fixture por
separado: `tools/player/generate_f2_2_fixture.sh`.

Desde `app/`, selecciona primero la toolchain local (no asumas qué `flutter`
resuelve el `PATH`):

```bash
unset FLUTTER_ROOT
export PATH="../.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
export PUB_CACHE="../.ai-local/pub-cache"
```

Luego ejecuta los checks de la UI y el módulo:

```bash
flutter test --no-pub test/player/media_kit_video_surface_controls_test.dart
flutter test --no-pub test/player/spike_player_page_test.dart
flutter test --no-pub test/player/spike_window_close_gate_test.dart
flutter test --no-pub test/player/main_player_spike_test.dart
flutter build linux --release --no-pub -t lib/main_player_spike.dart
```

Desde la raíz, hay dos probes independientes de la plataforma Flutter:

```bash
bash tools/player/test_f2_2_fixture_guards.sh
dart tools/player/verify_f2_2_close_gate.dart
```

La suite de página verifica 100 cambios del slider sin seek intermedio,
coalescing al arrastrar rápido, Stop descartando el destino pendiente y
esperando el seek activo, transición de un único Play/Pause, formato de tiempo
y layout estrecho. El test de superficie comprueba la propiedad
`controls == null`; la inspección del código de `media_kit_video 2.0.1`
confirma que eso omite el overlay completo. El test del close gate cubre
coalescing, limpieza en curso, watchdog, retry y fallo simulado.
El probe Dart del close gate prueba timeout, respuesta de ventana segura,
ausencia de cancelación, coalescing y retry sin requerir el Flutter engine.
`main_player_spike_test.dart` pasa por el `SpikePlayerApp` real y su
MethodChannel para comprobar que la pantalla conserva los mensajes de fallo o
espera de cleanup; no reemplaza una prueba de GTK.

El plugin Linux con `VideoController` nativo, el frame que presenta el
compositor y el gesto real de cierre GTK deben verificarse en una sesión
gráfica aislada. Tests fake/configuración y un build no sustituyen esas
pruebas. No se importa el player desde catálogo o navegación. Al extender el
spike, añadir acciones únicamente a través del coordinator y cubrir el cambio
con una prueba; no conectar el widget directamente al engine. El watchdog GTK
está compilado, pero todavía no se ha probado de extremo a extremo con una
ventana GTK real; su timeout conserva la ventana y solo permite reintentar.

## Calidad de video

`PlayerQualityPanel` se coloca junto a los controles de pistas existentes y
consume solo `PlaybackSessionSnapshot.videoTracks`. Presenta `360p`, `480p`,
`720p`, `1080p`, `4K` u otras dimensiones únicamente cuando corresponden a
metadatos observados; puede añadir bitrate/códec/título si la fuente los
informa. Cuando hay una sola pista, el tooltip y el menú muestran su calidad
fija, sin opciones ficticias. Cuando hay varias, se ofrece `Automático ·
selección del motor` (la pista predeterminada, sin afirmar ABR) y las pistas
reales.

La página captura generación y revisión de contexto al construir el menú y
descarta una selección obsoleta si cambió fuente/episodio/servidor o se detuvo
el medio. Las acciones usan `selectVideoTrack` del coordinator; no abren otra
instancia ni manipulan el Player desde el widget. El widget test ejerce el menú
y sus callbacks; `test/player/player_quality_test.dart` añade integración
libmpv de dos pistas de resolución distintas, comprobando ID efectivo,
posición, pausa y que los IDs de audio/subtítulos siguen iguales.

El archivo Morevna del DEMO reporta una única pista 534×300, por lo que se
muestra como calidad fija. La fuente actual no ofrece selección ABR ni se
analizan manifiestos HLS/DASH; los medios externos de URL tampoco forman parte
del flujo actual del spike.

## Subtítulos F2.6

La misma página conserva una superficie `Video` y presenta selector de pista,
tamaño, familia, color de texto/contorno, grosor del contorno, negrita,
posición, override ASS y delay ±250 ms. El selector incluye las entradas
normalizadas de media_kit para automático, desactivado, interno y externo. Las
acciones llaman a `SpikePlayerCoordinator`; la presentación no importa libmpv.
El estilo es temporal al ciclo de vida del widget y no se almacena entre
sesiones.

La búsqueda/carga de una pista externa se implementa en el panel F2.8 descrito
al inicio de este README. No anunciar un formato como visible por aparecer en
la lista: los tests libmpv prueban pistas y propiedades de motor, no renderizado de glifos. ASS
conserva estilos authored de forma predeterminada; forzar override puede
alterar carteles y posición. Hardsub no se puede apagar con el selector.

El widget test comprueba selección y cambios de estilo/delay a través del
coordinator. La integración con libmpv prueba Matroska SRT, ASS, pista sin
idioma, MP4 `mov_text`, SRT externo y propiedades de estilo y delay. Los avisos
Fontconfig de la máquina indican que no hay caché de sistema escribible y por
eso no se afirma validación gráfica de esos estilos.

Para revisar visualmente la pista interna del fixture, genera los medios y
ejecuta `tools/player/run_f2_6_subtitle_spike.sh` desde la raíz. El launcher
selecciona únicamente `.ai-local/f2.6/fixtures/subtitles-v2.mkv`; el launcher
F2.2 predeterminado sigue usando el fixture MP4. En la corrida Wayland del
2026-11-10 se observó la pista “English SRT”, texto visible, estado playing y
`First frame: processed`; la captura `subtitle-playing.png` y el log GTK están
bajo `.ai-local/f2.6/evidence/`. El motor reportó EGL inválido y usó renderizado
software; a pesar del aviso, la captura muestra frames y el texto. La prueba
no acredita renderizado hardware ni estilo visible de ASS. En ese entorno el
plugin devuelve textura registrada y el primer frame termina procesándose.

La captura `.ai-local/f2.6/evidence/subtitle-playing.png` se obtuvo en la
ventana real KDE Wayland del launcher
`tools/player/run_f2_6_subtitle_spike.sh`. Se observan el frame del video, el
texto “Kongroo internal English subtitle”, estado `playing`, posición
00:01/00:08, controller listo, textura registrada y primer frame procesado. El
log compañero está en `gui-player.log`. El motor notificó contexto EGL inválido
y pasó a renderizado software; esto verifica salida visible en esa sesión, no
aceleración hardware. La captura confirma esa pista SRT; el render de ASS no se
validó en compositor. Fontconfig emitió avisos de caché no escribible, aunque
el texto SRT sí quedó visible.

## DEMO extendido

El launcher y el flujo manual están en [la guía DEMO](../../../../docs/player/operacion-extendida.md). AudioTrackSelector lista pistas de la generación actual. PlayerDemoPanel ofrece las dos entradas de episodio y sus espejos. PlayerNerdPanel muestrea solo cuando se habilita. La UI utiliza el mismo coordinador para el cambio de fuente y el cierre.

## UI con Morevna

[Controles, módulos y comandos de verificación](../../../../docs/player/demo-morevna.md). El diagnóstico se abre bajo demanda. La superficie mantiene una sola textura y la barra usa un layout estable entre ventana y fullscreen. Los fixtures sintéticos se activan con --synthetic.

## Reproducción desde proveedores públicos

`provider_playback_route.dart` monta el mismo `SpikePlayerModule`, el mismo
`SpikePlayerCoordinator` y la misma instancia de `media_kit` que el spike. La
ruta solo acepta las URIs HTTPS exactas ya resueltas y pasa el manager y el
episodio al `PlaybackSourceSwitchService` existente para cambiar de servidor.
La resolución vive en `data/player/providers`; los widgets no conocen los
scrapers ni su HTML.

La ficha presenta el selector de servidor después de que el manager devuelva
una fuente. Si no hay un stream directo, no abre el player. La prueba live
opcional `KONGROO_LIVE_PROVIDER_SMOKE=1` en
`test/data/player/providers/public_playback_provider_test.dart` utiliza
libmpv real: la última corrida encontró servidores TioAnime, pero ninguna
reprodujo el episodio 1. No afirmar operatividad hasta que pase esa prueba en
Fedora con un episodio real.
