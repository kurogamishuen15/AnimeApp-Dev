# Anime detail presentation

## Responsibility

This module renders the shared cinematic detail header, internal tab strip, and
the currently available tab content. It owns no catalog, library, playback,
network, or database rules.

## Main files and contracts

- `anime_detail_header.dart` composes the real banner/cover URLs, title,
  romaji title, format, year, score, genres, synopsis, and approved actions.
- `anime_detail_tabs.dart` owns the lightweight horizontal tab navigation.
- `anime_detail_tab_content.dart` presents available information and explicit
  empty states for data not supplied by the current provider.
- `../anime_detail_page.dart` loads the view model through `CatalogService`,
  manages local library status (including completed confirmation), and saves
  existing local playback progress.
- `../catalog_home_page.dart` keeps detail navigation inside the existing
  shell so the approved desktop rail and mobile navigation remain mounted.

Data enters as `ProviderAnimeMetadata`, `LibraryEntry`, and
`PlaybackProgress`. UI widgets do not import Dio, GraphQL DTOs, Drift, or the
video engine. AniList remains a public, unauthenticated source for optional
metadata; the local library and progress remain user-owned data.

## Current content and platform behavior

The header uses AMOLED black, system typography, the existing purple accent,
and progressive bottom/side image gradients. It scales the poster and banner
decode sizes to their displayed width. Missing or failed images keep the
layout intact. Wider layouts use a 400 px composition with a 188×300 poster at
the upper-left content line; the title, metadata, genre chips, actions, and
short synopsis share that cinematic layer. Phone layouts use a 350 px
composition with a 96×154 poster, compact metadata to its right, and a
three-line synopsis below. These values are presentation parameters rather
than catalog rules. TV currently follows the wide variant until an approved
TV-specific reference exists. The global sidebar/header/bottom navigation is
not reconfigured by this module.

The approved-reference registry is
[`docs/ui/ANIME_DETAIL.md`](../../../../../docs/ui/ANIME_DETAIL.md). Its original
temporary attachment paths are retained there. The files were no longer
available on 2026-11-15, so automated geometry checks do not constitute a
pixel-fidelity claim.

Information and alternative titles use available AniList values. The gallery
shows only the real cover and banner URLs currently present in metadata. Cast
and relationship tabs display the public characters, voices, and anime
relations supplied by the catalog, with an empty state when absent. The
episode tab builds a lazy responsive grid from the public episode index. Where
AniList publishes `streamingEpisodes`, the grid also shows the real provider
title and thumbnail; a separate lazy list exposes validated HTTPS external
pages with a copy action. AniList documents these as legal streaming links on
external sites. They are not direct media sources: Kongroo never passes them
to libmpv. If an internal provider receives HTTP 403, the UI points the user to
these links when available. The playback manager also continues to the next
configured provider after a provider failure; optional Wikimedia and
user-defined entries remain subject to their enablement/configuration.
Playback in the existing player is available only when a provider returns a
supported media source. Existing saved progress remains editable only for a
local-library item and is not attributed automatically to a selected episode.

Loading keeps the back affordance available. Provider and local persistence
errors are shown inline. Missing optional fields are omitted. State changes
are written through `CatalogService`; manually marking Completed retains the
existing confirmation flow.

## Extension points

The tabs and content widgets accept the normalized episode/detail models
without coupling views to AniList. Layout
variants can be added through presentation configuration for Lite,
Minimalista, desktop, phone, and TV while retaining the same service and
domain contracts. No full personalization editor is included.

## Tests and limits

`app/test/catalog/anime_detail_external_streaming_links_test.dart` verifies
external-page display and the copy callback. `app/test/widget_test.dart`
verifies the shell remains mounted, numbered episode cards are lazy, library
state and completion confirmation remain functional, and the header/poster geometry fits phone 390×844 and desktop
1280×960 test sizes without layout exceptions. Loopback tests
cover titles/thumbnails and persistent cache. The opt-in AniList smoke test
verifies real episode metadata without OAuth; it is kept separate from the
reproducible suite. Fedora visual validation is recorded separately.

Playback reuses `PlaybackProviderManager`, the existing source-switch service,
and `SpikePlayerModule`/media_kit engine; it remains unavailable when no
provider returns a direct stream. Episode-level watch tracking, a third-party
gallery, trailer playback, and navigation along related titles remain outside
this increment.

The page loads the local snapshot and updates its state independently from
library/progress. The existing error area offers a metadata retry. The gallery
still uses the cover and banner URLs, and image bytes are cached in memory.
