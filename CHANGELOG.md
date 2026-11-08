# Registro de cambios

Cambios notables por versión y subfase. Sigue Conventional Commits para el historial técnico. No se anuncian releases hasta que el propietario apruebe una versión.

## Sin publicar

### F0.1 Entorno Fedora

- Se verificaron Flutter/Dart, compiladores, GTK3, libsecret y libmpv sin instalar ni modificar configuración del sistema.
- `flutter doctor -v` confirma toolchain Linux; Android SDK queda ausente y fuera del destino F0.
- Evidencia y versiones: [auditoría F0.1](docs/environment/F0.1-FEDORA.md).

### F0.4 Esqueleto Flutter Linux

- Se creó una app mínima con Linux, identidad de dominio Dart puro, composición UI, lints y prueba widget.
- `pub get`, análisis Dart, widget test y `flutter run -d linux` pasaron; Spectacle verificó la ventana Wayland en [captura](docs/perf/wayland-window-20261108.png). `flutter analyze` queda bloqueado por error LSP.

### F0.5 Controles de calidad

- Se añadieron CI local y comprobador de imports Dart con pruebas sintéticas válidas y negativas.
- 40 pruebas IA, formato Dart, análisis Dart, checker de imports, resolución de dependencias y widget test pasaron. CI queda no verde porque `flutter analyze` terminó con error LSP; no se oculta el bloqueo.

### F0.6 Medición inicial

- Bundle Linux release compilado. Tres ejecuciones registraron 462 ms medianos al primer frame rasterizado, RSS de 140096 KiB tras el frame, 145284 KiB tras cinco segundos y CPU de reposo de 0.60% de un núcleo.
- La ventana se verificó visualmente con Spectacle, pero no hay latencia numérica (xdotool no observa Wayland). El entorno reporta 7.5 GiB RAM y no representa el objetivo de 4 GB. No se midió reproducción ni fugas prolongadas.
- Datos: [medición F0.6](docs/perf/measure-20261108T133341Z-15982.tsv); método: [docs/perf/README.md](docs/perf/README.md).

### F0.3 Documentación

- Se añadieron plan, arquitectura, hoja de ruta, progreso, decisiones técnicas y guía de pruebas como documentación de continuidad.
- Se completaron los ocho documentos Markdown requeridos. D3/Licencia queda pendiente y no bloquea F0.3; no se creó un archivo LICENSE sin decisión aprobada.

### F0.2 Repositorio

- Se preparó el repositorio privado de desarrollo, sus reglas Git y el proceso separado de publicación pública.
- Commit inicial: `84efbfb`; cierre documental: `b18a79c`.
