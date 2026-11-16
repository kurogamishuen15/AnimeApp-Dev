# Adaptadores de reproducción

Esta carpeta agrupa integraciones de datos del reproductor; la coordinación vive en `application/player`, y los contratos neutrales en `domain/player`.

| Submódulo | Responsabilidad | Guía |
|---|---|---|
| `engine/` | Adaptador actual media_kit/libmpv, lease, pistas, subtítulos y métricas nativas | [`engine/README.md`](engine/README.md) |
| `providers/` | Composition root: AnimesDigital candidato y normalizador `direct-media` | [`providers/README.md`](providers/README.md) |

El engine media_kit/libmpv permanece único y no se modificó en S0-S. El runtime
registra AnimesDigital como candidato aún no reproducible; el resolver directo
solo normaliza candidates HTTPS que terminan en MP4/HLS/DASH. Los contratos neutrales están en `domain/player/providers`;
la selección/fallback vive en `application/player/providers`. Ver los README de
capa y el [estado S0-S](../../../../docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).
