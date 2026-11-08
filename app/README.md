# AnimeApp — Linux

Esqueleto inicial Flutter para Linux. Mantiene la identidad del dominio en Dart puro (`lib/domain`) y la composición de interfaz en `lib/app`. No incluye reproductor ni dependencias de producto.

## Requisitos

- Flutter SDK con destino Linux habilitado.
- Herramientas nativas de compilación Linux requeridas por Flutter.

Desde esta carpeta, mantén la caché de paquetes dentro del proyecto:

```bash
mkdir -p ../.ai-local/pub-cache
PUB_CACHE="$(pwd)/../.ai-local/pub-cache" FLUTTER_SUPPRESS_ANALYTICS=true flutter pub get
```

## Comprobaciones

```bash
flutter analyze
flutter test
flutter run -d linux
```

En la verificación, `dart analyze lib test`, `flutter test` (1 prueba) y el arranque con `flutter run -d linux` pasaron. La visibilidad/funcionalidad de una ventana no se pudo comprobar porque la sesión es Wayland y las herramientas X11 no observan esas superficies. `flutter analyze` reproduce la excepción LSP en la ruta con `í`; consulta la evidencia en [../TESTING.md](../TESTING.md).

La medición release final registró mediana de 462 ms al primer frame rasterizado, RSS de 140096 KiB tras el frame y 145284 KiB tras cinco segundos, y CPU media de reposo de 0.60% de un núcleo. La ventana quedó como no observable; estos datos no miden reproducción ni fugas prolongadas. Consulta [medición F0.6](../docs/perf/measure-20261108T133341Z-15982.tsv) y [método](../docs/perf/README.md).

La pantalla inicial es adaptable a ventanas estrechas y anchas, con semántica para lectores de pantalla. Es un punto de partida, no una función de catálogo o reproducción.
