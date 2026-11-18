# Refactorización modular de Kongroo · 2026-11-18

Auditoría, modularización incremental y verificación sin regresiones.
Rama: `refactor/modularizacion` (creada con snapshot
`394f1bd` del estado funcional acumulado; `main` intacto en `6cc3e5e`).

## FASE 0 — Línea base

- **Estado inicial:** 146 cambios sin confirmar (72 M, 66 ??, 8 D) — el
  trabajo acumulado de las misiones OC + ANILILI, con suite verde.
  Mecanismo de recuperación: snapshot completo en la rama de refactor
  antes de tocar nada; `.gitignore` ampliado con adjuntos locales
  (`.codex-attachments/`, `/*.zip` de la raíz).
- **Controles de línea base:** `flutter doctor -v` OK (Flutter
  3.50.0-0.4.pre aislado, Linux toolchain ✓); `flutter analyze` 0 issues;
  `dart analyze lib` 0; suite completa **401 aprobadas / 10 omitidas**;
  build Linux debug OK; import checker OK (32 límites player + 37 domain).
- **Preexistente detectado:** el gate `dart format` del `scripts/ci.sh`
  estaba en rojo (drift de formato en animegg/anizone/megaplay/parsers y
  tests, introducido en misiones anteriores). Corregido en el primer
  commit de esta fase.

## FASE 1 — Auditoría arquitectónica

- **Capas reales:** `app/` (UI: home, catalog, player), `application/`
  (catalog, player coordinator + manager), `data/` (anilist, kitsu,
  aniskip, local_db, metadata, opensubtitles, player, secure_storage,
  testing), `domain/`, `core/`, `settings/`. Sin imports UI→data (grep);
  pureza de dominio y límites de player verificados por el checker propio.
- **Duplicación (P2) — corregida:** tres helpers privados idénticos en
  semántica repetidos en 6 adapters (`_read`, `_check`, `_contractTitle`).
- **Monolitos (P2) — documentados, no divididos a propósito:**
  `spike_player_coordinator.dart` (1086 líneas) y
  `media_kit_spike_engine.dart` (969) concentran el contrato de
  serialización y el adaptador del motor; una división sin costuras medibles
  pondría en riesgo la única cadena N4-verificada. La misión prefiere una
  refactorización parcial bien probada.
- **Dependencias:** 4 «sin uso» aparentes eran falsos positivos
  (`drift_dev`/`build_runner` generan `app_database.g.dart`;
  `integration_test` usado en `integration_test/`; `media_kit_libs_video`
  aporta los binarios nativos de libmpv, sin import Dart por diseño).
- **Código muerto:** ninguno encontrado (`fake_metadata_provider`,
  `fake_sync_remote`, `mock_playback_provider` están referenciados por
  catálogo/tests/coordinador).
- **UI:** diseños aprobados intocados (home, ficha, reproductor).

## FASE 3 — Cambio incremental

**Commit `da87436` — `EpisodeSourceSupport`:**

- Nuevo módulo compartido `episode_source_support.dart` + 5 pruebas de
  caracterización (mapeo null→Empty, fallos de transporte→resultado,
  FormatException/ArgumentError→`invalidResponse`, cancelación exacta,
  normalización de título).
- Los seis adapters (allanime, animeav1, animegg, anizone, megaplay,
  miruro) migrados uno a uno, cada uno con su suite local en verde antes
  de pasar al siguiente (12+12+8+6+12+10).
- **Alineación documentada de comportamiento:** megaplay dejaba escapar
  `ArgumentError` al catch-all del adapter (`unavailable`); ahora lo mapea
  a `invalidResponse` — la clasificación semántica correcta para payloads
  malformados; ambos no cuentan para el circuito.
- Formato dart normalizado en los archivos afectados (gate CI de rojo a
  verde).

**Documentación (commit final):** README maestro de providers ampliado
(helpers compartidos en la cadena de arquitectura y en la guía «agregar
proveedor»); corrección factual del intro de `ARCHITECTURE.md`
(«no hay reproducción externa confirmada» → estado real N4 de seis
proveedores con video 1920×1080).

## FASE 7 — Verificación final

- `flutter analyze` / `dart analyze`: **0 hallazgos**.
- Suite completa: **406 aprobadas / 10 omitidas** (401 base + 5 de
  caracterización nuevas).
- `dart format --set-exit-if-changed lib test`: **0 cambios**.
- `scripts/ci.sh`: todos los gates en verde (GTK, memoria, IA tests,
  checker sintético, formato, análisis, dependencias, límites).
- **Motor real post-refactor:** build del arnés + reproducción de
  referencia megaplay (RESOLVED 7 → PLAY → SEEK-RESTORE 20 s → FRAME →
  ADVANCE 24274/1449629 → REOPEN) — la cadena refactorizada produce las
  mismas fuentes y el motor decodifica. Bundle por defecto
  (`lib/main.dart`) restaurado.
