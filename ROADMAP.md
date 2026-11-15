# Hoja de ruta AnimeApp

La numeración oficial es la del plan original. Esta hoja resume el orden y las dependencias conocidas; `PROGRESS.md` conserva el estado real de cada subfase.

## Dependencias entre fases

```text
F0 preparación
  └─ F1 núcleo
      ├─ F2 reproductor ─┐
      ├─ F3 UI ──────────┴─ F4 catálogo y funciones
      ├─ F5 plataformas y sincronización (parte posterior depende de F1/F4)
      └─ F6 ajustes y descargas (depende de módulos previos)
F7 estabilización ← resultados de las fases anteriores
```

La guía original sitúa el MVP después de integrar el núcleo, el reproductor mock y la UI mínima. No se adelantan funciones entre fases sin registrar y aprobar el cambio.

## F0 Preparación Fedora

| ID | Entregable |
| --- | --- |
| F0.1 | Verificar Fedora, Flutter/toolchain Linux, GTK, libsecret y disponibilidad de libmpv sin instalar paquetes sin autorización. |
| F0.2 | Git raíz, `.gitignore`, ramas/commits y separación privado/público. |
| F0.3 | Ocho documentos Markdown requeridos (README y siete referencias) completados y enlazados; D3/LICENSE se registra pendiente sin bloquear la subfase. |
| F0.4 | Esqueleto Flutter Linux mínimo, lints y ventana comprobada. |
| F0.5 | CI local reproducible y comprobación de imports con prueba positiva/negativa. |
| F0.6 | Línea base reproducible de inicio de proceso/ventana y RSS, con limitaciones registradas. |

## F1 Núcleo

F1.1 requisitos (aprobados: [18 FR, 13 NFR y trazabilidad](docs/requirements/F1.1-CORE-REQUIREMENTS.md)) → F1.2 decisiones tecnológicas (14 selecciones aprobadas como referencia; validaciones pendientes: [ADR](docs/adr/README.md)) → F1.3 arquitectura (**completada documentalmente**, [diagramas, módulos, flujos y estrategia Linux-first](ARCHITECTURE.md), [ADR-015](docs/adr/ADR-015-arquitectura-core-linux-first.md)) → F1.4 estructura modular mínima Linux (**completada**, [`app/README.md`](app/README.md), [`scripts/README.md`](scripts/README.md), checker y pruebas) → F1.5 registro tipado de ajustes → F1.6 persistencia Drift → F1.7 errores/logs → F1.8 cliente AniList GraphQL de lectura → F1.9 OAuth/almacén seguro → F1.10 progreso local → F1.11 contrato de sincronización/FakeRemote → F1.12 pruebas del núcleo.

F1.5 (infraestructura de registro tipado/store local), F1.6 (schema Drift y migración SQLite), F1.7 (errores/Result/logger), F1.8 (cliente AniList de lectura y caché acotada) y la infraestructura de almacenamiento seguro de F1.9 están implementadas técnicamente. F1.9 no define ni ejecuta OAuth: callback, grant, scope, expiración y revocación requieren una decisión; el runtime real del keyring y la elegibilidad de AniList siguen sin verificar. No se usaron credenciales ni llamadas externas. Estado y aplazamientos: [PROGRESS.md](PROGRESS.md).

F1.10 implementa progreso tipado con identidad de contenido/episodio independiente de AniList, checkpoints y recuperación local. El schema actual es v6 por identidad/membership/status provisional de catálogo; el progreso y los JSON heredados no se reinterpretan automáticamente. Pruebas en hardware modesto, acumulación estricta de tiempo activo y política cross-device siguen pendientes. Ver [README de progreso](app/lib/domain/progress/README.md), [ADR-A10](docs/adr/additional/ADR-A10-progreso-local.md) y [PROGRESS.md](PROGRESS.md).

F1.4 conserva solo el scaffold Linux y el dominio Dart puro existentes; no crea carpetas vacías ni código, servicios, interfaces o dependencias para Android, Android TV o Windows. El checker de imports protege todos los subdirectorios `domain` de `app/lib`. Las plataformas futuras se incorporarán con adaptadores solo tras identificar diferencias y consumidores reales. F1.5 define el catálogo y contrato funcional de ajustes; F1.6 aporta persistencia durable Drift, migraciones y verificación tras reinicio.

F1.11 aporta únicamente un contrato opaco de submit y FakeRemote configurable; no resuelve idempotencia, conflictos, reintentos ni orden y no activa Supabase. Ver [ADR-A11](docs/adr/additional/ADR-A11-sincronizacion-fakeremote.md) y [PROGRESS.md](PROGRESS.md).

F1.12 verificó el núcleo técnico mediante CI, fakes manuales, SQLite aislado y loopback HTTP; una falla remota fake conserva el progreso local. El resultado no cierra OAuth/keyring, modelo de progreso, política de conflictos ni elegibilidad AniList. CI pasa solo con el SDK beta aislado seleccionado; stable 3.47.9 mantiene el fallo LSP documentado. [Evidencia](docs/memory/sessions/2026-11-09-f1-12-core-tests.md).

El incremento de catálogo local-first añade contratos provider-neutral, UUID/crosswalk, biblioteca Drift v6 con estados provisionales, fake sintético offline e integración UI con progreso existente. El recorrido local mínimo está implementado y verificado; no completa F4 ni habilita proveedores externos. AniList requiere revisión de elegibilidad; TMDB de licencia/key/atribución y Kitsu Anime de términos/retención. ADR-A14 sigue pendiente de aceptación del propietario. Ver [auditoría](docs/architecture/catalog-system-audit.md), [arquitectura](docs/architecture/catalog-system.md), [pruebas](docs/development/catalog-testing.md) y [ADR-A14 propuesto](docs/adr/additional/ADR-A14-catalog-providers-identity.md).

## F2 Reproductor

F2.1 evaluación de motores → F2.2 spike media_kit → F2.3 controles → F2.4 sesión/estados → F2.5 contrato y proveedor mock → F2.6 subtítulos internos → F2.7 cambio de fuente → F2.8 subtítulos externos → F2.9–F2.10 saltos → F2.11 rendimiento y estabilidad.

F2.2 — spike opt-in de reproducción Linux — **completada y aceptada por el propietario el 2026-11-10**. El propietario verificó en Fedora imagen/audio, controles únicos, Play/Pause, Seek, dos ciclos Stop → Play con recuperación de imagen/audio y cierre normal de ventana/proceso. La CI completa pasó con exit 0 (40 pruebas de infraestructura y 99 Flutter), y el build Linux release con `-t lib/main_player_spike.dart` pasó. El backport local UTF-8 de Flutter 3.47.9 se conserva en `tools/flutter/` y `TESTING.md`; no modifica Flutter global. Limitación documentada: no hay prueba automatizada completa del lifecycle nativo de `VideoController`. Ver [PROGRESS.md](PROGRESS.md), [informe F2.2 v2](docs/player/F2.2-spike-report-v2.md), [reevaluación Stop → Play](docs/ai-system/audits/F2.2-stop-play-audit-2026-11-10.md) y [auditoría](docs/ai-system/audits/F2.2-audit-2026-11-10.md).

F2.3 — controles básicos por teclado — **implementada y verificada; pendiente de aceptación del propietario**. Space/K, flechas ±10 s seek, ±5 puntos de volumen, F/Escape GTK y botón visual fullscreen comparten su acción. Se corrigió una carrera reproducible: la respuesta inmediata de `setFullscreen` podía llegar después del evento nativo y revertir el estado observado. Pruebas focalizadas 20/20; CI completa exit 0 (40 Python + 118 Flutter), analyze sin issues y build Linux release `-t lib/main_player_spike.dart` exit 0. En KDE Wayland real se observó F→entrar, F→salir, Escape→salir, fotogramas cambiantes y cierre GTK desde fullscreen; audio no se midió por loopback en esta corrida y no se completó la comprobación de foco después de clic. Ver [README player](app/lib/app/player/README.md), [reevaluación F2.3](docs/ai-system/audits/F2.3-fullscreen-reevaluation-2026-11-10.md) y [TESTING](TESTING.md).

F2.4 — estado de reproducción — **implementada técnicamente; aceptación pendiente**. `PlaybackSessionSnapshot` añade estado tipado, seek ortogonal y generación de fuente; pruebas cubren transiciones, errores, rollback y cierre. Límite conocido: `Player.stream.error` entrega `String` sin identidad de fuente, por lo que un error nativo tardío no puede correlacionarse con certeza con A o B. Este riesgo no se declara resuelto por la generación Dart. Ver el README de application y `PROGRESS.md`.

F2.5 — contrato de proveedores — **implementada y revisada; aceptación pendiente**. Contratos provider-neutral y manager deduplican trabajo compartido con cancelación por caller. Pruebas verifican cancelación de uno/del último waiter y finalización tardía; la cancelación es cooperativa si el proveedor la observa. Informe: [auditoría F2.5](docs/ai-system/audits/F2.5-audit-2026-11-10.md).

F2.6 — subtítulos internos — **implementada y verificada técnicamente; aceptación pendiente**. Engine, coordinación, dominio y UI exponen pistas internas/externas ya conocidas por libmpv, estilo temporal, delay y política hardsub. CI final 40 Python + 150 Flutter, análisis limpio y build Linux release específico pasan. Captura KDE Wayland confirma frame y SRT visibles con fallback de software; ASS no tiene verificación visual. Sin lifecycle nativo automatizado completo de `VideoController`. Ver [auditoría F2.6](docs/ai-system/audits/F2.6-audit-2026-11-10.md).

F2.7 requiere resolver o acotar mediante evidencia el contrato de eventos nativos tardíos sin identidad de fuente antes de afirmar aislamiento completo de errores durante cambio de fuente. El orden posterior permanece autorizado por el propietario, pero ninguna subfase se considera aceptada automáticamente.

F2.8 — subtítulos externos — **implementada y auditada técnicamente; aceptación pendiente**. El dominio define queries/candidatos/resultados tipados, incluidos IDs padre y partes multipart; Dio adapta OpenSubtitles API v1, sigue redirects de búsqueda con hosts/ruta allowlisted, limita/valida archivos locales, conserva `Retry-After` y protege el cleanup de temporales. Application/UI conectan búsqueda y carga al coordinator existente y rechazan búsquedas reentrantes. Pasaron 24 tests focalizados, la integración con libmpv real, CI exit 0 (40 Python + 175 Flutter), análisis Flutter y build Linux release del entrypoint específico. Sin credenciales, API live, cuota y redirects reales no se probaron. La integración no comprueba glifos presentados por compositor. Ver informe [F2.8](docs/ai-system/audits/F2.8-audit-2026-11-11.md); no inferir aceptación formal.

## F3 UI y funciones posteriores

F3.1 componentes visuales → F3.2 layouts → F3.3 navegación → F3.4 Lite → F3.5 Base → F3.6 packs → F3.7 recursos visuales → F3.8 escalas → F3.9 usabilidad.

F4 cubre Home, búsqueda, descubrimiento/filtros, calendario, biblioteca, ficha, episodios, recomendaciones y selector aleatorio (F4.1–F4.10). F5 incorpora plataformas y sincronización (F5.1–F5.9; backend y cliente se prueban por separado). F6 incorpora ajustes, descargas y copias de seguridad (F6.1–F6.12). F7 mide, estabiliza y audita (F7.1–F7.10).

## Cambios y bloqueos

Las condiciones externas (servicios, drivers, APIs y permisos) se registran junto a la subfase afectada. Una modificación del orden debe explicar motivo, alternativas y consecuencias y esperar aprobación si cambia decisiones previas. No se rebautizan ni renumeran fases.

### Operación extendida del reproductor

El banco DEMO optativo y sus pruebas se describen en [la matriz de la operación extendida](docs/player/operacion-extendida.md). Este corte valida audio embebido y continuidad entre espejos HTTP locales. La reproducción de enlaces externos, la integración con episodios reales y la validación de 4 GB permanecen abiertas.
