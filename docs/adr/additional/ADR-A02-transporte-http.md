# ADR-005: Transporte HTTP

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto: Dio; pendiente de F1.8**
- Fecha: 2026-11-08
- Fuente: `TECH_DECISIONS.md`
- Requisitos: FR-05, NFR-06, NFR-08

## Contexto

El cliente AniList requerirá transporte remoto, pero la consulta exacta y el contrato del servicio no están definidos todavía. Dio aparece como propuesta, no como dependencia aprobada.

## Decisión propuesta

Comparar Dio con `package:http` y `dart:io` durante F1.8. Seleccionar solo el transporte que resuelva timeout, cancelación, headers, pruebas y manejo de errores con menor complejidad suficiente. Mantenerlo en adaptador externo.

## Alternativas

- `dart:io`: dependencia mínima, integración y pruebas requieren estructura propia.
- `package:http`: API simple; evaluar cancelación y necesidades reales.
- Dio: propuesta local; evaluar interceptores, cancelación, testabilidad y superficie de dependencia.

## Consecuencias

El dominio depende de un puerto, nunca del cliente HTTP. No se hacen solicitudes a AniList durante F1.1/F1.2.

## Aceptación y verificación

Spike con timeout, cancelación, errores HTTP/JSON y cliente falso; revisar dependencia/licencia/versiones y lockfile. No incorporar hasta aprobar resultado en F1.8.
