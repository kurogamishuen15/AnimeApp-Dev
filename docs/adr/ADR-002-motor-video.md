# ADR-002: Motor de video

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aprobado como punto de partida** en `TECH_DECISIONS.md`; compatibilidad/rendimiento pendientes.
- Fase: F2.1–F2.2; API interna definida en F2.5.
- Alcance: `media_kit` sobre libmpv detrás de `PlaybackEngine`.

## Contexto

El MVP necesita reproducir un clip mock y cambiar de servidor mock conservando posición. `ARCHITECTURE.md` documenta el flujo de producto previsto: UI → controller → sesión → `PlaybackEngine` → adaptador `media_kit`/libmpv. Esa descripción era el estado al aprobar este ADR; el spike F2.2 existe ahora como entrypoint opt-in y no sustituye la API final de F2.5.

## Decisión

Conservar `media_kit`/libmpv como integración inicial por detrás de `PlaybackEngine`, conforme a la decisión previa del proyecto. La UI nunca controla directamente libmpv. El wrapper `media_kit_video` puede formar parte de la integración visual, como registra la decisión local, pero no reemplaza el contrato `PlaybackEngine`.

## Alternativas

- FFI directa a libmpv: alternativa solo si un límite reproducible de `media_kit` lo justifica.
- Otro motor: comparar únicamente si el spike F2.1 descubre incompatibilidad funcional, de licencia o rendimiento.

## Consecuencias y aceptación

F2.1 verifica plataforma/licencia/artefactos y F2.2 mide reproducción mock, cierre y recursos. Aprobar el punto de partida no declara rendimiento validado ni autoriza fuentes reales. Pruebas: reproducción/pausa/seek, cambio de fuente preservando posición y liberación de recursos.

## Estado de implementación F2.2 (2026-11-09)

El spike aislado en `app/lib/{application,data,app}/player` valida localmente libmpv y no conecta catálogo, Drift, navegación ni progreso. Sus responsabilidades, contratos, pruebas y limitaciones se documentan en los README de módulo y en el [informe F2.2 v2](../player/F2.2-spike-report-v2.md). La API `PlaybackSpikeEngine` del spike es temporal; no es el contrato de producto `PlaybackEngine` y F2.2 no está aceptada ni cerrada. El estado de textura y primer frame del plugin no bastan para probar presentación del compositor; esa evidencia y la revisión de artefactos/licencias siguen pendientes.
