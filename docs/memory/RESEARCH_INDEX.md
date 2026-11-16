# Índice de investigación

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Informes enlazados; no hipótesis de producto

- [Herramientas MCP verificadas](../ai-system/MCP_RESEARCH.md).
- [Resumen técnico y fuentes](research/2026-11-07-entorno.md).

Registrar versión observada, fecha, limitaciones, licencia si se copia código y prueba realizada. No guardar páginas enteras ni conversaciones. El registro de investigación usa estado verificada, no vigente/aprobada como si fuera una decisión.

- [Auditoría del sistema de proveedores/episodios](../ai-system/audits/PROVIDER-SYSTEM-audit-2026-11-14.md): revisión de Anilili, desktoprepo1, media-index, anime1v-api, contratos locales y límites de autorización; no habilita proveedores.
- [Implementación y verificación de providers](../ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md): adaptación técnica de páginas públicas AnimeAV1/TioAnime, evidencia real libmpv y rutas bloqueadas/no confirmadas.
- [Misión S0: estado real de proveedores](../ai-system/missions/S0-REAL-PLAYBACK-REPORT.md): matriz de 22 candidatos, probes públicos limitados, resoluciones y playback real diferenciados; actualizado con AnimeGG y KickAssAnime el 2026-11-15.
- [Auditoría S0 del 2026-11-15](../ai-system/audits/S0-provider-audit-2026-11-15.md): regresiones de TioAnime/circuit breaker, bloqueos actuales, tests focalizados y criterios de reproducción aún pendientes.
- [Auditoría S0 de hosts de video del 2026-11-15](../ai-system/audits/S0-video-host-audit-2026-11-15.md): separación AnimeProvider/VideoHostResolver/PlaybackEngine, protocolo MP4/HLS, inventario live y evidencia libmpv sin reproducción de video externa.
- [Limpieza de implementaciones S0 del 2026-11-15](../ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md): archivos retirados, contratos y player conservados, referencias comprobadas y validación posterior.
- [Port S0-A de catálogo Miruro desde Anilili](../ai-system/missions/S0-ANILILI-PORT-REPORT.md) y [auditoría](../ai-system/audits/S0-ANILILI-port-audit-2026-11-15.md): commits upstream/licencias, mapping hacia contratos Kongroo, 403 observado en GET ordinario, CI y límites; no confirma playback ni implementa Anivexa.
- [Limpieza posterior a S0-A](../ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md): retiró Miruro del runtime, archivó las fuentes de pruebas y confirmó que los contratos, el manager y el player se mantienen; no confirma playback.
- [S0-R — revisión de referencias y accesibilidad de fuentes, 2026-11-16](../ai-system/missions/S0R-REFERENCE-REVIEW-2026-11-16.md): commits/licencias de Anilili, Aimi, clientes CLI y AniWorld; catálogo AniWorld accesible, cuatro hosters probados sin medio reproducible; no se copió código ni se confirmó proveedor operativo.
- [S0-R — prueba de AnimeHeaven, 2026-11-16](../ai-system/missions/S0-REAL-PLAYBACK-REPORT.md) y [auditoría](../ai-system/audits/S0R-ANIMEHEAVEN-audit-2026-11-16.md): provider implementado con referencia MIT-0; `cx`, `ct` y `ck` llegaron a libmpv y fallaron sin frame; 0/70. La auditoría registra P2 corregidos y evidencia pendiente.
