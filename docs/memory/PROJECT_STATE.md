# Estado operativo

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Auditoría local y pruebas en EVALUATION.md

## Objetivo y alcance
**Regla permanente del usuario:** inspeccionar, leer, buscar y trabajar únicamente en la raíz de este proyecto y sus subcarpetas. No listar ni consultar Imágenes, Documentos, Descargas, el directorio padre, otras carpetas, el hogar ni unidades externas. No seguir symlinks fuera de la raíz. Si falta un archivo externo, detenerse y pedir que lo coloquen aquí.

Preparar memoria, coordinación y ejecución segura únicamente en esta carpeta de Vídeos. No modificar funcionalidades de AnimeApp ni acceder a otro repositorio. Aquí no hay código Flutter de producto.

## Estado
Infraestructura de coordinación, memoria Markdown/FTS5 y evaluación documentadas. F0.2: archivos revisados y primer índice Git preparado con rutas explícitas; identidad local configurada con autorización del usuario. Sin commit, cambio de rama ni remoto. No declarar F0.2 completada hasta la aprobación del primer commit y los criterios verificables. Los informes ENVIRONMENT_AUDIT.md y MCP_RESEARCH.md son internos y se excluyen de toda publicación pública salvo aprobación de una versión revisada. Runner aislado sigue sin acreditación de modo nocturno; requiere proveedor y aislamiento reales. Resultados de la infraestructura en [FINAL_REPORT.md](../ai-system/FINAL_REPORT.md).

## Archivos y comprobaciones
Herramientas en tools/ai, pruebas en tests/ai, políticas en docs/ai-system. Ejecutar index, check y unittest; las métricas de recuperación se registran con evaluate.py.

## Siguiente paso
Esperar revisión y autorización explícita del usuario antes del primer commit `chore(repo): preparar base inicial de desarrollo (F0.2)`. La rama actual `ai/setup-autonomous-environment` se conserva; no cambiar a `main` en esta etapa. No hay remotos. F0.1 (entorno Fedora) sigue pendiente; no inicializar Flutter ni instalar dependencias por esta subfase.

## Restricciones
Un especialista a la vez en sesiones nuevas; no rebajar el modelo para ahorrar tokens. Sin push, sin servicios residentes ni secretos. Ante aprobación necesaria, continuar tareas independientes y registrar bloqueo.
