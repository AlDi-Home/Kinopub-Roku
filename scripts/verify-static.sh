#!/usr/bin/env bash
set -euo pipefail

required_files=(
  manifest
  source/main.brs
  source/services/KinoApiClient.brs
  source/services/KinoAuthService.brs
  source/services/KinoBookmarkService.brs
  source/services/KinoBrowseService.brs
  source/services/KinoContentTypeService.brs
  source/services/KinoHistoryService.brs
  source/services/KinoHomeService.brs
  source/services/KinoItemService.brs
  source/services/KinoSearchService.brs
  source/services/KinoTvService.brs
  source/services/KinoUserService.brs
  source/services/KinoWatchingService.brs
  source/services/PlayerPreferenceStore.brs
  source/services/SearchHistoryStore.brs
  source/services/TokenStore.brs
  components/AppScene.xml
  components/AppScene.brs
  components/screens/AuthScreen.xml
  components/screens/AuthScreen.brs
  components/screens/LoadingScreen.xml
  components/screens/HomeScreen.xml
  components/screens/HomeScreen.brs
  components/screens/PlayerScreen.xml
  components/screens/PlayerScreen.brs
  components/screens/VideoDetailScreen.xml
  components/screens/VideoDetailScreen.brs
  components/tasks/AuthTask.xml
  components/tasks/AuthTask.brs
  components/tasks/ContentTask.xml
  components/tasks/ContentTask.brs
  images/channel-icon_hd.png
  images/channel-icon_fhd.png
  images/kino-icon-source.png
  config/kinoapi.example.json
  scripts/generate-config.sh
  scripts/generate-build-info.sh
  scripts/package.sh
  .github/workflows/release-package.yml
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "Missing $file" >&2; exit 1; }
done

grep -q "replace-with-client-id" config/kinoapi.example.json
grep -q "mm_icon_focus_hd=pkg:/images/channel-icon_hd.png" manifest
grep -q "mm_icon_focus_fhd=pkg:/images/channel-icon_fhd.png" manifest
grep -q "config/kinoapi.local.json" .gitignore
grep -q "source/config/KinoConfig.brs" .gitignore
grep -q "source/config/BuildInfo.brs" .gitignore
grep -q 'id="accountVersionLabel".*translation="\[420,4\]".*width="520"' components/screens/HomeScreen.xml
grep -q 'release:' .github/workflows/release-package.yml
grep -q 'types: \[published\]' .github/workflows/release-package.yml
grep -q 'KINOAPI_CLIENT_ID' .github/workflows/release-package.yml
grep -q 'KINOAPI_CLIENT_SECRET' .github/workflows/release-package.yml
grep -q "wait(requestTimeoutMs" source/services/KinoApiClient.brs
grep -q "AsyncCancel" source/services/KinoApiClient.brs
grep -q "pollTimeoutMs: 10000" source/services/KinoApiClient.brs
grep -q "RetainBodyOnError(true)" source/services/KinoApiClient.brs
grep -q "postFormBody: kinoApiPostFormBody" source/services/KinoApiClient.brs
grep -q "post: kinoApiPost" source/services/KinoApiClient.brs
grep -q "Content-Type\", \"application/x-www-form-urlencoded" source/services/KinoApiClient.brs
grep -q "kinoApiLooksLikeJson" source/services/KinoApiClient.brs
grep -q 'CreateObject("roByteArray")' source/services/KinoApiClient.brs
grep -q "FromAsciiString(raw)" source/services/KinoApiClient.brs
grep -q "byteArray.Count()" source/services/KinoApiClient.brs
grep -q "code = byteArray\\[index\\]" source/services/KinoApiClient.brs
grep -q "KinoApiClient: response path=" source/services/KinoApiClient.brs
grep -q "showLoadingScreen()" components/AppScene.brs
grep -q "routeFromStoredTokens()" components/AppScene.brs
grep -q "routeFallbackTimer" components/AppScene.xml
grep -q "onRouteFallbackTimer" components/AppScene.brs
grep -q "requestTimer" components/screens/AuthScreen.xml
grep -q 'id="codePanel"' components/screens/AuthScreen.xml
grep -q 'height="300" color="#F9FAFB"' components/screens/AuthScreen.xml
grep -q 'id="instructionLabel".*font="font:LargeBoldSystemFont"' components/screens/AuthScreen.xml
grep -q 'id="codeLabel".*height="220".*color="#030712".*font="font:ExtraLargeBoldSystemFont"' components/screens/AuthScreen.xml
grep -q "m.codeLabel.font.size = 170" components/screens/AuthScreen.brs
grep -q 'id="statusLabel".*font="font:MediumBoldSystemFont"' components/screens/AuthScreen.xml
if grep -q '<Font .*uri="font:' components/screens/AuthScreen.xml; then
  echo "System fonts must be assigned with Label font attributes, not child Font uri nodes." >&2
  exit 1
fi
grep -q "m.progressFill.width = 640 \* percent" components/screens/AuthScreen.brs
grep -q "onRequestTimer" components/screens/AuthScreen.brs
grep -q "authorization_pending" source/services/KinoApiClient.brs
grep -q "kinoApiRawJsonValue" source/services/KinoApiClient.brs
grep -q "status=" components/screens/AuthScreen.brs
grep -q '"/v1/device/notify"' source/services/KinoAuthService.brs
grep -q "postFormBody(\"/v1/device/notify\"" source/services/KinoAuthService.brs
grep -q "queryParams = { access_token: accessToken }" source/services/KinoAuthService.brs
grep -q "bodyParams = {" source/services/KinoAuthService.brs
grep -q "deviceInfo = m.deviceNotifyInfo()" source/services/KinoAuthService.brs
grep -q "CreateObject(\"roDeviceInfo\")" source/services/KinoAuthService.brs
grep -q "GetModel()" source/services/KinoAuthService.brs
grep -q "GetModelType()" source/services/KinoAuthService.brs
grep -q "GetModelDetails()" source/services/KinoAuthService.brs
grep -q "GetOSVersion()" source/services/KinoAuthService.brs
grep -q "kinoAuthFormattedOsVersion" source/services/KinoAuthService.brs
grep -q "kinoAuthDeviceTitle" source/services/KinoAuthService.brs
grep -q "kinoAuthDeviceHardware" source/services/KinoAuthService.brs
grep -q "title: deviceInfo.title" source/services/KinoAuthService.brs
grep -q "hardware: deviceInfo.hardware" source/services/KinoAuthService.brs
grep -q "software: deviceInfo.software" source/services/KinoAuthService.brs
if grep -q "GetVersion()" source/services/KinoAuthService.brs; then
  echo "Device notify software must use GetOSVersion(), not deprecated GetVersion()." >&2
  exit 1
fi
grep -q "normalize: tokenStoreNormalize" source/services/TokenStore.brs
grep -q "tokenStoreTokenPayload" source/services/TokenStore.brs
grep -q "tokenStoreHasAnyTokenField" source/services/TokenStore.brs
grep -q '"tokens", "body", "data", "auth"' source/services/TokenStore.brs
grep -q "access_token" source/services/TokenStore.brs
grep -q "accesstoken" source/services/TokenStore.brs
grep -q "refreshtoken" source/services/TokenStore.brs
grep -q "accessexpiresat" source/services/TokenStore.brs
grep -q "refreshexpiresat" source/services/TokenStore.brs
grep -q "accessexpiresat = now + 3600" source/services/TokenStore.brs
grep -q "tokens.refreshexpiresat <= now" source/services/TokenStore.brs
grep -q "AuthTask: token fields access=" components/tasks/AuthTask.brs
grep -q "authTaskNotifyAllowsHome(tokens.accesstoken" components/tasks/AuthTask.brs
grep -q "notifyDevice(result.tokens.accessToken)" components/tasks/AuthTask.brs
grep -q "authTaskNotifyAllowsHome" components/tasks/AuthTask.brs
grep -q 'notifyResult.status = 401' components/tasks/AuthTask.brs
grep -q 'notifyResult.error = "unauthorized"' components/tasks/AuthTask.brs
grep -q 'message: "Device authorization was removed. Sign in again."' components/tasks/AuthTask.brs
grep -q "KinoContentTypeService.brs" components/tasks/ContentTask.xml
grep -q "KinoBookmarkService.brs" components/tasks/ContentTask.xml
grep -q "KinoBrowseService.brs" components/tasks/ContentTask.xml
grep -q "function KinoBookmarkService" source/services/KinoBookmarkService.brs
grep -q '"/v1/bookmarks"' source/services/KinoBookmarkService.brs
grep -q '"/v1/bookmarks/get-item-folders"' source/services/KinoBookmarkService.brs
grep -q '"/v1/bookmarks/toggle-item"' source/services/KinoBookmarkService.brs
grep -q 'postFormBody("/v1/bookmarks/toggle-item"' source/services/KinoBookmarkService.brs
grep -q "KinoBookmarkService(client)" components/tasks/ContentTask.brs
grep -q "function KinoBrowseService" source/services/KinoBrowseService.brs
grep -q '"/v1/items"' source/services/KinoBrowseService.brs
grep -q '"/v1/genres"' source/services/KinoBrowseService.brs
grep -q '"/v1/countries"' source/services/KinoBrowseService.brs
grep -q 'genreSectionName: "kinogenres"' source/services/KinoBrowseService.brs
grep -q 'countrySectionName: "kinocountries"' source/services/KinoBrowseService.brs
grep -q "cacheTtlSeconds: 86400" source/services/KinoBrowseService.brs
grep -q "KinoBrowseService(client)" components/tasks/ContentTask.brs
grep -q "loadBrowseOptions" components/tasks/ContentTask.brs
grep -q "loadBrowseItems" components/tasks/ContentTask.brs
grep -q "contentTaskLoadBrowseOptions" components/tasks/ContentTask.brs
grep -q "contentTaskLoadBrowseItems" components/tasks/ContentTask.brs
grep -q "typeMap = contentTaskTypeMap(typeService, tokenResult.accessToken)" components/tasks/ContentTask.brs
grep -q "typeTitle" source/services/KinoBrowseService.brs
grep -q "typeBadge" source/services/KinoBrowseService.brs
grep -q "year_from" source/services/KinoBrowseService.brs
grep -q "year_to" source/services/KinoBrowseService.brs
grep -q "finished" source/services/KinoBrowseService.brs
grep -q "loadBookmarkFolders" components/tasks/ContentTask.brs
grep -q "loadBookmarkFolderItems" components/tasks/ContentTask.brs
grep -q "loadItemBookmarkFolders" components/tasks/ContentTask.brs
grep -q "toggleItemBookmark" components/tasks/ContentTask.brs
grep -q "KinoContentTypeService(client)" components/tasks/ContentTask.brs
grep -q "contentTaskTypeMap(typeService, tokenResult.accessToken)" components/tasks/ContentTask.brs
grep -q "typeMap = contentTaskTypeMap(typeService, tokenResult.accessToken)" components/tasks/ContentTask.brs
grep -q '"/v1/types"' source/services/KinoContentTypeService.brs
grep -q 'sectionName: "kinotypes"' source/services/KinoContentTypeService.brs
grep -q 'cacheTtlSeconds: 86400' source/services/KinoContentTypeService.brs
grep -q 'fetchTimeoutMs: 1200' source/services/KinoContentTypeService.brs
grep -q 'function kinoContentTypeMap(accessToken as String)' source/services/KinoContentTypeService.brs
grep -q 'function kinoContentTypeFetchMap(accessToken as String)' source/services/KinoContentTypeService.brs
grep -q 'm.client.get("/v1/types", { access_token: accessToken }, m.fetchTimeoutMs)' source/services/KinoContentTypeService.brs
grep -q 'section.Read("typesJson")' source/services/KinoContentTypeService.brs
grep -q 'section.Read("typesCachedAt")' source/services/KinoContentTypeService.brs
grep -q 'section.Write("typesJson", FormatJson(typeMap))' source/services/KinoContentTypeService.brs
grep -q 'section.Write("typesCachedAt", StrI(now).Trim())' source/services/KinoContentTypeService.brs
grep -q "fallbackMap: kinoContentTypeFallbackMap" source/services/KinoContentTypeService.brs
grep -q 'movie: { id: "movie", title: "Movie", badge: "MOV" }' source/services/KinoContentTypeService.brs
grep -q 'serial: { id: "serial", title: "Series", badge: "SER" }' source/services/KinoContentTypeService.brs
grep -q 'concert: { id: "concert", title: "Concert", badge: "CON" }' source/services/KinoContentTypeService.brs
grep -q "badgeForType: kinoContentTypeBadgeForType" source/services/KinoContentTypeService.brs
grep -q "enrichItem: kinoContentTypeEnrichItem" source/services/KinoContentTypeService.brs
grep -q "typeTitle" source/services/KinoHistoryService.brs
grep -q "typeBadge" source/services/KinoHistoryService.brs
grep -q "typeTitle" source/services/KinoSearchService.brs
grep -q "typeBadge" source/services/KinoSearchService.brs
grep -q "appendTypeBadge" components/screens/HomeScreen.brs
grep -q "appendTypeBadge(card, item)" components/screens/HomeScreen.brs
grep -q "function homeUiPalette" components/screens/HomeScreen.brs
grep -q "function createMediaCard" components/screens/HomeScreen.brs
grep -q "function posterBrowseCardLayout" components/screens/HomeScreen.brs
grep -q "chipWidth = 64" components/screens/HomeScreen.brs
grep -q "subtitle.visible = false" components/screens/HomeScreen.brs
grep -q "function cardYearText" components/screens/HomeScreen.brs
grep -q "layout.showYear" components/screens/HomeScreen.brs
grep -q "layout.showYear = true" components/screens/HomeScreen.brs
grep -q "yearY = 190" components/screens/HomeScreen.brs
grep -q "year.translation = \\[layout.textX, yearY\\]" components/screens/HomeScreen.brs
grep -q "year.width = layout.textWidth" components/screens/HomeScreen.brs
grep -q "year.font.size = 24" components/screens/HomeScreen.brs
grep -q "cardVisualStateColor" components/screens/HomeScreen.brs
grep -q "function baseCardFocusColor" components/screens/HomeScreen.brs
grep -q "baseCardFocusColor(showOverlay)" components/screens/HomeScreen.brs
grep -q "sub updateContinueFocusVisuals" components/screens/HomeScreen.brs
grep -q "sub updateSelectedContentFocusVisuals" components/screens/HomeScreen.brs
grep -q "updateContinueFocusVisuals()" components/screens/HomeScreen.brs
grep -q "updateHomeCardFocus()" components/screens/HomeScreen.brs
grep -q "updateSelectedContentFocusVisuals()" components/screens/HomeScreen.brs
grep -q "function expandedPosterCardLayout" components/screens/HomeScreen.brs
grep -q "function focusedMediaCardOverlayY" components/screens/HomeScreen.brs
grep -q "return y" components/screens/HomeScreen.brs
if grep -q "if y > 180" components/screens/HomeScreen.brs; then
  echo "Focused media cards must use consistent top-edge expansion across rows." >&2
  exit 1
fi
grep -q "sub refreshFocusedMediaCardOverlay" components/screens/HomeScreen.brs
grep -q "title.height = layout.titleHeight" components/screens/HomeScreen.brs
grep -q "title.wrap = true" components/screens/HomeScreen.brs
grep -q "layout.focusOverlay = true" components/screens/HomeScreen.brs
grep -q "focusFrame: true" components/screens/HomeScreen.brs
grep -q "renderSearchFilters" components/screens/HomeScreen.brs
grep -q "m.homeMaxVisibleRails = 2" components/screens/HomeScreen.brs
grep -q "m.homeVisibleCards = 5" components/screens/HomeScreen.brs
grep -q "m.historyColumns = 5" components/screens/HomeScreen.brs
grep -q "m.searchColumns = 5" components/screens/HomeScreen.brs
grep -q "cardHeight: 220" components/screens/HomeScreen.brs
grep -q "posterHeight: 150" components/screens/HomeScreen.brs
grep -q "cardWidth: 190" components/screens/HomeScreen.brs
grep -q "cardHeight: 258" components/screens/HomeScreen.brs
grep -q "posterWidth: 144" components/screens/HomeScreen.brs
grep -q "posterHeight: 192" components/screens/HomeScreen.brs
grep -q "textWidth: 166" components/screens/HomeScreen.brs
grep -q "titleHeight: 42" components/screens/HomeScreen.brs
grep -q "progressY: 202" components/screens/HomeScreen.brs
grep -q "collapsedActiveIndicator" components/screens/HomeScreen.xml
grep -q "m.collapsedActiveIndicator.translation" components/screens/HomeScreen.brs
grep -q "sub previewMenuItem" components/screens/HomeScreen.brs
grep -q 'if section = "signOut" then return' components/screens/HomeScreen.brs
grep -q "previewMenuItem()" components/screens/HomeScreen.brs
grep -q "sub collapseMenuToContent" components/screens/HomeScreen.brs
grep -q "collapseMenuToContent()" components/screens/HomeScreen.brs
grep -q "function SearchHistoryStore" source/services/SearchHistoryStore.brs
grep -q 'sectionName: "searchhistory"' source/services/SearchHistoryStore.brs
grep -q 'historyKey: "queriesJson"' source/services/SearchHistoryStore.brs
grep -q "maxEntries: 10" source/services/SearchHistoryStore.brs
grep -q "searchHistoryStoreLoad" source/services/SearchHistoryStore.brs
grep -q "searchHistoryStoreSaveQuery" source/services/SearchHistoryStore.brs
grep -q "SearchHistoryStore.brs" components/screens/HomeScreen.xml
grep -q "recentSearchesGroup" components/screens/HomeScreen.xml
grep -q "recentSearchesHost" components/screens/HomeScreen.xml
grep -q "m.searchHistoryStore = SearchHistoryStore()" components/screens/HomeScreen.brs
grep -q "m.recentSearches = m.searchHistoryStore.load()" components/screens/HomeScreen.brs
grep -q "renderRecentSearches" components/screens/HomeScreen.brs
grep -q "sub prepareSearchForDisplay" components/screens/HomeScreen.brs
grep -q "prepareSearchForDisplay()" components/screens/HomeScreen.brs
grep -q 'if m.searchQuery.Trim() = "" and m.searchSubmittedQuery.Trim() = "" and m.searchItems.Count() = 0' components/screens/HomeScreen.brs
grep -q "selectRecentSearch" components/screens/HomeScreen.brs
grep -q "saveSubmittedSearchQuery" components/screens/HomeScreen.brs
grep -q '\["a", "b", "c", "d", "e", "f"\]' components/screens/HomeScreen.brs
grep -q '\["а", "б", "в", "г", "д", "е"\]' components/screens/HomeScreen.brs
grep -q '\["1", "2", "3", "4", "5", "6"\]' components/screens/HomeScreen.brs
grep -q 'if label = "123" then return { type: "layout", value: "symbols", label: "123" }' components/screens/HomeScreen.brs
grep -q 'if label = "ABC" then return { type: "layout", value: "alpha", label: "ABC" }' components/screens/HomeScreen.brs
grep -q "m.searchKeyboardPreviousTextLayout = m.searchKeyboardLayout" components/screens/HomeScreen.brs
grep -q "actionGap = 10" components/screens/HomeScreen.brs
grep -q "key.row = rowIndex" components/screens/HomeScreen.brs
grep -q "key.column = columnIndex" components/screens/HomeScreen.brs
grep -q "targetRow = current.row + direction" components/screens/HomeScreen.brs
grep -q 'm.selectedSection = "continue"' components/screens/HomeScreen.brs
grep -q 'm.menuExpanded = false' components/screens/HomeScreen.brs
grep -q 'showSection("continue")' components/screens/HomeScreen.brs
grep -q 'setMenuExpanded(true)' components/screens/HomeScreen.brs
grep -q 'setMenuExpanded(false)' components/screens/HomeScreen.brs
grep -q 'Continue Watching' components/screens/HomeScreen.xml
grep -q 'text="C  Continue"' components/screens/HomeScreen.xml
grep -q 'id="collapsedContinue"' components/screens/HomeScreen.xml
grep -q 'Home' components/screens/HomeScreen.xml
grep -q 'Browse' components/screens/HomeScreen.xml
grep -q 'Search' components/screens/HomeScreen.xml
grep -q 'Bookmarks' components/screens/HomeScreen.xml
grep -q 'Account' components/screens/HomeScreen.xml
grep -q 'id="collapsedBrowse" text="BR" translation="\[0,238\]"' components/screens/HomeScreen.xml
grep -q 'id="browseNav" text="B  Browse" translation="\[32,244\]"' components/screens/HomeScreen.xml
grep -q 'id="searchNav" text="S  Search" translation="\[32,304\]"' components/screens/HomeScreen.xml
grep -q 'id="bookmarksNav" text="K  Bookmarks" translation="\[32,364\]"' components/screens/HomeScreen.xml
grep -q 'id="accountNav" text="A  Account" translation="\[32,424\]"' components/screens/HomeScreen.xml
grep -q 'continueSummaryGroup' components/screens/HomeScreen.xml
grep -q 'continueFullListGroup' components/screens/HomeScreen.xml
grep -q "renderContinueSummary" components/screens/HomeScreen.brs
grep -q "openContinueFullList" components/screens/HomeScreen.brs
grep -q "selectContinueCard" components/screens/HomeScreen.brs
grep -q "continueNewEpisodes" components/screens/HomeScreen.brs
grep -q "targetSeasonNumber" components/screens/HomeScreen.brs
grep -q "targetEpisodeNumber" components/screens/HomeScreen.brs
grep -q 'homeContent' components/screens/HomeScreen.xml
grep -q 'browseContent' components/screens/HomeScreen.xml
grep -q 'browseFilterBar' components/screens/HomeScreen.xml
grep -q 'browseTypeFilterLabel' components/screens/HomeScreen.xml
grep -q 'browseGenreFilterLabel' components/screens/HomeScreen.xml
grep -q 'browseCountryFilterLabel' components/screens/HomeScreen.xml
grep -q 'browseYearFilterLabel' components/screens/HomeScreen.xml
grep -q 'browseFinishedFilterLabel' components/screens/HomeScreen.xml
grep -q 'browsePickerGroup' components/screens/HomeScreen.xml
grep -q 'browseResultGridHost' components/screens/HomeScreen.xml
grep -q 'browseResultCursor' components/screens/HomeScreen.xml
grep -q 'browseNextPageStatus' components/screens/HomeScreen.xml
grep -q 'searchContent' components/screens/HomeScreen.xml
grep -q 'bookmarksContent' components/screens/HomeScreen.xml
grep -q 'bookmarkFoldersHost' components/screens/HomeScreen.xml
grep -q 'bookmarkItemsHost' components/screens/HomeScreen.xml
grep -q 'bookmarksCursor' components/screens/HomeScreen.xml
grep -q 'bookmarkFolderScrollUpChevron' components/screens/HomeScreen.xml
grep -q 'bookmarkFolderScrollDownChevron' components/screens/HomeScreen.xml
grep -q 'bookmarkItemsScrollUpChevron' components/screens/HomeScreen.xml
grep -q 'bookmarkItemsScrollDownChevron' components/screens/HomeScreen.xml
grep -q "function detailUiPalette" components/screens/VideoDetailScreen.brs
grep -q "function detailButtonColor" components/screens/VideoDetailScreen.brs
grep -q "createEpisodeRow" components/screens/VideoDetailScreen.brs
grep -q "m.playButtonLabel.color = palette.primaryText" components/screens/VideoDetailScreen.brs
grep -q "m.descriptionFocusBg.color = palette.surfaceFocus" components/screens/VideoDetailScreen.brs
grep -q 'id="heroGradientOverlay"' components/screens/VideoDetailScreen.xml
grep -q 'id="detailAccentBar"' components/screens/VideoDetailScreen.xml
grep -q 'accountContent' components/screens/HomeScreen.xml
grep -q 'accountLoadingGroup' components/screens/HomeScreen.xml
grep -q 'accountErrorGroup' components/screens/HomeScreen.xml
grep -q 'accountRetryGroup' components/screens/HomeScreen.xml
grep -q 'accountDetailsGroup' components/screens/HomeScreen.xml
grep -q 'collapsedMenu' components/screens/HomeScreen.xml
grep -q 'expandedMenu' components/screens/HomeScreen.xml
grep -q 'signOutRequested' components/screens/HomeScreen.xml
grep -q 'signOutRequested' components/screens/HomeScreen.brs
grep -q 'exitRequested' components/screens/HomeScreen.xml
grep -q 'exitRequested' components/AppScene.xml
grep -q 'exitDialog' components/screens/HomeScreen.xml
grep -q 'showExitConfirmation()' components/screens/HomeScreen.brs
grep -q 'hideExitConfirmation()' components/screens/HomeScreen.brs
grep -q 'activateExitConfirmation()' components/screens/HomeScreen.brs
grep -q 'm.top.exitRequested = true' components/screens/HomeScreen.brs
grep -q 'homeScreen.observeField("exitRequested", "onExitRequested")' components/AppScene.brs
grep -q 'sub onExitRequested' components/AppScene.brs
grep -q 'scene.observeField("exitRequested", port)' source/main.brs
if grep -q 'screen.Close()' source/main.brs; then
  echo "App exit must return from the main BrightScript loop, not call undocumented roSGScreen.Close()." >&2
  exit 1
fi
show_line=$(grep -n 'screen.Show()' source/main.brs | head -n 1 | cut -d: -f1)
exit_observer_line=$(grep -n 'scene.observeField("exitRequested", port)' source/main.brs | head -n 1 | cut -d: -f1)
if [[ -z "$show_line" || -z "$exit_observer_line" || "$exit_observer_line" -le "$show_line" ]]; then
  echo "App exit observer must be attached after screen.Show()." >&2
  exit 1
fi
grep -q "get: kinoApiGet" source/services/KinoApiClient.brs
grep -q "function kinoApiGet(" source/services/KinoApiClient.brs
grep -q '"/v1/history"' source/services/KinoHistoryService.brs
grep -q "perpage: 20" components/screens/HomeScreen.brs
grep -q "loadHistoryPage" components/tasks/ContentTask.brs
grep -q "loadContinueHistoryPage" components/screens/HomeScreen.brs
grep -q "loadContinueNewEpisodesPage" components/screens/HomeScreen.brs
grep -q "historyLoadingGroup" components/screens/HomeScreen.xml
grep -q "historyEmptyGroup" components/screens/HomeScreen.xml
grep -q "historyErrorGroup" components/screens/HomeScreen.xml
grep -q "historyRetryGroup" components/screens/HomeScreen.xml
grep -q "historyGridHost" components/screens/HomeScreen.xml
grep -q "historyCountLabel" components/screens/HomeScreen.xml
grep -q "historyScrollUpChevron" components/screens/HomeScreen.xml
grep -q "historyScrollDownChevron" components/screens/HomeScreen.xml
grep -q "historyNextPageStatus" components/screens/HomeScreen.xml
grep -q "historyScrollUpChevron" components/screens/HomeScreen.brs
grep -q "m.historyTotalItems" components/screens/HomeScreen.brs
grep -q "m.historyCountLabel" components/screens/HomeScreen.brs
grep -q "renderHistoryCount" components/screens/HomeScreen.brs
grep -q "updateHistoryScrollChevrons" components/screens/HomeScreen.brs
grep -q "hasMoreHistoryPages" components/screens/HomeScreen.brs
grep -q "loadNextHistoryPageIfNeeded" components/screens/HomeScreen.brs
grep -q "final four loaded cards" components/screens/HomeScreen.brs
grep -q "fallback.visible = true" components/screens/HomeScreen.brs
grep -q "selectedHistoryIndex" components/screens/HomeScreen.brs
grep -q "firstSeenSeconds" source/services/KinoHistoryService.brs
grep -q "lastSeenSeconds" source/services/KinoHistoryService.brs
grep -q "watchCount" source/services/KinoHistoryService.brs
grep -q "firstSeenSeconds: selectedItem.firstSeenSeconds" components/screens/HomeScreen.brs
grep -q "lastSeenSeconds: selectedItem.lastSeenSeconds" components/screens/HomeScreen.brs
grep -q "watchCount: selectedItem.watchCount" components/screens/HomeScreen.brs
grep -q "videoSelected" components/screens/HomeScreen.xml
grep -q "videoSelected" components/screens/HomeScreen.brs
grep -q "showVideoDetailScreen" components/AppScene.brs
grep -q "m.homeScreen = homeScreen" components/AppScene.brs
grep -q "m.homeScreen.visible = false" components/AppScene.brs
grep -q "restoreHomeScreen()" components/AppScene.brs
grep -q "sub restoreHomeScreen()" components/AppScene.brs
grep -q "m.homeScreen.visible = true" components/AppScene.brs
grep -q "VideoDetailScreen" components/AppScene.brs
grep -q "backRequested" components/screens/VideoDetailScreen.xml
grep -q "playbackErrorLabel" components/screens/VideoDetailScreen.xml
grep -q 'id="heroArtworkPoster"' components/screens/VideoDetailScreen.xml
grep -q 'loadDisplayMode="scaleToFit"' components/screens/VideoDetailScreen.xml
grep -q "episodeScrollUpChevron" components/screens/VideoDetailScreen.xml
grep -q "episodeScrollDownChevron" components/screens/VideoDetailScreen.xml
grep -q 'id="historyMetaGroup"' components/screens/VideoDetailScreen.xml
grep -q 'id="historyMetaLabel"' components/screens/VideoDetailScreen.xml
grep -q 'id="trailerGroup"' components/screens/VideoDetailScreen.xml
grep -q 'id="trailerFocusBg"' components/screens/VideoDetailScreen.xml
grep -q 'id="similarGroup"' components/screens/VideoDetailScreen.xml
grep -q 'id="similarHost"' components/screens/VideoDetailScreen.xml
grep -q 'id="similarCursor"' components/screens/VideoDetailScreen.xml
grep -q "m.historyMetaGroup = m.top.findNode(\"historyMetaGroup\")" components/screens/VideoDetailScreen.brs
grep -q "m.historyMetaLabel = m.top.findNode(\"historyMetaLabel\")" components/screens/VideoDetailScreen.brs
grep -q "m.trailerGroup = m.top.findNode(\"trailerGroup\")" components/screens/VideoDetailScreen.brs
grep -q "m.similarGroup = m.top.findNode(\"similarGroup\")" components/screens/VideoDetailScreen.brs
grep -q "renderHistoryMetadata()" components/screens/VideoDetailScreen.brs
grep -q "m.historyMetaGroup.visible = false" components/screens/VideoDetailScreen.brs
grep -q "applyHistoryMetadataLayout(false)" components/screens/VideoDetailScreen.brs
grep -q "applyHistoryMetadataLayout(true)" components/screens/VideoDetailScreen.brs
grep -q "historyMetadataText" components/screens/VideoDetailScreen.brs
grep -q "renderDetailExtras()" components/screens/VideoDetailScreen.brs
grep -q "m.trailerGroup.visible = false" components/screens/VideoDetailScreen.brs
grep -q "m.similarGroup.visible = false" components/screens/VideoDetailScreen.brs
grep -q "startTrailerPlayback()" components/screens/VideoDetailScreen.brs
grep -q "selectSimilarItem()" components/screens/VideoDetailScreen.brs
grep -q 'source: "similar"' components/screens/VideoDetailScreen.brs
grep -q "seasonTabPanelWidth" components/screens/VideoDetailScreen.brs
grep -q "episodeListY" components/screens/VideoDetailScreen.brs
grep -q "updateEpisodeListLayout" components/screens/VideoDetailScreen.brs
grep -q "episodeScrollUpChevron" components/screens/VideoDetailScreen.brs
grep -q "updateEpisodeScrollChevrons" components/screens/VideoDetailScreen.brs
grep -q "visibleEpisodeStart + m.maxVisibleEpisodes" components/screens/VideoDetailScreen.brs
if grep -q 'id="backdropPoster".*loadDisplayMode="scaleToFill"' components/screens/VideoDetailScreen.xml; then
  echo "Video detail hero image must not stretch artwork with scaleToFill." >&2
  exit 1
fi
grep -q "loadItemDetail" components/tasks/ContentTask.brs
grep -q "KinoItemService" components/tasks/ContentTask.xml
grep -q "KinoItemService" source/services/KinoItemService.brs
grep -q '"/v1/items/"' source/services/KinoItemService.brs
grep -q "similar: kinoItemSimilar" source/services/KinoItemService.brs
grep -q "trailer: kinoItemTrailer" source/services/KinoItemService.brs
grep -q '"/v1/items/similar"' source/services/KinoItemService.brs
grep -q '"/v1/items/trailer"' source/services/KinoItemService.brs
grep -q "normalizeSimilarResponse" source/services/KinoItemService.brs
grep -q "normalizeTrailerResponse" source/services/KinoItemService.brs
grep -q "detailFacts: m.detailFacts(item)" source/services/KinoItemService.brs
grep -q "detailFacts: kinoItemDetailFacts" source/services/KinoItemService.brs
grep -q "appendFact: kinoItemAppendFact" source/services/KinoItemService.brs
grep -q '"Director"' source/services/KinoItemService.brs
grep -q '"Cast"' source/services/KinoItemService.brs
grep -q '"Voice"' source/services/KinoItemService.brs
grep -q '"Quality"' source/services/KinoItemService.brs
grep -q '"Ratings"' source/services/KinoItemService.brs
grep -q '"Series"' source/services/KinoItemService.brs
grep -q "m.detailFactsGroup = m.top.findNode(\"detailFactsGroup\")" components/screens/VideoDetailScreen.brs
grep -q "m.detailFactsHost = m.top.findNode(\"detailFactsHost\")" components/screens/VideoDetailScreen.brs
grep -q 'id="detailFactsGroup"' components/screens/VideoDetailScreen.xml
grep -q 'id="detailFactsHost"' components/screens/VideoDetailScreen.xml
grep -q "renderDetailFacts()" components/screens/VideoDetailScreen.brs
grep -q "m.detailFactsGroup.visible = false" components/screens/VideoDetailScreen.brs
grep -q "createDetailFactRow" components/screens/VideoDetailScreen.brs
grep -q "normalizeVideos" source/services/KinoItemService.brs
grep -q "normalizeSeasons" source/services/KinoItemService.brs
grep -q "streamUrl" source/services/KinoItemService.brs
grep -q "qualityOptions" source/services/KinoItemService.brs
grep -q "videoNumber" source/services/KinoItemService.brs
grep -q "watchStatus = m.watchStatus(media)" source/services/KinoItemService.brs
grep -q "watchStatus: kinoItemWatchStatus" source/services/KinoItemService.brs
grep -q "function kinoItemWatchStatus" source/services/KinoItemService.brs
grep -q 'm.integerField(media.watching, "status", -1)' source/services/KinoItemService.brs
grep -q "audioTracks" source/services/KinoItemService.brs
grep -q "subtitleTracks" source/services/KinoItemService.brs
grep -q "kinoItemQualityOptions" source/services/KinoItemService.brs
grep -q "addQualityUrlOptions: kinoItemAddQualityUrlOptions" source/services/KinoItemService.brs
grep -q "sub kinoItemAddQualityUrlOptions" source/services/KinoItemService.brs
grep -q 'hlsKeys = \["hls4", "hls2", "http", "hls"\]' source/services/KinoItemService.brs
grep -q 'for each key in \["hls4", "hls2", "http", "hls"\]' source/services/KinoItemService.brs
grep -q 'if key = "http" then format = "mp4"' source/services/KinoItemService.brs
grep -q "kinoItemTrackOptions" source/services/KinoItemService.brs
grep -q "similarResult = itemService.similar" components/tasks/ContentTask.brs
grep -q "trailerResult = itemService.trailer" components/tasks/ContentTask.brs
grep -q "result.item.similarItems = similarResult.items" components/tasks/ContentTask.brs
grep -q "result.item.trailer = trailerResult.trailer" components/tasks/ContentTask.brs
grep -q "KinoSearchService.brs" components/tasks/ContentTask.xml
grep -q "KinoSearchService(client)" components/tasks/ContentTask.brs
grep -q "searchItems" components/tasks/ContentTask.brs
grep -q "contentTaskSearchItems" components/tasks/ContentTask.brs
grep -q "KinoSearchService" source/services/KinoSearchService.brs
grep -q '"/v1/items"' source/services/KinoSearchService.brs
grep -q "queryParams\\[normalizedField\\] = trimmedQuery" source/services/KinoSearchService.brs
grep -q "if selectedType <> \"\" then queryParams.type = selectedType" source/services/KinoSearchService.brs
if grep -q '"/v1/items/search"' source/services/KinoSearchService.brs; then
  echo "Search service must use /v1/items with title filtering, not /v1/items/search." >&2
  exit 1
fi
if grep -q "sectioned: 0" source/services/KinoSearchService.brs; then
  echo "Search service must not send sectioned for /v1/items title filtering." >&2
  exit 1
fi
grep -q "normalizeResponse" source/services/KinoSearchService.brs
grep -q "normalizeItem" source/services/KinoSearchService.brs
grep -q "KinoUserService.brs" components/tasks/ContentTask.xml
grep -q "KinoUserService(client)" components/tasks/ContentTask.brs
grep -q "loadUserInfo" components/tasks/ContentTask.brs
grep -q "contentTaskLoadUserInfo" components/tasks/ContentTask.brs
grep -q "KinoUserService" source/services/KinoUserService.brs
grep -q '"/v1/user"' source/services/KinoUserService.brs
grep -q "normalizeResponse" source/services/KinoUserService.brs
grep -q "subscriptionDaysLeft" source/services/KinoUserService.brs
grep -q "searchQueryLabel" components/screens/HomeScreen.xml
grep -q 'id="searchTypeFilterBg"' components/screens/HomeScreen.xml
grep -q 'id="searchFieldFilterBg"' components/screens/HomeScreen.xml
grep -q 'id="searchSortFilterBg"' components/screens/HomeScreen.xml
grep -q 'id="searchPickerGroup"' components/screens/HomeScreen.xml
grep -q "m.searchSortByYear = true" components/screens/HomeScreen.brs
grep -q "m.searchRequestSortByYear = m.searchSortByYear" components/screens/HomeScreen.brs
grep -q "sortByYear: m.searchSortByYear" components/screens/HomeScreen.brs
grep -q "response.sortByYear <> m.searchSortByYear" components/screens/HomeScreen.brs
grep -q "sub toggleSearchYearSort" components/screens/HomeScreen.brs
grep -q 'm.searchFocusArea = "filters"' components/screens/HomeScreen.brs
grep -q "searchFieldOptions" components/screens/HomeScreen.brs
grep -q "searchTypeOptions" components/screens/HomeScreen.brs
grep -q "openSearchPicker" components/screens/HomeScreen.brs
grep -q "loadSearchOptionsIfNeeded" components/screens/HomeScreen.brs
grep -q "refreshSubmittedSearchAfterFilterChange" components/screens/HomeScreen.brs
grep -q 'queryParams.sort = "year-"' source/services/KinoSearchService.brs
grep -q 'sortByYear = contentTaskBooleanField(request, "sortByYear", true)' components/tasks/ContentTask.brs
grep -q 'command = "loadSearchOptions"' components/tasks/ContentTask.brs
grep -q "contentType = contentTaskStringField(request, \"contentType\"" components/tasks/ContentTask.brs
grep -q "searchField = LCase(contentTaskStringField(request, \"searchField\"" components/tasks/ContentTask.brs
grep -q "searchService.search(tokenResult.accessToken, query, page, perpage, typeMap, sortByYear, contentType, searchField)" components/tasks/ContentTask.brs
grep -q "searchKeyboardGroup" components/screens/HomeScreen.xml
grep -q "searchKeyboardCursorBg" components/screens/HomeScreen.xml
grep -q "searchResultGridHost" components/screens/HomeScreen.xml
grep -q "searchResultsCountLabel" components/screens/HomeScreen.xml
grep -q "searchResultCursor" components/screens/HomeScreen.xml
grep -q "searchScrollUpChevron" components/screens/HomeScreen.xml
grep -q "searchScrollDownChevron" components/screens/HomeScreen.xml
grep -q "searchNextPageStatus" components/screens/HomeScreen.xml
grep -q "searchScrollUpChevron" components/screens/HomeScreen.brs
grep -q "m.searchTotalItems" components/screens/HomeScreen.brs
grep -q "m.searchResultsCountLabel" components/screens/HomeScreen.brs
grep -q "renderSearchCount" components/screens/HomeScreen.brs
grep -q "function listCountText" components/screens/HomeScreen.brs
grep -q '" videos"' components/screens/HomeScreen.brs
grep -q "updateSearchScrollChevrons" components/screens/HomeScreen.brs
grep -q "hasMoreSearchPages" components/screens/HomeScreen.brs
grep -q "resetSearchState" components/screens/HomeScreen.brs
grep -q 'm.searchTask.control = "STOP"' components/screens/HomeScreen.brs
grep -q 'response.q <> m.searchSubmittedQuery' components/screens/HomeScreen.brs
grep -q 'm.searchFocusArea = "error"' components/screens/HomeScreen.brs
grep -q "renderSearchKeyboard" components/screens/HomeScreen.brs
grep -q "requestSearchPage" components/screens/HomeScreen.brs
grep -q "loadNextSearchPageIfNeeded" components/screens/HomeScreen.brs
grep -q 'source: "search"' components/screens/HomeScreen.brs
grep -q 'm.browseContent.visible = section = "browse"' components/screens/HomeScreen.brs
grep -q 'loadBrowseIfNeeded(false)' components/screens/HomeScreen.brs
grep -q 'function menuEntries' components/screens/HomeScreen.brs
grep -q 'function menuIndexForSection' components/screens/HomeScreen.brs
grep -q 'section = entries\[m.menuIndex\].section' components/screens/HomeScreen.brs
grep -q 'function browseYearOptions' components/screens/HomeScreen.brs
grep -q 'function browseFinishedOptions' components/screens/HomeScreen.brs
grep -q 'sub openBrowsePicker' components/screens/HomeScreen.brs
grep -q 'sub selectBrowsePickerItem' components/screens/HomeScreen.brs
grep -q 'sub requestBrowsePage' components/screens/HomeScreen.brs
grep -q 'function createBrowseCard' components/screens/HomeScreen.brs
grep -q 'm.top.videoSelected = item' components/screens/HomeScreen.brs
grep -q 'm.accountContent.visible = section = "account"' components/screens/HomeScreen.brs
grep -q 'loadAccountInfo' components/screens/HomeScreen.brs
grep -q 'onAccountInfoResponse' components/screens/HomeScreen.brs
grep -q 'renderAccountInfo' components/screens/HomeScreen.brs
grep -q 'm.menuIndex >= entries.Count()' components/screens/HomeScreen.brs
grep -q "updateBookmarkScrollChevrons" components/screens/HomeScreen.brs
grep -q "hasMoreBookmarkPages" components/screens/HomeScreen.brs
grep -q "loadNextBookmarkPageIfNeeded" components/screens/HomeScreen.brs
grep -q "requestBookmarkFolderItems(m.bookmarkCurrentFolderId, m.bookmarkCurrentPage + 1, true)" components/screens/HomeScreen.brs
grep -q 'showSection(section)' components/screens/HomeScreen.brs
grep -q 'KinoTvService.brs' components/tasks/ContentTask.xml
grep -q 'KinoTvService(client)' components/tasks/ContentTask.brs
grep -q 'command = "probeLiveTv" or command = "loadLiveTv"' components/tasks/ContentTask.brs
grep -q 'm.client.get("/v1/tv"' source/services/KinoTvService.brs
grep -q 'function kinoTvNormalizeResponse' source/services/KinoTvService.brs
grep -q 'artworkUrl: kinoTvArtworkUrl' source/services/KinoTvService.brs
grep -q 'function kinoTvArtworkUrl' source/services/KinoTvService.brs
grep -q 'containers = \["channel", "event", "item", "station", "metadata", "data"\]' source/services/KinoTvService.brs
grep -q 'typeBadge: "LIVE"' source/services/KinoTvService.brs
grep -q 'id="liveNav".*visible="false"' components/screens/HomeScreen.xml
grep -q 'id="liveContent".*visible="false"' components/screens/HomeScreen.xml
grep -q 'field id="livePlaybackSelected"' components/screens/HomeScreen.xml
grep -q 'probeLiveTv()' components/screens/HomeScreen.brs
grep -q 'setLiveAvailable(m.liveItems.Count() > 0)' components/screens/HomeScreen.brs
grep -q 'if m.liveAvailable then entries.Push' components/screens/HomeScreen.brs
grep -q 'm.top.livePlaybackSelected' components/screens/HomeScreen.brs
grep -q 'function createLiveCard' components/screens/HomeScreen.brs
grep -q 'logo.loadDisplayMode = "scaleToFit"' components/screens/HomeScreen.brs
grep -q 'homeScreen.observeField("livePlaybackSelected", "onLivePlaybackSelected")' components/AppScene.brs
grep -q 'sub onLivePlaybackSelected' components/AppScene.brs
grep -q 'function isLivePlayback' components/screens/PlayerScreen.brs
grep -q 'if isLivePlayback() then return' components/screens/PlayerScreen.brs
grep -q 'm.timeLabel.text = "LIVE"' components/screens/PlayerScreen.brs
grep -q "No playable video is available" components/screens/VideoDetailScreen.xml
grep -q 'field id="playbackRequested"' components/screens/VideoDetailScreen.xml
grep -q 'field id="playbackError"' components/screens/VideoDetailScreen.xml
grep -q "playbackPayloadForMedia" components/screens/VideoDetailScreen.brs
grep -q "episodeWatchStatus" components/screens/VideoDetailScreen.brs
grep -q "episodeProgressText" components/screens/VideoDetailScreen.brs
grep -q 'id="descriptionFocusBg"' components/screens/VideoDetailScreen.xml
grep -q 'id="descriptionOverlayGroup"' components/screens/VideoDetailScreen.xml
grep -q 'id="bookmarkActionGroup"' components/screens/VideoDetailScreen.xml
grep -q 'id="bookmarkOverlayGroup"' components/screens/VideoDetailScreen.xml
grep -q "loadItemBookmarkFolders" components/screens/VideoDetailScreen.brs
grep -q "toggleSelectedBookmarkFolder" components/screens/VideoDetailScreen.brs
grep -q 'id="descriptionOverlayTextLabel"' components/screens/VideoDetailScreen.xml
grep -q 'id="descriptionOverlayScrollUpChevron"' components/screens/VideoDetailScreen.xml
grep -q 'id="descriptionOverlayScrollDownChevron"' components/screens/VideoDetailScreen.xml
grep -q "m.descriptionFocusBg" components/screens/VideoDetailScreen.brs
grep -q "m.descriptionOverlayGroup" components/screens/VideoDetailScreen.brs
grep -q "m.descriptionOverlayTextLabel" components/screens/VideoDetailScreen.brs
grep -q "m.descriptionOverlayScrollStart" components/screens/VideoDetailScreen.brs
grep -q "sub openDescriptionOverlay" components/screens/VideoDetailScreen.brs
grep -q "sub closeDescriptionOverlay" components/screens/VideoDetailScreen.brs
grep -q "sub scrollDescriptionOverlay" components/screens/VideoDetailScreen.brs
grep -q "function descriptionOverlayLines" components/screens/VideoDetailScreen.brs
grep -q "sub updateDescriptionFocusVisual" components/screens/VideoDetailScreen.brs
grep -q 'if m.descriptionOverlayGroup.visible' components/screens/VideoDetailScreen.brs
grep -q 'openDescriptionOverlay()' components/screens/VideoDetailScreen.brs
grep -q 'm.focusArea = "description"' components/screens/VideoDetailScreen.brs
grep -q "appendWatchedCheck" components/screens/VideoDetailScreen.brs
grep -q "progressText = episodeProgressText(episode)" components/screens/VideoDetailScreen.brs
grep -q "watchStatus: media.watchStatus" components/screens/VideoDetailScreen.brs
grep -q "m.top.playbackRequested" components/screens/VideoDetailScreen.brs
grep -q 'mediaLinks: kinoItemMediaLinks' source/services/KinoItemService.brs
grep -q 'normalizeMediaLinksResponse: kinoItemNormalizeMediaLinksResponse' source/services/KinoItemService.brs
grep -q 'mergeMediaLinkFields: kinoItemMergeMediaLinkFields' source/services/KinoItemService.brs
grep -q '"/v1/items/media-links"' source/services/KinoItemService.brs
grep -q 'if sourceAudio.Count() = 0 then sourceAudio = m.arrayField(media, "audios")' source/services/KinoItemService.brs
grep -q 'command = "refreshMediaLinks"' components/tasks/ContentTask.brs
grep -q 'contentTaskRefreshMediaLinks' components/tasks/ContentTask.brs
grep -q 'itemService.mediaLinks(tokenResult.accessToken, media)' components/tasks/ContentTask.brs
grep -q 'm.pendingPlaybackMediaId = 0' components/screens/VideoDetailScreen.brs
grep -q 'm.playbackErrorLabel.text = "Preparing video..."' components/screens/VideoDetailScreen.brs
grep -q 'task.command = "refreshMediaLinks"' components/screens/VideoDetailScreen.brs
grep -q 'sub onMediaLinksRefreshResponse' components/screens/VideoDetailScreen.brs
grep -q 'm.top.playbackRequested = fallbackPayload' components/screens/VideoDetailScreen.brs
grep -q "m.posterFallback.visible = true" components/screens/VideoDetailScreen.brs
grep -q "showPlayerScreen" components/AppScene.brs
grep -q "onPlaybackRequested" components/AppScene.brs
grep -q "onPlayerExitRequested" components/AppScene.brs
grep -q 'field id="reloadRequested"' components/screens/VideoDetailScreen.xml
grep -q 'field id="reloadRequested" type="boolean" alwaysNotify="true"' components/screens/VideoDetailScreen.xml
grep -q 'm.top.observeField("reloadRequested", "onReloadRequested")' components/screens/VideoDetailScreen.brs
grep -q "sub onReloadRequested" components/screens/VideoDetailScreen.brs
grep -q "m.detailScreen.reloadRequested = true" components/AppScene.brs
grep -q "targetSeasonNumber" components/AppScene.brs
grep -q "targetEpisodeNumber" components/AppScene.brs
grep -q "targetSeasonNumber" components/tasks/ContentTask.brs
grep -q "targetEpisodeNumber" components/tasks/ContentTask.brs
grep -q "selectTargetEpisodeFromResponse" components/screens/VideoDetailScreen.brs
grep -q "PlayerScreen" components/AppScene.brs
grep -q 'playerScreen.id = "playerScreen"' components/AppScene.brs
grep -q 'removeScreenHostChild("playerScreen")' components/AppScene.brs
grep -q "function removeScreenHostChild" components/AppScene.brs
if grep -q "getChild(index) = child" components/AppScene.brs; then
  echo "AppScene must not compare SceneGraph node objects directly." >&2
  exit 1
fi
grep -q "KinoWatchingService.brs" components/tasks/ContentTask.xml
grep -q "KinoWatchingService(client)" components/tasks/ContentTask.brs
grep -q "savePlaybackProgress" components/tasks/ContentTask.brs
grep -q "markPlaybackWatched" components/tasks/ContentTask.brs
grep -q 'command = "loadContinueSummary"' components/tasks/ContentTask.brs
grep -q 'command = "loadContinueHistoryPage"' components/tasks/ContentTask.brs
grep -q 'command = "loadContinueNewEpisodesPage"' components/tasks/ContentTask.brs
grep -q "contentTaskLoadContinueSummary" components/tasks/ContentTask.brs
grep -q "contentTaskLoadContinueHistoryPage" components/tasks/ContentTask.brs
grep -q "contentTaskLoadContinueNewEpisodesPage" components/tasks/ContentTask.brs
grep -q 'listSerials: kinoWatchingListSerials' source/services/KinoWatchingService.brs
grep -q '"/v1/watching/marktime"' source/services/KinoWatchingService.brs
grep -q '"/v1/watching/toggle"' source/services/KinoWatchingService.brs
grep -q '"/v1/watching/serials"' source/services/KinoWatchingService.brs
grep -q "normalizeSerialsResponse" source/services/KinoWatchingService.brs
grep -q "normalizeSerialEntry" source/services/KinoWatchingService.brs
grep -q "normalizeWatchingPagination" source/services/KinoWatchingService.brs
grep -q "function PlayerPreferenceStore" source/services/PlayerPreferenceStore.brs
grep -q "playerprefs" source/services/PlayerPreferenceStore.brs

./scripts/tests/next-episode-flow.sh
grep -q "playerPreferenceLoad" source/services/PlayerPreferenceStore.brs
grep -q "playerPreferenceSave" source/services/PlayerPreferenceStore.brs
grep -q "playerPreferenceIntegerField" source/services/PlayerPreferenceStore.brs
grep -q "keyForSeries: playerPreferenceKeyForSeries" source/services/PlayerPreferenceStore.brs
grep -q "loadKey: playerPreferenceLoadKey" source/services/PlayerPreferenceStore.brs
grep -q "mergePreferences: playerPreferenceMerge" source/services/PlayerPreferenceStore.brs
grep -q "series:" source/services/PlayerPreferenceStore.brs
grep -q "seriesPreferences = m.loadKey(seriesKey)" source/services/PlayerPreferenceStore.brs
grep -q "mediaPreferences = m.loadKey(mediaKey)" source/services/PlayerPreferenceStore.brs
grep -q "m.mergePreferences(seriesPreferences, mediaPreferences)" source/services/PlayerPreferenceStore.brs
grep -q "section.Write(seriesKey, FormatJson(preferences))" source/services/PlayerPreferenceStore.brs
grep -q '"media:"' source/services/PlayerPreferenceStore.brs
grep -q '"item:"' source/services/PlayerPreferenceStore.brs
grep -q '<component name="PlayerScreen"' components/screens/PlayerScreen.xml
grep -q '<field id="playback" type="assocarray"' components/screens/PlayerScreen.xml
grep -q '<field id="exitRequested" type="boolean"' components/screens/PlayerScreen.xml
grep -q '<field id="exitRequested" type="boolean" alwaysNotify="true"' components/screens/PlayerScreen.xml
grep -q '<field id="playbackError" type="string"' components/screens/PlayerScreen.xml
grep -q '<field id="playbackError" type="string" alwaysNotify="true"' components/screens/PlayerScreen.xml
grep -q '<Video id="videoNode"' components/screens/PlayerScreen.xml
grep -q 'bottomRailGroup' components/screens/PlayerScreen.xml
grep -q 'id="bottomRailBackground"' components/screens/PlayerScreen.xml
grep -q 'railHideTimer' components/screens/PlayerScreen.xml
grep -q '<Timer id="railHideTimer" repeat="false" duration="4"' components/screens/PlayerScreen.xml
grep -q 'progressTimer' components/screens/PlayerScreen.xml
grep -q '<Timer id="progressTimer" repeat="true" duration="60"' components/screens/PlayerScreen.xml
grep -q 'resumePromptGroup' components/screens/PlayerScreen.xml
grep -q '<Timer id="resumePromptTimer" repeat="true" duration="1"' components/screens/PlayerScreen.xml
grep -q 'PlayerPreferenceStore.brs' components/screens/PlayerScreen.xml
grep -q 'PlayerScreen.brs' components/screens/PlayerScreen.xml
grep -q 'sub onPlaybackChanged' components/screens/PlayerScreen.brs
grep -q 'function playbackTitle' components/screens/PlayerScreen.brs
grep -q 'enableUI="false"' components/screens/PlayerScreen.xml
grep -q "m.videoNode.enableUI = false" components/screens/PlayerScreen.brs
grep -q "itemTitle:" components/screens/VideoDetailScreen.brs
grep -q "m.playback.itemTitle" components/screens/PlayerScreen.brs
grep -q 'sub buildControls' components/screens/PlayerScreen.brs
grep -q 'sub applyBottomRailLayout' components/screens/PlayerScreen.brs
grep -q 'railY = 516' components/screens/PlayerScreen.brs
grep -q 'railY = 400' components/screens/PlayerScreen.brs
grep -q 'railY = 550' components/screens/PlayerScreen.brs
grep -q 'm.bottomRailBackground.height = railHeight' components/screens/PlayerScreen.brs
grep -q 'm.controlFocusY = controlsY' components/screens/PlayerScreen.brs
grep -q 'sub showRail' components/screens/PlayerScreen.brs
grep -q 'function formatTime' components/screens/PlayerScreen.brs
grep -q 'function onKeyEvent' components/screens/PlayerScreen.brs
grep -q "startPlayback" components/screens/PlayerScreen.brs
grep -q "logPlaybackStart()" components/screens/PlayerScreen.brs
grep -q "function playbackStreamOptions" components/screens/PlayerScreen.brs
grep -q "sub addPlaybackStreamOption" components/screens/PlayerScreen.brs
grep -q "function hlsDirectMediaPlaylistUrl" components/screens/PlayerScreen.brs
grep -q 'marker = "master-v"' components/screens/PlayerScreen.brs
grep -q 'directName = "index-v" + videoId + "-a" + audioId + extension' components/screens/PlayerScreen.brs
grep -q 'label: label + " media"' components/screens/PlayerScreen.brs
grep -q "function currentPlaybackStream" components/screens/PlayerScreen.brs
grep -q "function tryNextPlaybackStream" components/screens/PlayerScreen.brs
grep -q "if tryNextPlaybackStream() then return" components/screens/PlayerScreen.brs
grep -q "m.videoNode.audioTrack = trackId" components/screens/PlayerScreen.brs
grep -q 'm.preferences\["audioTrackId"\]' components/screens/PlayerScreen.brs
grep -q 'm.preferences\["audioTrackLabel"\]' components/screens/PlayerScreen.brs
grep -q 'm.preferences\["audioTrackLanguage"\]' components/screens/PlayerScreen.brs
grep -q "m.preferenceStore.save(m.playback, m.preferences)" components/screens/PlayerScreen.brs
grep -q "applySavedAudioPreference()" components/screens/PlayerScreen.brs
grep -q "findSavedAudioTrack" components/screens/PlayerScreen.brs
grep -q 'm.preferences\["audioCurrentTrack"\] = trackId' components/screens/PlayerScreen.brs
grep -q "sub configureVideoHttpAgent" components/screens/PlayerScreen.brs
grep -q 'CreateObject("roHttpAgent")' components/screens/PlayerScreen.brs
grep -q 'AddHeader("User-Agent", "Roku/DVP-12.0 (12.0.0.0)")' components/screens/PlayerScreen.brs
grep -q "m.videoNode.setHttpAgent(m.videoHttpAgent)" components/screens/PlayerScreen.brs
grep -q 'content.HttpHeaders = \["User-Agent: Roku/DVP-12.0 (12.0.0.0)"\]' components/screens/PlayerScreen.brs
grep -q 'id="streamLoaderGroup"' components/screens/PlayerScreen.xml
grep -q 'id="streamLoaderPercentLabel"' components/screens/PlayerScreen.xml
grep -q 'id="streamLoaderFill"' components/screens/PlayerScreen.xml
grep -q '<Timer id="bufferingDebounceTimer" repeat="false" duration="1.2"' components/screens/PlayerScreen.xml
grep -q 'm.streamLoaderGroup = m.top.findNode("streamLoaderGroup")' components/screens/PlayerScreen.brs
grep -q 'm.bufferingDebounceTimer = m.top.findNode("bufferingDebounceTimer")' components/screens/PlayerScreen.brs
grep -q 'm.bufferingDebounceTimer.observeField("fire", "onBufferingDebounceTimer")' components/screens/PlayerScreen.brs
grep -q 'm.videoNode.observeField("bufferingStatus", "onVideoBufferingStatusChanged")' components/screens/PlayerScreen.brs
grep -q 'showStreamLoader("Loading stream")' components/screens/PlayerScreen.brs
grep -q 'showStreamLoader("Buffering")' components/screens/PlayerScreen.brs
grep -q 'startBufferingDebounce()' components/screens/PlayerScreen.brs
grep -q 'sub onBufferingDebounceTimer' components/screens/PlayerScreen.brs
grep -q 'hideStreamLoader()' components/screens/PlayerScreen.brs
grep -q 'function streamLoaderPercent' components/screens/PlayerScreen.brs
if grep -A 8 'else if state = "error"' components/screens/PlayerScreen.brs | grep -q 'sendProgressUpdate("error")'; then
  echo "Playback errors must not save progress while probing fallback streams." >&2
  exit 1
fi
grep -q "m.playbackStarted = false" components/screens/PlayerScreen.brs
grep -q "m.playbackStarted = true" components/screens/PlayerScreen.brs
grep -q "if m.playbackStarted <> true" components/screens/PlayerScreen.brs
grep -q "m.top.playbackError = \"Unable to play this video. Stream ended before playback started.\"" components/screens/PlayerScreen.brs
grep -q "PlayerScreen: stream finished before playback started" components/screens/PlayerScreen.brs
grep -q "PlayerScreen: retrying playback with stream option=" components/screens/PlayerScreen.brs
grep -q "function videoErrorDetails" components/screens/PlayerScreen.brs
grep -q "m.videoNode.errorCode" components/screens/PlayerScreen.brs
grep -q "m.videoNode.errorMsg" components/screens/PlayerScreen.brs
grep -q "m.videoNode.errorStr" components/screens/PlayerScreen.brs
grep -q "m.videoNode.errorInfo" components/screens/PlayerScreen.brs
grep -q "print \"PlayerScreen: video state=\"; state" components/screens/PlayerScreen.brs
grep -q "printVideoErrorDiagnostics()" components/screens/PlayerScreen.brs
grep -q "print \"PlayerScreen: video error" components/screens/PlayerScreen.brs
grep -q "resumeStartSeconds" components/screens/PlayerScreen.brs
grep -q "showResumePrompt" components/screens/PlayerScreen.brs
grep -q "startPlaybackAtPosition" components/screens/PlayerScreen.brs
grep -q "m.resumeCountdownSeconds = 15" components/screens/PlayerScreen.brs
grep -q "onResumePromptTimer" components/screens/PlayerScreen.brs
grep -q "handleResumePromptKey" components/screens/PlayerScreen.brs
grep -q "chooseResumePromptOption" components/screens/PlayerScreen.brs
grep -q "restartPlaybackFromBeginning()" components/screens/PlayerScreen.brs
grep -q "m.videoNode.control = \"stop\"" components/screens/PlayerScreen.brs
if grep -A 8 "sub startPlaybackAtPosition" components/screens/PlayerScreen.brs | grep -q 'm.videoNode.control = "stop"'; then
  echo "Normal playback start must not stop the freshly assigned Video content before play." >&2
  exit 1
fi
if ! grep -A 8 "sub restartPlaybackFromBeginning" components/screens/PlayerScreen.brs | grep -q 'm.videoNode.content = playbackContentNode'; then
  echo "Start from beginning must rebuild content before playing from 0." >&2
  exit 1
fi
grep -q "savePlaybackProgress" components/screens/PlayerScreen.brs
grep -q "sendProgressUpdate" components/screens/PlayerScreen.brs
grep -q 'if reason = "start" and position < 15 then return' components/screens/PlayerScreen.brs
grep -q "markCompletedIfSafe" components/screens/PlayerScreen.brs
grep -q "markPlaybackWatched" components/screens/PlayerScreen.brs
grep -q "seekBy" components/screens/PlayerScreen.brs
grep -q '<Rectangle id="progressFocus"' components/screens/PlayerScreen.xml
grep -q '<Timer id="seekDebounceTimer" repeat="false" duration="0.45"' components/screens/PlayerScreen.xml
grep -q '<Timer id="seekSettleTimer" repeat="false" duration="2.5"' components/screens/PlayerScreen.xml
grep -q 'm.focusArea = "controls"' components/screens/PlayerScreen.brs
grep -q 'm.seekDebounceTimer.observeField("fire", "onSeekDebounceTimer")' components/screens/PlayerScreen.brs
grep -q 'm.seekSettleTimer.observeField("fire", "onSeekSettleTimer")' components/screens/PlayerScreen.brs
grep -q "function isTransportKey" components/screens/PlayerScreen.brs
grep -q 'key = "rewind"' components/screens/PlayerScreen.brs
grep -q 'key = "fastforward"' components/screens/PlayerScreen.brs
grep -q "function handleProgressKey" components/screens/PlayerScreen.brs
grep -q "m.pendingSeekPosition" components/screens/PlayerScreen.brs
grep -q "sub clearPendingSeek" components/screens/PlayerScreen.brs
grep -q "sub updateSeekSettle" components/screens/PlayerScreen.brs
grep -q "sub applyPendingSeek" components/screens/PlayerScreen.brs
grep -q "exitPlayer" components/screens/PlayerScreen.brs
grep -q "openMenu" components/screens/PlayerScreen.brs
grep -q "handleMenuKey" components/screens/PlayerScreen.brs
grep -q "audioMenuItems" components/screens/PlayerScreen.brs
grep -q "subtitleMenuItems" components/screens/PlayerScreen.brs
grep -q "qualityMenuItems" components/screens/PlayerScreen.brs
grep -q "applyAudioSelection" components/screens/PlayerScreen.brs
grep -q "applySubtitleSelection" components/screens/PlayerScreen.brs
grep -q "applyQualitySelection" components/screens/PlayerScreen.brs
grep -q "contentSubtitleTracks" components/screens/PlayerScreen.brs
grep -q 'setStatusMessage("Audio: " + selectedAudioLabel(), true)' components/screens/PlayerScreen.brs
grep -q 'setStatusMessage("Subtitles: " + selectedSubtitleLabel(), true)' components/screens/PlayerScreen.brs
grep -q 'setStatusMessage("Quality: " + selectedQualityLabel(), true)' components/screens/PlayerScreen.brs
grep -q 'm.videoNode.subtitleTrack = trackName' components/screens/PlayerScreen.brs
grep -q 'm.videoNode.globalCaptionMode = "On"' components/screens/PlayerScreen.brs
grep -q 'm.videoNode.globalCaptionMode = "Off"' components/screens/PlayerScreen.brs
if grep -q "m.videoNode.suppressCaptions" components/screens/PlayerScreen.brs; then
  echo "Subtitle selection must use caption mode instead of suppressCaptions." >&2
  exit 1
fi
grep -q "content.SubtitleTracks = subtitleTracks" components/screens/PlayerScreen.brs
grep -q "content.SubtitleConfig = { TrackName: preferredSubtitleTrackName }" components/screens/PlayerScreen.brs
if ! grep -A 20 "sub startPlayback" components/screens/PlayerScreen.brs | grep -q "applySavedQualityPreference()"; then
  echo "Saved quality preference must be applied before playback content is created." >&2
  exit 1
fi
if grep -A 20 "sub startPlayback" components/screens/PlayerScreen.brs | grep -q "applySavedPreferences()"; then
  echo "Debug playback isolation must not apply saved audio/subtitle preferences on startup." >&2
  exit 1
fi
grep -q "m.controlFocusY = 234" components/screens/PlayerScreen.brs
grep -q "m.focusCursor.translation = \\[m.controlPositions\\[m.focusIndex\\], m.controlFocusY\\]" components/screens/PlayerScreen.brs
grep -q "updatePlayPauseControlLabel()" components/screens/PlayerScreen.brs
grep -q "updateControlLabels()" components/screens/PlayerScreen.brs
grep -q "selectedQualityLabel()" components/screens/PlayerScreen.brs
grep -q "selectedAudioLabel()" components/screens/PlayerScreen.brs
grep -q "selectedSubtitleLabel()" components/screens/PlayerScreen.brs
grep -q 'm.videoNode.observeField("availableAudioTracks", "onAvailableAudioTracksChanged")' components/screens/PlayerScreen.brs
grep -q "sub onAvailableAudioTracksChanged" components/screens/PlayerScreen.brs
grep -q "applySavedAudioPreference()" components/screens/PlayerScreen.brs
grep -q 'for each key in \["Track", "track", "TrackName", "trackName", "id", "Id", "ID", "url"\]' components/screens/PlayerScreen.brs
grep -q 'for each key in \["Name", "name", "Description", "description", "label", "title", "language", "Language", "lang"\]' components/screens/PlayerScreen.brs
grep -q "label = trackLabel(track)" components/screens/PlayerScreen.brs
grep -q 'if label = "" then label = "Audio " + StrI(items.Count() + 1).Trim()' components/screens/PlayerScreen.brs
grep -q "m.maxVisibleMenuItems = 6" components/screens/PlayerScreen.brs
grep -q "m.menuScrollStart = 0" components/screens/PlayerScreen.brs
grep -q "ensureMenuSelectionVisible()" components/screens/PlayerScreen.brs
grep -q "visibleIndex = index - m.menuScrollStart" components/screens/PlayerScreen.brs
grep -q "StrI(m.menuItems.Count()).Trim()" components/screens/PlayerScreen.brs
grep -q "subtitleTrackName(track)" components/screens/PlayerScreen.brs
grep -q 'for each key in \["TrackName", "trackName", "url", "Url", "URL"\]' components/screens/PlayerScreen.brs
grep -q "function playbackContentNode" components/screens/PlayerScreen.brs
grep -q "sub reloadPlaybackWithSubtitle" components/screens/PlayerScreen.brs
grep -q "contentSubtitleTracksForPreferred" components/screens/PlayerScreen.brs
grep -q "function savedPreferredSubtitleTrackNameForPlayback" components/screens/PlayerScreen.brs
grep -q "content = playbackContentNode(savedPreferredSubtitleTrackNameForPlayback())" components/screens/PlayerScreen.brs
grep -A 8 "sub onAvailableSubtitleTracksChanged" components/screens/PlayerScreen.brs | grep -q "applySavedSubtitlePreference()"
grep -A 40 "sub applySubtitleSelection" components/screens/PlayerScreen.brs | grep -q "m.videoNode.subtitleTrack = trackName"
grep -q 'm.videoNode.observeField("availableSubtitleTracks", "onAvailableSubtitleTracksChanged")' components/screens/PlayerScreen.brs
grep -q "sub onAvailableSubtitleTracksChanged" components/screens/PlayerScreen.brs
grep -q "applySavedSubtitlePreference()" components/screens/PlayerScreen.brs
grep -q "TrackName: trackName" components/screens/PlayerScreen.brs
grep -q "subtitleMenuItemForAvailableTrack(track)" components/screens/PlayerScreen.brs
grep -q "subtitleSourceTrackForTrackName(trackName)" components/screens/PlayerScreen.brs
if grep -A 12 'for each track in m.videoNode.availableSubtitleTracks' components/screens/PlayerScreen.brs | grep -q 'id: trackIdentifier(track)'; then
  echo "Available subtitle menu items must preserve the current media subtitle id instead of saving Roku TrackName URLs as ids." >&2
  exit 1
fi
if grep -q "TrackName: trackIdentifier(track)" components/screens/PlayerScreen.brs; then
  if grep -A 20 "function contentSubtitleTracks" components/screens/PlayerScreen.brs | grep -q "TrackName: trackIdentifier(track)"; then
    echo "Subtitle ContentNode TrackName must use a playable URL/track name, not language ids such as eng/rus/ukr." >&2
    exit 1
  fi
fi
grep -q "applySavedQualityPreference()" components/screens/PlayerScreen.brs
grep -q "setStatusMessage(\"Progress saved\", true)" components/screens/PlayerScreen.brs
if grep -q 'm.statusLabel.text = "Saved"' components/screens/PlayerScreen.brs; then
  echo "Player progress status must not show a bare Saved label next to controls." >&2
  exit 1
fi

if grep -E "DoesExist\\(\"(accessToken|refreshToken|tokenType|accessExpiresAt|refreshExpiresAt)\"\\)" source/services/TokenStore.brs components/tasks/AuthTask.brs; then
  echo "Token checks must use lowercase registry keys because BrightScript stores associative-array keys lowercased." >&2
  exit 1
fi

if grep -n -B 3 -A 1 "CreateObject(\"roSGNode\", \"AuthTask\")" components/AppScene.brs components/screens/AuthScreen.brs | grep -E "control = \"(start|stop)\""; then
  echo "AuthTask control must use RUN/STOP, not Timer-style start/stop." >&2
  exit 1
fi

if grep -E "= kinoAuthBaseParams\\(|return kinoAuthFailure\\(|then return kinoAuthFailure\\(" source/services/KinoAuthService.brs; then
  echo "Unbound auth helper call found. Helpers that rely on m must be called through the service object." >&2
  exit 1
fi

if grep -E "return kinoApiPost\\(" source/services/KinoApiClient.brs; then
  echo "KinoApiClient methods must call m.post so m stays bound." >&2
  exit 1
fi

if grep -R "\\.Escape(" source components; then
  echo "roUrlTransfer.Escape is not callable on this Roku runtime; use local percent encoding." >&2
  exit 1
fi

if grep -R "\\btostr(" source components; then
  echo "tostr() is not callable on this Roku runtime; use explicit string conversion." >&2
  exit 1
fi

if grep -R -E "\\.Trim\\(\\)\\.(UCase|LCase)\\(" source components; then
  echo "Roku runtime does not support chained Trim().UCase()/Trim().LCase() string calls." >&2
  exit 1
fi

if grep -R -E "\\.(UCase|LCase)\\(" source components; then
  echo "Roku runtime does not support UCase()/LCase() as string member calls; use global UCase(value)/LCase(value)." >&2
  exit 1
fi

if grep -R -E "pkg:/source/services/(KinoApiClient|KinoAuthService|TokenStore)\\.brs|pkg:/source/config/KinoConfig\\.brs" components --include "*.xml" | grep -v "components/tasks/"; then
  echo "Render-thread component loads main/task-only auth service script." >&2
  exit 1
fi

if grep -R "CreateObject(\"roUrlTransfer\")" components; then
  echo "Render-thread components must not create roUrlTransfer directly." >&2
  exit 1
fi

if grep -R "CreateObject(\"roUrlTransfer\")" source components | grep -v "source/services/KinoApiClient.brs"; then
  echo "Direct roUrlTransfer usage found outside KinoApiClient." >&2
  exit 1
fi

./scripts/package.sh >/dev/null
test -f dist/kinopub.zip
unzip -p dist/kinopub.zip manifest | grep -q "mm_icon_focus_hd=pkg:/images/channel-icon_hd.png"
unzip -p dist/kinopub.zip source/config/BuildInfo.brs | grep -q "displayVersion:"
unzip -p dist/kinopub.zip images/channel-icon_hd.png >/dev/null
unzip -p dist/kinopub.zip images/channel-icon_fhd.png >/dev/null
unzip -p dist/kinopub.zip components/screens/PlayerScreen.xml | grep -q "bottomRailGroup"
unzip -p dist/kinopub.zip components/screens/PlayerScreen.brs | grep -q "sendProgressUpdate"
unzip -p dist/kinopub.zip source/services/KinoWatchingService.brs | grep -q '"/v1/watching/marktime"'
unzip -p dist/kinopub.zip source/services/KinoBookmarkService.brs | grep -q '"/v1/bookmarks/toggle-item"'
unzip -p dist/kinopub.zip source/services/KinoItemService.brs | grep -q '"/v1/items/media-links"'
unzip -p dist/kinopub.zip source/services/PlayerPreferenceStore.brs | grep -q "playerprefs"
unzip -p dist/kinopub.zip source/services/KinoSearchService.brs | grep -q '"/v1/items"'
unzip -p dist/kinopub.zip source/services/KinoContentTypeService.brs | grep -q '"/v1/types"'
unzip -p dist/kinopub.zip source/services/KinoTvService.brs | grep -q '"/v1/tv"'
if unzip -p dist/kinopub.zip source/services/KinoSearchService.brs | grep -q '"/v1/items/search"'; then
  echo "Packaged search service must use /v1/items with title filtering, not /v1/items/search." >&2
  exit 1
fi
unzip -p dist/kinopub.zip components/tasks/ContentTask.brs | grep -q "searchItems"
unzip -p dist/kinopub.zip components/tasks/ContentTask.brs | grep -q "refreshMediaLinks"
unzip -p dist/kinopub.zip components/tasks/ContentTask.xml | grep -q "KinoContentTypeService.brs"
unzip -p dist/kinopub.zip components/tasks/ContentTask.xml | grep -q "KinoBookmarkService.brs"
unzip -p dist/kinopub.zip components/screens/HomeScreen.brs | grep 'source: "search"' >/dev/null
unzip -p dist/kinopub.zip components/screens/HomeScreen.brs | grep 'function menuEntries' >/dev/null
unzip -p dist/kinopub.zip components/screens/HomeScreen.brs | grep 'm.top.livePlaybackSelected' >/dev/null
unzip -p dist/kinopub.zip components/screens/HomeScreen.brs | grep "appendTypeBadge" >/dev/null
unzip -p dist/kinopub.zip components/screens/HomeScreen.xml | grep -q "searchKeyboardGroup"
unzip -p dist/kinopub.zip components/screens/VideoDetailScreen.brs | grep -q "Preparing video..."

bash scripts/tests/player-track-dedupe.sh
bash scripts/tests/player-audio-selection.sh
bash scripts/tests/player-subtitle-selection.sh
bash scripts/tests/player-quality-selection.sh
bash scripts/tests/player-menu-back.sh
bash scripts/tests/next-episode-flow.sh
bash scripts/tests/player-season-carousel.sh

echo "Static verification passed."
