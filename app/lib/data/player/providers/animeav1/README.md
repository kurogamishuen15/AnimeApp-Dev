# AnimeAV1 playback adapter

## Responsibility

`AnimeAv1PlaybackProvider` implements the existing domain
`PlaybackSourceProvider` contract. It searches AnimeAV1's public SvelteKit
catalog data, verifies an exact normalized title match, reads the returned
episode list, and collects the public iframe endpoint from that episode page.
The current JSON route format is decoded locally; remote DTOs stay in `data`.

The resolver accepts only a direct HTTPS `.m3u8` or `.mp4` URL exposed by the
public page/embed. It uses an ordinary HTTP GET and does not execute JavaScript,
solve challenges, handle credentials, or make up a media URL. A host denial is
reported as `unauthorized`, after which `PlaybackProviderManager` may continue
to the next registered provider.

## Files, dependencies, and contract

| File | Responsibility |
|---|---|
| `animeav1_playback_provider.dart` | Search, exact title match, episode extraction, iframe discovery, direct media resolution |
| `../public_site_http.dart` | Bounded HTTPS GETs, host allowlist, typed HTTP failures and public DNS guard |
| `domain/player/providers/PlaybackSourceProvider` | Shared discovery/resolution contract; no engine ownership |

The adapter receives the application's shared Dio client. It owns no persistent
cache, browser session, `Player`, or media_kit resource. Response bodies are
limited to 2 MiB. Only `animeav1.com` and the currently observed public player
host `player.zilla-networks.com` are requested.

## Verification and current limits (2026-11-14)

The public catalog and detail pages returned HTTP 200 during the initial
inspection. The exact page for AniList title `Shingeki no Kyojin` exposed
episodes 1–25 and an iframe on episode 1. A normal GET to that iframe returned
HTTP 403. Kongroo does not retry with alternate headers or otherwise bypass the
denial, so no playable direct stream was verified from AnimeAV1 in this run.
The adapter's `findSources` and resolver must still pass automated tests and a
real Fedora playback attempt before this provider can be called operational.

No source code was copied from the references. The independent implementation
was informed by the current public page payload and the Apache-2.0 Aniyomi
extension reference:
[AnimeAV1 extension source](https://github.com/yuzono/anime-extensions/blob/master/src/es/animeav1/src/eu/kanade/tachiyomi/animeextension/es/animeav1/AnimeAv1.kt).
