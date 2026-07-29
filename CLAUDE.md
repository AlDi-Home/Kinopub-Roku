# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

KinoPub Roku Channel is a Roku SceneGraph/BrightScript app for browsing and watching KinoPub content. It is sideloaded onto a Roku device — there is no build server or emulator; testing requires a physical device.

No package manager or dependency install step exists. Requirements: `bash`, `python3`, `zip`.

## Commands

### Setup

```bash
cp config/kinoapi.example.json config/kinoapi.local.json
# Edit config/kinoapi.local.json with real client_id and client_secret
```

### Build

```bash
./scripts/package.sh          # Generates dist/kinopub.zip (sideload this on the Roku)
./scripts/generate-config.sh  # Regenerate source/config/KinoConfig.brs only
```

Override defaults: `APP_VERSION`, `APP_SHA`, `PACKAGE_NAME` env vars; or use `KINOAPI_CLIENT_ID` / `KINOAPI_CLIENT_SECRET` instead of the local JSON config.

### Verify

```bash
./scripts/verify-static.sh    # Static checks: required files present, BrightScript field naming conventions, XML/manifest integrity
```

`verify-static.sh` also enforces BrightScript naming conventions (e.g., no uppercase-only field names, no disallowed patterns). Run it before committing.

## Architecture

### Language & framework

All app code is **BrightScript** (`.brs`) paired with **SceneGraph XML** (`.xml`). BrightScript is a weakly-typed scripting language; SceneGraph is Roku's UI component model. Each component consists of an `.xml` declaration and a `.brs` behavior file.

### Execution model

Roku SceneGraph runs the main thread and task threads in isolation. Tasks (`components/tasks/`) run blocking operations (network, registry) on background threads. Communication between the render thread (screens) and tasks happens exclusively through observed SceneGraph fields (`task.observeField("response", "handler")`).

### Screen / navigation flow

`source/main.brs` creates `AppScene`. `AppScene` (`components/AppScene.brs`) acts as the root navigator, managing a `screenHost` Group that holds the active screen stack:

```
LoadingScreen → AuthScreen (device-code login)
                         ↓ authCompleted
             HomeScreen (tabs: home, search, browse, bookmarks, history, live TV)
                         ↓ videoSelected
             VideoDetailScreen (item detail, season/episode selection)
                         ↓ playbackRequested
             PlayerScreen (custom video player UI)
```

Screens are created and destroyed by `AppScene`; the active screen holds focus. Player and detail screens are hidden (not destroyed) when layering on top, and restored on back.

### Tasks

- **`AuthTask`** (`components/tasks/`) — handles token storage/refresh and device-code OAuth flow.
- **`ContentTask`** (`components/tasks/`) — all content API calls (home feed, search, browse, bookmarks, history, live TV, playback progress). A single task file with a `command` field dispatch pattern.

### Services (`source/services/`)

Plain BrightScript objects (returned from constructor functions, not classes):

| File | Purpose |
|---|---|
| `KinoApiClient.brs` | HTTP client wrapping `roUrlTransfer` (GET/POST, timeout, JSON parse) |
| `KinoAuthService.brs` | Device-code OAuth: request code, poll token, refresh, notify |
| `TokenStore.brs` | Persist/load OAuth tokens via `roRegistrySection` |
| `PlayerPreferenceStore.brs` | Persist audio/subtitle/quality preferences per-item |
| `SearchHistoryStore.brs` | Persist recent search queries |
| `KinoHomeService.brs` | Home feed API calls |
| `KinoItemService.brs` | Item detail + media links API calls |
| `KinoWatchingService.brs` | Save playback progress, mark watched |
| `KinoBrowseService.brs` | Browse/filter API calls |
| `KinoBookmarkService.brs` | Bookmark folder CRUD |
| `KinoSearchService.brs` | Search API calls |
| `KinoHistoryService.brs` | Watch history API calls |
| `KinoTvService.brs` | Live TV channel list |
| `KinoContentTypeService.brs` | Content type metadata |
| `KinoUserService.brs` | User profile |

### Config

`source/config/KinoConfig.brs` is **generated** by `scripts/generate-config.sh` from `config/kinoapi.local.json`. It is gitignored. `source/config/BuildInfo.brs` is similarly generated. Do not edit these files manually.

### CI / Release

`.github/workflows/release-package.yml` triggers on GitHub release publication. It reads `KINOAPI_CLIENT_ID` and `KINOAPI_CLIENT_SECRET` from repository secrets, runs `scripts/package.sh`, and uploads the zip as a release asset.

## Key conventions

- BrightScript uses `m.` for component-scoped state (analogous to `this`).
- All service constructors return an associative array (AA) object with method references — BrightScript has no classes.
- Task responses always include `command` and `ok` fields; callers check `result.ok` before accessing other fields.
- `DEV_BUILD=true` is set in `manifest` via `bs_const`; use `#if DEV_BUILD` for debug-only code paths.
