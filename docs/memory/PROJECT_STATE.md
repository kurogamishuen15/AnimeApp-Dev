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
Infraestructura de coordinación, memoria Markdown/FTS5 y evaluación documentadas. F0.2 completada: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, rama activa `main`, antigua `ai/setup-autonomous-environment` conservada, `origin` privado verificado y clonación limpia comprobada. F0.1 y F0.3 completas. F0.4–F0.6 siguen parciales. La causa de `flutter analyze` quedó confirmada en Flutter 3.47.9: LSP Content-Length contado en caracteres, no bytes UTF-8. El SDK beta 3.50.0-0.4.pre aislado pasa analyze y CI cuando se selecciona explícitamente, pero no se adopta como solución permanente; stable actual sigue fallando. También se corrigió `analysis_options.yaml` y se migró la UI mínima a `material_ui`. Ver [PROGRESS.md](../../PROGRESS.md), [F0.1 Fedora](../environment/F0.1-FEDORA.md), [TESTING.md](../../TESTING.md) y [sesión](sessions/2026-11-08-flutter-analyze-ci-repair.md). No hay reproductor. `AnimeApp-Dev` es privado; `AnimeApp` es público y permanece vacío. Los informes ENVIRONMENT_AUDIT.md y MCP_RESEARCH.md son internos y se excluyen de toda publicación pública salvo aprobación de una versión revisada. Runner aislado sigue sin acreditación de modo nocturno; requiere proveedor y aislamiento reales. Resultados de la infraestructura en [FINAL_REPORT.md](../ai-system/FINAL_REPORT.md).

F1.1 fue aprobada formalmente el 2026-11-08: baseline final 18 FR + 13 NFR, con FR-11 acotado y su definición de negocio por campo pendiente; objetivos de rendimiento son preliminares. F1.2: el propietario aprobó las 14 selecciones del plan como arquitectura de referencia, con validaciones de integración pendientes. ADR adicionales no aprobados automáticamente. F1.3 fue aprobada y completada documentalmente: núcleo Dart compartido, Fedora/Linux primero y adaptadores progresivos por necesidad real. F1.4 se completó el 2026-11-08. F1.6 se completó el 2026-11-09 con Drift schema v2, archivo SQLite real, migración no destructiva v1→v2, conservación de datos, reapertura y rollback; ver [`local_db`](../../app/lib/data/local_db/README.md) y la sesión F1.6. La tabla de progreso solo guarda envelopes y documentos opacos; no decide la semántica pendiente de progreso. F1.7 se completó con Result, errores tipados y logger sanitizado. F1.5 permanece pendiente y es la siguiente subfase; F1.8–F1.12 no iniciadas. F0.4–F0.6 mantienen sus estados parciales; `flutter analyze` estable sigue siendo una limitación observada.

## Archivos y comprobaciones
Herramientas en tools/ai, pruebas en tests/ai, políticas en docs/ai-system. Ejecutar index, check y unittest; las métricas de recuperación se registran con evaluate.py.

## Siguiente paso
F1.1–F1.4 están cerradas documentalmente/por estructura; F1.6 y F1.7 están implementadas y probadas. Próximo: F1.5, catálogo tipado de ajustes, defaults, validación y store conectado a la persistencia. F1.8–F1.12 siguen sin iniciar. F0.4/F0.5 siguen parciales por `flutter analyze` estable; F0.6 sigue parcial hasta la prueba en 4 GB y cargas de reproducción/fugas. F1.4/F1.6 no cambian la evidencia de F0.

## Restricciones
Un especialista a la vez en sesiones nuevas; no rebajar el modelo para ahorrar tokens. Sin push, sin servicios residentes ni secretos. Ante aprobación necesaria, continuar tareas independientes y registrar bloqueo.
