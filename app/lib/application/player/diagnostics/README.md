# Diagnóstico de reproducción

Este módulo recoge muestras de rendimiento solo mientras se solicitan. No controla el motor ni inicia sondeos cuando el colector está detenido.

| Archivo | Responsabilidad | Contrato y pruebas |
|---|---|---|
| `playback_performance.dart` | Modelo `PlaybackPerformanceSample`, puerto `PlaybackPerformanceSource` y `PlaybackPerformanceCollector` | Muestras con métricas opcionales; polling no superpuesto y `stop`/`dispose` esperan la lectura activa. Tests: `test/player/player_performance_collector_test.dart` y `test/player/player_performance_integration_test.dart`. |

La aplicación consume el puerto y el adaptador de datos consulta propiedades de mpv. Para añadir una métrica, mantenerla opcional cuando no esté disponible, añadir su lectura en el adaptador y probar el valor presente y ausente. Nota arquitectónica pendiente: `data/player/engine/mpv_performance_reader.dart` importa hoy este contrato de application; conviene invertir esa dependencia en un cambio separado, sin alterar el comportamiento.
