# Auditoría Fase 0 — 2026-11-20

Alcance: código actual sin correcciones. Procedimiento kongroo-deep-audit,
segunda pasada propia, no independiente; sin agentes ni prueba gráfica.
La baseline no compila completa: no se recomienda aceptación técnica ni movimiento.
P1 equivale aquí a severidad alta, P2 media, P3 baja; no se afirma P0.
La fase documental no cierra las fases históricas del reproductor.

| ID | Archivo:líneas | Tipo | Severidad | Riesgo al tocar | Estado | Hallazgo | Propuesta |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A001 | app/lib/app/catalog/anime_detail_page.dart:1-428 | archivo >250 | media | medio | confirmado por lectura | 428 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A002 | app/lib/app/catalog/catalog_home_page.dart:1-693 | archivo >250 | media | medio | confirmado por lectura | 693 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A003 | app/lib/app/catalog/detail/anime_detail_header.dart:1-643 | archivo >250 | media | medio | confirmado por lectura | 643 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A004 | app/lib/app/catalog/detail/anime_detail_tab_content.dart:1-823 | archivo >250 | media | medio | confirmado por lectura | 823 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A005 | app/lib/app/home/home_card_actions.dart:1-500 | archivo >250 | media | medio | confirmado por lectura | 500 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A006 | app/lib/app/home/home_data.dart:1-285 | archivo >250 | media | medio | confirmado por lectura | 285 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A007 | app/lib/app/home/home_hero.dart:1-395 | archivo >250 | media | medio | confirmado por lectura | 395 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A008 | app/lib/app/home/home_sections.dart:1-630 | archivo >250 | media | medio | confirmado por lectura | 630 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A009 | app/lib/app/player/player_subtitle_panel.dart:1-311 | archivo >250 | media | medio | confirmado por lectura | 311 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A010 | app/lib/app/player/provider_playback_route.dart:1-298 | archivo >250 | media | medio | confirmado por lectura | 298 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A011 | app/lib/app/player/spike_player_module.dart:1-410 | archivo >250 | media | medio | confirmado por lectura | 410 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A012 | app/lib/app/player/spike_player_page.dart:1-825 | archivo >250 | media | medio | confirmado por lectura | 825 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A013 | app/lib/application/catalog/catalog_service.dart:1-310 | archivo >250 | media | medio | confirmado por lectura | 310 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A014 | app/lib/application/player/providers/playback_provider_manager.dart:1-894 | archivo >250 | media | alto | confirmado por lectura | 894 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A015 | app/lib/application/player/source_switching/playback_source_switch_service.dart:1-353 | archivo >250 | media | medio | confirmado por lectura | 353 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A016 | app/lib/application/player/spike_player_coordinator.dart:1-1086 | archivo >250 | media | medio | confirmado por lectura | 1086 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A017 | app/lib/data/anilist/anilist_client.dart:1-577 | archivo >250 | media | medio | confirmado por lectura | 577 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A018 | app/lib/data/anilist/offline_first_anime_catalog.dart:1-427 | archivo >250 | media | medio | confirmado por lectura | 427 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A019 | app/lib/data/local_db/app_database.g.dart:1-5462 | archivo >250 | baja | alto | confirmado por lectura | 5462 líneas; generado, no dividir a mano | Conservar generado |
| A020 | app/lib/data/local_db/drift_anime_identity_repository.dart:1-275 | archivo >250 | media | medio | confirmado por lectura | 275 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A021 | app/lib/data/opensubtitles/opensubtitles_client.dart:1-623 | archivo >250 | media | medio | confirmado por lectura | 623 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A022 | app/lib/data/player/engine/media_kit_spike_engine.dart:1-985 | archivo >250 | media | medio | confirmado por lectura | 985 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A023 | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:1-652 | archivo >250 | media | alto | confirmado por lectura | 652 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A024 | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:1-421 | archivo >250 | media | alto | confirmado por lectura | 421 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A025 | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:1-349 | archivo >250 | media | alto | confirmado por lectura | 349 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A026 | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:1-275 | archivo >250 | media | alto | confirmado por lectura | 275 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A027 | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:1-264 | archivo >250 | media | alto | confirmado por lectura | 264 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A028 | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:1-442 | archivo >250 | media | alto | confirmado por lectura | 442 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A029 | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:1-478 | archivo >250 | media | alto | confirmado por lectura | 478 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A030 | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:1-450 | archivo >250 | media | alto | confirmado por lectura | 450 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A031 | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:1-405 | archivo >250 | media | alto | confirmado por lectura | 405 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A032 | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:1-256 | archivo >250 | media | alto | confirmado por lectura | 256 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A033 | app/lib/data/player/providers/public_playback_http.dart:1-480 | archivo >250 | media | alto | confirmado por lectura | 480 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A034 | app/lib/domain/player/providers/playback_provider_contract.dart:1-385 | archivo >250 | media | alto | confirmado por lectura | 385 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A035 | app/lib/domain/player/providers/playback_source.dart:1-458 | archivo >250 | media | alto | confirmado por lectura | 458 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A036 | app/lib/main_player_spike.dart:1-255 | archivo >250 | media | medio | confirmado por lectura | 255 líneas | Dividir por responsabilidad en fase propia; fuentes solo mover. |
| A037 | app/lib/app/catalog/anime_detail_page.dart:42-428 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A038 | app/lib/app/catalog/catalog_home_page.dart:48-421 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A039 | app/lib/app/catalog/detail/anime_detail_header.dart:295-444 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A040 | app/lib/app/catalog/detail/anime_detail_tab_content.dart:117-314 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A041 | app/lib/app/home/home_hero.dart:30-370 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A042 | app/lib/app/home/home_screen.dart:32-198 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A043 | app/lib/app/home/home_sections.dart:328-584 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A044 | app/lib/app/player/external_subtitle_search_panel.dart:24-171 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A045 | app/lib/app/player/player_demo_panel.dart:22-150 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A046 | app/lib/app/player/player_subtitle_panel.dart:36-311 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A047 | app/lib/app/player/provider_playback_route.dart:54-298 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A048 | app/lib/app/player/spike_player_page.dart:60-780 | widget/State >120 | media | medio | confirmado por lectura | Clase UI excede 120 líneas; no equivale al tamaño de build(). | Extraer widgets const y estado local sin cambiar callbacks. |
| A049 | app/lib/application/player/providers/playback_provider_manager.dart:205-300 | contrato/sintaxis | alta | alto | confirmado por lectura | Manager no compila; diagnósticos de analyze y tests integrados. | Corrección funcional separada y autorizada antes de mover; no implementada. |
| A050 | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:60-80 | scraper inválido | alta | alto | confirmado por lectura | Regex/cadena y contratos presentan diagnósticos de análisis previos. | No modificar scraper; resolver bloqueo en tarea explícita y caracterizarlo. |
| A051 | app/lib/main.dart:33-36 | contrato bootstrap | alta | alto | confirmado por lectura | miruroProxy no existe en firma invocada. | Resolver contrato en tarea separada; no ocultar en refactor. |
| A052 | app/lib/app/catalog/catalog_home_page.dart:145-231 | negocio en widget | media | medio | confirmado por lectura | Widget coordina resolver, progreso, identidad y navegación. Guardas mounted presentes. | Extraer coordinación a view_model; conservar secuencia y cancelación. |
| A053 | app/lib/main.dart:103-124 | recurso/isolate/errores | alta | alto | confirmado por lectura | Isolate.spawn no esperado ni retenido; Future de probeHealth sin await, catch síncrono no observa su fallo asíncrono; sleep bloquea isolate. Riesgo de lifecycle, no medido. | Fase funcional separada: owner/cancelación y tests negativos; no implementarla aquí. |
| A054 | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:160-190 | parseo hilo UI | media | alto | riesgo no medido | XOR y gzip síncronos; no hay medición del coste en UI. | Perf posterior: medir; solo envolver sin cambiar parser si resulta costoso. |
| A055 | app/lib/main.dart:20-22 | constantes/caché | baja | medio | confirmado por lectura | Límite existente 120 imágenes / 48 MiB; ya hay ajuste de memoria. | Conservar default; no volver a recortarlo sin medir. |
| A056 | app/lib/main.dart:87-101 | código aparentemente muerto | baja | alto | confirmado por lectura | probeLoop local no invocado; analyzer unused_element. | Listar para decisión del propietario, nunca borrar ni mover a legacy por inferencia. |
| A057 | app/lib/main.dart:136-136 | errores/logs | baja | medio | confirmado por lectura | stderr.writeln fuera del logger estructurado. | Unificar en fase separada preservando mensaje y comportamiento. |
| A058 | app/lib/app/player/audio_track_selector.dart:16-23 | duplicación literal | baja | alto | candidato a revisión | 162 ventanas repetidas; ver DUPLICADOS, varias se solapan. | No unificar scrapers; validar equivalencia y decisión del propietario primero. |

## Revisión por categorías y límites

- Acoplamiento: IMPORTS.md registra todo el grafo y las SCC; part generado no es defecto.
- Widgets: se verificó mounted en el flujo de reproducción de catalog_home_page;
  no se encontró allí un uso demostrado de BuildContext tras await sin guarda.
- Estado compartido: setState detectado se lista en CANDIDATOS; no basta para
  afirmar que el estado sea compartido. No cambiar gestor de estado ni navegación.
- Red: el widget invoca coordinador/servicios; no se acreditó un HTTP directo
  dentro de build. La mezcla de responsabilidades sí consta en A de negocio UI.
- Recursos: hay dispose/cancel existentes; no se afirma fuga de Player por mera
  coincidencia léxica. El isolate de main necesita ownership explícito.
- Plataformas: imports dart:io y fronteras de codecs están inventariados; no hay
  scaffolds Android/Windows para verificar aislamiento real en esas plataformas.
- Tipado, catch, constantes y potenciales estáticos: ubicaciones en CANDIDATOS;
  diagnósticos comprobados de tipo/sintaxis en analyze_baseline.txt.
- Dependencias: conservar todas, incluidos plugins sin imports Dart directos.
  pubspec no contiene Riverpod, go_router, freezed ni very_good_analysis.
  No instalar ni migrar estas tecnologías dentro del refactor de paridad.
- Código muerto: solo probeLoop demostrado no referenciado; no eliminar nada.
- Scrapers no guardan en UI sus HTML directamente en el flujo revisado; no se
  ha demostrado mezcla con DB. Preservar transportes y parsers de cada fuente.

## Resumen

| Tipo | Cantidad | Severidad | Riesgo |
| --- | --- | --- | --- |
| archivo >250 | 21 | media | medio |
| archivo >250 | 14 | media | alto |
| archivo >250 | 1 | baja | alto |
| widget/State >120 | 12 | media | medio |
| contrato/sintaxis | 1 | alta | alto |
| scraper inválido | 1 | alta | alto |
| contrato bootstrap | 1 | alta | alto |
| negocio en widget | 1 | media | medio |
| recurso/isolate/errores | 1 | alta | alto |
| parseo hilo UI | 1 | media | alto |
| constantes/caché | 1 | baja | medio |
| código aparentemente muerto | 1 | baja | alto |
| errores/logs | 1 | baja | medio |
| duplicación literal | 1 | baja | alto |

## Segunda pasada adversarial

Se confrontaron diagnóstico de análisis, errores de parseo, imports y resultados
reales de tests; se verificó que los golden no dependan del manager roto. Se añadió
caso de URL pública para evitar una prueba vacía con todas las fuentes rechazadas.
No se declara cobertura completa de proveedores por los golden offline.
Reevaluación: resolver fallos previos en tarea distinta, caracterizar módulos SIN
TEST y comprobar pruebas completas antes de autorizar movimientos.

## Cierre de cobertura

Golden: 11 aprobados / 1 omitido (firma temporal AllAnime, B0-09).
JKAnime SIN GOLDEN; no aceptar funcionalmente ni avanzar. Hashes originales
intactos; sin revisión independiente ni validación gráfica/native actual.
