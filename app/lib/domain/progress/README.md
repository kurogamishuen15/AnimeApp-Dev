# Local progress contract

`ProgressDraft` is an opaque JSON-compatible payload with a caller-supplied
identity. `ProgressDocument` is the persisted/read model and carries the
adapter-assigned UTC write instant. `ProgressRepository` accepts a draft and
exposes local save and lookup only; it does not define anime/episode key
construction, resume behavior, remote sync, or conflicts. `updatedAtUtc` is a
technical write instant, not a domain timestamp or ordering rule.

Payload field names and semantics remain pending owner definition under FR-03,
FR-11, and ADR-A10. In particular, this contract does not turn AniList IDs into
AnimeApp identities or define episode/position/completion rules.
