# Cuenta opcional y autorización

La app y los datos locales no dependen de autenticación. `SecureCredentialStore` es solo un puerto/adapter de credenciales y no implementa OAuth. F1.9 sigue abierta: no hay login, callback URI, sesión, token refresh/revocation o prueba de keyring real.

El futuro debe mantener separados:

```text
PublicMetadataProvider (lectura pública)
OptionalAccountAuthentication (consentimiento y token)
AniListListSyncAdapter (mutaciones/lista; sync explícita)
LocalLibraryRepository + PlaybackProgressRepository (fuente operativa local)
```

La documentación primaria AniList dice:

- las consultas a metadatos públicos no requieren cuenta;
- no hay scopes OAuth;
- tokens duran un año y no hay refresh tokens;
- Implicit Grant devuelve `access_token` dentro del fragmento de URL; el cliente recupera el fragmento;
- Authorization Code requiere un secreto de aplicación que no puede incrustarse en cliente público Linux/Android.

La app no debe abrir login automáticamente. Logout/desvincular elimina la credencial local pero jamás borra biblioteca, identidad o progreso. Cambios a lista remota requieren consentimiento y sync manual explícitos; no se implementa outbox de lista en este cambio.

Los términos actuales AniList prohíben integrar sus datos en servicios competidores no complementarios de lista/seguimiento. Hasta que el propietario confirme la elegibilidad de AnimeApp/Kongroo, no se implementa ni activa OAuth/sync AniList. Esta decisión es un bloqueo operativo documentado, no una afirmación legal sobre el producto.

Fuentes: [AniList Auth](https://docs.anilist.co/guide/auth/), [Implicit Grant](https://docs.anilist.co/guide/auth/implicit), [Terms](https://docs.anilist.co/guide/terms-of-use), [ADR-A08](../adr/additional/ADR-A08-oauth-anilist.md). No se registraron aplicaciones OAuth, usaron credenciales reales o enviaron requests a cuentas personales.
