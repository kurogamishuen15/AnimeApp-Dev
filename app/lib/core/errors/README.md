# Errores compartidos

`app_error.dart` define la jerarquía sellada `AppError` y tipos de fallos de red, timeout, límite, autenticación, validación, almacenamiento, ausencia y disponibilidad. Es un vocabulario común de core; no depende de Flutter ni de un transporte concreto.

| Archivo | Uso |
|---|---|
| `app_error.dart` | Código y mensaje saneado, con variantes tipadas para capas superiores |

Los adaptadores convierten fallos externos en estos tipos y no propagan payloads privados. Al agregar una variante, revisar los `switch` exhaustivos y pruebas de mapeo en el módulo adaptador. La cobertura se ejecuta con suites de clientes, por ejemplo `flutter test --no-pub test/data/anilist/anilist_client_test.dart`.
