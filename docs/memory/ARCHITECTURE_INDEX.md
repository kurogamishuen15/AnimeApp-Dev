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
La arquitectura del producto está documentada en [ARCHITECTURE.md](../../ARCHITECTURE.md). El scaffold Flutter Linux tiene composición UI, identidad de dominio Dart puro y runner Linux; no hay reproductor ni catálogo implementados. La auditoría del entorno está en [F0.1 Fedora](../environment/F0.1-FEDORA.md).

Requisitos y trazabilidad del MVP/núcleo, pendientes de aprobación formal: [F1.1](../requirements/F1.1-CORE-REQUIREMENTS.md). Correspondencia de las 14 decisiones exactas proporcionadas por el propietario y ADR adicionales preservados: [ADR de F1.2](../adr/README.md). La documentación no implica implementación.

## Infraestructura de IA
La arquitectura confirmada aquí es Markdown → índice SQLite derivado → fragmentos acotados y herramientas Python sin dependencias externas. No inferir módulos de producto ni tratar planificación como implementación.
