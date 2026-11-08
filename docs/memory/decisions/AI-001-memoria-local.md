# AI-001 — Memoria textual y FTS5

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
Módulo: memoria
Estado: vigente
Decisión: AI-001
Evidencia: SQLite FTS5 funcional y evaluación de recuperación

Tipo: decisión
Claim: memory.backend = markdown-sqlite-fts5

## Motivo de la tecnología elegida
Markdown permite a otras IA y personas leer fuentes sin herramientas exclusivas. Python con SQLite FTS5 aporta ranking BM25, búsqueda por acentos normalizados y fragmentos verificables, sin red, dependencias externas ni servidor. rg permanece como respaldo.

## Alternativas y consecuencias
Una base vectorial y embeddings locales consumirían recursos adicionales sin ventaja medida en este corpus pequeño. No se instala un modelo semántico. La búsqueda léxica puede fallar con sinónimos: primero mejorar términos/índices y medir; solo prototipar semántica si persiste un fallo relevante.

## Compatibilidad y mantenimiento
Python 3.11+ con FTS5; índice derivado reconstruible y registros Markdown versionables. Verificación: tests y tools/ai/evaluate.py. No es una decisión sobre la base de datos de AnimeApp.
