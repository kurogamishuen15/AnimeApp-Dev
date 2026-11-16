> ARCHIVO HISTÓRICO — Esta página se conserva como registro de un intento anterior; no describe el runtime actual. Los adaptadores y resolutores de este intento fueron retirados en S0-S (2026-11-16). Consulta el [índice vigente](../README.md) y la [línea base/estado S0-S](../../../../missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).

# AnimeOnline Ninja provider status

## Status: blocked by the site's HTTP response

The standard public request to `https://ww3.animeonline.ninja/` redirected and
then returned HTTP 403 during the 2026-11-14 verification. No search, anime,
episode, or server route could be confirmed with an ordinary public request.
This repository therefore does not register a speculative adapter or invent
endpoint paths. The provider remains disabled until its public pages respond
without a challenge/denial and the route behavior can be verified.

The Aniyomi extension reference points to the site's public DooPlayer routes,
but also contains Cloudflare/VRF handling. Kongroo will not port or enable
interception/challenge logic. A future adapter must pass ordinary HTTPS calls
and return a direct public media URI before it can be enabled.

On 2026-11-15, ordinary GETs to both the older `ww3` host and the upstream
proposed canonical `ww4` host returned HTTP 403. The [public extension PR
#1274](https://github.com/yuzono/anime-extensions/pull/1274) reports that its
own manual verification stops at an interactive Cloudflare
challenge. No retry, challenge route, header impersonation, or alternate access
method was attempted. The current evidence remains `BLOCKED_EXTERNAL`; see the
[S0 evidence matrix](../../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).

No code has been copied. Reference inspected:
[AnimeOnline Ninja extension](https://github.com/yuzono/anime-extensions/blob/master/src/es/animeonlineninja/src/eu/kanade/tachiyomi/animeextension/es/animeonlineninja/AnimeOnlineNinja.kt).
