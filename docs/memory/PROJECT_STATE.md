# Estado operativo

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: núcleo y arquitectura del producto
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: `PROGRESS.md`, F1.1/F1.2 y sesión enlazados abajo

## Objetivo y alcance
**Regla permanente del usuario:** inspeccionar, leer, buscar y trabajar únicamente en la raíz de este proyecto y sus subcarpetas. No listar ni consultar Imágenes, Documentos, Descargas, el directorio padre, otras carpetas, el hogar ni unidades externas. No seguir symlinks fuera de la raíz. Si falta un archivo externo, detenerse y pedir que lo coloquen aquí.

Preparar memoria, coordinación y ejecución segura únicamente en esta carpeta de Vídeos. El proyecto ya contiene un esqueleto Flutter Linux (F0.4), comprobaciones de calidad (F0.5) y una primera medición release (F0.6); no hay reproductor ni funciones de catálogo.

## Estado
Infraestructura de coordinación, memoria Markdown/FTS5 y evaluación documentadas. F0.2 completada: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, rama activa `main`, antigua `ai/setup-autonomous-environment` conservada, `origin` privado verificado y clonación limpia comprobada. F0.1 y F0.3 completas. F0.4–F0.6 parciales: `flutter analyze` falla por regresión LSP en ruta no ASCII; Spectacle verificó visualmente la ventana Wayland (evidencia `docs/perf/wayland-window-20261108.png`); tres muestras release en 7.5 GiB dieron 462 ms al frame rasterizado, RSS 140096 KiB frame/145284 KiB a 5 s y CPU reposo 0.60%. La latencia de ventana no está medida y falta validar en objetivo 4 GB. Ver [PROGRESS.md](../../PROGRESS.md), [F0.1 Fedora](../environment/F0.1-FEDORA.md) y [sesión F0.1–F0.6](sessions/2026-11-08-f0-3-f0-6.md). No hay reproductor. `AnimeApp-Dev` es privado; `AnimeApp` es público y permanece vacío. Los informes ENVIRONMENT_AUDIT.md y MCP_RESEARCH.md son internos y se excluyen de toda publicación pública salvo aprobación de una versión revisada. Runner aislado sigue sin acreditación de modo nocturno; requiere proveedor y aislamiento reales. Resultados de la infraestructura en [FINAL_REPORT.md](../ai-system/FINAL_REPORT.md).

F1.1 está preparada para aprobación formal: 17 FR y 12 NFR en baseline, con FR-12/NFR-12 como candidatos excluidos; se añadieron seis requisitos MVP que faltaban en la primera versión. F1.2 se concilió con la lista exacta de 14 decisiones de la sección 3 transcrita por el propietario en conversación; el DOCX no está en la raíz, pero ya no es necesario. ADR-001/002 conservan aprobación local previa; las decisiones 3–14 no se marcan formalmente aprobadas. Trece análisis anteriores se preservaron como ADR adicionales. No se implementó producto ni se agregaron dependencias. F0.4–F0.6 permanecen parciales. Ver [sesión de conciliación](sessions/2026-11-08-f1-1-f1-2-reconciliation.md).

## Archivos y comprobaciones
Herramientas en tools/ai, pruebas en tests/ai, políticas en docs/ai-system. Ejecutar index, check y unittest; las métricas de recuperación se registran con evaluate.py.

## Siguiente paso
Esperar aprobación formal de F1.1 y decisiones tecnológicas que requieran al propietario antes de integrar dependencias. No iniciar F1.3 en esta tarea. F0.4/F0.5 siguen parciales por `flutter analyze`; F0.6 sigue parcial hasta la prueba en 4 GB y cargas de reproducción/fugas. La conciliación no cambia la evidencia ni el estado de F0.

## Restricciones
Un especialista a la vez en sesiones nuevas; no rebajar el modelo para ahorrar tokens. Sin push, sin servicios residentes ni secretos. Ante aprobación necesaria, continuar tareas independientes y registrar bloqueo.
