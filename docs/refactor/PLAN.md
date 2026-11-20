# Plan autosuficiente — refactor con paridad

## 1. Resumen ejecutivo

Fecha: 2026-11-20 (America/Bogota). Rama exclusiva `refactor-modular`.
Objetivo: reorganizar sin alterar ninguna función, extractor, fuente, endpoint,
header, firma, clave persistida, pantalla, calidad ni dependencia.
El propietario autorizó comenzar movimientos en la sesión 2026-11-20. F1 inició;
`AnimeApp` fue movida a core/bootstrap. No iniciar F2 automáticamente.

Respaldo confirmado en `origin`:
`https://github.com/kurogamishuen15/AnimeApp-Dev.git`.
Commit `507368b177a1b096ae4cfae9f3c0094f658693c8`, etiqueta
`respaldo-pre-refactor`, ambos comprobados con ls-remote el 2026-11-20.
Los cambios de producto anteriores quedaron en ese commit sin alterar contenido.
No se tocó main/master ni se usó force. Hay documentación previa ajena sin commit;
conservarla y no incluirla por accidente. PROJECT_STATE/AI_HANDOFF anteriores no
se editaron: esta sesión solo permite docs/refactor y test; este PLAN es el
traspaso vigente de esta misión. La etiqueta fija esta captura, no un
estado funcionalmente verde.

### Entorno y comandos obligatorios

Desde `/home/kyouma/Vídeos/PROYECTO ANIME/app`:

```bash
unset FLUTTER_ROOT
export PUB_CACHE='/home/kyouma/Vídeos/PROYECTO ANIME/.ai-local/pub-cache'
export PATH='/home/kyouma/Vídeos/PROYECTO ANIME/.ai-local/toolchains/flutter-3.47.9/bin:'"$PATH"
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --timeout 15s --reporter expanded
flutter test --no-pub --reporter expanded test/refactor/parser_characterization_test.dart test/data/player/providers/refactor_characterization_test.dart
flutter build linux --debug --no-pub
```

No usar el SDK beta `.ai-local/toolchains/flutter`: exige otro test_api.
No actualizar pubspec/lock. Analyze y tests pueden ejecutarse aquí; Linux build
puede intentarse pero actualmente falla en Dart, no se acreditó falta de librerías.
Android no verificable (SDK y scaffold ausentes), Windows sin scaffold/toolchain,
macOS/iOS/web no preparados en el proyecto; validación manual futura del dueño.
No instalar librerías de Fedora ni toolchains globales.

Estado de aceptación: pub get resuelto; golden nuevos 11 pasan / 1 omitido (firma temporal AllAnime), cobertura por
todas las fuentes aún incompleta; análisis con errores previos; varios tests no
compilan y algunos timeout. **No certificar paridad total ni recomendar cierre
funcional de Fase 0.** La entrega documental puede confirmarse con esos límites.
BASELINE y logs contienen resultados por carpeta y reglas exactas; no corregirlos
como parte de mover archivos.

## 2. Estructura objetivo y mapa completo

```text
app/lib/
  main.dart                         # entrada, conserva firma/comportamiento
  core/{bootstrap,theme,...}/        # infraestructura y Result existentes
  data/
    services/{anilist,kitsu,player}/
    repositories/                   # conservar contratos existentes
    local_db/                       # NO migrar esquema ni claves
  domain/                           # modelos/contratos existentes conservados
  features/
    home/{view,view_model,widgets}/
    search/{view,view_model,widgets}/
    detail/{view,view_model,widgets}/
    library/{view,view_model,widgets}/
    player/{view,view_model,widgets}/
    settings/{view,view_model,widgets}/
  shared/                           # solo componentes realmente compartidos
  sources/                          # adaptadores existentes, un módulo por fuente
  _legacy/                          # reservado, vacío; no enviar código por sospecha
```

No añadir directorios vacíos por estética ni otro motor/registry/contrato si existe.
El mapa individual de **todos** los archivos y la matriz individual de **todos**
los contratos se incluyen literalmente más abajo. Archivos fuera de lib se
conservan; generated .g.dart no se divide a mano. El mapa es propuesta, no
migración aprobada ni realizada. Se comprueba unicidad de destinos antes de mover.
Las APIs públicas se mantienen mediante actualización coordinada de imports;
si se consumen fuera del repo, conservar export shim y decidir compatibilidad.

## 3. Lista de cambios por tipo

- Mover: mapa completo al final, con git mv, ajustando solo imports/exports/part.
- Dividir: archivos no generados >250 líneas y clases UI >120 en AUDITORIA;
  extraer por responsabilidad, no reescribir cuerpos. Proveedores: solo mover.
- View_model: coordinación de catalog_home_page.dart:145-231; separar detalles,
  selección y progresos preservando orden, cancelación y mounted.
- Repositorio: CatalogService y contratos ya existen; extraer solo donde una vista
  los salta, sin crear repositorios que se llamen entre sí. DB y claves inmóviles.
- Constantes/tokens: mover valores actuales exactos de UI a core/theme sin cambiar
  colores, tipografía, distancias, textos ni duraciones.
- Recursos: lifecycle de isolate en main requiere corrección funcional aparte;
  no confundirlo con un movimiento. Conservar lease/dispose del player.
- Errores: preservar Result y PlaybackProviderResult; no normalizar respuestas de
  scrapers ni cambiar mensajes/semántica para hacer tests verdes.
- DI/estado: conservar composición manual/StatefulWidget/ValueNotifier; extraer
  ownership sin instalar Riverpod/go_router/freezed/very_good_analysis.
- Tests: ampliar golden de cada módulo SIN TEST antes de su fase, fixtures sin
  secretos y sin acceso de red por defecto; no regenerar expectativas para pasar.

## 4. Fases ordenadas de menor a mayor riesgo

Para cada fase, los archivos exactos son las filas del mapa cuyo origen pertenece
al prefijo indicado; toda excepción se enumera. Esto fija el alcance sin selección
implícita. Todos los contratos afectados son las filas de matriz del mismo origen.

| Fase | Objetivo y archivos exactos | Se mueve / se edita | Validación y terminada | Reversión |
| --- | --- | --- | --- | --- |
| F0 documental | docs/refactor/** y tests nuevos refactor | crear inventario/auditoría/plan/golden; sin lib | logs honestos, backup remoto verificado, golden pasan, gaps explícitos | revert del commit docs; conserva respaldo |
| F0-B prerrequisitos | playback_provider_manager.dart, jkanime_playback_provider.dart, registry/provider_spec.dart, main.dart y tests indicados por analyze | NO ejecutar; correcciones funcionales requieren orden independiente | baseline compilable y golden por fuente antes de movimientos | revert del commit específico; nunca mezclar con movimiento |
| F1 núcleo visual | app/lib/app/theme/** y app/lib/app/anime_app.dart | git mv según mapa; imports exactos; no cambiar valores | format solo cambiados, analyze sin nuevos, widget/home tests y golden, build si línea base lo permite | git revert COMMIT_F1 |
| F2 home/búsqueda | app/lib/app/home/**; catalog_search_page.dart, catalog_home_page.dart | primero solo mover; NO extraer coordinación aún | home/catalog/widget tests, navegación y vuelta preservadas; golden | git revert COMMIT_F2 |
| F3 detalle/biblioteca | app/lib/app/catalog/detail/** y demás app/catalog excepto catalog_module.dart y archivos F2 | mover; extraer widgets en commits separados por archivo de AUDITORIA | catalog tests, estado guardado y episodios sin cambio; logs y capturas comparables | git revert COMMIT_F3 |
| F4 coordinación catálogo | catalog_home_page movido; app/lib/application/catalog/**; app/lib/app/catalog/catalog_module.dart | extraer método por método a view_model manteniendo firmas/orden; conservar servicio existente | búsquedas canceladas, cierre durante await, errores, favoritos e historial; suite catálogo | git revert COMMIT_F4 |
| F5 UI reproductor | app/lib/app/player/** | mover a features/player/view; separar widgets en commits propios | todos test/player sin nuevos fallos, seek, stop/play, server switch, audio/subs; requiere evidencia nativa y visual | git revert COMMIT_F5 |
| F6 coordinación player | app/lib/application/player/** | mover a view_model, nombres y cuerpos idénticos | application/player tests negativos y concurrentes, cambio conserva Duration exacto | git revert COMMIT_F6 |
| F7 motor | app/lib/data/player/engine/** | mover a data/services/player; plataforma condicional y native intactos | engine/native tests, lifecycle, un solo Player, build Linux y revisión independiente si se autoriza | git revert COMMIT_F7 |
| F8 servicios catálogo | app/lib/data/anilist/** y app/lib/data/kitsu/** | solo git mv e imports; JSON, endpoints/cabeceras intactos | golden de parseo, rate/cache/offline existentes, hashes sin imports | git revert COMMIT_F8 |
| F9 fuentes | app/lib/data/player/providers/** | solo git mv a sources, un proveedor por mini-commit; cuerpo idéntico | golden de cada fuente obligatorio antes, fixtures negativos, requests headers/orden exactos, failover | git revert COMMIT_F9_por_fuente |
| F10 paridad final | toda la matriz y mapa | ningún cambio de producto; verificar cada contrato | sin faltantes, deps iguales, DB/claves igual, flujos clave y plataformas con evidencia separada | revert solo fase causante |
| F11 rendimiento | solo tras F10 acreditada y autorización | propuestas de sección 7; commit perf por medida | profile antes/después, golden idénticos, opción con default actual si cambia conducta | git revert COMMIT_PERF |

En **cada mini-fase** desde app: `dart format` solo archivos movidos/editados,
`flutter analyze --no-pub`, `flutter test --no-pub --concurrency=1`, golden
focalizados y `flutter build linux --debug --no-pub`. No aceptar errores nuevos
respecto al registro por regla/archivo, no solo por cantidad. Un build que falla
antes de compilar la fase no demuestra su corrección; dejar gate bloqueado.
Android se sustituye por estas puertas en este host; no se considera validado.
Comparar cada contrato y cada dependencia, revisar diff sin imports y no cambiar
expectativas. Si falla dos veces, detener esa fase, revertir solo su commit propio,
anotar BLOQUEOS y no avanzar a dependientes. No usar reset --hard ni revertir
trabajo previo. Un commit por mini-fase, Conventional Commits, push normal de
refactor-modular tras validar. No publicar ni tocar main/master.

## 5. Matriz de paridad

Las filas individuales se incluyen al final, con destino y estado pendiente de
revalidación tras movimiento. Hoy todo el producto está presente e idéntico al
respaldo; eso no demuestra que funcione. No reemplazar esta matriz por un conteo.
Rutas y claves dinámicas se preservan mediante la expresión completa y el hash
del módulo, sin cambiar el valor derivado ni los datos ya existentes.

## 6. Riesgos y decisiones del propietario

1. ¿Autorizar una tarea funcional separada para corregir los errores previos del
   manager, JKAnime, registry y bootstrap antes de intentar movimientos?
2. ¿Mantener probeLoop sin referencias en su ubicación o trasladarlo a _legacy?
   Por defecto se conserva; no borrarlo ni ejecutarlo por inferencia.
3. ¿Revisar las duplicaciones literales de DUPLICADOS.md? No unificar lógica
   entre scrapers ni borrar paquetes por cero imports directos.
4. ¿Mantener indefinidamente exports de compatibilidad si existen consumidores
   externos de rutas package? No cambiar firma pública.
5. ¿Cuándo proveer/verificar scaffolds Android/Windows y SDKs en sus equipos?
   No crearlos ni instalar SDK aquí sin orden.

Riesgos abiertos: cobertura incompleta de fuentes, parseo AST parcial por sintaxis
previa, tests con timeout, lifecycle native/GUI no observado, y perfiles sin medir.
Todas las propuestas de arquitectura son reversibles; ninguna decisión abierta
se convierte en aprobada porque figure aquí.

## 7. Optimización para poca RAM (separada)

Medir profile en inicio/home/búsqueda/detalle y 10 min de reproducción, RSS,
arranque, jank y tamaño por plataforma; marcar no medido cuando falte entorno.
Ya existe límite de caché 120/48 MiB; conservarlo como default. Evaluar decode
al tamaño de portada, paginación/retención de páginas, rebuild selectivo y solo
mover parseo pesado a isolate si el perfil lo justifica. Medir keep-alive y límite
de concurrencia alrededor de parsers, sin tocar su lógica. Buffer configurable
usa el API real bufferSize de media_kit; no reducirlo en silencio. Conservar
aceleración hardware y un solo Player; medir dispose y servidor con seek exacto.
Modo bajo consumo opcional agrupa límites, animación y polling minimizado;
default actual y automatismo por low RAM solo después de pruebas de plataforma.
No borrar dependencias/assets/fuentes; listarlos para decisión. Ver RENDIMIENTO.

## 8. Registro de progreso

| Fase | Estado | Commit | Fecha | GitHub |
| --- | --- | --- | --- | --- |
| Respaldo producto previo | verificado, sin afirmar baseline verde | 507368b177a1b096ae4cfae9f3c0094f658693c8 | 2026-11-20 | rama + etiqueta verificadas |
| F0 documentación/plan | entrega documental; límites de cobertura y gates abiertos | HEAD de la entrega: docs: fase 0 y planificación completa | 2026-11-20 | push normal requerido y verificado al cerrar; SHA por git log del archivo |
| F0 caracterización completa | parcial: 11 golden pasan / 1 omitido; JKAnime bloqueado | incluido en entrega documental | 2026-11-20 | según commit final |
| F0-B prerrequisitos | pendiente de decisión | — | — | no |
| F1.1 bootstrap | parcial: movimiento realizado; validación total bloqueada por baseline | commit F1.1 | 2026-11-20 | push normal |
| F1 tema visual | pendiente: tema vive dentro de HomeAppearance; revisar destinos sin alterar diseño | — | — | no |
| F2–F10 refactor/paridad | pendientes; no avanzar automáticamente | — | — | no |
| F11 optimización | pendiente de paridad y mediciones | — | — | no |

## 9. Mapa individual completo

# Mapa completo propuesto; ningún movimiento ejecutado

Incluye archivos versionados y no ignorados presentes al generar. Backups locales y builds ignorados quedan fuera.

| Actual | Destino propuesto | Acción |
| --- | --- | --- |
| .agents/skills/kongroo-deep-audit/SKILL.md | .agents/skills/kongroo-deep-audit/SKILL.md | conservar |
| .codex/agents/arquitecto.toml | .codex/agents/arquitecto.toml | conservar |
| .codex/agents/auditor_accesibilidad.toml | .codex/agents/auditor_accesibilidad.toml | conservar |
| .codex/agents/auditor_arquitectura.toml | .codex/agents/auditor_arquitectura.toml | conservar |
| .codex/agents/auditor_codigo.toml | .codex/agents/auditor_codigo.toml | conservar |
| .codex/agents/auditor_contratos.toml | .codex/agents/auditor_contratos.toml | conservar |
| .codex/agents/auditor_dependencias.toml | .codex/agents/auditor_dependencias.toml | conservar |
| .codex/agents/auditor_release.toml | .codex/agents/auditor_release.toml | conservar |
| .codex/agents/auditor_rendimiento.toml | .codex/agents/auditor_rendimiento.toml | conservar |
| .codex/agents/backend.toml | .codex/agents/backend.toml | conservar |
| .codex/agents/datos.toml | .codex/agents/datos.toml | conservar |
| .codex/agents/devops.toml | .codex/agents/devops.toml | conservar |
| .codex/agents/diagnostico_logs.toml | .codex/agents/diagnostico_logs.toml | conservar |
| .codex/agents/documentacion.toml | .codex/agents/documentacion.toml | conservar |
| .codex/agents/frontend.toml | .codex/agents/frontend.toml | conservar |
| .codex/agents/gestor_cola.toml | .codex/agents/gestor_cola.toml | conservar |
| .codex/agents/investigador.toml | .codex/agents/investigador.toml | conservar |
| .codex/agents/monitoreo.toml | .codex/agents/monitoreo.toml | conservar |
| .codex/agents/planificador.toml | .codex/agents/planificador.toml | conservar |
| .codex/agents/qa.toml | .codex/agents/qa.toml | conservar |
| .codex/agents/seguridad.toml | .codex/agents/seguridad.toml | conservar |
| .codex/agents/ux_ui.toml | .codex/agents/ux_ui.toml | conservar |
| .gitignore | .gitignore | conservar |
| AGENTS.md | AGENTS.md | conservar |
| ARCHITECTURE.md | ARCHITECTURE.md | conservar |
| CHANGELOG.md | CHANGELOG.md | conservar |
| CONTRIBUTING.md | CONTRIBUTING.md | conservar |
| KONGROO_AUDITORIA_GITHUB_Y_ANIKENTV_2026-11-16.md | KONGROO_AUDITORIA_GITHUB_Y_ANIKENTV_2026-11-16.md | conservar |
| KONGROO_OPENCODE_MISION_OC02_RECUPERACION_Y_FUENTES_2026-11-16.md | KONGROO_OPENCODE_MISION_OC02_RECUPERACION_Y_FUENTES_2026-11-16.md | conservar |
| Kongroo-F2.2-Auditoria-v2.zip | Kongroo-F2.2-Auditoria-v2.zip | conservar |
| Kongroo_Home_Referencia_Aprobada.png | Kongroo_Home_Referencia_Aprobada.png | conservar |
| PROGRESS.md | PROGRESS.md | conservar |
| PROJECT_PLAN.md | PROJECT_PLAN.md | conservar |
| README.md | README.md | conservar |
| RELEASING.md | RELEASING.md | conservar |
| ROADMAP.md | ROADMAP.md | conservar |
| TECH_DECISIONS.md | TECH_DECISIONS.md | conservar |
| TESTING.md | TESTING.md | conservar |
| app/.gitignore | app/.gitignore | conservar |
| app/.gitkeep | app/.gitkeep | conservar |
| app/README.md | app/README.md | conservar |
| app/analysis_options.yaml | app/analysis_options.yaml | conservar |
| app/drift_schemas/schema_v1.sql | app/drift_schemas/schema_v1.sql | conservar |
| app/drift_schemas/schema_v2.sql | app/drift_schemas/schema_v2.sql | conservar |
| app/drift_schemas/schema_v3.sql | app/drift_schemas/schema_v3.sql | conservar |
| app/drift_schemas/schema_v4.sql | app/drift_schemas/schema_v4.sql | conservar |
| app/drift_schemas/schema_v5.sql | app/drift_schemas/schema_v5.sql | conservar |
| app/integration_test/anime_playback_live_test.dart | app/integration_test/anime_playback_live_test.dart | conservar |
| app/lib/README.md | app/lib/README.md | conservar |
| app/lib/app/README.md | app/lib/app/README.md | conservar |
| app/lib/app/anime_app.dart | app/lib/core/bootstrap/anime_app.dart | movido en F1.1 |
| app/lib/app/catalog/README.md | app/lib/features/home/view/catalog_README.md | mover |
| app/lib/app/catalog/anime_detail_page.dart | app/lib/features/detail/view/anime_detail_page.dart | mover |
| app/lib/app/catalog/catalog_home_page.dart | app/lib/features/home/view/catalog_home_page.dart | mover |
| app/lib/app/catalog/catalog_module.dart | app/lib/features/home/view_model/catalog_module.dart | mover |
| app/lib/app/catalog/catalog_search_page.dart | app/lib/features/search/view/catalog_search_page.dart | mover |
| app/lib/app/catalog/confirm_completed_status.dart | app/lib/features/home/view/confirm_completed_status.dart | mover |
| app/lib/app/catalog/detail/README.md | app/lib/features/detail/widgets/README.md | mover |
| app/lib/app/catalog/detail/anime_detail_header.dart | app/lib/features/detail/widgets/anime_detail_header.dart | mover |
| app/lib/app/catalog/detail/anime_detail_tab_content.dart | app/lib/features/detail/widgets/anime_detail_tab_content.dart | mover |
| app/lib/app/catalog/detail/anime_detail_tabs.dart | app/lib/features/detail/widgets/anime_detail_tabs.dart | mover |
| app/lib/app/catalog/local_library_page.dart | app/lib/features/home/view/local_library_page.dart | mover |
| app/lib/app/catalog/playback_resolution_message.dart | app/lib/features/home/view/playback_resolution_message.dart | mover |
| app/lib/app/home/README.md | app/lib/features/home/view/README.md | mover |
| app/lib/app/home/home_appearance.dart | app/lib/features/home/view/home_appearance.dart | mover |
| app/lib/app/home/home_artwork.dart | app/lib/features/home/view/home_artwork.dart | mover |
| app/lib/app/home/home_artwork_diagnostics.dart | app/lib/features/home/view/home_artwork_diagnostics.dart | mover |
| app/lib/app/home/home_card_actions.dart | app/lib/features/home/view/home_card_actions.dart | mover |
| app/lib/app/home/home_data.dart | app/lib/features/home/view/home_data.dart | mover |
| app/lib/app/home/home_hero.dart | app/lib/features/home/view/home_hero.dart | mover |
| app/lib/app/home/home_icons.dart | app/lib/features/home/view/home_icons.dart | mover |
| app/lib/app/home/home_score_badge.dart | app/lib/features/home/view/home_score_badge.dart | mover |
| app/lib/app/home/home_screen.dart | app/lib/features/home/view/home_screen.dart | mover |
| app/lib/app/home/home_sections.dart | app/lib/features/home/view/home_sections.dart | mover |
| app/lib/app/home/home_typography.dart | app/lib/features/home/view/home_typography.dart | mover |
| app/lib/app/player/README.md | app/lib/features/player/view/README.md | mover |
| app/lib/app/player/audio_track_selector.dart | app/lib/features/player/view/audio_track_selector.dart | mover |
| app/lib/app/player/external_subtitle_search_panel.dart | app/lib/features/player/view/external_subtitle_search_panel.dart | mover |
| app/lib/app/player/media_kit_video_surface.dart | app/lib/features/player/view/media_kit_video_surface.dart | mover |
| app/lib/app/player/playback_route_session.dart | app/lib/features/player/view/playback_route_session.dart | mover |
| app/lib/app/player/player_demo_panel.dart | app/lib/features/player/view/player_demo_panel.dart | mover |
| app/lib/app/player/player_frame_timing_probe.dart | app/lib/features/player/view/player_frame_timing_probe.dart | mover |
| app/lib/app/player/player_nerd_panel.dart | app/lib/features/player/view/player_nerd_panel.dart | mover |
| app/lib/app/player/player_quality_panel.dart | app/lib/features/player/view/player_quality_panel.dart | mover |
| app/lib/app/player/player_subtitle_panel.dart | app/lib/features/player/view/player_subtitle_panel.dart | mover |
| app/lib/app/player/player_video_display.dart | app/lib/features/player/view/player_video_display.dart | mover |
| app/lib/app/player/player_video_display_panel.dart | app/lib/features/player/view/player_video_display_panel.dart | mover |
| app/lib/app/player/player_video_layout.dart | app/lib/features/player/view/player_video_layout.dart | mover |
| app/lib/app/player/player_window_controller.dart | app/lib/features/player/view/player_window_controller.dart | mover |
| app/lib/app/player/provider_playback_route.dart | app/lib/features/player/view/provider_playback_route.dart | mover |
| app/lib/app/player/skip_segment_panel.dart | app/lib/features/player/view/skip_segment_panel.dart | mover |
| app/lib/app/player/source_switch_panel.dart | app/lib/features/player/view/source_switch_panel.dart | mover |
| app/lib/app/player/spike_player_module.dart | app/lib/features/player/view/spike_player_module.dart | mover |
| app/lib/app/player/spike_player_page.dart | app/lib/features/player/view/spike_player_page.dart | mover |
| app/lib/app/player/spike_player_page_options.dart | app/lib/features/player/view/spike_player_page_options.dart | mover |
| app/lib/app/player/spike_window_close_gate.dart | app/lib/features/player/view/spike_window_close_gate.dart | mover |
| app/lib/application/README.md | app/lib/application/README.md | conservar |
| app/lib/application/catalog/README.md | app/lib/application/catalog/README.md | conservar |
| app/lib/application/catalog/catalog_service.dart | app/lib/application/catalog/catalog_service.dart | conservar |
| app/lib/application/player/README.md | app/lib/features/player/view_model/README.md | mover |
| app/lib/application/player/diagnostics/README.md | app/lib/features/player/view_model/diagnostics/README.md | mover |
| app/lib/application/player/diagnostics/playback_performance.dart | app/lib/features/player/view_model/diagnostics/playback_performance.dart | mover |
| app/lib/application/player/external_subtitles/README.md | app/lib/features/player/view_model/external_subtitles/README.md | mover |
| app/lib/application/player/external_subtitles/external_subtitle_service.dart | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | mover |
| app/lib/application/player/playback_progress_session.dart | app/lib/features/player/view_model/playback_progress_session.dart | mover |
| app/lib/application/player/playback_spike_contract.dart | app/lib/features/player/view_model/playback_spike_contract.dart | mover |
| app/lib/application/player/player_demo_session.dart | app/lib/features/player/view_model/player_demo_session.dart | mover |
| app/lib/application/player/providers/README.md | app/lib/features/player/view_model/providers/README.md | mover |
| app/lib/application/player/providers/playback_provider_manager.dart | app/lib/features/player/view_model/providers/playback_provider_manager.dart | mover |
| app/lib/application/player/providers/playback_source_cache.dart | app/lib/features/player/view_model/providers/playback_source_cache.dart | mover |
| app/lib/application/player/providers/provider_circuit_breaker.dart | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | mover |
| app/lib/application/player/skips/README.md | app/lib/features/player/view_model/skips/README.md | mover |
| app/lib/application/player/skips/automatic_skip_controller.dart | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | mover |
| app/lib/application/player/skips/skip_segment_service.dart | app/lib/features/player/view_model/skips/skip_segment_service.dart | mover |
| app/lib/application/player/source_switching/README.md | app/lib/features/player/view_model/source_switching/README.md | mover |
| app/lib/application/player/source_switching/playback_source_switch_service.dart | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | mover |
| app/lib/application/player/spike_player_coordinator.dart | app/lib/features/player/view_model/spike_player_coordinator.dart | mover |
| app/lib/core/README.md | app/lib/core/README.md | conservar |
| app/lib/core/errors/README.md | app/lib/core/errors/README.md | conservar |
| app/lib/core/errors/app_error.dart | app/lib/core/errors/app_error.dart | conservar |
| app/lib/core/logger/README.md | app/lib/core/logger/README.md | conservar |
| app/lib/core/logger/safe_logger.dart | app/lib/core/logger/safe_logger.dart | conservar |
| app/lib/core/result/README.md | app/lib/core/result/README.md | conservar |
| app/lib/core/result/result.dart | app/lib/core/result/result.dart | conservar |
| app/lib/data/README.md | app/lib/data/README.md | conservar |
| app/lib/data/anilist/README.md | app/lib/data/services/anilist/README.md | mover |
| app/lib/data/anilist/anilist_client.dart | app/lib/data/services/anilist/anilist_client.dart | mover |
| app/lib/data/anilist/anilist_detail_fields.dart | app/lib/data/services/anilist/anilist_detail_fields.dart | mover |
| app/lib/data/anilist/anilist_metadata_provider.dart | app/lib/data/services/anilist/anilist_metadata_provider.dart | mover |
| app/lib/data/anilist/drift_anilist_browse_cache.dart | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | mover |
| app/lib/data/anilist/offline_first_anime_catalog.dart | app/lib/data/services/anilist/offline_first_anime_catalog.dart | mover |
| app/lib/data/aniskip/README.md | app/lib/data/aniskip/README.md | conservar |
| app/lib/data/aniskip/aniskip_client.dart | app/lib/data/aniskip/aniskip_client.dart | conservar |
| app/lib/data/aniskip/aniskip_response_cache.dart | app/lib/data/aniskip/aniskip_response_cache.dart | conservar |
| app/lib/data/kitsu/README.md | app/lib/data/services/kitsu/README.md | mover |
| app/lib/data/kitsu/kitsu_episode_index.dart | app/lib/data/services/kitsu/kitsu_episode_index.dart | mover |
| app/lib/data/local_db/README.md | app/lib/data/local_db/README.md | conservar |
| app/lib/data/local_db/app_database.dart | app/lib/data/local_db/app_database.dart | conservar |
| app/lib/data/local_db/app_database.g.dart | app/lib/data/local_db/app_database.g.dart | conservar |
| app/lib/data/local_db/drift_anilist_detail_cache.dart | app/lib/data/local_db/drift_anilist_detail_cache.dart | conservar |
| app/lib/data/local_db/drift_anime_identity_repository.dart | app/lib/data/local_db/drift_anime_identity_repository.dart | conservar |
| app/lib/data/local_db/drift_local_library_repository.dart | app/lib/data/local_db/drift_local_library_repository.dart | conservar |
| app/lib/data/local_db/drift_playback_progress_repository.dart | app/lib/data/local_db/drift_playback_progress_repository.dart | conservar |
| app/lib/data/local_db/local_progress_repository.dart | app/lib/data/local_db/local_progress_repository.dart | conservar |
| app/lib/data/local_db/tables/README.md | app/lib/data/local_db/tables/README.md | conservar |
| app/lib/data/local_db/tables/anime_identity_entries.dart | app/lib/data/local_db/tables/anime_identity_entries.dart | conservar |
| app/lib/data/local_db/tables/anime_identity_relationships.dart | app/lib/data/local_db/tables/anime_identity_relationships.dart | conservar |
| app/lib/data/local_db/tables/external_anime_identifiers.dart | app/lib/data/local_db/tables/external_anime_identifiers.dart | conservar |
| app/lib/data/local_db/tables/latest_anime_search.dart | app/lib/data/local_db/tables/latest_anime_search.dart | conservar |
| app/lib/data/local_db/tables/library_entries.dart | app/lib/data/local_db/tables/library_entries.dart | conservar |
| app/lib/data/local_db/tables/playback_progress_entries.dart | app/lib/data/local_db/tables/playback_progress_entries.dart | conservar |
| app/lib/data/local_db/tables/progress_documents.dart | app/lib/data/local_db/tables/progress_documents.dart | conservar |
| app/lib/data/local_db/tables/settings_entries.dart | app/lib/data/local_db/tables/settings_entries.dart | conservar |
| app/lib/data/local_db/uuid_anime_id_generator.dart | app/lib/data/local_db/uuid_anime_id_generator.dart | conservar |
| app/lib/data/metadata/README.md | app/lib/data/metadata/README.md | conservar |
| app/lib/data/metadata/fake_metadata_provider.dart | app/lib/data/metadata/fake_metadata_provider.dart | conservar |
| app/lib/data/opensubtitles/README.md | app/lib/data/opensubtitles/README.md | conservar |
| app/lib/data/opensubtitles/opensubtitles_client.dart | app/lib/data/opensubtitles/opensubtitles_client.dart | conservar |
| app/lib/data/player/README.md | app/lib/data/player/README.md | conservar |
| app/lib/data/player/engine/README.md | app/lib/data/services/player/README.md | mover |
| app/lib/data/player/engine/active_player_lease.dart | app/lib/data/services/player/active_player_lease.dart | mover |
| app/lib/data/player/engine/media_codec_support.dart | app/lib/data/services/player/media_codec_support.dart | mover |
| app/lib/data/player/engine/media_codec_support_android.dart | app/lib/data/services/player/media_codec_support_android.dart | mover |
| app/lib/data/player/engine/media_codec_support_io.dart | app/lib/data/services/player/media_codec_support_io.dart | mover |
| app/lib/data/player/engine/media_codec_support_linux.dart | app/lib/data/services/player/media_codec_support_linux.dart | mover |
| app/lib/data/player/engine/media_codec_support_model.dart | app/lib/data/services/player/media_codec_support_model.dart | mover |
| app/lib/data/player/engine/media_codec_support_stub.dart | app/lib/data/services/player/media_codec_support_stub.dart | mover |
| app/lib/data/player/engine/media_codec_support_system.dart | app/lib/data/services/player/media_codec_support_system.dart | mover |
| app/lib/data/player/engine/media_codec_support_windows.dart | app/lib/data/services/player/media_codec_support_windows.dart | mover |
| app/lib/data/player/engine/media_kit_spike_engine.dart | app/lib/data/services/player/media_kit_spike_engine.dart | mover |
| app/lib/data/player/engine/mpv_performance_reader.dart | app/lib/data/services/player/mpv_performance_reader.dart | mover |
| app/lib/data/player/engine/mpv_subtitle_properties.dart | app/lib/data/services/player/mpv_subtitle_properties.dart | mover |
| app/lib/data/player/engine/mpv_subtitle_properties_native.dart | app/lib/data/services/player/mpv_subtitle_properties_native.dart | mover |
| app/lib/data/player/engine/mpv_subtitle_properties_stub.dart | app/lib/data/services/player/mpv_subtitle_properties_stub.dart | mover |
| app/lib/data/player/providers/README.md | app/lib/sources/README.md | mover |
| app/lib/data/player/providers/allanime/README.md | app/lib/sources/allanime/README.md | mover |
| app/lib/data/player/providers/allanime/allanime_playback_provider.dart | app/lib/sources/allanime/allanime_playback_provider.dart | mover |
| app/lib/data/player/providers/animeav1/README.md | app/lib/sources/animeav1/README.md | mover |
| app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart | app/lib/sources/animeav1/animeav1_playback_provider.dart | mover |
| app/lib/data/player/providers/animegg/README.md | app/lib/sources/animegg/README.md | mover |
| app/lib/data/player/providers/animegg/animegg_playback_provider.dart | app/lib/sources/animegg/animegg_playback_provider.dart | mover |
| app/lib/data/player/providers/anizone/README.md | app/lib/sources/anizone/README.md | mover |
| app/lib/data/player/providers/anizone/anizone_playback_provider.dart | app/lib/sources/anizone/anizone_playback_provider.dart | mover |
| app/lib/data/player/providers/episode_source_support.dart | app/lib/sources/episode_source_support.dart | mover |
| app/lib/data/player/providers/hosts/README.md | app/lib/sources/hosts/README.md | mover |
| app/lib/data/player/providers/hosts/direct_media_host_resolver.dart | app/lib/sources/hosts/direct_media_host_resolver.dart | mover |
| app/lib/data/player/providers/hosts/voe_video_host_resolver.dart | app/lib/sources/hosts/voe_video_host_resolver.dart | mover |
| app/lib/data/player/providers/html_playback_parsers.dart | app/lib/sources/html_playback_parsers.dart | mover |
| app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart | app/lib/sources/jkanime/jkanime_playback_provider.dart | mover |
| app/lib/data/player/providers/megaplay/README.md | app/lib/sources/megaplay/README.md | mover |
| app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart | app/lib/sources/megaplay/megaplay_playback_provider.dart | mover |
| app/lib/data/player/providers/miruro/README.md | app/lib/sources/miruro/README.md | mover |
| app/lib/data/player/providers/miruro/miruro_catalog_api.dart | app/lib/sources/miruro/miruro_catalog_api.dart | mover |
| app/lib/data/player/providers/miruro/miruro_catalog_parser.dart | app/lib/sources/miruro/miruro_catalog_parser.dart | mover |
| app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | mover |
| app/lib/data/player/providers/miruro/miruro_http2_client.dart | app/lib/sources/miruro/miruro_http2_client.dart | mover |
| app/lib/data/player/providers/miruro/miruro_media_proxy.dart | app/lib/sources/miruro/miruro_media_proxy.dart | mover |
| app/lib/data/player/providers/mock/README.md | app/lib/sources/mock/README.md | mover |
| app/lib/data/player/providers/mock/mock_playback_provider.dart | app/lib/sources/mock/mock_playback_provider.dart | mover |
| app/lib/data/player/providers/playback_providers_module.dart | app/lib/sources/playback_providers_module.dart | mover |
| app/lib/data/player/providers/public_episode_provider.dart | app/lib/sources/public_episode_provider.dart | mover |
| app/lib/data/player/providers/public_playback_http.dart | app/lib/sources/public_playback_http.dart | mover |
| app/lib/data/player/providers/registry/provider_spec.dart | app/lib/sources/registry/provider_spec.dart | mover |
| app/lib/data/player/providers/user_sources/README.md | app/lib/sources/user_sources/README.md | mover |
| app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart | app/lib/sources/user_sources/user_defined_playback_provider.dart | mover |
| app/lib/data/player/providers/wikimedia/README.md | app/lib/sources/wikimedia/README.md | mover |
| app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | mover |
| app/lib/data/player/providers/wikimedia/wikimedia_identity.dart | app/lib/sources/wikimedia/wikimedia_identity.dart | mover |
| app/lib/data/secure_storage/README.md | app/lib/data/secure_storage/README.md | conservar |
| app/lib/data/secure_storage/flutter_secure_credential_store.dart | app/lib/data/secure_storage/flutter_secure_credential_store.dart | conservar |
| app/lib/data/secure_storage/flutter_secure_storage_api.dart | app/lib/data/secure_storage/flutter_secure_storage_api.dart | conservar |
| app/lib/data/secure_storage/secure_storage_api.dart | app/lib/data/secure_storage/secure_storage_api.dart | conservar |
| app/lib/data/testing/README.md | app/lib/data/testing/README.md | conservar |
| app/lib/data/testing/fake_sync_remote.dart | app/lib/data/testing/fake_sync_remote.dart | conservar |
| app/lib/domain/README.md | app/lib/domain/README.md | conservar |
| app/lib/domain/app_identity.dart | app/lib/domain/app_identity.dart | conservar |
| app/lib/domain/auth/README.md | app/lib/domain/auth/README.md | conservar |
| app/lib/domain/auth/secure_credential_store.dart | app/lib/domain/auth/secure_credential_store.dart | conservar |
| app/lib/domain/catalog/README.md | app/lib/domain/catalog/README.md | conservar |
| app/lib/domain/catalog/anime_catalog_repository.dart | app/lib/domain/catalog/anime_catalog_repository.dart | conservar |
| app/lib/domain/catalog/anime_detail_metadata.dart | app/lib/domain/catalog/anime_detail_metadata.dart | conservar |
| app/lib/domain/catalog/anime_id.dart | app/lib/domain/catalog/anime_id.dart | conservar |
| app/lib/domain/catalog/anime_identity.dart | app/lib/domain/catalog/anime_identity.dart | conservar |
| app/lib/domain/catalog/anime_identity_repository.dart | app/lib/domain/catalog/anime_identity_repository.dart | conservar |
| app/lib/domain/catalog/anime_summary.dart | app/lib/domain/catalog/anime_summary.dart | conservar |
| app/lib/domain/catalog/episode_index_provider.dart | app/lib/domain/catalog/episode_index_provider.dart | conservar |
| app/lib/domain/catalog/external_anime_id.dart | app/lib/domain/catalog/external_anime_id.dart | conservar |
| app/lib/domain/catalog/library_entry.dart | app/lib/domain/catalog/library_entry.dart | conservar |
| app/lib/domain/catalog/library_repository.dart | app/lib/domain/catalog/library_repository.dart | conservar |
| app/lib/domain/catalog/metadata_provenance.dart | app/lib/domain/catalog/metadata_provenance.dart | conservar |
| app/lib/domain/catalog/metadata_provider.dart | app/lib/domain/catalog/metadata_provider.dart | conservar |
| app/lib/domain/catalog/provider_anime_metadata.dart | app/lib/domain/catalog/provider_anime_metadata.dart | conservar |
| app/lib/domain/catalog/provider_result.dart | app/lib/domain/catalog/provider_result.dart | conservar |
| app/lib/domain/player/README.md | app/lib/domain/player/README.md | conservar |
| app/lib/domain/player/audio_track_info.dart | app/lib/domain/player/audio_track_info.dart | conservar |
| app/lib/domain/player/providers/README.md | app/lib/domain/player/providers/README.md | conservar |
| app/lib/domain/player/providers/anime_identity.dart | app/lib/domain/player/providers/anime_identity.dart | conservar |
| app/lib/domain/player/providers/episode_source.dart | app/lib/domain/player/providers/episode_source.dart | conservar |
| app/lib/domain/player/providers/playback_provider_contract.dart | app/lib/domain/player/providers/playback_provider_contract.dart | conservar |
| app/lib/domain/player/providers/playback_source.dart | app/lib/domain/player/providers/playback_source.dart | conservar |
| app/lib/domain/player/skips/README.md | app/lib/domain/player/skips/README.md | conservar |
| app/lib/domain/player/skips/skip_automation_policy.dart | app/lib/domain/player/skips/skip_automation_policy.dart | conservar |
| app/lib/domain/player/skips/skip_segment.dart | app/lib/domain/player/skips/skip_segment.dart | conservar |
| app/lib/domain/player/skips/skip_segment_catalog.dart | app/lib/domain/player/skips/skip_segment_catalog.dart | conservar |
| app/lib/domain/player/subtitles/README.md | app/lib/domain/player/subtitles/README.md | conservar |
| app/lib/domain/player/subtitles/external_subtitle_catalog.dart | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | conservar |
| app/lib/domain/player/subtitles/hardsub_policy.dart | app/lib/domain/player/subtitles/hardsub_policy.dart | conservar |
| app/lib/domain/player/subtitles/subtitle_style.dart | app/lib/domain/player/subtitles/subtitle_style.dart | conservar |
| app/lib/domain/player/subtitles/subtitle_track_info.dart | app/lib/domain/player/subtitles/subtitle_track_info.dart | conservar |
| app/lib/domain/player/video_track_info.dart | app/lib/domain/player/video_track_info.dart | conservar |
| app/lib/domain/progress/README.md | app/lib/domain/progress/README.md | conservar |
| app/lib/domain/progress/checkpoint_coordinator.dart | app/lib/domain/progress/checkpoint_coordinator.dart | conservar |
| app/lib/domain/progress/content_identity.dart | app/lib/domain/progress/content_identity.dart | conservar |
| app/lib/domain/progress/playback_progress.dart | app/lib/domain/progress/playback_progress.dart | conservar |
| app/lib/domain/progress/playback_progress_repository.dart | app/lib/domain/progress/playback_progress_repository.dart | conservar |
| app/lib/domain/progress/progress_document.dart | app/lib/domain/progress/progress_document.dart | conservar |
| app/lib/domain/progress/progress_repository.dart | app/lib/domain/progress/progress_repository.dart | conservar |
| app/lib/domain/synchronization/README.md | app/lib/domain/synchronization/README.md | conservar |
| app/lib/domain/synchronization/sync_envelope.dart | app/lib/domain/synchronization/sync_envelope.dart | conservar |
| app/lib/domain/synchronization/sync_remote.dart | app/lib/domain/synchronization/sync_remote.dart | conservar |
| app/lib/main.dart | app/lib/main.dart | conservar |
| app/lib/main_player_spike.dart | app/lib/main_player_spike.dart | conservar |
| app/lib/settings/README.md | app/lib/settings/README.md | conservar |
| app/lib/settings/registry/README.md | app/lib/settings/registry/README.md | conservar |
| app/lib/settings/registry/setting_definition.dart | app/lib/settings/registry/setting_definition.dart | conservar |
| app/lib/settings/registry/settings_registry.dart | app/lib/settings/registry/settings_registry.dart | conservar |
| app/lib/settings/store/README.md | app/lib/settings/store/README.md | conservar |
| app/lib/settings/store/settings_store.dart | app/lib/settings/store/settings_store.dart | conservar |
| app/linux/.gitignore | app/linux/.gitignore | conservar |
| app/linux/CMakeLists.txt | app/linux/CMakeLists.txt | conservar |
| app/linux/flutter/CMakeLists.txt | app/linux/flutter/CMakeLists.txt | conservar |
| app/linux/flutter/generated_plugin_registrant.cc | app/linux/flutter/generated_plugin_registrant.cc | conservar |
| app/linux/flutter/generated_plugin_registrant.h | app/linux/flutter/generated_plugin_registrant.h | conservar |
| app/linux/flutter/generated_plugins.cmake | app/linux/flutter/generated_plugins.cmake | conservar |
| app/linux/local_codec.cmake | app/linux/local_codec.cmake | conservar |
| app/linux/media_kit_video_lifetime.cmake | app/linux/media_kit_video_lifetime.cmake | conservar |
| app/linux/runner/CMakeLists.txt | app/linux/runner/CMakeLists.txt | conservar |
| app/linux/runner/main.cc | app/linux/runner/main.cc | conservar |
| app/linux/runner/my_application.cc | app/linux/runner/my_application.cc | conservar |
| app/linux/runner/my_application.h | app/linux/runner/my_application.h | conservar |
| app/pubspec.lock | app/pubspec.lock | conservar |
| app/pubspec.yaml | app/pubspec.yaml | conservar |
| app/test/application/external_subtitle_service_test.dart | app/test/application/external_subtitle_service_test.dart | conservar |
| app/test/application/playback_provider_manager_test.dart | app/test/application/playback_provider_manager_test.dart | conservar |
| app/test/application/playback_source_cache_test.dart | app/test/application/playback_source_cache_test.dart | conservar |
| app/test/catalog/anime_detail_external_streaming_links_test.dart | app/test/catalog/anime_detail_external_streaming_links_test.dart | conservar |
| app/test/catalog/confirm_completed_status_test.dart | app/test/catalog/confirm_completed_status_test.dart | conservar |
| app/test/catalog/playback_resolution_message_test.dart | app/test/catalog/playback_resolution_message_test.dart | conservar |
| app/test/core/core_integration_test.dart | app/test/core/core_integration_test.dart | conservar |
| app/test/core/core_test.dart | app/test/core/core_test.dart | conservar |
| app/test/core/f1_12_real_integration_test.dart | app/test/core/f1_12_real_integration_test.dart | conservar |
| app/test/data/anilist/anilist_client_test.dart | app/test/data/anilist/anilist_client_test.dart | conservar |
| app/test/data/anilist/anilist_live_smoke_test.dart | app/test/data/anilist/anilist_live_smoke_test.dart | conservar |
| app/test/data/anilist/anilist_metadata_provider_test.dart | app/test/data/anilist/anilist_metadata_provider_test.dart | conservar |
| app/test/data/anilist/browse_cache_test.dart | app/test/data/anilist/browse_cache_test.dart | conservar |
| app/test/data/anilist/offline_first_anime_catalog_test.dart | app/test/data/anilist/offline_first_anime_catalog_test.dart | conservar |
| app/test/data/aniskip/aniskip_client_test.dart | app/test/data/aniskip/aniskip_client_test.dart | conservar |
| app/test/data/kitsu/kitsu_episode_index_test.dart | app/test/data/kitsu/kitsu_episode_index_test.dart | conservar |
| app/test/data/kitsu/kitsu_live_smoke_test.dart | app/test/data/kitsu/kitsu_live_smoke_test.dart | conservar |
| app/test/data/local_db/app_database_test.dart | app/test/data/local_db/app_database_test.dart | conservar |
| app/test/data/local_db/catalog_identity_repository_test.dart | app/test/data/local_db/catalog_identity_repository_test.dart | conservar |
| app/test/data/local_db/local_progress_repository_test.dart | app/test/data/local_db/local_progress_repository_test.dart | conservar |
| app/test/data/local_db/playback_progress_repository_test.dart | app/test/data/local_db/playback_progress_repository_test.dart | conservar |
| app/test/data/opensubtitles/opensubtitles_client_test.dart | app/test/data/opensubtitles/opensubtitles_client_test.dart | conservar |
| app/test/data/player/engine/media_codec_support_test.dart | app/test/data/player/engine/media_codec_support_test.dart | conservar |
| app/test/data/player/providers/allanime_playback_provider_test.dart | app/test/data/player/providers/allanime_playback_provider_test.dart | conservar |
| app/test/data/player/providers/animeav1_playback_provider_test.dart | app/test/data/player/providers/animeav1_playback_provider_test.dart | conservar |
| app/test/data/player/providers/animegg_playback_provider_test.dart | app/test/data/player/providers/animegg_playback_provider_test.dart | conservar |
| app/test/data/player/providers/anizone_playback_provider_test.dart | app/test/data/player/providers/anizone_playback_provider_test.dart | conservar |
| app/test/data/player/providers/episode_source_support_test.dart | app/test/data/player/providers/episode_source_support_test.dart | conservar |
| app/test/data/player/providers/hosts/direct_media_host_resolver_test.dart | app/test/data/player/providers/hosts/direct_media_host_resolver_test.dart | conservar |
| app/test/data/player/providers/megaplay_playback_provider_test.dart | app/test/data/player/providers/megaplay_playback_provider_test.dart | conservar |
| app/test/data/player/providers/miruro_catalog_provider_test.dart | app/test/data/player/providers/miruro_catalog_provider_test.dart | conservar |
| app/test/data/player/providers/miruro_media_proxy_test.dart | app/test/data/player/providers/miruro_media_proxy_test.dart | conservar |
| app/test/data/player/providers/playback_providers_module_test.dart | app/test/data/player/providers/playback_providers_module_test.dart | conservar |
| app/test/data/player/providers/public_playback_http_test.dart | app/test/data/player/providers/public_playback_http_test.dart | conservar |
| app/test/data/player/providers/public_playback_providers_test.dart | app/test/data/player/providers/public_playback_providers_test.dart | conservar |
| app/test/data/player/providers/refactor_characterization_test.dart | app/test/data/player/providers/refactor_characterization_test.dart | conservar |
| app/test/data/player/providers/user_defined_playback_provider_test.dart | app/test/data/player/providers/user_defined_playback_provider_test.dart | conservar |
| app/test/data/player/providers/voe_video_host_resolver_test.dart | app/test/data/player/providers/voe_video_host_resolver_test.dart | conservar |
| app/test/data/secure_storage/flutter_secure_credential_store_test.dart | app/test/data/secure_storage/flutter_secure_credential_store_test.dart | conservar |
| app/test/data/testing/fake_sync_remote_test.dart | app/test/data/testing/fake_sync_remote_test.dart | conservar |
| app/test/domain/catalog/catalog_contracts_test.dart | app/test/domain/catalog/catalog_contracts_test.dart | conservar |
| app/test/domain/episode_source_adapter_test.dart | app/test/domain/episode_source_adapter_test.dart | conservar |
| app/test/domain/external_subtitle_catalog_test.dart | app/test/domain/external_subtitle_catalog_test.dart | conservar |
| app/test/domain/playback_provider_contract_test.dart | app/test/domain/playback_provider_contract_test.dart | conservar |
| app/test/domain/skip_automation_policy_test.dart | app/test/domain/skip_automation_policy_test.dart | conservar |
| app/test/domain/subtitle_policy_test.dart | app/test/domain/subtitle_policy_test.dart | conservar |
| app/test/domain/video_track_info_test.dart | app/test/domain/video_track_info_test.dart | conservar |
| app/test/fixtures/refactor/README.md | app/test/fixtures/refactor/README.md | conservar |
| app/test/fixtures/refactor/allanime_harness.dart | app/test/fixtures/refactor/allanime_harness.dart | conservar |
| app/test/fixtures/refactor/animeav1_harness.dart | app/test/fixtures/refactor/animeav1_harness.dart | conservar |
| app/test/fixtures/refactor/animegg_harness.dart | app/test/fixtures/refactor/animegg_harness.dart | conservar |
| app/test/fixtures/refactor/anizone_harness.dart | app/test/fixtures/refactor/anizone_harness.dart | conservar |
| app/test/fixtures/refactor/megaplay_harness.dart | app/test/fixtures/refactor/megaplay_harness.dart | conservar |
| app/test/fixtures/refactor/miruro_config.json | app/test/fixtures/refactor/miruro_config.json | conservar |
| app/test/fixtures/refactor/miruro_payload.json | app/test/fixtures/refactor/miruro_payload.json | conservar |
| app/test/fixtures/refactor/miruro_payload_xor_gzip.bin | app/test/fixtures/refactor/miruro_payload_xor_gzip.bin | conservar |
| app/test/fixtures/refactor/parser_cases.json | app/test/fixtures/refactor/parser_cases.json | conservar |
| app/test/fixtures/refactor/parser_public_media.json | app/test/fixtures/refactor/parser_public_media.json | conservar |
| app/test/fixtures/refactor/voe_harness.dart | app/test/fixtures/refactor/voe_harness.dart | conservar |
| app/test/fixtures/refactor/wikimedia_harness.dart | app/test/fixtures/refactor/wikimedia_harness.dart | conservar |
| app/test/golden/refactor/allanime_sources.json | app/test/golden/refactor/allanime_sources.json | conservar |
| app/test/golden/refactor/animeav1_sources.json | app/test/golden/refactor/animeav1_sources.json | conservar |
| app/test/golden/refactor/animegg_sources.json | app/test/golden/refactor/animegg_sources.json | conservar |
| app/test/golden/refactor/anizone_sources.json | app/test/golden/refactor/anizone_sources.json | conservar |
| app/test/golden/refactor/megaplay_sources.json | app/test/golden/refactor/megaplay_sources.json | conservar |
| app/test/golden/refactor/miruro_config.json | app/test/golden/refactor/miruro_config.json | conservar |
| app/test/golden/refactor/parser_outputs.json | app/test/golden/refactor/parser_outputs.json | conservar |
| app/test/golden/refactor/parser_public_media_outputs.json | app/test/golden/refactor/parser_public_media_outputs.json | conservar |
| app/test/golden/refactor/transport_outputs.json | app/test/golden/refactor/transport_outputs.json | conservar |
| app/test/golden/refactor/voe_sources.json | app/test/golden/refactor/voe_sources.json | conservar |
| app/test/golden/refactor/wikimedia_sources.json | app/test/golden/refactor/wikimedia_sources.json | conservar |
| app/test/home/home_artwork_diagnostics_test.dart | app/test/home/home_artwork_diagnostics_test.dart | conservar |
| app/test/home/home_card_actions_test.dart | app/test/home/home_card_actions_test.dart | conservar |
| app/test/home/home_data_test.dart | app/test/home/home_data_test.dart | conservar |
| app/test/home/home_screen_test.dart | app/test/home/home_screen_test.dart | conservar |
| app/test/player/active_player_lease_test.dart | app/test/player/active_player_lease_test.dart | conservar |
| app/test/player/external_subtitle_search_panel_test.dart | app/test/player/external_subtitle_search_panel_test.dart | conservar |
| app/test/player/local_hls_transport_test.dart | app/test/player/local_hls_transport_test.dart | conservar |
| app/test/player/main_player_spike_test.dart | app/test/player/main_player_spike_test.dart | conservar |
| app/test/player/media_kit_spike_dispose_failure_test.dart | app/test/player/media_kit_spike_dispose_failure_test.dart | conservar |
| app/test/player/media_kit_spike_integration_test.dart | app/test/player/media_kit_spike_integration_test.dart | conservar |
| app/test/player/media_kit_video_surface_controls_test.dart | app/test/player/media_kit_video_surface_controls_test.dart | conservar |
| app/test/player/oc07_miruro_failover_test.dart | app/test/player/oc07_miruro_failover_test.dart | conservar |
| app/test/player/oc07_miruro_live_playback_test.dart | app/test/player/oc07_miruro_live_playback_test.dart | conservar |
| app/test/player/oc07_miruro_proxy_playback_test.dart | app/test/player/oc07_miruro_proxy_playback_test.dart | conservar |
| app/test/player/playback_spike_snapshot_test.dart | app/test/player/playback_spike_snapshot_test.dart | conservar |
| app/test/player/player_performance_collector_test.dart | app/test/player/player_performance_collector_test.dart | conservar |
| app/test/player/player_performance_integration_test.dart | app/test/player/player_performance_integration_test.dart | conservar |
| app/test/player/player_quality_test.dart | app/test/player/player_quality_test.dart | conservar |
| app/test/player/player_test_fixture.dart | app/test/player/player_test_fixture.dart | conservar |
| app/test/player/player_test_fixture_test.dart | app/test/player/player_test_fixture_test.dart | conservar |
| app/test/player/player_window_controller_test.dart | app/test/player/player_window_controller_test.dart | conservar |
| app/test/player/provider_playback_route_test.dart | app/test/player/provider_playback_route_test.dart | conservar |
| app/test/player/public_hls_host_integration_test.dart | app/test/player/public_hls_host_integration_test.dart | conservar |
| app/test/player/resume_start_position_integration_test.dart | app/test/player/resume_start_position_integration_test.dart | conservar |
| app/test/player/spike_player_coordinator_test.dart | app/test/player/spike_player_coordinator_test.dart | conservar |
| app/test/player/spike_player_module_test.dart | app/test/player/spike_player_module_test.dart | conservar |
| app/test/player/spike_player_page_test.dart | app/test/player/spike_player_page_test.dart | conservar |
| app/test/player/spike_window_close_gate_test.dart | app/test/player/spike_window_close_gate_test.dart | conservar |
| app/test/player/video_surface_status_label_test.dart | app/test/player/video_surface_status_label_test.dart | conservar |
| app/test/refactor/capture_sources.dart | app/test/refactor/capture_sources.dart | conservar |
| app/test/refactor/parser_characterization_test.dart | app/test/refactor/parser_characterization_test.dart | conservar |
| app/test/refactor/parser_snapshots.dart | app/test/refactor/parser_snapshots.dart | conservar |
| app/test/refactor/source_characterization_test.dart | app/test/refactor/source_characterization_test.dart | conservar |
| app/test/refactor/source_snapshot.dart | app/test/refactor/source_snapshot.dart | conservar |
| app/test/refactor/transport_characterization_test.dart | app/test/refactor/transport_characterization_test.dart | conservar |
| app/test/refactor/transport_snapshots.dart | app/test/refactor/transport_snapshots.dart | conservar |
| app/test/settings/settings_store_test.dart | app/test/settings/settings_store_test.dart | conservar |
| app/test/widget_test.dart | app/test/widget_test.dart | conservar |
| app/tool/README.md | app/tool/README.md | conservar |
| app/tool/allanime_live_check.dart | app/tool/allanime_live_check.dart | conservar |
| app/tool/anilili_live_player_app.dart | app/tool/anilili_live_player_app.dart | conservar |
| app/tool/animeav1_live_check.dart | app/tool/animeav1_live_check.dart | conservar |
| app/tool/animeav1_timing_probe.dart | app/tool/animeav1_timing_probe.dart | conservar |
| app/tool/animegg_timing_probe.dart | app/tool/animegg_timing_probe.dart | conservar |
| app/tool/anizone_live_check.dart | app/tool/anizone_live_check.dart | conservar |
| app/tool/commons_live_player_app.dart | app/tool/commons_live_player_app.dart | conservar |
| app/tool/oc07_h2_probe.dart | app/tool/oc07_h2_probe.dart | conservar |
| app/tool/oc07_miruro_probe.dart | app/tool/oc07_miruro_probe.dart | conservar |
| app/tool/oc07_proxy_probe.dart | app/tool/oc07_proxy_probe.dart | conservar |
| app/tool/voe_resolver_probe.dart | app/tool/voe_resolver_probe.dart | conservar |
| auditoria_f22_v2.zip | auditoria_f22_v2.zip | conservar |
| docs/adr/ADR-001-cliente-flutter-dart.md | docs/adr/ADR-001-cliente-flutter-dart.md | conservar |
| docs/adr/ADR-002-motor-video.md | docs/adr/ADR-002-motor-video.md | conservar |
| docs/adr/ADR-003-estado-riverpod.md | docs/adr/ADR-003-estado-riverpod.md | conservar |
| docs/adr/ADR-004-navegacion-go-router.md | docs/adr/ADR-004-navegacion-go-router.md | conservar |
| docs/adr/ADR-005-persistencia-drift.md | docs/adr/ADR-005-persistencia-drift.md | conservar |
| docs/adr/ADR-006-red-dio.md | docs/adr/ADR-006-red-dio.md | conservar |
| docs/adr/ADR-007-secretos-flutter-secure-storage.md | docs/adr/ADR-007-secretos-flutter-secure-storage.md | conservar |
| docs/adr/ADR-008-anilist-graphql.md | docs/adr/ADR-008-anilist-graphql.md | conservar |
| docs/adr/ADR-009-backend-supabase.md | docs/adr/ADR-009-backend-supabase.md | conservar |
| docs/adr/ADR-010-qr.md | docs/adr/ADR-010-qr.md | conservar |
| docs/adr/ADR-011-temas.md | docs/adr/ADR-011-temas.md | conservar |
| docs/adr/ADR-012-subtitulos-mpv.md | docs/adr/ADR-012-subtitulos-mpv.md | conservar |
| docs/adr/ADR-013-pruebas.md | docs/adr/ADR-013-pruebas.md | conservar |
| docs/adr/ADR-014-empaquetado-flatpak.md | docs/adr/ADR-014-empaquetado-flatpak.md | conservar |
| docs/adr/ADR-015-arquitectura-core-linux-first.md | docs/adr/ADR-015-arquitectura-core-linux-first.md | conservar |
| docs/adr/README.md | docs/adr/README.md | conservar |
| docs/adr/additional/ADR-A01-arquitectura-por-capas.md | docs/adr/additional/ADR-A01-arquitectura-por-capas.md | conservar |
| docs/adr/additional/ADR-A02-transporte-http.md | docs/adr/additional/ADR-A02-transporte-http.md | conservar |
| docs/adr/additional/ADR-A03-persistencia-local.md | docs/adr/additional/ADR-A03-persistencia-local.md | conservar |
| docs/adr/additional/ADR-A04-errores-y-resultados.md | docs/adr/additional/ADR-A04-errores-y-resultados.md | conservar |
| docs/adr/additional/ADR-A05-logs-y-redaccion.md | docs/adr/additional/ADR-A05-logs-y-redaccion.md | conservar |
| docs/adr/additional/ADR-A06-ajustes.md | docs/adr/additional/ADR-A06-ajustes.md | conservar |
| docs/adr/additional/ADR-A07-cliente-anilist.md | docs/adr/additional/ADR-A07-cliente-anilist.md | conservar |
| docs/adr/additional/ADR-A08-oauth-anilist.md | docs/adr/additional/ADR-A08-oauth-anilist.md | conservar |
| docs/adr/additional/ADR-A09-almacen-seguro.md | docs/adr/additional/ADR-A09-almacen-seguro.md | conservar |
| docs/adr/additional/ADR-A10-progreso-local.md | docs/adr/additional/ADR-A10-progreso-local.md | conservar |
| docs/adr/additional/ADR-A11-sincronizacion-fakeremote.md | docs/adr/additional/ADR-A11-sincronizacion-fakeremote.md | conservar |
| docs/adr/additional/ADR-A12-gestion-de-estado.md | docs/adr/additional/ADR-A12-gestion-de-estado.md | conservar |
| docs/adr/additional/ADR-A13-navegacion.md | docs/adr/additional/ADR-A13-navegacion.md | conservar |
| docs/adr/additional/ADR-A14-catalog-providers-identity.md | docs/adr/additional/ADR-A14-catalog-providers-identity.md | conservar |
| docs/adr/additional/ADR-A15-frontera-codecs-multimedia.md | docs/adr/additional/ADR-A15-frontera-codecs-multimedia.md | conservar |
| docs/ai-system/AGENT_REGISTRY.md | docs/ai-system/AGENT_REGISTRY.md | conservar |
| docs/ai-system/AUTONOMY_POLICY.md | docs/ai-system/AUTONOMY_POLICY.md | conservar |
| docs/ai-system/DELEGATION_PROBE.md | docs/ai-system/DELEGATION_PROBE.md | conservar |
| docs/ai-system/ENVIRONMENT_AUDIT.md | docs/ai-system/ENVIRONMENT_AUDIT.md | conservar |
| docs/ai-system/EVALUATION.md | docs/ai-system/EVALUATION.md | conservar |
| docs/ai-system/FINAL_REPORT.md | docs/ai-system/FINAL_REPORT.md | conservar |
| docs/ai-system/MCP_REGISTRY.md | docs/ai-system/MCP_REGISTRY.md | conservar |
| docs/ai-system/MCP_RESEARCH.md | docs/ai-system/MCP_RESEARCH.md | conservar |
| docs/ai-system/MEMORY_ARCHITECTURE.md | docs/ai-system/MEMORY_ARCHITECTURE.md | conservar |
| docs/ai-system/PORTABILITY.md | docs/ai-system/PORTABILITY.md | conservar |
| docs/ai-system/PROJECT_RULES.md | docs/ai-system/PROJECT_RULES.md | conservar |
| docs/ai-system/README.md | docs/ai-system/README.md | conservar |
| docs/ai-system/RUNBOOK.md | docs/ai-system/RUNBOOK.md | conservar |
| docs/ai-system/TOKEN_POLICY.md | docs/ai-system/TOKEN_POLICY.md | conservar |
| docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/README.md | docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/README.md | conservar |
| docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_catalog_api_test.dart.txt | docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_catalog_api_test.dart.txt | conservar |
| docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_catalog_test.dart.txt | docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_catalog_test.dart.txt | conservar |
| docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_live_smoke_test.dart.txt | docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_live_smoke_test.dart.txt | conservar |
| docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_playback_provider_test.dart.txt | docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/miruro_playback_provider_test.dart.txt | conservar |
| docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/playback_providers_module_test.before-cleanup.dart.txt | docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/playback_providers_module_test.before-cleanup.dart.txt | conservar |
| docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/public_playback_provider_test.from-head.dart.txt | docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/public_playback_provider_test.from-head.dart.txt | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/README.md | docs/ai-system/archive/providers/S0-2026-11-16/README.md | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/animeav1/README.md | docs/ai-system/archive/providers/S0-2026-11-16/animeav1/README.md | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/animegg/README.md | docs/ai-system/archive/providers/S0-2026-11-16/animegg/README.md | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/animeheaven/README.md | docs/ai-system/archive/providers/S0-2026-11-16/animeheaven/README.md | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/animeonline_ninja/README.md | docs/ai-system/archive/providers/S0-2026-11-16/animeonline_ninja/README.md | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/miruro/README.md | docs/ai-system/archive/providers/S0-2026-11-16/miruro/README.md | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/tioanime/README.md | docs/ai-system/archive/providers/S0-2026-11-16/tioanime/README.md | conservar |
| docs/ai-system/archive/providers/S0-2026-11-16/video_hosts/README.md | docs/ai-system/archive/providers/S0-2026-11-16/video_hosts/README.md | conservar |
| docs/ai-system/audits/F05-detail-offline-audit-2026-11-14.md | docs/ai-system/audits/F05-detail-offline-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/F05-episodes-audit-2026-11-14.md | docs/ai-system/audits/F05-episodes-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/F05.1-audit-2026-11-14.md | docs/ai-system/audits/F05.1-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/F2.2-audit-2026-11-09.md | docs/ai-system/audits/F2.2-audit-2026-11-09.md | conservar |
| docs/ai-system/audits/F2.2-audit-2026-11-10.md | docs/ai-system/audits/F2.2-audit-2026-11-10.md | conservar |
| docs/ai-system/audits/F2.2-audit-reevaluation-2026-11-09.md | docs/ai-system/audits/F2.2-audit-reevaluation-2026-11-09.md | conservar |
| docs/ai-system/audits/F2.2-stop-play-audit-2026-11-10.md | docs/ai-system/audits/F2.2-stop-play-audit-2026-11-10.md | conservar |
| docs/ai-system/audits/F2.3-audit-2026-11-10.md | docs/ai-system/audits/F2.3-audit-2026-11-10.md | conservar |
| docs/ai-system/audits/F2.3-fullscreen-reevaluation-2026-11-10.md | docs/ai-system/audits/F2.3-fullscreen-reevaluation-2026-11-10.md | conservar |
| docs/ai-system/audits/F2.5-audit-2026-11-10.md | docs/ai-system/audits/F2.5-audit-2026-11-10.md | conservar |
| docs/ai-system/audits/F2.6-audit-2026-11-10.md | docs/ai-system/audits/F2.6-audit-2026-11-10.md | conservar |
| docs/ai-system/audits/F2.7-server-switch-audit-2026-11-12.md | docs/ai-system/audits/F2.7-server-switch-audit-2026-11-12.md | conservar |
| docs/ai-system/audits/F2.8-audit-2026-11-11.md | docs/ai-system/audits/F2.8-audit-2026-11-11.md | conservar |
| docs/ai-system/audits/F3-home-card-interactions-audit-2026-11-14.md | docs/ai-system/audits/F3-home-card-interactions-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/F3-home-refinement-audit-2026-11-14.md | docs/ai-system/audits/F3-home-refinement-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/F3-home-surgical-adjustment-audit-2026-11-14.md | docs/ai-system/audits/F3-home-surgical-adjustment-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/HOME-audit-2026-11-14-v2.md | docs/ai-system/audits/HOME-audit-2026-11-14-v2.md | conservar |
| docs/ai-system/audits/HOME-audit-2026-11-14.md | docs/ai-system/audits/HOME-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/KONGROO-reconstruction-A-2026-11-15.md | docs/ai-system/audits/KONGROO-reconstruction-A-2026-11-15.md | conservar |
| docs/ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md | docs/ai-system/audits/KONGROO-reconstruction-A-reassessment-2026-11-15.md | conservar |
| docs/ai-system/audits/Kongroo_F2_2_Auditoria_Independiente.md | docs/ai-system/audits/Kongroo_F2_2_Auditoria_Independiente.md | conservar |
| docs/ai-system/audits/MEGAPLAY-audit-2026-11-19.md | docs/ai-system/audits/MEGAPLAY-audit-2026-11-19.md | conservar |
| docs/ai-system/audits/MIRURO-BACKEND-CONSUMET-audit-2026-11-19.md | docs/ai-system/audits/MIRURO-BACKEND-CONSUMET-audit-2026-11-19.md | conservar |
| docs/ai-system/audits/MIRURO-QUALITY-audit-2026-11-19.md | docs/ai-system/audits/MIRURO-QUALITY-audit-2026-11-19.md | conservar |
| docs/ai-system/audits/OC03-1-TRANSPORT-audit-2026-11-16.md | docs/ai-system/audits/OC03-1-TRANSPORT-audit-2026-11-16.md | conservar |
| docs/ai-system/audits/OC03-1-audit-2026-11-16.md | docs/ai-system/audits/OC03-1-audit-2026-11-16.md | conservar |
| docs/ai-system/audits/OC03-2-ANIME-TRANSPORT-audit-2026-11-17.md | docs/ai-system/audits/OC03-2-ANIME-TRANSPORT-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC03-ANILILI-BEE-audit-2026-11-17.md | docs/ai-system/audits/OC03-ANILILI-BEE-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC03-CLEANUP-audit-2026-11-17.md | docs/ai-system/audits/OC03-CLEANUP-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md | docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC04-BINARY-TRANSPORT-audit-2026-11-17.md | docs/ai-system/audits/OC04-BINARY-TRANSPORT-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md | docs/ai-system/audits/OC04-HTTP403-FALLBACK-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC04-LANGUAGES-audit-2026-11-17.md | docs/ai-system/audits/OC04-LANGUAGES-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC04-MEGAPLAY-PLAYBACK-audit-2026-11-17.md | docs/ai-system/audits/OC04-MEGAPLAY-PLAYBACK-audit-2026-11-17.md | conservar |
| docs/ai-system/audits/OC06-audit-2026-11-19.md | docs/ai-system/audits/OC06-audit-2026-11-19.md | conservar |
| docs/ai-system/audits/Operacion-cierre-F2.2.txt | docs/ai-system/audits/Operacion-cierre-F2.2.txt | conservar |
| docs/ai-system/audits/PLAYER-QUALITY-audit-2026-11-12.md | docs/ai-system/audits/PLAYER-QUALITY-audit-2026-11-12.md | conservar |
| docs/ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md | docs/ai-system/audits/PROVIDER-IMPLEMENTATION-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/PROVIDER-SYSTEM-audit-2026-11-14.md | docs/ai-system/audits/PROVIDER-SYSTEM-audit-2026-11-14.md | conservar |
| docs/ai-system/audits/S0-ANILILI-port-audit-2026-11-15.md | docs/ai-system/audits/S0-ANILILI-port-audit-2026-11-15.md | conservar |
| docs/ai-system/audits/S0-provider-audit-2026-11-15.md | docs/ai-system/audits/S0-provider-audit-2026-11-15.md | conservar |
| docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md | docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md | conservar |
| docs/ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md | docs/ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md | conservar |
| docs/ai-system/audits/S0-video-host-audit-2026-11-15.md | docs/ai-system/audits/S0-video-host-audit-2026-11-15.md | conservar |
| docs/ai-system/audits/S0R-ANIMEHEAVEN-audit-2026-11-16.md | docs/ai-system/audits/S0R-ANIMEHEAVEN-audit-2026-11-16.md | conservar |
| docs/ai-system/audits/S0S-audit-2026-11-16.md | docs/ai-system/audits/S0S-audit-2026-11-16.md | conservar |
| docs/ai-system/audits/UI-Morevna-audit-2026-11-12.md | docs/ai-system/audits/UI-Morevna-audit-2026-11-12.md | conservar |
| docs/ai-system/evaluation.json | docs/ai-system/evaluation.json | conservar |
| docs/ai-system/incidents/PLAYBACK-HTTP-ERROR-UNATTRIBUTED-2026-11-15.md | docs/ai-system/incidents/PLAYBACK-HTTP-ERROR-UNATTRIBUTED-2026-11-15.md | conservar |
| docs/ai-system/missions/ANILILI-9PROVIDERS-2026-11-18.md | docs/ai-system/missions/ANILILI-9PROVIDERS-2026-11-18.md | conservar |
| docs/ai-system/missions/ANILILI-PROVIDERS-2026-11-17.md | docs/ai-system/missions/ANILILI-PROVIDERS-2026-11-17.md | conservar |
| docs/ai-system/missions/FIX-REPRODUCCION-H264-2026-11-18.md | docs/ai-system/missions/FIX-REPRODUCCION-H264-2026-11-18.md | conservar |
| docs/ai-system/missions/KONGROO-RECONSTRUCTION-AUTOMATION.md | docs/ai-system/missions/KONGROO-RECONSTRUCTION-AUTOMATION.md | conservar |
| docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md | docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md | conservar |
| docs/ai-system/missions/KONGROO-RECONSTRUCTION-PLAN.md | docs/ai-system/missions/KONGROO-RECONSTRUCTION-PLAN.md | conservar |
| docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md | docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md | conservar |
| docs/ai-system/missions/OC02-EXECUTION-STATUS.md | docs/ai-system/missions/OC02-EXECUTION-STATUS.md | conservar |
| docs/ai-system/missions/OC02-R0-INVENTORY.md | docs/ai-system/missions/OC02-R0-INVENTORY.md | conservar |
| docs/ai-system/missions/OC03-1-EXECUTION-STATUS.md | docs/ai-system/missions/OC03-1-EXECUTION-STATUS.md | conservar |
| docs/ai-system/missions/OC03-1-REMOTE-TRANSPORT-2026-11-16.md | docs/ai-system/missions/OC03-1-REMOTE-TRANSPORT-2026-11-16.md | conservar |
| docs/ai-system/missions/OC03-2-ANIME-TRANSPORT-2026-11-17.md | docs/ai-system/missions/OC03-2-ANIME-TRANSPORT-2026-11-17.md | conservar |
| docs/ai-system/missions/OC05-CLOUDFLARE-ANIMEAV1-SUBTITLES-2026-11-18.md | docs/ai-system/missions/OC05-CLOUDFLARE-ANIMEAV1-SUBTITLES-2026-11-18.md | conservar |
| docs/ai-system/missions/OC06-CLOUDFLARE-ACCESS-RESEARCH-2026-11-18.md | docs/ai-system/missions/OC06-CLOUDFLARE-ACCESS-RESEARCH-2026-11-18.md | conservar |
| docs/ai-system/missions/OC07-MIRURO-FRONTEND-BACKEND-CONTRACT-2026-11-19.md | docs/ai-system/missions/OC07-MIRURO-FRONTEND-BACKEND-CONTRACT-2026-11-19.md | conservar |
| docs/ai-system/missions/REFACTOR-MODULARIZACION-2026-11-18.md | docs/ai-system/missions/REFACTOR-MODULARIZACION-2026-11-18.md | conservar |
| docs/ai-system/missions/S0-ANILILI-PORT-REPORT.md | docs/ai-system/missions/S0-ANILILI-PORT-REPORT.md | conservar |
| docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md | docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md | conservar |
| docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md | docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md | conservar |
| docs/ai-system/missions/S0R-BASELINE.md | docs/ai-system/missions/S0R-BASELINE.md | conservar |
| docs/ai-system/missions/S0R-MASTER-MISSION.md | docs/ai-system/missions/S0R-MASTER-MISSION.md | conservar |
| docs/ai-system/missions/S0R-REFERENCE-REVIEW-2026-11-16.md | docs/ai-system/missions/S0R-REFERENCE-REVIEW-2026-11-16.md | conservar |
| docs/architecture/F2.1-player-evaluation.md | docs/architecture/F2.1-player-evaluation.md | conservar |
| docs/architecture/anime-identity.md | docs/architecture/anime-identity.md | conservar |
| docs/architecture/catalog-failure-scenarios.md | docs/architecture/catalog-failure-scenarios.md | conservar |
| docs/architecture/catalog-system-audit.md | docs/architecture/catalog-system-audit.md | conservar |
| docs/architecture/catalog-system.md | docs/architecture/catalog-system.md | conservar |
| docs/architecture/metadata-providers.md | docs/architecture/metadata-providers.md | conservar |
| docs/architecture/optional-auth.md | docs/architecture/optional-auth.md | conservar |
| docs/development/catalog-testing.md | docs/development/catalog-testing.md | conservar |
| docs/environment/F0.1-FEDORA.md | docs/environment/F0.1-FEDORA.md | conservar |
| docs/memory/AI_HANDOFF.md | docs/memory/AI_HANDOFF.md | conservar |
| docs/memory/ARCHITECTURE_INDEX.md | docs/memory/ARCHITECTURE_INDEX.md | conservar |
| docs/memory/DECISIONS.md | docs/memory/DECISIONS.md | conservar |
| docs/memory/KNOWN_ISSUES.md | docs/memory/KNOWN_ISSUES.md | conservar |
| docs/memory/LESSONS_LEARNED.md | docs/memory/LESSONS_LEARNED.md | conservar |
| docs/memory/MODULE_INDEX.md | docs/memory/MODULE_INDEX.md | conservar |
| docs/memory/PROJECT_STATE.md | docs/memory/PROJECT_STATE.md | conservar |
| docs/memory/README.md | docs/memory/README.md | conservar |
| docs/memory/RESEARCH_INDEX.md | docs/memory/RESEARCH_INDEX.md | conservar |
| docs/memory/decisions/AI-001-memoria-local.md | docs/memory/decisions/AI-001-memoria-local.md | conservar |
| docs/memory/decisions/AI-002-autonomia.md | docs/memory/decisions/AI-002-autonomia.md | conservar |
| docs/memory/decisions/README.md | docs/memory/decisions/README.md | conservar |
| docs/memory/research/2026-11-07-entorno.md | docs/memory/research/2026-11-07-entorno.md | conservar |
| docs/memory/research/README.md | docs/memory/research/README.md | conservar |
| docs/memory/sessions/2026-11-07-f0-2-git.md | docs/memory/sessions/2026-11-07-f0-2-git.md | conservar |
| docs/memory/sessions/2026-11-07-setup.md | docs/memory/sessions/2026-11-07-setup.md | conservar |
| docs/memory/sessions/2026-11-08-f0-3-f0-6.md | docs/memory/sessions/2026-11-08-f0-3-f0-6.md | conservar |
| docs/memory/sessions/2026-11-08-f1-1-f1-2-approval.md | docs/memory/sessions/2026-11-08-f1-1-f1-2-approval.md | conservar |
| docs/memory/sessions/2026-11-08-f1-1-f1-2-reconciliation.md | docs/memory/sessions/2026-11-08-f1-1-f1-2-reconciliation.md | conservar |
| docs/memory/sessions/2026-11-08-f1-1-f1-2.md | docs/memory/sessions/2026-11-08-f1-1-f1-2.md | conservar |
| docs/memory/sessions/2026-11-08-f1-3-architecture.md | docs/memory/sessions/2026-11-08-f1-3-architecture.md | conservar |
| docs/memory/sessions/2026-11-08-f1-4-modular-structure.md | docs/memory/sessions/2026-11-08-f1-4-modular-structure.md | conservar |
| docs/memory/sessions/2026-11-08-flutter-analyze-ci-repair.md | docs/memory/sessions/2026-11-08-flutter-analyze-ci-repair.md | conservar |
| docs/memory/sessions/2026-11-09-catalog-local-integration.md | docs/memory/sessions/2026-11-09-catalog-local-integration.md | conservar |
| docs/memory/sessions/2026-11-09-catalog-system.md | docs/memory/sessions/2026-11-09-catalog-system.md | conservar |
| docs/memory/sessions/2026-11-09-f1-10-local-progress.md | docs/memory/sessions/2026-11-09-f1-10-local-progress.md | conservar |
| docs/memory/sessions/2026-11-09-f1-10-typed-progress.md | docs/memory/sessions/2026-11-09-f1-10-typed-progress.md | conservar |
| docs/memory/sessions/2026-11-09-f1-11-sync-contract.md | docs/memory/sessions/2026-11-09-f1-11-sync-contract.md | conservar |
| docs/memory/sessions/2026-11-09-f1-12-core-tests.md | docs/memory/sessions/2026-11-09-f1-12-core-tests.md | conservar |
| docs/memory/sessions/2026-11-09-f1-5-f1-12-real-tests.md | docs/memory/sessions/2026-11-09-f1-5-f1-12-real-tests.md | conservar |
| docs/memory/sessions/2026-11-09-f1-5-settings.md | docs/memory/sessions/2026-11-09-f1-5-settings.md | conservar |
| docs/memory/sessions/2026-11-09-f1-6-drift-storage.md | docs/memory/sessions/2026-11-09-f1-6-drift-storage.md | conservar |
| docs/memory/sessions/2026-11-09-f1-7-core-result-logger.md | docs/memory/sessions/2026-11-09-f1-7-core-result-logger.md | conservar |
| docs/memory/sessions/2026-11-09-f1-8-anilist.md | docs/memory/sessions/2026-11-09-f1-8-anilist.md | conservar |
| docs/memory/sessions/2026-11-09-f1-9-secure-storage.md | docs/memory/sessions/2026-11-09-f1-9-secure-storage.md | conservar |
| docs/memory/sessions/2026-11-09-f2-1-player-evaluation.md | docs/memory/sessions/2026-11-09-f2-1-player-evaluation.md | conservar |
| docs/memory/sessions/2026-11-10-f2-3-keyboard-controls.md | docs/memory/sessions/2026-11-10-f2-3-keyboard-controls.md | conservar |
| docs/memory/sessions/2026-11-10-f2-5-f2-6-progress.md | docs/memory/sessions/2026-11-10-f2-5-f2-6-progress.md | conservar |
| docs/memory/sessions/2026-11-11-f2-8-opensubtitles.md | docs/memory/sessions/2026-11-11-f2-8-opensubtitles.md | conservar |
| docs/memory/sessions/2026-11-14-fase05-1-detail.md | docs/memory/sessions/2026-11-14-fase05-1-detail.md | conservar |
| docs/memory/sessions/2026-11-14-home.md | docs/memory/sessions/2026-11-14-home.md | conservar |
| docs/memory/sessions/2026-11-14-playback-providers-implementation.md | docs/memory/sessions/2026-11-14-playback-providers-implementation.md | conservar |
| docs/memory/sessions/README.md | docs/memory/sessions/README.md | conservar |
| docs/perf/README.md | docs/perf/README.md | conservar |
| docs/perf/S0R-baseline-2026-11-16.tsv | docs/perf/S0R-baseline-2026-11-16.tsv | conservar |
| docs/perf/measure-20261108T055614Z-43216.tsv | docs/perf/measure-20261108T055614Z-43216.tsv | conservar |
| docs/perf/measure-20261108T132806Z-12361.tsv | docs/perf/measure-20261108T132806Z-12361.tsv | conservar |
| docs/perf/measure-20261108T133059Z-14183.tsv | docs/perf/measure-20261108T133059Z-14183.tsv | conservar |
| docs/perf/measure-20261108T133341Z-15982.tsv | docs/perf/measure-20261108T133341Z-15982.tsv | conservar |
| docs/perf/wayland-window-20261108.png | docs/perf/wayland-window-20261108.png | conservar |
| docs/player/F2.2-spike-report-v2.md | docs/player/F2.2-spike-report-v2.md | conservar |
| docs/player/F2.2-spike-report.md | docs/player/F2.2-spike-report.md | conservar |
| docs/player/README.md | docs/player/README.md | conservar |
| docs/player/demo-morevna.md | docs/player/demo-morevna.md | conservar |
| docs/player/operacion-extendida.md | docs/player/operacion-extendida.md | conservar |
| docs/refactor/API_PARSE_ERRORS.txt | docs/refactor/API_PARSE_ERRORS.txt | conservar |
| docs/refactor/AUDITORIA.md | docs/refactor/AUDITORIA.md | conservar |
| docs/refactor/BASELINE.md | docs/refactor/BASELINE.md | conservar |
| docs/refactor/BLOQUEOS.md | docs/refactor/BLOQUEOS.md | conservar |
| docs/refactor/CANDIDATOS.md | docs/refactor/CANDIDATOS.md | conservar |
| docs/refactor/CLASIFICACION_ANALYZE.md | docs/refactor/CLASIFICACION_ANALYZE.md | conservar |
| docs/refactor/CONTRATOS_REFERENCIAS.md | docs/refactor/CONTRATOS_REFERENCIAS.md | conservar |
| docs/refactor/DUPLICADOS.md | docs/refactor/DUPLICADOS.md | conservar |
| docs/refactor/IMPORTS.md | docs/refactor/IMPORTS.md | conservar |
| docs/refactor/INVENTARIO.md | docs/refactor/INVENTARIO.md | conservar |
| docs/refactor/INVESTIGACION.md | docs/refactor/INVESTIGACION.md | conservar |
| docs/refactor/MAPA_ARCHIVOS.md | docs/refactor/MAPA_ARCHIVOS.md | conservar |
| docs/refactor/MATRIZ_PARIDAD.md | docs/refactor/MATRIZ_PARIDAD.md | conservar |
| docs/refactor/PLAN.md | docs/refactor/PLAN.md | conservar |
| docs/refactor/PLATAFORMAS.md | docs/refactor/PLATAFORMAS.md | conservar |
| docs/refactor/PROTEGIDO.md | docs/refactor/PROTEGIDO.md | conservar |
| docs/refactor/REFERENCIAS.txt | docs/refactor/REFERENCIAS.txt | conservar |
| docs/refactor/RENDIMIENTO.md | docs/refactor/RENDIMIENTO.md | conservar |
| docs/refactor/RESULTADOS_TESTS.md | docs/refactor/RESULTADOS_TESTS.md | conservar |
| docs/refactor/WIDGET_SIZES.txt | docs/refactor/WIDGET_SIZES.txt | conservar |
| docs/refactor/contract-index.json | docs/refactor/contract-index.json | conservar |
| docs/refactor/generate_api.dart | docs/refactor/generate_api.dart | conservar |
| docs/refactor/generate_fixture_harnesses.py | docs/refactor/generate_fixture_harnesses.py | conservar |
| docs/refactor/logs/analyze_baseline.txt | docs/refactor/logs/analyze_baseline.txt | conservar |
| docs/refactor/logs/analyze_new_tests.txt | docs/refactor/logs/analyze_new_tests.txt | conservar |
| docs/refactor/logs/api_inventory.txt | docs/refactor/logs/api_inventory.txt | conservar |
| docs/refactor/logs/build_linux.txt | docs/refactor/logs/build_linux.txt | conservar |
| docs/refactor/logs/capture_additional_sources.txt | docs/refactor/logs/capture_additional_sources.txt | conservar |
| docs/refactor/logs/capture_golden.txt | docs/refactor/logs/capture_golden.txt | conservar |
| docs/refactor/logs/capture_public_golden.txt | docs/refactor/logs/capture_public_golden.txt | conservar |
| docs/refactor/logs/capture_sources.txt | docs/refactor/logs/capture_sources.txt | conservar |
| docs/refactor/logs/capture_transport.txt | docs/refactor/logs/capture_transport.txt | conservar |
| docs/refactor/logs/format.txt | docs/refactor/logs/format.txt | conservar |
| docs/refactor/logs/format_sources.txt | docs/refactor/logs/format_sources.txt | conservar |
| docs/refactor/logs/format_transport.txt | docs/refactor/logs/format_transport.txt | conservar |
| docs/refactor/logs/golden.txt | docs/refactor/logs/golden.txt | conservar |
| docs/refactor/logs/golden_all.txt | docs/refactor/logs/golden_all.txt | conservar |
| docs/refactor/logs/golden_sources.txt | docs/refactor/logs/golden_sources.txt | conservar |
| docs/refactor/logs/golden_timestamp_failure.txt | docs/refactor/logs/golden_timestamp_failure.txt | conservar |
| docs/refactor/logs/run_baseline.sh | docs/refactor/logs/run_baseline.sh | conservar |
| docs/refactor/logs/test_application.txt | docs/refactor/logs/test_application.txt | conservar |
| docs/refactor/logs/test_baseline.txt | docs/refactor/logs/test_baseline.txt | conservar |
| docs/refactor/logs/test_catalog.txt | docs/refactor/logs/test_catalog.txt | conservar |
| docs/refactor/logs/test_core.txt | docs/refactor/logs/test_core.txt | conservar |
| docs/refactor/logs/test_data.txt | docs/refactor/logs/test_data.txt | conservar |
| docs/refactor/logs/test_domain.txt | docs/refactor/logs/test_domain.txt | conservar |
| docs/refactor/logs/test_home.txt | docs/refactor/logs/test_home.txt | conservar |
| docs/refactor/logs/test_player.txt | docs/refactor/logs/test_player.txt | conservar |
| docs/refactor/logs/test_settings.txt | docs/refactor/logs/test_settings.txt | conservar |
| docs/refactor/logs/test_tool.txt | docs/refactor/logs/test_tool.txt | conservar |
| docs/refactor/protected-sha256.json | docs/refactor/protected-sha256.json | conservar |
| docs/refactor/snapshot_api.txt | docs/refactor/snapshot_api.txt | conservar |
| docs/refactor/source-sha256.json | docs/refactor/source-sha256.json | conservar |
| docs/requirements/F1.1-CORE-REQUIREMENTS.md | docs/requirements/F1.1-CORE-REQUIREMENTS.md | conservar |
| docs/third-party/ANILILI-MIT-0.md | docs/third-party/ANILILI-MIT-0.md | conservar |
| docs/third-party/OPENH264-BINARY-LICENSE.txt | docs/third-party/OPENH264-BINARY-LICENSE.txt | conservar |
| docs/third-party/PLAYBACK-DEPENDENCIES.md | docs/third-party/PLAYBACK-DEPENDENCIES.md | conservar |
| docs/ui/ANIME_DETAIL.md | docs/ui/ANIME_DETAIL.md | conservar |
| docs/ui/HOME.md | docs/ui/HOME.md | conservar |
| docs/validation/2026-11-09-f1-5-f1-12-real-tests.md | docs/validation/2026-11-09-f1-5-f1-12-real-tests.md | conservar |
| scripts/README.md | scripts/README.md | conservar |
| scripts/check_imports.dart | scripts/check_imports.dart | conservar |
| scripts/ci.sh | scripts/ci.sh | conservar |
| scripts/measure.sh | scripts/measure.sh | conservar |
| scripts/test_check_imports.sh | scripts/test_check_imports.sh | conservar |
| tests/ai/README.md | tests/ai/README.md | conservar |
| tests/ai/test_autonomy.py | tests/ai/test_autonomy.py | conservar |
| tests/ai/test_evaluate.py | tests/ai/test_evaluate.py | conservar |
| tests/ai/test_memory.py | tests/ai/test_memory.py | conservar |
| tools/ai/README.md | tools/ai/README.md | conservar |
| tools/ai/autonomy.py | tools/ai/autonomy.py | conservar |
| tools/ai/evaluate.py | tools/ai/evaluate.py | conservar |
| tools/ai/memory.py | tools/ai/memory.py | conservar |
| tools/ai/missions/README.md | tools/ai/missions/README.md | conservar |
| tools/ai/missions/smoke.json | tools/ai/missions/smoke.json | conservar |
| tools/flutter/apply_flutter_3479_lsp_patch.sh | tools/flutter/apply_flutter_3479_lsp_patch.sh | conservar |
| tools/flutter/patches/flutter-3.47.9-lsp-content-length-utf8.patch | tools/flutter/patches/flutter-3.47.9-lsp-content-length-utf8.patch | conservar |
| tools/player/capture_f2_2_owner_close.sh | tools/player/capture_f2_2_owner_close.sh | conservar |
| tools/player/generate_f2_2_fixture.sh | tools/player/generate_f2_2_fixture.sh | conservar |
| tools/player/generate_f2_6_subtitle_fixture.sh | tools/player/generate_f2_6_subtitle_fixture.sh | conservar |
| tools/player/generate_player_demo.py | tools/player/generate_player_demo.py | conservar |
| tools/player/prepare_real_player_demo.py | tools/player/prepare_real_player_demo.py | conservar |
| tools/player/run_f2_2_spike.sh | tools/player/run_f2_2_spike.sh | conservar |
| tools/player/run_f2_6_subtitle_spike.sh | tools/player/run_f2_6_subtitle_spike.sh | conservar |
| tools/player/run_kongroo_linux.sh | tools/player/run_kongroo_linux.sh | conservar |
| tools/player/run_player_demo.py | tools/player/run_player_demo.py | conservar |
| tools/player/test_f2_2_fixture_guards.sh | tools/player/test_f2_2_fixture_guards.sh | conservar |
| tools/player/verify_f2_2_close_gate.dart | tools/player/verify_f2_2_close_gate.dart | conservar |
| tools/refactor/snapshot.py | tools/refactor/snapshot.py | conservar |

## 10. Matriz individual completa

# Matriz individual de paridad

Estado pendiente significa revalidar tras movimiento; el código está presente en el respaldo. No se afirma equivalencia ejecutada.

| ID | Tipo | Actual | Destino | Estado |
| --- | --- | --- | --- | --- |
| S0001 | símbolo | app/lib/app/anime_app.dart:9 | app/lib/core/bootstrap/anime_app.dart | pendiente |
| S0002 | símbolo | app/lib/app/anime_app.dart:10 | app/lib/core/bootstrap/anime_app.dart | pendiente |
| S0003 | símbolo | app/lib/app/anime_app.dart:16 | app/lib/core/bootstrap/anime_app.dart | pendiente |
| S0004 | símbolo | app/lib/app/anime_app.dart:17 | app/lib/core/bootstrap/anime_app.dart | pendiente |
| S0005 | símbolo | app/lib/app/anime_app.dart:19 | app/lib/core/bootstrap/anime_app.dart | pendiente |
| S0006 | símbolo | app/lib/app/catalog/anime_detail_page.dart:18 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0007 | símbolo | app/lib/app/catalog/anime_detail_page.dart:19 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0008 | símbolo | app/lib/app/catalog/anime_detail_page.dart:30 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0009 | símbolo | app/lib/app/catalog/anime_detail_page.dart:31 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0010 | símbolo | app/lib/app/catalog/anime_detail_page.dart:32 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0011 | símbolo | app/lib/app/catalog/anime_detail_page.dart:33 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0012 | símbolo | app/lib/app/catalog/anime_detail_page.dart:34 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0013 | símbolo | app/lib/app/catalog/anime_detail_page.dart:35 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0014 | símbolo | app/lib/app/catalog/anime_detail_page.dart:36 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0015 | símbolo | app/lib/app/catalog/anime_detail_page.dart:38 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| S0016 | símbolo | app/lib/app/catalog/catalog_home_page.dart:34 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| S0017 | símbolo | app/lib/app/catalog/catalog_home_page.dart:35 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| S0018 | símbolo | app/lib/app/catalog/catalog_home_page.dart:41 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| S0019 | símbolo | app/lib/app/catalog/catalog_home_page.dart:42 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| S0020 | símbolo | app/lib/app/catalog/catalog_home_page.dart:44 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| S0021 | símbolo | app/lib/app/catalog/catalog_module.dart:17 | app/lib/features/home/view_model/catalog_module.dart | pendiente |
| S0022 | símbolo | app/lib/app/catalog/catalog_module.dart:26 | app/lib/features/home/view_model/catalog_module.dart | pendiente |
| S0023 | símbolo | app/lib/app/catalog/catalog_module.dart:27 | app/lib/features/home/view_model/catalog_module.dart | pendiente |
| S0024 | símbolo | app/lib/app/catalog/catalog_module.dart:28 | app/lib/features/home/view_model/catalog_module.dart | pendiente |
| S0025 | símbolo | app/lib/app/catalog/catalog_module.dart:29 | app/lib/features/home/view_model/catalog_module.dart | pendiente |
| S0026 | símbolo | app/lib/app/catalog/catalog_module.dart:31 | app/lib/features/home/view_model/catalog_module.dart | pendiente |
| S0027 | símbolo | app/lib/app/catalog/catalog_module.dart:75 | app/lib/features/home/view_model/catalog_module.dart | pendiente |
| S0028 | símbolo | app/lib/app/catalog/catalog_search_page.dart:6 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| S0029 | símbolo | app/lib/app/catalog/catalog_search_page.dart:7 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| S0030 | símbolo | app/lib/app/catalog/catalog_search_page.dart:13 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| S0031 | símbolo | app/lib/app/catalog/catalog_search_page.dart:14 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| S0032 | símbolo | app/lib/app/catalog/catalog_search_page.dart:16 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| S0033 | símbolo | app/lib/app/catalog/confirm_completed_status.dart:3 | app/lib/features/home/view/confirm_completed_status.dart | pendiente |
| S0034 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:5 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0035 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:6 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0036 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:17 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0037 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:18 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0038 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:19 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0039 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:20 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0040 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:21 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0041 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:22 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0042 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:23 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0043 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:27 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| S0044 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:9 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0045 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:10 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0046 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:28 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0047 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:29 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0048 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:30 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0049 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:31 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0050 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:32 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0051 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:33 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0052 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:34 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0053 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:35 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0054 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:36 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0055 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:37 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0056 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:38 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0057 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:39 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0058 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:40 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0059 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:41 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0060 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:43 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| S0061 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:3 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0062 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:4 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0063 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:5 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0064 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:6 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0065 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:7 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0066 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:8 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0067 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:9 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0068 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:11 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0069 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:12 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0070 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:15 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0071 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:16 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0072 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:22 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0073 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:23 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0074 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:25 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| S0075 | símbolo | app/lib/app/catalog/local_library_page.dart:8 | app/lib/features/home/view/local_library_page.dart | pendiente |
| S0076 | símbolo | app/lib/app/catalog/local_library_page.dart:9 | app/lib/features/home/view/local_library_page.dart | pendiente |
| S0077 | símbolo | app/lib/app/catalog/local_library_page.dart:16 | app/lib/features/home/view/local_library_page.dart | pendiente |
| S0078 | símbolo | app/lib/app/catalog/local_library_page.dart:17 | app/lib/features/home/view/local_library_page.dart | pendiente |
| S0079 | símbolo | app/lib/app/catalog/local_library_page.dart:18 | app/lib/features/home/view/local_library_page.dart | pendiente |
| S0080 | símbolo | app/lib/app/catalog/local_library_page.dart:20 | app/lib/features/home/view/local_library_page.dart | pendiente |
| S0081 | símbolo | app/lib/app/catalog/playback_resolution_message.dart:4 | app/lib/features/home/view/playback_resolution_message.dart | pendiente |
| S0082 | símbolo | app/lib/app/home/home_appearance.dart:3 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0083 | símbolo | app/lib/app/home/home_appearance.dart:4 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0084 | símbolo | app/lib/app/home/home_appearance.dart:15 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0085 | símbolo | app/lib/app/home/home_appearance.dart:16 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0086 | símbolo | app/lib/app/home/home_appearance.dart:17 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0087 | símbolo | app/lib/app/home/home_appearance.dart:18 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0088 | símbolo | app/lib/app/home/home_appearance.dart:19 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0089 | símbolo | app/lib/app/home/home_appearance.dart:20 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0090 | símbolo | app/lib/app/home/home_appearance.dart:23 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0091 | símbolo | app/lib/app/home/home_appearance.dart:24 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0092 | símbolo | app/lib/app/home/home_appearance.dart:25 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0093 | símbolo | app/lib/app/home/home_appearance.dart:27 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0094 | símbolo | app/lib/app/home/home_appearance.dart:30 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0095 | símbolo | app/lib/app/home/home_appearance.dart:52 | app/lib/features/home/view/home_appearance.dart | pendiente |
| S0096 | símbolo | app/lib/app/home/home_artwork.dart:6 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0097 | símbolo | app/lib/app/home/home_artwork.dart:7 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0098 | símbolo | app/lib/app/home/home_artwork.dart:16 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0099 | símbolo | app/lib/app/home/home_artwork.dart:17 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0100 | símbolo | app/lib/app/home/home_artwork.dart:18 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0101 | símbolo | app/lib/app/home/home_artwork.dart:19 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0102 | símbolo | app/lib/app/home/home_artwork.dart:20 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0103 | símbolo | app/lib/app/home/home_artwork.dart:22 | app/lib/features/home/view/home_artwork.dart | pendiente |
| S0104 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:7 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| S0105 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:12 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| S0106 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:17 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| S0107 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:19 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| S0108 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:21 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| S0109 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:29 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| S0110 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:43 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| S0111 | símbolo | app/lib/app/home/home_card_actions.dart:10 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0112 | símbolo | app/lib/app/home/home_card_actions.dart:12 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0113 | símbolo | app/lib/app/home/home_card_actions.dart:18 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0114 | símbolo | app/lib/app/home/home_card_actions.dart:24 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0115 | símbolo | app/lib/app/home/home_card_actions.dart:29 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0116 | símbolo | app/lib/app/home/home_card_actions.dart:35 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0117 | símbolo | app/lib/app/home/home_card_actions.dart:42 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0118 | símbolo | app/lib/app/home/home_card_actions.dart:43 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0119 | símbolo | app/lib/app/home/home_card_actions.dart:44 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0120 | símbolo | app/lib/app/home/home_card_actions.dart:45 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0121 | símbolo | app/lib/app/home/home_card_actions.dart:46 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0122 | símbolo | app/lib/app/home/home_card_actions.dart:49 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0123 | símbolo | app/lib/app/home/home_card_actions.dart:61 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0124 | símbolo | app/lib/app/home/home_card_actions.dart:68 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0125 | símbolo | app/lib/app/home/home_card_actions.dart:78 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0126 | símbolo | app/lib/app/home/home_card_actions.dart:85 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0127 | símbolo | app/lib/app/home/home_card_actions.dart:88 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0128 | símbolo | app/lib/app/home/home_card_actions.dart:97 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0129 | símbolo | app/lib/app/home/home_card_actions.dart:108 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| S0130 | símbolo | app/lib/app/home/home_data.dart:11 | app/lib/features/home/view/home_data.dart | pendiente |
| S0131 | símbolo | app/lib/app/home/home_data.dart:13 | app/lib/features/home/view/home_data.dart | pendiente |
| S0132 | símbolo | app/lib/app/home/home_data.dart:14 | app/lib/features/home/view/home_data.dart | pendiente |
| S0133 | símbolo | app/lib/app/home/home_data.dart:30 | app/lib/features/home/view/home_data.dart | pendiente |
| S0134 | símbolo | app/lib/app/home/home_data.dart:31 | app/lib/features/home/view/home_data.dart | pendiente |
| S0135 | símbolo | app/lib/app/home/home_data.dart:32 | app/lib/features/home/view/home_data.dart | pendiente |
| S0136 | símbolo | app/lib/app/home/home_data.dart:33 | app/lib/features/home/view/home_data.dart | pendiente |
| S0137 | símbolo | app/lib/app/home/home_data.dart:34 | app/lib/features/home/view/home_data.dart | pendiente |
| S0138 | símbolo | app/lib/app/home/home_data.dart:35 | app/lib/features/home/view/home_data.dart | pendiente |
| S0139 | símbolo | app/lib/app/home/home_data.dart:36 | app/lib/features/home/view/home_data.dart | pendiente |
| S0140 | símbolo | app/lib/app/home/home_data.dart:37 | app/lib/features/home/view/home_data.dart | pendiente |
| S0141 | símbolo | app/lib/app/home/home_data.dart:38 | app/lib/features/home/view/home_data.dart | pendiente |
| S0142 | símbolo | app/lib/app/home/home_data.dart:39 | app/lib/features/home/view/home_data.dart | pendiente |
| S0143 | símbolo | app/lib/app/home/home_data.dart:40 | app/lib/features/home/view/home_data.dart | pendiente |
| S0144 | símbolo | app/lib/app/home/home_data.dart:41 | app/lib/features/home/view/home_data.dart | pendiente |
| S0145 | símbolo | app/lib/app/home/home_data.dart:42 | app/lib/features/home/view/home_data.dart | pendiente |
| S0146 | símbolo | app/lib/app/home/home_data.dart:45 | app/lib/features/home/view/home_data.dart | pendiente |
| S0147 | símbolo | app/lib/app/home/home_data.dart:46 | app/lib/features/home/view/home_data.dart | pendiente |
| S0148 | símbolo | app/lib/app/home/home_data.dart:54 | app/lib/features/home/view/home_data.dart | pendiente |
| S0149 | símbolo | app/lib/app/home/home_data.dart:55 | app/lib/features/home/view/home_data.dart | pendiente |
| S0150 | símbolo | app/lib/app/home/home_data.dart:56 | app/lib/features/home/view/home_data.dart | pendiente |
| S0151 | símbolo | app/lib/app/home/home_data.dart:57 | app/lib/features/home/view/home_data.dart | pendiente |
| S0152 | símbolo | app/lib/app/home/home_data.dart:58 | app/lib/features/home/view/home_data.dart | pendiente |
| S0153 | símbolo | app/lib/app/home/home_data.dart:60 | app/lib/features/home/view/home_data.dart | pendiente |
| S0154 | símbolo | app/lib/app/home/home_data.dart:63 | app/lib/features/home/view/home_data.dart | pendiente |
| S0155 | símbolo | app/lib/app/home/home_data.dart:65 | app/lib/features/home/view/home_data.dart | pendiente |
| S0156 | símbolo | app/lib/app/home/home_data.dart:66 | app/lib/features/home/view/home_data.dart | pendiente |
| S0157 | símbolo | app/lib/app/home/home_data.dart:75 | app/lib/features/home/view/home_data.dart | pendiente |
| S0158 | símbolo | app/lib/app/home/home_data.dart:76 | app/lib/features/home/view/home_data.dart | pendiente |
| S0159 | símbolo | app/lib/app/home/home_data.dart:77 | app/lib/features/home/view/home_data.dart | pendiente |
| S0160 | símbolo | app/lib/app/home/home_data.dart:78 | app/lib/features/home/view/home_data.dart | pendiente |
| S0161 | símbolo | app/lib/app/home/home_data.dart:79 | app/lib/features/home/view/home_data.dart | pendiente |
| S0162 | símbolo | app/lib/app/home/home_data.dart:80 | app/lib/features/home/view/home_data.dart | pendiente |
| S0163 | símbolo | app/lib/app/home/home_data.dart:82 | app/lib/features/home/view/home_data.dart | pendiente |
| S0164 | símbolo | app/lib/app/home/home_data.dart:89 | app/lib/features/home/view/home_data.dart | pendiente |
| S0165 | símbolo | app/lib/app/home/home_data.dart:91 | app/lib/features/home/view/home_data.dart | pendiente |
| S0166 | símbolo | app/lib/app/home/home_data.dart:92 | app/lib/features/home/view/home_data.dart | pendiente |
| S0167 | símbolo | app/lib/app/home/home_data.dart:93 | app/lib/features/home/view/home_data.dart | pendiente |
| S0168 | símbolo | app/lib/app/home/home_data.dart:96 | app/lib/features/home/view/home_data.dart | pendiente |
| S0169 | símbolo | app/lib/app/home/home_data.dart:98 | app/lib/features/home/view/home_data.dart | pendiente |
| S0170 | símbolo | app/lib/app/home/home_hero.dart:11 | app/lib/features/home/view/home_hero.dart | pendiente |
| S0171 | símbolo | app/lib/app/home/home_hero.dart:13 | app/lib/features/home/view/home_hero.dart | pendiente |
| S0172 | símbolo | app/lib/app/home/home_hero.dart:21 | app/lib/features/home/view/home_hero.dart | pendiente |
| S0173 | símbolo | app/lib/app/home/home_hero.dart:22 | app/lib/features/home/view/home_hero.dart | pendiente |
| S0174 | símbolo | app/lib/app/home/home_hero.dart:23 | app/lib/features/home/view/home_hero.dart | pendiente |
| S0175 | símbolo | app/lib/app/home/home_hero.dart:24 | app/lib/features/home/view/home_hero.dart | pendiente |
| S0176 | símbolo | app/lib/app/home/home_hero.dart:26 | app/lib/features/home/view/home_hero.dart | pendiente |
| S0177 | símbolo | app/lib/app/home/home_icons.dart:3 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0178 | símbolo | app/lib/app/home/home_icons.dart:4 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0179 | símbolo | app/lib/app/home/home_icons.dart:5 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0180 | símbolo | app/lib/app/home/home_icons.dart:6 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0181 | símbolo | app/lib/app/home/home_icons.dart:7 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0182 | símbolo | app/lib/app/home/home_icons.dart:8 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0183 | símbolo | app/lib/app/home/home_icons.dart:9 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0184 | símbolo | app/lib/app/home/home_icons.dart:10 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0185 | símbolo | app/lib/app/home/home_icons.dart:11 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0186 | símbolo | app/lib/app/home/home_icons.dart:12 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0187 | símbolo | app/lib/app/home/home_icons.dart:13 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0188 | símbolo | app/lib/app/home/home_icons.dart:14 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0189 | símbolo | app/lib/app/home/home_icons.dart:15 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0190 | símbolo | app/lib/app/home/home_icons.dart:16 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0191 | símbolo | app/lib/app/home/home_icons.dart:17 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0192 | símbolo | app/lib/app/home/home_icons.dart:18 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0193 | símbolo | app/lib/app/home/home_icons.dart:19 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0194 | símbolo | app/lib/app/home/home_icons.dart:20 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0195 | símbolo | app/lib/app/home/home_icons.dart:23 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0196 | símbolo | app/lib/app/home/home_icons.dart:25 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0197 | símbolo | app/lib/app/home/home_icons.dart:45 | app/lib/features/home/view/home_icons.dart | pendiente |
| S0198 | símbolo | app/lib/app/home/home_score_badge.dart:5 | app/lib/features/home/view/home_score_badge.dart | pendiente |
| S0199 | símbolo | app/lib/app/home/home_score_badge.dart:7 | app/lib/features/home/view/home_score_badge.dart | pendiente |
| S0200 | símbolo | app/lib/app/home/home_score_badge.dart:9 | app/lib/features/home/view/home_score_badge.dart | pendiente |
| S0201 | símbolo | app/lib/app/home/home_score_badge.dart:10 | app/lib/features/home/view/home_score_badge.dart | pendiente |
| S0202 | símbolo | app/lib/app/home/home_score_badge.dart:12 | app/lib/features/home/view/home_score_badge.dart | pendiente |
| S0203 | símbolo | app/lib/app/home/home_score_badge.dart:14 | app/lib/features/home/view/home_score_badge.dart | pendiente |
| S0204 | símbolo | app/lib/app/home/home_screen.dart:11 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0205 | símbolo | app/lib/app/home/home_screen.dart:12 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0206 | símbolo | app/lib/app/home/home_screen.dart:21 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0207 | símbolo | app/lib/app/home/home_screen.dart:22 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0208 | símbolo | app/lib/app/home/home_screen.dart:24 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0209 | símbolo | app/lib/app/home/home_screen.dart:25 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0210 | símbolo | app/lib/app/home/home_screen.dart:26 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0211 | símbolo | app/lib/app/home/home_screen.dart:28 | app/lib/features/home/view/home_screen.dart | pendiente |
| S0212 | símbolo | app/lib/app/home/home_sections.dart:12 | app/lib/features/home/view/home_sections.dart | pendiente |
| S0213 | símbolo | app/lib/app/home/home_sections.dart:13 | app/lib/features/home/view/home_sections.dart | pendiente |
| S0214 | símbolo | app/lib/app/home/home_typography.dart:5 | app/lib/features/home/view/home_typography.dart | pendiente |
| S0215 | símbolo | app/lib/app/home/home_typography.dart:8 | app/lib/features/home/view/home_typography.dart | pendiente |
| S0216 | símbolo | app/lib/app/home/home_typography.dart:16 | app/lib/features/home/view/home_typography.dart | pendiente |
| S0217 | símbolo | app/lib/app/home/home_typography.dart:23 | app/lib/features/home/view/home_typography.dart | pendiente |
| S0218 | símbolo | app/lib/app/player/audio_track_selector.dart:5 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0219 | símbolo | app/lib/app/player/audio_track_selector.dart:6 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0220 | símbolo | app/lib/app/player/audio_track_selector.dart:15 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0221 | símbolo | app/lib/app/player/audio_track_selector.dart:16 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0222 | símbolo | app/lib/app/player/audio_track_selector.dart:17 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0223 | símbolo | app/lib/app/player/audio_track_selector.dart:18 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0224 | símbolo | app/lib/app/player/audio_track_selector.dart:20 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0225 | símbolo | app/lib/app/player/audio_track_selector.dart:22 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| S0226 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:7 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| S0227 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:10 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| S0228 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:16 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| S0229 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:17 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| S0230 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:19 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| S0231 | símbolo | app/lib/app/player/media_kit_video_surface.dart:6 | app/lib/features/player/view/media_kit_video_surface.dart | pendiente |
| S0232 | símbolo | app/lib/app/player/media_kit_video_surface.dart:8 | app/lib/features/player/view/media_kit_video_surface.dart | pendiente |
| S0233 | símbolo | app/lib/app/player/media_kit_video_surface.dart:14 | app/lib/features/player/view/media_kit_video_surface.dart | pendiente |
| S0234 | símbolo | app/lib/app/player/media_kit_video_surface.dart:15 | app/lib/features/player/view/media_kit_video_surface.dart | pendiente |
| S0235 | símbolo | app/lib/app/player/media_kit_video_surface.dart:17 | app/lib/features/player/view/media_kit_video_surface.dart | pendiente |
| S0236 | símbolo | app/lib/app/player/media_kit_video_surface.dart:29 | app/lib/features/player/view/media_kit_video_surface.dart | pendiente |
| S0237 | símbolo | app/lib/app/player/media_kit_video_surface.dart:45 | app/lib/features/player/view/media_kit_video_surface.dart | pendiente |
| S0238 | símbolo | app/lib/app/player/playback_route_session.dart:7 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0239 | símbolo | app/lib/app/player/playback_route_session.dart:12 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0240 | símbolo | app/lib/app/player/playback_route_session.dart:14 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0241 | símbolo | app/lib/app/player/playback_route_session.dart:17 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0242 | símbolo | app/lib/app/player/playback_route_session.dart:23 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0243 | símbolo | app/lib/app/player/playback_route_session.dart:25 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0244 | símbolo | app/lib/app/player/playback_route_session.dart:27 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0245 | símbolo | app/lib/app/player/playback_route_session.dart:29 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0246 | símbolo | app/lib/app/player/playback_route_session.dart:34 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0247 | símbolo | app/lib/app/player/playback_route_session.dart:35 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0248 | símbolo | app/lib/app/player/playback_route_session.dart:38 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0249 | símbolo | app/lib/app/player/playback_route_session.dart:43 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0250 | símbolo | app/lib/app/player/playback_route_session.dart:47 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0251 | símbolo | app/lib/app/player/playback_route_session.dart:49 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0252 | símbolo | app/lib/app/player/playback_route_session.dart:55 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0253 | símbolo | app/lib/app/player/playback_route_session.dart:56 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0254 | símbolo | app/lib/app/player/playback_route_session.dart:57 | app/lib/features/player/view/playback_route_session.dart | pendiente |
| S0255 | símbolo | app/lib/app/player/player_demo_panel.dart:8 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| S0256 | símbolo | app/lib/app/player/player_demo_panel.dart:9 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| S0257 | símbolo | app/lib/app/player/player_demo_panel.dart:15 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| S0258 | símbolo | app/lib/app/player/player_demo_panel.dart:16 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| S0259 | símbolo | app/lib/app/player/player_demo_panel.dart:18 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| S0260 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:6 | app/lib/features/player/view/player_frame_timing_probe.dart | pendiente |
| S0261 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:8 | app/lib/features/player/view/player_frame_timing_probe.dart | pendiente |
| S0262 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:13 | app/lib/features/player/view/player_frame_timing_probe.dart | pendiente |
| S0263 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:43 | app/lib/features/player/view/player_frame_timing_probe.dart | pendiente |
| S0264 | símbolo | app/lib/app/player/player_nerd_panel.dart:6 | app/lib/features/player/view/player_nerd_panel.dart | pendiente |
| S0265 | símbolo | app/lib/app/player/player_nerd_panel.dart:8 | app/lib/features/player/view/player_nerd_panel.dart | pendiente |
| S0266 | símbolo | app/lib/app/player/player_nerd_panel.dart:15 | app/lib/features/player/view/player_nerd_panel.dart | pendiente |
| S0267 | símbolo | app/lib/app/player/player_nerd_panel.dart:16 | app/lib/features/player/view/player_nerd_panel.dart | pendiente |
| S0268 | símbolo | app/lib/app/player/player_nerd_panel.dart:17 | app/lib/features/player/view/player_nerd_panel.dart | pendiente |
| S0269 | símbolo | app/lib/app/player/player_nerd_panel.dart:19 | app/lib/features/player/view/player_nerd_panel.dart | pendiente |
| S0270 | símbolo | app/lib/app/player/player_quality_panel.dart:5 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0271 | símbolo | app/lib/app/player/player_quality_panel.dart:8 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0272 | símbolo | app/lib/app/player/player_quality_panel.dart:17 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0273 | símbolo | app/lib/app/player/player_quality_panel.dart:18 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0274 | símbolo | app/lib/app/player/player_quality_panel.dart:19 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0275 | símbolo | app/lib/app/player/player_quality_panel.dart:20 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0276 | símbolo | app/lib/app/player/player_quality_panel.dart:22 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0277 | símbolo | app/lib/app/player/player_quality_panel.dart:24 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| S0278 | símbolo | app/lib/app/player/player_subtitle_panel.dart:12 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0279 | símbolo | app/lib/app/player/player_subtitle_panel.dart:14 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0280 | símbolo | app/lib/app/player/player_subtitle_panel.dart:16 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0281 | símbolo | app/lib/app/player/player_subtitle_panel.dart:17 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0282 | símbolo | app/lib/app/player/player_subtitle_panel.dart:20 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0283 | símbolo | app/lib/app/player/player_subtitle_panel.dart:21 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0284 | símbolo | app/lib/app/player/player_subtitle_panel.dart:28 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0285 | símbolo | app/lib/app/player/player_subtitle_panel.dart:29 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0286 | símbolo | app/lib/app/player/player_subtitle_panel.dart:30 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0287 | símbolo | app/lib/app/player/player_subtitle_panel.dart:32 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| S0288 | símbolo | app/lib/app/player/player_video_display.dart:3 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0289 | símbolo | app/lib/app/player/player_video_display.dart:4 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0290 | símbolo | app/lib/app/player/player_video_display.dart:4 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0291 | símbolo | app/lib/app/player/player_video_display.dart:4 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0292 | símbolo | app/lib/app/player/player_video_display.dart:4 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0293 | símbolo | app/lib/app/player/player_video_display.dart:6 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0294 | símbolo | app/lib/app/player/player_video_display.dart:6 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0295 | símbolo | app/lib/app/player/player_video_display.dart:6 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0296 | símbolo | app/lib/app/player/player_video_display.dart:6 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0297 | símbolo | app/lib/app/player/player_video_display.dart:6 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0298 | símbolo | app/lib/app/player/player_video_display.dart:8 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0299 | símbolo | app/lib/app/player/player_video_display.dart:10 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0300 | símbolo | app/lib/app/player/player_video_display.dart:15 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0301 | símbolo | app/lib/app/player/player_video_display.dart:16 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0302 | símbolo | app/lib/app/player/player_video_display.dart:18 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0303 | símbolo | app/lib/app/player/player_video_display.dart:26 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0304 | símbolo | app/lib/app/player/player_video_display.dart:34 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0305 | símbolo | app/lib/app/player/player_video_display.dart:37 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0306 | símbolo | app/lib/app/player/player_video_display.dart:39 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0307 | símbolo | app/lib/app/player/player_video_display.dart:42 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0308 | símbolo | app/lib/app/player/player_video_display.dart:45 | app/lib/features/player/view/player_video_display.dart | pendiente |
| S0309 | símbolo | app/lib/app/player/player_video_display_panel.dart:7 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| S0310 | símbolo | app/lib/app/player/player_video_display_panel.dart:9 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| S0311 | símbolo | app/lib/app/player/player_video_display_panel.dart:11 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| S0312 | símbolo | app/lib/app/player/player_video_display_panel.dart:13 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| S0313 | símbolo | app/lib/app/player/player_video_layout.dart:3 | app/lib/features/player/view/player_video_layout.dart | pendiente |
| S0314 | símbolo | app/lib/app/player/player_video_layout.dart:5 | app/lib/features/player/view/player_video_layout.dart | pendiente |
| S0315 | símbolo | app/lib/app/player/player_video_layout.dart:12 | app/lib/features/player/view/player_video_layout.dart | pendiente |
| S0316 | símbolo | app/lib/app/player/player_video_layout.dart:13 | app/lib/features/player/view/player_video_layout.dart | pendiente |
| S0317 | símbolo | app/lib/app/player/player_video_layout.dart:14 | app/lib/features/player/view/player_video_layout.dart | pendiente |
| S0318 | símbolo | app/lib/app/player/player_video_layout.dart:16 | app/lib/features/player/view/player_video_layout.dart | pendiente |
| S0319 | símbolo | app/lib/app/player/player_window_controller.dart:5 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0320 | símbolo | app/lib/app/player/player_window_controller.dart:8 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0321 | símbolo | app/lib/app/player/player_window_controller.dart:9 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0322 | símbolo | app/lib/app/player/player_window_controller.dart:11 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0323 | símbolo | app/lib/app/player/player_window_controller.dart:12 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0324 | símbolo | app/lib/app/player/player_window_controller.dart:13 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0325 | símbolo | app/lib/app/player/player_window_controller.dart:16 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0326 | símbolo | app/lib/app/player/player_window_controller.dart:17 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0327 | símbolo | app/lib/app/player/player_window_controller.dart:24 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0328 | símbolo | app/lib/app/player/player_window_controller.dart:25 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0329 | símbolo | app/lib/app/player/player_window_controller.dart:26 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0330 | símbolo | app/lib/app/player/player_window_controller.dart:27 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0331 | símbolo | app/lib/app/player/player_window_controller.dart:29 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0332 | símbolo | app/lib/app/player/player_window_controller.dart:43 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0333 | símbolo | app/lib/app/player/player_window_controller.dart:46 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0334 | símbolo | app/lib/app/player/player_window_controller.dart:52 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0335 | símbolo | app/lib/app/player/player_window_controller.dart:63 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0336 | símbolo | app/lib/app/player/player_window_controller.dart:66 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0337 | símbolo | app/lib/app/player/player_window_controller.dart:69 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0338 | símbolo | app/lib/app/player/player_window_controller.dart:94 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0339 | símbolo | app/lib/app/player/player_window_controller.dart:193 | app/lib/features/player/view/player_window_controller.dart | pendiente |
| S0340 | símbolo | app/lib/app/player/provider_playback_route.dart:14 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0341 | símbolo | app/lib/app/player/provider_playback_route.dart:18 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0342 | símbolo | app/lib/app/player/provider_playback_route.dart:22 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0343 | símbolo | app/lib/app/player/provider_playback_route.dart:35 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0344 | símbolo | app/lib/app/player/provider_playback_route.dart:36 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0345 | símbolo | app/lib/app/player/provider_playback_route.dart:37 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0346 | símbolo | app/lib/app/player/provider_playback_route.dart:38 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0347 | símbolo | app/lib/app/player/provider_playback_route.dart:39 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0348 | símbolo | app/lib/app/player/provider_playback_route.dart:40 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0349 | símbolo | app/lib/app/player/provider_playback_route.dart:46 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0350 | símbolo | app/lib/app/player/provider_playback_route.dart:47 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0351 | símbolo | app/lib/app/player/provider_playback_route.dart:48 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0352 | símbolo | app/lib/app/player/provider_playback_route.dart:50 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| S0353 | símbolo | app/lib/app/player/skip_segment_panel.dart:8 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| S0354 | símbolo | app/lib/app/player/skip_segment_panel.dart:9 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| S0355 | símbolo | app/lib/app/player/skip_segment_panel.dart:11 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| S0356 | símbolo | app/lib/app/player/skip_segment_panel.dart:13 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| S0357 | símbolo | app/lib/app/player/source_switch_panel.dart:7 | app/lib/features/player/view/source_switch_panel.dart | pendiente |
| S0358 | símbolo | app/lib/app/player/source_switch_panel.dart:9 | app/lib/features/player/view/source_switch_panel.dart | pendiente |
| S0359 | símbolo | app/lib/app/player/source_switch_panel.dart:11 | app/lib/features/player/view/source_switch_panel.dart | pendiente |
| S0360 | símbolo | app/lib/app/player/source_switch_panel.dart:13 | app/lib/features/player/view/source_switch_panel.dart | pendiente |
| S0361 | símbolo | app/lib/app/player/spike_player_module.dart:29 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0362 | símbolo | app/lib/app/player/spike_player_module.dart:47 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0363 | símbolo | app/lib/app/player/spike_player_module.dart:48 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0364 | símbolo | app/lib/app/player/spike_player_module.dart:49 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0365 | símbolo | app/lib/app/player/spike_player_module.dart:50 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0366 | símbolo | app/lib/app/player/spike_player_module.dart:51 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0367 | símbolo | app/lib/app/player/spike_player_module.dart:52 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0368 | símbolo | app/lib/app/player/spike_player_module.dart:53 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0369 | símbolo | app/lib/app/player/spike_player_module.dart:54 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0370 | símbolo | app/lib/app/player/spike_player_module.dart:55 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0371 | símbolo | app/lib/app/player/spike_player_module.dart:58 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0372 | símbolo | app/lib/app/player/spike_player_module.dart:63 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0373 | símbolo | app/lib/app/player/spike_player_module.dart:316 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0374 | símbolo | app/lib/app/player/spike_player_module.dart:328 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0375 | símbolo | app/lib/app/player/spike_player_module.dart:345 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0376 | símbolo | app/lib/app/player/spike_player_module.dart:394 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0377 | símbolo | app/lib/app/player/spike_player_module.dart:399 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0378 | símbolo | app/lib/app/player/spike_player_module.dart:406 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0379 | símbolo | app/lib/app/player/spike_player_module.dart:407 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0380 | símbolo | app/lib/app/player/spike_player_module.dart:408 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0381 | símbolo | app/lib/app/player/spike_player_module.dart:409 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| S0382 | símbolo | app/lib/app/player/spike_player_page.dart:26 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0383 | símbolo | app/lib/app/player/spike_player_page.dart:27 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0384 | símbolo | app/lib/app/player/spike_player_page.dart:29 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0385 | símbolo | app/lib/app/player/spike_player_page.dart:31 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0386 | símbolo | app/lib/app/player/spike_player_page.dart:45 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0387 | símbolo | app/lib/app/player/spike_player_page.dart:46 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0388 | símbolo | app/lib/app/player/spike_player_page.dart:47 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0389 | símbolo | app/lib/app/player/spike_player_page.dart:48 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0390 | símbolo | app/lib/app/player/spike_player_page.dart:49 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0391 | símbolo | app/lib/app/player/spike_player_page.dart:50 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0392 | símbolo | app/lib/app/player/spike_player_page.dart:51 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0393 | símbolo | app/lib/app/player/spike_player_page.dart:52 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0394 | símbolo | app/lib/app/player/spike_player_page.dart:53 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0395 | símbolo | app/lib/app/player/spike_player_page.dart:54 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0396 | símbolo | app/lib/app/player/spike_player_page.dart:56 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| S0397 | símbolo | app/lib/app/player/spike_player_page_options.dart:3 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0398 | símbolo | app/lib/app/player/spike_player_page_options.dart:8 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0399 | símbolo | app/lib/app/player/spike_player_page_options.dart:15 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0400 | símbolo | app/lib/app/player/spike_player_page_options.dart:37 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0401 | símbolo | app/lib/app/player/spike_player_page_options.dart:38 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0402 | símbolo | app/lib/app/player/spike_player_page_options.dart:39 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0403 | símbolo | app/lib/app/player/spike_player_page_options.dart:40 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0404 | símbolo | app/lib/app/player/spike_player_page_options.dart:42 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0405 | símbolo | app/lib/app/player/spike_player_page_options.dart:50 | app/lib/features/player/view/spike_player_page_options.dart | pendiente |
| S0406 | símbolo | app/lib/app/player/spike_window_close_gate.dart:3 | app/lib/features/player/view/spike_window_close_gate.dart | pendiente |
| S0407 | símbolo | app/lib/app/player/spike_window_close_gate.dart:5 | app/lib/features/player/view/spike_window_close_gate.dart | pendiente |
| S0408 | símbolo | app/lib/app/player/spike_window_close_gate.dart:16 | app/lib/features/player/view/spike_window_close_gate.dart | pendiente |
| S0409 | símbolo | app/lib/app/player/spike_window_close_gate.dart:22 | app/lib/features/player/view/spike_window_close_gate.dart | pendiente |
| S0410 | símbolo | app/lib/application/catalog/catalog_service.dart:17 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0411 | símbolo | app/lib/application/catalog/catalog_service.dart:19 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0412 | símbolo | app/lib/application/catalog/catalog_service.dart:25 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0413 | símbolo | app/lib/application/catalog/catalog_service.dart:26 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0414 | símbolo | app/lib/application/catalog/catalog_service.dart:27 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0415 | símbolo | app/lib/application/catalog/catalog_service.dart:29 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0416 | símbolo | app/lib/application/catalog/catalog_service.dart:32 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0417 | símbolo | app/lib/application/catalog/catalog_service.dart:35 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0418 | símbolo | app/lib/application/catalog/catalog_service.dart:44 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0419 | símbolo | app/lib/application/catalog/catalog_service.dart:45 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0420 | símbolo | app/lib/application/catalog/catalog_service.dart:46 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0421 | símbolo | app/lib/application/catalog/catalog_service.dart:47 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0422 | símbolo | app/lib/application/catalog/catalog_service.dart:48 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0423 | símbolo | app/lib/application/catalog/catalog_service.dart:52 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0424 | símbolo | app/lib/application/catalog/catalog_service.dart:72 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0425 | símbolo | app/lib/application/catalog/catalog_service.dart:75 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0426 | símbolo | app/lib/application/catalog/catalog_service.dart:105 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0427 | símbolo | app/lib/application/catalog/catalog_service.dart:111 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0428 | símbolo | app/lib/application/catalog/catalog_service.dart:127 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0429 | símbolo | app/lib/application/catalog/catalog_service.dart:155 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0430 | símbolo | app/lib/application/catalog/catalog_service.dart:197 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0431 | símbolo | app/lib/application/catalog/catalog_service.dart:211 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0432 | símbolo | app/lib/application/catalog/catalog_service.dart:214 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0433 | símbolo | app/lib/application/catalog/catalog_service.dart:250 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0434 | símbolo | app/lib/application/catalog/catalog_service.dart:255 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0435 | símbolo | app/lib/application/catalog/catalog_service.dart:259 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0436 | símbolo | app/lib/application/catalog/catalog_service.dart:262 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0437 | símbolo | app/lib/application/catalog/catalog_service.dart:267 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0438 | símbolo | app/lib/application/catalog/catalog_service.dart:273 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0439 | símbolo | app/lib/application/catalog/catalog_service.dart:276 | app/lib/application/catalog/catalog_service.dart | pendiente |
| S0440 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:3 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0441 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:7 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0442 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:33 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0443 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:34 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0444 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:35 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0445 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:36 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0446 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:39 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0447 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:40 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0448 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:41 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0449 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:42 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0450 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:43 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0451 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:44 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0452 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:45 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0453 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:46 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0454 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:47 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0455 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:48 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0456 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:49 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0457 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:50 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0458 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:51 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0459 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:52 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0460 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:53 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0461 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:54 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0462 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:55 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0463 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:56 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0464 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:57 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0465 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:60 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0466 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:61 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0467 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:64 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0468 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:68 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0469 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:78 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0470 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:79 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0471 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:82 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0472 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:93 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0473 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:94 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0474 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:96 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0475 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:135 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0476 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:144 | app/lib/features/player/view_model/diagnostics/playback_performance.dart | pendiente |
| S0477 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:4 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0478 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:5 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0479 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:10 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0480 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:11 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0481 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:14 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0482 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:17 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0483 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:23 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0484 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:24 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0485 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:25 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0486 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:27 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0487 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:37 | app/lib/features/player/view_model/external_subtitles/external_subtitle_service.dart | pendiente |
| S0488 | símbolo | app/lib/application/player/playback_progress_session.dart:8 | app/lib/features/player/view_model/playback_progress_session.dart | pendiente |
| S0489 | símbolo | app/lib/application/player/playback_progress_session.dart:10 | app/lib/features/player/view_model/playback_progress_session.dart | pendiente |
| S0490 | símbolo | app/lib/application/player/playback_progress_session.dart:58 | app/lib/features/player/view_model/playback_progress_session.dart | pendiente |
| S0491 | símbolo | app/lib/application/player/playback_spike_contract.dart:10 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0492 | símbolo | app/lib/application/player/playback_spike_contract.dart:11 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0493 | símbolo | app/lib/application/player/playback_spike_contract.dart:13 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0494 | símbolo | app/lib/application/player/playback_spike_contract.dart:14 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0495 | símbolo | app/lib/application/player/playback_spike_contract.dart:16 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0496 | símbolo | app/lib/application/player/playback_spike_contract.dart:17 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0497 | símbolo | app/lib/application/player/playback_spike_contract.dart:22 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0498 | símbolo | app/lib/application/player/playback_spike_contract.dart:23 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0499 | símbolo | app/lib/application/player/playback_spike_contract.dart:24 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0500 | símbolo | app/lib/application/player/playback_spike_contract.dart:25 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0501 | símbolo | app/lib/application/player/playback_spike_contract.dart:26 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0502 | símbolo | app/lib/application/player/playback_spike_contract.dart:27 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0503 | símbolo | app/lib/application/player/playback_spike_contract.dart:33 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0504 | símbolo | app/lib/application/player/playback_spike_contract.dart:34 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0505 | símbolo | app/lib/application/player/playback_spike_contract.dart:35 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0506 | símbolo | app/lib/application/player/playback_spike_contract.dart:36 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0507 | símbolo | app/lib/application/player/playback_spike_contract.dart:39 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0508 | símbolo | app/lib/application/player/playback_spike_contract.dart:41 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0509 | símbolo | app/lib/application/player/playback_spike_contract.dart:44 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0510 | símbolo | app/lib/application/player/playback_spike_contract.dart:47 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0511 | símbolo | app/lib/application/player/playback_spike_contract.dart:50 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0512 | símbolo | app/lib/application/player/playback_spike_contract.dart:52 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0513 | símbolo | app/lib/application/player/playback_spike_contract.dart:69 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0514 | símbolo | app/lib/application/player/playback_spike_contract.dart:72 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0515 | símbolo | app/lib/application/player/playback_spike_contract.dart:73 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0516 | símbolo | app/lib/application/player/playback_spike_contract.dart:74 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0517 | símbolo | app/lib/application/player/playback_spike_contract.dart:75 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0518 | símbolo | app/lib/application/player/playback_spike_contract.dart:78 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0519 | símbolo | app/lib/application/player/playback_spike_contract.dart:79 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0520 | símbolo | app/lib/application/player/playback_spike_contract.dart:83 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0521 | símbolo | app/lib/application/player/playback_spike_contract.dart:84 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0522 | símbolo | app/lib/application/player/playback_spike_contract.dart:85 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0523 | símbolo | app/lib/application/player/playback_spike_contract.dart:86 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0524 | símbolo | app/lib/application/player/playback_spike_contract.dart:87 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0525 | símbolo | app/lib/application/player/playback_spike_contract.dart:88 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0526 | símbolo | app/lib/application/player/playback_spike_contract.dart:89 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0527 | símbolo | app/lib/application/player/playback_spike_contract.dart:91 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0528 | símbolo | app/lib/application/player/playback_spike_contract.dart:127 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0529 | símbolo | app/lib/application/player/playback_spike_contract.dart:130 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0530 | símbolo | app/lib/application/player/playback_spike_contract.dart:131 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0531 | símbolo | app/lib/application/player/playback_spike_contract.dart:132 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0532 | símbolo | app/lib/application/player/playback_spike_contract.dart:133 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0533 | símbolo | app/lib/application/player/playback_spike_contract.dart:134 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0534 | símbolo | app/lib/application/player/playback_spike_contract.dart:135 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0535 | símbolo | app/lib/application/player/playback_spike_contract.dart:136 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0536 | símbolo | app/lib/application/player/playback_spike_contract.dart:137 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0537 | símbolo | app/lib/application/player/playback_spike_contract.dart:138 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0538 | símbolo | app/lib/application/player/playback_spike_contract.dart:139 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0539 | símbolo | app/lib/application/player/playback_spike_contract.dart:140 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0540 | símbolo | app/lib/application/player/playback_spike_contract.dart:141 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0541 | símbolo | app/lib/application/player/playback_spike_contract.dart:144 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0542 | símbolo | app/lib/application/player/playback_spike_contract.dart:147 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0543 | símbolo | app/lib/application/player/playback_spike_contract.dart:156 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0544 | símbolo | app/lib/application/player/playback_spike_contract.dart:159 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0545 | símbolo | app/lib/application/player/playback_spike_contract.dart:160 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0546 | símbolo | app/lib/application/player/playback_spike_contract.dart:161 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0547 | símbolo | app/lib/application/player/playback_spike_contract.dart:164 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0548 | símbolo | app/lib/application/player/playback_spike_contract.dart:165 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0549 | símbolo | app/lib/application/player/playback_spike_contract.dart:167 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0550 | símbolo | app/lib/application/player/playback_spike_contract.dart:168 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0551 | símbolo | app/lib/application/player/playback_spike_contract.dart:169 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0552 | símbolo | app/lib/application/player/playback_spike_contract.dart:170 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0553 | símbolo | app/lib/application/player/playback_spike_contract.dart:171 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0554 | símbolo | app/lib/application/player/playback_spike_contract.dart:172 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0555 | símbolo | app/lib/application/player/playback_spike_contract.dart:173 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0556 | símbolo | app/lib/application/player/playback_spike_contract.dart:174 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0557 | símbolo | app/lib/application/player/playback_spike_contract.dart:175 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0558 | símbolo | app/lib/application/player/playback_spike_contract.dart:176 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0559 | símbolo | app/lib/application/player/playback_spike_contract.dart:177 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0560 | símbolo | app/lib/application/player/playback_spike_contract.dart:179 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0561 | símbolo | app/lib/application/player/playback_spike_contract.dart:197 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0562 | símbolo | app/lib/application/player/playback_spike_contract.dart:197 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0563 | símbolo | app/lib/application/player/playback_spike_contract.dart:197 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0564 | símbolo | app/lib/application/player/playback_spike_contract.dart:199 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0565 | símbolo | app/lib/application/player/playback_spike_contract.dart:200 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0566 | símbolo | app/lib/application/player/playback_spike_contract.dart:202 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0567 | símbolo | app/lib/application/player/playback_spike_contract.dart:205 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0568 | símbolo | app/lib/application/player/playback_spike_contract.dart:206 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0569 | símbolo | app/lib/application/player/playback_spike_contract.dart:207 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0570 | símbolo | app/lib/application/player/playback_spike_contract.dart:208 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0571 | símbolo | app/lib/application/player/playback_spike_contract.dart:209 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0572 | símbolo | app/lib/application/player/playback_spike_contract.dart:212 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0573 | símbolo | app/lib/application/player/playback_spike_contract.dart:214 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0574 | símbolo | app/lib/application/player/playback_spike_contract.dart:223 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0575 | símbolo | app/lib/application/player/playback_spike_contract.dart:224 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0576 | símbolo | app/lib/application/player/playback_spike_contract.dart:225 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0577 | símbolo | app/lib/application/player/playback_spike_contract.dart:226 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0578 | símbolo | app/lib/application/player/playback_spike_contract.dart:227 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0579 | símbolo | app/lib/application/player/playback_spike_contract.dart:228 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0580 | símbolo | app/lib/application/player/playback_spike_contract.dart:230 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0581 | símbolo | app/lib/application/player/playback_spike_contract.dart:234 | app/lib/features/player/view_model/playback_spike_contract.dart | pendiente |
| S0582 | símbolo | app/lib/application/player/player_demo_session.dart:3 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0583 | símbolo | app/lib/application/player/player_demo_session.dart:5 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0584 | símbolo | app/lib/application/player/player_demo_session.dart:16 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0585 | símbolo | app/lib/application/player/player_demo_session.dart:17 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0586 | símbolo | app/lib/application/player/player_demo_session.dart:19 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0587 | símbolo | app/lib/application/player/player_demo_session.dart:21 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0588 | símbolo | app/lib/application/player/player_demo_session.dart:23 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0589 | símbolo | app/lib/application/player/player_demo_session.dart:27 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0590 | símbolo | app/lib/application/player/player_demo_session.dart:33 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0591 | símbolo | app/lib/application/player/player_demo_session.dart:35 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0592 | símbolo | app/lib/application/player/player_demo_session.dart:37 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0593 | símbolo | app/lib/application/player/player_demo_session.dart:38 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0594 | símbolo | app/lib/application/player/player_demo_session.dart:40 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0595 | símbolo | app/lib/application/player/player_demo_session.dart:41 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0596 | símbolo | app/lib/application/player/player_demo_session.dart:42 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0597 | símbolo | app/lib/application/player/player_demo_session.dart:43 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0598 | símbolo | app/lib/application/player/player_demo_session.dart:45 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| S0599 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:9 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0600 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:10 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0601 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:18 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0602 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:19 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0603 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:20 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0604 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:21 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0605 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:22 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0606 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:25 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0607 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:26 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0608 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:33 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0609 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:34 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0610 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:35 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0611 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:36 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0612 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:39 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0613 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:40 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0614 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:50 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0615 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:51 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0616 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:52 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0617 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:53 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0618 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:54 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0619 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:55 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0620 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:56 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0621 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:59 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0622 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:60 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0623 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:69 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0624 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:70 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0625 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:71 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0626 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:72 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0627 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:73 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0628 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:74 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0629 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:77 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0630 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:80 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0631 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:82 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0632 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:151 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0633 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:152 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0634 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:164 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0635 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:167 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0636 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:169 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0637 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:172 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0638 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:177 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0639 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:182 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0640 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:192 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0641 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:222 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0642 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:291 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0643 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:293 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| S0644 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:5 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0645 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:8 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0646 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:14 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0647 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:18 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0648 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:20 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0649 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:28 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0650 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:51 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0651 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:53 | app/lib/features/player/view_model/providers/playback_source_cache.dart | pendiente |
| S0652 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0653 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0654 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0655 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0656 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0657 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0658 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0659 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0660 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:7 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0661 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:9 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0662 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:20 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0663 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:21 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0664 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:27 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0665 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:28 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0666 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:29 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0667 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:30 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0668 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:32 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0669 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:39 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0670 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:48 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0671 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:55 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0672 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:76 | app/lib/features/player/view_model/providers/provider_circuit_breaker.dart | pendiente |
| S0673 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:9 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0674 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:12 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0675 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:25 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0676 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:26 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0677 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:27 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0678 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:28 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0679 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:29 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0680 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:39 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0681 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:48 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| S0682 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:9 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0683 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:10 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0684 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:20 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0685 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:21 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0686 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:22 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0687 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:23 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0688 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:24 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0689 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:25 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0690 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:26 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0691 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:29 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0692 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:32 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0693 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:41 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0694 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:42 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0695 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:43 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0696 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:44 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0697 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:53 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0698 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:54 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0699 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:56 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0700 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:104 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0701 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:176 | app/lib/features/player/view_model/skips/skip_segment_service.dart | pendiente |
| S0702 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:9 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0703 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:10 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0704 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:11 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0705 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:12 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0706 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:13 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0707 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:14 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0708 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:17 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0709 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:18 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0710 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:27 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0711 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:28 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0712 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:29 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0713 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:30 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0714 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:31 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0715 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:32 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0716 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:35 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0717 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:36 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0718 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:37 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0719 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:38 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0720 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:39 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0721 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:40 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0722 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:43 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0723 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:44 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0724 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:51 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0725 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:52 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0726 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:53 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0727 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:54 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0728 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:57 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0729 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:60 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0730 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:102 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0731 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:103 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0732 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:105 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0733 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:318 | app/lib/features/player/view_model/source_switching/playback_source_switch_service.dart | pendiente |
| S0734 | símbolo | app/lib/application/player/spike_player_coordinator.dart:11 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0735 | símbolo | app/lib/application/player/spike_player_coordinator.dart:14 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0736 | símbolo | app/lib/application/player/spike_player_coordinator.dart:52 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0737 | símbolo | app/lib/application/player/spike_player_coordinator.dart:63 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0738 | símbolo | app/lib/application/player/spike_player_coordinator.dart:64 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0739 | símbolo | app/lib/application/player/spike_player_coordinator.dart:66 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0740 | símbolo | app/lib/application/player/spike_player_coordinator.dart:90 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0741 | símbolo | app/lib/application/player/spike_player_coordinator.dart:145 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0742 | símbolo | app/lib/application/player/spike_player_coordinator.dart:224 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0743 | símbolo | app/lib/application/player/spike_player_coordinator.dart:394 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0744 | símbolo | app/lib/application/player/spike_player_coordinator.dart:400 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0745 | símbolo | app/lib/application/player/spike_player_coordinator.dart:409 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0746 | símbolo | app/lib/application/player/spike_player_coordinator.dart:421 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0747 | símbolo | app/lib/application/player/spike_player_coordinator.dart:438 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0748 | símbolo | app/lib/application/player/spike_player_coordinator.dart:454 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0749 | símbolo | app/lib/application/player/spike_player_coordinator.dart:463 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0750 | símbolo | app/lib/application/player/spike_player_coordinator.dart:475 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0751 | símbolo | app/lib/application/player/spike_player_coordinator.dart:489 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0752 | símbolo | app/lib/application/player/spike_player_coordinator.dart:511 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0753 | símbolo | app/lib/application/player/spike_player_coordinator.dart:517 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0754 | símbolo | app/lib/application/player/spike_player_coordinator.dart:542 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0755 | símbolo | app/lib/application/player/spike_player_coordinator.dart:547 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0756 | símbolo | app/lib/application/player/spike_player_coordinator.dart:602 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0757 | símbolo | app/lib/application/player/spike_player_coordinator.dart:667 | app/lib/features/player/view_model/spike_player_coordinator.dart | pendiente |
| S0758 | símbolo | app/lib/core/errors/app_error.dart:1 | app/lib/core/errors/app_error.dart | pendiente |
| S0759 | símbolo | app/lib/core/errors/app_error.dart:2 | app/lib/core/errors/app_error.dart | pendiente |
| S0760 | símbolo | app/lib/core/errors/app_error.dart:4 | app/lib/core/errors/app_error.dart | pendiente |
| S0761 | símbolo | app/lib/core/errors/app_error.dart:5 | app/lib/core/errors/app_error.dart | pendiente |
| S0762 | símbolo | app/lib/core/errors/app_error.dart:7 | app/lib/core/errors/app_error.dart | pendiente |
| S0763 | símbolo | app/lib/core/errors/app_error.dart:11 | app/lib/core/errors/app_error.dart | pendiente |
| S0764 | símbolo | app/lib/core/errors/app_error.dart:12 | app/lib/core/errors/app_error.dart | pendiente |
| S0765 | símbolo | app/lib/core/errors/app_error.dart:16 | app/lib/core/errors/app_error.dart | pendiente |
| S0766 | símbolo | app/lib/core/errors/app_error.dart:17 | app/lib/core/errors/app_error.dart | pendiente |
| S0767 | símbolo | app/lib/core/errors/app_error.dart:21 | app/lib/core/errors/app_error.dart | pendiente |
| S0768 | símbolo | app/lib/core/errors/app_error.dart:22 | app/lib/core/errors/app_error.dart | pendiente |
| S0769 | símbolo | app/lib/core/errors/app_error.dart:25 | app/lib/core/errors/app_error.dart | pendiente |
| S0770 | símbolo | app/lib/core/errors/app_error.dart:28 | app/lib/core/errors/app_error.dart | pendiente |
| S0771 | símbolo | app/lib/core/errors/app_error.dart:29 | app/lib/core/errors/app_error.dart | pendiente |
| S0772 | símbolo | app/lib/core/errors/app_error.dart:33 | app/lib/core/errors/app_error.dart | pendiente |
| S0773 | símbolo | app/lib/core/errors/app_error.dart:34 | app/lib/core/errors/app_error.dart | pendiente |
| S0774 | símbolo | app/lib/core/errors/app_error.dart:38 | app/lib/core/errors/app_error.dart | pendiente |
| S0775 | símbolo | app/lib/core/errors/app_error.dart:39 | app/lib/core/errors/app_error.dart | pendiente |
| S0776 | símbolo | app/lib/core/errors/app_error.dart:43 | app/lib/core/errors/app_error.dart | pendiente |
| S0777 | símbolo | app/lib/core/errors/app_error.dart:44 | app/lib/core/errors/app_error.dart | pendiente |
| S0778 | símbolo | app/lib/core/errors/app_error.dart:48 | app/lib/core/errors/app_error.dart | pendiente |
| S0779 | símbolo | app/lib/core/errors/app_error.dart:49 | app/lib/core/errors/app_error.dart | pendiente |
| S0780 | símbolo | app/lib/core/errors/app_error.dart:53 | app/lib/core/errors/app_error.dart | pendiente |
| S0781 | símbolo | app/lib/core/errors/app_error.dart:54 | app/lib/core/errors/app_error.dart | pendiente |
| S0782 | símbolo | app/lib/core/logger/safe_logger.dart:5 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0783 | símbolo | app/lib/core/logger/safe_logger.dart:5 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0784 | símbolo | app/lib/core/logger/safe_logger.dart:5 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0785 | símbolo | app/lib/core/logger/safe_logger.dart:5 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0786 | símbolo | app/lib/core/logger/safe_logger.dart:5 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0787 | símbolo | app/lib/core/logger/safe_logger.dart:7 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0788 | símbolo | app/lib/core/logger/safe_logger.dart:8 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0789 | símbolo | app/lib/core/logger/safe_logger.dart:16 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0790 | símbolo | app/lib/core/logger/safe_logger.dart:17 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0791 | símbolo | app/lib/core/logger/safe_logger.dart:18 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0792 | símbolo | app/lib/core/logger/safe_logger.dart:19 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0793 | símbolo | app/lib/core/logger/safe_logger.dart:20 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0794 | símbolo | app/lib/core/logger/safe_logger.dart:23 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0795 | símbolo | app/lib/core/logger/safe_logger.dart:25 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0796 | símbolo | app/lib/core/logger/safe_logger.dart:26 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0797 | símbolo | app/lib/core/logger/safe_logger.dart:34 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0798 | símbolo | app/lib/core/logger/safe_logger.dart:39 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0799 | símbolo | app/lib/core/logger/safe_logger.dart:58 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0800 | símbolo | app/lib/core/logger/safe_logger.dart:67 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0801 | símbolo | app/lib/core/logger/safe_logger.dart:77 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0802 | símbolo | app/lib/core/logger/safe_logger.dart:81 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0803 | símbolo | app/lib/core/logger/safe_logger.dart:83 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0804 | símbolo | app/lib/core/logger/safe_logger.dart:87 | app/lib/core/logger/safe_logger.dart | pendiente |
| S0805 | símbolo | app/lib/core/result/result.dart:3 | app/lib/core/result/result.dart | pendiente |
| S0806 | símbolo | app/lib/core/result/result.dart:4 | app/lib/core/result/result.dart | pendiente |
| S0807 | símbolo | app/lib/core/result/result.dart:6 | app/lib/core/result/result.dart | pendiente |
| S0808 | símbolo | app/lib/core/result/result.dart:8 | app/lib/core/result/result.dart | pendiente |
| S0809 | símbolo | app/lib/core/result/result.dart:16 | app/lib/core/result/result.dart | pendiente |
| S0810 | símbolo | app/lib/core/result/result.dart:21 | app/lib/core/result/result.dart | pendiente |
| S0811 | símbolo | app/lib/core/result/result.dart:27 | app/lib/core/result/result.dart | pendiente |
| S0812 | símbolo | app/lib/core/result/result.dart:28 | app/lib/core/result/result.dart | pendiente |
| S0813 | símbolo | app/lib/core/result/result.dart:30 | app/lib/core/result/result.dart | pendiente |
| S0814 | símbolo | app/lib/core/result/result.dart:33 | app/lib/core/result/result.dart | pendiente |
| S0815 | símbolo | app/lib/core/result/result.dart:34 | app/lib/core/result/result.dart | pendiente |
| S0816 | símbolo | app/lib/core/result/result.dart:36 | app/lib/core/result/result.dart | pendiente |
| S0817 | símbolo | app/lib/data/anilist/anilist_client.dart:106 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0818 | símbolo | app/lib/data/anilist/anilist_client.dart:110 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0819 | símbolo | app/lib/data/anilist/anilist_client.dart:122 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0820 | símbolo | app/lib/data/anilist/anilist_client.dart:128 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0821 | símbolo | app/lib/data/anilist/anilist_client.dart:161 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0822 | símbolo | app/lib/data/anilist/anilist_client.dart:206 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0823 | símbolo | app/lib/data/anilist/anilist_client.dart:506 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0824 | símbolo | app/lib/data/anilist/anilist_client.dart:508 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0825 | símbolo | app/lib/data/anilist/anilist_client.dart:521 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0826 | símbolo | app/lib/data/anilist/anilist_client.dart:550 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0827 | símbolo | app/lib/data/anilist/anilist_client.dart:568 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| S0828 | símbolo | app/lib/data/anilist/anilist_detail_fields.dart:4 | app/lib/data/services/anilist/anilist_detail_fields.dart | pendiente |
| S0829 | símbolo | app/lib/data/anilist/anilist_detail_fields.dart:109 | app/lib/data/services/anilist/anilist_detail_fields.dart | pendiente |
| S0830 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:12 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0831 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:18 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0832 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:21 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0833 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:22 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0834 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:25 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0835 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:27 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0836 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:34 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0837 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:46 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0838 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:53 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0839 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:58 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0840 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:63 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0841 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:77 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0842 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:96 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0843 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:130 | app/lib/data/services/anilist/anilist_metadata_provider.dart | pendiente |
| S0844 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:5 | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | pendiente |
| S0845 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:9 | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | pendiente |
| S0846 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:11 | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | pendiente |
| S0847 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:13 | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | pendiente |
| S0848 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:15 | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | pendiente |
| S0849 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:32 | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | pendiente |
| S0850 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:12 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0851 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:15 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0852 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:24 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0853 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:25 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0854 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:54 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0855 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:58 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0856 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:112 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0857 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:163 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0858 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:165 | app/lib/data/services/anilist/offline_first_anime_catalog.dart | pendiente |
| S0859 | símbolo | app/lib/data/aniskip/aniskip_client.dart:11 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| S0860 | símbolo | app/lib/data/aniskip/aniskip_client.dart:13 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| S0861 | símbolo | app/lib/data/aniskip/aniskip_client.dart:16 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| S0862 | símbolo | app/lib/data/aniskip/aniskip_client.dart:28 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| S0863 | símbolo | app/lib/data/aniskip/aniskip_client.dart:45 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| S0864 | símbolo | app/lib/data/aniskip/aniskip_client.dart:49 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| S0865 | símbolo | app/lib/data/aniskip/aniskip_client.dart:52 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| S0866 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:6 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0867 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:7 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0868 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:12 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0869 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:13 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0870 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:14 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0871 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:17 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0872 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:18 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0873 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:19 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0874 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:20 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0875 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:23 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0876 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:25 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0877 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:27 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0878 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:37 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0879 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:38 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0880 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:42 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0881 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:87 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0882 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:112 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| S0883 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:9 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| S0884 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:13 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| S0885 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:19 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| S0886 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:32 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| S0887 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:38 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| S0888 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:42 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| S0889 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:45 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| S0890 | símbolo | app/lib/data/local_db/app_database.dart:18 | app/lib/data/local_db/app_database.dart | pendiente |
| S0891 | símbolo | app/lib/data/local_db/app_database.dart:31 | app/lib/data/local_db/app_database.dart | pendiente |
| S0892 | símbolo | app/lib/data/local_db/app_database.dart:33 | app/lib/data/local_db/app_database.dart | pendiente |
| S0893 | símbolo | app/lib/data/local_db/app_database.dart:36 | app/lib/data/local_db/app_database.dart | pendiente |
| S0894 | símbolo | app/lib/data/local_db/app_database.dart:39 | app/lib/data/local_db/app_database.dart | pendiente |
| S0895 | símbolo | app/lib/data/local_db/app_database.dart:58 | app/lib/data/local_db/app_database.dart | pendiente |
| S0896 | símbolo | app/lib/data/local_db/app_database.g.dart:6 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0897 | símbolo | app/lib/data/local_db/app_database.g.dart:9 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0898 | símbolo | app/lib/data/local_db/app_database.g.dart:11 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0899 | símbolo | app/lib/data/local_db/app_database.g.dart:16 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0900 | símbolo | app/lib/data/local_db/app_database.g.dart:27 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0901 | símbolo | app/lib/data/local_db/app_database.g.dart:38 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0902 | símbolo | app/lib/data/local_db/app_database.g.dart:45 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0903 | símbolo | app/lib/data/local_db/app_database.g.dart:47 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0904 | símbolo | app/lib/data/local_db/app_database.g.dart:49 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0905 | símbolo | app/lib/data/local_db/app_database.g.dart:51 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0906 | símbolo | app/lib/data/local_db/app_database.g.dart:52 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0907 | símbolo | app/lib/data/local_db/app_database.g.dart:86 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0908 | símbolo | app/lib/data/local_db/app_database.g.dart:88 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0909 | símbolo | app/lib/data/local_db/app_database.g.dart:107 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0910 | símbolo | app/lib/data/local_db/app_database.g.dart:113 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0911 | símbolo | app/lib/data/local_db/app_database.g.dart:114 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0912 | símbolo | app/lib/data/local_db/app_database.g.dart:115 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0913 | símbolo | app/lib/data/local_db/app_database.g.dart:116 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0914 | símbolo | app/lib/data/local_db/app_database.g.dart:117 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0915 | símbolo | app/lib/data/local_db/app_database.g.dart:122 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0916 | símbolo | app/lib/data/local_db/app_database.g.dart:131 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0917 | símbolo | app/lib/data/local_db/app_database.g.dart:139 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0918 | símbolo | app/lib/data/local_db/app_database.g.dart:150 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0919 | símbolo | app/lib/data/local_db/app_database.g.dart:160 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0920 | símbolo | app/lib/data/local_db/app_database.g.dart:169 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0921 | símbolo | app/lib/data/local_db/app_database.g.dart:179 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0922 | símbolo | app/lib/data/local_db/app_database.g.dart:189 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0923 | símbolo | app/lib/data/local_db/app_database.g.dart:191 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0924 | símbolo | app/lib/data/local_db/app_database.g.dart:200 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0925 | símbolo | app/lib/data/local_db/app_database.g.dart:201 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0926 | símbolo | app/lib/data/local_db/app_database.g.dart:202 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0927 | símbolo | app/lib/data/local_db/app_database.g.dart:203 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0928 | símbolo | app/lib/data/local_db/app_database.g.dart:204 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0929 | símbolo | app/lib/data/local_db/app_database.g.dart:205 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0930 | símbolo | app/lib/data/local_db/app_database.g.dart:211 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0931 | símbolo | app/lib/data/local_db/app_database.g.dart:219 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0932 | símbolo | app/lib/data/local_db/app_database.g.dart:233 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0933 | símbolo | app/lib/data/local_db/app_database.g.dart:247 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0934 | símbolo | app/lib/data/local_db/app_database.g.dart:265 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0935 | símbolo | app/lib/data/local_db/app_database.g.dart:277 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0936 | símbolo | app/lib/data/local_db/app_database.g.dart:280 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0937 | símbolo | app/lib/data/local_db/app_database.g.dart:282 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0938 | símbolo | app/lib/data/local_db/app_database.g.dart:287 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0939 | símbolo | app/lib/data/local_db/app_database.g.dart:298 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0940 | símbolo | app/lib/data/local_db/app_database.g.dart:309 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0941 | símbolo | app/lib/data/local_db/app_database.g.dart:316 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0942 | símbolo | app/lib/data/local_db/app_database.g.dart:318 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0943 | símbolo | app/lib/data/local_db/app_database.g.dart:320 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0944 | símbolo | app/lib/data/local_db/app_database.g.dart:322 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0945 | símbolo | app/lib/data/local_db/app_database.g.dart:323 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0946 | símbolo | app/lib/data/local_db/app_database.g.dart:363 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0947 | símbolo | app/lib/data/local_db/app_database.g.dart:365 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0948 | símbolo | app/lib/data/local_db/app_database.g.dart:384 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0949 | símbolo | app/lib/data/local_db/app_database.g.dart:390 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0950 | símbolo | app/lib/data/local_db/app_database.g.dart:392 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0951 | símbolo | app/lib/data/local_db/app_database.g.dart:393 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0952 | símbolo | app/lib/data/local_db/app_database.g.dart:394 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0953 | símbolo | app/lib/data/local_db/app_database.g.dart:395 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0954 | símbolo | app/lib/data/local_db/app_database.g.dart:400 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0955 | símbolo | app/lib/data/local_db/app_database.g.dart:409 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0956 | símbolo | app/lib/data/local_db/app_database.g.dart:417 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0957 | símbolo | app/lib/data/local_db/app_database.g.dart:428 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0958 | símbolo | app/lib/data/local_db/app_database.g.dart:438 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0959 | símbolo | app/lib/data/local_db/app_database.g.dart:447 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0960 | símbolo | app/lib/data/local_db/app_database.g.dart:459 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0961 | símbolo | app/lib/data/local_db/app_database.g.dart:469 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0962 | símbolo | app/lib/data/local_db/app_database.g.dart:471 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0963 | símbolo | app/lib/data/local_db/app_database.g.dart:480 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0964 | símbolo | app/lib/data/local_db/app_database.g.dart:481 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0965 | símbolo | app/lib/data/local_db/app_database.g.dart:482 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0966 | símbolo | app/lib/data/local_db/app_database.g.dart:483 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0967 | símbolo | app/lib/data/local_db/app_database.g.dart:484 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0968 | símbolo | app/lib/data/local_db/app_database.g.dart:485 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0969 | símbolo | app/lib/data/local_db/app_database.g.dart:491 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0970 | símbolo | app/lib/data/local_db/app_database.g.dart:499 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0971 | símbolo | app/lib/data/local_db/app_database.g.dart:513 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0972 | símbolo | app/lib/data/local_db/app_database.g.dart:527 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0973 | símbolo | app/lib/data/local_db/app_database.g.dart:545 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0974 | símbolo | app/lib/data/local_db/app_database.g.dart:557 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0975 | símbolo | app/lib/data/local_db/app_database.g.dart:560 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0976 | símbolo | app/lib/data/local_db/app_database.g.dart:562 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0977 | símbolo | app/lib/data/local_db/app_database.g.dart:565 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0978 | símbolo | app/lib/data/local_db/app_database.g.dart:576 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0979 | símbolo | app/lib/data/local_db/app_database.g.dart:585 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0980 | símbolo | app/lib/data/local_db/app_database.g.dart:596 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0981 | símbolo | app/lib/data/local_db/app_database.g.dart:607 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0982 | símbolo | app/lib/data/local_db/app_database.g.dart:618 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0983 | símbolo | app/lib/data/local_db/app_database.g.dart:625 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0984 | símbolo | app/lib/data/local_db/app_database.g.dart:634 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0985 | símbolo | app/lib/data/local_db/app_database.g.dart:636 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0986 | símbolo | app/lib/data/local_db/app_database.g.dart:638 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0987 | símbolo | app/lib/data/local_db/app_database.g.dart:639 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0988 | símbolo | app/lib/data/local_db/app_database.g.dart:700 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0989 | símbolo | app/lib/data/local_db/app_database.g.dart:702 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0990 | símbolo | app/lib/data/local_db/app_database.g.dart:733 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0991 | símbolo | app/lib/data/local_db/app_database.g.dart:739 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0992 | símbolo | app/lib/data/local_db/app_database.g.dart:741 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0993 | símbolo | app/lib/data/local_db/app_database.g.dart:742 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0994 | símbolo | app/lib/data/local_db/app_database.g.dart:743 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0995 | símbolo | app/lib/data/local_db/app_database.g.dart:744 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0996 | símbolo | app/lib/data/local_db/app_database.g.dart:745 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0997 | símbolo | app/lib/data/local_db/app_database.g.dart:746 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0998 | símbolo | app/lib/data/local_db/app_database.g.dart:747 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S0999 | símbolo | app/lib/data/local_db/app_database.g.dart:755 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1000 | símbolo | app/lib/data/local_db/app_database.g.dart:767 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1001 | símbolo | app/lib/data/local_db/app_database.g.dart:778 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1002 | símbolo | app/lib/data/local_db/app_database.g.dart:792 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1003 | símbolo | app/lib/data/local_db/app_database.g.dart:805 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1004 | símbolo | app/lib/data/local_db/app_database.g.dart:820 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1005 | símbolo | app/lib/data/local_db/app_database.g.dart:835 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1006 | símbolo | app/lib/data/local_db/app_database.g.dart:848 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1007 | símbolo | app/lib/data/local_db/app_database.g.dart:851 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1008 | símbolo | app/lib/data/local_db/app_database.g.dart:863 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1009 | símbolo | app/lib/data/local_db/app_database.g.dart:865 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1010 | símbolo | app/lib/data/local_db/app_database.g.dart:866 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1011 | símbolo | app/lib/data/local_db/app_database.g.dart:867 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1012 | símbolo | app/lib/data/local_db/app_database.g.dart:868 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1013 | símbolo | app/lib/data/local_db/app_database.g.dart:869 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1014 | símbolo | app/lib/data/local_db/app_database.g.dart:870 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1015 | símbolo | app/lib/data/local_db/app_database.g.dart:871 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1016 | símbolo | app/lib/data/local_db/app_database.g.dart:872 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1017 | símbolo | app/lib/data/local_db/app_database.g.dart:881 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1018 | símbolo | app/lib/data/local_db/app_database.g.dart:895 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1019 | símbolo | app/lib/data/local_db/app_database.g.dart:915 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1020 | símbolo | app/lib/data/local_db/app_database.g.dart:935 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1021 | símbolo | app/lib/data/local_db/app_database.g.dart:962 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1022 | símbolo | app/lib/data/local_db/app_database.g.dart:977 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1023 | símbolo | app/lib/data/local_db/app_database.g.dart:980 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1024 | símbolo | app/lib/data/local_db/app_database.g.dart:982 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1025 | símbolo | app/lib/data/local_db/app_database.g.dart:987 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1026 | símbolo | app/lib/data/local_db/app_database.g.dart:998 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1027 | símbolo | app/lib/data/local_db/app_database.g.dart:1009 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1028 | símbolo | app/lib/data/local_db/app_database.g.dart:1020 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1029 | símbolo | app/lib/data/local_db/app_database.g.dart:1031 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1030 | símbolo | app/lib/data/local_db/app_database.g.dart:1042 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1031 | símbolo | app/lib/data/local_db/app_database.g.dart:1053 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1032 | símbolo | app/lib/data/local_db/app_database.g.dart:1061 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1033 | símbolo | app/lib/data/local_db/app_database.g.dart:1071 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1034 | símbolo | app/lib/data/local_db/app_database.g.dart:1073 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1035 | símbolo | app/lib/data/local_db/app_database.g.dart:1075 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1036 | símbolo | app/lib/data/local_db/app_database.g.dart:1076 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1037 | símbolo | app/lib/data/local_db/app_database.g.dart:1141 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1038 | símbolo | app/lib/data/local_db/app_database.g.dart:1143 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1039 | símbolo | app/lib/data/local_db/app_database.g.dart:1178 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1040 | símbolo | app/lib/data/local_db/app_database.g.dart:1184 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1041 | símbolo | app/lib/data/local_db/app_database.g.dart:1186 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1042 | símbolo | app/lib/data/local_db/app_database.g.dart:1187 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1043 | símbolo | app/lib/data/local_db/app_database.g.dart:1188 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1044 | símbolo | app/lib/data/local_db/app_database.g.dart:1189 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1045 | símbolo | app/lib/data/local_db/app_database.g.dart:1190 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1046 | símbolo | app/lib/data/local_db/app_database.g.dart:1191 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1047 | símbolo | app/lib/data/local_db/app_database.g.dart:1192 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1048 | símbolo | app/lib/data/local_db/app_database.g.dart:1193 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1049 | símbolo | app/lib/data/local_db/app_database.g.dart:1202 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1050 | símbolo | app/lib/data/local_db/app_database.g.dart:1217 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1051 | símbolo | app/lib/data/local_db/app_database.g.dart:1231 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1052 | símbolo | app/lib/data/local_db/app_database.g.dart:1246 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1053 | símbolo | app/lib/data/local_db/app_database.g.dart:1260 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1054 | símbolo | app/lib/data/local_db/app_database.g.dart:1277 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1055 | símbolo | app/lib/data/local_db/app_database.g.dart:1299 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1056 | símbolo | app/lib/data/local_db/app_database.g.dart:1313 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1057 | símbolo | app/lib/data/local_db/app_database.g.dart:1323 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1058 | símbolo | app/lib/data/local_db/app_database.g.dart:1336 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1059 | símbolo | app/lib/data/local_db/app_database.g.dart:1338 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1060 | símbolo | app/lib/data/local_db/app_database.g.dart:1339 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1061 | símbolo | app/lib/data/local_db/app_database.g.dart:1340 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1062 | símbolo | app/lib/data/local_db/app_database.g.dart:1341 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1063 | símbolo | app/lib/data/local_db/app_database.g.dart:1342 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1064 | símbolo | app/lib/data/local_db/app_database.g.dart:1343 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1065 | símbolo | app/lib/data/local_db/app_database.g.dart:1344 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1066 | símbolo | app/lib/data/local_db/app_database.g.dart:1345 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1067 | símbolo | app/lib/data/local_db/app_database.g.dart:1346 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1068 | símbolo | app/lib/data/local_db/app_database.g.dart:1356 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1069 | símbolo | app/lib/data/local_db/app_database.g.dart:1370 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1070 | símbolo | app/lib/data/local_db/app_database.g.dart:1392 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1071 | símbolo | app/lib/data/local_db/app_database.g.dart:1414 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1072 | símbolo | app/lib/data/local_db/app_database.g.dart:1444 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1073 | símbolo | app/lib/data/local_db/app_database.g.dart:1460 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1074 | símbolo | app/lib/data/local_db/app_database.g.dart:1463 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1075 | símbolo | app/lib/data/local_db/app_database.g.dart:1465 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1076 | símbolo | app/lib/data/local_db/app_database.g.dart:1470 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1077 | símbolo | app/lib/data/local_db/app_database.g.dart:1481 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1078 | símbolo | app/lib/data/local_db/app_database.g.dart:1488 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1079 | símbolo | app/lib/data/local_db/app_database.g.dart:1490 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1080 | símbolo | app/lib/data/local_db/app_database.g.dart:1492 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1081 | símbolo | app/lib/data/local_db/app_database.g.dart:1494 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1082 | símbolo | app/lib/data/local_db/app_database.g.dart:1495 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1083 | símbolo | app/lib/data/local_db/app_database.g.dart:1524 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1084 | símbolo | app/lib/data/local_db/app_database.g.dart:1526 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1085 | símbolo | app/lib/data/local_db/app_database.g.dart:1541 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1086 | símbolo | app/lib/data/local_db/app_database.g.dart:1547 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1087 | símbolo | app/lib/data/local_db/app_database.g.dart:1549 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1088 | símbolo | app/lib/data/local_db/app_database.g.dart:1550 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1089 | símbolo | app/lib/data/local_db/app_database.g.dart:1551 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1090 | símbolo | app/lib/data/local_db/app_database.g.dart:1552 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1091 | símbolo | app/lib/data/local_db/app_database.g.dart:1560 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1092 | símbolo | app/lib/data/local_db/app_database.g.dart:1567 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1093 | símbolo | app/lib/data/local_db/app_database.g.dart:1577 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1094 | símbolo | app/lib/data/local_db/app_database.g.dart:1586 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1095 | símbolo | app/lib/data/local_db/app_database.g.dart:1591 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1096 | símbolo | app/lib/data/local_db/app_database.g.dart:1600 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1097 | símbolo | app/lib/data/local_db/app_database.g.dart:1609 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1098 | símbolo | app/lib/data/local_db/app_database.g.dart:1611 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1099 | símbolo | app/lib/data/local_db/app_database.g.dart:1619 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1100 | símbolo | app/lib/data/local_db/app_database.g.dart:1621 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1101 | símbolo | app/lib/data/local_db/app_database.g.dart:1622 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1102 | símbolo | app/lib/data/local_db/app_database.g.dart:1623 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1103 | símbolo | app/lib/data/local_db/app_database.g.dart:1624 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1104 | símbolo | app/lib/data/local_db/app_database.g.dart:1629 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1105 | símbolo | app/lib/data/local_db/app_database.g.dart:1635 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1106 | símbolo | app/lib/data/local_db/app_database.g.dart:1647 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1107 | símbolo | app/lib/data/local_db/app_database.g.dart:1659 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1108 | símbolo | app/lib/data/local_db/app_database.g.dart:1674 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1109 | símbolo | app/lib/data/local_db/app_database.g.dart:1685 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1110 | símbolo | app/lib/data/local_db/app_database.g.dart:1688 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1111 | símbolo | app/lib/data/local_db/app_database.g.dart:1690 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1112 | símbolo | app/lib/data/local_db/app_database.g.dart:1695 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1113 | símbolo | app/lib/data/local_db/app_database.g.dart:1706 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1114 | símbolo | app/lib/data/local_db/app_database.g.dart:1717 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1115 | símbolo | app/lib/data/local_db/app_database.g.dart:1731 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1116 | símbolo | app/lib/data/local_db/app_database.g.dart:1742 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1117 | símbolo | app/lib/data/local_db/app_database.g.dart:1749 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1118 | símbolo | app/lib/data/local_db/app_database.g.dart:1757 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1119 | símbolo | app/lib/data/local_db/app_database.g.dart:1759 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1120 | símbolo | app/lib/data/local_db/app_database.g.dart:1761 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1121 | símbolo | app/lib/data/local_db/app_database.g.dart:1762 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1122 | símbolo | app/lib/data/local_db/app_database.g.dart:1815 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1123 | símbolo | app/lib/data/local_db/app_database.g.dart:1817 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1124 | símbolo | app/lib/data/local_db/app_database.g.dart:1847 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1125 | símbolo | app/lib/data/local_db/app_database.g.dart:1853 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1126 | símbolo | app/lib/data/local_db/app_database.g.dart:1855 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1127 | símbolo | app/lib/data/local_db/app_database.g.dart:1856 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1128 | símbolo | app/lib/data/local_db/app_database.g.dart:1857 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1129 | símbolo | app/lib/data/local_db/app_database.g.dart:1858 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1130 | símbolo | app/lib/data/local_db/app_database.g.dart:1859 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1131 | símbolo | app/lib/data/local_db/app_database.g.dart:1860 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1132 | símbolo | app/lib/data/local_db/app_database.g.dart:1867 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1133 | símbolo | app/lib/data/local_db/app_database.g.dart:1878 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1134 | símbolo | app/lib/data/local_db/app_database.g.dart:1888 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1135 | símbolo | app/lib/data/local_db/app_database.g.dart:1901 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1136 | símbolo | app/lib/data/local_db/app_database.g.dart:1913 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1137 | símbolo | app/lib/data/local_db/app_database.g.dart:1926 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1138 | símbolo | app/lib/data/local_db/app_database.g.dart:1944 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1139 | símbolo | app/lib/data/local_db/app_database.g.dart:1956 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1140 | símbolo | app/lib/data/local_db/app_database.g.dart:1959 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1141 | símbolo | app/lib/data/local_db/app_database.g.dart:1970 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1142 | símbolo | app/lib/data/local_db/app_database.g.dart:1972 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1143 | símbolo | app/lib/data/local_db/app_database.g.dart:1973 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1144 | símbolo | app/lib/data/local_db/app_database.g.dart:1974 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1145 | símbolo | app/lib/data/local_db/app_database.g.dart:1975 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1146 | símbolo | app/lib/data/local_db/app_database.g.dart:1976 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1147 | símbolo | app/lib/data/local_db/app_database.g.dart:1977 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1148 | símbolo | app/lib/data/local_db/app_database.g.dart:1978 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1149 | símbolo | app/lib/data/local_db/app_database.g.dart:1986 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1150 | símbolo | app/lib/data/local_db/app_database.g.dart:1998 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1151 | símbolo | app/lib/data/local_db/app_database.g.dart:2016 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1152 | símbolo | app/lib/data/local_db/app_database.g.dart:2034 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1153 | símbolo | app/lib/data/local_db/app_database.g.dart:2058 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1154 | símbolo | app/lib/data/local_db/app_database.g.dart:2072 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1155 | símbolo | app/lib/data/local_db/app_database.g.dart:2076 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1156 | símbolo | app/lib/data/local_db/app_database.g.dart:2078 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1157 | símbolo | app/lib/data/local_db/app_database.g.dart:2083 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1158 | símbolo | app/lib/data/local_db/app_database.g.dart:2097 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1159 | símbolo | app/lib/data/local_db/app_database.g.dart:2111 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1160 | símbolo | app/lib/data/local_db/app_database.g.dart:2122 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1161 | símbolo | app/lib/data/local_db/app_database.g.dart:2133 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1162 | símbolo | app/lib/data/local_db/app_database.g.dart:2140 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1163 | símbolo | app/lib/data/local_db/app_database.g.dart:2148 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1164 | símbolo | app/lib/data/local_db/app_database.g.dart:2150 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1165 | símbolo | app/lib/data/local_db/app_database.g.dart:2152 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1166 | símbolo | app/lib/data/local_db/app_database.g.dart:2153 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1167 | símbolo | app/lib/data/local_db/app_database.g.dart:2215 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1168 | símbolo | app/lib/data/local_db/app_database.g.dart:2221 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1169 | símbolo | app/lib/data/local_db/app_database.g.dart:2251 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1170 | símbolo | app/lib/data/local_db/app_database.g.dart:2257 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1171 | símbolo | app/lib/data/local_db/app_database.g.dart:2259 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1172 | símbolo | app/lib/data/local_db/app_database.g.dart:2260 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1173 | símbolo | app/lib/data/local_db/app_database.g.dart:2261 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1174 | símbolo | app/lib/data/local_db/app_database.g.dart:2262 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1175 | símbolo | app/lib/data/local_db/app_database.g.dart:2263 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1176 | símbolo | app/lib/data/local_db/app_database.g.dart:2264 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1177 | símbolo | app/lib/data/local_db/app_database.g.dart:2271 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1178 | símbolo | app/lib/data/local_db/app_database.g.dart:2282 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1179 | símbolo | app/lib/data/local_db/app_database.g.dart:2292 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1180 | símbolo | app/lib/data/local_db/app_database.g.dart:2305 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1181 | símbolo | app/lib/data/local_db/app_database.g.dart:2317 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1182 | símbolo | app/lib/data/local_db/app_database.g.dart:2330 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1183 | símbolo | app/lib/data/local_db/app_database.g.dart:2350 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1184 | símbolo | app/lib/data/local_db/app_database.g.dart:2362 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1185 | símbolo | app/lib/data/local_db/app_database.g.dart:2370 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1186 | símbolo | app/lib/data/local_db/app_database.g.dart:2381 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1187 | símbolo | app/lib/data/local_db/app_database.g.dart:2383 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1188 | símbolo | app/lib/data/local_db/app_database.g.dart:2384 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1189 | símbolo | app/lib/data/local_db/app_database.g.dart:2385 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1190 | símbolo | app/lib/data/local_db/app_database.g.dart:2386 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1191 | símbolo | app/lib/data/local_db/app_database.g.dart:2387 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1192 | símbolo | app/lib/data/local_db/app_database.g.dart:2388 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1193 | símbolo | app/lib/data/local_db/app_database.g.dart:2389 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1194 | símbolo | app/lib/data/local_db/app_database.g.dart:2397 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1195 | símbolo | app/lib/data/local_db/app_database.g.dart:2409 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1196 | símbolo | app/lib/data/local_db/app_database.g.dart:2427 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1197 | símbolo | app/lib/data/local_db/app_database.g.dart:2445 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1198 | símbolo | app/lib/data/local_db/app_database.g.dart:2469 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1199 | símbolo | app/lib/data/local_db/app_database.g.dart:2483 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1200 | símbolo | app/lib/data/local_db/app_database.g.dart:2486 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1201 | símbolo | app/lib/data/local_db/app_database.g.dart:2488 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1202 | símbolo | app/lib/data/local_db/app_database.g.dart:2493 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1203 | símbolo | app/lib/data/local_db/app_database.g.dart:2507 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1204 | símbolo | app/lib/data/local_db/app_database.g.dart:2516 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1205 | símbolo | app/lib/data/local_db/app_database.g.dart:2524 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1206 | símbolo | app/lib/data/local_db/app_database.g.dart:2526 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1207 | símbolo | app/lib/data/local_db/app_database.g.dart:2528 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1208 | símbolo | app/lib/data/local_db/app_database.g.dart:2530 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1209 | símbolo | app/lib/data/local_db/app_database.g.dart:2531 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1210 | símbolo | app/lib/data/local_db/app_database.g.dart:2566 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1211 | símbolo | app/lib/data/local_db/app_database.g.dart:2568 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1212 | símbolo | app/lib/data/local_db/app_database.g.dart:2587 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1213 | símbolo | app/lib/data/local_db/app_database.g.dart:2593 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1214 | símbolo | app/lib/data/local_db/app_database.g.dart:2595 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1215 | símbolo | app/lib/data/local_db/app_database.g.dart:2596 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1216 | símbolo | app/lib/data/local_db/app_database.g.dart:2597 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1217 | símbolo | app/lib/data/local_db/app_database.g.dart:2598 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1218 | símbolo | app/lib/data/local_db/app_database.g.dart:2603 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1219 | símbolo | app/lib/data/local_db/app_database.g.dart:2612 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1220 | símbolo | app/lib/data/local_db/app_database.g.dart:2620 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1221 | símbolo | app/lib/data/local_db/app_database.g.dart:2631 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1222 | símbolo | app/lib/data/local_db/app_database.g.dart:2641 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1223 | símbolo | app/lib/data/local_db/app_database.g.dart:2650 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1224 | símbolo | app/lib/data/local_db/app_database.g.dart:2660 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1225 | símbolo | app/lib/data/local_db/app_database.g.dart:2670 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1226 | símbolo | app/lib/data/local_db/app_database.g.dart:2672 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1227 | símbolo | app/lib/data/local_db/app_database.g.dart:2681 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1228 | símbolo | app/lib/data/local_db/app_database.g.dart:2682 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1229 | símbolo | app/lib/data/local_db/app_database.g.dart:2683 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1230 | símbolo | app/lib/data/local_db/app_database.g.dart:2684 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1231 | símbolo | app/lib/data/local_db/app_database.g.dart:2685 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1232 | símbolo | app/lib/data/local_db/app_database.g.dart:2686 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1233 | símbolo | app/lib/data/local_db/app_database.g.dart:2692 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1234 | símbolo | app/lib/data/local_db/app_database.g.dart:2699 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1235 | símbolo | app/lib/data/local_db/app_database.g.dart:2713 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1236 | símbolo | app/lib/data/local_db/app_database.g.dart:2727 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1237 | símbolo | app/lib/data/local_db/app_database.g.dart:2745 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1238 | símbolo | app/lib/data/local_db/app_database.g.dart:2840 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1239 | símbolo | app/lib/data/local_db/app_database.g.dart:2847 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1240 | símbolo | app/lib/data/local_db/app_database.g.dart:2855 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1241 | símbolo | app/lib/data/local_db/app_database.g.dart:2857 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1242 | símbolo | app/lib/data/local_db/app_database.g.dart:2864 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1243 | símbolo | app/lib/data/local_db/app_database.g.dart:2869 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1244 | símbolo | app/lib/data/local_db/app_database.g.dart:2874 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1245 | símbolo | app/lib/data/local_db/app_database.g.dart:2880 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1246 | símbolo | app/lib/data/local_db/app_database.g.dart:2882 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1247 | símbolo | app/lib/data/local_db/app_database.g.dart:2889 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1248 | símbolo | app/lib/data/local_db/app_database.g.dart:2894 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1249 | símbolo | app/lib/data/local_db/app_database.g.dart:2899 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1250 | símbolo | app/lib/data/local_db/app_database.g.dart:2905 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1251 | símbolo | app/lib/data/local_db/app_database.g.dart:2907 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1252 | símbolo | app/lib/data/local_db/app_database.g.dart:2914 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1253 | símbolo | app/lib/data/local_db/app_database.g.dart:2919 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1254 | símbolo | app/lib/data/local_db/app_database.g.dart:2922 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1255 | símbolo | app/lib/data/local_db/app_database.g.dart:2926 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1256 | símbolo | app/lib/data/local_db/app_database.g.dart:2944 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1257 | símbolo | app/lib/data/local_db/app_database.g.dart:2998 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1258 | símbolo | app/lib/data/local_db/app_database.g.dart:3015 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1259 | símbolo | app/lib/data/local_db/app_database.g.dart:3022 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1260 | símbolo | app/lib/data/local_db/app_database.g.dart:3030 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1261 | símbolo | app/lib/data/local_db/app_database.g.dart:3032 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1262 | símbolo | app/lib/data/local_db/app_database.g.dart:3039 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1263 | símbolo | app/lib/data/local_db/app_database.g.dart:3044 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1264 | símbolo | app/lib/data/local_db/app_database.g.dart:3049 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1265 | símbolo | app/lib/data/local_db/app_database.g.dart:3055 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1266 | símbolo | app/lib/data/local_db/app_database.g.dart:3057 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1267 | símbolo | app/lib/data/local_db/app_database.g.dart:3064 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1268 | símbolo | app/lib/data/local_db/app_database.g.dart:3069 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1269 | símbolo | app/lib/data/local_db/app_database.g.dart:3074 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1270 | símbolo | app/lib/data/local_db/app_database.g.dart:3080 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1271 | símbolo | app/lib/data/local_db/app_database.g.dart:3082 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1272 | símbolo | app/lib/data/local_db/app_database.g.dart:3089 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1273 | símbolo | app/lib/data/local_db/app_database.g.dart:3094 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1274 | símbolo | app/lib/data/local_db/app_database.g.dart:3099 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1275 | símbolo | app/lib/data/local_db/app_database.g.dart:3103 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1276 | símbolo | app/lib/data/local_db/app_database.g.dart:3125 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1277 | símbolo | app/lib/data/local_db/app_database.g.dart:3182 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1278 | símbolo | app/lib/data/local_db/app_database.g.dart:3203 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1279 | símbolo | app/lib/data/local_db/app_database.g.dart:3213 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1280 | símbolo | app/lib/data/local_db/app_database.g.dart:3224 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1281 | símbolo | app/lib/data/local_db/app_database.g.dart:3226 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1282 | símbolo | app/lib/data/local_db/app_database.g.dart:3233 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1283 | símbolo | app/lib/data/local_db/app_database.g.dart:3238 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1284 | símbolo | app/lib/data/local_db/app_database.g.dart:3243 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1285 | símbolo | app/lib/data/local_db/app_database.g.dart:3248 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1286 | símbolo | app/lib/data/local_db/app_database.g.dart:3253 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1287 | símbolo | app/lib/data/local_db/app_database.g.dart:3258 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1288 | símbolo | app/lib/data/local_db/app_database.g.dart:3264 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1289 | símbolo | app/lib/data/local_db/app_database.g.dart:3266 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1290 | símbolo | app/lib/data/local_db/app_database.g.dart:3273 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1291 | símbolo | app/lib/data/local_db/app_database.g.dart:3278 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1292 | símbolo | app/lib/data/local_db/app_database.g.dart:3283 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1293 | símbolo | app/lib/data/local_db/app_database.g.dart:3288 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1294 | símbolo | app/lib/data/local_db/app_database.g.dart:3293 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1295 | símbolo | app/lib/data/local_db/app_database.g.dart:3298 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1296 | símbolo | app/lib/data/local_db/app_database.g.dart:3304 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1297 | símbolo | app/lib/data/local_db/app_database.g.dart:3306 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1298 | símbolo | app/lib/data/local_db/app_database.g.dart:3313 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1299 | símbolo | app/lib/data/local_db/app_database.g.dart:3316 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1300 | símbolo | app/lib/data/local_db/app_database.g.dart:3321 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1301 | símbolo | app/lib/data/local_db/app_database.g.dart:3324 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1302 | símbolo | app/lib/data/local_db/app_database.g.dart:3327 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1303 | símbolo | app/lib/data/local_db/app_database.g.dart:3332 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1304 | símbolo | app/lib/data/local_db/app_database.g.dart:3336 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1305 | símbolo | app/lib/data/local_db/app_database.g.dart:3358 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1306 | símbolo | app/lib/data/local_db/app_database.g.dart:3429 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1307 | símbolo | app/lib/data/local_db/app_database.g.dart:3450 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1308 | símbolo | app/lib/data/local_db/app_database.g.dart:3461 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1309 | símbolo | app/lib/data/local_db/app_database.g.dart:3473 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1310 | símbolo | app/lib/data/local_db/app_database.g.dart:3475 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1311 | símbolo | app/lib/data/local_db/app_database.g.dart:3482 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1312 | símbolo | app/lib/data/local_db/app_database.g.dart:3487 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1313 | símbolo | app/lib/data/local_db/app_database.g.dart:3492 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1314 | símbolo | app/lib/data/local_db/app_database.g.dart:3497 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1315 | símbolo | app/lib/data/local_db/app_database.g.dart:3502 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1316 | símbolo | app/lib/data/local_db/app_database.g.dart:3507 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1317 | símbolo | app/lib/data/local_db/app_database.g.dart:3512 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1318 | símbolo | app/lib/data/local_db/app_database.g.dart:3518 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1319 | símbolo | app/lib/data/local_db/app_database.g.dart:3520 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1320 | símbolo | app/lib/data/local_db/app_database.g.dart:3527 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1321 | símbolo | app/lib/data/local_db/app_database.g.dart:3532 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1322 | símbolo | app/lib/data/local_db/app_database.g.dart:3537 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1323 | símbolo | app/lib/data/local_db/app_database.g.dart:3542 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1324 | símbolo | app/lib/data/local_db/app_database.g.dart:3547 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1325 | símbolo | app/lib/data/local_db/app_database.g.dart:3552 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1326 | símbolo | app/lib/data/local_db/app_database.g.dart:3557 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1327 | símbolo | app/lib/data/local_db/app_database.g.dart:3563 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1328 | símbolo | app/lib/data/local_db/app_database.g.dart:3565 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1329 | símbolo | app/lib/data/local_db/app_database.g.dart:3572 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1330 | símbolo | app/lib/data/local_db/app_database.g.dart:3575 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1331 | símbolo | app/lib/data/local_db/app_database.g.dart:3578 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1332 | símbolo | app/lib/data/local_db/app_database.g.dart:3583 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1333 | símbolo | app/lib/data/local_db/app_database.g.dart:3588 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1334 | símbolo | app/lib/data/local_db/app_database.g.dart:3593 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1335 | símbolo | app/lib/data/local_db/app_database.g.dart:3598 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1336 | símbolo | app/lib/data/local_db/app_database.g.dart:3602 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1337 | símbolo | app/lib/data/local_db/app_database.g.dart:3624 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1338 | símbolo | app/lib/data/local_db/app_database.g.dart:3706 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1339 | símbolo | app/lib/data/local_db/app_database.g.dart:3727 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1340 | símbolo | app/lib/data/local_db/app_database.g.dart:3733 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1341 | símbolo | app/lib/data/local_db/app_database.g.dart:3740 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1342 | símbolo | app/lib/data/local_db/app_database.g.dart:3747 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1343 | símbolo | app/lib/data/local_db/app_database.g.dart:3763 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1344 | símbolo | app/lib/data/local_db/app_database.g.dart:3791 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1345 | símbolo | app/lib/data/local_db/app_database.g.dart:3821 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1346 | símbolo | app/lib/data/local_db/app_database.g.dart:3849 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1347 | símbolo | app/lib/data/local_db/app_database.g.dart:3867 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1348 | símbolo | app/lib/data/local_db/app_database.g.dart:3869 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1349 | símbolo | app/lib/data/local_db/app_database.g.dart:3876 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1350 | símbolo | app/lib/data/local_db/app_database.g.dart:3881 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1351 | símbolo | app/lib/data/local_db/app_database.g.dart:3886 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1352 | símbolo | app/lib/data/local_db/app_database.g.dart:3913 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1353 | símbolo | app/lib/data/local_db/app_database.g.dart:3940 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1354 | símbolo | app/lib/data/local_db/app_database.g.dart:3967 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1355 | símbolo | app/lib/data/local_db/app_database.g.dart:3993 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1356 | símbolo | app/lib/data/local_db/app_database.g.dart:3995 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1357 | símbolo | app/lib/data/local_db/app_database.g.dart:4002 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1358 | símbolo | app/lib/data/local_db/app_database.g.dart:4007 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1359 | símbolo | app/lib/data/local_db/app_database.g.dart:4013 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1360 | símbolo | app/lib/data/local_db/app_database.g.dart:4015 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1361 | símbolo | app/lib/data/local_db/app_database.g.dart:4022 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1362 | símbolo | app/lib/data/local_db/app_database.g.dart:4025 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1363 | símbolo | app/lib/data/local_db/app_database.g.dart:4030 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1364 | símbolo | app/lib/data/local_db/app_database.g.dart:4057 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1365 | símbolo | app/lib/data/local_db/app_database.g.dart:4086 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1366 | símbolo | app/lib/data/local_db/app_database.g.dart:4115 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1367 | símbolo | app/lib/data/local_db/app_database.g.dart:4142 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1368 | símbolo | app/lib/data/local_db/app_database.g.dart:4162 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1369 | símbolo | app/lib/data/local_db/app_database.g.dart:4318 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1370 | símbolo | app/lib/data/local_db/app_database.g.dart:4337 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1371 | símbolo | app/lib/data/local_db/app_database.g.dart:4346 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1372 | símbolo | app/lib/data/local_db/app_database.g.dart:4356 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1373 | símbolo | app/lib/data/local_db/app_database.g.dart:4363 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1374 | símbolo | app/lib/data/local_db/app_database.g.dart:4375 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1375 | símbolo | app/lib/data/local_db/app_database.g.dart:4390 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1376 | símbolo | app/lib/data/local_db/app_database.g.dart:4392 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1377 | símbolo | app/lib/data/local_db/app_database.g.dart:4399 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1378 | símbolo | app/lib/data/local_db/app_database.g.dart:4404 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1379 | símbolo | app/lib/data/local_db/app_database.g.dart:4409 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1380 | símbolo | app/lib/data/local_db/app_database.g.dart:4414 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1381 | símbolo | app/lib/data/local_db/app_database.g.dart:4419 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1382 | símbolo | app/lib/data/local_db/app_database.g.dart:4443 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1383 | símbolo | app/lib/data/local_db/app_database.g.dart:4445 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1384 | símbolo | app/lib/data/local_db/app_database.g.dart:4452 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1385 | símbolo | app/lib/data/local_db/app_database.g.dart:4457 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1386 | símbolo | app/lib/data/local_db/app_database.g.dart:4462 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1387 | símbolo | app/lib/data/local_db/app_database.g.dart:4467 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1388 | símbolo | app/lib/data/local_db/app_database.g.dart:4472 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1389 | símbolo | app/lib/data/local_db/app_database.g.dart:4497 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1390 | símbolo | app/lib/data/local_db/app_database.g.dart:4499 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1391 | símbolo | app/lib/data/local_db/app_database.g.dart:4506 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1392 | símbolo | app/lib/data/local_db/app_database.g.dart:4511 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1393 | símbolo | app/lib/data/local_db/app_database.g.dart:4516 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1394 | símbolo | app/lib/data/local_db/app_database.g.dart:4519 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1395 | símbolo | app/lib/data/local_db/app_database.g.dart:4524 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1396 | símbolo | app/lib/data/local_db/app_database.g.dart:4549 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1397 | símbolo | app/lib/data/local_db/app_database.g.dart:4564 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1398 | símbolo | app/lib/data/local_db/app_database.g.dart:4674 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1399 | símbolo | app/lib/data/local_db/app_database.g.dart:4688 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1400 | símbolo | app/lib/data/local_db/app_database.g.dart:4697 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1401 | símbolo | app/lib/data/local_db/app_database.g.dart:4707 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1402 | símbolo | app/lib/data/local_db/app_database.g.dart:4714 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1403 | símbolo | app/lib/data/local_db/app_database.g.dart:4725 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1404 | símbolo | app/lib/data/local_db/app_database.g.dart:4744 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1405 | símbolo | app/lib/data/local_db/app_database.g.dart:4759 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1406 | símbolo | app/lib/data/local_db/app_database.g.dart:4761 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1407 | símbolo | app/lib/data/local_db/app_database.g.dart:4768 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1408 | símbolo | app/lib/data/local_db/app_database.g.dart:4773 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1409 | símbolo | app/lib/data/local_db/app_database.g.dart:4778 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1410 | símbolo | app/lib/data/local_db/app_database.g.dart:4783 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1411 | símbolo | app/lib/data/local_db/app_database.g.dart:4806 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1412 | símbolo | app/lib/data/local_db/app_database.g.dart:4830 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1413 | símbolo | app/lib/data/local_db/app_database.g.dart:4832 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1414 | símbolo | app/lib/data/local_db/app_database.g.dart:4839 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1415 | símbolo | app/lib/data/local_db/app_database.g.dart:4844 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1416 | símbolo | app/lib/data/local_db/app_database.g.dart:4849 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1417 | símbolo | app/lib/data/local_db/app_database.g.dart:4854 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1418 | símbolo | app/lib/data/local_db/app_database.g.dart:4878 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1419 | símbolo | app/lib/data/local_db/app_database.g.dart:4903 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1420 | símbolo | app/lib/data/local_db/app_database.g.dart:4905 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1421 | símbolo | app/lib/data/local_db/app_database.g.dart:4912 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1422 | símbolo | app/lib/data/local_db/app_database.g.dart:4917 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1423 | símbolo | app/lib/data/local_db/app_database.g.dart:4920 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1424 | símbolo | app/lib/data/local_db/app_database.g.dart:4925 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1425 | símbolo | app/lib/data/local_db/app_database.g.dart:4949 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1426 | símbolo | app/lib/data/local_db/app_database.g.dart:4974 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1427 | símbolo | app/lib/data/local_db/app_database.g.dart:4992 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1428 | símbolo | app/lib/data/local_db/app_database.g.dart:5116 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1429 | símbolo | app/lib/data/local_db/app_database.g.dart:5130 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1430 | símbolo | app/lib/data/local_db/app_database.g.dart:5137 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1431 | símbolo | app/lib/data/local_db/app_database.g.dart:5145 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1432 | símbolo | app/lib/data/local_db/app_database.g.dart:5152 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1433 | símbolo | app/lib/data/local_db/app_database.g.dart:5163 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1434 | símbolo | app/lib/data/local_db/app_database.g.dart:5178 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1435 | símbolo | app/lib/data/local_db/app_database.g.dart:5180 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1436 | símbolo | app/lib/data/local_db/app_database.g.dart:5187 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1437 | símbolo | app/lib/data/local_db/app_database.g.dart:5192 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1438 | símbolo | app/lib/data/local_db/app_database.g.dart:5197 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1439 | símbolo | app/lib/data/local_db/app_database.g.dart:5221 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1440 | símbolo | app/lib/data/local_db/app_database.g.dart:5223 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1441 | símbolo | app/lib/data/local_db/app_database.g.dart:5230 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1442 | símbolo | app/lib/data/local_db/app_database.g.dart:5235 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1443 | símbolo | app/lib/data/local_db/app_database.g.dart:5240 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1444 | símbolo | app/lib/data/local_db/app_database.g.dart:5265 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1445 | símbolo | app/lib/data/local_db/app_database.g.dart:5267 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1446 | símbolo | app/lib/data/local_db/app_database.g.dart:5274 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1447 | símbolo | app/lib/data/local_db/app_database.g.dart:5279 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1448 | símbolo | app/lib/data/local_db/app_database.g.dart:5282 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1449 | símbolo | app/lib/data/local_db/app_database.g.dart:5307 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1450 | símbolo | app/lib/data/local_db/app_database.g.dart:5322 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1451 | símbolo | app/lib/data/local_db/app_database.g.dart:5418 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1452 | símbolo | app/lib/data/local_db/app_database.g.dart:5433 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1453 | símbolo | app/lib/data/local_db/app_database.g.dart:5435 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1454 | símbolo | app/lib/data/local_db/app_database.g.dart:5436 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1455 | símbolo | app/lib/data/local_db/app_database.g.dart:5438 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1456 | símbolo | app/lib/data/local_db/app_database.g.dart:5440 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1457 | símbolo | app/lib/data/local_db/app_database.g.dart:5442 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1458 | símbolo | app/lib/data/local_db/app_database.g.dart:5447 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1459 | símbolo | app/lib/data/local_db/app_database.g.dart:5449 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1460 | símbolo | app/lib/data/local_db/app_database.g.dart:5454 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1461 | símbolo | app/lib/data/local_db/app_database.g.dart:5460 | app/lib/data/local_db/app_database.g.dart | pendiente |
| S1462 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:5 | app/lib/data/local_db/drift_anilist_detail_cache.dart | pendiente |
| S1463 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:7 | app/lib/data/local_db/drift_anilist_detail_cache.dart | pendiente |
| S1464 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:8 | app/lib/data/local_db/drift_anilist_detail_cache.dart | pendiente |
| S1465 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:10 | app/lib/data/local_db/drift_anilist_detail_cache.dart | pendiente |
| S1466 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:27 | app/lib/data/local_db/drift_anilist_detail_cache.dart | pendiente |
| S1467 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:51 | app/lib/data/local_db/drift_anilist_detail_cache.dart | pendiente |
| S1468 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:11 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1469 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:12 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1470 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:18 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1471 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:19 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1472 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:22 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1473 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:31 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1474 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:48 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1475 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:107 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1476 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:132 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1477 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:188 | app/lib/data/local_db/drift_anime_identity_repository.dart | pendiente |
| S1478 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:10 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1479 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:11 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1480 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:16 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1481 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:19 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1482 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:31 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1483 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:44 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1484 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:78 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1485 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:106 | app/lib/data/local_db/drift_local_library_repository.dart | pendiente |
| S1486 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:10 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| S1487 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:12 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| S1488 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:13 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| S1489 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:15 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| S1490 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:41 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| S1491 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:78 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| S1492 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:116 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| S1493 | símbolo | app/lib/data/local_db/local_progress_repository.dart:9 | app/lib/data/local_db/local_progress_repository.dart | pendiente |
| S1494 | símbolo | app/lib/data/local_db/local_progress_repository.dart:10 | app/lib/data/local_db/local_progress_repository.dart | pendiente |
| S1495 | símbolo | app/lib/data/local_db/local_progress_repository.dart:13 | app/lib/data/local_db/local_progress_repository.dart | pendiente |
| S1496 | símbolo | app/lib/data/local_db/local_progress_repository.dart:16 | app/lib/data/local_db/local_progress_repository.dart | pendiente |
| S1497 | símbolo | app/lib/data/local_db/local_progress_repository.dart:47 | app/lib/data/local_db/local_progress_repository.dart | pendiente |
| S1498 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:3 | app/lib/data/local_db/tables/anime_identity_entries.dart | pendiente |
| S1499 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:5 | app/lib/data/local_db/tables/anime_identity_entries.dart | pendiente |
| S1500 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:7 | app/lib/data/local_db/tables/anime_identity_entries.dart | pendiente |
| S1501 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:9 | app/lib/data/local_db/tables/anime_identity_entries.dart | pendiente |
| S1502 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:12 | app/lib/data/local_db/tables/anime_identity_entries.dart | pendiente |
| S1503 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:5 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1504 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:8 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1505 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:17 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1506 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:26 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1507 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:28 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1508 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:30 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1509 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:32 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1510 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:39 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| S1511 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:5 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1512 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:8 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1513 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:10 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1514 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:12 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1515 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:20 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1516 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:22 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1517 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:24 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1518 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:27 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| S1519 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:3 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1520 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:5 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1521 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:7 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1522 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:9 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1523 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:11 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1524 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:13 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1525 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:15 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1526 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:17 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| S1527 | símbolo | app/lib/data/local_db/tables/library_entries.dart:5 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| S1528 | símbolo | app/lib/data/local_db/tables/library_entries.dart:8 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| S1529 | símbolo | app/lib/data/local_db/tables/library_entries.dart:16 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| S1530 | símbolo | app/lib/data/local_db/tables/library_entries.dart:18 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| S1531 | símbolo | app/lib/data/local_db/tables/library_entries.dart:21 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| S1532 | símbolo | app/lib/data/local_db/tables/library_entries.dart:24 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| S1533 | símbolo | app/lib/data/local_db/tables/library_entries.dart:27 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| S1534 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:3 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1535 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:4 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1536 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:5 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1537 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:6 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1538 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:7 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1539 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:8 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1540 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:9 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1541 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:10 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1542 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:12 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| S1543 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:3 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| S1544 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:5 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| S1545 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:7 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| S1546 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:9 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| S1547 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:11 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| S1548 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:3 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| S1549 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:5 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| S1550 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:7 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| S1551 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:9 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| S1552 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:11 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| S1553 | símbolo | app/lib/data/local_db/uuid_anime_id_generator.dart:5 | app/lib/data/local_db/uuid_anime_id_generator.dart | pendiente |
| S1554 | símbolo | app/lib/data/local_db/uuid_anime_id_generator.dart:7 | app/lib/data/local_db/uuid_anime_id_generator.dart | pendiente |
| S1555 | símbolo | app/lib/data/local_db/uuid_anime_id_generator.dart:11 | app/lib/data/local_db/uuid_anime_id_generator.dart | pendiente |
| S1556 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:7 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1557 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:13 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1558 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:16 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1559 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:19 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1560 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:20 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1561 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:67 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1562 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:70 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1563 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:76 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1564 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:96 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1565 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:101 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1566 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:107 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1567 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:119 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1568 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:124 | app/lib/data/metadata/fake_metadata_provider.dart | pendiente |
| S1569 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:11 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1570 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:12 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1571 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:13 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1572 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:15 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1573 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:18 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1574 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:52 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1575 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:55 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1576 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:58 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1577 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:63 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1578 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:72 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1579 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:178 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| S1580 | símbolo | app/lib/data/player/engine/active_player_lease.dart:3 | app/lib/data/services/player/active_player_lease.dart | pendiente |
| S1581 | símbolo | app/lib/data/player/engine/active_player_lease.dart:12 | app/lib/data/services/player/active_player_lease.dart | pendiente |
| S1582 | símbolo | app/lib/data/player/engine/active_player_lease.dart:15 | app/lib/data/services/player/active_player_lease.dart | pendiente |
| S1583 | símbolo | app/lib/data/player/engine/active_player_lease.dart:22 | app/lib/data/services/player/active_player_lease.dart | pendiente |
| S1584 | símbolo | app/lib/data/player/engine/active_player_lease.dart:38 | app/lib/data/services/player/active_player_lease.dart | pendiente |
| S1585 | símbolo | app/lib/data/player/engine/active_player_lease.dart:69 | app/lib/data/services/player/active_player_lease.dart | pendiente |
| S1586 | símbolo | app/lib/data/player/engine/active_player_lease.dart:71 | app/lib/data/services/player/active_player_lease.dart | pendiente |
| S1587 | símbolo | app/lib/data/player/engine/media_codec_support_android.dart:3 | app/lib/data/services/player/media_codec_support_android.dart | pendiente |
| S1588 | símbolo | app/lib/data/player/engine/media_codec_support_android.dart:10 | app/lib/data/services/player/media_codec_support_android.dart | pendiente |
| S1589 | símbolo | app/lib/data/player/engine/media_codec_support_android.dart:12 | app/lib/data/services/player/media_codec_support_android.dart | pendiente |
| S1590 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:11 | app/lib/data/services/player/media_codec_support_io.dart | pendiente |
| S1591 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:29 | app/lib/data/services/player/media_codec_support_io.dart | pendiente |
| S1592 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:32 | app/lib/data/services/player/media_codec_support_io.dart | pendiente |
| S1593 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:50 | app/lib/data/services/player/media_codec_support_io.dart | pendiente |
| S1594 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:8 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1595 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:11 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1596 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:16 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1597 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:19 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1598 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:32 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1599 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:47 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1600 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:94 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1601 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:100 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1602 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:106 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1603 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:107 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1604 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:108 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1605 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:110 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1606 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:125 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| S1607 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:1 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1608 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:6 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1609 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:10 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1610 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:14 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1611 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:20 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1612 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:24 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1613 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:29 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1614 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:37 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1615 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:39 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1616 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:42 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1617 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:45 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1618 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:47 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1619 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:53 | app/lib/data/services/player/media_codec_support_model.dart | pendiente |
| S1620 | símbolo | app/lib/data/player/engine/media_codec_support_stub.dart:3 | app/lib/data/services/player/media_codec_support_stub.dart | pendiente |
| S1621 | símbolo | app/lib/data/player/engine/media_codec_support_system.dart:3 | app/lib/data/services/player/media_codec_support_system.dart | pendiente |
| S1622 | símbolo | app/lib/data/player/engine/media_codec_support_system.dart:8 | app/lib/data/services/player/media_codec_support_system.dart | pendiente |
| S1623 | símbolo | app/lib/data/player/engine/media_codec_support_system.dart:10 | app/lib/data/services/player/media_codec_support_system.dart | pendiente |
| S1624 | símbolo | app/lib/data/player/engine/media_codec_support_windows.dart:3 | app/lib/data/services/player/media_codec_support_windows.dart | pendiente |
| S1625 | símbolo | app/lib/data/player/engine/media_codec_support_windows.dart:10 | app/lib/data/services/player/media_codec_support_windows.dart | pendiente |
| S1626 | símbolo | app/lib/data/player/engine/media_codec_support_windows.dart:12 | app/lib/data/services/player/media_codec_support_windows.dart | pendiente |
| S1627 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:21 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1628 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:28 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1629 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:102 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1630 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:163 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1631 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:170 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1632 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:222 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1633 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:227 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1634 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:237 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1635 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:240 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1636 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:260 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1637 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:263 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1638 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:307 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1639 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:433 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1640 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:460 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1641 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:466 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1642 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:472 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1643 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:487 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1644 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:517 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1645 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:557 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1646 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:575 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1647 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:586 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1648 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:607 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1649 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:763 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1650 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:788 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1651 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:935 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1652 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:970 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1653 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:976 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1654 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:982 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1655 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:983 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1656 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:984 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| S1657 | símbolo | app/lib/data/player/engine/mpv_performance_reader.dart:7 | app/lib/data/services/player/mpv_performance_reader.dart | pendiente |
| S1658 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_native.dart:3 | app/lib/data/services/player/mpv_subtitle_properties_native.dart | pendiente |
| S1659 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_native.dart:34 | app/lib/data/services/player/mpv_subtitle_properties_native.dart | pendiente |
| S1660 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_stub.dart:3 | app/lib/data/services/player/mpv_subtitle_properties_stub.dart | pendiente |
| S1661 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_stub.dart:11 | app/lib/data/services/player/mpv_subtitle_properties_stub.dart | pendiente |
| S1662 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:17 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1663 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:17 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1664 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:17 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1665 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:19 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1666 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:41 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1667 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:51 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1668 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:60 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1669 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:61 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1670 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:62 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1671 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:63 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1672 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:64 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1673 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:65 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1674 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:68 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1675 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:71 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1676 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:72 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1677 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:96 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1678 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:97 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1679 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:111 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1680 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:116 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1681 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:161 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1682 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:290 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1683 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:302 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1684 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:313 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| S1685 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:14 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1686 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:17 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1687 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:27 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1688 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:32 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1689 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:35 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1690 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:120 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1691 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:207 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1692 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:227 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1693 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:256 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1694 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:358 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1695 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:360 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| S1696 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:12 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1697 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:12 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1698 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:12 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1699 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:14 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1700 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:21 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1701 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:35 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1702 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:36 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1703 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:69 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1704 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:74 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1705 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:107 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1706 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:158 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1707 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:170 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1708 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:181 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| S1709 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:12 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1710 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:19 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1711 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:32 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1712 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:57 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1713 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:60 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1714 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:81 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1715 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:127 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1716 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:139 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1717 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:150 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| S1718 | símbolo | app/lib/data/player/providers/episode_source_support.dart:4 | app/lib/sources/episode_source_support.dart | pendiente |
| S1719 | símbolo | app/lib/data/player/providers/episode_source_support.dart:14 | app/lib/sources/episode_source_support.dart | pendiente |
| S1720 | símbolo | app/lib/data/player/providers/episode_source_support.dart:22 | app/lib/sources/episode_source_support.dart | pendiente |
| S1721 | símbolo | app/lib/data/player/providers/episode_source_support.dart:28 | app/lib/sources/episode_source_support.dart | pendiente |
| S1722 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:6 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1723 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:9 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1724 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:12 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1725 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:16 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1726 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:19 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1727 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:22 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1728 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:30 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1729 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:71 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1730 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:83 | app/lib/sources/hosts/direct_media_host_resolver.dart | pendiente |
| S1731 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:10 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1732 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:13 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1733 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:37 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1734 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:39 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1735 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:42 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1736 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:49 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1737 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:141 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1738 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:153 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1739 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:155 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| S1740 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:1 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1741 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:7 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1742 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:26 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1743 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:34 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1744 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:58 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1745 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:63 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1746 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:89 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1747 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:98 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1748 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:114 | app/lib/sources/html_playback_parsers.dart | pendiente |
| S1749 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:10 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1750 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:23 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1751 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:25 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1752 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:27 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1753 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:30 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1754 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:32 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1755 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:37 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1756 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:41 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1757 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:57 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1758 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:65 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1759 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:72 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1760 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:245 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| S1761 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:15 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1762 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:15 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1763 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:15 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1764 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:17 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1765 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:22 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1766 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:36 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1767 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:38 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1768 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:39 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1769 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:48 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1770 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:53 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1771 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:154 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1772 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:168 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1773 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:180 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1774 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:192 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1775 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:208 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| S1776 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:12 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1777 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:14 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1778 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:21 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1779 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:24 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1780 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:45 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1781 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:122 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1782 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:154 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1783 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:160 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| S1784 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:8 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1785 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:10 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1786 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:19 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1787 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:20 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1788 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:21 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1789 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:22 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1790 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:23 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1791 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:24 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1792 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:27 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1793 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:28 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1794 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:35 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1795 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:36 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1796 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:37 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1797 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:38 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1798 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:41 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1799 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:42 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1800 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:44 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1801 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:45 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1802 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:46 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1803 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:49 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1804 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:57 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1805 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:59 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1806 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:60 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1807 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:61 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1808 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:63 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1809 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:104 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1810 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:141 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1811 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:172 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| S1812 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:15 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1813 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:22 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1814 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:28 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1815 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:51 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1816 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:53 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1817 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:59 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1818 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:62 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1819 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:75 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1820 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:113 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1821 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:130 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1822 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:155 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1823 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:402 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| S1824 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:8 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1825 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:10 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1826 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:16 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1827 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:17 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1828 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:18 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1829 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:21 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1830 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:23 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1831 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:31 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1832 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:43 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1833 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:49 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1834 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:52 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1835 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:56 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1836 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:105 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| S1837 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:9 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| S1838 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:33 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| S1839 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:45 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| S1840 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:48 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| S1841 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:55 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| S1842 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:6 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1843 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:7 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1844 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:8 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1845 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:9 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1846 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:10 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1847 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:11 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1848 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:12 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1849 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:13 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1850 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:14 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1851 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:15 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1852 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:16 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1853 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:19 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1854 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:22 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1855 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:39 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1856 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:40 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1857 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:41 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1858 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:42 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1859 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:43 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1860 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:44 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1861 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:45 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1862 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:46 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1863 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:47 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1864 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:48 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1865 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:49 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1866 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:50 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1867 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:52 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1868 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:60 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1869 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:63 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1870 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:66 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1871 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:71 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1872 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:142 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| S1873 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:19 | app/lib/sources/playback_providers_module.dart | pendiente |
| S1874 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:28 | app/lib/sources/playback_providers_module.dart | pendiente |
| S1875 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:229 | app/lib/sources/playback_providers_module.dart | pendiente |
| S1876 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:233 | app/lib/sources/playback_providers_module.dart | pendiente |
| S1877 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:8 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1878 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:10 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1879 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:16 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1880 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:30 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1881 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:50 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1882 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:59 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1883 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:61 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1884 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:63 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1885 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:65 | app/lib/sources/public_episode_provider.dart | pendiente |
| S1886 | símbolo | app/lib/data/player/providers/public_playback_http.dart:13 | app/lib/sources/public_playback_http.dart | pendiente |
| S1887 | símbolo | app/lib/data/player/providers/public_playback_http.dart:15 | app/lib/sources/public_playback_http.dart | pendiente |
| S1888 | símbolo | app/lib/data/player/providers/public_playback_http.dart:16 | app/lib/sources/public_playback_http.dart | pendiente |
| S1889 | símbolo | app/lib/data/player/providers/public_playback_http.dart:20 | app/lib/sources/public_playback_http.dart | pendiente |
| S1890 | símbolo | app/lib/data/player/providers/public_playback_http.dart:22 | app/lib/sources/public_playback_http.dart | pendiente |
| S1891 | símbolo | app/lib/data/player/providers/public_playback_http.dart:30 | app/lib/sources/public_playback_http.dart | pendiente |
| S1892 | símbolo | app/lib/data/player/providers/public_playback_http.dart:31 | app/lib/sources/public_playback_http.dart | pendiente |
| S1893 | símbolo | app/lib/data/player/providers/public_playback_http.dart:32 | app/lib/sources/public_playback_http.dart | pendiente |
| S1894 | símbolo | app/lib/data/player/providers/public_playback_http.dart:33 | app/lib/sources/public_playback_http.dart | pendiente |
| S1895 | símbolo | app/lib/data/player/providers/public_playback_http.dart:34 | app/lib/sources/public_playback_http.dart | pendiente |
| S1896 | símbolo | app/lib/data/player/providers/public_playback_http.dart:65 | app/lib/sources/public_playback_http.dart | pendiente |
| S1897 | símbolo | app/lib/data/player/providers/public_playback_http.dart:83 | app/lib/sources/public_playback_http.dart | pendiente |
| S1898 | símbolo | app/lib/data/player/providers/public_playback_http.dart:109 | app/lib/sources/public_playback_http.dart | pendiente |
| S1899 | símbolo | app/lib/data/player/providers/public_playback_http.dart:129 | app/lib/sources/public_playback_http.dart | pendiente |
| S1900 | símbolo | app/lib/data/player/providers/public_playback_http.dart:451 | app/lib/sources/public_playback_http.dart | pendiente |
| S1901 | símbolo | app/lib/data/player/providers/public_playback_http.dart:452 | app/lib/sources/public_playback_http.dart | pendiente |
| S1902 | símbolo | app/lib/data/player/providers/public_playback_http.dart:461 | app/lib/sources/public_playback_http.dart | pendiente |
| S1903 | símbolo | app/lib/data/player/providers/public_playback_http.dart:462 | app/lib/sources/public_playback_http.dart | pendiente |
| S1904 | símbolo | app/lib/data/player/providers/public_playback_http.dart:463 | app/lib/sources/public_playback_http.dart | pendiente |
| S1905 | símbolo | app/lib/data/player/providers/public_playback_http.dart:464 | app/lib/sources/public_playback_http.dart | pendiente |
| S1906 | símbolo | app/lib/data/player/providers/public_playback_http.dart:465 | app/lib/sources/public_playback_http.dart | pendiente |
| S1907 | símbolo | app/lib/data/player/providers/public_playback_http.dart:466 | app/lib/sources/public_playback_http.dart | pendiente |
| S1908 | símbolo | app/lib/data/player/providers/public_playback_http.dart:467 | app/lib/sources/public_playback_http.dart | pendiente |
| S1909 | símbolo | app/lib/data/player/providers/public_playback_http.dart:469 | app/lib/sources/public_playback_http.dart | pendiente |
| S1910 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:1 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1911 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:10 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1912 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:22 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1913 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:24 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1914 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:26 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1915 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:29 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1916 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:31 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1917 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:34 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1918 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:38 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1919 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:40 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1920 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:43 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1921 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1922 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1923 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1924 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1925 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:46 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1926 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:52 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1927 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:58 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1928 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:68 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1929 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:72 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1930 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:77 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1931 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:86 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1932 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:87 | app/lib/sources/registry/provider_spec.dart | pendiente |
| S1933 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:8 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1934 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:10 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1935 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:28 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1936 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:29 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1937 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:30 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1938 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:31 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1939 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:32 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1940 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:34 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1941 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:73 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1942 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:76 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1943 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:79 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1944 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:82 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1945 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:86 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1946 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:89 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1947 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:96 | app/lib/sources/user_sources/user_defined_playback_provider.dart | pendiente |
| S1948 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:14 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1949 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:17 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1950 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:36 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1951 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:38 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1952 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:45 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1953 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:48 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1954 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:69 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1955 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:85 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| S1956 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_identity.dart:2 | app/lib/sources/wikimedia/wikimedia_identity.dart | pendiente |
| S1957 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:7 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| S1958 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:12 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| S1959 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:19 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| S1960 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:28 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| S1961 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:41 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| S1962 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:5 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| S1963 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:6 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| S1964 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:11 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| S1965 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:14 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| S1966 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:18 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| S1967 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:1 | app/lib/data/secure_storage/secure_storage_api.dart | pendiente |
| S1968 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:6 | app/lib/data/secure_storage/secure_storage_api.dart | pendiente |
| S1969 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:8 | app/lib/data/secure_storage/secure_storage_api.dart | pendiente |
| S1970 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:10 | app/lib/data/secure_storage/secure_storage_api.dart | pendiente |
| S1971 | símbolo | app/lib/data/testing/fake_sync_remote.dart:8 | app/lib/data/testing/fake_sync_remote.dart | pendiente |
| S1972 | símbolo | app/lib/data/testing/fake_sync_remote.dart:10 | app/lib/data/testing/fake_sync_remote.dart | pendiente |
| S1973 | símbolo | app/lib/data/testing/fake_sync_remote.dart:12 | app/lib/data/testing/fake_sync_remote.dart | pendiente |
| S1974 | símbolo | app/lib/data/testing/fake_sync_remote.dart:15 | app/lib/data/testing/fake_sync_remote.dart | pendiente |
| S1975 | símbolo | app/lib/data/testing/fake_sync_remote.dart:17 | app/lib/data/testing/fake_sync_remote.dart | pendiente |
| S1976 | símbolo | app/lib/domain/app_identity.dart:1 | app/lib/domain/app_identity.dart | pendiente |
| S1977 | símbolo | app/lib/domain/app_identity.dart:3 | app/lib/domain/app_identity.dart | pendiente |
| S1978 | símbolo | app/lib/domain/auth/secure_credential_store.dart:3 | app/lib/domain/auth/secure_credential_store.dart | pendiente |
| S1979 | símbolo | app/lib/domain/auth/secure_credential_store.dart:8 | app/lib/domain/auth/secure_credential_store.dart | pendiente |
| S1980 | símbolo | app/lib/domain/auth/secure_credential_store.dart:10 | app/lib/domain/auth/secure_credential_store.dart | pendiente |
| S1981 | símbolo | app/lib/domain/auth/secure_credential_store.dart:12 | app/lib/domain/auth/secure_credential_store.dart | pendiente |
| S1982 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:4 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1983 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:4 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1984 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:4 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1985 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:6 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1986 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:8 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1987 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:10 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1988 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:16 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1989 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:24 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1990 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:26 | app/lib/domain/catalog/anime_catalog_repository.dart | pendiente |
| S1991 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:3 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1992 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:4 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1993 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:11 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1994 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:12 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1995 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:14 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1996 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:19 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1997 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:44 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1998 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:45 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S1999 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:46 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2000 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:47 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2001 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:50 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2002 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:53 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2003 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:55 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2004 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:67 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2005 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:68 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2006 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:69 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2007 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:70 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2008 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:71 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2009 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:72 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2010 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:73 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2011 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:74 | app/lib/domain/catalog/anime_detail_metadata.dart | pendiente |
| S2012 | símbolo | app/lib/domain/catalog/anime_id.dart:1 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2013 | símbolo | app/lib/domain/catalog/anime_id.dart:6 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2014 | símbolo | app/lib/domain/catalog/anime_id.dart:16 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2015 | símbolo | app/lib/domain/catalog/anime_id.dart:18 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2016 | símbolo | app/lib/domain/catalog/anime_id.dart:21 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2017 | símbolo | app/lib/domain/catalog/anime_id.dart:24 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2018 | símbolo | app/lib/domain/catalog/anime_id.dart:28 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2019 | símbolo | app/lib/domain/catalog/anime_id.dart:30 | app/lib/domain/catalog/anime_id.dart | pendiente |
| S2020 | símbolo | app/lib/domain/catalog/anime_identity.dart:4 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2021 | símbolo | app/lib/domain/catalog/anime_identity.dart:5 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2022 | símbolo | app/lib/domain/catalog/anime_identity.dart:6 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2023 | símbolo | app/lib/domain/catalog/anime_identity.dart:7 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2024 | símbolo | app/lib/domain/catalog/anime_identity.dart:10 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2025 | símbolo | app/lib/domain/catalog/anime_identity.dart:11 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2026 | símbolo | app/lib/domain/catalog/anime_identity.dart:12 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2027 | símbolo | app/lib/domain/catalog/anime_identity.dart:13 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2028 | símbolo | app/lib/domain/catalog/anime_identity.dart:14 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2029 | símbolo | app/lib/domain/catalog/anime_identity.dart:15 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2030 | símbolo | app/lib/domain/catalog/anime_identity.dart:16 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2031 | símbolo | app/lib/domain/catalog/anime_identity.dart:17 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2032 | símbolo | app/lib/domain/catalog/anime_identity.dart:20 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2033 | símbolo | app/lib/domain/catalog/anime_identity.dart:21 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2034 | símbolo | app/lib/domain/catalog/anime_identity.dart:27 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2035 | símbolo | app/lib/domain/catalog/anime_identity.dart:28 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2036 | símbolo | app/lib/domain/catalog/anime_identity.dart:29 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2037 | símbolo | app/lib/domain/catalog/anime_identity.dart:32 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2038 | símbolo | app/lib/domain/catalog/anime_identity.dart:33 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2039 | símbolo | app/lib/domain/catalog/anime_identity.dart:40 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2040 | símbolo | app/lib/domain/catalog/anime_identity.dart:41 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2041 | símbolo | app/lib/domain/catalog/anime_identity.dart:42 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2042 | símbolo | app/lib/domain/catalog/anime_identity.dart:43 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2043 | símbolo | app/lib/domain/catalog/anime_identity.dart:46 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2044 | símbolo | app/lib/domain/catalog/anime_identity.dart:49 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2045 | símbolo | app/lib/domain/catalog/anime_identity.dart:70 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2046 | símbolo | app/lib/domain/catalog/anime_identity.dart:71 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2047 | símbolo | app/lib/domain/catalog/anime_identity.dart:72 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2048 | símbolo | app/lib/domain/catalog/anime_identity.dart:73 | app/lib/domain/catalog/anime_identity.dart | pendiente |
| S2049 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:7 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2050 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:8 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2051 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:10 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2052 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:12 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2053 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:19 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2054 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:21 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2055 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:28 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2056 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:36 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2057 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:37 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2058 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:40 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2059 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:41 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2060 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:43 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2061 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:46 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2062 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:47 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2063 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:50 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2064 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:51 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2065 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:53 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2066 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:56 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2067 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:59 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2068 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:61 | app/lib/domain/catalog/anime_identity_repository.dart | pendiente |
| S2069 | símbolo | app/lib/domain/catalog/anime_summary.dart:5 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2070 | símbolo | app/lib/domain/catalog/anime_summary.dart:7 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2071 | símbolo | app/lib/domain/catalog/anime_summary.dart:27 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2072 | símbolo | app/lib/domain/catalog/anime_summary.dart:28 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2073 | símbolo | app/lib/domain/catalog/anime_summary.dart:29 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2074 | símbolo | app/lib/domain/catalog/anime_summary.dart:30 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2075 | símbolo | app/lib/domain/catalog/anime_summary.dart:31 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2076 | símbolo | app/lib/domain/catalog/anime_summary.dart:32 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2077 | símbolo | app/lib/domain/catalog/anime_summary.dart:33 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2078 | símbolo | app/lib/domain/catalog/anime_summary.dart:34 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2079 | símbolo | app/lib/domain/catalog/anime_summary.dart:35 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2080 | símbolo | app/lib/domain/catalog/anime_summary.dart:36 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2081 | símbolo | app/lib/domain/catalog/anime_summary.dart:37 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2082 | símbolo | app/lib/domain/catalog/anime_summary.dart:38 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2083 | símbolo | app/lib/domain/catalog/anime_summary.dart:39 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2084 | símbolo | app/lib/domain/catalog/anime_summary.dart:40 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2085 | símbolo | app/lib/domain/catalog/anime_summary.dart:41 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2086 | símbolo | app/lib/domain/catalog/anime_summary.dart:42 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2087 | símbolo | app/lib/domain/catalog/anime_summary.dart:43 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2088 | símbolo | app/lib/domain/catalog/anime_summary.dart:46 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2089 | símbolo | app/lib/domain/catalog/anime_summary.dart:48 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2090 | símbolo | app/lib/domain/catalog/anime_summary.dart:50 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2091 | símbolo | app/lib/domain/catalog/anime_summary.dart:51 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2092 | símbolo | app/lib/domain/catalog/anime_summary.dart:52 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2093 | símbolo | app/lib/domain/catalog/anime_summary.dart:55 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2094 | símbolo | app/lib/domain/catalog/anime_summary.dart:55 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2095 | símbolo | app/lib/domain/catalog/anime_summary.dart:55 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2096 | símbolo | app/lib/domain/catalog/anime_summary.dart:57 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2097 | símbolo | app/lib/domain/catalog/anime_summary.dart:59 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2098 | símbolo | app/lib/domain/catalog/anime_summary.dart:65 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2099 | símbolo | app/lib/domain/catalog/anime_summary.dart:66 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2100 | símbolo | app/lib/domain/catalog/anime_summary.dart:67 | app/lib/domain/catalog/anime_summary.dart | pendiente |
| S2101 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:5 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2102 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:10 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2103 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:21 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2104 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:22 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2105 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:23 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2106 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:24 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2107 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:27 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2108 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:30 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2109 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:32 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| S2110 | símbolo | app/lib/domain/catalog/external_anime_id.dart:1 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2111 | símbolo | app/lib/domain/catalog/external_anime_id.dart:3 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2112 | símbolo | app/lib/domain/catalog/external_anime_id.dart:17 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2113 | símbolo | app/lib/domain/catalog/external_anime_id.dart:19 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2114 | símbolo | app/lib/domain/catalog/external_anime_id.dart:23 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2115 | símbolo | app/lib/domain/catalog/external_anime_id.dart:26 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2116 | símbolo | app/lib/domain/catalog/external_anime_id.dart:30 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2117 | símbolo | app/lib/domain/catalog/external_anime_id.dart:33 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2118 | símbolo | app/lib/domain/catalog/external_anime_id.dart:46 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2119 | símbolo | app/lib/domain/catalog/external_anime_id.dart:47 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2120 | símbolo | app/lib/domain/catalog/external_anime_id.dart:49 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2121 | símbolo | app/lib/domain/catalog/external_anime_id.dart:53 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2122 | símbolo | app/lib/domain/catalog/external_anime_id.dart:59 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2123 | símbolo | app/lib/domain/catalog/external_anime_id.dart:62 | app/lib/domain/catalog/external_anime_id.dart | pendiente |
| S2124 | símbolo | app/lib/domain/catalog/library_entry.dart:3 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2125 | símbolo | app/lib/domain/catalog/library_entry.dart:5 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2126 | símbolo | app/lib/domain/catalog/library_entry.dart:6 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2127 | símbolo | app/lib/domain/catalog/library_entry.dart:7 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2128 | símbolo | app/lib/domain/catalog/library_entry.dart:8 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2129 | símbolo | app/lib/domain/catalog/library_entry.dart:9 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2130 | símbolo | app/lib/domain/catalog/library_entry.dart:10 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2131 | símbolo | app/lib/domain/catalog/library_entry.dart:13 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2132 | símbolo | app/lib/domain/catalog/library_entry.dart:16 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2133 | símbolo | app/lib/domain/catalog/library_entry.dart:22 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2134 | símbolo | app/lib/domain/catalog/library_entry.dart:23 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2135 | símbolo | app/lib/domain/catalog/library_entry.dart:24 | app/lib/domain/catalog/library_entry.dart | pendiente |
| S2136 | símbolo | app/lib/domain/catalog/library_repository.dart:5 | app/lib/domain/catalog/library_repository.dart | pendiente |
| S2137 | símbolo | app/lib/domain/catalog/library_repository.dart:6 | app/lib/domain/catalog/library_repository.dart | pendiente |
| S2138 | símbolo | app/lib/domain/catalog/library_repository.dart:8 | app/lib/domain/catalog/library_repository.dart | pendiente |
| S2139 | símbolo | app/lib/domain/catalog/library_repository.dart:10 | app/lib/domain/catalog/library_repository.dart | pendiente |
| S2140 | símbolo | app/lib/domain/catalog/library_repository.dart:12 | app/lib/domain/catalog/library_repository.dart | pendiente |
| S2141 | símbolo | app/lib/domain/catalog/library_repository.dart:14 | app/lib/domain/catalog/library_repository.dart | pendiente |
| S2142 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:3 | app/lib/domain/catalog/metadata_provenance.dart | pendiente |
| S2143 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:6 | app/lib/domain/catalog/metadata_provenance.dart | pendiente |
| S2144 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:15 | app/lib/domain/catalog/metadata_provenance.dart | pendiente |
| S2145 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:16 | app/lib/domain/catalog/metadata_provenance.dart | pendiente |
| S2146 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:17 | app/lib/domain/catalog/metadata_provenance.dart | pendiente |
| S2147 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2148 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2149 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2150 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2151 | símbolo | app/lib/domain/catalog/metadata_provider.dart:8 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2152 | símbolo | app/lib/domain/catalog/metadata_provider.dart:10 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2153 | símbolo | app/lib/domain/catalog/metadata_provider.dart:12 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2154 | símbolo | app/lib/domain/catalog/metadata_provider.dart:14 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2155 | símbolo | app/lib/domain/catalog/metadata_provider.dart:19 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2156 | símbolo | app/lib/domain/catalog/metadata_provider.dart:23 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2157 | símbolo | app/lib/domain/catalog/metadata_provider.dart:27 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2158 | símbolo | app/lib/domain/catalog/metadata_provider.dart:30 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2159 | símbolo | app/lib/domain/catalog/metadata_provider.dart:31 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2160 | símbolo | app/lib/domain/catalog/metadata_provider.dart:37 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2161 | símbolo | app/lib/domain/catalog/metadata_provider.dart:38 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2162 | símbolo | app/lib/domain/catalog/metadata_provider.dart:39 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2163 | símbolo | app/lib/domain/catalog/metadata_provider.dart:42 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2164 | símbolo | app/lib/domain/catalog/metadata_provider.dart:45 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2165 | símbolo | app/lib/domain/catalog/metadata_provider.dart:78 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2166 | símbolo | app/lib/domain/catalog/metadata_provider.dart:98 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2167 | símbolo | app/lib/domain/catalog/metadata_provider.dart:101 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2168 | símbolo | app/lib/domain/catalog/metadata_provider.dart:106 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2169 | símbolo | app/lib/domain/catalog/metadata_provider.dart:107 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2170 | símbolo | app/lib/domain/catalog/metadata_provider.dart:110 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2171 | símbolo | app/lib/domain/catalog/metadata_provider.dart:112 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2172 | símbolo | app/lib/domain/catalog/metadata_provider.dart:115 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2173 | símbolo | app/lib/domain/catalog/metadata_provider.dart:120 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2174 | símbolo | app/lib/domain/catalog/metadata_provider.dart:121 | app/lib/domain/catalog/metadata_provider.dart | pendiente |
| S2175 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2176 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2177 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2178 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2179 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2180 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2181 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2182 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2183 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:7 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2184 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:8 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2185 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:9 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2186 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:10 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2187 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:11 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2188 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:12 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2189 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:15 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2190 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:19 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2191 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:61 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2192 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:62 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2193 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:63 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2194 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:64 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2195 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:65 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2196 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:66 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2197 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:67 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2198 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:68 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2199 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:69 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2200 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:70 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2201 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:71 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2202 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:72 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2203 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:73 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2204 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:74 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2205 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:75 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2206 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:76 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2207 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:77 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2208 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:78 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2209 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:79 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2210 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:87 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2211 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:90 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2212 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:116 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2213 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:117 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2214 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:118 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2215 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:119 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2216 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:120 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2217 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:121 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2218 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:122 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2219 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:123 | app/lib/domain/catalog/provider_anime_metadata.dart | pendiente |
| S2220 | símbolo | app/lib/domain/catalog/provider_result.dart:1 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2221 | símbolo | app/lib/domain/catalog/provider_result.dart:2 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2222 | símbolo | app/lib/domain/catalog/provider_result.dart:3 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2223 | símbolo | app/lib/domain/catalog/provider_result.dart:4 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2224 | símbolo | app/lib/domain/catalog/provider_result.dart:5 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2225 | símbolo | app/lib/domain/catalog/provider_result.dart:6 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2226 | símbolo | app/lib/domain/catalog/provider_result.dart:7 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2227 | símbolo | app/lib/domain/catalog/provider_result.dart:8 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2228 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2229 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2230 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2231 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2232 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2233 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2234 | símbolo | app/lib/domain/catalog/provider_result.dart:13 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2235 | símbolo | app/lib/domain/catalog/provider_result.dart:16 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2236 | símbolo | app/lib/domain/catalog/provider_result.dart:19 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2237 | símbolo | app/lib/domain/catalog/provider_result.dart:20 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2238 | símbolo | app/lib/domain/catalog/provider_result.dart:22 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2239 | símbolo | app/lib/domain/catalog/provider_result.dart:25 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2240 | símbolo | app/lib/domain/catalog/provider_result.dart:26 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2241 | símbolo | app/lib/domain/catalog/provider_result.dart:29 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2242 | símbolo | app/lib/domain/catalog/provider_result.dart:30 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2243 | símbolo | app/lib/domain/catalog/provider_result.dart:32 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2244 | símbolo | app/lib/domain/catalog/provider_result.dart:35 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2245 | símbolo | app/lib/domain/catalog/provider_result.dart:36 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2246 | símbolo | app/lib/domain/catalog/provider_result.dart:38 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2247 | símbolo | app/lib/domain/catalog/provider_result.dart:39 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2248 | símbolo | app/lib/domain/catalog/provider_result.dart:41 | app/lib/domain/catalog/provider_result.dart | pendiente |
| S2249 | símbolo | app/lib/domain/player/audio_track_info.dart:1 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2250 | símbolo | app/lib/domain/player/audio_track_info.dart:3 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2251 | símbolo | app/lib/domain/player/audio_track_info.dart:14 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2252 | símbolo | app/lib/domain/player/audio_track_info.dart:15 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2253 | símbolo | app/lib/domain/player/audio_track_info.dart:16 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2254 | símbolo | app/lib/domain/player/audio_track_info.dart:17 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2255 | símbolo | app/lib/domain/player/audio_track_info.dart:18 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2256 | símbolo | app/lib/domain/player/audio_track_info.dart:19 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2257 | símbolo | app/lib/domain/player/audio_track_info.dart:20 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2258 | símbolo | app/lib/domain/player/audio_track_info.dart:21 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2259 | símbolo | app/lib/domain/player/audio_track_info.dart:23 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2260 | símbolo | app/lib/domain/player/audio_track_info.dart:34 | app/lib/domain/player/audio_track_info.dart | pendiente |
| S2261 | símbolo | app/lib/domain/player/providers/anime_identity.dart:4 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| S2262 | símbolo | app/lib/domain/player/providers/anime_identity.dart:7 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| S2263 | símbolo | app/lib/domain/player/providers/anime_identity.dart:26 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| S2264 | símbolo | app/lib/domain/player/providers/anime_identity.dart:27 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| S2265 | símbolo | app/lib/domain/player/providers/anime_identity.dart:28 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| S2266 | símbolo | app/lib/domain/player/providers/anime_identity.dart:30 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| S2267 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2268 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2269 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2270 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2271 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2272 | símbolo | app/lib/domain/player/providers/episode_source.dart:8 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2273 | símbolo | app/lib/domain/player/providers/episode_source.dart:10 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2274 | símbolo | app/lib/domain/player/providers/episode_source.dart:28 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2275 | símbolo | app/lib/domain/player/providers/episode_source.dart:29 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2276 | símbolo | app/lib/domain/player/providers/episode_source.dart:30 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2277 | símbolo | app/lib/domain/player/providers/episode_source.dart:31 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2278 | símbolo | app/lib/domain/player/providers/episode_source.dart:32 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2279 | símbolo | app/lib/domain/player/providers/episode_source.dart:33 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2280 | símbolo | app/lib/domain/player/providers/episode_source.dart:34 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2281 | símbolo | app/lib/domain/player/providers/episode_source.dart:36 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2282 | símbolo | app/lib/domain/player/providers/episode_source.dart:56 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2283 | símbolo | app/lib/domain/player/providers/episode_source.dart:58 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2284 | símbolo | app/lib/domain/player/providers/episode_source.dart:75 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2285 | símbolo | app/lib/domain/player/providers/episode_source.dart:76 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2286 | símbolo | app/lib/domain/player/providers/episode_source.dart:77 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2287 | símbolo | app/lib/domain/player/providers/episode_source.dart:78 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2288 | símbolo | app/lib/domain/player/providers/episode_source.dart:79 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2289 | símbolo | app/lib/domain/player/providers/episode_source.dart:81 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2290 | símbolo | app/lib/domain/player/providers/episode_source.dart:82 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2291 | símbolo | app/lib/domain/player/providers/episode_source.dart:84 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| S2292 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:7 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2293 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:8 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2294 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:9 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2295 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:10 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2296 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:13 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2297 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:14 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2298 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:15 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2299 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:16 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2300 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:17 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2301 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:18 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2302 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:19 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2303 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:20 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2304 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:21 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2305 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:22 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2306 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:23 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2307 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:24 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2308 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:25 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2309 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:26 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2310 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:27 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2311 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:28 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2312 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:29 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2313 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:30 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2314 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:31 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2315 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:32 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2316 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:33 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2317 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:34 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2318 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:35 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2319 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:36 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2320 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:37 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2321 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:38 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2322 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:39 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2323 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:42 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2324 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:43 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2325 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2326 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2327 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2328 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2329 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2330 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2331 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:76 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2332 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:77 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2333 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:87 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2334 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:88 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2335 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:89 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2336 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:90 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2337 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:91 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2338 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:93 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2339 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:94 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2340 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:96 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2341 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:101 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2342 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:102 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2343 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:105 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2344 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:106 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2345 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:107 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2346 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:110 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2347 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:111 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2348 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:114 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2349 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:115 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2350 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:116 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2351 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:119 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2352 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:120 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2353 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:121 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2354 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:124 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2355 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:130 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2356 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:131 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2357 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:133 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2358 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:149 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2359 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:161 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2360 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:162 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2361 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:163 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2362 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:165 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2363 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:171 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2364 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:176 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2365 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:178 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2366 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:181 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2367 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:183 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2368 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:190 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2369 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:195 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2370 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:197 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2371 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:202 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2372 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:207 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2373 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:238 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2374 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:243 | app/lib/domain/player/providers/playback_provider_contract.dart | pendiente |
| S2375 | símbolo | app/lib/domain/player/providers/playback_source.dart:6 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2376 | símbolo | app/lib/domain/player/providers/playback_source.dart:8 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2377 | símbolo | app/lib/domain/player/providers/playback_source.dart:32 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2378 | símbolo | app/lib/domain/player/providers/playback_source.dart:42 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2379 | símbolo | app/lib/domain/player/providers/playback_source.dart:43 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2380 | símbolo | app/lib/domain/player/providers/playback_source.dart:44 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2381 | símbolo | app/lib/domain/player/providers/playback_source.dart:45 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2382 | símbolo | app/lib/domain/player/providers/playback_source.dart:47 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2383 | símbolo | app/lib/domain/player/providers/playback_source.dart:49 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2384 | símbolo | app/lib/domain/player/providers/playback_source.dart:55 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2385 | símbolo | app/lib/domain/player/providers/playback_source.dart:74 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2386 | símbolo | app/lib/domain/player/providers/playback_source.dart:76 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2387 | símbolo | app/lib/domain/player/providers/playback_source.dart:90 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2388 | símbolo | app/lib/domain/player/providers/playback_source.dart:92 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2389 | símbolo | app/lib/domain/player/providers/playback_source.dart:96 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2390 | símbolo | app/lib/domain/player/providers/playback_source.dart:99 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2391 | símbolo | app/lib/domain/player/providers/playback_source.dart:103 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2392 | símbolo | app/lib/domain/player/providers/playback_source.dart:104 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2393 | símbolo | app/lib/domain/player/providers/playback_source.dart:105 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2394 | símbolo | app/lib/domain/player/providers/playback_source.dart:106 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2395 | símbolo | app/lib/domain/player/providers/playback_source.dart:107 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2396 | símbolo | app/lib/domain/player/providers/playback_source.dart:108 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2397 | símbolo | app/lib/domain/player/providers/playback_source.dart:111 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2398 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2399 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2400 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2401 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2402 | símbolo | app/lib/domain/player/providers/playback_source.dart:114 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2403 | símbolo | app/lib/domain/player/providers/playback_source.dart:116 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2404 | símbolo | app/lib/domain/player/providers/playback_source.dart:137 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2405 | símbolo | app/lib/domain/player/providers/playback_source.dart:138 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2406 | símbolo | app/lib/domain/player/providers/playback_source.dart:139 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2407 | símbolo | app/lib/domain/player/providers/playback_source.dart:140 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2408 | símbolo | app/lib/domain/player/providers/playback_source.dart:141 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2409 | símbolo | app/lib/domain/player/providers/playback_source.dart:143 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2410 | símbolo | app/lib/domain/player/providers/playback_source.dart:151 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2411 | símbolo | app/lib/domain/player/providers/playback_source.dart:166 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2412 | símbolo | app/lib/domain/player/providers/playback_source.dart:168 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2413 | símbolo | app/lib/domain/player/providers/playback_source.dart:203 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2414 | símbolo | app/lib/domain/player/providers/playback_source.dart:204 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2415 | símbolo | app/lib/domain/player/providers/playback_source.dart:205 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2416 | símbolo | app/lib/domain/player/providers/playback_source.dart:206 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2417 | símbolo | app/lib/domain/player/providers/playback_source.dart:207 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2418 | símbolo | app/lib/domain/player/providers/playback_source.dart:208 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2419 | símbolo | app/lib/domain/player/providers/playback_source.dart:211 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2420 | símbolo | app/lib/domain/player/providers/playback_source.dart:214 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2421 | símbolo | app/lib/domain/player/providers/playback_source.dart:215 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2422 | símbolo | app/lib/domain/player/providers/playback_source.dart:218 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2423 | símbolo | app/lib/domain/player/providers/playback_source.dart:219 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2424 | símbolo | app/lib/domain/player/providers/playback_source.dart:220 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2425 | símbolo | app/lib/domain/player/providers/playback_source.dart:221 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2426 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2427 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2428 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2429 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2430 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2431 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2432 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2433 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2434 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2435 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2436 | símbolo | app/lib/domain/player/providers/playback_source.dart:228 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2437 | símbolo | app/lib/domain/player/providers/playback_source.dart:231 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2438 | símbolo | app/lib/domain/player/providers/playback_source.dart:265 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2439 | símbolo | app/lib/domain/player/providers/playback_source.dart:266 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2440 | símbolo | app/lib/domain/player/providers/playback_source.dart:267 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2441 | símbolo | app/lib/domain/player/providers/playback_source.dart:268 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2442 | símbolo | app/lib/domain/player/providers/playback_source.dart:269 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2443 | símbolo | app/lib/domain/player/providers/playback_source.dart:270 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2444 | símbolo | app/lib/domain/player/providers/playback_source.dart:271 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2445 | símbolo | app/lib/domain/player/providers/playback_source.dart:272 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2446 | símbolo | app/lib/domain/player/providers/playback_source.dart:275 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2447 | símbolo | app/lib/domain/player/providers/playback_source.dart:276 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2448 | símbolo | app/lib/domain/player/providers/playback_source.dart:277 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2449 | símbolo | app/lib/domain/player/providers/playback_source.dart:278 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2450 | símbolo | app/lib/domain/player/providers/playback_source.dart:279 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2451 | símbolo | app/lib/domain/player/providers/playback_source.dart:280 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2452 | símbolo | app/lib/domain/player/providers/playback_source.dart:282 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2453 | símbolo | app/lib/domain/player/providers/playback_source.dart:289 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2454 | símbolo | app/lib/domain/player/providers/playback_source.dart:291 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2455 | símbolo | app/lib/domain/player/providers/playback_source.dart:300 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2456 | símbolo | app/lib/domain/player/providers/playback_source.dart:373 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2457 | símbolo | app/lib/domain/player/providers/playback_source.dart:377 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2458 | símbolo | app/lib/domain/player/providers/playback_source.dart:379 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2459 | símbolo | app/lib/domain/player/providers/playback_source.dart:408 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2460 | símbolo | app/lib/domain/player/providers/playback_source.dart:411 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2461 | símbolo | app/lib/domain/player/providers/playback_source.dart:440 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2462 | símbolo | app/lib/domain/player/providers/playback_source.dart:441 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2463 | símbolo | app/lib/domain/player/providers/playback_source.dart:442 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2464 | símbolo | app/lib/domain/player/providers/playback_source.dart:443 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2465 | símbolo | app/lib/domain/player/providers/playback_source.dart:444 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2466 | símbolo | app/lib/domain/player/providers/playback_source.dart:445 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2467 | símbolo | app/lib/domain/player/providers/playback_source.dart:446 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2468 | símbolo | app/lib/domain/player/providers/playback_source.dart:447 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2469 | símbolo | app/lib/domain/player/providers/playback_source.dart:448 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2470 | símbolo | app/lib/domain/player/providers/playback_source.dart:449 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2471 | símbolo | app/lib/domain/player/providers/playback_source.dart:450 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2472 | símbolo | app/lib/domain/player/providers/playback_source.dart:451 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2473 | símbolo | app/lib/domain/player/providers/playback_source.dart:452 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2474 | símbolo | app/lib/domain/player/providers/playback_source.dart:454 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2475 | símbolo | app/lib/domain/player/providers/playback_source.dart:458 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| S2476 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:4 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2477 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:6 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2478 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:14 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2479 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:15 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2480 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:16 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2481 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:17 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2482 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:18 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2483 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2484 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2485 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2486 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2487 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:23 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2488 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:25 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2489 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:36 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2490 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:37 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2491 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:38 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2492 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:39 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2493 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:42 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2494 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:43 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2495 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:45 | app/lib/domain/player/skips/skip_automation_policy.dart | pendiente |
| S2496 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2497 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2498 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2499 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2500 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2501 | símbolo | app/lib/domain/player/skips/skip_segment.dart:5 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2502 | símbolo | app/lib/domain/player/skips/skip_segment.dart:5 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2503 | símbolo | app/lib/domain/player/skips/skip_segment.dart:5 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2504 | símbolo | app/lib/domain/player/skips/skip_segment.dart:7 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2505 | símbolo | app/lib/domain/player/skips/skip_segment.dart:9 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2506 | símbolo | app/lib/domain/player/skips/skip_segment.dart:28 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2507 | símbolo | app/lib/domain/player/skips/skip_segment.dart:29 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2508 | símbolo | app/lib/domain/player/skips/skip_segment.dart:30 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2509 | símbolo | app/lib/domain/player/skips/skip_segment.dart:31 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2510 | símbolo | app/lib/domain/player/skips/skip_segment.dart:32 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2511 | símbolo | app/lib/domain/player/skips/skip_segment.dart:33 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2512 | símbolo | app/lib/domain/player/skips/skip_segment.dart:34 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2513 | símbolo | app/lib/domain/player/skips/skip_segment.dart:35 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2514 | símbolo | app/lib/domain/player/skips/skip_segment.dart:37 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2515 | símbolo | app/lib/domain/player/skips/skip_segment.dart:44 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2516 | símbolo | app/lib/domain/player/skips/skip_segment.dart:46 | app/lib/domain/player/skips/skip_segment.dart | pendiente |
| S2517 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:4 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2518 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:5 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2519 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:11 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2520 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:14 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2521 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:15 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2522 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:16 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2523 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:17 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2524 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:18 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2525 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:19 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2526 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:22 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2527 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:23 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2528 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:26 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2529 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:27 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2530 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:28 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2531 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:31 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2532 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:32 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2533 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:33 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2534 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:36 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2535 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:37 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2536 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:38 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2537 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:41 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2538 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:43 | app/lib/domain/player/skips/skip_segment_catalog.dart | pendiente |
| S2539 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:3 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2540 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:5 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2541 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:69 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2542 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:70 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2543 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:71 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2544 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:72 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2545 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:73 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2546 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:74 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2547 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:75 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2548 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:76 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2549 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:77 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2550 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:80 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2551 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:81 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2552 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:96 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2553 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:97 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2554 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:98 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2555 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:99 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2556 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:100 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2557 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:101 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2558 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:102 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2559 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:103 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2560 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:104 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2561 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:105 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2562 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:106 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2563 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:107 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2564 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:110 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2565 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:111 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2566 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:120 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2567 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:121 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2568 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:122 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2569 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:123 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2570 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:124 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2571 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:127 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2572 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:128 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2573 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:131 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2574 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:132 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2575 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:133 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2576 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:136 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2577 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:137 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2578 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:138 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2579 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:139 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2580 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:142 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2581 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:143 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2582 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:144 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2583 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:145 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2584 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:146 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2585 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:147 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2586 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:148 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2587 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:149 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2588 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:150 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2589 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:151 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2590 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:152 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2591 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:153 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2592 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:154 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2593 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:155 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2594 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:156 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2595 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:157 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2596 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:158 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2597 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:159 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2598 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:162 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2599 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:163 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2600 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:167 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2601 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:172 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2602 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:174 | app/lib/domain/player/subtitles/external_subtitle_catalog.dart | pendiente |
| S2603 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2604 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2605 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2606 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2607 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2608 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2609 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2610 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2611 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:5 | app/lib/domain/player/subtitles/hardsub_policy.dart | pendiente |
| S2612 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:1 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2613 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:3 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2614 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:37 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2615 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:38 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2616 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:39 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2617 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:40 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2618 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:41 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2619 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:42 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2620 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:43 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2621 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:47 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2622 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:49 | app/lib/domain/player/subtitles/subtitle_style.dart | pendiente |
| S2623 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:1 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2624 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:3 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2625 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:13 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2626 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:14 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2627 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:15 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2628 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:16 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2629 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:17 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2630 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:18 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2631 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:19 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2632 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2633 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2634 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2635 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2636 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | app/lib/domain/player/subtitles/subtitle_track_info.dart | pendiente |
| S2637 | símbolo | app/lib/domain/player/video_track_info.dart:1 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2638 | símbolo | app/lib/domain/player/video_track_info.dart:4 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2639 | símbolo | app/lib/domain/player/video_track_info.dart:15 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2640 | símbolo | app/lib/domain/player/video_track_info.dart:16 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2641 | símbolo | app/lib/domain/player/video_track_info.dart:17 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2642 | símbolo | app/lib/domain/player/video_track_info.dart:18 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2643 | símbolo | app/lib/domain/player/video_track_info.dart:19 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2644 | símbolo | app/lib/domain/player/video_track_info.dart:20 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2645 | símbolo | app/lib/domain/player/video_track_info.dart:21 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2646 | símbolo | app/lib/domain/player/video_track_info.dart:22 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2647 | símbolo | app/lib/domain/player/video_track_info.dart:24 | app/lib/domain/player/video_track_info.dart | pendiente |
| S2648 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2649 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2650 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2651 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2652 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2653 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2654 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:9 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2655 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:12 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2656 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:19 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2657 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:21 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2658 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:22 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2659 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:27 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| S2660 | símbolo | app/lib/domain/progress/content_identity.dart:1 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2661 | símbolo | app/lib/domain/progress/content_identity.dart:3 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2662 | símbolo | app/lib/domain/progress/content_identity.dart:4 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2663 | símbolo | app/lib/domain/progress/content_identity.dart:5 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2664 | símbolo | app/lib/domain/progress/content_identity.dart:7 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2665 | símbolo | app/lib/domain/progress/content_identity.dart:11 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2666 | símbolo | app/lib/domain/progress/content_identity.dart:12 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2667 | símbolo | app/lib/domain/progress/content_identity.dart:13 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2668 | símbolo | app/lib/domain/progress/content_identity.dart:14 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2669 | símbolo | app/lib/domain/progress/content_identity.dart:16 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2670 | símbolo | app/lib/domain/progress/content_identity.dart:20 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2671 | símbolo | app/lib/domain/progress/content_identity.dart:21 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2672 | símbolo | app/lib/domain/progress/content_identity.dart:22 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2673 | símbolo | app/lib/domain/progress/content_identity.dart:23 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2674 | símbolo | app/lib/domain/progress/content_identity.dart:24 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2675 | símbolo | app/lib/domain/progress/content_identity.dart:26 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2676 | símbolo | app/lib/domain/progress/content_identity.dart:31 | app/lib/domain/progress/content_identity.dart | pendiente |
| S2677 | símbolo | app/lib/domain/progress/playback_progress.dart:3 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2678 | símbolo | app/lib/domain/progress/playback_progress.dart:3 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2679 | símbolo | app/lib/domain/progress/playback_progress.dart:3 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2680 | símbolo | app/lib/domain/progress/playback_progress.dart:5 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2681 | símbolo | app/lib/domain/progress/playback_progress.dart:8 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2682 | símbolo | app/lib/domain/progress/playback_progress.dart:16 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2683 | símbolo | app/lib/domain/progress/playback_progress.dart:17 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2684 | símbolo | app/lib/domain/progress/playback_progress.dart:18 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2685 | símbolo | app/lib/domain/progress/playback_progress.dart:19 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2686 | símbolo | app/lib/domain/progress/playback_progress.dart:20 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2687 | símbolo | app/lib/domain/progress/playback_progress.dart:21 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2688 | símbolo | app/lib/domain/progress/playback_progress.dart:23 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2689 | símbolo | app/lib/domain/progress/playback_progress.dart:38 | app/lib/domain/progress/playback_progress.dart | pendiente |
| S2690 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:5 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2691 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:6 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2692 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:7 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2693 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:8 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2694 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:9 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2695 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:12 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2696 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:13 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2697 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:14 | app/lib/domain/progress/playback_progress_repository.dart | pendiente |
| S2698 | símbolo | app/lib/domain/progress/progress_document.dart:1 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2699 | símbolo | app/lib/domain/progress/progress_document.dart:6 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2700 | símbolo | app/lib/domain/progress/progress_document.dart:12 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2701 | símbolo | app/lib/domain/progress/progress_document.dart:13 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2702 | símbolo | app/lib/domain/progress/progress_document.dart:16 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2703 | símbolo | app/lib/domain/progress/progress_document.dart:19 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2704 | símbolo | app/lib/domain/progress/progress_document.dart:22 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2705 | símbolo | app/lib/domain/progress/progress_document.dart:24 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2706 | símbolo | app/lib/domain/progress/progress_document.dart:25 | app/lib/domain/progress/progress_document.dart | pendiente |
| S2707 | símbolo | app/lib/domain/progress/progress_repository.dart:4 | app/lib/domain/progress/progress_repository.dart | pendiente |
| S2708 | símbolo | app/lib/domain/progress/progress_repository.dart:7 | app/lib/domain/progress/progress_repository.dart | pendiente |
| S2709 | símbolo | app/lib/domain/progress/progress_repository.dart:9 | app/lib/domain/progress/progress_repository.dart | pendiente |
| S2710 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:1 | app/lib/domain/synchronization/sync_envelope.dart | pendiente |
| S2711 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:6 | app/lib/domain/synchronization/sync_envelope.dart | pendiente |
| S2712 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:8 | app/lib/domain/synchronization/sync_envelope.dart | pendiente |
| S2713 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:9 | app/lib/domain/synchronization/sync_envelope.dart | pendiente |
| S2714 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:12 | app/lib/domain/synchronization/sync_envelope.dart | pendiente |
| S2715 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:14 | app/lib/domain/synchronization/sync_envelope.dart | pendiente |
| S2716 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:16 | app/lib/domain/synchronization/sync_envelope.dart | pendiente |
| S2717 | símbolo | app/lib/domain/synchronization/sync_remote.dart:4 | app/lib/domain/synchronization/sync_remote.dart | pendiente |
| S2718 | símbolo | app/lib/domain/synchronization/sync_remote.dart:7 | app/lib/domain/synchronization/sync_remote.dart | pendiente |
| S2719 | símbolo | app/lib/main.dart:18 | app/lib/main.dart | pendiente |
| S2720 | símbolo | app/lib/main_player_spike.dart:16 | app/lib/main_player_spike.dart | pendiente |
| S2721 | símbolo | app/lib/main_player_spike.dart:134 | app/lib/main_player_spike.dart | pendiente |
| S2722 | símbolo | app/lib/main_player_spike.dart:135 | app/lib/main_player_spike.dart | pendiente |
| S2723 | símbolo | app/lib/main_player_spike.dart:143 | app/lib/main_player_spike.dart | pendiente |
| S2724 | símbolo | app/lib/main_player_spike.dart:144 | app/lib/main_player_spike.dart | pendiente |
| S2725 | símbolo | app/lib/main_player_spike.dart:145 | app/lib/main_player_spike.dart | pendiente |
| S2726 | símbolo | app/lib/main_player_spike.dart:147 | app/lib/main_player_spike.dart | pendiente |
| S2727 | símbolo | app/lib/main_player_spike.dart:149 | app/lib/main_player_spike.dart | pendiente |
| S2728 | símbolo | app/lib/settings/registry/setting_definition.dart:3 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2729 | símbolo | app/lib/settings/registry/setting_definition.dart:4 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2730 | símbolo | app/lib/settings/registry/setting_definition.dart:5 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2731 | símbolo | app/lib/settings/registry/setting_definition.dart:7 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2732 | símbolo | app/lib/settings/registry/setting_definition.dart:9 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2733 | símbolo | app/lib/settings/registry/setting_definition.dart:25 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2734 | símbolo | app/lib/settings/registry/setting_definition.dart:26 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2735 | símbolo | app/lib/settings/registry/setting_definition.dart:27 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2736 | símbolo | app/lib/settings/registry/setting_definition.dart:28 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2737 | símbolo | app/lib/settings/registry/setting_definition.dart:29 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2738 | símbolo | app/lib/settings/registry/setting_definition.dart:30 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2739 | símbolo | app/lib/settings/registry/setting_definition.dart:32 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2740 | símbolo | app/lib/settings/registry/setting_definition.dart:39 | app/lib/settings/registry/setting_definition.dart | pendiente |
| S2741 | símbolo | app/lib/settings/registry/settings_registry.dart:5 | app/lib/settings/registry/settings_registry.dart | pendiente |
| S2742 | símbolo | app/lib/settings/registry/settings_registry.dart:7 | app/lib/settings/registry/settings_registry.dart | pendiente |
| S2743 | símbolo | app/lib/settings/registry/settings_registry.dart:10 | app/lib/settings/registry/settings_registry.dart | pendiente |
| S2744 | símbolo | app/lib/settings/registry/settings_registry.dart:17 | app/lib/settings/registry/settings_registry.dart | pendiente |
| S2745 | símbolo | app/lib/settings/store/settings_store.dart:7 | app/lib/settings/store/settings_store.dart | pendiente |
| S2746 | símbolo | app/lib/settings/store/settings_store.dart:9 | app/lib/settings/store/settings_store.dart | pendiente |
| S2747 | símbolo | app/lib/settings/store/settings_store.dart:15 | app/lib/settings/store/settings_store.dart | pendiente |
| S2748 | símbolo | app/lib/settings/store/settings_store.dart:16 | app/lib/settings/store/settings_store.dart | pendiente |
| S2749 | símbolo | app/lib/settings/store/settings_store.dart:19 | app/lib/settings/store/settings_store.dart | pendiente |
| S2750 | símbolo | app/lib/settings/store/settings_store.dart:39 | app/lib/settings/store/settings_store.dart | pendiente |
| S2751 | símbolo | app/lib/settings/store/settings_store.dart:66 | app/lib/settings/store/settings_store.dart | pendiente |
| C0001 | endpoint/cabecera/parámetro | app/lib/app/anime_app.dart:40 | app/lib/core/bootstrap/anime_app.dart | pendiente |
| C0002 | ruta/pantalla | app/lib/app/catalog/anime_detail_page.dart:18 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| C0003 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:110 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| C0004 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:354 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| C0005 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:359 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| C0006 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:402 | app/lib/features/detail/view/anime_detail_page.dart | pendiente |
| C0007 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:34 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0008 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:95 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0009 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:103 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0010 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:112 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0011 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:204 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0012 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:205 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0013 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:330 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0014 | persistencia | app/lib/app/catalog/catalog_home_page.dart:374 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0015 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:380 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0016 | persistencia | app/lib/app/catalog/catalog_home_page.dart:451 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0017 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:457 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0018 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:465 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0019 | persistencia | app/lib/app/catalog/catalog_home_page.dart:620 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0020 | persistencia | app/lib/app/catalog/catalog_home_page.dart:687 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0021 | configuración | app/lib/app/catalog/catalog_home_page.dart:687 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0022 | persistencia | app/lib/app/catalog/catalog_home_page.dart:688 | app/lib/features/home/view/catalog_home_page.dart | pendiente |
| C0023 | ruta/pantalla | app/lib/app/catalog/catalog_search_page.dart:6 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| C0024 | persistencia | app/lib/app/catalog/catalog_search_page.dart:67 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| C0025 | persistencia | app/lib/app/catalog/catalog_search_page.dart:73 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| C0026 | persistencia | app/lib/app/catalog/catalog_search_page.dart:110 | app/lib/features/search/view/catalog_search_page.dart | pendiente |
| C0027 | ruta/pantalla | app/lib/app/catalog/confirm_completed_status.dart:16 | app/lib/features/home/view/confirm_completed_status.dart | pendiente |
| C0028 | ruta/pantalla | app/lib/app/catalog/confirm_completed_status.dart:20 | app/lib/features/home/view/confirm_completed_status.dart | pendiente |
| C0029 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:32 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0030 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:84 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0031 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:94 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0032 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:103 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0033 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:142 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0034 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:152 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0035 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:154 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0036 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:195 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0037 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:208 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0038 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:225 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0039 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:227 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0040 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:246 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0041 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:378 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0042 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:388 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0043 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:414 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0044 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:429 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0045 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:565 | app/lib/features/detail/widgets/anime_detail_header.dart | pendiente |
| C0046 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:46 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0047 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:60 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0048 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:62 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0049 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:73 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0050 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:74 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0051 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:76 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0052 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:89 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0053 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:94 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0054 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:102 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0055 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:167 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0056 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:331 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0057 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:336 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0058 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:393 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0059 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:515 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0060 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:525 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0061 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:534 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0062 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:568 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0063 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:646 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0064 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:654 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0065 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:691 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0066 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:696 | app/lib/features/detail/widgets/anime_detail_tab_content.dart | pendiente |
| C0067 | persistencia | app/lib/app/catalog/detail/anime_detail_tabs.dart:42 | app/lib/features/detail/widgets/anime_detail_tabs.dart | pendiente |
| C0068 | ruta/pantalla | app/lib/app/catalog/local_library_page.dart:8 | app/lib/features/home/view/local_library_page.dart | pendiente |
| C0069 | persistencia | app/lib/app/catalog/local_library_page.dart:108 | app/lib/features/home/view/local_library_page.dart | pendiente |
| C0070 | persistencia | app/lib/app/catalog/local_library_page.dart:118 | app/lib/features/home/view/local_library_page.dart | pendiente |
| C0071 | endpoint/cabecera/parámetro | app/lib/app/home/README.md:42 | app/lib/features/home/view/README.md | pendiente |
| C0072 | persistencia | app/lib/app/home/home_artwork_diagnostics.dart:24 | app/lib/features/home/view/home_artwork_diagnostics.dart | pendiente |
| C0073 | endpoint/cabecera/parámetro | app/lib/app/home/home_card_actions.dart:82 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| C0074 | ruta/pantalla | app/lib/app/home/home_card_actions.dart:210 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| C0075 | ruta/pantalla | app/lib/app/home/home_card_actions.dart:364 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| C0076 | ruta/pantalla | app/lib/app/home/home_card_actions.dart:452 | app/lib/features/home/view/home_card_actions.dart | pendiente |
| C0077 | endpoint/cabecera/parámetro | app/lib/app/home/home_data.dart:271 | app/lib/features/home/view/home_data.dart | pendiente |
| C0078 | persistencia | app/lib/app/home/home_hero.dart:159 | app/lib/features/home/view/home_hero.dart | pendiente |
| C0079 | persistencia | app/lib/app/home/home_hero.dart:245 | app/lib/features/home/view/home_hero.dart | pendiente |
| C0080 | ruta/pantalla | app/lib/app/home/home_screen.dart:11 | app/lib/features/home/view/home_screen.dart | pendiente |
| C0081 | persistencia | app/lib/app/home/home_screen.dart:149 | app/lib/features/home/view/home_screen.dart | pendiente |
| C0082 | persistencia | app/lib/app/home/home_screen.dart:177 | app/lib/features/home/view/home_screen.dart | pendiente |
| C0083 | persistencia | app/lib/app/home/home_sections.dart:215 | app/lib/features/home/view/home_sections.dart | pendiente |
| C0084 | persistencia | app/lib/app/home/home_sections.dart:503 | app/lib/features/home/view/home_sections.dart | pendiente |
| C0085 | persistencia | app/lib/app/home/home_sections.dart:609 | app/lib/features/home/view/home_sections.dart | pendiente |
| C0086 | persistencia | app/lib/app/player/audio_track_selector.dart:37 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| C0087 | persistencia | app/lib/app/player/audio_track_selector.dart:44 | app/lib/features/player/view/audio_track_selector.dart | pendiente |
| C0088 | endpoint/cabecera/parámetro | app/lib/app/player/external_subtitle_search_panel.dart:54 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| C0089 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:128 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| C0090 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:140 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| C0091 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:151 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| C0092 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:162 | app/lib/features/player/view/external_subtitle_search_panel.dart | pendiente |
| C0093 | persistencia | app/lib/app/player/player_demo_panel.dart:54 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0094 | ruta/pantalla | app/lib/app/player/player_demo_panel.dart:70 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0095 | persistencia | app/lib/app/player/player_demo_panel.dart:75 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0096 | ruta/pantalla | app/lib/app/player/player_demo_panel.dart:82 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0097 | ruta/pantalla | app/lib/app/player/player_demo_panel.dart:89 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0098 | persistencia | app/lib/app/player/player_demo_panel.dart:109 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0099 | persistencia | app/lib/app/player/player_demo_panel.dart:117 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0100 | persistencia | app/lib/app/player/player_demo_panel.dart:125 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0101 | persistencia | app/lib/app/player/player_demo_panel.dart:133 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0102 | persistencia | app/lib/app/player/player_demo_panel.dart:147 | app/lib/features/player/view/player_demo_panel.dart | pendiente |
| C0103 | persistencia | app/lib/app/player/player_nerd_panel.dart:23 | app/lib/features/player/view/player_nerd_panel.dart | pendiente |
| C0104 | persistencia | app/lib/app/player/player_quality_panel.dart:28 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| C0105 | persistencia | app/lib/app/player/player_quality_panel.dart:40 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| C0106 | persistencia | app/lib/app/player/player_quality_panel.dart:54 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| C0107 | persistencia | app/lib/app/player/player_quality_panel.dart:61 | app/lib/features/player/view/player_quality_panel.dart | pendiente |
| C0108 | persistencia | app/lib/app/player/player_subtitle_panel.dart:14 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0109 | persistencia | app/lib/app/player/player_subtitle_panel.dart:23 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0110 | persistencia | app/lib/app/player/player_subtitle_panel.dart:29 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0111 | persistencia | app/lib/app/player/player_subtitle_panel.dart:37 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0112 | persistencia | app/lib/app/player/player_subtitle_panel.dart:38 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0113 | persistencia | app/lib/app/player/player_subtitle_panel.dart:39 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0114 | persistencia | app/lib/app/player/player_subtitle_panel.dart:40 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0115 | ruta/pantalla | app/lib/app/player/player_subtitle_panel.dart:83 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0116 | persistencia | app/lib/app/player/player_subtitle_panel.dart:137 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0117 | persistencia | app/lib/app/player/player_subtitle_panel.dart:165 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0118 | persistencia | app/lib/app/player/player_subtitle_panel.dart:182 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0119 | persistencia | app/lib/app/player/player_subtitle_panel.dart:197 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0120 | persistencia | app/lib/app/player/player_subtitle_panel.dart:219 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0121 | persistencia | app/lib/app/player/player_subtitle_panel.dart:238 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0122 | persistencia | app/lib/app/player/player_subtitle_panel.dart:261 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0123 | persistencia | app/lib/app/player/player_subtitle_panel.dart:280 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0124 | persistencia | app/lib/app/player/player_subtitle_panel.dart:287 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0125 | persistencia | app/lib/app/player/player_subtitle_panel.dart:295 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0126 | persistencia | app/lib/app/player/player_subtitle_panel.dart:302 | app/lib/features/player/view/player_subtitle_panel.dart | pendiente |
| C0127 | persistencia | app/lib/app/player/player_video_display_panel.dart:15 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| C0128 | persistencia | app/lib/app/player/player_video_display_panel.dart:40 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| C0129 | persistencia | app/lib/app/player/player_video_display_panel.dart:56 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| C0130 | ruta/pantalla | app/lib/app/player/player_video_display_panel.dart:86 | app/lib/features/player/view/player_video_display_panel.dart | pendiente |
| C0131 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:21 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| C0132 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:118 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| C0133 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:132 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| C0134 | endpoint/cabecera/parámetro | app/lib/app/player/provider_playback_route.dart:178 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| C0135 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:212 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| C0136 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:269 | app/lib/features/player/view/provider_playback_route.dart | pendiente |
| C0137 | persistencia | app/lib/app/player/skip_segment_panel.dart:43 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| C0138 | persistencia | app/lib/app/player/skip_segment_panel.dart:59 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| C0139 | persistencia | app/lib/app/player/skip_segment_panel.dart:69 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| C0140 | persistencia | app/lib/app/player/skip_segment_panel.dart:74 | app/lib/features/player/view/skip_segment_panel.dart | pendiente |
| C0141 | persistencia | app/lib/app/player/source_switch_panel.dart:40 | app/lib/features/player/view/source_switch_panel.dart | pendiente |
| C0142 | persistencia | app/lib/app/player/source_switch_panel.dart:57 | app/lib/features/player/view/source_switch_panel.dart | pendiente |
| C0143 | persistencia | app/lib/app/player/source_switch_panel.dart:66 | app/lib/features/player/view/source_switch_panel.dart | pendiente |
| C0144 | configuración | app/lib/app/player/spike_player_module.dart:266 | app/lib/features/player/view/spike_player_module.dart | pendiente |
| C0145 | ruta/pantalla | app/lib/app/player/spike_player_page.dart:30 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0146 | ruta/pantalla | app/lib/app/player/spike_player_page.dart:424 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0147 | persistencia | app/lib/app/player/spike_player_page.dart:438 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0148 | endpoint/cabecera/parámetro | app/lib/app/player/spike_player_page.dart:467 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0149 | endpoint/cabecera/parámetro | app/lib/app/player/spike_player_page.dart:485 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0150 | persistencia | app/lib/app/player/spike_player_page.dart:592 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0151 | persistencia | app/lib/app/player/spike_player_page.dart:602 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0152 | persistencia | app/lib/app/player/spike_player_page.dart:621 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0153 | persistencia | app/lib/app/player/spike_player_page.dart:631 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0154 | persistencia | app/lib/app/player/spike_player_page.dart:639 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0155 | persistencia | app/lib/app/player/spike_player_page.dart:732 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0156 | persistencia | app/lib/app/player/spike_player_page.dart:738 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0157 | persistencia | app/lib/app/player/spike_player_page.dart:751 | app/lib/features/player/view/spike_player_page.dart | pendiente |
| C0158 | endpoint/cabecera/parámetro | app/lib/application/catalog/catalog_service.dart:189 | app/lib/application/catalog/catalog_service.dart | pendiente |
| C0159 | persistencia | app/lib/application/catalog/catalog_service.dart:281 | app/lib/application/catalog/catalog_service.dart | pendiente |
| C0160 | persistencia | app/lib/application/catalog/catalog_service.dart:303 | app/lib/application/catalog/catalog_service.dart | pendiente |
| C0161 | persistencia | app/lib/application/player/playback_progress_session.dart:78 | app/lib/features/player/view_model/playback_progress_session.dart | pendiente |
| C0162 | endpoint/cabecera/parámetro | app/lib/application/player/player_demo_session.dart:25 | app/lib/features/player/view_model/player_demo_session.dart | pendiente |
| C0163 | persistencia | app/lib/application/player/providers/playback_provider_manager.dart:261 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| C0164 | persistencia | app/lib/application/player/providers/playback_provider_manager.dart:575 | app/lib/features/player/view_model/providers/playback_provider_manager.dart | pendiente |
| C0165 | persistencia | app/lib/application/player/skips/automatic_skip_controller.dart:96 | app/lib/features/player/view_model/skips/automatic_skip_controller.dart | pendiente |
| C0166 | persistencia | app/lib/core/logger/safe_logger.dart:106 | app/lib/core/logger/safe_logger.dart | pendiente |
| C0167 | persistencia | app/lib/core/logger/safe_logger.dart:121 | app/lib/core/logger/safe_logger.dart | pendiente |
| C0168 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:14 | app/lib/data/services/anilist/README.md | pendiente |
| C0169 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:39 | app/lib/data/services/anilist/README.md | pendiente |
| C0170 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:40 | app/lib/data/services/anilist/README.md | pendiente |
| C0171 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:43 | app/lib/data/services/anilist/README.md | pendiente |
| C0172 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:12 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0173 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:139 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0174 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:149 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0175 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:178 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0176 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:192 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0177 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:221 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0178 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:239 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0179 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:260 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0180 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:272 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0181 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:303 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0182 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:499 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0183 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:500 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0184 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:550 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0185 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:551 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0186 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:562 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0187 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:568 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0188 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:570 | app/lib/data/services/anilist/anilist_client.dart | pendiente |
| C0189 | persistencia | app/lib/data/anilist/drift_anilist_browse_cache.dart:18 | app/lib/data/services/anilist/drift_anilist_browse_cache.dart | pendiente |
| C0190 | endpoint/cabecera/parámetro | app/lib/data/aniskip/README.md:3 | app/lib/data/aniskip/README.md | pendiente |
| C0191 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_client.dart:26 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| C0192 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_client.dart:41 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| C0193 | persistencia | app/lib/data/aniskip/aniskip_client.dart:49 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| C0194 | persistencia | app/lib/data/aniskip/aniskip_client.dart:57 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| C0195 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_client.dart:100 | app/lib/data/aniskip/aniskip_client.dart | pendiente |
| C0196 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_response_cache.dart:77 | app/lib/data/aniskip/aniskip_response_cache.dart | pendiente |
| C0197 | endpoint/cabecera/parámetro | app/lib/data/kitsu/README.md:12 | app/lib/data/services/kitsu/README.md | pendiente |
| C0198 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:23 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| C0199 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:26 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| C0200 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:68 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| C0201 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:95 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| C0202 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:176 | app/lib/data/services/kitsu/kitsu_episode_index.dart | pendiente |
| C0203 | persistencia | app/lib/data/local_db/app_database.dart:40 | app/lib/data/local_db/app_database.dart | pendiente |
| C0204 | persistencia | app/lib/data/local_db/app_database.dart:43 | app/lib/data/local_db/app_database.dart | pendiente |
| C0205 | persistencia | app/lib/data/local_db/app_database.dart:44 | app/lib/data/local_db/app_database.dart | pendiente |
| C0206 | persistencia | app/lib/data/local_db/app_database.dart:51 | app/lib/data/local_db/app_database.dart | pendiente |
| C0207 | persistencia | app/lib/data/local_db/app_database.dart:52 | app/lib/data/local_db/app_database.dart | pendiente |
| C0208 | persistencia | app/lib/data/local_db/app_database.dart:90 | app/lib/data/local_db/app_database.dart | pendiente |
| C0209 | persistencia | app/lib/data/local_db/app_database.dart:91 | app/lib/data/local_db/app_database.dart | pendiente |
| C0210 | persistencia | app/lib/data/local_db/drift_playback_progress_repository.dart:59 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| C0211 | persistencia | app/lib/data/local_db/drift_playback_progress_repository.dart:95 | app/lib/data/local_db/drift_playback_progress_repository.dart | pendiente |
| C0212 | persistencia | app/lib/data/local_db/tables/anime_identity_entries.dart:5 | app/lib/data/local_db/tables/anime_identity_entries.dart | pendiente |
| C0213 | persistencia | app/lib/data/local_db/tables/anime_identity_entries.dart:7 | app/lib/data/local_db/tables/anime_identity_entries.dart | pendiente |
| C0214 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:9 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| C0215 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:18 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| C0216 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:26 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| C0217 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:28 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| C0218 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:30 | app/lib/data/local_db/tables/anime_identity_relationships.dart | pendiente |
| C0219 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:8 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| C0220 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:10 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| C0221 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:12 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| C0222 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:20 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| C0223 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:22 | app/lib/data/local_db/tables/external_anime_identifiers.dart | pendiente |
| C0224 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:5 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| C0225 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:7 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| C0226 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:9 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| C0227 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:11 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| C0228 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:13 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| C0229 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:15 | app/lib/data/local_db/tables/latest_anime_search.dart | pendiente |
| C0230 | persistencia | app/lib/data/local_db/tables/library_entries.dart:8 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| C0231 | persistencia | app/lib/data/local_db/tables/library_entries.dart:16 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| C0232 | persistencia | app/lib/data/local_db/tables/library_entries.dart:18 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| C0233 | persistencia | app/lib/data/local_db/tables/library_entries.dart:25 | app/lib/data/local_db/tables/library_entries.dart | pendiente |
| C0234 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:4 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| C0235 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:5 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| C0236 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:6 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| C0237 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:7 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| C0238 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:8 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| C0239 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:9 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| C0240 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:10 | app/lib/data/local_db/tables/playback_progress_entries.dart | pendiente |
| C0241 | persistencia | app/lib/data/local_db/tables/progress_documents.dart:5 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| C0242 | persistencia | app/lib/data/local_db/tables/progress_documents.dart:7 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| C0243 | persistencia | app/lib/data/local_db/tables/progress_documents.dart:9 | app/lib/data/local_db/tables/progress_documents.dart | pendiente |
| C0244 | persistencia | app/lib/data/local_db/tables/settings_entries.dart:5 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| C0245 | persistencia | app/lib/data/local_db/tables/settings_entries.dart:7 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| C0246 | persistencia | app/lib/data/local_db/tables/settings_entries.dart:9 | app/lib/data/local_db/tables/settings_entries.dart | pendiente |
| C0247 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:31 | app/lib/data/opensubtitles/README.md | pendiente |
| C0248 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:44 | app/lib/data/opensubtitles/README.md | pendiente |
| C0249 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:48 | app/lib/data/opensubtitles/README.md | pendiente |
| C0250 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:58 | app/lib/data/opensubtitles/README.md | pendiente |
| C0251 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:112 | app/lib/data/opensubtitles/README.md | pendiente |
| C0252 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:130 | app/lib/data/opensubtitles/README.md | pendiente |
| C0253 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:133 | app/lib/data/opensubtitles/README.md | pendiente |
| C0254 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:16 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0255 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:47 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0256 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:78 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0257 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:82 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0258 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:124 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0259 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:129 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0260 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:136 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0261 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:190 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0262 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:194 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0263 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:202 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0264 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:207 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0265 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:325 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0266 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:346 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0267 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:436 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0268 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:442 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0269 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:445 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0270 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:447 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0271 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:450 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0272 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:452 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0273 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:461 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0274 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:543 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0275 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:580 | app/lib/data/opensubtitles/opensubtitles_client.dart | pendiente |
| C0276 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:30 | app/lib/data/services/player/README.md | pendiente |
| C0277 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:210 | app/lib/data/services/player/README.md | pendiente |
| C0278 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:213 | app/lib/data/services/player/README.md | pendiente |
| C0279 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:300 | app/lib/data/services/player/README.md | pendiente |
| C0280 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:303 | app/lib/data/services/player/README.md | pendiente |
| C0281 | configuración | app/lib/data/player/engine/media_codec_support_linux.dart:37 | app/lib/data/services/player/media_codec_support_linux.dart | pendiente |
| C0282 | persistencia | app/lib/data/player/engine/media_kit_spike_engine.dart:184 | app/lib/data/services/player/media_kit_spike_engine.dart | pendiente |
| C0283 | endpoint/cabecera/parámetro | app/lib/data/player/providers/README.md:69 | app/lib/sources/README.md | pendiente |
| C0284 | endpoint/cabecera/parámetro | app/lib/data/player/providers/README.md:121 | app/lib/sources/README.md | pendiente |
| C0285 | endpoint/cabecera/parámetro | app/lib/data/player/providers/README.md:122 | app/lib/sources/README.md | pendiente |
| C0286 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:30 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0287 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:36 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0288 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:78 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0289 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:123 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0290 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:124 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0291 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:130 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0292 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:131 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0293 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:241 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0294 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:375 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0295 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:393 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0296 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:400 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0297 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:401 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0298 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:402 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0299 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:438 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0300 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:442 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0301 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:478 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0302 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:484 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0303 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:485 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0304 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:486 | app/lib/sources/allanime/allanime_playback_provider.dart | pendiente |
| C0305 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/README.md:6 | app/lib/sources/animeav1/README.md | pendiente |
| C0306 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/README.md:7 | app/lib/sources/animeav1/README.md | pendiente |
| C0307 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:18 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| C0308 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:77 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| C0309 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:82 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| C0310 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:83 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| C0311 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:321 | app/lib/sources/animeav1/animeav1_playback_provider.dart | pendiente |
| C0312 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:26 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0313 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:81 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0314 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:86 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0315 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:87 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0316 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:122 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0317 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:200 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0318 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:214 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0319 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:271 | app/lib/sources/animegg/animegg_playback_provider.dart | pendiente |
| C0320 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:23 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0321 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:41 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0322 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:50 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0323 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:54 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0324 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:96 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0325 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:168 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0326 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:169 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0327 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:214 | app/lib/sources/anizone/anizone_playback_provider.dart | pendiente |
| C0328 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:25 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| C0329 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:67 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| C0330 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:71 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| C0331 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:89 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| C0332 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:105 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| C0333 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:110 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| C0334 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:143 | app/lib/sources/hosts/voe_video_host_resolver.dart | pendiente |
| C0335 | endpoint/cabecera/parámetro | app/lib/data/player/providers/html_playback_parsers.dart:91 | app/lib/sources/html_playback_parsers.dart | pendiente |
| C0336 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:230 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| C0337 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:364 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| C0338 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:370 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| C0339 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:378 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| C0340 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:379 | app/lib/sources/jkanime/jkanime_playback_provider.dart | pendiente |
| C0341 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/README.md:33 | app/lib/sources/megaplay/README.md | pendiente |
| C0342 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:36 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0343 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:240 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0344 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:244 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0345 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:268 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0346 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:283 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0347 | persistencia | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:329 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0348 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:405 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0349 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:406 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0350 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:407 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0351 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:408 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0352 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:415 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0353 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:417 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0354 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:418 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0355 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:468 | app/lib/sources/megaplay/megaplay_playback_provider.dart | pendiente |
| C0356 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:12 | app/lib/sources/miruro/README.md | pendiente |
| C0357 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:18 | app/lib/sources/miruro/README.md | pendiente |
| C0358 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:31 | app/lib/sources/miruro/README.md | pendiente |
| C0359 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:36 | app/lib/sources/miruro/README.md | pendiente |
| C0360 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:42 | app/lib/sources/miruro/README.md | pendiente |
| C0361 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:61 | app/lib/sources/miruro/README.md | pendiente |
| C0362 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:63 | app/lib/sources/miruro/README.md | pendiente |
| C0363 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:82 | app/lib/sources/miruro/README.md | pendiente |
| C0364 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:84 | app/lib/sources/miruro/README.md | pendiente |
| C0365 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:85 | app/lib/sources/miruro/README.md | pendiente |
| C0366 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:86 | app/lib/sources/miruro/README.md | pendiente |
| C0367 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:87 | app/lib/sources/miruro/README.md | pendiente |
| C0368 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:165 | app/lib/sources/miruro/README.md | pendiente |
| C0369 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:17 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0370 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:60 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0371 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:68 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0372 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:72 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0373 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:73 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0374 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:116 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0375 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:124 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0376 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:139 | app/lib/sources/miruro/miruro_catalog_api.dart | pendiente |
| C0377 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:83 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0378 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:180 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0379 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:193 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0380 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:194 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0381 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:216 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0382 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:294 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0383 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:311 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0384 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:320 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0385 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:321 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0386 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:322 | app/lib/sources/miruro/miruro_catalog_parser.dart | pendiente |
| C0387 | configuración | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:94 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| C0388 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:194 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| C0389 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:266 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| C0390 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:323 | app/lib/sources/miruro/miruro_catalog_playback_provider.dart | pendiente |
| C0391 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:12 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0392 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:17 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0393 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:25 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0394 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:34 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0395 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:60 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0396 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:71 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0397 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:144 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0398 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:157 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0399 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:183 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0400 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:184 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0401 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:217 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0402 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:218 | app/lib/sources/miruro/miruro_http2_client.dart | pendiente |
| C0403 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:11 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0404 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:45 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0405 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:46 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0406 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:49 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0407 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:51 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0408 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:102 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0409 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:103 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0410 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:104 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0411 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:105 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0412 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:106 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0413 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:107 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0414 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:112 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0415 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:126 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0416 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:127 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0417 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:131 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0418 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:133 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0419 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:150 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0420 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:175 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0421 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:216 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0422 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:222 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0423 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:226 | app/lib/sources/miruro/miruro_media_proxy.dart | pendiente |
| C0424 | endpoint/cabecera/parámetro | app/lib/data/player/providers/mock/mock_playback_provider.dart:232 | app/lib/sources/mock/mock_playback_provider.dart | pendiente |
| C0425 | persistencia | app/lib/data/player/providers/public_episode_provider.dart:35 | app/lib/sources/public_episode_provider.dart | pendiente |
| C0426 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:24 | app/lib/sources/public_playback_http.dart | pendiente |
| C0427 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:31 | app/lib/sources/public_playback_http.dart | pendiente |
| C0428 | persistencia | app/lib/data/player/providers/public_playback_http.dart:38 | app/lib/sources/public_playback_http.dart | pendiente |
| C0429 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:70 | app/lib/sources/public_playback_http.dart | pendiente |
| C0430 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:77 | app/lib/sources/public_playback_http.dart | pendiente |
| C0431 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:80 | app/lib/sources/public_playback_http.dart | pendiente |
| C0432 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:92 | app/lib/sources/public_playback_http.dart | pendiente |
| C0433 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:102 | app/lib/sources/public_playback_http.dart | pendiente |
| C0434 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:105 | app/lib/sources/public_playback_http.dart | pendiente |
| C0435 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:117 | app/lib/sources/public_playback_http.dart | pendiente |
| C0436 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:123 | app/lib/sources/public_playback_http.dart | pendiente |
| C0437 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:126 | app/lib/sources/public_playback_http.dart | pendiente |
| C0438 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:129 | app/lib/sources/public_playback_http.dart | pendiente |
| C0439 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:135 | app/lib/sources/public_playback_http.dart | pendiente |
| C0440 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:142 | app/lib/sources/public_playback_http.dart | pendiente |
| C0441 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:151 | app/lib/sources/public_playback_http.dart | pendiente |
| C0442 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:216 | app/lib/sources/public_playback_http.dart | pendiente |
| C0443 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:222 | app/lib/sources/public_playback_http.dart | pendiente |
| C0444 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:228 | app/lib/sources/public_playback_http.dart | pendiente |
| C0445 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:230 | app/lib/sources/public_playback_http.dart | pendiente |
| C0446 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:236 | app/lib/sources/public_playback_http.dart | pendiente |
| C0447 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:240 | app/lib/sources/public_playback_http.dart | pendiente |
| C0448 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:258 | app/lib/sources/public_playback_http.dart | pendiente |
| C0449 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:264 | app/lib/sources/public_playback_http.dart | pendiente |
| C0450 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:277 | app/lib/sources/public_playback_http.dart | pendiente |
| C0451 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:281 | app/lib/sources/public_playback_http.dart | pendiente |
| C0452 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:387 | app/lib/sources/public_playback_http.dart | pendiente |
| C0453 | persistencia | app/lib/data/player/providers/registry/provider_spec.dart:70 | app/lib/sources/registry/provider_spec.dart | pendiente |
| C0454 | endpoint/cabecera/parámetro | app/lib/data/player/providers/user_sources/README.md:13 | app/lib/sources/user_sources/README.md | pendiente |
| C0455 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:14 | app/lib/sources/wikimedia/README.md | pendiente |
| C0456 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:15 | app/lib/sources/wikimedia/README.md | pendiente |
| C0457 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:16 | app/lib/sources/wikimedia/README.md | pendiente |
| C0458 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:17 | app/lib/sources/wikimedia/README.md | pendiente |
| C0459 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:97 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| C0460 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:151 | app/lib/sources/wikimedia/wikimedia_anime_provider.dart | pendiente |
| C0461 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/wikimedia_identity.dart:3 | app/lib/sources/wikimedia/wikimedia_identity.dart | pendiente |
| C0462 | persistencia | app/lib/data/secure_storage/README.md:1 | app/lib/data/secure_storage/README.md | pendiente |
| C0463 | persistencia | app/lib/data/secure_storage/README.md:7 | app/lib/data/secure_storage/README.md | pendiente |
| C0464 | persistencia | app/lib/data/secure_storage/README.md:19 | app/lib/data/secure_storage/README.md | pendiente |
| C0465 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:3 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| C0466 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:22 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| C0467 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:34 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| C0468 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:44 | app/lib/data/secure_storage/flutter_secure_credential_store.dart | pendiente |
| C0469 | persistencia | app/lib/data/secure_storage/flutter_secure_storage_api.dart:12 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| C0470 | persistencia | app/lib/data/secure_storage/flutter_secure_storage_api.dart:16 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| C0471 | persistencia | app/lib/data/secure_storage/flutter_secure_storage_api.dart:19 | app/lib/data/secure_storage/flutter_secure_storage_api.dart | pendiente |
| C0472 | persistencia | app/lib/data/secure_storage/secure_storage_api.dart:4 | app/lib/data/secure_storage/secure_storage_api.dart | pendiente |
| C0473 | persistencia | app/lib/domain/README.md:20 | app/lib/domain/README.md | pendiente |
| C0474 | persistencia | app/lib/domain/auth/README.md:8 | app/lib/domain/auth/README.md | pendiente |
| C0475 | persistencia | app/lib/domain/auth/secure_credential_store.dart:6 | app/lib/domain/auth/secure_credential_store.dart | pendiente |
| C0476 | ruta/pantalla | app/lib/domain/catalog/episode_index_provider.dart:9 | app/lib/domain/catalog/episode_index_provider.dart | pendiente |
| C0477 | persistencia | app/lib/domain/catalog/provider_result.dart:5 | app/lib/domain/catalog/provider_result.dart | pendiente |
| C0478 | persistencia | app/lib/domain/catalog/provider_result.dart:46 | app/lib/domain/catalog/provider_result.dart | pendiente |
| C0479 | persistencia | app/lib/domain/player/providers/anime_identity.dart:30 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| C0480 | persistencia | app/lib/domain/player/providers/anime_identity.dart:31 | app/lib/domain/player/providers/anime_identity.dart | pendiente |
| C0481 | persistencia | app/lib/domain/player/providers/episode_source.dart:84 | app/lib/domain/player/providers/episode_source.dart | pendiente |
| C0482 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:295 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0483 | persistencia | app/lib/domain/player/providers/playback_source.dart:295 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0484 | persistencia | app/lib/domain/player/providers/playback_source.dart:296 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0485 | persistencia | app/lib/domain/player/providers/playback_source.dart:297 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0486 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:298 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0487 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:304 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0488 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:305 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0489 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:306 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0490 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:307 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0491 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:319 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0492 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:326 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0493 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:365 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0494 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:368 | app/lib/domain/player/providers/playback_source.dart | pendiente |
| C0495 | persistencia | app/lib/domain/progress/checkpoint_coordinator.dart:54 | app/lib/domain/progress/checkpoint_coordinator.dart | pendiente |
| C0496 | persistencia | app/lib/domain/progress/content_identity.dart:24 | app/lib/domain/progress/content_identity.dart | pendiente |
| C0497 | configuración | app/lib/main.dart:29 | app/lib/main.dart | pendiente |
| C0498 | configuración | app/lib/main.dart:37 | app/lib/main.dart | pendiente |
| C0499 | configuración | app/lib/main.dart:38 | app/lib/main.dart | pendiente |
| C0500 | configuración | app/lib/main.dart:39 | app/lib/main.dart | pendiente |
| C0501 | configuración | app/lib/main.dart:40 | app/lib/main.dart | pendiente |
| C0502 | configuración | app/lib/main.dart:41 | app/lib/main.dart | pendiente |
| C0503 | configuración | app/lib/main.dart:42 | app/lib/main.dart | pendiente |
| C0504 | configuración | app/lib/main.dart:61 | app/lib/main.dart | pendiente |
| C0505 | endpoint/cabecera/parámetro | app/lib/main.dart:109 | app/lib/main.dart | pendiente |
| C0506 | configuración | app/lib/main.dart:131 | app/lib/main.dart | pendiente |
| C0507 | configuración | app/lib/main.dart:150 | app/lib/main.dart | pendiente |
| C0508 | configuración | app/lib/main.dart.bak:21 | app/lib/main.dart.bak | pendiente |
| C0509 | configuración | app/lib/main.dart.bak:22 | app/lib/main.dart.bak | pendiente |
| C0510 | configuración | app/lib/main.dart.bak:30 | app/lib/main.dart.bak | pendiente |
| C0511 | configuración | app/lib/main.dart.bak:31 | app/lib/main.dart.bak | pendiente |
| C0512 | configuración | app/lib/main.dart.bak:32 | app/lib/main.dart.bak | pendiente |
| C0513 | configuración | app/lib/main.dart.bak:33 | app/lib/main.dart.bak | pendiente |
| C0514 | configuración | app/lib/main.dart.bak:34 | app/lib/main.dart.bak | pendiente |
| C0515 | configuración | app/lib/main.dart.bak:35 | app/lib/main.dart.bak | pendiente |
| C0516 | configuración | app/lib/main.dart.bak:44 | app/lib/main.dart.bak | pendiente |
| C0517 | configuración | app/lib/main.dart.bak:64 | app/lib/main.dart.bak | pendiente |
| C0518 | configuración | app/lib/main.dart.bak:83 | app/lib/main.dart.bak | pendiente |
| C0519 | configuración | app/lib/main_player_spike.dart:18 | app/lib/main_player_spike.dart | pendiente |
| C0520 | configuración | app/lib/main_player_spike.dart:23 | app/lib/main_player_spike.dart | pendiente |
| C0521 | configuración | app/lib/main_player_spike.dart:36 | app/lib/main_player_spike.dart | pendiente |
| C0522 | configuración | app/lib/main_player_spike.dart:37 | app/lib/main_player_spike.dart | pendiente |
| C0523 | configuración | app/lib/main_player_spike.dart:38 | app/lib/main_player_spike.dart | pendiente |
| C0524 | configuración | app/lib/main_player_spike.dart:74 | app/lib/main_player_spike.dart | pendiente |
| C0525 | configuración | app/lib/main_player_spike.dart:90 | app/lib/main_player_spike.dart | pendiente |
| C0526 | configuración | app/lib/main_player_spike.dart:93 | app/lib/main_player_spike.dart | pendiente |
| C0527 | configuración | app/lib/main_player_spike.dart:119 | app/lib/main_player_spike.dart | pendiente |
| C0528 | endpoint/cabecera/parámetro | app/lib/main_player_spike.dart:242 | app/lib/main_player_spike.dart | pendiente |
| C0529 | persistencia | app/lib/settings/registry/README.md:4 | app/lib/settings/registry/README.md | pendiente |
| C0530 | persistencia | app/lib/settings/registry/setting_definition.dart:8 | app/lib/settings/registry/setting_definition.dart | pendiente |
| C0531 | persistencia | app/lib/settings/registry/setting_definition.dart:9 | app/lib/settings/registry/setting_definition.dart | pendiente |
| C0532 | persistencia | app/lib/settings/registry/settings_registry.dart:10 | app/lib/settings/registry/settings_registry.dart | pendiente |
| C0533 | persistencia | app/lib/settings/registry/settings_registry.dart:17 | app/lib/settings/registry/settings_registry.dart | pendiente |
| C0534 | persistencia | app/lib/settings/registry/settings_registry.dart:19 | app/lib/settings/registry/settings_registry.dart | pendiente |
| C0535 | persistencia | app/lib/settings/store/settings_store.dart:19 | app/lib/settings/store/settings_store.dart | pendiente |
| C0536 | persistencia | app/lib/settings/store/settings_store.dart:20 | app/lib/settings/store/settings_store.dart | pendiente |
| C0537 | persistencia | app/lib/settings/store/settings_store.dart:21 | app/lib/settings/store/settings_store.dart | pendiente |
| C0538 | persistencia | app/lib/settings/store/settings_store.dart:39 | app/lib/settings/store/settings_store.dart | pendiente |
| C0539 | persistencia | app/lib/settings/store/settings_store.dart:40 | app/lib/settings/store/settings_store.dart | pendiente |
| C0540 | persistencia | app/lib/settings/store/settings_store.dart:41 | app/lib/settings/store/settings_store.dart | pendiente |
| C0541 | persistencia | app/lib/settings/store/settings_store.dart:66 | app/lib/settings/store/settings_store.dart | pendiente |
| C0542 | persistencia | app/lib/settings/store/settings_store.dart:67 | app/lib/settings/store/settings_store.dart | pendiente |
| C0543 | persistencia | app/lib/settings/store/settings_store.dart:68 | app/lib/settings/store/settings_store.dart | pendiente |
| C0544 | persistencia | app/lib/settings/store/settings_store.dart:76 | app/lib/settings/store/settings_store.dart | pendiente |

## Cierre para retomar sin releer el repositorio

Hecho: respaldo de producto previo en GitHub y etiqueta, baseline por carpeta,
clasificación de análisis, inventario y mapa individual, auditoría, zona protegida,
investigación y golden offline sin cambiar lib/manifiestos/assets.
Pendiente: corregir errores previos mediante tarea autorizada distinta; completar
caracterización de módulos sin golden; resolver timeouts y validar UI/native.
Decisiones del propietario: sección 6. Fase 0 documental quedó comprometida; paridad total sigue incompleta. F1.1
registrada abajo. No avanzar a F2 sin instrucción del propietario.
