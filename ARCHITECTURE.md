# Arquitectura de AnimeApp

Este documento conserva la arquitectura de referencia aprobada para F1.3 y registra las implementaciones locales posteriores. No todos los módulos conceptuales están implementados: el estado real se indica por módulo y en `PROGRESS.md`. El producto abre [Inicio](app/lib/app/home/README.md) dentro del shell de catálogo local offline y un spike aislado de reproducción local F2.2; el spike no está conectado a la navegación ni al catálogo.

## Decisión de plataforma

AnimeApp se construirá con un núcleo compartido y Fedora/Linux como primer destino de implementación y validación. Android, Android TV y Windows son destinos futuros. No se crearán ahora código, carpetas, adaptadores, servicios, interfaces ni dependencias específicos de esos destinos. Al incorporarlos se reutilizará el núcleo y se añadirán únicamente las piezas que una necesidad real de la plataforma justifique.

El código general se escribirá en Dart reutilizable cuando sea técnicamente viable. Dominio y aplicación no dependerán de Flutter UI, Linux, plugins ni servicios externos. Flutter se utiliza en las capas de presentación y composición; las APIs del sistema y las bibliotecas concretas quedan en adaptadores. Esto conserva la independencia del dominio sin crear puertos abstractos que aún no tengan consumidor.

## Diagrama de contexto

```mermaid
flowchart LR
  User[Usuario]
  Linux[Fedora / Linux\nDESTINO ACTUAL]
  App[AnimeApp\nFlutter UI]
  Core[Núcleo compartido Dart]
  OS[Servicios y APIs Linux]
  Future[Android · Android TV · Windows\nDESTINOS FUTUROS · NO IMPLEMENTADOS]
  User --> Linux --> App
  App --> Core
  App -->|adaptadores solo cuando se necesiten| OS
  Future -. reutiliza .-> Core
```

La línea discontinua indica una dirección de portabilidad futura, no una integración actual.

## Diagrama de capas y dependencias

```mermaid
flowchart TB
  UI[Presentación Flutter\napp / features UI]
  Use[Aplicación\ncasos de uso y coordinación]
  Domain[Dominio Dart puro\nmodelos, reglas y contratos]
  Infra[Infraestructura compartida\ndata e integrations]
  Linux[Adaptadores Linux concretos\nsolo ante necesidades reales]
  Plugins[Plugins / servicios del sistema]
  UI --> Use
  Use --> Domain
  Infra -. implementa contratos .-> Domain
  Linux -. implementa contratos necesarios .-> Domain
  Infra --> Plugins
  Linux --> Plugins
  Compose[Composición en app]
  Compose --> UI
  Compose --> Infra
  Compose --> Linux
```

Las flechas sólidas representan uso/configuración; las discontinuas representan implementación de contratos. El dominio no importa capas externas. La composición de dependencias ocurre en `app`; una feature no importa la UI de otra feature. Los módulos que no tengan responsabilidad real o consumidor no se crean.

## Módulos conceptuales

Estos nombres describen límites de responsabilidad; no ordenan crear de antemano todas las carpetas bajo `app/lib/`.

| Grupo | Responsabilidad y límite | Estado y portabilidad |
| --- | --- | --- |
| `app` | Arranque, composición y selección de implementaciones. | Parcial: bootstrap Flutter y composición del catálogo local Linux-first. |
| `application` | Coordinación de casos de uso Dart puros. | Implementado para catálogo; no depende de Flutter, SQL ni HTTP. |
| `domain` | Identidades, modelos, reglas y contratos Dart puros. | Implementado para identidad, catálogo, biblioteca, progreso, credenciales y sincronización. |
| `data` | Adaptadores de persistencia, proveedores y servicios externos. | Implementado para Drift/SQLite y fake de metadatos; proveedores reales no están conectados al flujo local. |
| `core` | Tipos y utilidades transversales realmente compartidos; contratos solo cuando haya necesidad concreta. | Implementado para `Result`, errores y logging; no debe convertirse en depósito de funcionalidades. |
| `shared` | Componentes reutilizables por más de una feature, con límites y ciclo de vida propios. | Planificado; crear al aparecer reutilización demostrada. |
| `features` | Recorridos independientes, cada uno con presentación y coordinación propias. | Planificado; lógica de negocio invoca aplicación/dominio y no importa otras UIs. |
| `integrations` | Clientes/adaptadores de AniList, persistencia, sincronización, reproductor y sistemas externos. | Planificado; aislar librerías aprobadas tras sus validaciones por fase. |
| `platform` | Adaptadores de capacidades concretas del sistema operativo. | No hay un framework de plataformas anticipado. En la etapa inicial solo se añade implementación Linux requerida. |
| Runner nativo | Ventana, ciclo de vida y conexión con el host Flutter. | Existe runner Linux en `app/linux`; sus detalles nativos no deben filtrarse al dominio. |

No se separan archivos solo por tamaño o por preferencia: un archivo propio se justifica por responsabilidad, estado/lógica, pruebas, reutilización, frecuencia de cambio o dependencias particulares. Componentes pequeños y cohesionados pueden compartir archivo. No crear carpetas con un único archivo sin motivo.

## Flujos de referencia

Los siguientes son diagramas de diseño, no afirmaciones de capacidades implementadas.

### Arranque en Linux

```mermaid
sequenceDiagram
  participant Host as Runner Linux
  participant Main as app/main.dart
  participant Composition as app / composición
  participant UI as Flutter UI
  Host->>Main: inicia proceso
  Main->>Composition: configura dependencias usadas
  Composition->>UI: crea widget raíz
  UI-->>Host: presenta ventana
```

Solo se inicializan servicios necesarios para el recorrido disponible. El arranque no debe cargar anticipadamente integraciones pesadas ni iniciar tareas de fondo innecesarias.

### Catálogo local offline (implementado parcialmente)

```mermaid
sequenceDiagram
  participant UI as app/catalog UI
  participant UC as CatalogService
  participant Port as Contratos/modelos domain
  participant Fake as FakeMetadataProvider
  participant Repo as Adaptadores Drift
  participant DB as Drift / SQLite
  UI->>UC: buscar / consultar / añadir
  UC->>Fake: búsqueda o detalles sintéticos
  UC->>Port: operaciones tipadas
  UC->>Repo: identidad, biblioteca y progreso
  Repo->>DB: lee/escribe datos locales
  DB-->>UI: resultado mediante aplicación/estado
```

El recorrido usa registros sintéticos y no hace solicitudes de red. `CatalogModule` compone servicio, fake, repositorios y base; es responsable de cerrarlos. Persisten identidad local, membresía de biblioteca y progreso tipado F1.10 en Drift v6. Los estados de biblioteca y `episode:1` son demostrativos. AniList/TMDB/Kitsu no están conectados a este flujo.

### Reproducción F2.2 (spike local, no flujo de producto)

```mermaid
flowchart LR
  PlayerUI[SpikePlayerPage] --> Coordinator[SpikePlayerCoordinator]
  Coordinator --> Contract[PlaybackSpikeEngine]
  Contract --> Adapter[MediaKitSpikeEngine]
  Adapter --> Backend[media_kit / libmpv del sistema]
  Adapter --> Surface[VideoController único]
  Surface --> PlayerUI
```

F2.2 implementa un puerto temporal `PlaybackSpikeEngine`, no el contrato final `PlaybackEngine` de F2.5. El adaptador crea un solo `Player` y su único `VideoController`; la UI usa el mismo controller mediante `MediaKitVideoSurface`. Esta superficie configura `NoVideoControls` para que `media_kit_video` no monte su barra adaptativa; Play/Pause, Stop y seek pertenecen solo a los controles de Kongroo. El entrypoint abre únicamente un fixture local. No modifica `main.dart`, navegación, catálogo, Drift ni progreso. El seek interactivo solicita el destino final y el adaptador valida `file:` y archivo regular existente. El runner GTK destruye la ventana solo después de la respuesta Dart que confirma cleanup real. Su watchdog de respuesta de 15 s devuelve “mantener abierta” si el cleanup sigue pendiente; no cancela ninguna operación nativa. La última ejecución no pudo compilar el entrypoint por un desacople del Flutter framework/engine local; por ello la UI corregida, el gesto GTK y un frame en compositor no se revalidaron. La auditoría de artefactos/licencias también sigue pendiente; ver el [informe F2.2 v2](docs/player/F2.2-spike-report-v2.md) y la [auditoría del 2026-11-10](docs/ai-system/audits/F2.2-audit-2026-11-10.md).

## Contratos y adaptadores

- Mantener el dominio Dart puro; no importar Flutter, Dio, Drift, Supabase, `media_kit` ni APIs del sistema desde dominio.
- La aplicación coordina casos de uso mediante contratos orientados a capacidades y resultados del negocio.
- Un adaptador se justifica cuando una dependencia externa, almacenamiento, sistema operativo o mecanismo de presentación debe aislarse o sustituirse. Evitar interfaces espejo de cada clase de una biblioteca.
- La capa de composición selecciona adaptadores Linux actuales y conecta implementaciones con contratos.
- Preservar persistencia local-first. Sincronización remota es posterior y no almacena archivos de video.
- El motor multimedia se valida antes de integrarse. `mobile_scanner` queda limitado a Android cuando esa plataforma se emprenda; no se incorpora en la etapa Linux.
- Mantener cancelación, errores tipados, cierre de streams/controladores y liberación de memoria/recursos en el módulo propietario.

## Estructura futura propuesta para F1.4

F1.4 implementará solamente el esqueleto necesario para Linux y los contratos compartidos que correspondan. Esta propuesta es el límite de planificación, no una autorización para adelantar implementaciones de F1.5 en adelante ni para añadir dependencias sin necesidad.

### Conservar como base existente

| Ruta existente | Uso |
| --- | --- |
| `app/lib/main.dart` | Punto de entrada Flutter existente. |
| `app/lib/app/anime_app.dart` | Widget raíz/composición UI existente. |
| `app/lib/domain/app_identity.dart` | Identidad Dart pura existente; mantener libre de imports Flutter. |
| `app/linux/` | Runner Linux generado/actual; modificar solo ante necesidad documentada. |

### Crear en F1.4 solo si los criterios lo justifican

| Ruta candidata | Propósito mínimo |
| --- | --- |
| `app/lib/app/` | Mantener composición/arranque y registro de implementaciones realmente usadas. |
| `app/lib/core/` | Tipos compartidos mínimos con dos o más consumidores o contrato requerido por un caso de uso. |
| `app/lib/domain/` | Modelos/reglas/puertos compartidos solo para requisitos incluidos en el alcance concreto de F1.4. |
| `app/lib/platform/linux/` | Adaptador Linux únicamente si el esqueleto requiere una capacidad del host que no proporciona Flutter directamente. |

No es obligatorio crear todas estas rutas; no crear estructura candidata vacía. `shared/`, `features/`, `integrations/` y adaptadores Android/TV/Windows quedan para fases que implementen responsabilidades reales. Drift, AniList, credenciales, sincronización y reproducción conservan sus subfases, no se adelantan como parte de este diseño. Los límites exactos de F1.4 deben contrastarse con sus criterios y los archivos actuales antes de escribir código.

## Documentación y portabilidad de módulos

Cada módulo importante tendrá un README propio junto con su implementación, no un README vacío anticipado. Incluirá: responsabilidad; arquitectura interna; tabla de archivos y funciones; contratos públicos; dependencias; flujo; estado/ciclo de vida; errores; configuración; pruebas; rendimiento; partes portables; dependencias Linux actuales; procedimiento de portado; riesgos y limitaciones. Actualizarlo con cada cambio relevante sin duplicar la arquitectura general.

Al incorporar una plataforma futura: inventariar dependencias reales, reutilizar dominio/aplicación, definir adaptadores solo ante diferencias demostradas, adaptar UI/controles, probar paridad funcional y medir rendimiento/tamaño. Las diferencias funcionales requieren justificación técnica documentada. No se preparan ahora adaptadores simulados ni servicios futuros.

## Rendimiento, seguridad y distribución

- Medir arranque, memoria, CPU, latencia, fluidez, estabilidad y tamaño en cargas y equipos reproducibles; modularidad y tree shaking no prueban por sí solos eficiencia.
- Inicializar servicios bajo demanda; cancelar trabajo y liberar recursos al terminar. Evitar procesos en segundo plano sin necesidad.
- Revisar permisos mínimos, tratamiento de credenciales y seguridad de Auth/RLS antes de habilitar Supabase. No alojar video en el backend.
- Revisar licencias y compatibilidad de dependencias antes de distribuir. Flatpak permanece como formato Linux principal propuesto; no se configura ni publica un paquete en F1.3.
- Las metas preliminares existentes no son resultados medidos ni presupuestos definitivos. Resultados reales se registran en `docs/perf/`.

## Estado actual de implementación

El catálogo se distribuye por capas: contratos/modelos en `app/lib/domain/catalog`, coordinación en `app/lib/application/catalog`, persistencia en `app/lib/data/local_db`, fake en `app/lib/data/metadata` y UI/composición en `app/lib/app/catalog`. El progreso tipado está en `app/lib/domain/progress` con adaptador en `data/local_db`; el formato opaco legado permanece separado para preservar compatibilidad. Los README de módulo detallan archivos, contratos, dependencias y pruebas.

F2.1 tiene evaluación documental y F2.2 tiene un spike nativo aislado con `media_kit`/libmpv. Las responsabilidades por archivo y los comandos verificados se documentan en los README de los módulos player y en [el informe v2](docs/player/F2.2-spike-report-v2.md). La señal del plugin de textura/primer frame no prueba presentación visual del compositor; en este entorno no se obtuvo captura nativa. El motor no se integra con progreso, catálogo, navegación ni persistencia. Android, Android TV y Windows no están implementados. El estado de F0.4–F0.6 se registra en [PROGRESS.md](PROGRESS.md) y [TESTING.md](TESTING.md).

## Decisión asociada

La estrategia **núcleo compartido + Fedora/Linux primero + adaptadores progresivos por plataforma** fue aprobada por el propietario para F1.3. Su registro independiente, alternativas y consecuencias están en [ADR-015](docs/adr/ADR-015-arquitectura-core-linux-first.md). Las selecciones F1.2 continúan sujetas a sus validaciones técnicas por fase.
