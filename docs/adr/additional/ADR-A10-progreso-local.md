# ADR-013: Progreso local

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Requisito aprobado; persistencia genérica local implementada; modelo/campos y política de producto pendientes**
- Fecha: 2026-11-08
- Fase propietaria: F1.10
- Requisitos: FR-01, FR-03, FR-09, NFR-02, NFR-05

## Contexto

El MVP requiere reanudar episodios y el plan prioriza disponibilidad local. No están definidos todos los campos, claves de identidad, frecuencia de escritura, reglas de conflicto ni relación con AniList.

## Decisión

Mantener el progreso local como fuente disponible offline y exponerlo mediante repositorio tipado. No sincronizarlo automáticamente con AniList ni asumir que los identificadores externos de anime equivalen a la identidad interna hasta definir el mapeo.

## Alternativas

- Guardar solo posición reciente: simple, puede perder historial/estado necesario.
- Guardar un evento por avance: auditable, mayor volumen y complejidad.
- Sincronizar cada escritura directamente: acopla continuidad local a red y puede duplicar operaciones.

## Consecuencias

F1.10 debe definir identidad, campos, semántica de actualización, cadencia de escritura y recuperación tras cierre. La relación con sincronización se especificará en F1.11.

## Aceptación y verificación

Pruebas de guardar/reabrir, actualizar progreso de un episodio, datos ausentes, escritura interrumpida y operación sin red. Medir volumen/latencia con una carga documentada antes de fijar presupuesto numérico.

## Implementación F1.10 (alcance acotado)

Se añadió `ProgressRepository` y `LocalProgressRepository` con payload JSON opaco y clave exacta provista por el llamador. La base reemplaza el payload de la misma clave en un upsert local y asigna `updatedAt` como instante técnico UTC. Tests cubren guardado/reapertura, reemplazo del payload por identidad, ausencia y payload inválido. No se asignaron campos de episodio, posición, porcentaje, finalización, identidad del catálogo ni semántica adicional al tiempo. La aceptación funcional FR-03 queda pendiente hasta que se definan identidad estable anime/episodio y campos; escritura interrumpida y medición de volumen también quedan pendientes.
