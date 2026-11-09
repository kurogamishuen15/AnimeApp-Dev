# Store de ajustes

`SettingsStore` implementa acceso local-first sobre `AppDatabase`:

- `get<T>` retorna el default si no hay fila, decodifica y vuelve a validar
  datos persistidos, y expresa fallos mediante `Result<T>`.
- `set<T>` valida y persiste el JSON en transacción SQLite individual.
- `watch<T>` emite el valor inicial/default y cambios observados en SQLite como
  `Stream<Result<T>>`.

Las credenciales quedan excluidas. No hay sincronización ni preferencias de
producto registradas mientras el propietario no apruebe cada campo. La
composición debe poseer y cerrar `AppDatabase`; el adaptador es independiente
de Flutter UI y portátil a otro host que implemente la base SQLite.

Pruebas de integración reales: `app/test/settings/settings_store_test.dart`.
El ciclo de vida y los archivos de test están documentados en
[`local_db`](../../data/local_db/README.md).
