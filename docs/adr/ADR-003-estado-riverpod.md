# ADR-003: Gestión de estado

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Propuesto; no consta aprobación formal**. `TECH_DECISIONS.md` también lo marca como propuesta.
- Fase: validar en F1.3–F1.4; integrar cuando la UI lo requiera.
- Requisitos: FR-02, FR-03, FR-12; NFR-09, NFR-10.

## Contexto

La solución debe coordinar casos de uso sin filtrar estado de presentación a dominio. El proyecto no tiene todavía features o navegación.

## Propuesta

Usar Riverpod como mecanismo de composición/estado de presentación si el spike confirma ciclo de vida, cancelación y sustitución por fakes. Los modelos y casos de uso permanecen Dart puros.

## Alternativas

- Estado local Flutter para componentes sin estado compartido.
- Bloc u otra solución solo si el flujo representativo ofrece una ventaja demostrable.

## Consecuencias y aceptación

No agregar Riverpod hasta la decisión formal. Spike: ciclo de vida, dependencias reemplazables, aislamiento de tests y cancelación/liberación; registrar versión, licencia y cambio de bundle.
