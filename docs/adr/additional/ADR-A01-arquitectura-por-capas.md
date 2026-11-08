# ADR-002: Capas y dirección de dependencias

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Principios aceptados; descomposición concreta propuesta para F1.3**
- Fecha: 2026-11-08
- Evidencia: `ARCHITECTURE.md`
- Requisitos: FR-10, NFR-01, NFR-09, NFR-10

## Contexto

La arquitectura registrada separa presentación, aplicación, dominio e infraestructura; las dependencias apuntan a contratos del dominio. El dominio no importa Flutter, UI, proveedores ni infraestructura. Las carpetas aparecen cuando hay responsabilidad real.

## Decisión

Se conservan esos límites como regla. En F1.3 se propone formalizar puertos de repositorio/servicio en el dominio, casos de uso en aplicación y adaptadores concretos en infraestructura. Una feature no importa la UI de otra.

## Alternativas

- Capas por tipo global (todos los widgets/repositorios juntos): difícil de evolucionar por feature.
- Arquitectura hexagonal estricta desde el primer archivo: puede crear abstracciones vacías antes de necesidades reales.
- Separación por responsabilidad con contratos explícitos: mantiene dominio puro sin crear carpetas prematuras.

## Consecuencias

Composición conecta implementaciones; pruebas de dominio no levantan Flutter, base ni red. Los detalles de módulos se aceptan en F1.3/F1.4.

## Aceptación y verificación

Checker automatizado positivo/negativo de imports; revisión del grafo de dependencias; pruebas Dart puras. Ningún código de producto se crea en F1.1/F1.2.
