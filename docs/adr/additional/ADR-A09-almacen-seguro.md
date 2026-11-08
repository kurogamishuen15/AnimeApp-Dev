# ADR-012: Almacén seguro

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Propuesto: puerto común y adaptador específico por plataforma**
- Fecha: 2026-11-08
- Fase propietaria: F1.9
- Requisitos: FR-06, NFR-03, NFR-04, NFR-06

## Contexto

OAuth requiere conservar credenciales sin colocarlas en preferencias ordinarias. F0.1 registró disponibilidad de libsecret en el entorno observado, pero eso no verifica el comportamiento de un adaptador multiplataforma ni de otros destinos.

## Decisión propuesta

Definir un contrato mínimo de guardar, leer y borrar secreto. La composición elige un almacén nativo de la plataforma; dominio y casos de uso no dependen de libsecret. Si el almacén está bloqueado/no disponible, el error se comunica y no se degrada silenciosamente a texto claro.

## Alternativas

- Preferencias ordinarias o archivo plano: no aceptables para credenciales.
- libsecret directo desde dominio: ata el núcleo a Linux.
- Plugin multiplataforma: posible si se verifican seguridad, mantenimiento, licencias y cobertura de destinos.

## Consecuencias

La selección del paquete/adaptador requiere revisar compatibilidad y licencias en F1.9. Android/Windows deberán proveer implementaciones propias antes de declarar soporte.

## Aceptación y verificación

Probar guardar/leer/borrar en entorno objetivo; simular almacén ausente y permisos denegados; asegurar que el error no filtra valores. Verificar que el token no aparece en logs, prefs, fixtures persistentes ni artefactos de build.
