# Tablas Drift

Esta carpeta contiene declaraciones de esquema; no contiene repositorios ni ejecuta consultas. `AppDatabase` registra estas tablas y sus restricciones, y el código generado se mantiene mediante el generador Drift del proyecto.

| Archivo | Datos |
|---|---|
| `anime_identity_entries.dart`, `anime_identity_relationships.dart`, `external_anime_identifiers.dart` | Identidad local y relaciones/IDs externos |
| `library_entries.dart`, `latest_anime_search.dart` | Biblioteca local y último resultado de búsqueda |
| `playback_progress_entries.dart`, `progress_documents.dart` | Progreso tipado y documentos de sincronización |
| `settings_entries.dart` | Valores de configuración locales |

Las migraciones y consultas pertenecen a `data/local_db`, no a las entidades UI. Un cambio de esquema debe actualizar tabla, versión/migración, snapshot Drift y pruebas de migración; no editar el `.g.dart` a mano. Pruebas: `flutter test --no-pub test/data/local_db`.
