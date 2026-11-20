# Investigación aplicada — 2026-11-20

Fuentes primarias consultadas hoy; no se copiaron implementaciones ni se cambió
ninguna dependencia. Entorno instalado: Flutter local 3.47.9, Dart 3.13.7,
media_kit 1.2.6, media_kit_video 2.0.1, flutter_lints 6.0.0. El lock manda sobre
los ejemplos de main upstream. Ver dependencias completas en INVENTARIO.

- [Guía Flutter](https://docs.flutter.dev/app-architecture/guide): separar vistas,
  view_models, repositorios y servicios. Aplicable extraer coordinación del widget;
  dominio opcional donde ya existe lógica compleja. No exige reescribir parsers.
- [Result](https://docs.flutter.dev/app-architecture/design-patterns/result): hace
  explícito éxito/fallo. El proyecto ya tiene Result y PlaybackProviderResult;
  conservar sus contratos, no sustituirlos por otra jerarquía dentro del refactor.
- [Compass](https://github.com/flutter/samples/tree/main/compass_app), consultado
  mediante su [README oficial](https://raw.githubusercontent.com/flutter/samples/main/compass_app/README.md):
  ejemplo de separación por funcionalidades, datos locales y entornos. Adoptar
  separación y fakes, no su backend, negocio ni dependencias. La página del árbol
  falló en el navegador de investigación; el README sí fue leído.
- [very_good_analysis](https://github.com/VeryGoodOpenSource/very_good_analysis):
  referencia de lints estrictos. Mantener flutter_lints y reglas actuales;
  instalarlo introduciría nuevas incidencias y cambiaría pubspec/lock, fuera del
  alcance autorizado. Comparar reglas una a una en futura decisión separada.
- [media-kit](https://github.com/media-kit/media-kit): liberar Player con dispose,
  conservar aceleración hardware. Context7 `/media-kit/media-kit` confirmó nombres
  de bufferSize y enableHardwareAcceleration; se cotejaron con fuentes instaladas
  bajo `.ai-local/pub-cache/hosted/pub.dev/`. PlayerConfiguration de 1.2.6 declara
  bufferSize predeterminado 32 MiB; VideoControllerConfiguration de 2.0.1 declara
  enableHardwareAcceleration=true. Son defaults de biblioteca, no mediciones ni
  evidencia de qué configuración runtime se aplica en cada plataforma.

El producto actual usa composición manual, StatefulWidget/ValueNotifier y
Navigator/MaterialPageRoute. No introducir Riverpod, go_router ni freezed:
la continuación exige conservar gestor, navegación, dependencias y comportamiento.
Las reglas objetivo históricas se aplicarán sin migración tecnológica implícita.
El catálogo actual usa AniList/Kitsu y existe identidad MyAnimeList en proveedores;
no reemplazar el catálogo por asumir el nombre del documento original.

No se midieron RAM, jank, arranque ni reproducción real en esta sesión.
