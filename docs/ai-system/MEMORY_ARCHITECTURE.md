# Arquitectura de memoria persistente

## Capas y fuentes

| Capa | Fuente canónica | Actualización |
| --- | --- | --- |
| Operativa | `docs/memory/PROJECT_STATE.md` | Al iniciar, tras un hito y al finalizar. Objetivo, alcance, archivos, validación, siguiente paso. |
| Arquitectónica | `ARCHITECTURE_INDEX.md`, `MODULE_INDEX.md`, `DECISIONS.md`, `decisions/` | Al cambiar contratos o adoptar una decisión, con evidencia. |
| Episódica | `sessions/`, `LESSONS_LEARNED.md`, `KNOWN_ISSUES.md` | Intento, resultado, causa, solución, comprobación y commit si existe. |
| Investigación | `RESEARCH_INDEX.md`, `research/` | Resumen verificable, versión, fuente, fecha, limitaciones y licencia cuando corresponda. |
| Transferencia | `AI_HANDOFF.md` y comando `handoff` | Estado compacto y enlaces para otro agente. |

No hay arquitectura de producto disponible en esta carpeta. Los índices describen la infraestructura comprobada y declaran el límite. Si en una misión posterior aparece documentación canónica de AnimeApp, enlazarla; no duplicarla ni importarla desde carpetas excluidas.

## Recuperación

1. Leer `AGENTS.md` y el estado operativo.
2. Identificar intención y consultar índice relevante.
3. Ejecutar `memory.py search "términos concretos" --limit 5 --max-chars 4000` o `rg -n` sobre la carpeta pertinente.
4. Abrir únicamente el fragmento y su fuente. Verificar fecha, estado y evidencia frente al código disponible.
5. Investigar fuentes oficiales si el conocimiento falta o cambió.
6. Trabajar, verificar, actualizar solo memoria afectada y ejecutar `check`.

SQLite FTS5 usa BM25 y términos normalizados sin acentos. Se indexan únicamente Markdown de `docs/ai-system`, `docs/memory`, `docs/architecture` y `docs/perf` si existen. Cada fragmento incluye ruta, línea, hash y mtime; se reconstruye transaccionalmente al buscar para reflejar cambios y borrados. Esto lee el corpus documental acotado, no todo el repositorio. La salida está limitada en caracteres, incluidos metadatos; `truncated` señala extractos parciales. La base `.ai-local/memory.sqlite3` es derivada, no fuente de verdad.

`handoff` prioriza estado, traspaso, problemas, arquitectura, módulos y decisiones y reparte el presupuesto entre fuentes. Un resultado truncado exige abrir las referencias necesarias. No equivale a resumir semánticamente todo el proyecto.

## Calidad

Los registros de `docs/memory` usan líneas `Fuente:`, `Fecha: YYYY-MM-DD`, `Módulo:`, `Estado:`, `Decisión:` y `Evidencia:`. Una investigación usa `Tipo: investigación` y estado `pendiente` o `verificada`; una decisión confirmada es un registro separado con `Tipo: decisión`. No aprobar automáticamente hipótesis.

El linter detecta metadata ausente, fecha inválida/futura, enlaces locales inexistentes o fuera del proyecto, documentos marcados obsoletos y conflictos de declaraciones `Claim: clave = valor`. No detecta todas las contradicciones de lenguaje natural; la auditoría humana/IA sigue siendo necesaria. Los documentos obsoletos se excluyen de búsqueda normal y se conservan con enlace a su reemplazo cuando aportan historia.

Para invalidar una decisión: marcar la anterior obsoleta, añadir reemplazo y actualizar el índice. No reescribir episodios históricos como si nunca hubieran ocurrido. No guardar secretos, páginas enteras, datos personales ni volcar conversaciones.

## Opciones evaluadas

`rg` es respaldo transparente y no requiere índice. FTS5 añade ranking y fragmentos con metadatos sin procesos persistentes. Embeddings locales, base vectorial y MCP de memoria se posponen: no se ha demostrado una mejora sobre este corpus pequeño y añadirían dependencias, RAM y mantenimiento. Reabrir la decisión únicamente si la evaluación muestra fallos de recuperación semántica persistentes.

Fuente técnica: [SQLite FTS5](https://www.sqlite.org/fts5.html). Pruebas, tiempos y contexto aproximado en `EVALUATION.md`. Para reconstruir basta volver a ejecutar `index`; no borrar respaldos ni registros de `.ai-local` para ello.
