# ADR F1.2 — Decisiones del plan maestro

Fuente: sección 3 de `Plan_AnimeApp_actualizado.docx`, lista transcrita por el propietario en conversación el 2026-11-08. El archivo DOCX no se inspeccionó ni se requiere para esta conciliación.

## Correspondencia exacta

| # original | Decisión de sección 3 | ADR | Coincidencia | Estado de aprobación en el proyecto |
| --- | --- | --- | --- | --- |
| 1 | Flutter + Dart | [ADR-001](ADR-001-cliente-flutter-dart.md) | Coincide | Aprobado en F0.4; ver `TECH_DECISIONS.md`. |
| 2 | media_kit (libmpv) detrás de `PlaybackEngine` | [ADR-002](ADR-002-motor-video.md) | Coincide; el wrapper visual `media_kit_video` también figura en el registro local | Aprobado como punto de partida; compatibilidad/rendimiento pendientes. |
| 3 | Riverpod | [ADR-003](ADR-003-estado-riverpod.md) | Coincide | Propuesta; aprobación formal pendiente. |
| 4 | go_router | [ADR-004](ADR-004-navegacion-go-router.md) | Coincide | Propuesta; aprobación formal pendiente. |
| 5 | Drift (SQLite) | [ADR-005](ADR-005-persistencia-drift.md) | Coincide | Propuesta; aprobación formal y spike pendientes. |
| 6 | Dio | [ADR-006](ADR-006-red-dio.md) | Coincide | Propuesta; aprobación formal y spike pendientes. |
| 7 | flutter_secure_storage | [ADR-007](ADR-007-secretos-flutter-secure-storage.md) | Coincide | Plan maestro lo especifica; no consta aprobación formal en el registro local. |
| 8 | AniList GraphQL, cliente propio, sin codegen | [ADR-008](ADR-008-anilist-graphql.md) | Añade GraphQL, cliente propio y restricción sin codegen al requisito local genérico de lectura AniList | Plan maestro lo especifica; no consta aprobación formal local. |
| 9 | Supabase (Postgres + Auth + RLS) | [ADR-009](ADR-009-backend-supabase.md) | Concreta el proveedor que el registro local dejaba pendiente | Plan maestro lo especifica; backend concreto no está formalmente aprobado en el registro local. |
| 10 | qr_flutter genera; mobile_scanner escanea solo Android | [ADR-010](ADR-010-qr.md) | Coincide | Plan maestro lo especifica; no consta aprobación formal local. |
| 11 | Motor propio con ThemeExtension | [ADR-011](ADR-011-temas.md) | Concreta ThemeExtension; el principio local de packs validables sí está aprobado | Principio de temas aprobado; mecanismo concreto no consta aprobado. |
| 12 | Estilo de subtítulos por propiedades de mpv | [ADR-012](ADR-012-subtitulos-mpv.md) | Coincide | Plan maestro lo especifica; no consta aprobación formal local. |
| 13 | flutter_test + fakes escritos a mano | [ADR-013](ADR-013-pruebas.md) | Coincide | `flutter_test` ya se usa en F0; estrategia de fakes del núcleo no consta aprobada. |
| 14 | Flatpak como formato Linux principal | [ADR-014](ADR-014-empaquetado-flatpak.md) | Coincide | Plan maestro lo especifica; no consta aprobación formal local. |

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

## Criterio de cierre de F1.2

La conciliación documental queda completa cuando cada fila 1–14 tiene un ADR coincidente con el plan, diferencias explícitas, estado de aprobación respaldado y verificación para su fase. Implementar o agregar paquetes requiere la aprobación y evidencia indicadas en cada ADR. Los ADR adicionales no sustituyen el conjunto original.
