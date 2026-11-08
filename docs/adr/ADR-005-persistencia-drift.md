# ADR-005: Base local

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aceptado por el propietario el 2026-11-08 como selección arquitectónica; spike y validación técnica pendientes**.
- Fase: F1.6.
- Requisitos: FR-01–FR-03, NFR-02, NFR-05, NFR-07.

## Contexto

Preferencias y progreso deben estar disponibles offline. Aún no hay base de datos de producto ni modelo final de ajustes/progreso. F0.6 no midió en el objetivo de 4 GB.

## Propuesta

Usar Drift sobre SQLite para consultas tipadas y migraciones, encapsulado en infraestructura detrás de repositorios del dominio. La aprobación de selección no autoriza integrar dependencias fuera de F1.6.

## Alternativas

- SQLite directo: menor abstracción, más mapeo y migración manual.
- Archivos: sencillos, menos adecuados para consultas/transacciones crecientes.

## Consecuencias y aceptación

En F1.6 medir CRUD, transacciones, migración/rollback, pruebas aisladas, RAM y latencia con datos representativos; conservar `pubspec.lock` y verificar licencia/compatibilidad. Los presupuestos numéricos de rendimiento siguen siendo metas preliminares hasta medir hardware objetivo; no están aprobados como límites.
