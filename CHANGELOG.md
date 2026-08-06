# Changelog

All notable changes to this project are documented in this file.

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
