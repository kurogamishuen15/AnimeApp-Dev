# ADR-002: Motor de video

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aprobado como punto de partida** en `TECH_DECISIONS.md`; compatibilidad/rendimiento pendientes.
- Fase: F2.1–F2.2; API interna definida en F2.5.
- Alcance: `media_kit` sobre libmpv detrás de `PlaybackEngine`.

## Contexto

El MVP necesita reproducir un clip mock y cambiar de servidor mock conservando posición. `ARCHITECTURE.md` ya documenta el flujo UI → controller → sesión → `PlaybackEngine` → adaptador `media_kit`/libmpv. No hay reproductor implementado.

## Decisión

Conservar `media_kit`/libmpv como integración inicial por detrás de `PlaybackEngine`, conforme a la decisión previa del proyecto. La UI nunca controla directamente libmpv. El wrapper `media_kit_video` puede formar parte de la integración visual, como registra la decisión local, pero no reemplaza el contrato `PlaybackEngine`.

## Alternativas

- FFI directa a libmpv: alternativa solo si un límite reproducible de `media_kit` lo justifica.
- Otro motor: comparar únicamente si el spike F2.1 descubre incompatibilidad funcional, de licencia o rendimiento.

## Consecuencias y aceptación

F2.1 verifica plataforma/licencia/artefactos y F2.2 mide reproducción mock, cierre y recursos. Aprobar el punto de partida no declara rendimiento validado ni autoriza fuentes reales. Pruebas: reproducción/pausa/seek, cambio de fuente preservando posición y liberación de recursos.
