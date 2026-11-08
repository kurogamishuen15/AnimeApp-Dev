# ADR-009: Ajustes y configuración

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto**, catálogo pendiente de F1.5
- Fecha: 2026-11-08
- Fase propietaria: F1.5
- Requisitos: FR-02, NFR-02, NFR-05

## Contexto

El roadmap requiere un registro de ajustes antes de integrar persistencia. El plan no enumera todavía preferencias, valores predeterminados ni sensibilidad de cada campo.

## Decisión propuesta

Modelar ajustes como valores tipados detrás de un contrato local-first. Persistir solo opciones explícitamente aprobadas; distinguir valores predeterminados de valores guardados y versionar cambios que requieran migración. No guardar tokens OAuth en este almacén.

## Alternativas

- Acceder a preferencias directamente desde UI: mezcla presentación y almacenamiento.
- Guardar cualquier estado en un mapa genérico: sin esquema ni garantías de migración.
- Persistir cada ajuste en tabla dedicada: válido si las consultas/migraciones lo justifican.

## Consecuencias

F1.5 debe acordar catálogo, tipo, valor predeterminado, alcance de sincronización y política de migración de cada ajuste. Este ADR no fija nombres de preferencias inexistentes.

## Aceptación y verificación

Una prueba debe leer valores iniciales sin red, guardar/leer/reiniciar, tratar versión antigua y rechazar tipos inválidos. Cada campo debe tener propietario y clasificación antes de persistirse.
