# Resultado tipado

`result.dart` ofrece `Result<T>` con `Success<T>` y `Failure<T>`, además de `fold`, `map` y `flatMap` para componer operaciones sin excepciones como flujo normal.

| Archivo | Responsabilidad |
|---|---|
| `result.dart` | Unión sellada del valor o `AppError` |

El módulo depende de `core/errors` y de Dart. Si se cambia la forma de componer resultados, mantener exhaustividad de patrones y revisar los repositorios de sincronización/catálogo. La validación actual está en pruebas de consumidores, incluida `flutter test --no-pub test/data/testing/fake_sync_remote_test.dart`.
