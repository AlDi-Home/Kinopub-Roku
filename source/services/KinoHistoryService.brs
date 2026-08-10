function KinoHistoryService(client as Object) as Object
    return {
        client: client
        list: kinoHistoryList
        normalizeResponse: kinoHistoryNormalizeResponse
        normalizeEntry: kinoHistoryNormalizeEntry
        enrichType: kinoHistoryEnrichType
        typeTitleForType: kinoHistoryTypeTitleForType
        typeBadgeForType: kinoHistoryTypeBadgeForType
        stringField: kinoHistoryStringField
        integerField: kinoHistoryIntegerField
        arrayField: kinoHistoryArrayField
        itemIsAnime: kinoHistoryItemIsAnime
        posterUrl: kinoHistoryPosterUrl
        failure: kinoHistoryFailure
    }
end function

function kinoHistoryList(accessToken as String, page as Integer, perpage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    queryParams = {
        access_token: accessToken
        page: page
        perpage: perpage
    }

    response = m.client.get("/v1/history", queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeResponse(response.body, page, perpage, typeMap, hideAnime)
end function

function kinoHistoryNormalizeResponse(body as Dynamic, requestedPage as Integer, requestedPerPage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    items = []
    pagination = {
        total: 0
        current: requestedPage
        perpage: requestedPerPage
        total_items: 0
    }

    if body = invalid or type(body) <> "roAssociativeArray"
        return { ok: false, items: [], pagination: pagination, error: "invalid_response", message: "History response was not readable.", status: 0 }
    end if

    if body.DoesExist("history") <> true or body.history = invalid or type(body.history) <> "roArray"
        return { ok: false, items: [], pagination: pagination, error: "invalid_response", message: "History response did not include a history list.", status: 0 }
    end if

    seenItemIds = {}
    for each entry in body.history
        entryItem = invalid
        if entry <> invalid and type(entry) = "roAssociativeArray" and entry.DoesExist("item") then entryItem = entry.item
        if hideAnime <> true or m.itemIsAnime(entryItem) <> true
            normalized = m.normalizeEntry(entry, typeMap)
            isDuplicate = false
            if normalized.itemId > 0
                key = StrI(normalized.itemId).Trim()
                if seenItemIds.DoesExist(key) then isDuplicate = true
                seenItemIds[key] = true
            end if
            if isDuplicate <> true then items.Push(normalized)
        end if
    end for

    if body.DoesExist("pagination") and body.pagination <> invalid and type(body.pagination) = "roAssociativeArray"
        apiPagination = body.pagination
        pagination.total = m.integerField(apiPagination, "total", pagination.total)
        pagination.current = m.integerField(apiPagination, "current", pagination.current)
        pagination.perpage = m.integerField(apiPagination, "perpage", pagination.perpage)
        pagination.total_items = m.integerField(apiPagination, "total_items", pagination.total_items)
    end if

    return { ok: true, items: items, pagination: pagination }
end function

function kinoHistoryNormalizeEntry(entry as Dynamic, typeMap = invalid as Dynamic) as Object
    item = invalid
    media = invalid
    if entry <> invalid and type(entry) = "roAssociativeArray"
        if entry.DoesExist("item") then item = entry.item
        if entry.DoesExist("media") then media = entry.media
    end if

    title = m.stringField(item, "title", "")
    if title = "" then title = m.stringField(media, "title", "")
    if title = "" then title = "Untitled"

    subtitle = m.stringField(media, "title", "")
    if subtitle = title then subtitle = ""

    progressSeconds = 0
    if entry <> invalid and type(entry) = "roAssociativeArray" then progressSeconds = m.integerField(entry, "time", 0)

    normalized = {
        title: title
        subtitle: subtitle
        posterUrl: m.posterUrl(item, media)
        progressSeconds: progressSeconds
        durationSeconds: m.integerField(media, "duration", 0)
        watchCount: m.integerField(entry, "counter", 0)
        firstSeenSeconds: m.integerField(entry, "first_seen", 0)
        lastSeenSeconds: m.integerField(entry, "last_seen", 0)
        itemId: m.integerField(item, "id", 0)
        mediaId: m.integerField(media, "id", 0)
        type: m.stringField(item, "type", "")
        imdbRating: m.stringField(item, "imdb_rating", "")
        kinopoiskRating: m.stringField(item, "kinopoisk_rating", "")
        kinopubRating: m.stringField(item, "rating", "")
        selected: false
    }

    return m.enrichType(normalized, typeMap)
end function

function kinoHistoryEnrichType(item as Object, typeMap as Dynamic) as Object
    contentType = ""
    if item.DoesExist("type") and item.type <> invalid then contentType = item.type
    item.typeTitle = m.typeTitleForType(contentType, typeMap)
    item.typeBadge = m.typeBadgeForType(contentType, item.typeTitle, typeMap)
    return item
end function

function kinoHistoryTypeTitleForType(contentType as String, typeMap as Dynamic) as String
    if contentType = "" then return ""
    if typeMap <> invalid and type(typeMap) = "roAssociativeArray" and typeMap.DoesExist(contentType)
        entry = typeMap[contentType]
        if entry <> invalid and type(entry) = "roAssociativeArray"
            title = m.stringField(entry, "title", "")
            if title <> "" then return title
        end if
    end if
    return contentType
end function

function kinoHistoryTypeBadgeForType(contentType as String, title as String, typeMap as Dynamic) as String
    if contentType = "" then return ""
    if typeMap <> invalid and type(typeMap) = "roAssociativeArray" and typeMap.DoesExist(contentType)
        entry = typeMap[contentType]
        if entry <> invalid and type(entry) = "roAssociativeArray"
            badge = m.stringField(entry, "badge", "")
            if badge <> "" then return badge
        end if
    end if
    source = title
    if source = "" then source = contentType
    source = source.Trim()
    source = UCase(source)
    if Len(source) > 3 then source = Left(source, 3)
    return source
end function

function kinoHistoryPosterUrl(item as Dynamic, media as Dynamic) as String
    if item <> invalid and type(item) = "roAssociativeArray" and item.DoesExist("posters") and item.posters <> invalid and type(item.posters) = "roAssociativeArray"
        posters = item.posters
        url = m.stringField(posters, "medium", "")
        if url <> "" then return url
        url = m.stringField(posters, "small", "")
        if url <> "" then return url
        url = m.stringField(posters, "big", "")
        if url <> "" then return url
    end if

    url = m.stringField(media, "thumbnail", "")
    if url <> "" then return url
    return m.stringField(media, "poster", "")
end function

function kinoHistoryStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()
    return fallback
end function

function kinoHistoryIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function kinoHistoryArrayField(source as Dynamic, key as String) as Object
    if source = invalid or type(source) <> "roAssociativeArray" then return []
    if source.DoesExist(key) <> true or source[key] = invalid then return []
    if type(source[key]) = "roArray" then return source[key]
    return []
end function

function kinoHistoryItemIsAnime(item as Dynamic) as Boolean
    genres = m.arrayField(item, "genres")
    for each genre in genres
        if LCase(m.stringField(genre, "title", "")) = "аниме" then return true
    end for
    return false
end function

function kinoHistoryFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function
