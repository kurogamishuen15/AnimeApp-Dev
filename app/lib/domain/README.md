# Módulo `domain`

## Propósito y responsabilidad

Contiene identidad y, cuando existan, modelos, reglas y contratos propios del negocio. Debe analizarse y probarse sin Flutter UI, Linux, plugins, red ni base de datos.

## Archivos y contratos

| Archivo | Función |
| --- | --- |
| `app_identity.dart` | `AppIdentity.name`, constante pública con el nombre de la aplicación. |

No se declaran todavía repositorios, casos de uso, ajustes ni contratos multimedia porque no existen en el código actual.

## Dependencias permitidas y prohibidas

Puede depender de bibliotecas Dart puras que se justifiquen y de otros contratos del dominio. No puede importar `dart:ui`, `dart:io`, `dart:ffi`, Flutter/UI, composición `app`, presentación, infraestructura, integraciones, plugins ni módulos de plataforma. Tampoco puede importar archivos fuera de `app/lib`; el checker rechaza cualquier symlink bajo `app/lib` sin seguirlo. Evitar dependencias entre features que creen ciclos.

[`scripts/check_imports.dart`](../../../scripts/check_imports.dart) aplica estas reglas a todos los directorios `domain` bajo `app/lib`, incluyendo `features/<feature>/domain`, con imports package y relativos resueltos. Las reglas y sus limitaciones están en [`scripts/README.md`](../../../scripts/README.md).

## Flujo, pruebas y rendimiento

El widget raíz usa `AppIdentity.name`; no hay ciclo de vida, estado mutable ni recursos. No existen tests unitarios del dominio todavía; la prueba widget actual solo valida la pantalla inicial. La constante no requiere inicialización adicional ni tiene impacto material de recursos.

## Portabilidad y trabajo pendiente

El módulo es Dart puro y reutilizable en todas las plataformas objetivo. Crear modelos/reglas/puertos solo cuando un requisito aprobado tenga consumidor; probar cada regla con tests Dart puros. No añadir ajustes ni persistencia aquí por adelantado: el registro tipado pertenece a F1.5 y su almacenamiento durable a F1.6.
