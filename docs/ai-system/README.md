# Entorno IA de AnimeApp

Infraestructura portable de memoria, coordinación y verificación. El alcance es esta carpeta; aquí todavía no hay código de producto. Python 3.11+ con SQLite FTS5 y Git bastan para memoria y pruebas. No hay dependencias Python externas, suscripciones nuevas ni demonios de indexación.

## Inicio

Desde la raíz del proyecto:

```bash
python3 tools/ai/memory.py index
python3 tools/ai/memory.py search "decisión memoria SQLite" --max-chars 4000
python3 tools/ai/memory.py check
python3 tools/ai/memory.py handoff --max-chars 6000
python3 -W error::ResourceWarning -m unittest discover -s tests/ai -v
python3 tools/ai/autonomy.py doctor
```

## Documentación

| Documento | Uso |
| --- | --- |
| [ENVIRONMENT_AUDIT.md](ENVIRONMENT_AUDIT.md) | Inventario inicial y riesgos. |
| [MEMORY_ARCHITECTURE.md](MEMORY_ARCHITECTURE.md) | Fuentes canónicas y recuperación. |
| [AGENT_REGISTRY.md](AGENT_REGISTRY.md) | Selección automática y responsabilidades. |
| [Protocolo KONGROO](../../.agents/skills/kongroo-deep-audit/SKILL.md) | Auditoría profunda obligatoria y puerta de calidad para todo el repositorio. |
| [Auditorías](audits/) | Informes de revisión por fase, evidencia y recomendación. |
| [MCP_REGISTRY.md](MCP_REGISTRY.md) | Integraciones seleccionadas y descartadas. |
| [TOKEN_POLICY.md](TOKEN_POLICY.md) | Presupuestos, métricas y comparación. |
| [AUTONOMY_POLICY.md](AUTONOMY_POLICY.md) | Autorizaciones, aislamiento y límites. |
| [RUNBOOK.md](RUNBOOK.md) | Operación, fallos y recuperación. |
| [PORTABILITY.md](PORTABILITY.md) | Continuidad con Claude, OpenCode y otras IA. |
| [EVALUATION.md](EVALUATION.md) | Resultados reproducibles. |
| [FINAL_REPORT.md](FINAL_REPORT.md) | Entrega y pendientes reales. |

## Mantenimiento

Actualizar fuentes Markdown al terminar una tarea, ejecutar `check`, repetir la evaluación si cambia el índice y revalidar versiones antes de modificar configuración. `.ai-local` contiene índices reconstruibles, respaldos y registros privados: no versionarlo. La memoria no convierte al modelo en un servicio residente ni garantiza supervivencia a un reinicio.
