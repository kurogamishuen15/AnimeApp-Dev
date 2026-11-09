# F1.9 — Almacén seguro y estado OAuth

Fuente: implementación local, revisión de seguridad de solo lectura y documentación del paquete/AniList
Fecha: 2026-11-09
Módulo: domain/auth y data/secure_storage
Estado: almacén técnico implementado; OAuth y runtime del keyring pendientes
Decisión: usar flutter_secure_storage como adaptador de la selección aprobada ADR-007; no elegir grant/callback
Evidencia: tests fake, analyze, build Linux y enlaces oficiales

## Cambios

- Se añadió un puerto Dart puro `SecureCredentialStore` con lectura, escritura y borrado local del access token.
- `FlutterSecureCredentialStore` usa `flutter_secure_storage 11.2.0`; el paquete bloquea `flutter_secure_storage_linux 3.0.3`. Errores del plugin se convierten en `StorageError` genérico; no hay fallback a Drift, preferencias o archivos.
- Pruebas con fake verifican CRUD, valor vacío, credencial ausente y que la excepción del backend no aparezca en errores.
- `flutter build linux --debug` pasó y compiló el plugin Linux. No se inicializó un daemon ni se leyó/escribió el keyring; runtime disponible/ausente/denegado sigue pendiente.
- Revisión independiente de seguridad confirmó que no se debe reutilizar `SettingsStore`, que FR-06 puede cumplir borrado local sin decidir revocación, y que OAuth continúa sin parámetros aprobados.

## Fuentes vigentes

- [`flutter_secure_storage` en pub.dev](https://pub.dev/packages/flutter_secure_storage): versión consultada 11.2.0, plataforma Linux y licencia BSD-3-Clause.
- [Implementación Linux en pub.dev](https://pub.dev/packages/flutter_secure_storage_linux): utiliza libsecret/Secret Service y requiere servicio de keyring en runtime.
- [Guía oficial de autenticación AniList](https://docs.anilist.co/guide/auth/): describe OAuth2 y ambos Authorization Code e Implicit grants. No se escogió ninguno.

## Verificación

Con Flutter 3.50.0-0.4.pre / Dart 3.14.0 beta:

- `dart analyze lib/domain/auth lib/data/secure_storage test/data/secure_storage`: exit 0, sin issues.
- `flutter test --no-pub test/data/secure_storage`: exit 0, 4 pruebas.
- `flutter build linux --debug`: exit 0.

## Pendiente

- El propietario debe definir grant/cliente, callback/redirect Linux, scopes, expiración/refresh, tratamiento de cancelación y revocación antes de implementar OAuth.
- Ejecutar prueba de runtime Secret Service disponible, ausente y error de permiso solo en un entorno de prueba autorizado; no usar cuentas ni credenciales reales.
- Android/TV/Windows y distribución/Flatpak son posteriores; no hay código de esas plataformas.
- AniList API eligibility sigue pendiente de revisión propietaria antes de activar autenticación o solicitudes en producto.

## Commit

- Commit de cierre F1.9: pendiente al momento de redactar esta sesión.
