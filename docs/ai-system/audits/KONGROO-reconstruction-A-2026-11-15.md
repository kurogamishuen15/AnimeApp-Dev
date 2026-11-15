# Auditoría de reconstrucción Kongroo — Bloque A

**Fecha:** 2026-11-15
**Alcance:** T00–T03 únicamente.
**Rama/base:** `main`, `33ceaef5b996c55577524c3448bbb4bee5363952`.
**Estado Git:** al redactar esta auditoría, la ejecución de Bloque A todavía no tenía commit/push. Después, el propietario autorizó materializarla en el repositorio privado `AnimeApp-Dev`; el resultado está en el historial de `main`. El ZIP y `KONGROO-RECONSTRUCTION-AUTOMATION.md` se mantienen fuera del cambio.

## Alcance y evidencia

Se inspeccionaron la app y sus pruebas, manifiestos Flutter, CI y checker de imports, documentación/memoria, configuración Linux y rutas de catálogo/reproductor relevantes. El texto literal `No se encontró un servidor HTTP disponible` no aparece en `app/lib` ni en el bundle release examinado el 2026-11-15. No se atribuyó a una ruta actual; la explicación compatible con la evidencia es un desfase de versión o una ruta antigua, sin poder determinar su origen histórico.

La ruta activa de catálogo resuelve candidatos mediante `PlaybackProviderManager` y entrega una selección a `ProviderPlaybackRoute`, que crea el módulo de `media_kit`/libmpv. La UI y el composition root comparten la implementación del player; no se agregó un segundo motor.

Grafo verificado para el alcance: `app` compone pantallas, catálogo, providers y reproductor; `application` orquesta casos de uso y managers; `domain` define contratos/modelos neutrales; `data` adapta providers, persistencia y `MediaKitSpikeEngine` hacia esos contratos; `core` contiene resultados/errores/logging compartidos; `settings` separa registry/store. El runner Linux conecta GTK con Flutter; `media_kit` es la única ruta nativa del reproductor. Los fakes de metadata y providers están aislados para test/demo; `PlayerDemoSession` no es un proveedor real. El grafo general queda en `ARCHITECTURE.md` y los responsables/README en `docs/memory/MODULE_INDEX.md`.

Las pruebas unitarias de proveedores y UI no acreditan disponibilidad externa. En esta ejecución no se hicieron solicitudes nuevas a proveedores ni reproducciones externas: el contador de esta misión permanece en **0/70**.

## Inventario T00

- **UI y composición (`app`):** `CatalogHomePage`/ficha inician búsqueda; `ProviderPlaybackRoute` recibe la fuente permitida y abre/cierra el módulo existente. `SpikePlayerPage` presenta estado y controles, sin ser dueña de la API nativa.
- **Aplicación (`application`):** `PlaybackProviderManager` resuelve candidatos; `PlaybackSourceSwitchService` y `SpikePlayerCoordinator` orquestan cambio de fuente y comandos.
- **Dominio (`domain`):** contratos de provider, episodio, fuente y resultado; no importa Flutter, HTTP ni libmpv. `core` comparte `Result`/errores; `settings` mantiene su registry/store.
- **Datos (`data`):** adaptadores AniList/proveedores, Drift y el único `MediaKitSpikeEngine`; el engine integra `media_kit` con libmpv. En Linux el runner usa GTK3; el gate de CI `pkg-config --exists gtk+-3.0` pasó.
- **Tests/fakes:** `FakeMetadataProvider`, providers mock y `PlayerDemoSession` son rutas de demo/test explícitas. No se clasificaron como código obsoleto solo por no ser producción; no se hizo borrado ni un escaneo general de dead code. La CI ejercita contratos, widgets, almacenamiento y fixtures locales con libmpv; no produce un porcentaje de coverage.
- **Docs desactualizados corregidos:** `ARCHITECTURE.md` describía el player como desconectado del catálogo; `MODULE_INDEX.md` tenía la misma descripción. Ahora documentan el recorrido integrado y el límite de reproducción externa. Los READMEs app/catalog/player, `PROGRESS.md`, `TESTING.md`, estado y handoff registran los nuevos contratos y resultados.

## Hallazgos y cambios del Bloque A

| Hallazgo reproducible | Severidad | Archivos principales | Cambio y regresión |
|---|---:|---|---|
| `spike_player_page.dart` accedía a entorno/plataforma mediante `dart:io`, cruzando el límite que protege el checker de imports. | P1 | `app/lib/app/player/spike_player_page.dart`, `spike_player_module.dart`, `spike_player_page_options.dart` | El acceso quedó en el composition root y la pantalla recibe `SpikePlayerPageOptions` inmutables/validadas; se añadieron pruebas de opciones y se conservó el checker. |
| La vista de catálogo no presentaba de forma útil los resultados vacíos ni los fallos tipados de resolución. | P1 | `app/lib/app/catalog/catalog_home_page.dart`, `playback_resolution_message.dart` | Se agregó `PlaybackResolutionMessage` y su integración, con mensajes seguros y pruebas para resultados vacíos, errores y cancelación; no se muestran URLs ni detalles de transporte. |
| La apertura del player podía fallar antes de presentar una ruta recuperable y el cierre podía permitir salir mientras la limpieza nativa seguía pendiente. | P1 | `app/lib/app/player/provider_playback_route.dart`, `playback_route_session.dart`, `spike_player_module.dart` | Se introdujo el contrato `PlaybackRouteSession`, un estado de ruta explícito, espera de `close()`, CTA de retorno ante contención y bloqueo de navegación cuando la limpieza es insegura. Una limpieza fallida puede reintentarse. |
| Una colisión del lease global se podía confundir con un fallo de cleanup y provocar una liberación/reintento indebido del recurso de otra sesión. | P1 | `app/lib/data/player/engine/active_player_lease.dart`, `app/lib/app/player/spike_player_module.dart` | `ActivePlayerLeaseInUse` se distingue en adquisición y retry, se propaga como `StateError` compatible con consumidores anteriores, y el módulo no intenta limpiar el lease que pertenece a otra sesión. Las pruebas deterministas comprueban contención post-preflight y rollback síncrono exitoso/fallido. |
| Los argumentos inválidos no transferían propiedad de los callbacks de cleanup. | P3 | `app/lib/app/player/spike_player_module.dart` | El contrato está documentado y probado: el llamador mantiene esa propiedad si la validación falla. |

La construcción real de `Player` puede adquirir el lease antes de lanzar; el rollback espera `retryPendingDispose()` para observar ese estado. Un intento de prueba con dos aperturas de `SpikePlayerModule` y libmpv real agotó 45 segundos y se retiró; no cuenta como prueba aprobada. La cobertura determinista verifica la lógica del lease y rollback, pero no reproduce ese caso de concurrencia mediante dos construcciones nativas.

## Auditoría independiente

`auditor_codigo` revisó la implementación de solo lectura y no encontró P0/P1/P2 abiertos. La revisión tomó como evidencia reportada las pruebas focalizadas del coordinador y no ejecutó pruebas propias. Consideró resueltos los anteriores vacíos de contención post-preflight y rollback con pruebas sintéticas. Su limitación principal es la ausencia de una prueba nativa de apertura simultánea; tampoco hay una prueba automatizada end-to-end del ciclo de vida completo de `VideoController`. Esto queda como límite de evidencia para trabajo posterior, no como reproducción verificada de una regresión.

Una segunda pasada revisó la compatibilidad añadida después: `ActivePlayerLeaseInUse` extiende `StateError`, y `acquire()`/`retryPendingRelease()` conservan el tipo específico. No encontró P0/P1/P2; recomendó como mejora menor una aserción explícita de compatibilidad con `StateError`. Se añadió esa aserción y pasaron 12/12 pruebas de lease/módulo/ruta; la CI final exit 0 se ejecutó después de incluirla.

## Verificaciones ejecutadas

| Comando / comprobación | Resultado |
|---|---|
| `flutter test --no-pub test/player/spike_player_module_test.dart test/player/provider_playback_route_test.dart test/player/active_player_lease_test.dart test/player/spike_window_close_gate_test.dart test/catalog/playback_resolution_message_test.dart` (desde `app/`) | Exit 0; 18 pruebas pasaron. |
| `flutter test --no-pub test/player/spike_player_module_test.dart test/player/provider_playback_route_test.dart test/player/active_player_lease_test.dart` (desde `app/`) | Exit 0; 12 pruebas pasaron, incluida la aserción `ActivePlayerLeaseInUse` y `StateError`. |
| `flutter test --no-pub test/player/media_kit_spike_dispose_failure_test.dart` (desde `app/`) | Exit 0; 1 prueba con libmpv pasó. |
| `flutter test --no-pub test/player/media_kit_spike_integration_test.dart --plain-name 'real libmpv opens, advances, pauses, seeks, stops and disposes'` | Exit 0; 1 prueba con fixture local/libmpv pasó. |
| CI final `scripts/ci.sh`, SDK de proyecto `.ai-local/toolchains/flutter-3.47.9`, resolución Pub offline | Exit 0: 40 pruebas Python, 262 Flutter pasaron y 6 opt-in se omitieron; memoria, import checker, Dart/Flutter analyze y formato pasaron. |
| `flutter analyze --no-pub` después de retirar el import redundante | Exit 0; no issues found. |
| Checker real de imports | 30 archivos player y 34 archivos domain validados. |
| `dart format --output=none --set-exit-if-changed` (CI) | Exit 0; 183 archivos sin cambios de formato. |
| `python3 tools/ai/memory.py check` | Exit 0; `[]` después de crear el informe. |

`git diff --check` terminó exit 0. La inspección del lockfile mostró que `flutter pub get --offline` había reemplazado la resolución versionada (`listen 1.0.1`, `test_api 0.7.14`) con una variante del caché local; esos cambios generados se restauraron a los valores de HEAD. El informe y el tablero documentan G1 como completado; el gate no extiende su alcance a T04/B.

## Límites fuera del cierre de Bloque A

- No se confirmó ninguna reproducción externa; proveedores, episodios y fuentes reales siguen pendientes de los bloques posteriores.
- No se intentó reparar el SDK global. Se usó el SDK local de proyecto; el fallo histórico del SDK en `PATH` no se declara resuelto.
- No se modificó el diseño visual ni se inició el siguiente bloque.
- La ejecución técnica de Bloque A no hizo commit/push; la autorización posterior al repositorio privado se materializa en el historial Git de `main`.
