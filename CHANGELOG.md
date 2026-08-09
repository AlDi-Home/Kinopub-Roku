# Changelog

All notable changes to this project are documented in this file.

## 0.5.3 - 2026-08-08

### Added
- Video detail screen: the hero description text is now focusable (Up from the first action button). Pressing OK on it opens a full-text overlay ("semiwindow") since the inline hero text is truncated to a few wrapped lines; Back/OK closes it and returns focus to the hero, following the same "dialog never takes real focus" pattern already used for the bookmarks overlay.

### Changed
- Video detail screen: technical info row text is smaller (16px, was default size) with a bit more line spacing headroom, leaving a visible gap between the last line and the bottom of the screen instead of running flush to the edge.

## 0.5.2 - 2026-08-08

### Removed
- Comments/reviews ("Отзывы") row from the video detail screen — this functionality is deprecated on the main KinoPub site. Removed the row renderer and its lazy-load wiring from `VideoDetailScreen.brs`, the `loadItemComments` task command from `ContentTask.brs`, and `kinoItemComments`/its normalize helpers from `KinoItemService.brs` (added last round, now unused). The recommendations rail, ratings row, and tech info row are unaffected.

## 0.5.1 - 2026-08-08

### Fixed
- Video detail screen: the "Сезоны"/"Похожее" row headings no longer overlap the first tile when it pops into focus. Regressed from an earlier fix when the seasons row's layout was generalized into the shared rail-row builder for Stage 2 (recommendations reused it too, with the same too-tight clearance).

## 0.5.0 - 2026-08-08

Video detail screen — Stage 2: recommendations, ratings, technical info, and comments, all in a new scrollable content row list below the hero (seasons tiles included, generalized from Stage 1's single-purpose seasons row).

### Added
- Recommendations rail ("Похожее") — reuses `item.similarItems`, already loaded but unused since Stage 1. Selecting one reloads the screen on that item.
- Ratings row — IMDb / Kinopoisk / KinoPub score boxes, only showing the ratings actually present. `KinoItemService.brs` now exposes `imdbRating`/`kinopoiskRating`/`kinopubRating` as separate fields (previously only folded into a joined string), matching a pattern already used by three other services.
- Technical info row — genres/quality/tracks/etc. from the existing `item.detailFacts`, translated to Russian for display.
- Comments row — a new `/v1/items/comments` integration (`KinoItemService.brs`'s `kinoItemComments`, a new `loadItemComments` task command), showing a flat, read-only list (avatar, name, rating, message) loaded lazily after the main page renders. No threading, no pagination.
- The seasons row, recommendations row, ratings, info, and comments now live in one continuously scrollable region below the hero (Down from the action buttons reaches it regardless of whether the item has seasons at all) instead of Stage 1's seasons-only, series-only row.

### Excluded
- Cast/crew rail — no photos available from the API (confirmed earlier), low payoff as text-only chips.
- Comment threading/replies, comment pagination, posting/replying — read-only flat list only.

## 0.4.6 - 2026-08-08

### Fixed
- Video detail screen: the backdrop image now stays fixed as a true static page background instead of scrolling off along with the foreground content. Scrolling into the episode list previously moved the backdrop up with everything else, so once scrolled its bottom edge no longer reached the bottom of the screen, exposing the flat app background underneath the lower episode rows.

## 0.4.5 - 2026-08-08

### Changed
- Video detail screen: single-season serials now show the season tile row first (like any multi-season serial), instead of jumping straight into the episode list. The season-tile gate is now "is this a real series" (has season data at all) rather than "has more than one season" — a movie still skips straight to its Play button.
- Entering the episode list (via a season tile) now scrolls the whole page up, not just the small list viewport below a permanently pinned hero — the hero moves off-screen and the episode list gets nearly the full screen instead of a ~284px strip. Leaving the episode list (Up at the top row, or Back) scrolls it back down.

## 0.4.4 - 2026-08-08

### Fixed
- Video detail screen: removed the two visible dark seams in the backdrop scrim. They were caused by stacking three semi-transparent flat rectangles to fake a vertical gradient — Roku's `Rectangle` has no native gradient, and the rectangles' overlap zones compounded to a visibly darker band at each boundary. Replaced with a single pre-rendered gradient PNG (`images/ui/backdrop-scrim.png`) stretched over the backdrop, giving a smooth, seamless darken-toward-the-bottom effect.

## 0.4.3 - 2026-08-08

### Fixed
- Video detail screen: the "Сезоны" heading no longer overlaps the first season tile when it pops into focus (moved the heading up and the tile row down slightly for clearance).
- Down on a season tile no longer jumps into that season's episode list — episodes are only entered via OK on a tile now (Down is reserved for future below-the-fold content, not yet built).
- Back from an episode list reached via a season tile now returns to the seasons row instead of leaving the detail screen entirely.

## 0.4.2 - 2026-08-08

### Changed
- Video detail screen: the backdrop now fills the entire screen instead of just the top band, with a 3-step scrim darkening toward the bottom for readability. Episode rows are semi-transparent with light text, sitting directly on the backdrop. Season tiles use a lighter "frosted glass" backing rather than full transparency, since their title text (from the shared `PosterCard.brs` component used by every grid in the app) is hardcoded dark and needs some opaque backing to stay legible.

## 0.4.1 - 2026-08-08

### Changed
- Redesigned the video detail screen (VideoDetailScreen) to match the light theme: a full-bleed backdrop hero (title, description, genre/quality badges, and a Play/Trailer/Bookmark action stack) replaces the old dark split-panel layout. Seasons now show as poster-card tiles with a red unwatched-episode-count badge and a green checkmark once a season is fully watched, matching the styling already used for Continue Watching's "New Episodes" rail. Selecting a season opens its episode list, auto-focused on the first unwatched episode.
- The Play button label now reflects the currently selected episode (e.g. "Смотреть S2E6") instead of a static "Play".

### Removed
- Dropped the modal "read full description" overlay (the hero shows a few wrapped lines directly instead), the "Similar" recommendations rail, and the detailed technical-info panel from the detail screen — candidates for a later pass. Actor/cast photos were considered and intentionally not implemented: KinoPub's API only returns flat comma-separated name strings, no photo URLs.

### Added
- Settings screen (the gear pill-nav tab), replacing the temporary dev-fonts placeholder:
  - Account summary: display name, username, subscription status/days-left/end date, registered date, app version.
  - Device settings (`KinoDeviceService.brs`, new `loadDeviceSettings`/`updateDeviceSetting` task commands, per KinoAPI's `/v1/device/{id}/settings`): 4K support toggle, server selection, and streaming-type selection, saved immediately and resynced from the server if a save fails.
  - Sign out, reachable for the first time since the light-theme redesign — no screen exposed it until now.

## 0.3.32 - 2026-08-08

Light-theme redesign: replaces the dark, left-rail `HomeScreen` navigation with a light theme and a top pill-based navigation bar, splitting each section into its own dedicated screen. The legacy `HomeScreen` remains in the codebase (used as a functional reference during the port) but is no longer reachable from the UI.

### Added
- `PillNavBar` top navigation (Поиск / Фильмы / Сериалы / Мои / Библиотека / ТВ / Settings), replacing the old left-rail tab list.
- `ContinueScreen` ("Мои"): Continue Watching + New Episodes rails on the new light theme.
- `BrowseScreen`, shared by three tabs:
  - Фильмы / Сериалы: fixed content type, left-side "Свежие / Горячие / Популярные" shortcuts (KinoPub's shortcut endpoints).
  - Библиотека: a Тип / Жанр / Страна / Год / Статус filter bar (combined filters, e.g. Movies + 1990s + Australia at once) against the full `/v1/items` endpoint, matching the original legacy Browse page's functionality.
- `LiveScreen` ("ТВ"): a light-theme grid for KinoPub's live channel list.
- `SearchScreen` ("Поиск"): merged search box + Тип/Поле/Сорт. filter bar, a ported on-screen RU/EN/symbols keyboard, recent searches, and a paginated results grid.
- `ExitConfirmDialog` and `ListPickerDialog` shared overlay components, used by every new screen.
- `UiTheme.brs` (light theme tokens) and `PosterCard.brs` (shared poster-tile builder) used across all new screens.
- New app icon assets generated from `images/kinopub.svg`.

### Changed
- Selecting a pill-nav tab now lands focus directly on that screen's content (grid/tiles) instead of the left list or filter bar.
- Up-arrow from the first grid row now returns focus to the top nav (or the filter/search bar, where one sits between the grid and the nav) instead of dead-ending.

### Fixed
- Pressing Back on any of the new screens now shows an exit-confirmation dialog instead of closing the app immediately.
- Fixed the pill nav bar occasionally resuming keyboard focus on the wrong tab when re-entering the top nav.
- Fixed navigation (all arrow keys, OK, Back) becoming completely unresponsive after applying a Library filter. Root cause: `ListPickerDialog`/`ExitConfirmDialog` previously took real SceneGraph focus and tried to hand it back from inside their own key handler; this didn't reliably stick. Dialogs no longer take real focus at all — the owning screen keeps it and routes keys to the dialog explicitly while it's open.
- Fixed Сериалы and Библиотека both showing Фильмы's content on first visit (a field-timing bug in `BrowseScreen`'s construction, fixed by moving initialization into an explicit `configure()` call).

## 0.3.2 - 2026-08-05

### Fixed
- Sign-in tokens are now stored with lowercase field names (`accesstoken`, `refreshtoken`, `tokentype`, `accessexpiresat`, `refreshexpiresat`), matching the canonical form `TokenStore.brs` expects everywhere else. Previously `KinoAuthService.brs` saved them with camelCase keys; this only worked on real Roku hardware because `roAssociativeArray` key lookups are case-insensitive there. Case-sensitive tooling (e.g. the community BrightScript Simulator) exposed the mismatch: every login was immediately followed by a forced sign-out because the freshly saved token was reported as unusable.

## 0.3.1 - 2026-08-05

### Changed
- Renamed local variables/parameters that shadowed globally-scoped BrightScript functions (`tokenStore` -> `tokenStoreService`, `buildInfo` -> `appBuildInfo`, `browseRequest` -> `browseRequestParams`), clearing the "Declaring a local variable with same name as scoped function" warnings across `AuthTask.brs`, `ContentTask.brs`, `KinoAuthService.brs`, and `HomeScreen.brs`. No behavior change.

## 0.1.0 - 0.3.0 - 2026-08-04

Initial hardening pass after the first round of on-device testing.

### Added
- Version consolidated into a single root `VERSION` file; `scripts/generate-build-info.sh` now syncs both `BuildInfo.brs` and the real `manifest` from it, keeping the VS Code debug launch and `package.sh` in sync.

### Changed
- Continue Watching's "New Episodes" rail now filters to `type = "serial"` (excludes docuseries) and requests `subscribed=1`, so it only lists shows on the "to watch" list.
- "New Episodes" now renders before "History" on the Continue Watching page.
- Video detail screens default to the first unwatched episode when opened without an explicit target (e.g. from Browse/Home), instead of always the first playable episode.

### Fixed
- `AuthScreen.brs` recognizes `incorrect_client_credentials` (in addition to `invalid_client`) as an invalid-credentials error, so bad KinoAPI credentials show a clear message instead of the generic "Unable to sign in."
- `KinoApiClient.brs` no longer leaks raw non-JSON error bodies (e.g. an nginx 502 HTML page) into on-screen messages; added friendly text for 500/502/503/504 responses.
- History (and History-backed rails) no longer show duplicate cards for the same show. `KinoHistoryService.brs` dedupes per API page, and `HomeScreen.brs` also dedupes across paginated "load more" fetches, since a show's watched episodes can straddle page boundaries in the underlying per-event watch log.
