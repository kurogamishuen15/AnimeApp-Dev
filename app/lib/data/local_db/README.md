# Persistencia local (infraestructura)

`AppDatabase` encapsula SQLite mediante Drift. Es infraestructura y no debe
filtrarse al dominio. El dominio consume contratos/repositorios; la
composición de aplicación crea y cierra la base.

## Estado actual

- Schema version 2.
- `settings_entries` conserva envelopes JSON por clave estable; catálogo,
  validación y semántica tipada están en [`settings`](../../settings/README.md).
- `progress_documents` conserva un documento opaco. No define reglas de
  progreso, conflictos ni semántica temporal; esos contratos pertenecen a
  F1.10/F1.11.
- Migración v1→v2 no destructiva. El snapshot histórico v1 está en
  [`app/drift_schemas/schema_v1.sql`](../../../drift_schemas/schema_v1.sql).
- Apertura de producto usa el directorio de soporte de la aplicación. Las
  pruebas inyectan una ruta SQLite real bajo `.ai-local/test-db/`.
- Integración del ciclo de vida con el composition root y responsable de
  cierre aún pendientes de F1.5; por ahora el consumidor debe cerrar la base.
- `NativeDatabase.createInBackground` mantiene el acceso al archivo fuera del
  isolate de UI. No se ha medido rendimiento en hardware objetivo.

## Pruebas y portabilidad

`test/data/local_db/app_database_test.dart` comprueba creación, persistencia
tras cierre y reapertura, migración de archivo v1 con datos existentes y
rollback transaccional. Cada prueba crea y elimina su propio directorio dentro
de `.ai-local/`; no usar la base de usuario de la aplicación en pruebas.

Drift/SQLite es una selección aprobada (ADR-005); la versión bloqueada y los
archivos generados se revisan junto con el `pubspec.lock`. Licencia,
compatibilidad Flatpak y mediciones de rendimiento siguen pendientes para sus
fases de validación. El snapshot debe conservarse al cambiar esquema y cada
nueva versión debe agregar una migración probada desde la anterior.

## Comandos

Desde `app/`:

```sh
dart run build_runner build
dart format lib/data/local_db test/data/local_db
flutter test --no-pub test/data/local_db/app_database_test.dart
```
