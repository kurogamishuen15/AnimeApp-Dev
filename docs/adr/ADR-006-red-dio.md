# ADR-006: Transporte de red

- Fuente de propuesta: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Propuesto; no consta aprobación formal**. `TECH_DECISIONS.md` también lo marca como propuesta.
- Fase: F1.8 para AniList; F5 para cliente/backend de sincronización si procede.
- Requisitos: FR-05, NFR-06, NFR-08.

## Contexto

La red se restringe a adaptadores; el dominio no importa clientes HTTP. Dio fue propuesto, pero las consultas exactas y necesidades de cancelación deben verificarse.

## Propuesta

Evaluar Dio como cliente de transporte inyectable en el adaptador AniList. No usar interceptores globales para logging de cuerpos o secretos.

## Alternativas

- `package:http`: API simple, evaluar cancelación/requisitos.
- `dart:io`: dependencia directa, con trabajo propio para testabilidad y políticas.

## Consecuencias y aceptación

No agregar el paquete aún. Spike con timeout, cancelación, HTTP/JSON inválidos, cliente falso, redacción de headers, licencia y compatibilidad. Pruebas usan transporte falso sin llamar servicios externos por defecto.
