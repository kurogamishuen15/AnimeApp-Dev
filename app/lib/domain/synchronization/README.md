# Synchronization contract

`SyncRemote` accepts an opaque `SyncEnvelope` and returns a request receipt via
typed `Result`. The domain has no Supabase dependency and the contract does not
make local startup or local reads depend on a remote service.

The envelope's request identifier and payload are supplied by the caller. This
contract intentionally does not define a persistent change identity, dedupe
semantics, conflict winner, ordering, deletion, retry cadence, upload fields,
authentication, or video storage. Those choices remain pending under ADR-A11
and must be explicit before implementing real synchronization.

`FakeSyncRemote` is an in-memory test adapter only. It records immutable deep snapshots of JSON requests
and can return a scripted typed result; it does not emulate a server, retain
remote data, deduplicate requests, or resolve conflicts. No Supabase connection
or deployment configuration exists in this subphase.
