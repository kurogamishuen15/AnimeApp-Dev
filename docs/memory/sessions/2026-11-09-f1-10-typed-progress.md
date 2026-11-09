# F1.10 — progreso tipado local

Fuente: implementación y pruebas F1.10
Fecha: 2026-11-09
Módulo: domain/progress y data/local_db
Estado: implementado y validado localmente
Decisión: identidad propia por contenido/episodio; JSON heredado se conserva sin conversión ambigua
Evidencia: `app/test/data/local_db/playback_progress_repository_test.dart`, `app/test/data/local_db/app_database_test.dart`, `.ai-local/validation/f1_10_*`

Schema v4 agrega `playback_progress_entries`, sin eliminar `progress_documents`.
IDs normalizados con trim, no vacíos en release, equality/hash por valor y clave
compuesta longitud-prefijada. `PlaybackProgress` valida posición/duración,
timestamp UTC/revisión; completado es explícito. Repositorio Drift implementa
upsert/get/list/delete por `ProgressKey`. `CheckpointCoordinator` recibe eventos
por API, reloj/writer inyectables, particiona estado por clave y serializa
escrituras; solo confirma después del writer exitoso.

Resultados en Flutter 3.50.0-0.4.pre / Dart 3.14.0 beta aislado: análisis Dart,
Flutter analyze, 12 pruebas focalizadas, 49 suite total, CI y Linux debug build
exit 0. Migraciones v1→v4 y v3→v4; registros JSON existentes preservados;
SQLite integrity_check `ok`. La carrera 15:00→45:00 espera una barrera de inicio
de escritura, lanza seek durante bloqueo, libera, cierra DB, reabre y recupera
45:00. Auditoría QA confirmó corrección del gate y aislamiento por clave.

Límite: el intervalo actual se mide con reloj de pared desde el último
checkpoint, no tiempo activo acumulado; una pausa larga puede volver elegible
el primer tick. Los umbrales de 10 s/30 s son provisionales. No probado en
reproductor real, crash del proceso/OS ni hardware objetivo de 4 GB. Sin sync ni
política de conflicto.
