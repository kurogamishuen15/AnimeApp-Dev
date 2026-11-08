# Herramientas IA

Python 3.11+ con biblioteca estándar; SQLite debe incluir FTS5. Ejecutar desde la raíz. No hay instalación pip ni servicios residentes.

- `memory.py`: indexar documentación autorizada, recuperar fragmentos, comprobar registros y preparar traspaso. Límites: 256 KiB/documento, 4 MiB/corpus, 500 documentos; metadata al inicio (primeros 16 KiB). Si se exceden, informa error; no omite evidencia silenciosamente.
- `autonomy.py`: doctor, plan, run. No ejecuta en el anfitrión como alternativa a Podman. Leer AUTONOMY_POLICY y RUNBOOK antes de usar.
- `evaluate.py`: medición reproducible de recuperación y pruebas integrales inocuas. No llama a un modelo ni simula una certificación de ejecución nocturna.

```bash
python3 tools/ai/memory.py --help
python3 tools/ai/memory.py search "SQLite memoria" --limit 5 --max-chars 4000
python3 tools/ai/memory.py check --as-of 2026-11-07
python3 tools/ai/memory.py handoff --max-chars 6000
python3 tools/ai/autonomy.py --help
```

Después de cambios: ejecutar unittest y evaluate, revisar diff y actualizar docs. Los datos de ejecución se guardan en .ai-local/, ignorado por Git. No eliminar respaldos al reconstruir el índice. Retirar herramientas solo tras verificar referencias y conservar la memoria Markdown.
