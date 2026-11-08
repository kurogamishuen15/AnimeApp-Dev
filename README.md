# AnimeApp

AnimeApp es un proyecto multiplataforma para explorar, organizar y reproducir anime. El desarrollo empieza en Fedora Linux. La aplicación Flutter se está preparando; no se debe confundir el plan con funciones ya implementadas.

## Documentación principal del proyecto

| Documento | Propósito |
| --- | --- |
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | Objetivos, alcance MVP, fases y criterios generales. |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Capas, límites de módulos y adaptadores previstos. |
| [ROADMAP.md](ROADMAP.md) | Orden y dependencias de fases/subfases. |
| [PROGRESS.md](PROGRESS.md) | Estado real, evidencia y pendientes por subfase. |
| [TECH_DECISIONS.md](TECH_DECISIONS.md) | Decisiones aprobadas, propuestas y cuestiones abiertas. |
| [CHANGELOG.md](CHANGELOG.md) | Cambios por subfase y versión. |
| [TESTING.md](TESTING.md) | Comandos y alcance de las pruebas disponibles y previstas. |
| [Decisión D3 sobre LICENSE](TECH_DECISIONS.md#licencia-del-proyecto) | Archivo legal adicional, pendiente de elección del propietario. |

La documentación requerida de F0.3 consta de README más los otros siete documentos Markdown de la tabla; todos están creados y enlazados. `LICENSE` es un archivo adicional previsto, sujeto a D3, y su decisión pendiente no bloquea F0.3. No se inventa un archivo legal.

## Contribuir y publicar

- [AGENTS.md](AGENTS.md) es el punto de entrada para agentes.
- [CONTRIBUTING.md](CONTRIBUTING.md) explica ramas, Conventional Commits y revisión.
- [RELEASING.md](RELEASING.md) describe la publicación futura y la selección explícita de archivos.
- [CHANGELOG.md](CHANGELOG.md) registra los cambios y [TESTING.md](TESTING.md) contiene las instrucciones de prueba.
- El estado vigente para continuar es [docs/memory/PROJECT_STATE.md](docs/memory/PROJECT_STATE.md) y [docs/memory/AI_HANDOFF.md](docs/memory/AI_HANDOFF.md).

AnimeApp-Dev es el repositorio privado de trabajo. AnimeApp es el repositorio público, actualmente vacío. No se publican automáticamente el historial ni los documentos internos.

## Instalar, ejecutar y probar

El esqueleto Linux está en `app/`; su instalación y pruebas están descritas en [TESTING.md](TESTING.md) y [app/README.md](app/README.md). No instalar paquetes del sistema ni modificar configuraciones globales sin autorización. El estado real de cada comprobación está en `PROGRESS.md`.

La infraestructura de IA existente usa Python estándar y SQLite FTS5. Desde la raíz:

```bash
python3 tools/ai/memory.py search "SQLite memoria" --max-chars 4000
python3 tools/ai/memory.py handoff --max-chars 6000
python3 -m unittest discover -s tests/ai -v
python3 tools/ai/evaluate.py
```

Para la memoria técnica de IA, consulta [docs/ai-system/README.md](docs/ai-system/README.md) y [docs/ai-system/FINAL_REPORT.md](docs/ai-system/FINAL_REPORT.md). El proyecto conserva once perfiles especializados y documentación para continuidad entre IA.

El ejecutor nocturno es experimental y se bloquea sin imagen, proveedor y pruebas reales de aislamiento. No confundir los tests con una certificación de operación desatendida. No se habilitan servicios, arranque automático ni push.

La licencia del proyecto y las licencias de dependencias deben revisarse antes de distribuir código o binarios.
