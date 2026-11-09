# Estado operativo

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: núcleo y arquitectura del producto
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: `PROGRESS.md`, F1.1–F1.3 y sesiones enlazadas abajo

## Objetivo y alcance
**Regla permanente del usuario:** inspeccionar, leer, buscar y trabajar únicamente en la raíz de este proyecto y sus subcarpetas. No listar ni consultar Imágenes, Documentos, Descargas, el directorio padre, otras carpetas, el hogar ni unidades externas. No seguir symlinks fuera de la raíz. Si falta un archivo externo, detenerse y pedir que lo coloquen aquí.

Preparar memoria, coordinación y ejecución segura únicamente en esta carpeta de Vídeos. La autorización posterior del propietario habilitó documentación de requisitos/arquitectura F1.1/F1.2, no funcionalidades. El proyecto contiene un esqueleto Flutter Linux (F0.4), comprobaciones de calidad (F0.5) y primera medición release (F0.6); no hay reproductor ni funciones de catálogo.

## Estado
Infraestructura de coordinación, memoria Markdown/FTS5 y evaluación documentadas. F0.2 completada: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, rama activa `main`, antigua `ai/setup-autonomous-environment` conservada, `origin` privado verificado y clonación limpia comprobada. F0.1 y F0.3 completas. F0.4–F0.6 parciales: `flutter analyze` falla por regresión LSP en ruta no ASCII; Spectacle verificó visualmente la ventana Wayland (evidencia `docs/perf/wayland-window-20261108.png`); tres muestras release en 7.5 GiB dieron 462 ms al frame rasterizado, RSS 140096 KiB frame/145284 KiB a 5 s y CPU reposo 0.60%. La latencia de ventana no está medida y falta validar en objetivo 4 GB. Ver [PROGRESS.md](../../PROGRESS.md), [F0.1 Fedora](../environment/F0.1-FEDORA.md) y [sesión F0.1–F0.6](sessions/2026-11-08-f0-3-f0-6.md). No hay reproductor. `AnimeApp-Dev` es privado; `AnimeApp` es público y permanece vacío. Los informes ENVIRONMENT_AUDIT.md y MCP_RESEARCH.md son internos y se excluyen de toda publicación pública salvo aprobación de una versión revisada. Runner aislado sigue sin acreditación de modo nocturno; requiere proveedor y aislamiento reales. Resultados de la infraestructura en [FINAL_REPORT.md](../ai-system/FINAL_REPORT.md).

F1.1 fue aprobada formalmente el 2026-11-08: baseline final 18 FR + 13 NFR, con FR-11 acotado y su definición de negocio por campo pendiente; objetivos de rendimiento son preliminares. F1.2: el propietario aprobó las 14 selecciones del plan como arquitectura de referencia, con validaciones de integración pendientes. ADR adicionales no aprobados automáticamente. F1.3 fue aprobada y completada documentalmente el 2026-11-08: núcleo Dart compartido, Fedora/Linux primero y adaptadores progresivos por necesidad real. Arquitectura, diagramas y propuesta F1.4 en [ARCHITECTURE.md](../../ARCHITECTURE.md); decisión en [ADR-015](../adr/ADR-015-arquitectura-core-linux-first.md) y registro de sesión [F1.3](sessions/2026-11-08-f1-3-architecture.md). No se implementó producto ni se agregaron dependencias. F0.4–F0.6 permanecen parciales.

## Archivos y comprobaciones
Herramientas en tools/ai, pruebas en tests/ai, políticas en docs/ai-system. Ejecutar index, check y unittest; las métricas de recuperación se registran con evaluate.py.

## Siguiente paso
F1.1/F1.2 están cerradas documentalmente; validaciones técnicas se ejecutan únicamente en su fase. F1.1–F1.3 están cerradas documentalmente; F1.4 es el siguiente paso planificado y aún no se había iniciado. F0.4/F0.5 siguen parciales por `flutter analyze`; F0.6 sigue parcial hasta la prueba en 4 GB y cargas de reproducción/fugas. La aprobación no cambia la evidencia ni el estado de F0.

## Restricciones
Un especialista a la vez en sesiones nuevas; no rebajar el modelo para ahorrar tokens. Sin push, sin servicios residentes ni secretos. Ante aprobación necesaria, continuar tareas independientes y registrar bloqueo.
