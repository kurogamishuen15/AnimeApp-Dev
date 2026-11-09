# ADR-014: Contrato y política de sincronización

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Local-first aceptado; protocolo y resolución de conflictos propuestos/pendientes**
- Fecha: 2026-11-08
- Fase propietaria: F1.11
- Requisitos: FR-01, FR-08, FR-09, NFR-02, NFR-08, NFR-09

## Contexto

El proyecto aprueba operación local primero y que un backend remoto no sea requisito para uso offline. El roadmap pide contrato de sincronización y FakeRemote, mientras el plan posterga sincronización real y establece que el backend no aloje video.

## Decisión

F1.11 define un puerto remoto y un FakeRemote determinista. La persistencia local sigue disponible sin red y no se elimina/reescribe por un fallo remoto. No se selecciona endpoint, proveedor, almacenamiento de video ni política final de conflictos; el transporte REST es el principio local registrado, no una autorización para desplegar backend.

## Alternativas

- Sincronización remota obligatoria: contradice offline/local-first.
- Replicación automática sin versión/conflicto: puede sobrescribir progreso.
- Contrato + FakeRemote primero: prueba reglas sin servicio externo y coincide con el plan.

## Consecuencias

F1.11 debe decidir identidad de cambios, idempotencia, orden, conflictos, borrado y reintentos con casos explícitos. El FakeRemote verifica el contrato y no prueba compatibilidad con backend real.

## Aceptación y verificación

Ejecutar los mismos tests de contrato contra fake local/remoto; probar repetición de petición, desconexión, conflicto concurrente y reinicio. Confirmar que el uso local no requiere red y que no existe código ni configuración de despliegue en esta fase.

## Contrato F1.11 (sin política de réplica aprobada)

Se añadió un puerto Dart puro `SyncRemote.submit(SyncEnvelope)` con un identificador y payload opacos provistos por el llamador. `FakeSyncRemote` permite respuesta tipada configurable y registra cada intento en memoria. El fake reconoce solicitudes vacías como inválidas, pero no retiene datos remotos, deduplica, fusiona, ordena, borra ni reintenta.

Esto valida el límite de dependencia y el paso de resultados/errores; no completa idempotencia remota ni resolución de conflictos. Antes de implementar sincronización real, el propietario debe definir identidad persistente del cambio, semántica de repetición, conflictos, borrado, precedencia/orden, reintentos y carga permitida. No hay conexión Supabase, despliegue, configuración de Auth/RLS ni transferencia de video.
