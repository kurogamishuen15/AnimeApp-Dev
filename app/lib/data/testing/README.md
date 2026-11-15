# Fakes de transporte para pruebas

`FakeSyncRemote` implementa `SyncRemote` para ejercitar la capa de sincronización sin red ni credenciales. Permite inyectar la respuesta y devuelve recibos observables; no es una implementación de producción.

| Archivo | Responsabilidad | Pruebas |
|---|---|---|
| `fake_sync_remote.dart` | Fake determinista y copia defensiva del envelope/resultado | `test/data/testing/fake_sync_remote_test.dart` |

Al añadir escenarios, mantener el fake acotado al contrato y no simular semánticas de servidor que no estén especificadas. Ejecutar desde `app/`: `flutter test --no-pub test/data/testing/fake_sync_remote_test.dart`.
