# Adaptadores de reproducción

Esta carpeta agrupa integraciones de datos del reproductor; la coordinación vive en `application/player`, y los contratos neutrales en `domain/player`.

| Submódulo | Responsabilidad | Guía |
|---|---|---|
| `engine/` | Adaptador actual media_kit/libmpv, lease, pistas, subtítulos y métricas nativas | [`engine/README.md`](engine/README.md) |
| `providers/` | Provider AnimeHeaven, resolver MP4 separado, manager, mocks e historial de adapters retirados | [`providers/README.md`](providers/README.md) |

El composition root registra AnimeHeaven y su resolver sin dar a widgets o dominio conocimiento de Dio o del host. Hay un provider implementado, pero reproducción externa sigue sin confirmarse; ver el README del submódulo y el estado S0.
