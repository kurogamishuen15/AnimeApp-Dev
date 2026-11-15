# Dominio de subtítulos

Contratos y políticas neutrales al proveedor para pistas, estilos y subtítulos externos. No realiza solicitudes, almacenamiento ni comandos mpv.

| Archivo | Responsabilidad |
|---|---|
| `subtitle_track_info.dart` | Identidad de pista de sesión, idioma, tipo y metadatos opcionales |
| `subtitle_style.dart` | Valores de estilo con rangos validados |
| `hardsub_policy.dart` | Estado hardsub y decisión para carga externa |
| `external_subtitle_catalog.dart` | Query limitada, candidatos, errores, resultado y puertos de catálogo/loader |

Application coordina estos contratos; `data/opensubtitles` implementa catálogo y el engine implementa carga. Los IDs nativos son efímeros por fuente. Al agregar un campo o formato, declarar su semántica y cubrir disponibilidad/fallo antes de adaptar capas externas. Tests: `flutter test --no-pub test/domain/external_subtitle_catalog_test.dart test/domain/subtitle_policy_test.dart`.
