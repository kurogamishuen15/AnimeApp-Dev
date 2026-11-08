# ADR-004: Navegación

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aceptado por el propietario el 2026-11-08 como selección arquitectónica; validación técnica pendiente**.
- Fase: F3.3.
- Requisitos: MVP de búsqueda/ficha/episodios; NFR-06, NFR-10.

## Contexto

El scaffold no implementa navegación. El primer entorno es Fedora/Linux y el plan contempla más adelante Android, Android TV y Windows.

## Propuesta

Usar go_router para rutas declarativas, manteniendo parámetros/rutas dentro de presentación. La navegación no contiene reglas de dominio. Integración en F3.3, no en F1.2.

## Alternativas

- Navigator de Flutter: dependencias mínimas y estructura manual.
- Otra solución: solo ante una necesidad no resuelta y con comparación de compatibilidad/licencia.

## Consecuencias y aceptación

Integrar solo en F3.3 tras probar navegación a búsqueda/ficha/episodio, retorno/restauración en escritorio y plataformas previstas, rutas inválidas y revisión de dependencias/licencia.
