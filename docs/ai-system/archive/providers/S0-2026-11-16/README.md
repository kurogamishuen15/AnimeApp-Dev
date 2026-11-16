# Archivo histórico de módulos de reproducción S0

Estos documentos fueron movidos fuera de los directorios de runtime para que no
parezcan módulos activos. Describen intentos previos y conservan su contexto;
las auditorías enlazadas son la fuente de estado vigente. El runtime actual no
registra providers ni resolutores externos hasta que un flujo nuevo pase las
pruebas de contrato y playback.

| Intento | Documento archivado | Evidencia canónica |
|---|---|---|
| AnimeHeaven | [README histórico](animeheaven/README.md) | [auditoría S0-R](../../../audits/S0R-ANIMEHEAVEN-audit-2026-11-16.md), [reporte S0](../../../missions/S0-REAL-PLAYBACK-REPORT.md) |
| AnimeAV1 | [README histórico](animeav1/README.md) | [auditoría de limpieza S0](../../../audits/S0-provider-cleanup-audit-2026-11-15.md) |
| TioAnime | [README histórico](tioanime/README.md) | [auditoría de hosts](../../../audits/S0-video-host-audit-2026-11-15.md) |
| AnimeGG | [README histórico](animegg/README.md) | [auditoría de hosts](../../../audits/S0-video-host-audit-2026-11-15.md) |
| Miruro | [README histórico](miruro/README.md) | [auditoría de limpieza posterior](../../../audits/S0-provider-cleanup-followup-audit-2026-11-15.md) |
| AnimeOnline Ninja | [README histórico](animeonline_ninja/README.md) | [reporte S0](../../../missions/S0-REAL-PLAYBACK-REPORT.md) |
| Resolutores compartidos previos | [README histórico](video_hosts/README.md) | [auditoría de hosts](../../../audits/S0-video-host-audit-2026-11-15.md) |

Los adaptadores/resolutores retirados no se conservan como código ejecutable.
Las pruebas genéricas del manager, contratos, selección/fallback y player
permanecen en sus rutas activas.
