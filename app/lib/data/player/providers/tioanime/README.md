# TioAnime playback adapter

## Responsibility

`TioAnimePlaybackProvider` implements the shared
`PlaybackSourceProvider` contract. It queries the public directory, requires an
exact normalized title match, reads the anime's publicly rendered episode
number list, then reads that episode page's declared `videos` entries as server
choices. It never guesses an episode URL from AniList metadata alone: the
episode number must also appear in the provider page's `episodes` array.

Resolution supports direct HTTPS `.m3u8`/`.mp4` endpoints and media URLs
explicitly embedded in ordinary HTML/JWPlayer source declarations. It does not
execute site JavaScript or decrypt/solve any host challenge. Unsupported
embed formats return a typed unsupported result; HTTP 401/403, quota errors,
and timeouts remain typed so the manager can try another provider.

## Files, dependencies, and contract

| File | Responsibility |
|---|---|
| `tioanime_playback_provider.dart` | Public title search, episode list, server candidates and direct media extraction |
| `../public_site_http.dart` | Bounded HTTPS GETs, host allowlist, typed errors and DNS guard |
| `domain/player/providers/PlaybackSourceProvider` | Shared provider contract; no Flutter or engine dependency |

The adapter receives the app's shared Dio client and owns no socket pool,
browser state, local cache, `Player`, or media_kit resource. It sends no cookies
or credentials. The host allowlist currently covers TioAnime and the server
domains observed in its episode page.

## Verification and current limits (2026-11-14)

An ordinary request to TioAnime's public directory returned a real exact match
for `Shingeki no Kyojin`; its anime page listed 25 numbered episodes, and the
provider's episode 1 page exposed five named server endpoints. One observed
YourUpload embed page returned an MP4 URL, but a normal HEAD request to that
URL returned HTTP 500. StreamSB timed out and the OK.ru embed page did not
expose a direct media URL in its public HTML. Therefore search and episode
discovery were observed live, but a playable TioAnime stream was **not**
verified. The adapter does not claim this provider is operational until a real
Fedora playback succeeds.

No source code was copied. The adapter behavior was informed by the current
public pages and the Apache-2.0 Aniyomi extension reference:
[TioAnime extension source](https://github.com/yuzono/anime-extensions/blob/master/src/es/tioanimeh/src/eu/kanade/tachiyomi/animeextension/es/tioanimeh/TioanimeH.kt).
