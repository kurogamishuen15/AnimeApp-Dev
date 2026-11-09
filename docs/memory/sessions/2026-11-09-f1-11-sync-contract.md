# F1.11 — Contrato local-first y FakeRemote

Fuente: implementación local y ADR-009/A11
Fecha: 2026-11-09
Módulo: domain/synchronization y data/testing
Estado: frontera y fake implementados; protocolo de sincronización pendiente
Decisión: exponer transporte abstracto sin fijar idempotencia, conflictos, orden o borrado
Evidencia: Dart analyze, 4 pruebas fake y checker de imports

## Implementación

- `SyncRemote` expone `submit(SyncEnvelope)` y retorna `Result<SyncReceipt>`; solicitud/payload son opacos y el identificador lo aporta el llamador.
- `FakeSyncRemote` registra snapshots profundos e inmutables de intentos solo en memoria, responde con un ack determinista por defecto o acepta una respuesta tipada inyectada. Una excepción inesperada se convierte en `UnavailableError`; identificador vacío se rechaza.
- El fake no guarda una réplica remota, no deduplica, no resuelve conflictos, no ordena, no borra, no reintenta y no llama a Supabase. Estas políticas quedan pendientes; no se afirmó idempotencia.
- La capa local de progreso no depende de `SyncRemote`; los fallos remotos no pueden ser prerrequisito de lecturas locales.

## Verificación

Con Flutter 3.50.0-0.4.pre / Dart 3.14.0 beta:

- `dart analyze lib/domain/synchronization lib/data/testing test/data/testing`: exit 0.
- `flutter test --no-pub test/data/testing/fake_sync_remote_test.dart`: exit 0, 4 pruebas.
- `dart scripts/check_imports.dart --root .`: exit 0, 8 archivos domain. El primer nombre `domain/sync/` activó la regla del checker que prohíbe ese segmento; se movió el contrato a `domain/synchronization/` y se validó otra vez sin editar la política global.

## Pendiente

Definir por el propietario identidad/idempotencia de cambios, concurrencia/conflicto, orden/fuente, borrado, retry/cancelación y estructura/campos de sincronización antes de un cliente real. Probar Supabase/Auth/RLS y seguridad solo en F5. No alojar video en el backend.

## Commit

- Commit F1.11: `6bea050`.
