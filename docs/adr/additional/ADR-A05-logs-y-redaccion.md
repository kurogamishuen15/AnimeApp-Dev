# ADR-008: Logs y redacción

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto**
- Fecha: 2026-11-08
- Fase propietaria: F1.7
- Requisitos: NFR-03, NFR-04, NFR-11

## Contexto

El núcleo necesita diagnosticar persistencia, OAuth, solicitudes remotas y sincronización. Los registros no pueden exponer credenciales ni datos sensibles; producción no debe depender de una consola de desarrollo.

## Decisión propuesta

Definir una interfaz de logging inyectable con niveles y campos estructurados, un logger de desarrollo y adaptadores de salida seleccionados por composición. Aplicar lista explícita de campos permitidos o redacción central antes de emitir eventos; nunca registrar cuerpos/headers completos por defecto. No se selecciona paquete de logging aún.

## Alternativas

- `print`/consola directa: bajo costo, sin control uniforme o redacción.
- Logger global mutable: cómodo, pero complica pruebas y aislamiento.
- Paquete estructurado: valorar si satisface formatos, redacción y compatibilidad multiplataforma sin añadir salida persistente innecesaria.

## Consecuencias

Los adaptadores reciben logger por composición. Cada evento tendrá nombre estable, nivel y contexto no sensible. Retención y exportación de logs quedan fuera de F1 hasta que exista requisito explícito.

## Aceptación y verificación

Inyectar valores señuelo para token, código OAuth, cabecera Authorization y datos personales; comprobar automáticamente que no aparecen en ninguna salida. Verificar niveles, formato determinista y que un logger falso permite pruebas sin I/O.
