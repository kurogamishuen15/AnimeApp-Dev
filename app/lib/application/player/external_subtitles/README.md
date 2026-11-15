# Coordinación de subtítulos externos

`ExternalSubtitleService` coordina búsqueda/descarga del catálogo con la política de hardsub y el puerto de carga del reproductor. No implementa HTTP ni entrega una URL temporal al motor: solo acepta un URI local descargado.

| Archivo | Responsabilidad | Pruebas |
|---|---|---|
| `external_subtitle_service.dart` | Fallos tipados, bloqueo por hardsub confirmado, validación `file:` y carga mediante `ExternalSubtitleLoader` | `test/application/external_subtitle_service_test.dart`; recorrido con engine real en `test/player/media_kit_spike_integration_test.dart`. |

Depende de `domain/player/subtitles` y recibe sus puertos por constructor. Para extender formatos o contexto, cambiar primero el contrato domain y su adaptador; conservar generación de fuente y no introducir acceso directo a red en application. Ejecutar desde `app/`: `flutter test --no-pub test/application/external_subtitle_service_test.dart`.
