# Módulo `domain`

## Propósito y responsabilidad

Contiene identidad y, cuando existan, modelos, reglas y contratos propios del negocio. Debe analizarse y probarse sin Flutter UI, Linux, plugins, red ni base de datos.

## Archivos y contratos

| Archivo | Función |
| --- | --- |
| `app_identity.dart` | `AppIdentity.name`, constante pública con el nombre de la aplicación. |
| `catalog/anime_summary.dart` | Resultado de búsqueda de dominio con fuente explícita, modelo anime minimal y error de refresco opcional. |
| `catalog/anime_catalog_repository.dart` | Puerto Dart puro para búsqueda de catálogo, usando `Result` y modelos propios. |

El dominio incluye los modelos de catálogo puros en `catalog/`; el repositorio
AniList se declara aquí y el adaptador reside en `data/anilist`.

## Dependencias permitidas y prohibidas

Puede depender de bibliotecas Dart puras que se justifiquen y de otros contratos del dominio. No puede importar `dart:ui`, `dart:io`, `dart:ffi`, Flutter/UI, composición `app`, presentación, infraestructura, integraciones, plugins ni módulos de plataforma. Tampoco puede importar archivos fuera de `app/lib`; el checker rechaza cualquier symlink bajo `app/lib` sin seguirlo. Evitar dependencias entre features que creen ciclos.

[`scripts/check_imports.dart`](../../../scripts/check_imports.dart) aplica estas reglas a todos los directorios `domain` bajo `app/lib`, incluyendo `features/<feature>/domain`, con imports package y relativos resueltos. Las reglas y sus limitaciones están en [`scripts/README.md`](../../../scripts/README.md).

## Flujo, pruebas y rendimiento

El widget raíz usa `AppIdentity.name`. Los modelos de catálogo no ejecutan I/O; los tests HTTP están en el adapter y usan loopback. El domain no inicializa servicios ni mantiene estado mutable.

## Portabilidad y trabajo pendiente

El módulo es Dart puro y reutilizable en todas las plataformas objetivo. El checker de imports impide acoplarlo a Flutter/Drift/Dio/plugins. El adapter AniList y su cache son infraestructura externos y no son necesarios para analizar o usar capacidades locales.
