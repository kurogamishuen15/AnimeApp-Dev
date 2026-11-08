# Medición inicial de AnimeApp en Linux

`bash scripts/measure.sh` registra una línea base del bundle Linux `release`. No compila ni instala paquetes; requiere `app/build/linux/x64/release/bundle/anime_app`. Si falta, desde `app/` ejecuta:

```bash
mkdir -p ../.ai-local/pub-cache
PUB_CACHE="$(pwd)/../.ai-local/pub-cache" FLUTTER_SUPPRESS_ANALYTICS=true flutter build linux --release
```

Desde la raíz del repositorio:

```bash
bash scripts/measure.sh
```

Por defecto hace tres lanzamientos secuenciales y espera cinco segundos por muestra de reposo. `--runs N` (1–10), `--idle-seconds N` (1–300) y `--output docs/perf/nombre.tsv` ajustan la ejecución. Rechaza rutas de salida existentes y escribe solo dentro de `docs/perf/`. Una medición es válida únicamente si termina con `# complete true`; una interrupción conserva una salida parcial como `# status collecting`, que no debe usarse como resultado completo.

Antes de cada fila el script comprueba que `/proc/PID/exe` corresponde al bundle esperado. Registra PID, primer frame rasterizado, ventana visible si es observable, RSS tras frame y reposo, CPU media del proceso durante el reposo y medianas. El tiempo al primer frame se obtiene de una marca opt-in tras `waitUntilFirstFrameRasterized`: confirma rasterización del engine, pero no sustituye observar la ventana presentada por el compositor.

La detección de ventana usa `xdotool` o `wmctrl` en sesiones X11. En Wayland con backend Wayland registra `not-observable-wayland`; los detectores X11 no pueden observar esas superficies. La latencia de ventana queda `NA` y no se sustituye por la de primer frame. El RSS procede de `/proc/PID/status`; las muestras obligatorias ausentes marcan la corrida incompleta. CPU de un núcleo se calcula desde `utime+stime` en `/proc/PID/stat` sobre el intervalo de reposo.

El informe incluye versión de app, modo, kernel, arquitectura, CPUs en línea, RAM total y observador. No incluye usuario ni hostname. La app solo escribe la marca temporal cuando `ANIMEAPP_FIRST_FRAME_MARKER` está definida por el script; los lanzamientos ordinarios no generan archivos. La limpieza espera y recoge solo el PID propio, verificado contra la ruta del bundle; usa TERM y, si no responde, KILL únicamente sobre ese PID. El marcador temporal reside bajo `.ai-local/` y se retira al salir.

## Validación y resultados

La validación no invasiva incluye `bash -n scripts/measure.sh`, `scripts/measure.sh --help` y argumentos inválidos. La ejecución real del bundle produce el TSV. Si se interrumpe, conserva la salida marcada como collecting; no la trates como completa.

La primera ejecución se hizo en Fedora 44, kernel 6.19.10, x86_64 y 7,5 GiB RAM total, no en el equipo objetivo de 4 GB. La app todavía muestra solo la pantalla inicial. Estas muestras no miden reproducción ni fugas prolongadas; RSS/CPU en reposo no representan carga de reproducción. La ventana sí se verificó visualmente en Wayland con [captura de Spectacle](wayland-window-20261108.png), pero no se obtuvo latencia numérica en el TSV.
