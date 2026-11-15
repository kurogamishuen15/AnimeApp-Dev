# Mock de proveedores de reproducción F2.5

`MockPlaybackProvider` implementa `PlaybackSourceProvider` sin red, disco,
credenciales ni acceso al motor. Sirve para reproducir contratos, fallos y
alternativas de forma determinista.

| Archivo | Responsabilidad |
|---|---|
| `mock_playback_provider.dart` | fixture con identidad, escenarios, fuentes/servidores y contadores observables |
| `README.md` | modos disponibles, límites y comandos de prueba |

Los escenarios incluyen fuente/servidor válido, dos fuentes con idiomas y
calidades distintas, fuente caída, timeout tipado, lista vacía, fallo de red,
episodio ajeno, alternativas no declaradas y resolución con IDs inconsistentes.
`requestGate` y `resolveGate` son `Completer`
inyectables para carreras y cancelación deterministas; no se usan `sleep` ni
retardos de reloj reales. El escenario timeout representa la respuesta tipada
del adaptador; no simula la expiración de un socket externo.

El fixture usa únicamente `mock.invalid`, dominio reservado de prueba. Los
resultados nunca se envían a `MediaKitSpikeEngine`. La mock mutable de escenario
es exclusiva para pruebas y permite demostrar el probe de recuperación.

```bash
flutter test --no-pub test/domain/playback_provider_contract_test.dart \
  test/application/playback_provider_manager_test.dart
```
