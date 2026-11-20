# Core: resultados, errores y logging

Estado: F1.7 implementado; módulo Dart puro, sin acceso a infraestructura.

| Archivo | Responsabilidad |
|---|---|
| `errors/app_error.dart` | Taxonomía de errores de aplicación tipados y estables. |
| `result/result.dart` | `Success<T>` / `Failure<T>` con `fold`, `map` y `flatMap`. |
| `logger/safe_logger.dart` | Eventos estructurados, sanitización, sinks y cierre. |

Las excepciones de paquetes se mapean en cada adaptador al error tipado apropiado antes de cruzar al dominio. `SafeLogger` registra nivel, código de evento, timestamp UTC y correlation id opcional. Los sinks se inyectan; `MemoryLogSink` sirve para pruebas y se cierra explícitamente. `SafeLogger.dispose()` deja de aceptar eventos y libera su lista de sinks. No hay un sink de consola de producción implementado; la captura de salida real de ese sink no aplica y no se presenta como verificada.

La sanitización opera sobre mapas/listas recursivos, nombres de cabeceras y credenciales conocidos, texto bearer y errores. Las URI se reducen a esquema, host y puerto; omite userinfo, path, query y fragment completos. URL malformadas se sustituyen por `[INVALID URL]` para que el saneamiento no interrumpa logging. Objetos desconocidos no se convierten con `toString`; se registra solo su tipo. No se persisten logs ni se guardan bodies de red. La redacción cubre patrones sensibles conocidos, no tokens arbitrarios sin contexto/etiqueta.

No depende de Flutter, Drift, Dio ni servicios del sistema. Portable a otras plataformas sin adaptador. Las pruebas están en `test/core/core_test.dart`; ejecutar `flutter test test/core`. No se midió overhead de producción; el logger no mantiene colas, timers ni procesos.


## Bootstrap Flutter

`bootstrap/anime_app.dart` conserva la composición de la aplicación (`AnimeApp`),
el título/restoration scope y la integración actual del catálogo y playback. No
posee rutas ni registro de servicios nuevo. La pantalla y su tema local siguen en
`app/catalog` y `app/home` hasta sus mini-fases correspondientes.
