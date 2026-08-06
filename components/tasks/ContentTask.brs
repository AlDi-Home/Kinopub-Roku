sub init()
    m.top.functionName = "runContentTask"
end sub

sub runContentTask()
    tokenStoreService = TokenStore()
    client = KinoApiClient(KinoConfig())
    authService = KinoAuthService(client, tokenStoreService)
    bookmarkService = KinoBookmarkService(client)
    browseService = KinoBrowseService(client)
    typeService = KinoContentTypeService(client)
    historyService = KinoHistoryService(client)
    homeService = KinoHomeService(client)
    itemService = KinoItemService(client)
    searchService = KinoSearchService(client)
    tvService = KinoTvService(client)
    userService = KinoUserService(client)
    watchingService = KinoWatchingService(client)
    command = m.top.command
    request = m.top.request
    print "ContentTask: running command "; command

    if command = "loadHistoryPage"
        m.top.response = contentTaskLoadHistoryPage(tokenStoreService, authService, historyService, typeService, request)
    else if command = "loadContinueSummary"
        m.top.response = contentTaskLoadContinueSummary(tokenStoreService, authService, historyService, watchingService, typeService, request)
    else if command = "loadContinueHistoryPage"
        m.top.response = contentTaskLoadContinueHistoryPage(tokenStoreService, authService, historyService, typeService, request)
    else if command = "loadContinueNewEpisodesPage"
        m.top.response = contentTaskLoadContinueNewEpisodesPage(tokenStoreService, authService, watchingService, typeService, request)
    else if command = "loadHome"
        m.top.response = contentTaskLoadHome(tokenStoreService, authService, homeService, typeService, request)
    else if command = "loadItemDetail"
        m.top.response = contentTaskLoadItemDetail(tokenStoreService, authService, itemService, request)
    else if command = "refreshMediaLinks"
        m.top.response = contentTaskRefreshMediaLinks(tokenStoreService, authService, itemService, request)
    else if command = "loadSearchOptions"
        m.top.response = contentTaskLoadSearchOptions(tokenStoreService, authService, typeService)
    else if command = "searchItems"
        m.top.response = contentTaskSearchItems(tokenStoreService, authService, searchService, typeService, request)
    else if command = "loadUserInfo"
        m.top.response = contentTaskLoadUserInfo(tokenStoreService, authService, userService)
    else if command = "loadBookmarkFolders"
        m.top.response = contentTaskLoadBookmarkFolders(tokenStoreService, authService, bookmarkService)
    else if command = "loadBookmarkFolderItems"
        m.top.response = contentTaskLoadBookmarkFolderItems(tokenStoreService, authService, bookmarkService, typeService, request)
    else if command = "loadBrowseOptions"
        m.top.response = contentTaskLoadBrowseOptions(tokenStoreService, authService, browseService, typeService)
    else if command = "loadBrowseItems"
        m.top.response = contentTaskLoadBrowseItems(tokenStoreService, authService, browseService, typeService, request)
    else if command = "probeLiveTv" or command = "loadLiveTv"
        m.top.response = contentTaskLoadLiveTv(tokenStoreService, authService, tvService, command)
    else if command = "loadItemBookmarkFolders"
        m.top.response = contentTaskLoadItemBookmarkFolders(tokenStoreService, authService, bookmarkService, request)
    else if command = "toggleItemBookmark"
        m.top.response = contentTaskToggleItemBookmark(tokenStoreService, authService, bookmarkService, request)
    else if command = "savePlaybackProgress"
        m.top.response = contentTaskSavePlaybackProgress(tokenStoreService, authService, watchingService, request)
    else if command = "markPlaybackWatched"
        m.top.response = contentTaskMarkPlaybackWatched(tokenStoreService, authService, watchingService, request)
    else if command = "toggleEpisodeWatched"
        m.top.response = contentTaskToggleEpisodeWatched(tokenStoreService, authService, watchingService, request)
    else
        m.top.response = { command: command, ok: false, error: "unknown_command", message: "Unknown content task command." }
    end if
end sub

function contentTaskLoadSearchOptions(tokenStoreService as Object, authService as Object, typeService as Object) as Object
    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load Search filters.")
    if tokenResult.ok <> true
        tokenResult.command = "loadSearchOptions"
        tokenResult.typeMap = {}
        return tokenResult
    end if

    return {
        command: "loadSearchOptions"
        ok: true
        typeMap: contentTaskTypeMap(typeService, tokenResult.accessToken)
    }
end function

function contentTaskLoadLiveTv(tokenStoreService as Object, authService as Object, tvService as Object, command as String) as Object
    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load Live.")
    if tokenResult.ok <> true
        tokenResult.command = command
        tokenResult.items = []
        return tokenResult
    end if

    result = tvService.load(tokenResult.accessToken)
    result.command = command
    return result
end function

function contentTaskLoadHome(tokenStoreService as Object, authService as Object, homeService as Object, typeService as Object, request as Dynamic) as Object
    perpage = contentTaskIntegerField(request, "perpage", 12)
    if perpage < 1 then perpage = 12
    if perpage > 20 then perpage = 20

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load Home.")
    if tokenResult.ok <> true
        tokenResult.command = "loadHome"
        tokenResult.perpage = perpage
        return tokenResult
    end if

    typeMap = contentTaskTypeMap(typeService, tokenResult.accessToken)
    result = homeService.load(tokenResult.accessToken, perpage, typeMap)
    result.command = "loadHome"
    result.perpage = perpage
    return result
end function

function contentTaskLoadHistoryPage(tokenStoreService as Object, authService as Object, historyService as Object, typeService as Object, request as Dynamic) as Object
    page = contentTaskIntegerField(request, "page", 1)
    perpage = contentTaskIntegerField(request, "perpage", 20)
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50

    tokenResult = contentTaskUsableTokens(tokenStoreService, authService)

    if tokenResult.ok <> true
        if tokenResult.error = "auth_required"
            return { command: "loadHistoryPage", ok: false, page: page, perpage: perpage, error: "auth_required", message: "Sign in again to load History." }
        end if
        return { command: "loadHistoryPage", ok: false, page: page, perpage: perpage, error: tokenResult.error, message: tokenResult.message, status: tokenResult.status }
    end if

    tokens = tokenResult.tokens
    if tokens = invalid
        return { command: "loadHistoryPage", ok: false, page: page, perpage: perpage, error: "auth_required", message: "Sign in again to load History." }
    end if

    accessToken = contentTaskTokenString(tokens, "accesstoken")
    if accessToken = "" then accessToken = contentTaskTokenString(tokens, "accessToken")
    if accessToken = "" then return { command: "loadHistoryPage", ok: false, page: page, perpage: perpage, error: "auth_required", message: "Sign in again to load History." }

    typeMap = contentTaskTypeMap(typeService, accessToken)
    result = historyService.list(accessToken, page, perpage, typeMap)
    result.command = "loadHistoryPage"
    result.page = page
    result.perpage = perpage
    return result
end function

function contentTaskContinuePageRequest(request as Dynamic) as Object
    page = contentTaskIntegerField(request, "page", 1)
    perpage = contentTaskIntegerField(request, "perpage", 20)
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50
    return { page: page, perpage: perpage }
end function

function contentTaskLoadContinueHistoryPage(tokenStoreService as Object, authService as Object, historyService as Object, typeService as Object, request as Dynamic) as Object
    result = contentTaskLoadHistoryPage(tokenStoreService, authService, historyService, typeService, request)
    result.command = "loadContinueHistoryPage"
    result.kind = "history"
    return result
end function

function contentTaskLoadContinueNewEpisodesPage(tokenStoreService as Object, authService as Object, watchingService as Object, typeService as Object, request as Dynamic) as Object
    pageRequest = contentTaskContinuePageRequest(request)
    page = pageRequest.page
    perpage = pageRequest.perpage

    tokenResult = contentTaskUsableTokens(tokenStoreService, authService)

    if tokenResult.ok <> true
        if tokenResult.error = "auth_required"
            return { command: "loadContinueNewEpisodesPage", kind: "newEpisodes", ok: false, page: page, perpage: perpage, error: "auth_required", message: "Sign in again to load new episodes." }
        end if
        return { command: "loadContinueNewEpisodesPage", kind: "newEpisodes", ok: false, page: page, perpage: perpage, error: tokenResult.error, message: tokenResult.message, status: tokenResult.status }
    end if

    tokens = tokenResult.tokens
    if tokens = invalid
        return { command: "loadContinueNewEpisodesPage", kind: "newEpisodes", ok: false, page: page, perpage: perpage, error: "auth_required", message: "Sign in again to load new episodes." }
    end if

    accessToken = contentTaskTokenString(tokens, "accesstoken")
    if accessToken = "" then accessToken = contentTaskTokenString(tokens, "accessToken")
    if accessToken = "" then return { command: "loadContinueNewEpisodesPage", kind: "newEpisodes", ok: false, page: page, perpage: perpage, error: "auth_required", message: "Sign in again to load new episodes." }

    typeMap = contentTaskTypeMap(typeService, accessToken)
    result = watchingService.listSerials(accessToken, page, perpage, typeMap)
    result.command = "loadContinueNewEpisodesPage"
    result.kind = "newEpisodes"
    result.page = page
    result.perpage = perpage
    return result
end function

function contentTaskLoadContinueSummary(tokenStoreService as Object, authService as Object, historyService as Object, watchingService as Object, typeService as Object, request as Dynamic) as Object
    perpage = contentTaskIntegerField(request, "perpage", 10)
    if perpage < 1 then perpage = 10
    if perpage > 20 then perpage = 20
    pageRequest = { page: 1, perpage: perpage }

    history = contentTaskLoadContinueHistoryPage(tokenStoreService, authService, historyService, typeService, pageRequest)
    if history.error = "auth_required"
        return { command: "loadContinueSummary", ok: false, error: "auth_required", message: history.message, history: history }
    end if

    newEpisodes = contentTaskLoadContinueNewEpisodesPage(tokenStoreService, authService, watchingService, typeService, pageRequest)
    if newEpisodes.error = "auth_required"
        return { command: "loadContinueSummary", ok: false, error: "auth_required", message: newEpisodes.message, history: history, newEpisodes: newEpisodes }
    end if

    ok = false
    if history.ok = true or newEpisodes.ok = true then ok = true
    return { command: "loadContinueSummary", ok: ok, rails: [history, newEpisodes], history: history, newEpisodes: newEpisodes }
end function

function contentTaskLoadItemDetail(tokenStoreService as Object, authService as Object, itemService as Object, request as Dynamic) as Object
    itemId = contentTaskIntegerField(request, "itemId", 0)
    mediaId = contentTaskIntegerField(request, "mediaId", 0)
    if itemId <= 0
        return { command: "loadItemDetail", ok: false, itemId: itemId, mediaId: mediaId, error: "invalid_item", message: "Unable to open this video.", status: 0 }
    end if

    tokenResult = contentTaskUsableTokens(tokenStoreService, authService)

    if tokenResult.ok <> true
        if tokenResult.error = "auth_required"
            return { command: "loadItemDetail", ok: false, itemId: itemId, mediaId: mediaId, error: "auth_required", message: "Sign in again to load video details.", status: 0 }
        end if
        return { command: "loadItemDetail", ok: false, itemId: itemId, mediaId: mediaId, error: tokenResult.error, message: tokenResult.message, status: tokenResult.status }
    end if

    tokens = tokenResult.tokens
    if tokens = invalid
        return { command: "loadItemDetail", ok: false, itemId: itemId, mediaId: mediaId, error: "auth_required", message: "Sign in again to load video details.", status: 0 }
    end if

    accessToken = contentTaskTokenString(tokens, "accesstoken")
    if accessToken = "" then accessToken = contentTaskTokenString(tokens, "accessToken")
    if accessToken = "" then return { command: "loadItemDetail", ok: false, itemId: itemId, mediaId: mediaId, error: "auth_required", message: "Sign in again to load video details.", status: 0 }

    result = itemService.detail(accessToken, itemId)
    if result.ok = true and result.item <> invalid
        similarResult = itemService.similar(accessToken, itemId)
        if similarResult.ok = true
            result.item.similarItems = similarResult.items
        else
            result.item.similarItems = []
        end if

        trailerResult = itemService.trailer(accessToken, itemId)
        if trailerResult.ok = true
            result.item.trailer = trailerResult.trailer
        else
            result.item.trailer = invalid
        end if
    end if
    result.command = "loadItemDetail"
    result.itemId = itemId
    result.mediaId = mediaId
    result.targetSeasonNumber = contentTaskIntegerField(request, "targetSeasonNumber", 0)
    result.targetEpisodeNumber = contentTaskIntegerField(request, "targetEpisodeNumber", 0)
    result.seasonNumber = contentTaskIntegerField(request, "seasonNumber", 0)
    result.episodeNumber = contentTaskIntegerField(request, "episodeNumber", 0)
    return result
end function

function contentTaskRefreshMediaLinks(tokenStoreService as Object, authService as Object, itemService as Object, request as Dynamic) as Object
    media = invalid
    if request <> invalid and type(request) = "roAssociativeArray" and request.DoesExist("media") then media = request.media
    mediaId = contentTaskIntegerField(media, "mediaId", 0)
    if mediaId <= 0
        return { command: "refreshMediaLinks", ok: false, mediaId: mediaId, error: "invalid_media", message: "Unable to refresh this video.", status: 0 }
    end if

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to play this video.")
    if tokenResult.ok <> true
        tokenResult.command = "refreshMediaLinks"
        tokenResult.mediaId = mediaId
        return tokenResult
    end if

    result = itemService.mediaLinks(tokenResult.accessToken, media)
    result.command = "refreshMediaLinks"
    result.mediaId = mediaId
    return result
end function

function contentTaskSearchItems(tokenStoreService as Object, authService as Object, searchService as Object, typeService as Object, request as Dynamic) as Object
    query = contentTaskStringField(request, "q", "").Trim()
    page = contentTaskIntegerField(request, "page", 1)
    perpage = contentTaskIntegerField(request, "perpage", 20)
    sortByYear = contentTaskBooleanField(request, "sortByYear", true)
    contentType = contentTaskStringField(request, "contentType", "")
    searchField = LCase(contentTaskStringField(request, "searchField", "title").Trim())
    if searchField <> "director" and searchField <> "cast" then searchField = "title"
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50

    if query = ""
        return { command: "searchItems", ok: false, q: query, page: page, perpage: perpage, sortByYear: sortByYear, contentType: contentType, searchField: searchField, error: "invalid_query", message: "Enter a search term.", status: 0 }
    end if

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to search.")
    if tokenResult.ok <> true
        tokenResult.command = "searchItems"
        tokenResult.q = query
        tokenResult.page = page
        tokenResult.perpage = perpage
        tokenResult.sortByYear = sortByYear
        tokenResult.contentType = contentType
        tokenResult.searchField = searchField
        return tokenResult
    end if

    typeMap = contentTaskTypeMap(typeService, tokenResult.accessToken)
    result = searchService.search(tokenResult.accessToken, query, page, perpage, typeMap, sortByYear, contentType, searchField)
    result.command = "searchItems"
    result.q = query
    result.page = page
    result.perpage = perpage
    result.sortByYear = sortByYear
    result.contentType = contentType
    result.searchField = searchField
    return result
end function

function contentTaskLoadUserInfo(tokenStoreService as Object, authService as Object, userService as Object) as Object
    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load account information.")
    if tokenResult.ok <> true
        tokenResult.command = "loadUserInfo"
        return tokenResult
    end if

    result = userService.info(tokenResult.accessToken)
    result.command = "loadUserInfo"
    return result
end function

function contentTaskLoadBookmarkFolders(tokenStoreService as Object, authService as Object, bookmarkService as Object) as Object
    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load bookmarks.")
    if tokenResult.ok <> true
        tokenResult.command = "loadBookmarkFolders"
        return tokenResult
    end if

    result = bookmarkService.listFolders(tokenResult.accessToken)
    result.command = "loadBookmarkFolders"
    return result
end function

function contentTaskLoadBookmarkFolderItems(tokenStoreService as Object, authService as Object, bookmarkService as Object, typeService as Object, request as Dynamic) as Object
    folderId = contentTaskIntegerField(request, "folderId", 0)
    page = contentTaskIntegerField(request, "page", 1)
    perpage = contentTaskIntegerField(request, "perpage", 20)

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load bookmark folder.")
    if tokenResult.ok <> true
        tokenResult.command = "loadBookmarkFolderItems"
        tokenResult.folderId = folderId
        return tokenResult
    end if

    typeMap = contentTaskTypeMap(typeService, tokenResult.accessToken)
    result = bookmarkService.listFolderItems(tokenResult.accessToken, folderId, page, perpage, typeMap)
    result.command = "loadBookmarkFolderItems"
    result.folderId = folderId
    result.page = page
    result.perpage = perpage
    return result
end function

function contentTaskLoadItemBookmarkFolders(tokenStoreService as Object, authService as Object, bookmarkService as Object, request as Dynamic) as Object
    itemId = contentTaskIntegerField(request, "itemId", 0)

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load bookmark status.")
    if tokenResult.ok <> true
        tokenResult.command = "loadItemBookmarkFolders"
        tokenResult.itemId = itemId
        return tokenResult
    end if

    result = bookmarkService.itemFolders(tokenResult.accessToken, itemId)
    result.command = "loadItemBookmarkFolders"
    result.itemId = itemId
    return result
end function

function contentTaskToggleItemBookmark(tokenStoreService as Object, authService as Object, bookmarkService as Object, request as Dynamic) as Object
    itemId = contentTaskIntegerField(request, "itemId", 0)
    folderId = contentTaskIntegerField(request, "folderId", 0)

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to update bookmark.")
    if tokenResult.ok <> true
        tokenResult.command = "toggleItemBookmark"
        tokenResult.itemId = itemId
        tokenResult.folderId = folderId
        return tokenResult
    end if

    result = bookmarkService.toggleItem(tokenResult.accessToken, itemId, folderId)
    result.command = "toggleItemBookmark"
    result.itemId = itemId
    result.folderId = folderId
    return result
end function

function contentTaskLoadBrowseOptions(tokenStoreService as Object, authService as Object, browseService as Object, typeService as Object) as Object
    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to load Browse filters.")
    if tokenResult.ok <> true
        tokenResult.command = "loadBrowseOptions"
        return tokenResult
    end if

    typeMap = contentTaskTypeMap(typeService, tokenResult.accessToken)
    result = browseService.loadOptions(tokenResult.accessToken, typeMap)
    result.command = "loadBrowseOptions"
    return result
end function

function contentTaskLoadBrowseItems(tokenStoreService as Object, authService as Object, browseService as Object, typeService as Object, request as Dynamic) as Object
    page = contentTaskIntegerField(request, "page", 1)
    perpage = contentTaskIntegerField(request, "perpage", 20)
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to browse.")
    if tokenResult.ok <> true
        tokenResult.command = "loadBrowseItems"
        tokenResult.page = page
        tokenResult.perpage = perpage
        return tokenResult
    end if

    typeMap = contentTaskTypeMap(typeService, tokenResult.accessToken)
    browseRequestParams = contentTaskBrowseRequest(request, page, perpage)
    result = browseService.listItems(tokenResult.accessToken, browseRequestParams, typeMap)
    result.command = "loadBrowseItems"
    result.page = page
    result.perpage = perpage
    result.contentType = browseRequestParams.contentType
    result.genreId = browseRequestParams.genreId
    result.countryId = browseRequestParams.countryId
    result.yearRange = browseRequestParams.yearRange
    result.finished = browseRequestParams.finished
    return result
end function

function contentTaskBrowseRequest(request as Dynamic, page as Integer, perpage as Integer) as Object
    return {
        page: page
        perpage: perpage
        contentType: contentTaskStringField(request, "contentType", "")
        genreId: contentTaskStringField(request, "genreId", "")
        countryId: contentTaskStringField(request, "countryId", "")
        yearRange: contentTaskStringField(request, "yearRange", "all")
        finished: contentTaskStringField(request, "finished", "any")
    }
end function

function contentTaskAccessToken(tokenStoreService as Object, authService as Object, message as String) as Object
    tokenResult = contentTaskUsableTokens(tokenStoreService, authService)

    if tokenResult.ok <> true
        if tokenResult.error = "auth_required"
            return { ok: false, error: "auth_required", message: message, status: 0 }
        end if
        return { ok: false, error: tokenResult.error, message: tokenResult.message, status: tokenResult.status }
    end if

    tokens = tokenResult.tokens
    if tokens = invalid then return { ok: false, error: "auth_required", message: message, status: 0 }

    accessToken = contentTaskTokenString(tokens, "accesstoken")
    if accessToken = "" then accessToken = contentTaskTokenString(tokens, "accessToken")
    if accessToken = "" then return { ok: false, error: "auth_required", message: message, status: 0 }

    return { ok: true, accessToken: accessToken }
end function

function contentTaskTypeMap(typeService as Object, accessToken as String) as Object
    if typeService = invalid then return {}
    return typeService.typeMap(accessToken)
end function

function contentTaskSavePlaybackProgress(tokenStoreService as Object, authService as Object, watchingService as Object, request as Dynamic) as Object
    itemId = contentTaskIntegerField(request, "itemId", 0)
    seasonNumber = contentTaskIntegerField(request, "seasonNumber", 0)
    videoNumber = contentTaskIntegerField(request, "videoNumber", 0)
    timeSeconds = contentTaskIntegerField(request, "timeSeconds", 0)
    if timeSeconds < 0 then timeSeconds = 0
    if itemId <= 0 or videoNumber <= 0
        return { command: "savePlaybackProgress", ok: false, itemId: itemId, seasonNumber: seasonNumber, videoNumber: videoNumber, timeSeconds: timeSeconds, error: "invalid_media", message: "Unable to save playback progress.", status: 0 }
    end if

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to save playback progress.")
    if tokenResult.ok <> true
        tokenResult.command = "savePlaybackProgress"
        return tokenResult
    end if

    result = watchingService.markTime(tokenResult.accessToken, itemId, seasonNumber, videoNumber, timeSeconds)
    result.command = "savePlaybackProgress"
    result.itemId = itemId
    result.seasonNumber = seasonNumber
    result.videoNumber = videoNumber
    result.timeSeconds = timeSeconds
    return result
end function

function contentTaskMarkPlaybackWatched(tokenStoreService as Object, authService as Object, watchingService as Object, request as Dynamic) as Object
    itemId = contentTaskIntegerField(request, "itemId", 0)
    seasonNumber = contentTaskIntegerField(request, "seasonNumber", 0)
    videoNumber = contentTaskIntegerField(request, "videoNumber", 0)
    if itemId <= 0 or videoNumber <= 0
        return { command: "markPlaybackWatched", ok: false, itemId: itemId, seasonNumber: seasonNumber, videoNumber: videoNumber, error: "invalid_media", message: "Unable to mark this video watched.", status: 0 }
    end if

    watchedState = contentTaskBooleanFieldState(request, "watched")
    currentWatchedState = contentTaskBooleanFieldState(request, "currentWatched")
    if watchedState.value = true or currentWatchedState.value = true
        ' The KinoPub endpoint toggles state; skip it when the media is already watched to avoid flipping it back.
        return { command: "markPlaybackWatched", ok: true, itemId: itemId, seasonNumber: seasonNumber, videoNumber: videoNumber, watched: true, skipped: true }
    end if
    if watchedState.exists <> true and currentWatchedState.exists <> true
        return { command: "markPlaybackWatched", ok: false, itemId: itemId, seasonNumber: seasonNumber, videoNumber: videoNumber, error: "unknown_watched_state", message: "Unable to confirm whether this video is already watched.", skipped: true, status: 0 }
    end if

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to mark playback watched.")
    if tokenResult.ok <> true
        tokenResult.command = "markPlaybackWatched"
        return tokenResult
    end if

    result = watchingService.toggleWatched(tokenResult.accessToken, itemId, seasonNumber, videoNumber)
    result.command = "markPlaybackWatched"
    result.itemId = itemId
    result.seasonNumber = seasonNumber
    result.videoNumber = videoNumber
    if result.ok <> true then return result
    if result.watched <> true
        result.ok = false
        result.error = "watched_not_confirmed"
        result.message = "Unable to confirm this video was marked watched."
    end if
    return result
end function

function contentTaskToggleEpisodeWatched(tokenStoreService as Object, authService as Object, watchingService as Object, request as Dynamic) as Object
    itemId = contentTaskIntegerField(request, "itemId", 0)
    seasonNumber = contentTaskIntegerField(request, "seasonNumber", 0)
    videoNumber = contentTaskIntegerField(request, "videoNumber", 0)
    if itemId <= 0 or videoNumber <= 0
        return { command: "toggleEpisodeWatched", ok: false, itemId: itemId, seasonNumber: seasonNumber, videoNumber: videoNumber, error: "invalid_media", message: "Unable to update watched status.", status: 0 }
    end if

    targetWatchedState = contentTaskBooleanFieldState(request, "watched")
    if targetWatchedState.exists <> true
        return { command: "toggleEpisodeWatched", ok: false, itemId: itemId, seasonNumber: seasonNumber, videoNumber: videoNumber, error: "unknown_watched_state", message: "Unable to update watched status.", status: 0 }
    end if

    tokenResult = contentTaskAccessToken(tokenStoreService, authService, "Sign in again to update watched status.")
    if tokenResult.ok <> true
        tokenResult.command = "toggleEpisodeWatched"
        return tokenResult
    end if

    result = watchingService.toggleWatched(tokenResult.accessToken, itemId, seasonNumber, videoNumber)
    result.command = "toggleEpisodeWatched"
    result.itemId = itemId
    result.seasonNumber = seasonNumber
    result.videoNumber = videoNumber
    result.progressCleared = false
    if result.ok <> true then return result

    apiWatched = invalid
    if result.DoesExist("watched") then apiWatched = result.watched
    apiWatchedState = contentTaskBooleanValueState(apiWatched)
    if apiWatchedState.exists and apiWatchedState.value <> targetWatchedState.value
        result.ok = false
        result.error = "watched_not_confirmed"
        result.message = "Unable to confirm watched status changed."
        return result
    end if

    clearResult = watchingService.markTime(tokenResult.accessToken, itemId, seasonNumber, videoNumber, 0)
    if clearResult.ok = true
        result.progressCleared = true
    else
        result.progressError = clearResult.error
        result.progressMessage = clearResult.message
    end if
    result.watched = targetWatchedState.value
    return result
end function

function contentTaskUsableTokens(tokenStoreService as Object, authService as Object) as Object
    tokens = tokenStoreService.load()
    if tokenStoreService.hasUsableAccessToken(tokens) then return { ok: true, tokens: tokens }

    if tokenStoreService.hasRefreshToken(tokens)
        refreshToken = contentTaskTokenString(tokens, "refreshtoken")
        result = authService.refreshToken(refreshToken)
        if result.ok = true
            refreshedTokens = tokenStoreService.load()
            if tokenStoreService.hasUsableAccessToken(refreshedTokens) then return { ok: true, tokens: refreshedTokens }
            return { ok: false, error: "auth_required", message: "Sign in again.", status: 0 }
        end if
        if contentTaskAuthFailure(result)
            tokenStoreService.clear()
            return { ok: false, error: "auth_required", message: "Device authorization was removed. Sign in again.", status: result.status }
        end if
        return { ok: false, error: result.error, message: result.message, status: result.status }
    end if

    return { ok: false, error: "auth_required", message: "Sign in again.", status: 0 }
end function

function contentTaskAuthFailure(result as Dynamic) as Boolean
    if result = invalid or type(result) <> "roAssociativeArray" then return false
    if result.DoesExist("status") and result.status <> invalid and result.status = 401 then return true
    if result.DoesExist("error") <> true or result.error = invalid then return false
    errorCode = result.error
    if type(errorCode) <> "String" and type(errorCode) <> "roString" then return false
    errorCode = LCase(errorCode)
    return errorCode = "unauthorized" or errorCode = "invalid_grant" or errorCode = "auth_required"
end function

function contentTaskStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()
    return fallback
end function

function contentTaskIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function contentTaskBooleanField(source as Dynamic, key as String, fallback as Boolean) as Boolean
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value <> 0
    return fallback
end function

function contentTaskBooleanFieldState(source as Dynamic, key as String) as Object
    if source = invalid or type(source) <> "roAssociativeArray" then return { exists: false, value: false }
    if source.DoesExist(key) <> true or source[key] = invalid then return { exists: false, value: false }
    return contentTaskBooleanValueState(source[key])
end function

function contentTaskBooleanValueState(value as Dynamic) as Object
    if value = invalid then return { exists: false, value: false }
    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return { exists: true, value: value }
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return { exists: true, value: value <> 0 }
    return { exists: false, value: false }
end function

function contentTaskTokenString(tokens as Dynamic, key as String) as String
    if tokens = invalid or type(tokens) <> "roAssociativeArray" then return ""
    if tokens.DoesExist(key) <> true or tokens[key] = invalid then return ""
    return tokens[key]
end function
