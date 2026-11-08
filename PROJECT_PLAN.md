# Plan del proyecto AnimeApp

AnimeApp será una aplicación cliente multiplataforma para descubrir, organizar y reproducir anime. Este documento conserva el alcance y el orden del plan aprobado; una funcionalidad planificada no se considera implementada hasta que `PROGRESS.md` y sus pruebas lo demuestren.

## Objetivos y límites

- Comenzar en Fedora Linux y adaptarse después a Android, Android TV y Windows.
- Mantener el trabajo offline y el progreso local como base; la sincronización remota es posterior.
- Mantener proveedores de contenido fuera del núcleo y activados solo tras evaluación técnica y legal. El MVP usa un proveedor mock.
- No alojar video en el backend de sincronización.
- Aplicar optimización y documentación desde F0, con mediciones reales y reproducibles.
- No implementar reproductor, fuentes reales, descargas ni temas avanzados durante F0.3–F0.6.

## MVP previsto

En Fedora: buscar anime, consultar una ficha, elegir un episodio, reproducir un clip mock, cambiar de servidor mock conservando la posición y reanudar al abrir de nuevo. Incluye inicio de sesión/lista AniList según las fases aprobadas. El MVP no incluye proveedores reales, sincronización real, descargas, Android/TV/Windows, temas Otaku, OpenSubtitles, AniSkip, MAL, Simkl, Discord ni manga.

## Fases originales

| Fase | Alcance principal | Salida prevista |
| --- | --- | --- |
| F0 | Preparación Fedora, repositorio y calidad | Entorno comprobado, documentación, esqueleto Linux, controles de calidad y línea base inicial. F0.1 entorno Fedora; F0.2 Git; F0.3 documentación; F0.4 esqueleto; F0.5 calidad; F0.6 medición. |
| F1 | Núcleo y arquitectura | Ajustes, persistencia, errores/logs, AniList de lectura/login, progreso local y contratos de sincronización con fake. |
| F2 | Reproductor | Evaluar e integrar motor detrás de `PlaybackEngine`, sesión/control, proveedor mock, subtítulos internos y cambio de fuente. |
| F3 | UI y temas | Sistema visual, layouts, navegación, modos Lite/Base y packs validados. |
| F4 | Funciones de catálogo | Home, búsqueda, descubrimiento, calendario, biblioteca, ficha, episodios y recomendaciones por reglas. |
| F5 | Plataformas y sincronización | Fedora empaquetado, Android/TV, vinculación, backend y sincronización; Windows posterior dentro de la fase. |
| F6 | Ajustes y descargas | Registro/pantalla de ajustes, descargas permitidas por fuente y respaldo/restauración. |
| F7 | Estabilización | Medición y optimización basada en datos, estabilidad, sincronización, seguridad y documentación final. |

Las dependencias y criterios detallados de subfase se registran en `ROADMAP.md` y `PROGRESS.md`. Esta fase no cambia su numeración ni ordena adelantar dependencias.

### Selecciones tecnológicas del plan maestro (sección 3)

La siguiente transcripción de las 14 selecciones fue proporcionada por el propietario el 2026-11-08. La presencia en el plan maestro documenta la selección de planificación, pero no se trata automáticamente como aprobación formal de implementación. El estado de aprobación se registra por separado en `TECH_DECISIONS.md` y en cada ADR.

| N.º | Selección del plan | ADR |
| --- | --- | --- |
| 1 | Lenguaje y UI: Flutter + Dart | [ADR-001](docs/adr/ADR-001-cliente-flutter-dart.md) |
| 2 | Motor de video: media_kit (libmpv) detrás de PlaybackEngine | [ADR-002](docs/adr/ADR-002-motor-video.md) |
| 3 | Estado: Riverpod | [ADR-003](docs/adr/ADR-003-estado-riverpod.md) |
| 4 | Navegación: go_router | [ADR-004](docs/adr/ADR-004-navegacion-go-router.md) |
| 5 | Base local: Drift (SQLite) | [ADR-005](docs/adr/ADR-005-persistencia-drift.md) |
| 6 | Red: Dio | [ADR-006](docs/adr/ADR-006-red-dio.md) |
| 7 | Secretos: flutter_secure_storage | [ADR-007](docs/adr/ADR-007-secretos-flutter-secure-storage.md) |
| 8 | Catálogo: AniList GraphQL con cliente propio, sin generación de código | [ADR-008](docs/adr/ADR-008-anilist-graphql.md) |
| 9 | Backend sync: Supabase (Postgres + Auth + RLS) | [ADR-009](docs/adr/ADR-009-backend-supabase.md) |
| 10 | QR: qr_flutter para generar; mobile_scanner para escanear, solo Android | [ADR-010](docs/adr/ADR-010-qr.md) |
| 11 | Temas: motor propio con ThemeExtension | [ADR-011](docs/adr/ADR-011-temas.md) |
| 12 | Subtítulos: estilo aplicado con propiedades de mpv | [ADR-012](docs/adr/ADR-012-subtitulos-mpv.md) |
| 13 | Tests: flutter_test + fakes escritos a mano | [ADR-013](docs/adr/ADR-013-pruebas.md) |
| 14 | Empaquetado Linux: Flatpak como formato principal | [ADR-014](docs/adr/ADR-014-empaquetado-flatpak.md) |

Las decisiones de sincronización local-first, FakeRemote, contratos de capas, errores/logs, ajustes, progreso local y OAuth de AniList permanecen documentadas como ADR adicionales; no reemplazan estos catorce elementos.

### Documentación F0.3

F0.3 requiere ocho documentos Markdown: `README.md`, `PROJECT_PLAN.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `PROGRESS.md`, `TECH_DECISIONS.md`, `CHANGELOG.md` y `TESTING.md`. README es el índice principal. `LICENSE` es un archivo adicional previsto y queda sujeto a D3, pendiente de elección del propietario; no bloquea completar F0.3 ni se crea un texto legal provisional.

## Criterio de finalización

Una subfase requiere implementación real, pruebas pertinentes, resultado observado, análisis de rendimiento cuando aplique y documentación actualizada. Un bloqueo o una prueba no ejecutada se registra como tal; no se sustituye por una afirmación de éxito.

## Decisiones pendientes

La licencia del proyecto, varias dependencias de aplicación y los servicios backend siguen sujetos a las decisiones anotadas en `TECH_DECISIONS.md`. Las versiones de herramientas y compatibilidad deben verificarse en el entorno antes de utilizarlas.
