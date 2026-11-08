# Pruebas de AnimeApp

Esta guía distingue pruebas disponibles de las previstas. Nunca marques una comprobación como aprobada si no se ejecutó en el entorno y versión registrados.

## Infraestructura de IA disponible

Desde la raíz del repositorio:

```bash
python3 tools/ai/memory.py check
python3 -W error::ResourceWarning -m unittest discover -s tests/ai -v
```

Estas pruebas validan las herramientas de memoria, evaluación y ejecución aislada; no prueban la app Flutter ni reproducción de video. Para repetir evaluación de recuperación, consulta `docs/ai-system/EVALUATION.md`.

Los controles integrados se describen en [scripts/README.md](scripts/README.md); la ejecución completa usa `bash scripts/ci.sh`.

## Aplicación Flutter

### SDK y alcance del arreglo LSP

La versión instalada se volvió a verificar como Flutter 3.47.9 stable, revisión `c197ca5199e9ee5661e865596c9c07294dfab51c`, Dart 3.13.7. El manifest oficial de releases lista esa revisión como stable vigente al 2026-11-08 y 3.50.0-0.4.pre en beta con Dart 3.14; el changelog 3.47.9 no lista #191377. No se identificó una versión estable publicada que incluya ese arreglo; la versión instalada sigue reproduciendo el fallo.

La beta 3.50.0-0.4.pre sería compatible con `sdk: ^3.13.7`, pero no se completó la prueba aislada: el bundle oficial Linux pesa 1,516,903,176 bytes y la transferencia observada rondó 0.3 MiB/s (más de una hora estimada). Se canceló tras unos 7.7 MiB y se eliminó el archivo parcial creado para esa prueba. El SDK global quedó intacto. No se afirma que la beta pase el análisis ni que contenga el arreglo sin probarla. Fuentes: [manifest oficial de releases](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json), [changelog Flutter](https://github.com/flutter/flutter/blob/master/CHANGELOG.md), [PR #191377](https://github.com/flutter/flutter/pull/191377).

La base de entorno comprobada está en [F0.1 Fedora](docs/environment/F0.1-FEDORA.md); reporta versiones y límites de plataforma.

F0.4 creó un esqueleto Linux dentro de `app/` y conservó `pubspec.lock`. Desde esa carpeta:

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run -d linux
```

Resultados observados en esta sesión:

- `flutter pub get`: pasó usando caché en `.ai-local/pub-cache`.
- `dart analyze lib test`: pasó, sin issues.
- `flutter test`: pasó (1 widget test).
- `flutter run -d linux`: compiló y lanzó la app; hubo warnings GTK/ATK del entorno. No quedaron procesos de AnimeApp abiertos.
- `flutter analyze`: **bloqueado en Flutter 3.47.9/Dart 3.13.7**. `flutter analyze --no-pub` y `flutter analyze --no-pub .` reproducen exit 255 en `LspByteStreamServerChannel._readMessage`, con un `initialize` JSON truncado. `dart analyze lib test` pasa en la misma ruta. La ruta incluye el carácter no ASCII `í` en `Vídeos`; el caso coincide con la regresión de Flutter que calcula `Content-Length` en caracteres en vez de bytes UTF-8. La causa es consistente con la incidencia oficial y su corrección [Flutter #191309](https://github.com/flutter/flutter/issues/191309), [PR #191377](https://github.com/flutter/flutter/pull/191377). No se hizo un control ASCII local porque el proyecto no debe moverse ni copiarse fuera de la raíz; espacios solos no se han demostrado como causa. No se desactivó el análisis ni se reemplazó permanentemente `flutter analyze`.

`flutter run -d linux` compiló e inició la app. Spectacle con captura `--activewindow` en la sesión KDE Wayland guardó [evidencia visual](docs/perf/wayland-window-20261108.png) (1280×768): muestra la barra GTK, título `anime_app`, título de pantalla AnimeApp, icono y texto inicial. Esto confirma que el compositor presenta el scaffold visible; la pantalla aún no tiene controles interactivos que probar. `xdotool` no observa superficies Wayland, así que la latencia numérica de ventana queda NA. La captura visual no es medición de arranque.

`flutter screenshot --type=skia` falló con Impeller (`Cannot capture SKP screenshot with Impeller enabled`); se descartó ese método y se usó captura de ventana activa por Spectacle. El log temporal generado por Flutter se retiró después de registrar el resultado.

## Rendimiento y pruebas manuales

La [línea base release final](docs/perf/measure-20261108T133341Z-15982.tsv) registra tres primeras tramas rasterizadas (mediana 462 ms), RSS (140096 KiB tras frame; 145284 KiB tras reposo a 5 s) y CPU media en reposo de 0.60% de un núcleo. Su método y límites están en [docs/perf/README.md](docs/perf/README.md). La ventana tiene evidencia visual, pero no latencia numérica; la app no reproduce medios y la prueba no cubre fugas prolongadas.

Registrar entorno, modo, repeticiones y limitaciones para cada nueva línea base. RSS del proceso no equivale a memoria total del sistema. Los checklists manuales por plataforma se incorporarán cuando existan esas plataformas.
