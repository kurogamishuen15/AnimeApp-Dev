# ADR-004: Navegación

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Propuesto; no consta aprobación formal**. `TECH_DECISIONS.md` también lo marca como propuesta.
- Fase: F3.3.
- Requisitos: MVP de búsqueda/ficha/episodios; NFR-06, NFR-10.

## Contexto

El scaffold no implementa navegación. El primer entorno es Fedora/Linux y el plan contempla más adelante Android, Android TV y Windows.

## Propuesta

Evaluar go_router para rutas declarativas, manteniendo parámetros/rutas dentro de presentación. La navegación no contiene reglas de dominio.

## Alternativas

- Navigator de Flutter: dependencias mínimas y estructura manual.
- Otra solución: solo ante una necesidad no resuelta y con comparación de compatibilidad/licencia.

## Consecuencias y aceptación

No se incorpora paquete aún. Spike en F3.3 con navegación a búsqueda/ficha/episodio, retorno/restauración en escritorio y plataformas previstas, rutas inválidas y revisión de dependencias/licencia.
