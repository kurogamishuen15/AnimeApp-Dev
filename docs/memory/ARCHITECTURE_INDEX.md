# Índice arquitectónico

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001
Evidencia: tools/ai/memory.py y pruebas de recuperación

## Fuentes canónicas
- [Arquitectura de memoria](../ai-system/MEMORY_ARCHITECTURE.md).
- [Decisiones](DECISIONS.md).
- [Módulos](MODULE_INDEX.md).
- [Permisos y autonomía](../ai-system/AUTONOMY_POLICY.md).

## AnimeApp
La arquitectura F1.3 aprobada (núcleo Dart compartido, Fedora/Linux primero, adaptadores progresivos) está documentada en [ARCHITECTURE.md](../../ARCHITECTURE.md) y [ADR-015](../adr/ADR-015-arquitectura-core-linux-first.md). F1.4 conserva el scaffold Flutter Linux mínimo; módulos activos y límites/checker están descritos en [`app/README.md`](../../app/README.md) y [`scripts/README.md`](../../scripts/README.md). El dominio permanece Dart puro y no hay reproductor ni catálogo implementados. Android, Android TV y Windows son destinos futuros sin código específico. La auditoría del entorno está en [F0.1 Fedora](../environment/F0.1-FEDORA.md).

Requisitos y trazabilidad del MVP/núcleo, aprobados formalmente el 2026-11-08: [F1.1](../requirements/F1.1-CORE-REQUIREMENTS.md). Las 14 selecciones de referencia aprobadas y sus validaciones pendientes, además de ADR adicionales preservados: [ADR de F1.2](../adr/README.md). La aprobación documental no implica implementación.

## Infraestructura de IA
La arquitectura confirmada aquí es Markdown → índice SQLite derivado → fragmentos acotados y herramientas Python sin dependencias externas. No inferir módulos de producto ni tratar planificación como implementación.
