# Cambio coordinado de fuente

`PlaybackSourceSwitchService` solicita candidatos al `PlaybackProviderManager` y ejecuta cada cambio mediante el `SpikePlayerCoordinator` existente. Conserva un checkpoint de posición/estado, intenta alternativas y, si fallan, intenta restaurar la fuente anterior. No posee ni invoca un `Player` nativo.

| Archivo | Responsabilidad | Pruebas |
|---|---|---|
| `playback_source_switch_service.dart` | Estado tipado, cancelación/generación, exclusión de fuentes intentadas, fallback y restauración | `test/player/spike_player_coordinator_test.dart`; integración de fuente en `test/player/media_kit_spike_integration_test.dart` |

Depende de contratos de proveedor y aplicación. Nuevas políticas de continuidad deben probar éxito, fallo, pausa, cancelación y cierre sin abrir otro motor. Ejecutar: `flutter test --no-pub test/player/spike_player_coordinator_test.dart test/player/media_kit_spike_integration_test.dart`.

La ficha reutiliza este servicio mediante `ProviderPlaybackRoute`: el mismo
manager descubre y resuelve fuentes, y el mismo coordinator abre/cambia el
medio. La primera resolución entrega al player una allowlist exacta de URIs
HTTPS; un URI firmado que cambie tras la carga inicial puede no estar permitido
durante un refresh posterior. Ese caso necesita una política de renovación
confinada por provider antes de ampliar la allowlist.
