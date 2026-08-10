# Changelog

All notable changes to this project are documented in this file.

## 0.8.0 - 2026-08-09

### Added
- Settings: new "Скрывать Аниме" toggle (on by default). KinoPub has no dedicated content type for anime — titles are just movies/serials tagged with the "Аниме" genre — so this filters any item whose genre list includes it out of Movies, Series, Library (all-genres view), Search, Continue Watching (both History and New Episodes), and bookmark folders. It's a purely local (registry-backed) preference, applied server-response-side in each content service before items are normalized for display, not a KinoPub account setting. Explicitly picking "Жанр: Аниме" in Library's own filter bar is left alone — the blanket filter only applies when browsing "Любой" (no specific genre chosen), so it never fights an explicit genre pick with an empty result list.
- Video detail (serials only): a new "Буду смотреть" action alongside "В закладки", toggling the item on/off KinoPub's watchlist (`/v1/watching/togglewatchlist`, see https://kinoapi.com/api_watching.html#id16) — the same subscribed set that feeds Continue Watching's "New Episodes" rail. Initial state comes from the item detail response's `subscribed`/`in_watchlist` field, no extra request needed.

### Docs
- Rewrote `Readme.md` from scratch — it still described the app as a "small SceneGraph app" with a home/search-only feature set from well before the navigation/screens/player rewrite. Now covers the actual screen set, services, task-thread architecture, and current feature list, plus a proper attribution chain (this project → slimus/Kinopub → the archived karpeychik/Kinopub).

## 0.7.1 - 2026-08-09

### Fixed
- Stats overlay showed a hardcoded "Audio: DEFAULT" and blank "Language: —" for a brand-new episode/serial with no prior manually-picked audio track. `selectedAudioLabel()`/`selectedAudioLanguage()` only matched against `m.preferences["audioTrackId"]`, which is only ever written by an explicit manual pick (`applyAudioSelection`) — never by the auto-applied saved-preference path — and fell back to a generic placeholder for any multi-track list instead of the actual track Roku defaults to (index 0) when nothing has been explicitly chosen yet. Both now fall back to the first available track for any non-empty list, not just single-track ones.

## 0.7.0 - 2026-08-09

Player screen redesign, matching reference screenshots for a Netflix/Apple-TV-style dark UI. Most of the underlying mechanics (Play/Pause, Rewind/FastForward, the show-on-Up/OK auto-hiding OSD, the audio/subtitle/quality track-picker popover) were already implemented — this pass is primarily a visual restyle, plus a few real behavior changes.

### Changed
- AC3/E-AC3 audio tracks are no longer offered in the audio panel — most Roku models can't decode them. `KinoItemService.brs`'s `kinoItemTrackOptions` now reads the KinoPub API's per-track `codec` field and drops anything matching "ac3"; since Roku's own `Video.availableAudioTracks` (used once a stream is actually loaded) exposes no codec field at all, `PlayerScreen.brs` cross-references by track label against the (now codec-filtered) KinoPub list to keep those tracks out of the real, functional picker too, with a text-based "ac3"/"ac-3" label check as a second layer of defense.
- Resume-playback prompt restyled from a stacked two-row list to a "Продолжить с HH:MM:SS?" message with side-by-side Да/Нет buttons (Да resumes, matching the existing 15s auto-resume countdown; Нет starts over) — same underlying mechanism as before, just a different layout and Russian copy.
- The bottom OSD's control row switched from 4 text labels ("Play/Pause", "Audio: X", "Subs: X", "Quality: X") to 4 icons (stats/gear, subtitles, audio, quality — 3 new icon assets in `images/ui/`). Play/Pause is no longer an on-screen control — it was always also controllable via the remote's dedicated transport key regardless of OSD focus, and stays that way; the icon row just no longer duplicates it.
- Audio/subtitle track panels restyled (checkmark-prefixed rows, translucent gray panel, Russian headers "АУДИОДОРОЖКА"/"СУБТИТРЫ") — same underlying track list/selection logic as before.
- Default video quality now picks the best available stream (Auto → hls4 → hls2 → hls, matching `KinoItemService.brs`'s priority list) instead of always starting on the server's literal "default" entry regardless of format; hls4/hls2 previously were only ever reached via the on-failure fallback path.
- Subtitle track choice is now remembered across a serial's episodes, the same way audio track choice already was (`PlayerPreferenceStore.brs`'s per-series preference key, previously used for audio only).
- Direct mp4/"http" streaming is no longer offered or used anywhere — `KinoItemService.brs`'s stream-resolution helpers (`kinoItemMediaStream`, `kinoItemStreamFromUrlContainer`, `kinoItemAddQualityUrlOptions`) are now HLS-only; an item with no HLS variant at all simply has no playable stream rather than falling back to a direct file.

### Fixed
- Back now dismisses the OSD/control row first and only exits the player (stopping video playback, per `exitPlayer()`) on a second Back once the rail is already hidden. Previously Back always exited the player immediately whenever no menu/prompt was open, even with the OSD visible right after changing an audio/subtitle track — there was no way to just dismiss the controls without leaving.
- Left/Right now seek immediately even with the OSD hidden, same as the remote's dedicated rewind/fastforward keys, and land focus on the seek bar (not the icon row) so a second Left/Right keeps seeking instead of moving between icons — previously these just revealed the OSD without seeking at all.
- Reopening the OSD (Up, after it had auto-hidden or been Back-dismissed) now always lands focus back on the icon row. Previously, if focus had been left on the seek bar (e.g. right after a Left/Right seek with the OSD hidden) or the season carousel, that stale focus area carried over to the next time the OSD was shown instead of resetting.
- Default quality now actually starts on the "Auto" stream when one exists, instead of silently falling back to a lower tier. `playbackStreamOptions()` used to add the "default" entry before the quality-options list; since `m.playback.streamUrl` is almost always the exact same URL the "auto" option resolves to, and options are deduped by URL, "default" was winning that race every time — `bestQualityOptionIndex` never actually saw an option with `id="auto"` to prefer, even though the stats overlay/quality panel still displayed "Auto" via a coincidental URL match against a different list. Quality options are now added first.
- The stats overlay now actually refreshes: a dedicated 2s timer updates it continuously while visible (previously it only computed its text once, when toggled on, and relied on `Video.position` changes to catch up).
- Stats overlay's Audio line no longer gets stuck showing "UNKNOWN" for the whole session — `m.videoNode.audioFormat` was observed never populating on-device; it now falls back to the selected track's own label (matching the checkmark shown in the audio panel) whenever the Video node's own format field is empty.
- Stats overlay's Bitrate line removed entirely. Tried `streamInfo.measuredBitrate`, computed throughput from `downloadedSegment`'s `SegSize`/`DownloadDuration`, then the direct `BitrateBPS`/`segBitrateBps` fields — all three stayed stuck on "measuring...". Confirmed via the console log that `Video.downloadedSegment`/`streamingSegment` never fire *at all* for this content/device (not just empty fields), so no live bitrate figure is obtainable here; a permanently-stuck placeholder is worse than not showing the line.
- Removed the redundant format tag from the stats overlay's Video line ("Auto AUTO", or "1080p hls4 HLS4" for non-Auto picks) — the quality label itself already includes the tier text (`kinoItemAddQualityUrlOptions` appends " hls4"/" hls2"/" hls" to the label), so the separate tag was always duplicating it.
- **Resuming from a saved position silently played from the beginning instead.** `startPlaybackAtPosition` set `m.videoNode.seek` immediately, before `control="play"` — the same Roku timing quirk already known and worked around for audio-track preference (`applySavedAudioPreference` is deliberately deferred to `state="playing"`, not called at playback start). The resume seek is now deferred the same way, applied once `onVideoStateChanged` actually reaches `"playing"`.
- Choosing "Сначала" (or reloading with a different subtitle or quality option) silently reset the audio track back to the stream's default, dropping the user's saved/selected audio track. Assigning a fresh `ContentNode` to `m.videoNode.content` resets Roku's own audio-track selection, but `applySavedAudioPreference()` only ever re-applies once per playback session (`m.savedAudioPreferenceApplied`, a one-shot guard only reset in `startPlayback()`). `restartPlaybackFromBeginning()`, `reloadPlaybackWithSubtitle()`, and `reloadPlaybackWithQuality()` — the three places that reassign `m.videoNode.content` mid-session — now re-arm that guard before reassigning content, so the saved track reapplies every time instead of only on the very first load.

### Added
- A "stats for nerds" overlay — quality/stream label, audio codec (or track label as a fallback), audio language, and subtitle status, each on its own line (no bitrate — see Fixed). Toggled only by OK on the gear icon, and deliberately independent of the OSD/Back stack: it isn't in `onKeyEvent`'s overlay-precedence chain, stays visible across the OSD hiding/reappearing, and Back never closes it — only pressing OK on the gear control again does.
- Pressing Down while the OSD is hidden now shows a "Сначала" / "Следующая серия" dialog (restart this episode from 0, or jump to the next one) — a quicker manual alternative to opening the OSD and navigating the season carousel. Back or a ~4.5s idle timeout cancels it with no action, matching each other (unlike the resume prompt's countdown, which auto-*chooses* an option). "Следующая серия" only appears when a next episode actually exists (movies/live just show "Сначала"); it reuses the same `nextPlaybackRequested`/`nextPlayback` request pipeline as the season carousel and auto-triggered next-episode prompt, with its own `"manualNext"` reason so the switch happens immediately once picked instead of asking for confirmation a second time.

### Visual
- Audio/subtitle track panel background darkened (`#6B7280` → `#111827`, opacity bumped to 0.97) — the lighter gray was hard to read over bright video content.
- Audio/subtitle track panel rows now show a highlight bar behind the currently-focused (cursor) row — previously only a subtle text-color change distinguished it, easy to miss; separate from the "✓" prefix, which marks the saved/applied track, not cursor position.

### Not built (no supported Roku API)
- A playback-speed picker — Roku's `Video` node has no documented API for sustained variable-rate playback (only fixed-interval FF/RW trick-play).
- Subtitle "style" customization and an audio "loud sounds quieter" leveling toggle — both are Roku system-level settings (Settings > Accessibility / Settings > Audio), not exposed to channel apps via SceneGraph.

## 0.6.0 - 2026-08-08

Performance and correctness fixes from an external code review (independently verified against current code before implementing — the review's comments/reviews-feature finding was already stale, since that feature had been removed).

### Changed
- Browse, Search, Live, and Continue Watching's poster grids are now truly virtualized (`components/grid/VideoGrid.brs`, new): a small fixed pool of card nodes is rebound to whichever items are scrolled into view, instead of building one card (and firing one poster image load) per item up front. Previously this was capped at 300 items for Browse/Search and fully uncapped for Live/Continue Watching — Roku hardware struggles with hundreds of concurrently-loading textures regardless of whether they're currently visible. `PosterCard.brs` gained `updatePosterCard`, rebinding an existing card's content/badges/poster in place; `createPosterCard`'s return shape is now a superset of before, so its other (non-pooled) callers are unaffected.
- The video detail page's recommendations rail and trailer availability are now fetched in a separate request fired after the base page has already rendered, instead of blocking first paint behind two extra sequential API calls.
- Screens that fire multiple concurrent background requests on load (Continue Watching: 3, Settings: 2) now run a single token-refresh preflight first instead of letting each request independently discover an expired token and race to refresh it — a losing refresh call could previously fail against an already-rotated token and spuriously sign the user out.

### Fixed
- Fast-reselecting a recommendation on the video detail page could occasionally show stale data from an in-flight request for the previously-viewed item, since nothing stopped an older request or checked whether a response still belonged to the current selection. Responses now carry a request generation number and stale ones are ignored.
- `KinoApiClient.brs` no longer logs API response bodies outside dev builds, and never logs OAuth token-exchange bodies (even in dev builds) — previously every response, including token exchanges, was logged unconditionally.
- Browse/Series/Movies/Continue Watching: switching the left-menu row (e.g. Свежие→Горячие, or between bookmark folders) no longer left the tile grid showing the previous row's items. The new pooled grid (`VideoGridPool`) only rebinds a card when its computed item index actually changes since the last call — but a freshly loaded list can map the same slot to the same index as the old one, so switching rows was wrongly treated as a no-op. `setItems` now forces every pooled card to rebind whenever it's handed a new list.

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
