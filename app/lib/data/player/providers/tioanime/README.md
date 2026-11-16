# TioAnime playback adapter

> **Estado tras la limpieza S0 (2026-11-15): retirado.** El archivo Dart del
> adaptador ya no existe ni está registrado. El resto de esta página conserva
> el diseño y la evidencia histórica de ese intento; no describe código activo.
> No se confirmó reproducción externa. Ver la
> [auditoría de limpieza](../../../../../../docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md)
> y la [auditoría de hosts](../../../../../../docs/ai-system/audits/S0-video-host-audit-2026-11-15.md).

## Responsibility

`TioAnimePlaybackProvider` implements only anime discovery. It queries the
public directory, requires an exact normalized title match, reads the anime's
public episode number list, then reads that episode page's `videos` entries as
server choices. It declares `sourceAlternatives` because one episode can
publish multiple hosts. It never guesses an episode URL from AniList metadata
alone: the episode number must appear in the provider's `episodes` array.
`PublicMediaVideoHostResolver` owns host-specific media resolution.

## Files, dependencies, and contract

| File | Responsibility |
|---|---|
| `tioanime_playback_provider.dart` | Public title search, episode list and host alternatives |
| `../video_hosts/public_media_video_host_resolver.dart` | Shared static embed/media resolution and redirect validation |
| `../public_site_http.dart` | Bounded HTTPS GETs, host allowlist, typed errors and DNS guard |
| `domain/player/providers/PlaybackSourceProvider` | Shared provider contract; no Flutter or engine dependency |

The adapter receives the app's shared Dio client and owns no socket pool,
browser state, local cache, `Player`, or media_kit resource. It sends no cookies
or credentials. The episode 1 inventory observed `mega.nz` (Mega),
`embedsb.com` (StreamSB), `yourupload.com` (YourUpload), `ok.ru` (OK.ru), and
`hqq.tv` (Netu). FileStream, Bee and Goma were not present among those five
alternatives; this does not establish they are absent from every episode.

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

## S0 live recheck (2026-11-15)

`sourceAlternatives` is declared, and a manager-level fixture proves that all
returned choices are accepted. The opt-in Fedora run found the same five hosts.
Mega, OK.ru and Netu returned `Unsupported`; StreamSB timed out; a later
YourUpload resolution produced a network error before a URI. An earlier attempt
resolved a URI, but libmpv reported an error at position 0. No first frame,
audio, seek, or external playback was verified. The sanitized output is in
`.ai-local/review/s0-real-playback-2026-11-15/tioanime-live-smoke-final-sanitized.log`;
see the [S0 evidence matrix](../../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md)
for the current status.

The shared resolver was re-run once against each of the five distinct choices
after bounded embed redirect support was added. The results were
Mega/OK.ru/Netu `unsupported`, StreamSB `timeout`, and YourUpload `network`; no
candidate opened in libmpv. Quality labels are not counted as hosts.
