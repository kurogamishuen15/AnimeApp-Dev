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

`flutter run -d linux` compiló, inició el proceso `anime_app` y mostró el modo interactivo de Flutter/servicio VM. Se midió además el primer frame rasterizado en release. La sesión es Wayland: `xdotool` solo enumera ventanas Xwayland, no superficies Wayland, y no se obtuvo evidencia compatible del compositor sobre ventana creada, visible o funcional. Por tanto no afirmamos verificación visual. Las pruebas que requieran red se separan y no corren por defecto.

## Rendimiento y pruebas manuales

La [línea base release final](docs/perf/measure-20261108T133341Z-15982.tsv) registra tres primeras tramas rasterizadas (mediana 462 ms), RSS (140096 KiB tras frame; 145284 KiB tras reposo a 5 s) y CPU media en reposo de 0.60% de un núcleo. Su método y límites están en [docs/perf/README.md](docs/perf/README.md). La ventana sigue no observable en esta sesión; la app no reproduce medios y la prueba no cubre fugas prolongadas.

Registrar entorno, modo, repeticiones y limitaciones para cada nueva línea base. RSS del proceso no equivale a memoria total del sistema. Los checklists manuales por plataforma se incorporarán cuando existan esas plataformas.
