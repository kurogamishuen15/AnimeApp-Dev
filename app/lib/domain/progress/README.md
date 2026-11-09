# Progreso tipado de reproducción (F1.10)

Dominio Dart puro para identificar y reanudar episodios sin depender de
AniList, archivos de streaming, Flutter o reproductor concreto.

## Archivos y contratos

- `content_identity.dart`: `ContentId`, `EpisodeId`, `ProgressKey`; trim de
  extremos, rechazo runtime de IDs vacíos, igualdad por valor y clave compuesta
  con longitud prefijada. Los IDs son de AnimeApp y deben persistirse sin
  convertirlos a IDs de proveedores; consumidores/importadores conservan un
  namespace en el valor, por ejemplo `local:...` o `catalog:...`.
- `playback_progress.dart`: posición/duración entera en milisegundos,
  `CompletionState` explícito, revisión y `updatedAtUtc` técnico. La duración
  desconocida se representa con `null`; no implica completado.
- `playback_progress_repository.dart`: contrato `upsert/get/list/delete` por
  `ProgressKey` y filtro de contenido.
- `checkpoint_coordinator.dart`: orquesta eventos de reproducción con reloj
  inyectable y writer. No depende de Flutter ni del motor.

## Validación y reanudación

Posición ≥0; duración nula o positiva; posición no puede exceder duración
conocida; timestamp debe ser UTC; revisión ≥0. Finalización es una acción
explícita; no se deduce de porcentaje. Resume devuelve la posición persistida
solo si el registro valida; si no, el adaptador entrega error y el consumidor
debe iniciar desde cero de forma segura.

## Checkpoints y concurrencia

Configuración provisional: intervalo de 10 s y seek estricto mayor a 30 s.
Eventos playing consultan el reloj, paused/closing/completed solicitan guardado
inmediato, y seek compara posición previa/nueva. El estado de tiempo/posición
se separa por `ProgressKey`. Las escrituras pasan por una cola serial; el
resultado solo es exitoso tras confirmación del writer. Un fallo no mueve la
marca confirmada; eventos posteriores pueden volver a guardar. El coordinador
no crea timers ni tareas de fondo; el caller le envía ticks/eventos. La política
actual mide tiempo de reloj entre checkpoints, no acumula exclusivamente
tiempo activo; una pausa larga puede hacer que el próximo tick sea elegible.
Es un límite conocido que debe ajustarse antes de conectar el reproductor.

## Persistencia y migración

`data/local_db/drift_playback_progress_repository.dart` implementa el contrato
con SQLite/Drift en la tabla `playback_progress_entries`, clave primaria
compuesta `(content_id, episode_id)`. Schema v4 se añade sin borrar
`progress_documents`: los documentos JSON existentes se preservan intactos y
no se convierten automáticamente porque no tienen identidad inequívoca. Una
migración futura podrá importar solo registros que un usuario/propietario
asocie explícitamente a una clave tipada.

## Pruebas

Desde `app/`:

```bash
flutter test --no-pub test/data/local_db/playback_progress_repository_test.dart
flutter test --no-pub test/data/local_db/app_database_test.dart
```

Las pruebas usan SQLite en archivos temporales `.ai-local/test-db/`, verifican
CRUD, 45:00, reopen, migraciones v1→v4/v3→v4, integridad, episodios aislados y
el caso de concurrencia minute 15→45 con gate Completer real sobre el writer
Drift. Reloj falso controla el intervalo. Los valores 10 s/30 s son provisionales.

## Portabilidad y límites

El dominio puede compartirse con futuras plataformas sin adaptadores de
reproductor. Persistencia depende de Drift/SQLite. No sincroniza, no sabe de
cuentas/perfiles y no define merge cross-device. Rendimiento en hardware de
4 GB, recuperación tras crash del proceso/OS y duración activa acumulada quedan
pendientes; el test cierra/reabre la DB en el mismo proceso.
