# ADR-010: Cliente AniList de lectura

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Requisito aprobado por el plan; contrato y tecnología pendientes**
- Fecha: 2026-11-08
- Fase propietaria: F1.8
- Requisitos: FR-04, FR-05, NFR-08

## Contexto

El plan del MVP incluye cuenta/lista AniList; el roadmap separa un cliente de lectura. Los documentos locales no fijan consultas, campos, límites, paquete de transporte ni versión del API.

## Decisión

Mantener un puerto de lectura AniList separado del dominio y un adaptador que traduzca la respuesta externa a modelos propios. No añadir dependencias ni fijar consultas hasta verificar el contrato vigente y el subconjunto requerido por el producto.

## Alternativas

- Exponer DTO/API externos al dominio: acopla el núcleo a cambios del proveedor.
- Generar cliente desde esquema: evaluar tras confirmar estabilidad, cobertura y licencias del esquema.
- Cliente HTTP manual: viable para un alcance pequeño, con costo de mantenimiento y validación.

## Consecuencias

F1.8 debe identificar consultas mínimas, campos requeridos, paginación/límites, errores y respuestas parciales. La lectura pública que no requiera cuenta y la lectura autenticada deben distinguirse según el contrato verificado.

## Aceptación y verificación

Pruebas de contrato con fixtures controlados, campos ausentes/malformados, error HTTP, límite y timeout. El dominio no importa tipos AniList ni cliente de transporte; pruebas no contactan el servicio real por defecto.
