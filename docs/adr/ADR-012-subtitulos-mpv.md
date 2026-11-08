# ADR-012: Estilo de subtítulos

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aceptado por el propietario el 2026-11-08 como selección arquitectónica; propiedades soportadas pendientes de spike**.
- Fase: F2.6–F2.8.
- Requisitos: MVP de reproducción mock; detalle de controles pendiente de F2.

## Propuesta

Aplicar estilo de subtítulos mediante propiedades de mpv a través del adaptador `media_kit`/`PlaybackEngine`. La UI no escribe propiedades directamente sobre el motor.

## Alternativas

- Renderer propio de subtítulos: mayor control visual y complejidad/perf adicional; no es la selección del plan.
- Aceptar solo estilo nativo: fallback si spike muestra limitación compatible con requisitos.

## Consecuencias y aceptación

No implementar ahora. En F2 probar estilos con archivos/casos representativos, cambio de fuente, sincronización y liberación de recursos; verificar qué propiedades expone la integración y documentar límites antes de integrar. Subtítulos externos cumplen sus subfases separadas.
