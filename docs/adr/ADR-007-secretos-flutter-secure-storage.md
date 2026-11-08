# ADR-007: Almacenamiento de secretos

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aceptado por el propietario el 2026-11-08 como selección arquitectónica; validación por plataforma pendiente**.
- Fase: F1.9.
- Requisitos: FR-04, FR-06, NFR-03, NFR-04, NFR-06.

## Contexto

OAuth AniList requiere guardar y borrar credenciales. F0.1 observó libsecret disponible en el entorno, pero no verificó Flutter Secure Storage ni otros sistemas operativos.

## Propuesta

Usar `flutter_secure_storage` como adaptador detrás de un contrato de almacén seguro. Dominio y casos de uso no dependen del plugin. Si el almacén está indisponible, se informa error y nunca se degrada a texto claro.

## Alternativas

- Plugin multiplataforma alternativo sujeto a auditoría equivalente.
- Adaptadores nativos por plataforma detrás del mismo puerto.
- Preferencias/archivo plano: no aceptables para tokens.

## Consecuencias y aceptación

En F1.9, antes de integrar: comprobar mantenimiento, licencias y mecanismos de cada plataforma; probar guardar/leer/borrar, almacén bloqueado/ausente, redacción y que el token no aparece en prefs, logs, fixtures o artefactos. La selección está aprobada; la integración depende de resultados satisfactorios.
