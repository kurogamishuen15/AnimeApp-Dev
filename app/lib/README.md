# Código Flutter

La aplicación sigue una separación por capas; `main.dart` y los composition roots conectan implementaciones concretas. La ficha conserva el `SpikePlayerModule` y el único motor media_kit/libmpv. El runtime de proveedores registra el adaptador de catálogo Miruro y el normalizador genérico de fuentes directas; los proveedores de anime anteriores fueron retirados. Miruro respondió HTTP 403 a consultas públicas ordinarias antes de episodios o media, por lo que no se acredita reproducción externa. Wikimedia sigue opt-in para su título documentado y el progreso todavía no está integrado con el player. Ver [`data/player/providers`](data/player/providers/README.md) y la [auditoría de migración](../../docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md).

| Carpeta | Responsabilidad | Guía |
|---|---|---|
| `app/` | Widgets, presentación y composition roots Flutter/Linux | [`app/README.md`](app/README.md) |
| `application/` | Casos de uso y coordinación sin widgets ni motor multimedia directo | [`application/README.md`](application/README.md) |
| `core/` | Errores, resultados y utilidades transversales | [`core/README.md`](core/README.md) |
| `data/` | Persistencia y adaptadores de servicios externos | [`data/README.md`](data/README.md) |
| `domain/` | Modelos, políticas y contratos neutrales | [`domain/README.md`](domain/README.md) |
| `settings/` | Registro y almacenamiento de ajustes | [`settings/README.md`](settings/README.md) |

Las dependencias deben apuntar hacia contratos/domain; los composition roots conectan implementaciones. Antes de crear una capa o carpeta, revisar la guía de arquitectura del repositorio. Los tests viven bajo `app/test/`; para análisis: `dart analyze lib test` desde `app/`.
