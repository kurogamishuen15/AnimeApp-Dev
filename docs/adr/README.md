# ADR F1.2 — Decisiones del plan maestro

Fuente: sección 3 de `Plan_AnimeApp_actualizado.docx`, lista transcrita por el propietario en conversación el 2026-11-08. El propietario aprobó formalmente las 14 selecciones el 2026-11-08 como arquitectura de referencia. El archivo DOCX no se inspeccionó ni se requiere para esta conciliación.

## Correspondencia exacta

| # original | Decisión de sección 3 | ADR | Coincidencia | Estado de aprobación en el proyecto |
| --- | --- | --- | --- | --- |
| 1 | Flutter + Dart | [ADR-001](ADR-001-cliente-flutter-dart.md) | Coincide | Aprobado previamente en F0.4; independencia del dominio respecto de Flutter se mantiene. |
| 2 | media_kit (libmpv) detrás de `PlaybackEngine` | [ADR-002](ADR-002-motor-video.md) | Coincide; `media_kit_video` es wrapper complementario del registro local | Aprobado como punto de partida; compatibilidad/rendimiento pendientes antes de integrar. |
| 3 | Riverpod | [ADR-003](ADR-003-estado-riverpod.md) | Coincide | Aceptado como selección arquitectónica; spike/ciclo de vida pendientes. |
| 4 | go_router | [ADR-004](ADR-004-navegacion-go-router.md) | Coincide | Aceptado; validación de flujos/targets en F3.3. |
| 5 | Drift (SQLite) | [ADR-005](ADR-005-persistencia-drift.md) | Coincide | Aceptado; schema, migraciones, licencias y rendimiento en F1.6. |
| 6 | Dio | [ADR-006](ADR-006-red-dio.md) | Coincide | Aceptado; timeout/cancelación/errores y licencia en F1.8/F5. |
| 7 | flutter_secure_storage | [ADR-007](ADR-007-secretos-flutter-secure-storage.md) | Coincide | Aceptado; seguridad/mecanismo/compatibilidad por plataforma en F1.9. |
| 8 | AniList GraphQL, cliente propio, sin codegen | [ADR-008](ADR-008-anilist-graphql.md) | Antes solo constaba lectura AniList genérica; se añadieron protocolo, cliente propio y no-codegen | Aceptado; contrato, consultas, límites y errores a verificar en F1.8. |
| 9 | Supabase (Postgres + Auth + RLS) | [ADR-009](ADR-009-backend-supabase.md) | Concreta el proveedor que el registro local dejaba pendiente | Aceptado como referencia; auth/RLS, transporte, offline y protección de datos deben verificarse antes de F5. |
| 10 | qr_flutter genera; mobile_scanner escanea solo Android | [ADR-010](ADR-010-qr.md) | Coincide | Aceptado; licencias/permisos/ciclo de vida en F5; escaneo Android únicamente. |
| 11 | Motor propio con ThemeExtension | [ADR-011](ADR-011-temas.md) | Concreta ThemeExtension; el principio de packs validables ya estaba aprobado | Aceptado; rendering/fallback/seguridad de packs en F3. |
| 12 | Estilo de subtítulos por propiedades de mpv | [ADR-012](ADR-012-subtitulos-mpv.md) | Coincide | Aceptado; verificar propiedades disponibles y efecto en F2. |
| 13 | flutter_test + fakes escritos a mano | [ADR-013](ADR-013-pruebas.md) | Coincide | Aceptado; validar contratos/fakes del núcleo en F1.12. |
| 14 | Flatpak como formato Linux principal | [ADR-014](ADR-014-empaquetado-flatpak.md) | Coincide | Formato principal propuesto para distribución, aceptado como referencia; permisos/licencias/artefacto en F5.1. |

## Cambios de interpretación corregidos

- La primera colección derivó catorce áreas de los documentos locales y numeró aparte el cliente AniList, OAuth, almacenamiento seguro y sincronización. Esa colección no correspondía uno a uno con la sección 3. Se corrigió el conjunto ADR-001–ADR-014 para que siga exactamente la lista suministrada.
- El requisito local de “cliente AniList de lectura” no decía GraphQL ni prohibía codegen. Se añadieron esos dos elementos como especificación del plan maestro, sin alegar que estuvieran antes documentados.
- La decisión local de backend seguía pendiente. Supabase queda como selección de plan, no como decisión formal aprobada. Se conserva el principio aprobado local-first/contrato REST y el backend no almacenará video.
- La aprobación del principio de temas no convierte automáticamente ThemeExtension en mecanismo aprobado.
- Que una tecnología aparezca en el plan maestro no demuestra por sí solo aprobación formal. El estado de cada entrada distingue evidencia local de selección en el plan.

## ADR adicionales conservados

Estos documentos pertenecen a la colección creada durante la primera pasada. No se cuentan entre las 14 decisiones originales y se retienen como contratos/análisis complementarios; no promueven ninguna propuesta a aprobada.

| ADR adicional | Contenido útil conservado | Relación |
| --- | --- | --- |
| [A01](additional/ADR-A01-arquitectura-por-capas.md) | Capas y dirección de dependencias | Principio arquitectónico transversal |
| [A02](additional/ADR-A02-transporte-http.md) | Alternativas y pruebas de transporte HTTP | Complementa ADR-006 |
| [A03](additional/ADR-A03-persistencia-local.md) | Opciones SQLite/Drift y migraciones | Complementa ADR-005 |
| [A04](additional/ADR-A04-errores-y-resultados.md) | Tipos de error/resultado | F1.7 |
| [A05](additional/ADR-A05-logs-y-redaccion.md) | Logging y redacción | F1.7 |
| [A06](additional/ADR-A06-ajustes.md) | Persistencia de ajustes | F1.5 |
| [A07](additional/ADR-A07-cliente-anilist.md) | Límites del cliente de lectura | Complementa ADR-008 |
| [A08](additional/ADR-A08-oauth-anilist.md) | Flujo OAuth AniList | F1.9; distinto de la decisión GraphQL |
| [A09](additional/ADR-A09-almacen-seguro.md) | Puerto de almacén seguro | Complementa ADR-007 |
| [A10](additional/ADR-A10-progreso-local.md) | Modelo/política de progreso local | F1.10 |
| [A11](additional/ADR-A11-sincronizacion-fakeremote.md) | Contrato local-first y FakeRemote | F1.11; complementa ADR-009 |
| [A12](additional/ADR-A12-gestion-de-estado.md) | Análisis inicial de gestión de estado | Complementa ADR-003 |
| [A13](additional/ADR-A13-navegacion.md) | Análisis inicial de navegación | Complementa ADR-004 |
| [A14](additional/ADR-A14-catalog-providers-identity.md) | IDs locales, crosswalk, provider-neutral, biblioteca y demo offline sintética | Propuesta parcialmente implementada; status provisional y pendiente de aceptación, no habilita fuentes ni modifica ADR-008 |

## Condiciones de la aprobación y validaciones pendientes

La aprobación es de **selección arquitectónica**, no de instalación inmediata ni de implementación fuera de fase. Se mantienen las condiciones del propietario: dominio independiente de Flutter; motor media_kit/libmpv aislado tras `PlaybackEngine`; rendimiento y compatibilidad real previos a integrar motor; persistencia local-first; validación de Supabase/Auth/RLS; backend sin videos; `mobile_scanner` solo Android; revisión de licencias/compatibilidad antes de distribuir; Flatpak como formato Linux principal propuesto.

Los ADR originales están aceptados como selección; cada uno conserva sus validaciones por fase. Los ADR adicionales A01–A14 son análisis/contratos complementarios; A14 continúa como propuesta y no se aprueba por implementación o documentación.

## Decisión arquitectónica F1.3

El propietario aprobó para F1.3 la estrategia **núcleo compartido + Fedora/Linux primero + adaptadores progresivos por plataforma**. Se registra como [ADR-015](ADR-015-arquitectura-core-linux-first.md), separado de los 14 ADR originales de tecnología y sin sobrescribir la colección adicional. La decisión mantiene Android, Android TV y Windows como destinos futuros; no autoriza código ni carpetas anticipadas. La propuesta y diagramas están en [ARCHITECTURE.md](../../ARCHITECTURE.md). En F1.4 se implementará solo el esqueleto Linux mínimo que sus criterios justifiquen.

## Criterio de cierre de F1.2

La conciliación documental queda completa cuando cada fila 1–14 tiene un ADR coincidente con el plan, diferencias explícitas, aprobación formal y verificación para su fase. La aprobación no autoriza instalar todas las dependencias ni adelantar implementación. Los ADR adicionales no sustituyen el conjunto original.
