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
- HTTP and GraphQL 401 errors become `AuthAppError`. Redirects are disabled so
  a search POST is not forwarded to another host.
- Timeout, transport, server-unavailable, malformed GraphQL and empty search
  results remain distinguishable. Missing optional titles map to `null`.
- Tests use a real local loopback HTTP server and never call AniList. Injected
  clock/delay tests cover the 90/minute and 30/minute windows without sleeping.

`OfflineFirstAnimeCatalog` saves only the most recent explicit search in one
replace-on-write database slot. That slot is reused when the query, page
and result count match. A separate detail cache can supply title matches on outage. The repository reports `localCache` plus the refresh error. It
does not prefetch, crawl, or bulk retain catalogue data. The real integration
test closes the loopback server, closes/reopens SQLite, confirms a refused
connection and serves the persistent result offline, then reconnects to a
second loopback server and verifies recovery. No TTL or freshness rule exists:
`cachedAt` is metadata only, and staleness needs an approved product policy.
Image bytes are not stored in SQLite. Persistent use remains subject to owner review of
current API terms.

## Policy and release status

Current official docs say the nominal limit is 90 requests/minute but note a
temporary degraded limit of 30/minute; they also state that limits can change
during outages ([rate limiting](https://docs.anilist.co/guide/rate-limiting),
[API considerations](https://docs.anilist.co/guide/considerations)). The API
terms prohibit use as a backup/storage service and use in competing,
non-complementary anime/manga list or tracker services
([terms](https://docs.anilist.co/guide/terms-of-use)). AnimeApp's exact
eligibility has not been verified. F1.8 originally verified its adapter using loopback HTTP. Current app startup uses the public adapter.

For portability, keep GraphQL DTO parsing inside `data/anilist`; application
logic consumes the pure Dart `AnimeCatalogRepository` contract. Do not add
code generation, scraping, bulk collection or mutations.

## Provider-neutral catalog adapter

`AniListMetadataProvider` adapts the F1.8 `AnimeCatalogRepository` client to
`MetadataProvider` and `PublicAnimeBrowseProvider`. It maps public search,
popular and trending results into provider-neutral metadata without login.
Details use an exact numeric AniList media-ID query rather than treating the
ID as a title search.
The normal `CatalogModule.open()` composition uses this adapter and
`OfflineFirstAnimeCatalog`; `FakeMetadataProvider` is opt-in for tests/demo.
Browse pages are not persisted. Search cache remains one latest explicit
query. This integration is owner-authorized; product eligibility under the
current AniList terms still needs a separate policy review. See
[`catalog-system-audit.md`](../../../../docs/architecture/catalog-system-audit.md)
and [`ADR-A14`](../../../../docs/adr/additional/ADR-A14-catalog-providers-identity.md).

## Integración de Home

`AniListMetadataProvider` adapta el contrato GraphQL legado al modelo `ProviderAnimeMetadata`; no transmite Dio ni DTOs a la presentación. `browseAnime` solicita popularidad o tendencias sin iniciar sesión; detalles consulta IDs exactos. El modelo conserva carátula, banner, descripción, géneros, estado, formato, fechas, temporada, año de temporada, puntuación y popularidad. El romaji existente en `AnimeSummary` también se conserva en el DTO neutral; el año final se deriva de la fecha de fin ya consultada. La imagen llega como URL HTTPS y se carga en Home/ficha con el ImageCache acotado de Flutter y anchos de decodificación apropiados. Las consultas de búsqueda y Home no solicitan el suplemento de ficha. El fixture de loopback prueba transformación y errores; el smoke test externo se ejecuta aparte y no reemplaza esos tests reproducibles.

## Fichas públicas y caché por ID

`AniListClient.searchAnimeById` consulta de forma anónima el ID exacto, con los
campos de cabecera existentes y un suplemento de estudios principales, tráiler,
hasta 12 personajes con voces japonesas, relaciones de tipo anime, total de
episodios y `streamingEpisodes` públicos (título, miniatura y sitio). El códec
`anilist_detail_fields.dart` mantiene el mapeo GraphQL fuera de la UI. Los
resultados de búsqueda y Home conservan su consulta breve.

`AniListMetadataProvider` declara `episodeMetadata` y expone esa lista mediante
el contrato neutral. Las miniaturas HTTP recibidas se normalizan a HTTPS. Ni la
URL de streaming ni el sitio se tratan como una fuente reproducible de Kongroo;
no se inventan títulos o imágenes cuando AniList solo conoce el total.

`OfflineFirstAnimeCatalog` lee primero Drift. Un registro completo de menos de
24 horas evita la solicitud. Los registros creados antes del campo de episodios
se refrescan una vez sin borrar la base. Se comparte un refresco concurrente
por ID y el resultado válido se conserva al fallar la red. La caché es de
demanda, hasta 64 fichas de 512 KiB cada una para admitir series largas. No
guarda archivos de imagen. Se conserva la última búsqueda
exacta y, si el proveedor falla y esa búsqueda no coincide, se permite encontrar
las fichas guardadas por título. HTTP, timeout, cuota y respuesta inválida siguen
sus rutas tipadas. El cliente normal no configura OAuth. TMDB y Kitsu siguen
siendo opciones documentadas sin adaptador activo; un reemplazo debe implementar
`MetadataProvider` y resolver IDs en su propio espacio de nombres.

Desde `app/`, ejecutar `flutter test --no-pub test/data/anilist`. El acceso real
se habilita por separado con `--dart-define=KONGROO_TEST_ANILIST_LIVE=true` y
comprueba, entre otros datos, los episodios públicos de AniList 16498.
