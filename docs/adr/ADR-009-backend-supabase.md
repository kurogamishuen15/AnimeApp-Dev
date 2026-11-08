# ADR-009: Backend de sincronización

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Especificado en el plan; aprobación formal no consta en el registro local**. `TECH_DECISIONS.md` deja sin aprobar proveedor/backend concreto.
- Fase: contrato/FakeRemote en F1.11; backend y sincronización real en F5.
- Requisitos: FR-08, FR-09; NFR-02, NFR-08.

## Contexto

El proyecto es local-first; sincronización remota no es necesaria para operar offline y el backend no aloja video. La selección del plan indica Supabase con Postgres, Auth y Row Level Security (RLS), pero el contrato local decía solo REST y proveedor pendiente.

## Propuesta

Evaluar Supabase (Postgres + Auth + RLS) como backend de sincronización. Mantener un puerto de sincronización y cliente separado; no acceder a Supabase desde dominio ni convertir conectividad remota en requisito de arranque/uso local. El plan no decide si el cliente usa SDK Supabase o su API HTTP; no habilitar conexión directa del cliente a PostgreSQL ni exponer credenciales privilegiadas. La opción de transporte se decide tras verificar autenticación, RLS y compatibilidad con el contrato de dominio.

## Alternativas

- Servicio propio REST: más control operativo, mayor costo de implementación.
- Backend administrado alternativo: comparación solo si Supabase falla criterios de seguridad/costo/portabilidad.
- Sin sincronización real: mantiene offline, no satisface la salida futura de F5.

## Consecuencias y aceptación

Antes de F5: aprobar proveedor formalmente, modelar filas mínimas, demostrar RLS por identidad/operación, auth/desvinculación, recuperación offline, reintentos e idempotencia. Comparar SDK con API HTTP detrás del puerto, sin conexión directa PostgreSQL ni secretos privilegiados en cliente. Verificar costos, licencias, residencia/retención y política de datos antes de crear servicios. No almacenar ni proxy de video.
