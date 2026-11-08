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

### Documentación F0.3

F0.3 requiere ocho documentos Markdown: `README.md`, `PROJECT_PLAN.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `PROGRESS.md`, `TECH_DECISIONS.md`, `CHANGELOG.md` y `TESTING.md`. README es el índice principal. `LICENSE` es un archivo adicional previsto y queda sujeto a D3, pendiente de elección del propietario; no bloquea completar F0.3 ni se crea un texto legal provisional.

## Criterio de finalización

Una subfase requiere implementación real, pruebas pertinentes, resultado observado, análisis de rendimiento cuando aplique y documentación actualizada. Un bloqueo o una prueba no ejecutada se registra como tal; no se sustituye por una afirmación de éxito.

## Decisiones pendientes

La licencia del proyecto, varias dependencias de aplicación y los servicios backend siguen sujetos a las decisiones anotadas en `TECH_DECISIONS.md`. Las versiones de herramientas y compatibilidad deben verificarse en el entorno antes de utilizarlas.
