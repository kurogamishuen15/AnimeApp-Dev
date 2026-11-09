# Índice de módulos responsables

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001
Evidencia: Rutas de herramientas y sus tests

| Función | Responsable | Validación |
| --- | --- | --- |
| Inicio y composición Flutter Linux | app/lib/main.dart, app/lib/app/anime_app.dart; [README](../../app/lib/app/README.md) | tests Flutter; `dart analyze lib test` |
| Resultados, errores tipados y logging sanitizado | app/lib/core; [README](../../app/lib/core/README.md) | tests/core y `dart analyze lib/core test/core` |
| Identidad independiente del toolkit | app/lib/domain/app_identity.dart; [README](../../app/lib/domain/README.md) | test widget y checker recursivo de imports |
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
| Requisitos, aceptación y trazabilidad del núcleo | docs/requirements/F1.1-CORE-REQUIREMENTS.md | Verificar por subfase al implementar |
| Decisiones tecnológicas originales y complementarias | docs/adr/ADR-001–ADR-014.md; docs/adr/additional/ | Correspondencia exacta del plan maestro y estado formal individual |
| Arquitectura compartida Linux-first de F1.3 | ARCHITECTURE.md; docs/adr/ADR-015-arquitectura-core-linux-first.md | F1.4 conserva el scaffold mínimo y verifica límites por imports |
| Checker global de límites de dominio | scripts/check_imports.dart; scripts/test_check_imports.sh | Un import permitido + diez violaciones negativas; protege todos los directorios domain bajo app/lib |

El módulo responsable de reproducción de anime, catálogo o autenticación del producto se desconoce: no hay código de aplicación en este alcance.
