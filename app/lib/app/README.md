# Módulo `app`

## Propósito

Compone los widgets Flutter y el punto de composición del recorrido de catálogo local. Los widgets dependen de `CatalogService`; no incluyen reglas de dominio, SQL, HTTP ni adaptadores nativos.

## Archivos

| Archivo | Función |
| --- | --- |
| `anime_app.dart` | `AnimeApp({required CatalogService catalogService})`, `MaterialApp` y pantalla raíz |
| `catalog/catalog_module.dart` | Composition root Linux-first: AniList público, DB, repositorios y service; dueño de `close()` |
| `catalog/catalog_home_page.dart` | Navegación local entre Inicio, catálogo y biblioteca |
| `catalog/catalog_search_page.dart` | búsqueda y apertura de detalle |
| `catalog/local_library_page.dart` | filas locales, edición provisional del estado |
| `catalog/anime_detail_page.dart` | detalle, alta y edición de progreso demo |
| `main.dart` | bootstrap Flutter y opción controlada de DB temporal para validación |

## Flujo y dependencias

```text
main → CatalogModule → CatalogService → contratos domain
                                ├→ AniListMetadataProvider (público, sin auth)
                                ├→ repositorios Drift/SQLite
                                └→ progreso F1.10 existente
AnimeApp/widgets ───────────────→ CatalogService
```

El primer arranque abre [Inicio](home/README.md), carga AniList público y deja vacías las filas personales hasta que haya datos locales. La búsqueda pública funciona sin iniciar sesión; alta, estado y posición progresan por repositorios ya existentes. `FakeMetadataProvider` queda para pruebas y demo explícito. No se crea un sistema paralelo. La ficha muestra fallback de identidad si la metadata deja de estar disponible. Los seis estados de biblioteca se seleccionan manualmente; `episode:1` sigue siendo un registro demostrativo y no se infiere visionado desde él.

El runtime instalado abre su base app-owned en Application Support. Para pruebas aisladas, `KONGROO_DATABASE_PATH` solo se acepta dentro de `.ai-local/`, con rechazo de `..` y symlinks. Las pruebas usan `AppDatabase.atFile` temporal y nunca abren la base personal.

## Verificación y errores

`test/widget_test.dart` bloquea HTTP, recorre búsqueda/detalle/alta/duplicado/estado/progreso y crea una nueva composición sobre el mismo SQLite después del cierre. Errores de dominio se presentan como texto; las pantallas se actualizan solo después de respuesta del service/repository.

```bash
flutter test --no-pub test/widget_test.dart
dart analyze lib/app test/widget_test.dart
flutter build linux --debug --no-pub
```

## Portabilidad y pendientes

El límite visual permanece Flutter; domain y aplicación son Dart puros. Fedora/Linux se construyó en esta integración; Android y Android TV requieren verificación en dispositivo. No hay OAuth, sync ni descarga. El producto principal no integra el reproductor: el spike F2.2 opt-in está aislado en `lib/{application,data,app}/player/` y no forma parte de su navegación ni de los flujos de reproducción. Cerrar el módulo al terminar el ciclo de vida del runtime. Revisar accesibilidad y uso con teclado al ampliar pantallas.
