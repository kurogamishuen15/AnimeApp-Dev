# KONGROO — auditoría S0 de proveedores — 2026-11-15

> **Corte histórico:** esta revisión precede las dos limpiezas de S0. Los
> adapters y resolutores descritos ya no están registrados; el runtime actual
> se documenta en la [auditoría de limpieza posterior](S0-provider-cleanup-followup-audit-2026-11-15.md).

> Resultado: **S0 continúa activa e incompleta**. Esta auditoría no acepta G1,
> no cierra la misión y no inicia bloques posteriores.

## Resumen

Se corrigió el contrato de alternativas de TioAnime y el circuito de resolución
para contabilizar el fallo solo cuando se agotan los servidores del proveedor.
La regresión confirma que el cuarto servidor todavía puede resolver después de
tres fallidos. La suite focalizada pasó; no se encontró un defecto P0/P1 nuevo
en el código revisado.

La aceptación de S0 sigue bloqueada: los intentos live existentes de TioAnime y
AnimeAV1 no reprodujeron con libmpv, no se verificó primer frame visible y solo
12 de 22 candidatos tienen evidencia parcial actual. Diez carecen todavía de
evidencia suficiente. Ningún proveedor queda `PLAYBACK_VERIFIED` y el contador
real permanece en `0/70`.

## Alcance y entorno

- Raíz Git: `/home/kyouma/Vídeos/PROYECTO ANIME`; rama `main`.
- HEAD durante esta auditoría: `b1bd952ac03c8711ce50cf22d249fa448d2e2880`.
  No se creó commit ni se hizo push.
- Toolchain de pruebas: Flutter 3.47.9 aislado en `.ai-local/toolchains`, Dart
  3.13.7; no se tocó el SDK global.
- Se preservaron los cambios previos de reevaluación del Bloque A y archivos
  locales no rastreados. La auditoría cubre la coordinación/providers de S0 y
  las pruebas indicadas, no todo el conjunto de cambios preexistentes.
- Las peticiones web nuevas fueron GET públicos acotados, sin cookies ni
  autenticación. No se ejecutó JavaScript, Cloudflare, pipe, descifrado ni
  resolvedores externos. No se reutilizó ninguna respuesta como prueba de
  reproducción.

## Archivos revisados

- `app/lib/application/player/providers/playback_provider_manager.dart`
- `app/lib/data/player/providers/tioanime/tioanime_playback_provider.dart`
- `app/test/application/playback_provider_manager_test.dart`
- `app/test/data/player/providers/public_playback_provider_test.dart`
- READMEs de providers/manager, TioAnime y AnimeOnline Ninja.
- `KONGROO-RECONSTRUCTION-PLAN.md`, `STATUS`, `HANDOFF`, `S0-REAL-PLAYBACK-REPORT.md`,
  `PROGRESS.md`, `TESTING.md`, `docs/memory/PROJECT_STATE.md` y `AI_HANDOFF.md`.

## Hallazgos

### S0-P1-01 — La aceptación de reproducción real sigue incumplida — `OPEN`

- **Referencia:** [informe S0](../missions/S0-REAL-PLAYBACK-REPORT.md#bloqueos-y-siguiente-trabajo),
  puntos 1–3 y matriz de reproducción.
- **Evidencia:** TioAnime obtuvo una URI de YourUpload, pero libmpv quedó en
  `position_ms=0` con error. AnimeAV1 devolvió `unauthorized` antes de obtener
  una URI. Ambos smokes live terminaron exit 1 en los logs sanitizados. Ninguno
  demuestra primer frame, audio, seek ni cierre de una reproducción externa.
- **Reproducción:** desde `app/`, ejecutar una sola prueba opt-in por proveedor
  usando `KONGROO_LIVE_PROVIDER_SMOKE=1` y `--plain-name`; consultar antes los
  logs del corte para evitar repetir fallos sin nueva evidencia. Los detalles de
  esta corrida están en `.ai-local/review/s0-real-playback-2026-11-15/`.
- **Consecuencia:** no se puede aceptar S0 ni contar títulos para la meta 70.
- **Acción:** continuar con servidores y proveedores públicamente accesibles;
  registrar primer frame/avance/audio/seek/cierre reales antes de cambiar el
  estado a `PLAYBACK_VERIFIED`.
- **Pruebas de regresión necesarias:** un smoke reproducible por fuente y
  servidor, con ID de anime/episodio, métricas de decodificación, posición y
  dispose; una prueba externa no puede sustituirse por fixtures.

### S0-P2-01 — Cobertura de inventario parcial — `OPEN`

- **Referencia:** [matriz de 22 candidatos](../missions/S0-REAL-PLAYBACK-REPORT.md#matriz-del-inventario-autorizado)
  y lista de bloqueos al final del informe.
- **Evidencia:** 12 candidatos tienen sondeos parciales, pero esos sondeos no
  equivalen a búsqueda, identificación, episodios, servidores y reproducción.
  Diez candidatos aún carecen de evidencia suficiente. Animeflv.one permitió
  buscar One Piece, pero sus fichas públicas de One Piece y Demons' Crest no
  mostraron rutas de episodio. AnimeJara, Latanime,
  AnimeKai, AllAnime, Henaojara y Animeflv.one permanecen sin episodio externo
  verificado; varios se bloquearon en una respuesta corriente, DNS, redirección
  no validada o control de acceso descrito upstream.
- **Reproducción:** revisar las filas `PENDING`, `INVESTIGATING` y
  `BLOCKED_EXTERNAL` en el informe; para cada una, confirmar dominio actual con
  una fuente primaria antes de hacer un GET normal.
- **Consecuencia:** la misión no puede declararse completa ni todos los
  candidatos clasificarse como operativos/no disponibles.
- **Acción:** continuar el inventario de uno en uno. No repetir una respuesta
  denegada sin evidencia de que cambió el acceso; no inventar mirrors ni
  transformar raíz 200 en búsqueda/episodio.
- **Pruebas de regresión necesarias:** por adaptador que se implemente,
  contract tests de búsqueda/identidad/episodio/alternativas, validación de host
  y resolución; live smoke real solo cuando una fuente pública devuelva un
  candidato sin eludir restricciones.

## Revisión del código y límites

`TioAnimePlaybackProvider` declara ahora `sourceAlternatives`, requerido por el
manager cuando una respuesta contiene varios servidores. En resolución, el
manager recorre fuentes y servidores ordenados antes de registrar un fallo
agregado, reinicia el breaker con una resolución válida y libera un probe
half-open cuando los resultados son vacíos o no soportados. La cancelación
libera el probe antes de salir.

La regresión de cuatro servidores cubre los tres primeros errores y exige éxito
del cuarto. La regresión de contrato fixture pasa dos alternativas por el
manager. Las pruebas con fake o libmpv sobre medios locales solo verifican
coordinación local; no son evidencia de un proveedor externo.

La segunda pasada adversarial revisó intentos posteriores al primer éxito,
resultados vacíos/no soportados, cancelación durante la búsqueda de mirrors,
respuesta inválida y el cierre de circuitos. No se encontró defecto reproducido
en esos caminos dentro del diff revisado. Esta pasada la realizó el coordinador
localmente; **no es una auditoría independiente**.

## Pruebas ejecutadas en el recheck

| Comprobación | Resultado |
|---|---|
| `flutter test --no-pub --reporter expanded test/data/player/providers/public_playback_provider_test.dart test/application/playback_provider_manager_test.dart` | Exit 0; 22 pass, 2 live opt-in omitidas |
| `flutter analyze --no-pub` | Exit 0; no issues |
| `dart analyze lib test` | Exit 0; no issues |
| `dart format --output=none --set-exit-if-changed` en los cuatro archivos Dart modificados de S0 | Exit 0; 0 archivos cambiados |
| `python3 tools/ai/memory.py check` | Exit 0; `[]` |
| `git diff --check` | Exit 0; sin errores |

Los smokes live de TioAnime y AnimeAV1, el fallback de source switch con fake y
el cambio con libmpv/fixtures locales son evidencia anterior del mismo trabajo
S0 y están identificados por separado en el informe. No se repitieron en este
recheck final.

## Fuentes externas consultadas

Acceso: 2026-11-15.

- [PR AnimeOnline Ninja #1274](https://github.com/yuzono/anime-extensions/pull/1274):
  propone `ww4`; registra desafío Cloudflare durante la verificación. Solo se
  hicieron GETs corrientes a `ww3` y `ww4`.
- [Solicitud Animeflv.one #1278](https://github.com/yuzono/anime-extensions/issues/1278):
  fuente comunitaria, no implementación ni confirmación de que `.one` sea el
  AnimeFLV original.
- [anime1v-api](https://github.com/FxxMorgan/anime1v-api) y su
  [MIT License](https://github.com/FxxMorgan/anime1v-api/blob/main/LICENSE):
  describe scraping de AnimeAV1.com, API con clave y automatización anti-bot.
  No se usó el servicio ni se copió código.
- [AnimeKai extension](https://github.com/aniyomi-addons/animekai-ext): su README
  describe Cloudflare, extracción tokenizada y un servicio externo; no se
  utilizaron esas rutas.
- [AllAnime issue #607](https://github.com/yuzono/anime-extensions/issues/607) y
  [cambio de dominio #4566](https://github.com/keiyoushi/extensions-source/issues/4566):
  el primero reporta desafío Cloudflare en episodios y redirección a
  `mkissa.to`; el segundo conserva el cambio histórico a `allmanga.to`.
- [Referencia histórica Henaojara](https://github.com/aniyomiorg/aniyomi-extensions/issues/2309)
  y [lista de extensiones Latanime](https://github.com/mojuru/anime-repo/blob/repo/index.json):
  fuentes para los hosts que recibieron una única petición pública acotada.

Estas fuentes describen implementaciones o reportes upstream, no demuestran
disponibilidad actual de sus medios ni autorizan eludir controles.

## Riesgo de recursos y pruebas faltantes

La nueva iteración de alternativas es finita y está limitada por las listas
devueltas por el adaptador. No se midió CPU/RAM, arranque, tiempo al primer
frame, retención ni fugas de memoria en este recheck. Tampoco se observó ventana
visible de Kongroo, audio audible o seek externo. Los criterios quedan
pendientes de prueba en Fedora y no se extrapolan a rendimiento validado.

## Recomendación y continuidad

Mantener S0 `ACTIVE`, con reproducción `0/70`. No declarar proveedor operativo,
no aceptar G1 y no iniciar B–F. La siguiente ejecución debe continuar con el
próximo candidato de los diez que carecen de evidencia suficiente, confirmando
primero su dominio mediante una fuente primaria y usando solo rutas públicas
corrientes. El estado detallado por proveedor está en el informe S0 y el punto
de reanudación en `KONGROO-RECONSTRUCTION-HANDOFF.md`.
