# F1.3 — Arquitectura compartida y Linux-first

Fuente: aprobación explícita del propietario y adjunto de la solicitud autorizado para lectura
Fecha: 2026-11-08
Módulo: arquitectura de AnimeApp
Estado: completada documentalmente; sin implementación
Decisión: núcleo compartido Dart + Fedora/Linux primero + adaptadores progresivos por plataforma
Evidencia: `ARCHITECTURE.md`, `docs/adr/ADR-015-arquitectura-core-linux-first.md`, `PROGRESS.md`

## Alcance realizado

- Se formalizó Fedora/Linux como plataforma inicial. Android, Android TV y Windows permanecen futuros, sin código, carpetas, servicios, interfaces ni dependencias anticipados.
- Se documentó separación de presentación, aplicación, dominio Dart puro, infraestructura, adaptadores Linux y composición.
- Se añadieron diagramas Mermaid de contexto, capas/dependencias, arranque Linux, operación local futura y flujo conceptual de reproducción.
- Se describieron los grupos `app`, `core`, `shared`, `features`, `integrations` y `platform` como límites conceptuales; la estructura no obliga a crear carpetas vacías.
- Se definieron reglas razonables de granularidad, ciclo de vida, recursos, rendimiento, seguridad, licencias y documentación/portabilidad por módulo importante.
- Se presentó una propuesta delimitada para F1.4: conservar el scaffold existente y crear solo estructura Linux/contratos compartidos que justifiquen criterios y consumidores reales.
- Se registró la decisión en ADR-015, independiente de F1.2 y complementaria del ADR adicional A01. No se alteraron ADR anteriores.

## Validación

No se creó ni modificó código de producto, no se instalaron dependencias y no se inició F1.4. Los diagramas son Mermaid y representan las plataformas futuras como no implementadas. La documentación distingue arquitectura objetivo, propuesta de F1.4 y estado real del scaffold. Se revisan enlaces internos, consistencia, formato y `python3 tools/ai/memory.py check` antes del cierre.

## Pendiente

- F1.4 debe concretar sus archivos mínimos contra los criterios de ROADMAP y el scaffold real; no asumir que todas las rutas candidatas son necesarias.
- Validaciones de licencias, compatibilidad, seguridad, rendimiento y comportamiento siguen en sus fases asignadas (F1.2/F2/F3/F5/F7 según la tecnología).
- F0.4–F0.6 continúan parciales como se registran en PROGRESS.md; F1.3 no altera su estado.
