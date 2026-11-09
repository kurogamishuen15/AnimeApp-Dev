# Secure credential storage

`FlutterSecureCredentialStore` implements the pure Dart
`SecureCredentialStore` contract with `flutter_secure_storage`. It stores only
the AniList access-token value under one internal key; it does not manage OAuth,
refresh, account identity, or token expiry. The settings registry and Drift
database are not used for credentials.

The adapter returns generic typed failures and does not log plugin exceptions
or token values. Empty/whitespace-only values are rejected; accepted values
are preserved exactly. There is no plaintext fallback. `deleteAccessToken`
provides the local deletion operation needed by unlinking; revocation and
stopping authenticated requests are not yet wired because OAuth is not
implemented.

Tests inject a manual in-memory fake. They do not read or write the user's
desktop keyring. The Linux plugin uses libsecret and requires a running Secret
Service keyring at runtime; build and distribution compatibility remain
platform validation items. No credentials, OAuth callback flow, account
session, or live API requests are included.

## Portability

The domain depends only on `SecureCredentialStore` and `Result`. The Flutter
plugin remains in `data/secure_storage`; other platform adapters can implement
the same contract only when those platforms enter scope and their secure-store
behavior is validated.
