# Prueba real de delegación QA

Fecha: 2026-11-07 (America/Bogota).
Estado: evidencia de delegación real durante la sesión; no ejecución nocturna.

## Alcance e instrucciones verificadas

Se leyeron `AGENTS.md`, `docs/memory/PROJECT_STATE.md`,
`docs/memory/ARCHITECTURE_INDEX.md`, la decisión AI-001 y
`.codex/agents/qa.toml`. El encargo asignó propiedad exclusiva sobre este archivo,
prohibió subdelegar y dejó al coordinador la memoria canónica y Git. No se usaron
Git, contenedores ni credenciales. No se modificó configuración existente;
`ls -l docs/ai-system/DELEGATION_PROBE.md` confirmó que este archivo no existía
(salida 2) antes de crearlo. La comprobación Git y el cierre canónico corresponden
al coordinador por la separación explícita del encargo.

## Recuperación de memoria

Comandos ejecutados con salida 0:

- `python3 tools/ai/memory.py search 'SQLite FTS5' --max-chars 1800`
- `python3 tools/ai/memory.py handoff --max-chars 1800`

La búsqueda recuperó `docs/memory/decisions/AI-001-memoria-local.md`
(vigente, fecha 2026-11-07) y `docs/ai-system/MEMORY_ARCHITECTURE.md`
(sin estado declarado en el resultado). El handoff recuperó rutas a
`PROJECT_STATE.md`, `AI_HANDOFF.md`, `KNOWN_ISSUES.md`, `ARCHITECTURE_INDEX.md`,
`MODULE_INDEX.md`, `DECISIONS.md` dentro de `docs/memory/`, además de
`docs/ai-system/AGENT_REGISTRY.md`, `AUTONOMY_POLICY.md` y `ENVIRONMENT_AUDIT.md`.
Sus fragmentos estaban truncados: recuperar una ruta no equivale a leerla entera.

## Consulta técnica y fuente primaria

Se consultó mediante navegación la documentación oficial,
[SQLite FTS5, sección Unicode61 Tokenizer](https://www.sqlite.org/fts5.html#unicode61_tokenizer).
`unicode61` elimina por defecto diacríticos latinos y distingue las opciones
`remove_diacritics 0`, `1` y `2`. El valor predeterminado `1` conserva una
excepción histórica para ciertos caracteres con varios diacríticos en un único
punto de código, como U+1ED9. El valor `2` también normaliza ese caso; `0`
desactiva la eliminación. Esto documenta el tokenizador y no adopta una nueva
decisión del proyecto.

## Validación y límites

Se valida la presencia de la fuente, instrucciones, rutas recuperadas, tokens
técnicos y declaración de alcance mediante un script Python con aserciones.
Se ejecuta `python3 tools/ai/memory.py index` para reconstruir el índice derivado.
Resultado del script: salida 0, `PASS: 10 tokens, fuente primaria y alcance`.
Resultado de indexación: salida 0, 27 documentos y 92 fragmentos.
Los resultados efectivos se reportan al coordinador. No se ejecutaron pruebas
de producto, proveedor ni aislamiento nocturno; esta prueba no los acredita.
