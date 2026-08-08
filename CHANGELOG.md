# Changelog

All notable changes to this project are documented in this file.

## 0.4.0 - 2026-08-08

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
