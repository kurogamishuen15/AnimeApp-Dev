# Código Flutter

La aplicación sigue una separación por capas; `main.dart` y los composition roots conectan implementaciones concretas. La ficha conecta AnimeAV1/TioAnime con el player `SpikePlayerModule` existente. La ruta de playback está implementada, pero la reproducción de un episodio externo real sigue sin validación exitosa; el progreso todavía no está integrado con el player.

| Carpeta | Responsabilidad | Guía |
|---|---|---|
| `app/` | Widgets, presentación y composition roots Flutter/Linux | [`app/README.md`](app/README.md) |
| `application/` | Casos de uso y coordinación sin widgets ni motor multimedia directo | [`application/README.md`](application/README.md) |
| `core/` | Errores, resultados y utilidades transversales | [`core/README.md`](core/README.md) |
| `data/` | Persistencia y adaptadores de servicios externos | [`data/README.md`](data/README.md) |
| `domain/` | Modelos, políticas y contratos neutrales | [`domain/README.md`](domain/README.md) |
| `settings/` | Registro y almacenamiento de ajustes | [`settings/README.md`](settings/README.md) |

Las dependencias deben apuntar hacia contratos/domain; los composition roots conectan implementaciones. Antes de crear una capa o carpeta, revisar la guía de arquitectura del repositorio. Los tests viven bajo `app/test/`; para análisis: `dart analyze lib test` desde `app/`.
