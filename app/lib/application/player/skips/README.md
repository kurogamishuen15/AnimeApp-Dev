# Coordinación de segmentos de skip

El módulo resuelve segmentos para el episodio activo, presenta el segmento actual y envía el seek mediante `SpikePlayerCoordinator`. Los saltos automáticos son opt-in y usan la política domain; no crean una cola de reproducción paralela.

| Archivo | Responsabilidad | Pruebas |
|---|---|---|
| `skip_segment_service.dart` | Consulta/ciclo de vida del catálogo, estado del segmento y confirmación observable de seek | `test/player/spike_player_coordinator_test.dart` |
| `automatic_skip_controller.dart` | Evalúa snapshots, política, generación y seeks automáticos; libera ambas suscripciones en `dispose` | `test/domain/skip_automation_policy_test.dart` y pruebas del coordinator |

Depende de contratos `domain/player/skips` y del coordinator. Para añadir clase de segmento, declarar origen y política en domain antes de conectar su UI. Comando: `flutter test --no-pub test/domain/skip_automation_policy_test.dart test/player/spike_player_coordinator_test.dart`.
