# Progreso tipado de reproducción (F1.10)

Dominio Dart puro para identificar/reanudar episodios sin depender de AniList, proveedor de video, Flutter o cuenta.

## Archivos y contratos

- `content_identity.dart`: `ContentId`, `EpisodeId`, `ProgressKey`; trim, validación release, igualdad por valor y clave compuesta no ambigua.
- `playback_progress.dart`: posición/duración ms, estado de finalización explícito, revisión y timestamp UTC técnico. Duración desconocida es `null`.
- `playback_progress_repository.dart`: `upsert/get/list/delete` por clave tipada.
- `checkpoint_coordinator.dart`: coordina ticks, pausa, seek, cierre y finalización con reloj y writer inyectables. La escritura solo queda confirmada después de su resultado.

## Validación y reanudación

Posición ≥0; duración `null` o >0; posición no excede duración conocida; timestamp UTC; revisión ≥0. Finalización es explícita; no se infiere por porcentaje. Una fila válida restaura la posición guardada; fila corrupta produce error y el consumidor debe reanudar en forma segura.

El flujo del catálogo demo no tiene todavía proveedor real de episodios ni player conectado. Utiliza el `AnimeId` local como `ContentId`, `EpisodeId('episode:1')`, posición en milisegundos y duración desconocida. No cambia el estado de biblioteca al guardar progreso.

## Checkpoints y concurrencia

Los umbrales de 10 s y seek estricto >30 s siguen provisionales. Los ticks consultan reloj inyectable, y pausa/seek/cierre/finalización solicitan guardado inmediato. Seek compara posición previa observada con la nueva. El estado se separa por `ProgressKey` y la cola serial evita perder la última posición; escritura fallida no se reporta como éxito ni mueve la última marca confirmada. El caller envía eventos; el coordinator no crea timers/background jobs. La política de tiempo activo exacto aún requiere validación antes de conectar el reproductor.

## Persistencia y migración

`data/local_db/drift_playback_progress_repository.dart` usa la tabla `playback_progress_entries`, PK `(content_id, episode_id)`. Schema v4 introdujo progreso tipado; el schema actual es v6 por cambios separados del catálogo. Migraciones desde v1/v3/v4/v5 conservan el progreso/JSON previo que corresponda. No se borran ni se convierten automáticamente filas de `progress_documents`; una importación futura requiere identidad confirmada.

## Pruebas

Desde `app/`:

```bash
flutter test --no-pub test/data/local_db/playback_progress_repository_test.dart
flutter test --no-pub test/data/local_db/app_database_test.dart
flutter test --no-pub test/widget_test.dart
```

SQLite usa archivos temporales bajo `.ai-local/test-db/`; la integración UI guarda 2700 s y comprueba reapertura real. Tests focalizados comprueban CRUD, 45:00, episodios/contenidos aislados, migraciones, integridad y concurrencia minute 15→45 con gate `Completer`; el reloj de checkpoints es falso/inyectable. La UI prueba offline con HTTP bloqueado.

## Portabilidad y límites

El modelo es reusable en otras plataformas y providers mediante contratos. Persistencia usa Drift/SQLite. No hay sync, perfil, cuenta, selección real de episodios, reproducción conectada ni política de merge cross-device aprobada. Rendimiento del equipo objetivo, acumulación de tiempo activo y recuperación tras crash del OS quedan pendientes.
