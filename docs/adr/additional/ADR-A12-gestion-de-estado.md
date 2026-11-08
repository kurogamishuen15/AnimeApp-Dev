# ADR-003: Gestión de estado

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto: Riverpod; pendiente de validación**
- Fecha: 2026-11-08
- Fuente: `TECH_DECISIONS.md`
- Requisitos: FR-02, FR-03, FR-12, NFR-09, NFR-10

## Contexto

El cliente requerirá coordinar estado de casos de uso, pero la UI y navegación se implementan en fases posteriores. Riverpod figura como propuesta, no como decisión aprobada.

## Decisión propuesta

Evaluar Riverpod como composición de estado de presentación, manteniéndolo fuera de dominio y persistencia. No añadirlo al scaffold hasta validar ciclo de vida, cancelación y testabilidad con un flujo representativo.

## Alternativas

- Estado local de Flutter: adecuado para estado efímero; puede ser insuficiente para dependencias compartidas.
- Bloc u otra solución: comparar API, carga conceptual y dependencias.
- Riverpod: propuesta existente; sus ventajas deben demostrarse con spike.

## Consecuencias

Si se acepta, proveedores residen en composición/UI y consumen casos de uso; ningún modelo de dominio depende de Riverpod.

## Aceptación y verificación

Spike con carga/éxito/error/cancelación, reemplazo por fake, aislamiento entre tests y liberación del ciclo de vida. Registrar versión/licencia y efecto sobre bundle cuando la dependencia se evalúe.
