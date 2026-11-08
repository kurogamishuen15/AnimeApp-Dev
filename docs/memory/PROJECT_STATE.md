# Estado operativo

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Auditoría local y pruebas en EVALUATION.md

## Objetivo y alcance
**Regla permanente del usuario:** inspeccionar, leer, buscar y trabajar únicamente en la raíz de este proyecto y sus subcarpetas. No listar ni consultar Imágenes, Documentos, Descargas, el directorio padre, otras carpetas, el hogar ni unidades externas. No seguir symlinks fuera de la raíz. Si falta un archivo externo, detenerse y pedir que lo coloquen aquí.

Preparar memoria, coordinación y ejecución segura únicamente en esta carpeta de Vídeos. El proyecto ya contiene un esqueleto Flutter Linux (F0.4), comprobaciones de calidad (F0.5) y una primera medición release (F0.6); no hay reproductor ni funciones de catálogo.

## Estado
Infraestructura de coordinación, memoria Markdown/FTS5 y evaluación documentadas. F0.2 completada: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, rama activa `main`, antigua `ai/setup-autonomous-environment` conservada, `origin` privado verificado y clonación limpia comprobada. F0.1 y F0.3 están completas. F0.4–F0.6 parciales: scaffold Linux compila y mide primer frame; Flutter analyze falla con regresión LSP en ruta no ASCII; ventana no observable por Wayland; medición: 462 ms al primer frame, RSS frame 140096 KiB, RSS reposo 145284 KiB, CPU reposo 0.60%. Ver [PROGRESS.md](../../PROGRESS.md), [F0.1 Fedora](../environment/F0.1-FEDORA.md) y [sesión F0.1–F0.6](sessions/2026-11-08-f0-3-f0-6.md). El rendimiento en el objetivo de 4 GB sigue pendiente. `AnimeApp-Dev` es privado; `AnimeApp` es público y permanece vacío. Los informes ENVIRONMENT_AUDIT.md y MCP_RESEARCH.md son internos y se excluyen de toda publicación pública salvo aprobación de una versión revisada. Runner aislado sigue sin acreditación de modo nocturno; requiere proveedor y aislamiento reales. Resultados de la infraestructura en [FINAL_REPORT.md](../ai-system/FINAL_REPORT.md).

## Archivos y comprobaciones
Herramientas en tools/ai, pruebas en tests/ai, políticas en docs/ai-system. Ejecutar index, check y unittest; las métricas de recuperación se registran con evaluate.py.

## Siguiente paso
F0.1–F0.6 se trabajaron según el plan original; F0.1/F0.3 están completas y F0.4/F0.5/F0.6 conservan pendientes documentados. D3/LICENCIA sigue pendiente sin bloquear F0.3. Resolver el error del analysis server con un Flutter corregido, verificar una ventana en una sesión observable y repetir rendimiento en el equipo objetivo antes de cerrar subfases parciales; no inferir que el tiempo de ventana es cero. No iniciar Fase 1 todavía.

## Restricciones
Un especialista a la vez en sesiones nuevas; no rebajar el modelo para ahorrar tokens. Sin push, sin servicios residentes ni secretos. Ante aprobación necesaria, continuar tareas independientes y registrar bloqueo.
