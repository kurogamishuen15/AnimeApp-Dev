# ADR-008: Catálogo AniList

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aceptado por el propietario el 2026-11-08 como selección arquitectónica; contrato técnico vigente pendiente de verificación**.
- Fase: F1.8 para lectura de cuenta/lista; búsqueda y ficha visibles al usuario en F4.
- Requisitos: FR-04, FR-05, MVP de búsqueda/ficha; NFR-08.

## Contexto

Los documentos previos pedían cliente AniList de lectura, pero no registraban protocolo GraphQL, cliente propio ni prohibición de generación de código. La lista del propietario resuelve esas omisiones de alcance.

## Propuesta

Consumir AniList GraphQL mediante cliente propio, sin codegen, dentro de un adaptador externo. Mapear respuestas a modelos de dominio y limitar consultas/campos a lo necesario. Este ADR no fija todavía queries ni scopes OAuth.

## Alternativas

- Generar código desde esquema: excluido por la decisión del plan.
- Exponer DTO GraphQL al dominio: rechazado por acoplamiento.
- REST u otro servicio: no sustituye la selección GraphQL del plan sin decisión aprobada.

## Consecuencias y aceptación

En F1.8 verificar documentación/API vigente, consultas mínimas, límites, errores, paginación, datos ausentes y compatibilidad. Usar fixtures y transporte falso; cero codegen en el flujo de build. Las credenciales se manejan según F1.9. Si la API o el mantenimiento no permiten cumplir el alcance, presentar evidencia antes de cambiar la selección.
