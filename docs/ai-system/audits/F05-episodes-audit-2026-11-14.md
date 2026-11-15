# Auditoría F05 — episodios públicos en la ficha — 2026-11-14

## Resumen y recomendación

La pestaña no fallaba por OAuth: el corte 05.1 la había dejado como placeholder
y la consulta exacta descartaba `streamingEpisodes`. La corrección conserva el
layout general, usa metadatos públicos sin sesión, persiste la respuesta bajo
demanda y construye una cuadrícula lazy. No se conectó una fuente de video.

No quedan P0/P1 en el alcance revisado. El código, las pruebas reproducibles,
las consultas live y el build Linux pasan. La aplicación está abierta en Fedora,
pero no hay backend de entrada Wayland para navegar hasta una ficha; la
inspección visual de los episodios queda para el propietario. No se recomienda
aceptar ni avanzar de fase hasta esa revisión manual.

## Alcance y entorno

- Raíz: `/home/kyouma/Vídeos/PROYECTO ANIME`.
- Flutter 3.47.9 / Dart 3.13.7 aislados, Fedora Linux.
- Módulos: dominio de catálogo, AniList público, caché Drift v8 y contenido
  de la pestaña Episodios.
- Se preservaron todos los cambios previos; sin commit ni push.

## Fuente primaria consultada

El 2026-11-14 se envió un POST GraphQL anónimo a
`https://graphql.anilist.co` para `Media(id: 16498, type: ANIME)` con
`episodes` y `streamingEpisodes { title thumbnail url site }`. HTTP 200 devolvió
*Attack on Titan*, total 25 y 25 entradas con título/miniatura/sitio. La prueba
opt-in ejecutó luego la consulta de producción sin cabecera Authorization.
Esto prueba disponibilidad actual de esos datos; no convierte los enlaces
externos en fuentes reproducibles ni garantiza que todas las obras publiquen
la lista completa.

## Implementación revisada

- `anilist_client.dart` pide el suplemento solo para lookup exacto; Home y
  búsqueda conservan la consulta breve.
- `anilist_detail_fields.dart` normaliza número, título, miniatura HTTPS y sitio.
  El códec conserva el marcador que diferencia respuesta actual de caché vieja.
- `AniListMetadataProvider` declara `episodeMetadata` y lo expone mediante el
  contrato existente. `ProviderEpisodeMetadata` no representa reproducción.
- `OfflineFirstAnimeCatalog` refresca una vez un documento previo al nuevo
  campo, mantiene fallback stale ante fallo y limita cada documento a 512 KiB;
  el almacén sigue recortado a 64 fichas.
- `anime_detail_tab_content.dart` usa `SliverGrid`/builder, `cacheWidth: 480` y
  el total real para representar huecos como `Episodio N`, sin inventar título
  ni imagen. Los controles de playback siguen desconectados.

## Hallazgos y reevaluación

- **F05-E1, P1, corregido.** Causa original: estado vacío codificado en UI y
  ausencia de `streamingEpisodes` en la query. Reproducción: abrir cualquier
  ficha y seleccionar Episodios mostraba el mensaje de lista no conectada.
  Corrección y regresión: query/mapeo/caché/grid y widget que exige 12 tarjetas
  derivadas del total del fixture.
- **F05-E2, P2, corregido tras auditoría independiente.** El encoder escribía
  `episodeMetadataFetched: false`, pero el decoder infería `true` solo por la
  presencia de la lista. Ahora conserva el bool explícito y usa presencia solo
  para respuestas GraphQL. Un round-trip `false → false` lo prueba.
- **F05-E3, P3, corregido tras auditoría independiente.** Dos constructores
  aceptaban una cadena no parseable porque comprobaban solo el caso URI no nula.
  Ahora rechazan URI nula o no HTTPS; hay regresiones de dominio.

La revisión independiente fue de solo lectura y no encontró otros P0/P1.
Confirmó separación metadata/reproducción, construcción perezosa y refresco
sin borrado. Riesgo residual: AniList puede publicar una lista parcial; la UI
completa solo la numeración hasta el total real.

## Validación actual

- `flutter analyze --no-pub lib/app/catalog lib/data/anilist lib/domain/catalog test/data/anilist test/widget_test.dart`: sin issues.
- 26 pruebas reproducibles: cliente loopback, adapter, códec, caché/reapertura,
  refresco legacy único, UI y progreso; todas pasan.
- 3 pruebas live con `KONGROO_TEST_ANILIST_LIVE=true`: título/imágenes,
  reparto/relaciones y episodios reales sin OAuth; todas pasan.
- `flutter build linux --release --no-pub -t lib/main.dart`: correcto.
- App release abierta sobre `.ai-local/fase05/detail-review.sqlite`. Captura de
  Home actual: `.ai-local/fase05/episodes-open.png`.
- MCP Wayland: captura disponible por Spectacle; teclado y puntero no
  disponibles. No se obtuvo captura de la ficha ni se probó clic real.

No se ejecutó la suite completa del repositorio, Android/TV físicos, perfilado
de RAM o reproducción, porque quedan fuera del defecto focalizado.

## Documentación y criterio de revisión

Se actualizaron los README de ficha, AniList, persistencia local y dominio,
además de memoria/traspaso. Para reevaluar manualmente: desde Home abrir un
anime como *Attack on Titan*, entrar en Episodios y confirmar conteo, títulos,
miniaturas, scroll y ausencia de acción de reproducción falsa.
