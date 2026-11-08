# ADR-006: Persistencia local y migraciones

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto: SQLite con Drift; pendiente de spike en F1.6**
- Fecha: 2026-11-08
- Fuente: `TECH_DECISIONS.md`, `ROADMAP.md`
- Requisitos: FR-02, FR-03, NFR-02, NFR-05, NFR-07

## Contexto

El progreso y ajustes deben estar disponibles offline. Drift/SQLite aparece como propuesta. El rendimiento del equipo objetivo de 4 GB no se ha verificado y el plan exige conservar `pubspec.lock` al agregar paquetes.

## Decisión propuesta

Evaluar SQLite con Drift como almacenamiento local y capa de consultas tipadas. Encapsular esquema/DAO en infraestructura; casos de uso consumen repositorios de dominio. No tratar la elección como aprobada hasta validar migración, consultas y rendimiento.

## Alternativas

- Archivos JSON: sencillos, pero transacciones/consultas/concurrencia más manuales.
- SQLite directo: control y dependencia reducida, con mapeo/migraciones manuales.
- Drift: propuesta registrada; genera tipos y ayuda con consultas/migraciones a cambio de codegen/dependencias.

## Consecuencias

F1.6 define esquema mínimo para progreso y ajustes, migraciones, política de cierre y pruebas. Los umbrales de rendimiento se fijan con evidencia del hardware objetivo, no desde este ADR.

## Aceptación y verificación

Spike de CRUD, transacciones, migración de versión, rollback, pruebas aisladas y medición de memoria/latencia. Auditoría de licencia, mantenimiento y lockfile antes de integrar.
