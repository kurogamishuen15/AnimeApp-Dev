# Índice de decisiones

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: ADR locales y evaluaciones

- [AI-001: Markdown y SQLite FTS5](decisions/AI-001-memoria-local.md): portable, sin suscripción ni procesos residentes.
- [AI-002: aislamiento y concurrencia](decisions/AI-002-autonomia.md): limitar procesos y rechazar ejecución sin prerrequisitos.

## AnimeApp — F1.2

Las 14 selecciones tecnológicas de la sección 3 fueron aprobadas por el propietario el 2026-11-08 como arquitectura de referencia; validaciones y límites de integración están en [ADR F1.2](../adr/README.md). El baseline de [requisitos F1.1](../requirements/F1.1-CORE-REQUIREMENTS.md) también fue aprobado formalmente. La aprobación documental no autoriza implementar fuera de fase ni convierte ADR complementarios en decisiones aprobadas.

F1.3: estrategia aprobada **núcleo Dart compartido + Fedora/Linux primero + adaptadores progresivos por necesidad real**, registrada independientemente en [ADR-015](../adr/ADR-015-arquitectura-core-linux-first.md) y desarrollada en [ARCHITECTURE.md](../../ARCHITECTURE.md). Android, Android TV y Windows son destinos futuros; no crear scaffolding anticipado. F1.3 se completó documentalmente; F1.4 no está iniciada.

Catálogo desacoplado e identidad local: propuesta incremental parcialmente implementada, no aprobada formalmente, registrada en [ADR-A14](../adr/additional/ADR-A14-catalog-providers-identity.md). La UI usa un fake local sin I/O y la persistencia está en Drift v6; no altera ADR-008 ni F1.3. Los estados de biblioteca y el default son provisionales. Providers externos permanecen desconectados; elegibilidad/retención/licencias siguen pendientes.

Las decisiones de investigación no se aprueban automáticamente. Los ADR de producto no están disponibles aquí.
