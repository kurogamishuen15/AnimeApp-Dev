# AnimeApp

Repositorio privado de desarrollo de AnimeApp y de su infraestructura de coordinación, memoria y verificación de IA. El estado confirmado de cada componente se registra en la documentación; la existencia de planificación no implica que una función esté implementada.

## Orientación para colaboradores y agentes

- Empezar en [AGENTS.md](AGENTS.md) y [docs/memory/PROJECT_STATE.md](docs/memory/PROJECT_STATE.md).
- Consultar [CONTRIBUTING.md](CONTRIBUTING.md) para ramas, revisión y Conventional Commits.
- Consultar [RELEASING.md](RELEASING.md) para el proceso futuro de aprobación y publicación pública.
- La memoria técnica y el traspaso entre sesiones están en [docs/memory/README.md](docs/memory/README.md) y [docs/memory/AI_HANDOFF.md](docs/memory/AI_HANDOFF.md).

La aplicación Flutter está prevista en `app/`. No inicializarla ni instalar dependencias hasta que la subfase correspondiente esté autorizada.

```bash
python3 tools/ai/memory.py search "SQLite memoria" --max-chars 4000
python3 tools/ai/memory.py handoff --max-chars 6000
python3 -m unittest discover -s tests/ai -v
python3 tools/ai/evaluate.py
```

Comenzar en [AGENTS.md](AGENTS.md), [guía del entorno](docs/ai-system/README.md) y [estado/informe final](docs/ai-system/FINAL_REPORT.md). Python 3.11+ con SQLite FTS5; memoria sin suscripciones ni procesos residentes. Hay 11 perfiles especializados de Codex y documentación portable para otras IA.

El ejecutor nocturno es experimental y se bloquea sin imagen, proveedor y pruebas reales de aislamiento. No confundir los tests con una certificación de operación desatendida. No se habilitan servicios, arranque automático ni push.

Antes de publicar este proyecto debe decidirse una licencia. No se impone una licencia de producto durante esta misión de entorno.
