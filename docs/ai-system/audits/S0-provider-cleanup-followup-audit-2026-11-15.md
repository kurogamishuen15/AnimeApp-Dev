# Auditoría de seguimiento — limpieza de providers S0 tras Miruro

**Fecha:** 2026-11-15<br>
**Raíz:** `/home/kyouma/Vídeos/PROYECTO ANIME`<br>
**Rama/HEAD de inicio y fin:** `main` / `b1bd952ac03c8711ce50cf22d249fa448d2e2880`<br>
**Alcance:** retirar exclusivamente el runtime experimental Miruro y sincronizar su composición, pruebas y documentación. Sin nueva integración de servidores.

## Resumen y recomendación

Se retiraron los tres archivos de implementación Miruro y su registro concreto.
`PlaybackProvidersModule.open()` conserva la misma API de composición, pero
ahora crea un `PlaybackProviderManager` vacío y no abre cliente HTTP. La prueba
activa de composición comprueba que no hay providers externos registrados.
Las fuentes de las pruebas retiradas se archivaron como `.dart.txt`, fuera del
árbol que Flutter descubre como tests.

Se conservaron los contratos neutrales, el manager y sus circuit breakers, el
source switch, la propagación genérica de cabeceras validadas, los mocks y el
único engine media_kit/libmpv. No se modificó el reproductor ni la UI. `dio`
permanece en las dependencias porque otros módulos lo usan.

**Resultado:** la limpieza queda validada en el checkout actual y el runtime
queda preparado para recibir instrucciones nuevas de integración. S0 no está
completa: ningún provider/resolver externo está activo y el playback externo
continúa en `0/70`. G1/T03 no se acepta ni se inicia F1.

## Estado Git y preservación

- `git rev-parse --show-toplevel` confirmó la raíz indicada arriba.
- `git worktree list` mostró solo este checkout; no se cambió de rama.
- No había cambios staged al comenzar ni al terminar. HEAD no cambió.
- El árbol ya contenía cambios locales de Bloque A, player, documentación,
  informes y ZIP antes de esta limpieza. Se conservaron; este informe no los
  atribuye a la tarea.
- No se hizo commit, push, fetch, cambio de remoto ni actualización de ramas.
- `app/pubspec.yaml` y `app/pubspec.lock` no cambiaron.

## Retirado y archivado

Se eliminaron del runtime:

1. `app/lib/data/player/providers/miruro/miruro_catalog.dart` — DTOs y parser
   específicos del catálogo Miruro.
2. `app/lib/data/player/providers/miruro/miruro_catalog_api.dart` — API HTTP
   Dio específica de Miruro.
3. `app/lib/data/player/providers/miruro/miruro_playback_provider.dart` —
   adapter de anime y resolver directo Miruro HLS/MP4.
4. Las cuatro pruebas Miruro bajo `app/test/data/player/providers/miruro/`;
   sus bytes coinciden con las copias de archivo. Se archivó también la prueba
   previa del composition root y el test histórico que ya estaba borrado del
   árbol de trabajo.

Fuentes de prueba preservadas en
[`docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/`](../archive/S0-A-miruro-tests-2026-11-15/).
Los `.dart.txt` son documentación de evidencia, no código activo. Los valores
`token=fixture`, `sig=fixture` y `fixture-cookie` allí son marcadores
sintéticos, no credenciales ni URLs firmadas.

El registro en `playback_providers_module.dart` se retiró junto al código. El
módulo no crea sockets, no hace requests al abrirse y mantiene `close()` como
hook de lifecycle sin recursos propios.

## Conservado

- `PlaybackSourceProvider`, `PlaybackVideoHostResolver`, modelos tipados y
  cancelación: `app/lib/domain/player/providers/`.
- Registro independiente de providers/resolvers, validación de respuestas,
  prioridades, fallback, deduplicación y circuit breakers:
  `app/lib/application/player/providers/`.
- `PlaybackSourceSwitchService` y la coordinación hacia el player existente.
- `PlaybackRequestHeaders` con validación de `Referer` público y la ruta
  existente que los transporta al engine.
- `MockPlaybackProvider`, la ruta de playback y el único motor
  media_kit/libmpv con su lease.
- README, informe S0-A, auditorías y resultados históricos. Se añadieron notas
  visibles que distinguen esos cortes del runtime actual; no se borraron logs
  sanitizados bajo `.ai-local/review/`.
- AnimeAV1, TioAnime, AnimeGG, `PublicSiteHttp`, el resolver estático y la prueba
  anterior de hosts ya estaban retirados antes de esta tarea; sus cambios
  locales se preservaron y no se restauraron.

La dependencia `dio` no se eliminó: además del código ahora retirado, sigue
siendo usada por AniList, AniSkip y OpenSubtitles.

## Referencias y resultado externo

Una búsqueda de referencias Dart después de la retirada no encontró
`MiruroPlaybackProvider`, `DioMiruroCatalogApi`, `MiruroDirectMediaResolver`,
`PublicSiteHttp`, `PublicMediaVideoHostResolver`, `AnimeAv1PlaybackProvider`,
`TioAnimePlaybackProvider` ni `AnimeGgPlaybackProvider` dentro de `app/**/*.dart`.
La única composición de providers sigue conectada desde `main.dart` y ahora
expone un manager vacío.

Los GET públicos ordinarios anteriores de Miruro config/lookup devolvieron
HTTP 403. Esta limpieza no repitió requests ni intentó cambiar la respuesta.
Esos resultados se conservan como evidencia histórica en el
[informe S0-A](../missions/S0-ANILILI-PORT-REPORT.md) y su
[auditoría](S0-ANILILI-port-audit-2026-11-15.md). No hubo episodios, URI,
playback, prueba Wayland o métricas de provider en esta tarea.

## Validación ejecutada

Toolchain local aislada: Flutter `3.50.0-0.4.pre`, revisión `368ac9e40b`;
Dart `3.14.0-315.3.beta`. Se usó la configuración ya instalada sin ejecutar
`flutter pub get`.

| Comprobación | Resultado |
|---|---|
| Tests focalizados de composición, manager y contrato | Exit 0; 24 aprobados |
| `flutter analyze --no-pub` | Exit 0; sin issues |
| `dart analyze lib test` | Exit 0; sin issues |
| Suite `flutter test --no-pub` | Exit 0; 268 aprobados, 6 optativos omitidos |
| Formato Dart de los dos archivos de composición/test | Exit 0; 0 archivos cambiados por formato |
| `python3 -W error::ResourceWarning -m unittest discover -s tests/ai -v` | Exit 0; 40 aprobados |
| `bash scripts/test_check_imports.sh` y checker del árbol | Exit 0; dos positivos y doce negativos esperados pasan; árbol real pasa |
| `git diff --check` y `git diff --cached --check` | Exit 0; sin errores |
| `python3 tools/ai/memory.py check` | Exit 0 después de crear este informe y resolver enlaces |

La prueba completa ejercitó libmpv con fixtures locales existentes; no prueba
proveedores externos. No se ejecutó build Linux porque no se modificaron el
engine, runner ni dependencias; tampoco se ejecutó `scripts/ci.sh`, ya que
incluye `flutter pub get`, innecesario para validar esta limpieza. No se
ejecutaron smokes live, mediciones de rendimiento o pruebas gráficas.

## Hallazgos

### S0-CLEAN-P1 — el objetivo de playback externo continúa sin cumplirse — abierto

- **Evidencia:** ningún provider ni resolver concreto queda registrado; el
  último GET público Miruro observado fue 403 y no se obtuvo fuente.
- **Reproducción:** `PlaybackProvidersModule.open()` crea el manager vacío;
  la prueba `playback_providers_module_test.dart` verifica `diagnostics.isEmpty`.
- **Consecuencia:** S0 permanece incompleta y playback externo `0/70`.
- **Corrección requerida:** una futura integración autorizada debe aportar
  provider/resolver modular, pruebas propias y reproducción real comprobada.
- **Estado:** conocido, fuera del alcance de limpieza; no bloquea aceptar esta
  limpieza como tal.

### S0-CLEAN-P2 — pruebas específicas retiradas ya no son regresión ejecutable — abierto

- **Evidencia:** su código quedó archivado como texto, fuera de `app/test`.
- **Consecuencia:** la limpieza no conserva tests activos del parser Miruro;
  ejecutar esas copias requeriría restaurar el runtime que se retiró.
- **Corrección requerida:** la siguiente integración debe incorporar pruebas
  nuevas que validen el contrato y su implementación, en vez de reactivar tests
  acoplados al código retirado.
- **Estado:** aceptado para este alcance de retiro.

No se observó una regresión en composición, manager, contratos ni player en las
pruebas ejecutadas.

## Revisión adversarial

Se verificó que los tests no quedaran importando clases eliminadas, que el
composition root no mantuviera un cliente Dio sin consumidores, que no se
eliminara `dio` de módulos ajenos y que los README y handoffs no declararan a
Miruro activo. Un auditor de código revisó secuencialmente en solo lectura el
grafo de dependencias; su informe coincidió en conservar contratos, manager,
source switch, header allowlist, mock, composition root vacío y engine. La
revisión independiente no ejecutó pruebas ni requests.

## Archivos actualizados en esta limpieza

- `app/lib/data/player/providers/playback_providers_module.dart`
- `app/test/data/player/providers/playback_providers_module_test.dart`
- `app/lib/README.md`, `app/lib/data/player/README.md`
- `ARCHITECTURE.md`, `docs/memory/ARCHITECTURE_INDEX.md`
- `app/lib/data/player/providers/README.md`
- `app/lib/data/player/providers/miruro/README.md`
- `app/lib/data/player/providers/video_hosts/README.md`
- `TESTING.md`, `PROGRESS.md`
- `docs/ai-system/missions/KONGROO-RECONSTRUCTION-PLAN.md`
- `docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md`
- `docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md`
- `docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md`
- `docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md`
- `docs/ai-system/audits/S0-provider-audit-2026-11-15.md`,
  `S0-video-host-audit-2026-11-15.md` y
  `PROVIDER-IMPLEMENTATION-audit-2026-11-14.md`
- `docs/ai-system/missions/S0-ANILILI-PORT-REPORT.md`
- `docs/ai-system/audits/S0-ANILILI-port-audit-2026-11-15.md`
- `docs/memory/PROJECT_STATE.md`, `AI_HANDOFF.md`, `MODULE_INDEX.md` y
  `RESEARCH_INDEX.md`
- Este informe y el archivo de fuentes de tests bajo
  `docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/`.
