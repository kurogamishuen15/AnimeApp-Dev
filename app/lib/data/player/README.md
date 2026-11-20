# Adaptadores de reproducción

Esta carpeta agrupa integraciones de datos del reproductor; la coordinación vive en `application/player`, y los contratos neutrales en `domain/player`.

| Submódulo | Responsabilidad | Guía |
|---|---|---|
| `engine/` | Adaptador actual media_kit/libmpv, lease, pistas, subtítulos y métricas nativas | [`engine/README.md`](engine/README.md) |
| `providers/` | Composition root: Miruro catalog adapter, Wikimedia opt-in, fuentes de usuario y normalizador `direct-media` | [`providers/README.md`](providers/README.md) |

El engine media_kit/libmpv permanece único y protegido. El runtime registra
Miruro como adaptador del catálogo público, pero la consulta live devuelve 403
antes de obtener fuentes; no hay reproducción externa de anime confirmada. El
resolver directo normaliza solo candidatos HTTPS de formato conocido y no
comprueba su disponibilidad. Los contratos neutrales están en
`domain/player/providers`; selección/fallback vive en
`application/player/providers`. Ver los README de capa y la
[auditoría de migración](../../../../docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md).
