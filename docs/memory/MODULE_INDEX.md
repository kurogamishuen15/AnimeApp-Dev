# Índice de módulos responsables

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001
Evidencia: Rutas de herramientas y sus tests

| Función | Responsable | Validación |
| --- | --- | --- |
| Inicio y composición Flutter Linux | app/lib/main.dart, app/lib/app/anime_app.dart | tests Flutter; `dart analyze lib test` |
| Identidad independiente del toolkit | app/lib/domain/app_identity.dart | test widget y checker de imports |
| Runner nativo Linux | app/linux | `flutter build linux --release` |
| CI local y límites de imports | scripts/ci.sh, scripts/check_imports.dart | prueba sintética y ejecución CI |
| Medición de rendimiento Linux | scripts/measure.sh | TSV en docs/perf; evidencia de PID y salida completa |
| Entorno base Fedora | docs/environment/F0.1-FEDORA.md | Flutter doctor y pkg-config |
| Recuperar conocimiento y búsquedas | tools/ai/memory.py | tests/ai/test_memory.py |
| Comprobar metadata y conflictos | tools/ai/memory.py check | fixtures con Claim y estado obsoleto |
| Preparar contexto para otra IA | tools/ai/memory.py handoff | prueba de estado y siguiente tarea |
| Ejecutar misión aislada y registrar métricas | tools/ai/autonomy.py | tests/ai/test_autonomy.py |
| Evaluar recuperación y regresiones | tools/ai/evaluate.py | EVALUATION.md y reporte JSON |
| Políticas de coordinación | AGENTS.md y .codex/agents | AGENT_REGISTRY.md |

El módulo responsable de reproducción de anime, catálogo o autenticación del producto se desconoce: no hay código de aplicación en este alcance.
