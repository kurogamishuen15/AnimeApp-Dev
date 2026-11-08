# ADR-004: Navegación

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto: go_router; pendiente de F3.3**
- Fecha: 2026-11-08
- Fuente: `TECH_DECISIONS.md`
- Requisitos: NFR-06, NFR-10, NFR-12

## Contexto

El scaffold aún no tiene navegación ni pantallas de producto. La navegación prevista debe servir primero en Linux y permitir plataformas posteriores; go_router figura como propuesta.

## Decisión propuesta

Evaluar go_router al iniciar F3.3. Mantener rutas y parámetros en el límite de presentación y no usar navegación como contenedor de reglas de dominio.

## Alternativas

- Navigator de Flutter: dependencias mínimas y control directo, con más estructura manual.
- go_router: propuesta existente; aporta rutas declarativas, a validar para desktop y plataformas previstas.
- Framework de navegación adicional: solo si necesidad demostrable supera complejidad/licencia.

## Consecuencias

No se incorpora paquete de navegación en F1.2. F3 debe cubrir retorno, rutas desconocidas, restauración de estado cuando aplique y accesibilidad del foco.

## Aceptación y verificación

Spike con flujos reales de la fase UI, prueba de deep links si el producto los requiere, retorno/restauración y medición de dependencias por plataforma. Revisar compatibilidad/licencia antes de aceptar.
