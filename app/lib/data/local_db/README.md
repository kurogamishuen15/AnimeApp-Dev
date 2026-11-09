# Persistencia local (infraestructura)

`AppDatabase` encapsula SQLite mediante Drift. Es infraestructura y no debe
filtrarse al dominio. El dominio consume contratos/repositorios; la
composición de aplicación crea y cierra la base.

## Estado actual

- Schema version 3. F1.8 agrega `latest_anime_search` mediante migración v2→v3;
  la ruta desde v1 se prueba encadenando migraciones.
- `settings_entries` conserva envelopes JSON por clave estable; catálogo,
  validación y semántica tipada están en [`settings`](../../settings/README.md).
- `progress_documents` conserva un documento opaco. No define reglas de
  progreso, conflictos ni semántica temporal. `LocalProgressRepository`
  persiste y recupera payloads JSON por una identidad exacta suministrada por
  su consumidor; su `updatedAt` es un instante técnico UTC. Campos de negocio,
  formación de la identidad, reanudación y conflictos siguen pendientes en
  F1.10/F1.11.
- `latest_anime_search` es un único slot reemplazable para la última búsqueda
  explícita del usuario; no conserva un historial o lote de respuestas. La
  consulta, página y tamaño deben coincidir antes de usarla offline.
  `cached_at` es un instante UTC técnico de recepción, no una regla de negocio.
- Migración v1→v2 no destructiva. El snapshot histórico v1 está en
  [`app/drift_schemas/schema_v1.sql`](../../../drift_schemas/schema_v1.sql).
- Apertura de producto usa el directorio de soporte de la aplicación. Las
  pruebas inyectan una ruta SQLite real bajo `.ai-local/test-db/`.
- Integración del ciclo de vida con el composition root y responsable de
  cierre siguen pendientes de la integración de aplicación; el consumidor debe
  cerrar la base explícitamente.
- `NativeDatabase.createInBackground` mantiene el acceso al archivo fuera del
  isolate de UI. No se ha medido rendimiento en hardware objetivo.

## Pruebas y portabilidad

`test/data/local_db/app_database_test.dart` comprueba creación, persistencia
tras cierre y reapertura, migración de archivo v1 con datos existentes a
schema v3 (incluye la rama v1→v2 y luego v2→v3), migración v2→v3 y rollback
transaccional. `test/core/f1_12_real_integration_test.dart` además verifica
`PRAGMA integrity_check` luego de cierre/reapertura y una secuencia settings →
SQLite → HTTP loopback → caché → desconexión/reinicio → recuperación. Cada prueba
usa su propio directorio bajo `.ai-local/`; no usa la base real de aplicación.

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
