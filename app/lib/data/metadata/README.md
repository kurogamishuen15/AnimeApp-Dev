# Proveedor de metadatos de demostración

## Responsabilidad

Contiene fixtures deterministas sintéticos para demostrar catálogo offline. No consulta fuentes públicas y no contiene datos copiados de AniList, TMDB o Kitsu.

## Árbol

```text
data/metadata/
  fake_metadata_provider.dart   resultados locales sintéticos de búsqueda/detalle
  README.md                     alcance, errores y sustitución futura
```

## Contrato y funcionamiento

`FakeMetadataProvider` implementa `MetadataProvider`, declara `publicSearch` y `animeDetails`, expone tres títulos ficticios y namespace `demo`, y acepta un reloj UTC inyectable. La búsqueda usa coincidencia insensible a mayúsculas sobre título/sinopsis; el límite no positivo produce `ProviderNoResults`. Los IDs son deterministas entre ejecuciones. Episodios son `ProviderUnsupported`, y no se simula un proveedor de reproducción.

El provider no abre sockets, archivos, cuentas ni servicios. `searchRequestCount` y `detailsRequestCount` permiten comprobar que la UI usa el fake en las pruebas.

## Errores y pruebas

La búsqueda sin coincidencias responde `ProviderNoResults`; un namespace externo diferente tampoco devuelve detalles. La prueba widget de `app/test/widget_test.dart` cubre resultados, ficha y ausencia de HTTP mediante `HttpOverrides` que rechaza cualquier `HttpClient`; el conjunto completo se ejecuta con `flutter test --no-pub`.

## Portabilidad y límites

Es Dart puro, se puede usar en pruebas de otras plataformas sin dependencias de host. No reemplazarlo por un provider real hasta aprobar elegibilidad, licencia/términos, atribución, cuotas y retención. No persistir la metadata fake como si fuera fuente de verdad. Los fixtures no se diseñaron como catálogo de producto.
