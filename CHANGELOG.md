# Registro de cambios

Cambios notables por versión y subfase. Sigue Conventional Commits para el historial técnico. No se anuncian releases hasta que el propietario apruebe una versión.

## Sin publicar

### F1.7 — Core result, errores y logging

- Añadidos tipos de error de aplicación y `Result<T>` con transformaciones tipadas.
- Añadido logger estructurado con sinks inyectables, timestamps UTC, correlation id y sanitización de estructuras, credenciales y URI. No persiste mensajes.
- Pruebas unitarias y revisión estática de seguridad documentadas en [README core](app/lib/core/README.md) y [sesión F1.7](docs/memory/sessions/2026-11-09-f1-7-core-result-logger.md).


### Reparación de análisis y CI (F0.4–F0.5)

- Causa LSP confirmada en Flutter 3.47.9: longitud de contenido en caracteres en vez de bytes UTF-8. El arreglo upstream está en PR #191377; la stable publicada sigue sin incluirlo.
- Validación aislada con Flutter 3.50.0-0.4.pre/Dart 3.14.0: probes Unicode, Flutter analyze, widget tests, build Linux release y CI pasan con selección explícita de SDK. La CI continúa fallando con stable 3.47.9 por el error LSP; estado parcial hasta que exista stable corregida.
- Se ubicaron correctamente los modos strict en `analyzer.language` y se migró el scaffold a `material_ui` oficial para eliminar issues reales bajo el analyzer actualizado. `pubspec.lock` queda resuelto con stable.
- Detalle, limitaciones y reproducción: [TESTING.md](TESTING.md) y [sesión de memoria](docs/memory/sessions/2026-11-08-flutter-analyze-ci-repair.md).


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
