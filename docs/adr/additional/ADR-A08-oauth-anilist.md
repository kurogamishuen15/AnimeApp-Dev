# ADR-011: Autorización de cuenta AniList

> Colección adicional: análisis complementario de la primera pasada; no pertenece a las 14 decisiones originales ni implica aprobación formal. Ver [índice](../README.md).


- Estado: **Requisito aprobado; flujo concreto pendiente de investigación y aprobación**
- Fecha: 2026-11-08
- Fase propietaria: F1.9
- Requisitos: FR-04, FR-06, NFR-03, NFR-04

## Contexto

El MVP requiere vinculación AniList y el roadmap prevé OAuth/almacén seguro. Los documentos locales no especifican tipo de cliente, flujo, scopes, callbacks, expiración, renovación ni revocación. No se deben inventar ni copiar parámetros sin verificar documentación primaria actual.

## Decisión

Separar autorización de la lógica de dominio mediante puertos de inicio, callback, renovación/desvinculación y almacén de credenciales. El flujo y scopes quedan **pendientes** hasta una investigación de la documentación oficial de AniList y del modelo de aplicación por plataforma.

## Alternativas

- Flujo OAuth interactivo con navegador del sistema, si el proveedor lo soporta para cliente nativo.
- Flujo de cliente confidencial con servidor propio, que requeriría backend fuera del alcance actual.
- No vincular cuenta, lo que no satisface el alcance del MVP pero mantiene modo local.

## Consecuencias

No se implementa OAuth en F1.1/F1.2. F1.9 documentará redirect, PKCE/secretos, scopes mínimos, estados de error y desvinculación solo con evidencia vigente. No se incorpora secreto de cliente al binario.

## Aceptación y verificación

Antes de implementación: citar documentación primaria vigente, demostrar el flujo compatible con app nativa, restringir permisos a lectura requerida, probar cancelación/error/callback inválido y confirmar que desconectar borra credenciales. Revisión de seguridad antes de aprobar.

## Investigación F1.9 (sin decisión de flujo)

La [guía oficial de autenticación](https://docs.anilist.co/guide/auth/) describe OAuth2 y tanto Authorization Code Grant como Implicit Grant. Esto confirma alternativas soportadas por el proveedor, pero no selecciona una para AnimeApp ni define cliente nativo, redirect/callback, scopes, expiry/refresh, cancelación o revocación. No se incorporó OAuth ni se creó una sesión.
