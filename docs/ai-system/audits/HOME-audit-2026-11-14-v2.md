# Auditoría de Home de Kongroo · revisión visual v2 · 2026-11-14

## Resumen y recomendación

La implementación actual reemplaza la composición Home anterior según la captura más reciente enviada por el propietario: rail izquierdo, hero ancho con metadatos públicos, secciones horizontales y nuevos iconos sobre fondo AMOLED `#000000`. El flujo de producción usa AniList sin login; `FakeMetadataProvider` queda explícito para tests/demo. Biblioteca y continuación usan solo datos locales existentes.

No se recomienda aceptación todavía: falta la revisión manual del propietario solicitada por el propio encargo. No se avanza a otra pantalla. No se hallaron P0/P1 dentro del alcance revisado. Las limitaciones de plataforma y hardware están abajo.

## Alcance y entorno

- Alcance: Home, composición necesaria del shell, modelos y adaptador AniList, cargador/cache de imágenes, búsqueda pública exacta por ID, módulos README y regresiones asociadas.
- Fedora 44 KDE Wayland; Flutter 3.47.9/Dart 3.13.7 para suite y build Linux. Análisis Flutter con Flutter 3.50.0-0.4.pre/Dart 3.14.0 aislado bajo `.ai-local/toolchains/flutter`.
- Aplicación Linux release ejecutada con SQLite aislado en `.ai-local/home/public-catalog.sqlite`; no se accedió a la base de usuario.
- La captura de la ventana activa se guardó en `.ai-local/home/home-kongroo-review-final.png` (1280×768). RSS al momento de revisión: ~214 MiB, unos segundos después del primer frame.
- `mcp__wayland__capture_screenshot` quedó esperando y se terminó; `mcp__wayland__describe_environment` devolvió `Transport closed`. Spectacle de Fedora sí capturó la ventana activa.

## Código y límites revisados

- `app/lib/app/catalog/catalog_home_page.dart`: rail de escritorio; navegación inferior compacta; modalidad superior Android directional para TV. Inicio/Catálogo/Biblioteca son destinos conectados; calendario/descubrir, ajustes y perfil están señalados como extensiones sin acción.
- `app/lib/app/home/home_data.dart`, `home_screen.dart`, `home_hero.dart`, `home_sections.dart`, `home_artwork.dart`, `home_icons.dart`, `home_appearance.dart`: composición de Home, estados vacíos, metadatos, carga HTTPS y tokens visuales.
- `app/lib/data/anilist/anilist_client.dart`, `offline_first_anime_catalog.dart`, `anilist_metadata_provider.dart` y modelos domain: browse, búsqueda exacta por ID, imágenes, género, estado, formato, fecha, temporada/año, score y popularidad.
- `app/lib/app/catalog/catalog_module.dart`: AniList público por defecto; fake solo en modo de test/demo.
- READMEs de Home, AniList, catalog UI y dominio; `docs/ui/HOME.md`; pruebas en Home y AniList.
- No se consultaron páginas externas nuevas en esta pasada. El esquema usado se comprobó en el smoke test live y en la ventana real. Las referencias oficiales de rate limits/terms ya presentes en README no se revalidaron; por eso queda abierto HOME-V2-04.
- Pasada adversarial separada por el coordinador, no independiente: comprobó que `Continue viendo` permanece vacío sin player, que la biblioteca personal solo viene de Drift local, que el banner no sustituye la imagen por una carátula, que las URLs requieren HTTPS, que el decode se limita a 1600 px y que el LRU de Flutter se acota a 120 entradas/48 MiB.

## Hallazgos y riesgos pendientes

| ID | Prioridad | Estado | Evidencia y efecto | Cierre requerido |
| --- | --- | --- | --- | --- |
| HOME-V2-01 | P2 | Pendiente | La captura real y la revisión de la composición corresponden al propietario. No inferir aceptación por build/tests. | Revisión manual de `.ai-local/home/home-kongroo-review-final.png` y la ventana abierta. |
| HOME-V2-02 | P2 | Pendiente | La cache de imagen está limitada, pero la corrida fue en un equipo de ~7.5 GiB; no prueba estabilidad de memoria/scroll en hardware de 4 GB ni frame pacing. RSS de un arranque no basta para afirmarlo. | Perfil de scroll sostenido y memoria en el equipo objetivo de 4 GB. |
| HOME-V2-03 | P2 | Pendiente | Fedora/Linux se ejecutó; Android/TV no se ejecutaron en dispositivo. La navegación TV depende de `MediaQuery.navigationMode == directional` en Android y no se confirmó con mando real. | Validación visual/foco con Android móvil y Android TV. |
| HOME-V2-04 | P2 | Pendiente de política | El propietario autorizó AniList público y el smoke test live funcionó sin credenciales. El proyecto aún no registra una revisión actual de elegibilidad/condiciones para este producto. | Revisar los términos aplicables antes de distribución pública; la caché persistente actual sigue limitada a la última búsqueda explícita. |

No se creó progreso sintético ni una lista personal a partir del browse público. El smoke test externo prueba disponibilidad en una solicitud; no demuestra uptime ni garantiza términos/estabilidad futura.

## Validación ejecutada

- `dart analyze lib test`: sin issues.
- `flutter analyze --no-pub`: sin issues con Flutter beta aislado 3.50.0-0.4.pre.
- `flutter test --no-pub`: 226 aprobadas, 3 omitidas.
- Smoke real opt-in de AniList (`KONGROO_TEST_ANILIST_LIVE=true`): título real, carátula y banner, sin autenticación.
- Loopback local cubre browse, metadatos estacionales, caché persistente de AniList y búsqueda exacta por ID.
- `flutter build linux --release --no-pub`: exitoso tras el último cambio de código.
- Fedora: primer frame real observado, screenshot real de Home. No se probó Android/TV ni hardware de 4 GB.
- Flutter stable `flutter analyze` conserva el fallo LSP UTF-8 documentado en `TESTING.md`; el análisis Dart y el Flutter analyze beta sí pasaron. Una prueba Flutter con la beta se descartó porque el SDK beta y engine empaquetados no compilan juntos el `SemanticsRole.slider`; la suite de producto se ejecutó con la stable.
- `git diff --check`: exit 0, sin whitespace errors.
- `python3 tools/ai/memory.py check`: exit 0, salida `[]`.

## Próximo paso

El siguiente paso corresponde al propietario: revisar la imagen y la ventana real de Home y señalar ajustes visuales. Mantenerse en Home. No aceptar fase ni iniciar otra pantalla automáticamente.
