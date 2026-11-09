# F0.4–F0.5: diagnóstico y reparación de analyze/CI

Fuente: comandos locales de Flutter/Dart, código del SDK instalado y fuentes oficiales enlazadas
Fecha: 2026-11-08
Módulo: F0.4–F0.5, tooling y scaffold Flutter Linux
Estado: reparación temporal validada; incidencia stable pendiente
Decisión: no adoptar beta como toolchain permanente; esperar release stable con PR #191377
Evidencia: comandos y resultados registrados en esta sesión y [TESTING.md](../../../TESTING.md)

## Estado antes

- Raíz: `/home/kyouma/Vídeos/PROYECTO ANIME`; rama `main`; `HEAD`=`origin/main`=`81e26baf027bdc955112ca72aeb1374d2fd73d31` antes de esta misión.
- Conservar sin mezclar los cambios concurrentes ajenos en `AGENTS.md`, `.codex/agents/`, `docs/ai-system/`.
- `which flutter`: `/home/kyouma/flutter/bin/flutter`; `which dart`: `/home/kyouma/flutter/bin/dart`.
- Flutter 3.47.9 stable, revisión `c197ca5199e9ee5661e865596c9c07294dfab51c`, Dart 3.13.7. Manifiesto oficial de releases consultado; stable vigente 3.47.9, beta vigente 3.50.0-0.4.pre.
- Desde `app/`, `dart analyze lib test` exit 0. `flutter analyze --no-pub` exit 255 con `FormatException: Unexpected end of input`, `LspByteStreamServerChannel._readMessage`; app y CI reproducen truncamiento del `initialize` LSP.
- `scripts/ci.sh` baseline: exit 1; 40 tests IA, checker fixture, format, Dart analyze, pub get y widget test pasan; la única comprobación obligatoria fallida fue Flutter analyze (255).

## Causa verificada

El archivo local de Flutter 3.47.9 `packages/flutter_tools/lib/src/dart/analysis.dart` calcula `Content-Length` como `${message.length}`. El PR oficial [#191377](https://github.com/flutter/flutter/pull/191377) modifica el transporte a longitud de bytes UTF-8, `utf8.encode(message).length`, y añade prueba. La stable 3.47.9 no tiene ese cambio; la beta 3.50.0-0.4.pre consultada en el tag sí lo tiene. El fallo coincide con la reproducción descrita en [#191309](https://github.com/flutter/flutter/issues/191309) y [#192079](https://github.com/flutter/flutter/issues/192079). No se asumió resolución por el cierre de incidencias.

## Probes

Se crearon dos paquetes mínimos en `.ai-local/diagnostics/ascii/probe` y `.ai-local/diagnostics/unicodé/probe`, cada uno con `pubspec.yaml` y `lib/main.dart`, mismo contenido y mismo SDK por corrida. En stable 3.47.9, `dart analyze` pasa en ambos y `flutter analyze --no-pub` falla en ambos con 255. El segmento `ascii` es ASCII, pero la ruta absoluta completa incluye `/home/kyouma/Vídeos/`; no se puede hacer un control absolutamente ASCII dentro de la raíz autorizada y por ello no se presenta como tal. En beta 3.50.0-0.4.pre, ambos probes pasan Dart y Flutter analyze (exit 0). El proyecto AnimeApp en la misma ruta Unicode también pasa Flutter analyze con beta.

## Toolchain aislado

La descarga del bundle completo oficial de 1,516,903,176 bytes progresaba a ~0.43 MiB/s; se canceló y retiró exactamente el archivo parcial propio. En vez de conservar ese archivo, se clonó el tag oficial:

- Ubicación ignorada por Git: `.ai-local/toolchains/flutter`.
- Tag: `3.50.0-0.4.pre`.
- Revisión: `368ac9e40bad0566927cc9428a42461152652c12`, coincidente con hash del manifiesto oficial.
- Flutter 3.50.0-0.4.pre; Dart 3.14.0 beta.
- SDK global y configuración global no modificados.
- Selección explícita por sesión: `export PATH="$PWD/.ai-local/toolchains/flutter/bin:$PATH"`; caché del proyecto: `PUB_CACHE="$PWD/.ai-local/pub-cache"`.

Es una selección temporal de validación, no una adopción permanente de canal beta. Con el stable actual, `flutter analyze` y CI predeterminada continúan fallando; la incidencia general permanece abierta hasta que una stable oficial incluya el PR.

## Cambios propios

1. `app/analysis_options.yaml`: mover strict-casts, strict-inference y strict-raw-types bajo `analyzer.language`, la estructura documentada. No se quitó ningún lint.
2. `app/pubspec.yaml`, `app/pubspec.lock`, `app/lib/main.dart`, `app/lib/app/anime_app.dart`: añadir `material_ui: ^1.10.0` y migrar los dos imports. En beta, los imports `package:flutter/material.dart` producían dos issues deprecados y Flutter analyze devolvía exit 1; usar la librería oficial evitó ocultar issues. `pubspec.lock` se resolvió finalmente usando stable para evitar el paquete transitorio `listen` propio de la beta.
3. `TESTING.md`, `app/README.md`, `docs/environment/F0.1-FEDORA.md`, `PROGRESS.md`, `CHANGELOG.md`, `docs/memory/PROJECT_STATE.md`, `docs/memory/AI_HANDOFF.md` y esta sesión: diagnóstico, workaround y estado parcial documentados.
4. No se cambió `scripts/ci.sh`; usa herramientas del PATH. Para repetir CI beta se requiere anteponer explícitamente el SDK aislado, evitando un path personal incrustado en un script público.

## Validación después

Con SDK beta seleccionado (un solo `flutter` y `dart` desde el SDK aislado):

- `flutter pub get`: 0.
- `dart format --output=none --set-exit-if-changed lib test`: 0 (4 archivos; 0 cambiados).
- `dart analyze lib test`: 0, sin issues.
- `flutter analyze --no-pub`: 0, sin issues.
- `flutter test --no-pub`: 0, widget inicial pasa (1 test).
- `flutter build linux --release --no-pub`: 0, bundle release creado.
- `dart scripts/check_imports.dart --root .`: 0.
- `bash scripts/test_check_imports.sh`: 0, positivo y diez negativos esperados.
- `bash scripts/ci.sh`: 0; incluye 40 pruebas IA y todas las verificaciones de aplicación.
- Prueba negativa de CI: fixture temporal `app/lib/domain/ci_probe_import_violation.dart` con import Flutter; CI exit 1 esperado en prueba sintética y límites de imports; archivo retirado tras confirmar contenido exacto.

Compatibilidad con stable global 3.47.9 después de migración: `flutter pub get`, `dart analyze lib test`, `flutter test --no-pub` y `flutter build linux --release --no-pub` pasan. `flutter analyze --no-pub` sigue en 255 por causa LSP externa. No se reporta CI stable como verde.

`flutter doctor -v`: Linux toolchain y Chrome pasan; Android SDK ausente, no afecta destino Linux. Las versiones exactas y limitación ASCII se detallan en `TESTING.md`.
