# OC-02 · R0 — Inventario y limpieza controlada

**Fecha:** 2026-11-16 · **Base:** `6cc3e5e` (sin commits nuevos) · **Árbol:** cambios sin stage, ver `OC02-EXECUTION-STATUS.md`

## Método (reproducible)

1. Ficheros sin importadores: para cada `app/lib/**/*.dart` se buscó su nombre base en `lib/` y `test/` (`grep -rl`). Resultado: **solo `lib/main.dart`** (entrypoint). No hay ficheros muertos por importación.
2. Dependencias: para cada entrada de `app/pubspec.yaml` se buscó `package:<nombre>/` en `lib`, `test` y `tool`.
3. Proveedores: se revisó el composition root `app/lib/data/player/providers/playback_providers_module.dart` y quién referencia cada adaptador.
4. Retiros pasados ya documentados (S0-A, S0-R, S0-S): Miruro, AnimeHeaven y su resolutor específico. No se reintroducen.

## Tabla conservar / reparar / retirar / archivar

| Ruta | Decisión | Evidencia |
|---|---|---|
| `lib/data/anilist/*` | **Conservar y reparar** | Causa de feed suprimido corregida (tolerancia por entrada); caché de browse; tests 25+ |
| `lib/data/kitsu/kitsu_episode_index.dart` | **Nuevo, conservar** | Índice público sin cuenta; smoke en vivo PASS (One Piece, AniList 21 → Kitsu 12) |
| `lib/data/player/providers/animesdigital/*` | **Conservar, marcar no verificado** | Registrado como candidato en `PlaybackProvidersModule`. Scraper de un portal de catálogo; S0-S: manifiesto 200 y sin frame. No se retira todavía porque sus contratos y tests siguen en uso y la sustitución por un índice legítimo de fuentes aún no existe. **Requiere decisión del propietario** |
| `lib/data/player/providers/hosts/direct_media_host_resolver.dart` | **Conservar** | Resolutor genérico HTTPS MP4/HLS/DASH; `DirectMediaHostResolver` usado por el composition root y por tests de host |
| `lib/data/player/providers/mock/mock_playback_provider.dart` | **Conservar (fake)** | Solo lo usan tests de contrato y del spike. Moverlo a `test/` sería una refactorización posterior, sin impacto funcional |
| `lib/data/player/engine/*`, `lib/app/player/*`, `media_kit_spike_engine.dart`, `SpikePlayerPage` | **Protegidos, sin cambios** | Regresiones de player verdes; spike de video visible verificado en Fedora (ver estado) |
| `lib/main_player_spike.dart` | **Conservar** | Harness de la prueba visual del motor |
| `lib/data/aniskip/*`, `lib/data/opensubtitles/*` | **Conservar** | Consumidores activos en el reproductor (subtítulos y saltos) |
| `lib/data/metadata/fake_metadata_provider.dart` | **Conservar (demo)** | Modo `useDemoProvider` y tests de catálogo |
| `docs/ai-system/archive/*`, misiones S0 y S0-R | **Archivar (no tocar)** | Documentación histórica que explica fallos |

## Dependencias (`app/pubspec.yaml`)

| Paquete | Estado | Motivo |
|---|---|---|
| `dio`, `drift`, `sqlite3`, `path_provider`, `flutter_secure_storage`, `material_ui` | En uso | Importados por `lib/` |
| `media_kit`, `media_kit_video`, `media_kit_libs_linux` | En uso | Motor protegido |
| `media_kit_libs_video` | **Conservar** | Sin importación Dart directa, pero empaqueta libmpv para las plataformas no Linux del núcleo. Retirarlo rompería Android/Windows. No se retira sin prueba de build |
| `drift_dev`, `build_runner` | Herramientas | Regeneración de `app_database.g.dart` |

## Cambios de código realizados en R0

- **Ninguna eliminación.** No hay ficheros ni dependencias demostrados como muertos. Retirar código por estética habría sido contrario a la misión.

## Límites

- El análisis de símbolos no usados (métodos sin caller) no se ejecutó con herramienta dedicada; solo el de ficheros e imports.
- Plataformas Android y Windows no se compilaron; la decisión sobre `media_kit_libs_video` depende de ese build.
