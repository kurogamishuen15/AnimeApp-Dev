# Dominio de segmentos de skip

Define segmentos y reglas independientes de UI, HTTP y motor. Un segmento queda ligado a una identidad de episodio, intervalo válido y procedencia; la política mantiene los prompts manuales habilitados y los saltos automáticos desactivados por defecto.

| Archivo | Responsabilidad |
|---|---|
| `skip_segment.dart` | Tipos, procedencia, intervalo y validación por episodio/duración |
| `skip_segment_catalog.dart` | Puerto y resultado tipado de consulta; ID MAL validado |
| `skip_automation_policy.dart` | Preferencias opt-in y evidencia requerida para recap/filler |

Application consume el contrato y data implementa el catálogo (AniSkip). No añadir DTO HTTP ni dependencias Flutter/libmpv aquí. Para cambiar una regla, actualizar sus tests antes de conectar application. Tests: `flutter test --no-pub test/domain/skip_automation_policy_test.dart test/data/aniskip/aniskip_client_test.dart`.
