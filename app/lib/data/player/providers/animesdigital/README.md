# AnimesDigital episode source

## Responsibility and status

`AnimesDigitalPlaybackProvider` maps an exact anime title to the public
AnimesDigital index, finds the requested numbered episode, and reads the
supported first player's direct HLS link. It is an `EpisodeSourceAdapter`; it
does not resolve host protocols, own libmpv, or render the player. The HLS
candidate goes through the shared `DirectMediaHostResolver` and the existing
`PlaybackProviderManager`/player route.

The provider is registered as version `1.0.0`. Its state is `candidate` until
real Fedora playback and visual presentation have been verified. The source
site labels are Portuguese; this adapter leaves audio/subtitle language as
`unknown` because the page does not reliably establish the stream language.

## Files and contracts

| File | Responsibility |
|---|---|
| `animesdigital_playback_provider.dart` | Bounded same-origin GETs, exact-title matching, lazy episode lookup, typed failures, cancellation and source construction. |
| `animesdigital_html_parser.dart` | Pure parsing of same-origin anime links, numbered `/video/` links, pagination and the supported `api.anivideo.net/videohls.php` iframe's `d` value. |
| `../../../../domain/player/providers/episode_source.dart` | Shared `SourceAnimeMatch` and `EpisodeRef` contracts. |
| `../hosts/direct_media_host_resolver.dart` | Shared HLS/MP4/DASH normalizer; not duplicated here. |

Dependencies are the already-present Dio package and Dart SDK. No new package,
WebView, cookies, login, JavaScript execution, challenge handling or player
engine is introduced. HTTP is a data-layer adapter, so Linux, Android and
Windows share the same implementation; Android/Windows builds remain to be
verified separately.

## Network, errors and resource limits

- Search uses up to three AniList title aliases and only accepts an exact
  normalized title; it does not silently play fuzzy matches.
- Episode lookup fetches pages sequentially and stops once the requested number
  is found. One operation is limited to 32 catalog pages, 2 MiB per HTML
  response, 16 MiB total catalog bytes, three same-origin redirects, bounded
  connect/send/receive and stream-idle timeouts, and a shared 20 second deadline
  across all of its HTTP requests. The deadline cancels trickling responses and
  prevents slow pagination or title aliases from multiplying the wait.
- Redirects to a different origin, HTTP media URLs, credentialed links, embeds
  other than the supported first player, and unrecognized media formats are
  rejected. No cookies, authorization headers or signed values are logged.
- The current parser allowlists only the CDN hostname observed in ordinary
  live playback. If the provider publishes a new media origin, verify that
  origin independently and update the explicit parser allowlist before
  enabling it; do not accept arbitrary HTTPS hosts from page markup.
- Provider errors preserve `forbidden`, `notFound`, `rateLimited`, `timeout`,
  `blocked`, `invalidResponse`, `unsupportedEmbed` and `cancelled` distinctions.
- The composition root uses source-cache TTL zero because a direct HLS link may
  expire without an explicit expiry field.
- `close()` is idempotent and closes only a Dio client created by this adapter.

## Tests and live verification

Offline parser, loopback HTTP, cancellation, body-size, redirect, typed-error
and manager-to-resolver tests:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/animesdigital \
  test/data/player/providers/playback_providers_module_test.dart
```

The integration is not tested through `flutter test` for live HTTP because its
test binding intentionally intercepts `HttpClient`. Use the project-local live
harness from `app/` instead:

```bash
../.ai-local/toolchains/flutter/bin/dart run tool/animesdigital_live_harness.dart
```

It prints only provider, episode, host, format and manifest facts, never the
full media URL. A real libmpv/display check uses the existing application
player and the opt-in steps recorded in `TESTING.md`.

## Upstream and limits

The implementation is written in Dart against the public page flow described
in GoAnime v2.0.0's AnimesDigital source. No upstream source file is copied.
See [upstream source](https://github.com/alvarorichard/Goanime/blob/v2.0.0/internal/scraper/providers/animesdigital/client.go)
and [package docs](https://pkg.go.dev/github.com/alvarorichard/Goanime/v2@v2.0.0/internal/scraper/providers/animesdigital).
Those references establish the observed parser flow and upstream license; they
do not establish current availability or rights to any video. The adapter
supports only the public player that exposes direct HLS. The alternate
Blogspot route is unsupported. A returned URL or HTTP 200 is not proof of
playable video; visual libmpv evidence is tracked separately in the S0-S report.
