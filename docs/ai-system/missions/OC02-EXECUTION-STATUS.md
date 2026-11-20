# OC-02 — Estado de ejecución (checkpoint 2)

**Fecha:** 2026-11-16 · **Rama:** `main` · **HEAD:** `6cc3e5e` (sin commits, sin push)
**Raíz verificada:** `/home/kyouma/Vídeos/PROYECTO ANIME`
**Resultado:** PARTIAL. Home y carátulas verificadas en Fedora; episodios con índice real; Continuar viendo conectado; video visible con el motor existente (fixture local). Fuentes externas reproducibles: **0 verificadas**.

## Entorno

| Elemento | Valor |
|---|---|
| SDK usado | `.ai-local/toolchains/flutter-3.47.9` (Flutter 3.47.9 / Dart 3.13.7) |
| `pubspec.lock` | Sin cambios (verificado con `git status`) |
| Sesión gráfica | Wayland `wayland-0`, `DISPLAY=:0`. Capturas con `spectacle -b -n -f` (sin aceptar diálogos) |
| Entrada sintética | `ydotool` instalado pero requiere `ydotoold` y `/dev/uinput` (permisos de sistema). **No usado** |
| Base de datos de la app en pruebas | `KONGROO_DATABASE_PATH` → `.ai-local/oc02-fedora/home.sqlite`. La base del propietario no se toca |
| Plataformas | Linux (Fedora) ejecutado. **Android y Windows: no ejecutados** (no hay runner `app/android/` ni `app/windows/`) |

## Sección 1 — Home (`home_screen.dart`, `home_data.dart`, `home_artwork.dart`)

| Punto | Estado | Evidencia |
|---|---|---|
| Timeout global 12 s eliminado | HECHO | Presupuesto por sección `CatalogHomeSource.sectionBudget` (10 s); techo de seguridad 30 s en `HomeScreen.loadCeiling`. Test `a slow library is bounded…` |
| Diagnóstico seguro de `HomeArtwork` | HECHO | `home_artwork_diagnostics.dart`: registra tipo y host, nunca URL ni query. Test de widget con imagen fallida y de sanitización |
| Campo opcional inválido no oculta el anime | HECHO | `anilist_client.dart::_lenient`. Test `drops only the invalid optional field and keeps the valid anime` (antes descartaba la entrada) |
| Caché de populares/tendencias | HECHO | `drift_anilist_browse_cache.dart`, esquema v9, máx. 16 feeds, TTL 30 min, copia local si falla la red. Tests `browse_cache_test.dart` (4). Nota: es TTL + stale-if-error, **no** revalidación en segundo plano |
| Pruebas de regresión | HECHO | Suite completa verde (ver abajo) |
| Captura Fedora de carátulas | PARCIAL | Captura 1 y 2: hero con banners reales (Death Note, Jujutsu Kaisen) y fila «En emisión» con carátula de One Piece. Log: 0 `home_artwork_failed`. **Filas Populares/Tendencias no vistas**: requieren desplazamiento y no hay herramienta de entrada sin permisos de sistema |

Capturas: `.ai-local/oc02-fedora/home-fedora-1.png`, `home-fedora-2.png`.

## Sección 2 — Episodios (índice real)

| Punto | Estado | Evidencia |
|---|---|---|
| Índice público sin cuenta | HECHO | `lib/data/kitsu/kitsu_episode_index.dart` (Kitsu: `/mappings` AniList→Kitsu y `/anime/{id}/episodes`) |
| Smoke en vivo | PASS | `KONGROO_TEST_KITSU_LIVE=true flutter test test/data/kitsu/kitsu_live_smoke_test.dart`: One Piece (AniList 21) con episodios numerados |
| Mapa de fuentes separado | HECHO (contrato) | `EpisodeIndexProvider` (dominio) ≠ `MetadataProvider` (AniList) ≠ `PlaybackProviderManager` (fuentes). Un episodio indexado no es reproducible |
| Conexión a la ficha | HECHO | `anime_detail_page.dart` pide el índice tras los metadatos; `_EpisodesTab` muestra solo filas del índice, con «Cargar más» y estados de carga, error y ausencia |
| Texto honesto | HECHO | «N de M indexados · fuentes sin verificar» / «AniList anuncia N episodios, pero no hay índice verificado» |
| Sin dependencia de `streamingEpisodes` | HECHO | El índice no usa `streamingEpisodes`; la ficha ya no fabrica tarjetas 1..N |
| Verificación visual de la ficha en Fedora | NO HECHO | Requiere navegar a una ficha (clic/teclado). Sin entrada sintética no es posible sin cambiar permisos |

Pruebas: `test/data/kitsu/kitsu_episode_index_test.dart` (5), `test/widget_test.dart` (ficha con índice fixture determinista, sin red).

## Sección 3 — Continuar viendo

| Punto | Estado | Evidencia |
|---|---|---|
| Lectura de progreso real | HECHO | `CatalogService.listProgress()` → `CatalogHomeSource._continueWatching`: solo progreso en curso (`positionMs > 0`, no completado) de títulos en biblioteca |
| Degradación | HECHO | Si falla la lectura, la sección queda vacía y el resto de Home sigue |
| Diseño aprobado | CONSERVADO | Se reutiliza la sección `Continue watching` existente de `home_sections.dart`; no se reconstruyó la UI |
| Reanudar desde Home | PENDIENTE | `showResume` sigue mostrando el mensaje «No hay una fuente de reproducción conectada» |

Pruebas: `home_data_test.dart` («continue watching uses only saved in-progress local episodes», «a failed progress read…»).

## Sección 4 — Modularidad y limpieza (R0)

Detalle en `OC02-R0-INVENTORY.md`. Resumen: sin ficheros muertos por importación (solo `main.dart`), sin dependencias retirables con evidencia, **ninguna eliminación**. `AnimesDigital` queda marcado como candidato no verificado y su retiro requiere decisión del propietario.

Comprobador de imports desde la raíz: dominio sin violaciones (37 ficheros). `scripts/test_check_imports.sh`: 2 positivos y 12 negativos pasaron.

## Sección 5 — Fuentes y reproducción (R3–R5)

| Gate | Estado |
|---|---|
| R3 proveedores/hosts | Contratos y manager existentes; **0 fuentes verificadas**. Sin proveedor de fuentes legítimo confirmado en esta sesión |
| R4 video visible con motor existente | **PASS (control local)**: `media_kit/libmpv` mostró video en Fedora con `.ai-local/f2.2/fixtures/spike.mp4` (MPEG-4 320×180, 8 s, AAC). Captura `spike-video-2.png`: barras de color en movimiento y progreso 00:08/00:08. Log sin errores de decodificación. **Audio no verificado de oído** |
| R4 fuente externa | NO HECHO. Sin fuente externa verificada con frame |
| Cierre seguro | PASS en el spike (proceso terminado, sin excepciones en el log) |

Probes externos registrados en esta sesión:
- Jikan (`api.jikan.moe`): timeout en dos intentos (25 s y 30 s). No se reintenta.
- Kitsu (`kitsu.io/api/edge`): HTTP 200 en búsqueda, episodios y mapeos.
- AniList GraphQL y CDN `s4.anilist.co`: HTTP 200.
- MyAnimeList web: HTTP 200 (no usado como fuente de episodios).

## Sección 6 — Reproductor protegido

No se modificó `media_kit_spike_engine.dart`, `SpikePlayerPage`, `provider_playback_route.dart` ni `lib/app/player/*`. Dependencias de motor sin cambios. La suite de player pasa sin cambios en sus tests.

## Sección 7 — Autonomía y continuidad

Este documento y `AI_HANDOFF.md` se actualizan en cada apartado. No hay commits ni pushes.

## Resultados de verificación (esta sesión)

| Comprobación | Resultado |
|---|---|
| `dart format --set-exit-if-changed lib test` | exit 0 |
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub` (suite completa) | exit 0 · **320 pasan · 8 opt-in omitidas** (7 AniList/player + 1 Kitsu live) |
| Smoke Kitsu live (`--dart-define=KONGROO_TEST_KITSU_LIVE=true`) | 1 pasa |
| `dart run scripts/check_imports.dart --root .` (desde raíz) | Sin violaciones |
| `scripts/test_check_imports.sh` | exit 0 |
| `python3 tools/ai/memory.py check` | exit 0, `[]` |
| `git diff --check` | OK |
| `pubspec.lock` | Sin cambios |

Antes de esta continuación: 305 pasan / 7 omitidas. Después: 320 / 8.

## Gates

| Gate | Estado | Motivo |
|---|---|---|
| R0 | PARCIAL | Inventario hecho. Sin eliminaciones demostradas. Decisión pendiente sobre `AnimesDigital` |
| R1 | PARCIAL | Home y carátulas en Fedora: hero y una fila. Faltan filas inferiores y la vista de error/caché offline en pantalla |
| R2 | PARCIAL | Índice real y ficha conectados (tests + smoke live). Falta verificación visual de la ficha y reproducción por fuente |
| R3 | NO CUMPLIDO | 0 fuentes verificadas; no hay dos familias independientes |
| R4 | PARCIAL | Video visible con motor existente (control local). Falta fuente externa y audio verificado |
| R5 | NO INICIADO | Requiere recorrido completo de usuario en Fedora |
| Android / Windows | NO EJECUTADO | No hay runners |

## Mapa de fuentes (estado actual)

| Fuente / componente | registered | can_list_episodes | can_resolve_host | media_http_ok | frame_confirmed | estado |
|---|---|---|---|---|---|---|
| AniList (metadatos) | sí | n/a | n/a | sí (CDN 200) | n/a | operativo |
| Kitsu (índice) | sí | sí (live) | n/a | n/a | n/a | operativo, sin fuentes |
| AnimesDigital (fuente) | sí | no | no | no (S0-S) | no | no verificado |
| DirectMediaHostResolver | sí | n/a | sí (HTTPS directo) | n/a | local sí | solo medios directos |
| Fixture local (spike) | n/a | n/a | n/a | local | **sí** | control de motor |

## Próxima acción técnica ejecutable

1. **Ficha en Fedora:** abrir una ficha con índice (One Piece, AniList 21) y capturar `_EpisodesTab` con filas del índice. Requiere una entrada sintética o un inicio de la app que abra la ficha directamente; ver `CatalogHomeSource`/`AnimeDetailPage`.
2. **Continuar viendo en Fedora:** crear progreso en `.ai-local/oc02-fedora/home.sqlite` para un título de biblioteca y capturar Home.
3. **R3:** investigar un índice público de fuentes con licencia verificada antes de añadir cualquier adaptador; hasta entonces no registrar fuentes.
4. **Decisión del propietario:** retirar o archivar `AnimesDigital` (sección 4).
5. **Persistir caché de episodios** (hoy solo en memoria) y añadir cobertura de fallos del adaptador de `CatalogService.listEpisodes` (hoy cubierto solo el caso feliz con fixture).

## Checkpoint OC-03 (continuación) — 2026-11-16

- Base: `main` @ `6cc3e5e`, sin commits ni push. Cambios previos conservados.
- `flutter analyze --no-pub`: el aviso previo quedaba en `tool/external_hls_probe_app.dart` (harness sin evidencia visual). Se eliminó ese archivo; análisis limpio.
- Continuar viendo: la tarjeta ya no abre un diálogo informativo. Tocarla llama a `onResume` → `CatalogHomeSource`/`HomeEpisode.playback` (`PlaybackEpisode` derivado de `episode:N` + identidad del anime) → `_resumeEpisode` → `_playEpisode` (flujo de fuentes existente). Sin fuente, muestra el mensaje ya existente y conserva el progreso. El botón de detalles abre la ficha.
- Limitación: `ProviderPlaybackRoute`/`SpikePlayerModule` no reciben posición inicial; el salto a la posición guardada NO está conectado (requiere tocar archivos protegidos con causa demostrada). Pendiente.
- Pruebas: `test/home` 26/26; `test/catalog` + `widget_test` 6/6; suite completa 322 aprobadas, 8 omitidas, 0 fallos.
- Gates: J1 parcial (Home/catálogo por pruebas; sin verificación gráfica nueva), J3 parcial (acción conectada, reanudación en posición pendiente), J4/J5 BLOQUEADOS (sin fuente externa legítima verificada; AnimesDigital desactivado; probe visual de ventana Wayland no obtenido), J6 pendiente.
- Siguiente acción ejecutable: conectar posición inicial mediante un parámetro opcional en la ruta de reproducción tras aprobar el cambio en archivos protegidos; o buscar una fuente legítima con URL suministrada por el propietario.

## Checkpoint OC-03 (posición de reanudación) — 2026-11-16

- Implementado: `SpikePlayerModule.open(startPosition:)` (espera la primera duración y luego hace seek; límite 30 s), `ProviderPlaybackRoute.startPosition`, `CatalogHomeSource`→`HomeEpisode.positionMs`→`_resumeEpisode`→`_playEpisode(startPosition:)`.
- Hallazgo real: un seek emitido antes de que libmpv reporte duración se pierde (primera posición observada 0,107 s). Por eso el módulo espera duración.
- Prueba: `test/player/resume_start_position_integration_test.dart` (opt-in `KONGROO_TEST_LOCAL_MEDIA=1`) PASA con el motor real: tras seek a 3 s y play, la primera posición positiva es ≥ 2,5 s.
- Límite: el camino completo del módulo no se prueba en headless (crear `VideoController` sin GPU bloquea `open`). Verificación visual pendiente.
- Pruebas: suite 322 aprobadas, 9 omitidas, 0 fallos; `flutter analyze` limpio.
- Fuentes de anime: sin cambio. No hay fuente externa legítima verificada; no se implementó ningún proveedor nuevo.

## Checkpoint OC-03 (fuentes definidas por el usuario) — 2026-11-16

- Implementado: proveedor `user-defined` (`lib/data/player/providers/user_sources/`), que sirve solo URLs https que el usuario registra en un JSON local (`KONGROO_USER_SOURCES`). Usa el manager, `DirectMediaHostResolver` y el motor existentes. README incluido.
- Emparejamiento: ID local o `<proveedor>:<id>` (p. ej. `anilist:21`), mismo número de episodio. Sin coincidencia → vacío.
- Registro: `PlaybackProvidersModule.open(userSources:)`; `main.dart` lee la variable de entorno y no registra nada si falta.
- Sin sitios de terceros: no se integró AnimesDigital ni otros sitios. El permiso y licencia alegados no se pueden verificar desde el proyecto.
- Pruebas: `test/data/player/providers/user_defined_playback_provider_test.dart` (parser, emparejamiento, registro). Suite 326 aprobadas, 9 omitidas, 0 fallos; análisis limpio.
- Pendiente: reproducción visual de una URL registrada por el usuario (gate J5); requiere una URL real del usuario.
