# ADR-007: Errores y resultados

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto**
- Fecha: 2026-11-08
- Fase propietaria: F1.7
- Requisitos: FR-07, FR-09, NFR-08, NFR-11

## Contexto

La arquitectura reserva errores y resultado para `core`. El dominio debe distinguir fallos recuperables, validación, falta de conexión y cancelación sin depender de Flutter o de excepciones de una biblioteca de red/base de datos.

## Decisión propuesta

Definir tipos Dart puros para resultados de casos de uso y errores semánticos estables. Adaptadores traducen excepciones técnicas a esos tipos y conservan causa diagnóstica acotada, sin exponer secretos. La cancelación se representa explícitamente donde una operación pueda cancelarse. No se selecciona aquí un paquete externo.

## Alternativas

- Propagar excepciones de cada biblioteca: simple inicialmente, pero acopla capas y dificulta manejo uniforme.
- Devolver `null`/booleanos: no distingue causas ni permite recuperación consistente.
- Adoptar un paquete Result: posible si el spike demuestra una ventaja; añade dependencia y compatibilidad por validar.

## Consecuencias

Los casos de uso deben enumerar errores que la UI o sincronización puedan manejar. Errores inesperados aún requieren diagnóstico interno redactado. El diseño exacto de tipos se implementa en F1.7.

## Aceptación y verificación

Probar éxito, validación, no encontrado, desconexión, timeout, cancelación y fallo inesperado; verificar que no se pierdan causas útiles ni se filtren datos sensibles. Las pruebas deben ejecutarse sin Flutter y sin servicios reales.
