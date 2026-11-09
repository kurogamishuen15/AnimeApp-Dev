# AniList GraphQL adapter

`AniListClient` is a client-owned, read-only GraphQL adapter. It sends the
minimum user-requested anime search fields through Dio, parses responses into
domain-owned `AnimeSummary`, and returns `Result` with typed errors. It makes
no request at construction, has no authentication or mutation path, and does
not log request/response data.

## Rate and error behavior

- Requests are POSTs with variables, bounded to 1–50 results, and serialized
  per client instance.
- One process-wide rate gate starts at a conservative two seconds (30/minute);
  subsequent `X-RateLimit-Limit` headers adjust spacing across client
  instances. `429` and `Retry-After` become `RateLimitError`; the client never
  retries automatically.
- Timeout, transport, server-unavailable, malformed GraphQL and empty search
  results remain distinguishable. Missing optional titles map to `null`.
- Tests use a real local loopback HTTP server and never call AniList.

`OfflineFirstAnimeCatalog` saves only the most recent explicit search in one
replace-on-write database slot. It falls back only when the same query, page
and result count match, and reports `localCache` plus the refresh error. It
does not prefetch, crawl, or bulk retain catalogue data. Persistent use remains
subject to owner review of current API terms.

## Policy and release status

Current official docs say the nominal limit is 90 requests/minute but note a
temporary degraded limit of 30/minute; they also state that limits can change
during outages ([rate limiting](https://docs.anilist.co/guide/rate-limiting),
[API considerations](https://docs.anilist.co/guide/considerations)). The API
terms prohibit use as a backup/storage service and use in competing,
non-complementary anime/manga list or tracker services
([terms](https://docs.anilist.co/guide/terms-of-use)). AnimeApp's exact
eligibility has not been verified. The adapter is not wired into app startup
or UI; F1.8 verification uses only loopback HTTP.

For portability, keep GraphQL DTO parsing inside `data/anilist`; application
logic consumes the pure Dart `AnimeCatalogRepository` contract. Do not add
code generation, scraping, bulk collection or mutations.
