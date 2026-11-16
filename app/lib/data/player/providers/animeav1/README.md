# AnimeAV1 playback adapter

> **Estado tras la limpieza S0 (2026-11-15): retirado.** El archivo Dart del
> adaptador ya no existe ni está registrado. El resto de esta página conserva
> el diseño y la evidencia histórica de ese intento; no describe código activo.
> No se confirmó reproducción externa. Ver la
> [auditoría de limpieza](../../../../../../docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md)
> y la [auditoría de hosts](../../../../../../docs/ai-system/audits/S0-video-host-audit-2026-11-15.md).

## Responsibility

`AnimeAv1PlaybackProvider` implements the existing domain
`PlaybackSourceProvider` contract. It searches AnimeAV1's public SvelteKit
catalog data, verifies an exact normalized title match, reads the returned
episode list, and collects the public iframe endpoint from that episode page.
The current JSON route format is decoded locally; remote DTOs stay in `data`.

The adapter returns only the public iframe as a server alternative. The shared
`PublicMediaVideoHostResolver` owns direct media extraction and host validation.
It uses ordinary HTTPS requests and does not execute JavaScript, solve
challenges, handle credentials, or make up a media URL. A host denial is
reported as `unauthorized`, after which the manager may try another server or
provider.

## Files, dependencies, and contract

| File | Responsibility |
|---|---|
| `animeav1_playback_provider.dart` | Search, exact title match, episode extraction and iframe discovery |
| `../video_hosts/public_media_video_host_resolver.dart` | Shared static embed/media resolution, redirect and stream validation |
| `../public_site_http.dart` | Bounded HTTPS GETs, host allowlist, typed HTTP failures and public DNS guard |
| `domain/player/providers/PlaybackSourceProvider` | Anime discovery contract; no host or engine ownership |

The adapter receives the application's shared Dio client. It owns no persistent
cache, browser session, `Player`, or media_kit resource. Discovery response
bodies are limited to 2 MiB. Its observed hosts are `animeav1.com` and
`player.zilla-networks.com`; resolver behavior and limits are in the shared
video-host README.

## Verification and current limits (2026-11-14)

The public catalog and detail pages returned HTTP 200 during the initial
inspection. The exact page for AniList title `Shingeki no Kyojin` exposed
episodes 1–25 and an iframe on episode 1. A normal GET to that iframe returned
HTTP 403. Kongroo does not retry with alternate headers or otherwise bypass the
denial, so no playable direct stream was verified from AnimeAV1 in this run.
The adapter's `findSources` and shared resolver must pass automated tests and a
real Fedora playback attempt before this provider can be called operational.

No source code was copied from the references. The independent implementation
was informed by the current public page payload and the Apache-2.0 Aniyomi
extension reference:
[AnimeAV1 extension source](https://github.com/yuzono/anime-extensions/blob/master/src/es/animeav1/src/eu/kanade/tachiyomi/animeextension/es/animeav1/AnimeAv1.kt).

## S0 live recheck (2026-11-15)

The public root returned HTTP 200. A live lookup for `Shingeki no Kyojin`,
episode 1, returned one public embed source, but resolving it returned
`unauthorized` before Kongroo received a URI to open. The denial was not
retried or bypassed. A new opt-in smoke test requires
both advancing position and non-zero decoded video dimensions; the current
live attempt failed and does not mark the provider operational. See the
[S0 evidence matrix](../../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md)
and sanitized output under `.ai-local/review/s0-real-playback-2026-11-15/`.
The shared video-host resolver still classifies the Zilla embed denial as
`unauthorized`. No direct media URI reached libmpv, and no retry or challenge
handling was added.
An upstream [AnimeAV1 issue](https://github.com/yuzono/anime-extensions/issues/1111)
reports an HLS segment 403 associated with `Sec-Fetch-Site`. Kongroo does not
forge browser fetch-metadata headers to get past the denial; this remains an
external access limitation unless the host documents a supported client flow.
