# ADR-007: Almacenamiento de secretos

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Aceptado por el propietario el 2026-11-08 como selección arquitectónica; integrado para Linux con validación de runtime pendiente**.
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

En F1.9 se integró `flutter_secure_storage 11.2.0` con implementación Linux `flutter_secure_storage_linux 3.0.3` (BSD-3-Clause), aislado detrás de un puerto Dart puro. Con el SDK Flutter beta actual, `flutter build linux --debug` compila el plugin. Las operaciones CRUD, valores vacíos y fallos sanitizados pasan pruebas con fake; no se accedió al llavero real. La validación de runtime Linux (Secret Service disponible/ausente/denegado) y las validaciones de otras plataformas siguen pendientes. Ver [README del adaptador](../../app/lib/data/secure_storage/README.md) y [sesión F1.9](../memory/sessions/2026-11-09-f1-9-secure-storage.md).
