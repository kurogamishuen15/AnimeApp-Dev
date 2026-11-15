# UI y composición del catálogo local

## Árbol y responsabilidad

```text
app/catalog/
  catalog_module.dart       composition root: SQLite + AniList público + repositorios + service
  catalog_home_page.dart    pestañas Catálogo / Mi biblioteca
  catalog_search_page.dart  búsqueda pública y navegación a detalle
  local_library_page.dart   filas locales, estado y navegación
  anime_detail_page.dart    composición y carga de la ficha
  detail/                   cabecera, navegación interna y contenido real/empty
  README.md                 flujo, errores, almacenamiento y portabilidad
```

Los widgets usan `CatalogService`; no importan Drift, SQL, Dio, AniList, OAuth ni el motor de video. `CatalogModule` es propietario del `AppDatabase` y expone `close()` para el ciclo de vida/test. No hay otro repositorio ni tabla de biblioteca/progreso.

`CatalogHomePage` recibe opcionalmente `PlaybackProviderManager`. La ficha crea
un `PlaybackEpisode` desde el ID externo y aliases del anime; la UI ofrece el
selector solo al resolver streams HTTPS candidatos. La ruta de reproducción
utiliza el `SpikePlayerModule` y `media_kit` existentes, y cancela la resolución
pendiente al abandonar la ficha. AniList `streamingEpisodes` nunca se usa como
URL reproducible.

## Flujo visible

1. `CatalogHomePage` abre Home con browse público AniList y biblioteca local.
2. `CatalogSearchPage` busca metadatos públicos de AniList sin autenticación y abre una ficha.
3. La ficha permanece dentro del área central del shell y muestra cabecera cinematográfica y pestañas. Permite añadir y cambiar el estado; la confirmación de Completed se conserva.
4. La pantalla de biblioteca permite cambiar estado y volver a abrir la ficha.
5. El campo de segundos conserva el progreso local existente, sin inventar una lista o duración de episodios.

Errores tipados se muestran como texto recuperable. Si una referencia de metadata ya no está disponible, la biblioteca se conserva y muestra `AnimeId` como fallback. Indicadores de carga están presentes mientras terminan operaciones; el test bombea estados objetivo y no espera un spinner infinito.

## Persistencia y aislamiento

El flujo normal abre la base de AnimeApp en Application Support. `CatalogModule.open(useDemoProvider: true)` permite aislar las pruebas con `FakeMetadataProvider`. Para pruebas de la misión, `CatalogModule.open(databaseFile: ...)` recibe un archivo bajo `.ai-local/`; el arranque Linux acepta `KONGROO_DATABASE_PATH` solo dentro de `.ai-local/`, rechaza `..` y symlinks y deja el path normal como comportamiento de la aplicación instalada. No ejecutar pruebas con la variable ausente si el objetivo es mantener aislada la base personal.

`app/test/widget_test.dart` recorre el flujo sobre un archivo temporal, bloquea HTTP y cierra/reabre el archivo. La evidencia adicional de arranque Fedora está en la sesión de memoria del catálogo.

## Límites y portabilidad

UI Flutter portable con composición Linux-first. La ficha utiliza metadata
pública de AniList sin autenticar y preserva la navegación global. Android y
Android TV aún no se han probado en dispositivo. AniList aporta el total y,
cuando está disponible, metadata pública de episodios; la ficha la presenta en
una cuadrícula lazy, pero no la confunde con una fuente reproducible. Reparto y
relaciones muestran los datos públicos disponibles y la galería usa solo
carátula/banner reales. Descarga sigue desactivada. El flujo de reproducción y
sus contratos están conectados, aunque los proveedores disponibles no han
producido un episodio reproducible en la validación real actual. Los seis estados son decisiones
manuales locales. Completar conserva la confirmación porque no hay seguimiento
verificado de episodios vistos. `PlaybackProgressRepository` se reutiliza por
el service. Cerrar `CatalogModule` al terminar el propietario del runtime. Ver
[detalle](detail/README.md).

## Inicio

La aplicación abre [Inicio de Kongroo](../home/README.md), con browse público y estados personales vacíos hasta que haya datos locales. El shell conserva los accesos a Catálogo y Mi biblioteca. `FakeMetadataProvider` solo se usa explícitamente en pruebas y demostraciones aisladas.

## Recorrido de una ficha sin cuenta

Ficha → `CatalogService` → caché Drift por ID → proveedor público si falta o
venció → persistencia → UI. Con datos locales, la cabecera se actualiza antes
del refresco. Si falla la red y falta la ficha, se ofrece reintentar. Si ya se
consultó la ficha, puede buscarse por título desde Catálogo sin conexión.
`test/widget_test.dart` recorre Home → Ficha con datos de prueba y verifica
también biblioteca local y reinicio. La prueba real del proveedor se ejecuta
por separado.
