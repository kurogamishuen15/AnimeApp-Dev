# Adaptadores de reproducción

Esta carpeta agrupa integraciones de datos del reproductor; la coordinación vive en `application/player`, y los contratos neutrales en `domain/player`.

| Submódulo | Responsabilidad | Guía |
|---|---|---|
| `engine/` | Adaptador actual media_kit/libmpv, lease, pistas, subtítulos y métricas nativas | [`engine/README.md`](engine/README.md) |
| `providers/` | Adaptadores públicos AnimeAV1/TioAnime, composition root y mock de pruebas | [`providers/README.md`](providers/README.md) |

Los adaptadores se inyectan desde el composition root. Añadir una integración sin hacer que widgets o dominio conozcan la dependencia concreta; cubrirla con contract tests y pruebas del motor/proveedor.
