# ADR-005: Base local

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Propuesto; no consta aprobación formal**. `TECH_DECISIONS.md` marca Drift/SQLite como propuesta.
- Fase: F1.6.
- Requisitos: FR-01–FR-03, NFR-02, NFR-05, NFR-07.

## Contexto

Preferencias y progreso deben estar disponibles offline. Aún no hay base de datos de producto ni modelo final de ajustes/progreso. F0.6 no midió en el objetivo de 4 GB.

## Propuesta

Usar Drift sobre SQLite para consultas tipadas y migraciones, encapsulado en infraestructura detrás de repositorios del dominio.

## Alternativas

- SQLite directo: menor abstracción, más mapeo y migración manual.
- Archivos: sencillos, menos adecuados para consultas/transacciones crecientes.

## Consecuencias y aceptación

No agregar dependencia hasta decisión formal y spike F1.6. Medir CRUD, transacciones, migración/rollback, pruebas aisladas, RAM y latencia con datos representativos; conservar `pubspec.lock`. Los presupuestos numéricos requieren medición del hardware objetivo y aprobación.
