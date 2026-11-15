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

No code has been copied. Reference inspected:
[AnimeOnline Ninja extension](https://github.com/yuzono/anime-extensions/blob/master/src/es/animeonlineninja/src/eu/kanade/tachiyomi/animeextension/es/animeonlineninja/AnimeOnlineNinja.kt).
