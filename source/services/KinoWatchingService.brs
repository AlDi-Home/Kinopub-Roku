function KinoWatchingService(client as Object) as Object
    return {
        client: client
        listSerials: kinoWatchingListSerials
        normalizeSerialsResponse: kinoWatchingNormalizeSerialsResponse
        normalizeSerialEntry: kinoWatchingNormalizeSerialEntry
        normalizeWatchingPagination: kinoWatchingNormalizePagination
        serialsListFromBody: kinoWatchingSerialsListFromBody
        stringField: kinoWatchingStringField
        integerField: kinoWatchingIntegerField
        arrayField: kinoWatchingArrayField
        itemIsAnime: kinoWatchingItemIsAnime
        entryItem: kinoWatchingEntryItem
        posterUrl: kinoWatchingPosterUrl
        markTime: kinoWatchingMarkTime
        toggleWatched: kinoWatchingToggleWatched
        toggleWatchlist: kinoWatchingToggleWatchlist
        success: kinoWatchingSuccess
        failure: kinoWatchingFailure
    }
end function

function kinoWatchingListSerials(accessToken as String, page as Integer, perpage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50

    queryParams = {
        access_token: accessToken
        page: page
        perpage: perpage
        subscribed: 1
    }

    response = m.client.get("/v1/watching/serials", queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeSerialsResponse(response.body, page, perpage, typeMap, hideAnime)
end function

function kinoWatchingNormalizeSerialsResponse(body as Dynamic, requestedPage as Integer, requestedPerPage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    items = []
    pagination = m.normalizeWatchingPagination(body, requestedPage, requestedPerPage)
    serials = m.serialsListFromBody(body)

    if serials = invalid
        return { ok: false, items: [], pagination: pagination, error: "invalid_response", message: "Continue Watching response did not include a serials list.", status: 0 }
    end if

    for each entry in serials
        if hideAnime <> true or m.itemIsAnime(m.entryItem(entry)) <> true
            normalized = m.normalizeSerialEntry(entry, typeMap)
            if normalized.itemId > 0 and normalized.type = "serial" then items.Push(normalized)
        end if
    end for

    return { ok: true, items: items, pagination: pagination }
end function

' Shared with kinoWatchingNormalizeSerialsResponse's pre-normalize anime
' filter — the "which field actually holds the raw item" resolution needs to
' happen the same way in both places, before and during normalization.
function kinoWatchingEntryItem(entry as Dynamic) as Dynamic
    item = invalid
    if entry <> invalid and type(entry) = "roAssociativeArray"
        if entry.DoesExist("item") then item = entry.item
        if entry.DoesExist("serial") then item = entry.serial
        if entry.DoesExist("series") then item = entry.series
    end if
    if item = invalid then item = entry
    return item
end function

function kinoWatchingNormalizeSerialEntry(entry as Dynamic, typeMap = invalid as Dynamic) as Object
    item = m.entryItem(entry)
    media = invalid
    if entry <> invalid and type(entry) = "roAssociativeArray"
        if entry.DoesExist("media") then media = entry.media
        if entry.DoesExist("video") then media = entry.video
        if entry.DoesExist("episode") then media = entry.episode
    end if

    title = m.stringField(item, "title", "")
    if title = "" then title = m.stringField(item, "name", "")
    if title = "" then title = m.stringField(entry, "title", "")
    if title = "" then title = "Untitled"

    subtitle = m.stringField(media, "title", "")
    if subtitle = "" then subtitle = m.stringField(entry, "subtitle", "")
    if subtitle = title then subtitle = ""

    contentType = m.stringField(item, "type", "")
    if contentType = "" then contentType = m.stringField(entry, "type", "")
    if contentType = "" then contentType = "serial"

    typeTitle = contentType
    typeBadge = contentType
    if typeMap <> invalid and type(typeMap) = "roAssociativeArray" and typeMap.DoesExist(contentType)
        typeEntry = typeMap[contentType]
        if typeEntry <> invalid and type(typeEntry) = "roAssociativeArray"
            mappedTitle = m.stringField(typeEntry, "title", "")
            if mappedTitle <> "" then typeTitle = mappedTitle
            mappedBadge = m.stringField(typeEntry, "badge", "")
            if mappedBadge <> "" then typeBadge = mappedBadge
        end if
    end if
    if typeBadge = contentType
        source = typeTitle
        if source = "" then source = contentType
        source = source.Trim()
        source = UCase(source)
        if Len(source) > 3 then source = Left(source, 3)
        typeBadge = source
    end if

    seasonNumber = m.integerField(entry, "season", 0)
    if seasonNumber = 0 then seasonNumber = m.integerField(entry, "season_number", 0)
    if seasonNumber = 0 then seasonNumber = m.integerField(media, "season", 0)
    if seasonNumber = 0 then seasonNumber = m.integerField(media, "season_number", 0)

    episodeNumber = m.integerField(entry, "episode", 0)
    if episodeNumber = 0 then episodeNumber = m.integerField(entry, "video", 0)
    if episodeNumber = 0 then episodeNumber = m.integerField(entry, "episode_number", 0)
    if episodeNumber = 0 then episodeNumber = m.integerField(media, "number", 0)
    if episodeNumber = 0 then episodeNumber = m.integerField(media, "episode", 0)

    targetSeasonNumber = m.integerField(entry, "target_season", seasonNumber)
    if targetSeasonNumber = seasonNumber then targetSeasonNumber = m.integerField(entry, "target_season_number", targetSeasonNumber)
    if targetSeasonNumber = seasonNumber then targetSeasonNumber = m.integerField(entry, "new_season", targetSeasonNumber)

    targetEpisodeNumber = m.integerField(entry, "target_episode", episodeNumber)
    if targetEpisodeNumber = episodeNumber then targetEpisodeNumber = m.integerField(entry, "target_episode_number", targetEpisodeNumber)
    if targetEpisodeNumber = episodeNumber then targetEpisodeNumber = m.integerField(entry, "new_episode", targetEpisodeNumber)
    if targetEpisodeNumber = episodeNumber then targetEpisodeNumber = m.integerField(entry, "new_video", targetEpisodeNumber)

    newEpisodeCount = m.integerField(entry, "new_episode_count", 0)
    if newEpisodeCount = 0 then newEpisodeCount = m.integerField(entry, "new_episodes", 0)
    if newEpisodeCount = 0 then newEpisodeCount = m.integerField(entry, "new", 0)

    unwatchedCount = m.integerField(entry, "unwatched_count", 0)
    if unwatchedCount = 0 then unwatchedCount = m.integerField(entry, "unwatched", 0)
    if unwatchedCount = 0 then unwatchedCount = newEpisodeCount

    progressSeconds = m.integerField(entry, "time", 0)
    if progressSeconds = 0 then progressSeconds = m.integerField(entry, "progress", 0)
    if progressSeconds = 0 then progressSeconds = m.integerField(entry, "progress_seconds", 0)
    if progressSeconds = 0 then progressSeconds = m.integerField(media, "time", 0)

    durationSeconds = m.integerField(media, "duration", 0)
    if durationSeconds = 0 then durationSeconds = m.integerField(entry, "duration", 0)
    if durationSeconds = 0 then durationSeconds = m.integerField(entry, "duration_seconds", 0)

    itemId = m.integerField(item, "id", 0)
    if itemId = 0 then itemId = m.integerField(entry, "item_id", 0)
    if itemId = 0 then itemId = m.integerField(entry, "serial_id", 0)
    if itemId = 0 then itemId = m.integerField(entry, "id", 0)

    mediaId = m.integerField(media, "id", 0)
    if mediaId = 0 then mediaId = m.integerField(entry, "media_id", 0)
    if mediaId = 0 then mediaId = m.integerField(entry, "video_id", 0)
    if mediaId = 0 then mediaId = m.integerField(entry, "episode_id", 0)

    return {
        itemId: itemId
        mediaId: mediaId
        title: title
        subtitle: subtitle
        posterUrl: m.posterUrl(item, media, entry)
        type: contentType
        typeTitle: typeTitle
        typeBadge: typeBadge
        seasonNumber: seasonNumber
        episodeNumber: episodeNumber
        targetSeasonNumber: targetSeasonNumber
        targetEpisodeNumber: targetEpisodeNumber
        newEpisodeCount: newEpisodeCount
        unwatchedCount: unwatchedCount
        progressSeconds: progressSeconds
        durationSeconds: durationSeconds
        imdbRating: m.stringField(item, "imdb_rating", "")
        kinopoiskRating: m.stringField(item, "kinopoisk_rating", "")
        kinopubRating: m.stringField(item, "rating", "")
        selected: false
    }
end function

function kinoWatchingNormalizePagination(body as Dynamic, requestedPage as Integer, requestedPerPage as Integer) as Object
    pagination = {
        total: 0
        current: requestedPage
        perpage: requestedPerPage
        total_items: 0
    }

    if body = invalid or type(body) <> "roAssociativeArray" then return pagination

    apiPagination = invalid
    if body.DoesExist("pagination") and body.pagination <> invalid and type(body.pagination) = "roAssociativeArray" then apiPagination = body.pagination
    if apiPagination = invalid and body.DoesExist("meta") and body.meta <> invalid and type(body.meta) = "roAssociativeArray" then apiPagination = body.meta

    if apiPagination <> invalid
        pagination.total = m.integerField(apiPagination, "total", pagination.total)
        pagination.current = m.integerField(apiPagination, "current", pagination.current)
        pagination.perpage = m.integerField(apiPagination, "perpage", pagination.perpage)
        pagination.total_items = m.integerField(apiPagination, "total_items", pagination.total_items)
    else
        pagination.total = m.integerField(body, "total", pagination.total)
        pagination.current = m.integerField(body, "current", pagination.current)
        pagination.perpage = m.integerField(body, "perpage", pagination.perpage)
        pagination.total_items = m.integerField(body, "total_items", pagination.total_items)
    end if

    return pagination
end function

function kinoWatchingSerialsListFromBody(body as Dynamic) as Dynamic
    if body <> invalid and type(body) = "roArray" then return body
    if body = invalid or type(body) <> "roAssociativeArray" then return invalid

    wrapperKeys = ["items", "serials", "watching", "data", "results"]
    for each key in wrapperKeys
        if body.DoesExist(key) and body[key] <> invalid and type(body[key]) = "roArray" then return body[key]
    end for

    return invalid
end function

function kinoWatchingMarkTime(accessToken as String, itemId as Integer, seasonNumber as Integer, videoNumber as Integer, timeSeconds as Integer) as Object
    if itemId <= 0 or videoNumber <= 0
        return { ok: false, error: "invalid_media", message: "Unable to save playback progress.", status: 0 }
    end if

    if timeSeconds < 0 then timeSeconds = 0
    queryParams = {
        access_token: accessToken
        id: itemId
        video: videoNumber
        time: timeSeconds
    }
    if seasonNumber > 0 then queryParams.season = seasonNumber

    response = m.client.get("/v1/watching/marktime", queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.success(response)
end function

function kinoWatchingToggleWatched(accessToken as String, itemId as Integer, seasonNumber as Integer, videoNumber as Integer) as Object
    if itemId <= 0 or videoNumber <= 0
        return { ok: false, error: "invalid_media", message: "Unable to mark this video watched.", status: 0 }
    end if

    queryParams = {
        access_token: accessToken
        id: itemId
        video: videoNumber
    }
    if seasonNumber > 0 then queryParams.season = seasonNumber

    response = m.client.get("/v1/watching/toggle", queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)

    watched = invalid
    if response.body <> invalid and type(response.body) = "roAssociativeArray" and response.body.DoesExist("watched")
        watched = response.body.watched
    end if
    result = m.success(response)
    result.watched = watched
    return result
end function

' https://kinoapi.com/api_watching.html#id16 — "Буду смотреть" toggle. Adds
' or removes a serial from the user's watchlist (the same subscribed set
' /v1/watching/serials?subscribed=1 reads back for the New Episodes rail);
' unrelated to toggleWatched, which marks a single episode watched/unwatched.
function kinoWatchingToggleWatchlist(accessToken as String, itemId as Integer) as Object
    if itemId <= 0
        return { ok: false, error: "invalid_item", message: "Unable to update your watchlist.", status: 0 }
    end if

    queryParams = {
        access_token: accessToken
        id: itemId
    }

    response = m.client.get("/v1/watching/togglewatchlist", queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)

    watching = invalid
    if response.body <> invalid and type(response.body) = "roAssociativeArray" and response.body.DoesExist("watching")
        watching = response.body.watching
    end if
    result = m.success(response)
    result.watching = watching
    return result
end function

function kinoWatchingSuccess(response as Object) as Object
    return { ok: true, status: response.status, rawBody: response.rawBody }
end function

function kinoWatchingPosterUrl(item as Dynamic, media as Dynamic, entry = invalid as Dynamic) as String
    url = kinoWatchingPosterFromSource(item)
    if url <> "" then return url
    url = kinoWatchingPosterFromSource(entry)
    if url <> "" then return url
    url = m.stringField(item, "poster", "")
    if url <> "" then return url
    url = m.stringField(item, "cover", "")
    if url <> "" then return url
    url = m.stringField(item, "image", "")
    if url <> "" then return url
    url = m.stringField(media, "thumbnail", "")
    if url <> "" then return url
    url = m.stringField(media, "poster", "")
    if url <> "" then return url
    return m.stringField(entry, "poster", "")
end function

function kinoWatchingPosterFromSource(source as Dynamic) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return ""
    for each containerKey in ["posters", "images"]
        if source.DoesExist(containerKey) and source[containerKey] <> invalid and type(source[containerKey]) = "roAssociativeArray"
            container = source[containerKey]
            for each key in ["medium", "small", "big", "poster", "cover", "thumbnail"]
                url = kinoWatchingStringField(container, key, "")
                if url <> "" then return url
            end for
        end if
    end for
    return ""
end function

function kinoWatchingStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()
    return fallback
end function

function kinoWatchingIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function kinoWatchingArrayField(source as Dynamic, key as String) as Object
    if source = invalid or type(source) <> "roAssociativeArray" then return []
    if source.DoesExist(key) <> true or source[key] = invalid then return []
    if type(source[key]) = "roArray" then return source[key]
    return []
end function

function kinoWatchingItemIsAnime(item as Dynamic) as Boolean
    genres = m.arrayField(item, "genres")
    for each genre in genres
        if LCase(m.stringField(genre, "title", "")) = "аниме" then return true
    end for
    return false
end function

function kinoWatchingFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function
