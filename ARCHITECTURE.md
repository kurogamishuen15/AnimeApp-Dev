# Arquitectura de AnimeApp

Esta página registra la arquitectura objetivo y distingue contratos aprobados de componentes aún no implementados. La aplicación Flutter todavía no existía al comenzar F0.3; no asumir que los diagramas describen código ya presente.

## Capas

```text
Presentación (features/*/ui)
        ↓ acciones / estado
Aplicación (casos de uso y coordinación)
        ↓ contratos
Dominio (modelos, reglas e interfaces Dart puras)
        ↑ implementaciones
Infraestructura (persistencia, red, proveedores y motor multimedia)
```

Las dependencias deben dirigirse hacia contratos de dominio. `domain` no importa Flutter, UI, proveedores concretos ni infraestructura. Las funciones de negocio se prueban sin iniciar Flutter. Las carpetas solo se crean cuando alojan responsabilidades reales.

## Componentes previstos

- `core`: errores, resultado, identificadores, reloj, logs y capacidades de plataforma compartidas.
- `domain`: modelos y contratos para catálogo, biblioteca, progreso, proveedores, descargas y sincronización.
- `data`: adaptadores de AniList, base local, sincronización y servicios externos.
- `features`: interfaces y coordinación de cada recorrido de usuario; una feature no importa la UI de otra.
- `player`: sesión, controlador y motor tras `PlaybackEngine`; la interfaz nunca controla directamente el motor.
- `providers`: contrato común, gestor y adaptadores aislados por fuente. El núcleo no contiene fuentes reales.
- `theming`, `settings`, `downloads` y `sync`: módulos independientes que se incorporan según las fases.

## Reproductor futuro

El flujo conceptual es `PlayerUI → PlayerController → PlaybackSession → PlaybackEngine → MediaKitPlaybackEngine → media_kit/libmpv`. El usuario confirmó media_kit/libmpv como integración inicial a verificar; la alternativa directa a libmpv no se descarta si aparece una limitación demostrable. La fase actual no implementa el reproductor.

## Plataformas

Se comparte dominio y lógica portable. Ventanas, almacenamiento seguro, entrada de teclado/táctil/mando, renderizado multimedia y empaquetado quedan detrás de adaptadores o composición específica de plataforma. Ocultar un control no garantiza excluir su dependencia del paquete; verificar dependencias y artefactos por plataforma.

## Rendimiento y recursos

Cada módulo es responsable de cancelar tareas, cerrar streams/controladores y liberar recursos. Las cachés deben tener límites. Medir arranque, RSS, CPU, reproducción, fluidez y estabilidad con procedimientos reproducibles. Los objetivos iniciales están en `PROJECT_PLAN.md`; resultados medidos se guardan en `docs/perf/`.

## Estado de implementación

F0.4 añadió `app/lib/domain/app_identity.dart`, que no importa Flutter, y la composición de UI en `app/lib/app/anime_app.dart`. `app/lib/main.dart` conecta el widget raíz y, solo bajo una variable de entorno opt-in, registra el primer frame rasterizado para F0.6. La app aún no tiene catálogo, navegación, servicios, repositorios ni motor de video. `dart analyze lib test` no reportó problemas y la prueba widget pasó. `flutter analyze` reproduce un error LSP al serializar una ruta no ASCII en Flutter 3.47.9; está registrado con fuente upstream en `TESTING.md` y no se considera aprobado.
