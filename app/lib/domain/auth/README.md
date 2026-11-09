# Authentication contracts

This directory contains toolkit-independent authentication contracts only.
`SecureCredentialStore` exposes access-token read, write, and local deletion
through typed `Result` values. It has no dependency on Flutter, Dio, Drift,
browser callbacks, or AniList OAuth details.

The contract supports the local credential lifecycle required by FR-06, but
does not imply an approved OAuth grant, callback URI, scope, expiry/refresh
policy, or remote revocation behavior. Those remain owner decisions under
ADR-A08. See the [secure-storage adapter](../../data/secure_storage/README.md).
