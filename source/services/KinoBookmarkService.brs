function KinoBookmarkService(client as Object) as Object
    return {
        client: client
        listFolders: kinoBookmarkListFolders
        listFolderItems: kinoBookmarkListFolderItems
        itemFolders: kinoBookmarkItemFolders
        toggleItem: kinoBookmarkToggleItem
        normalizeFoldersResponse: kinoBookmarkNormalizeFoldersResponse
        normalizeFolderItemsResponse: kinoBookmarkNormalizeFolderItemsResponse
        normalizeItemFoldersResponse: kinoBookmarkNormalizeItemFoldersResponse
        normalizeFolder: kinoBookmarkNormalizeFolder
        normalizeItem: kinoBookmarkNormalizeItem
        enrichType: kinoBookmarkEnrichType
        typeTitleForType: kinoBookmarkTypeTitleForType
        typeBadgeForType: kinoBookmarkTypeBadgeForType
        posterUrl: kinoBookmarkPosterUrl
        subtitle: kinoBookmarkSubtitle
        metadata: kinoBookmarkMetadata
        genreTitles: kinoBookmarkGenreTitles
        countryTitles: kinoBookmarkCountryTitles
        itemIsAnime: kinoBookmarkItemIsAnime
        stringField: kinoBookmarkStringField
        integerField: kinoBookmarkIntegerField
        arrayField: kinoBookmarkArrayField
        failure: kinoBookmarkFailure
    }
end function

function kinoBookmarkListFolders(accessToken as String) as Object
    response = m.client.get("/v1/bookmarks", { access_token: accessToken }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeFoldersResponse(response.body)
end function

function kinoBookmarkListFolderItems(accessToken as String, folderId as Integer, page as Integer, perpage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    if folderId <= 0 then return { ok: false, error: "invalid_folder", message: "Unable to load this bookmark folder.", status: 0 }
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50

    response = m.client.get("/v1/bookmarks/" + StrI(folderId).Trim(), { access_token: accessToken, page: page, perpage: perpage }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeFolderItemsResponse(response.body, page, perpage, typeMap, hideAnime)
end function

function kinoBookmarkItemFolders(accessToken as String, itemId as Integer) as Object
    if itemId <= 0 then return { ok: false, error: "invalid_item", message: "Unable to load bookmark folders for this item.", status: 0 }

    response = m.client.get("/v1/bookmarks/get-item-folders", { access_token: accessToken, item: itemId }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeItemFoldersResponse(response.body)
end function

function kinoBookmarkToggleItem(accessToken as String, itemId as Integer, folderId as Integer) as Object
    if itemId <= 0 then return { ok: false, error: "invalid_item", message: "Unable to update bookmark.", status: 0 }
    if folderId <= 0 then return { ok: false, error: "invalid_folder", message: "Choose a bookmark folder.", status: 0 }

    response = m.client.postFormBody("/v1/bookmarks/toggle-item", { access_token: accessToken }, { item: itemId, folder: folderId }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return { ok: true, itemId: itemId, folderId: folderId, status: response.status }
end function

function kinoBookmarkNormalizeFoldersResponse(body as Dynamic) as Object
    folders = []

    if body <> invalid and type(body) = "roAssociativeArray" and body.DoesExist("items") and type(body.items) = "roArray"
        for each folder in body.items
            normalized = m.normalizeFolder(folder)
            if normalized.folderId > 0 then folders.Push(normalized)
        end for
    else if body <> invalid and type(body) = "roArray"
        for each folder in body
            normalized = m.normalizeFolder(folder)
            if normalized.folderId > 0 then folders.Push(normalized)
        end for
    else
        return { ok: false, folders: [], error: "invalid_response", message: "Bookmarks response did not include a folder list.", status: 0 }
    end if

    return { ok: true, folders: folders }
end function

function kinoBookmarkNormalizeItemFoldersResponse(body as Dynamic) as Object
    folders = []

    if body <> invalid and type(body) = "roAssociativeArray" and body.DoesExist("folders") and type(body.folders) = "roArray"
        for each folder in body.folders
            normalized = m.normalizeFolder(folder)
            if normalized.folderId > 0 then folders.Push(normalized)
        end for
    end if

    return { ok: true, folders: folders }
end function

function kinoBookmarkNormalizeFolder(folder as Dynamic) as Object
    title = m.stringField(folder, "title", "")
    if title = "" then title = "Untitled folder"

    return {
        folderId: m.integerField(folder, "id", 0)
        title: title
        count: m.integerField(folder, "count", 0)
        views: m.integerField(folder, "views", 0)
        createdSeconds: m.integerField(folder, "created", 0)
        updatedSeconds: m.integerField(folder, "updated", 0)
    }
end function

function kinoBookmarkNormalizeFolderItemsResponse(body as Dynamic, requestedPage as Integer, requestedPerPage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    items = []
    folder = invalid
    pagination = {
        total: 0
        current: requestedPage
        perpage: requestedPerPage
        total_items: 0
    }

    if body = invalid or type(body) <> "roAssociativeArray"
        return { ok: false, folder: folder, items: [], pagination: pagination, error: "invalid_response", message: "Bookmark folder response was not readable.", status: 0 }
    end if

    if body.DoesExist("folder") then folder = m.normalizeFolder(body.folder)
    if body.DoesExist("items") <> true or body.items = invalid or type(body.items) <> "roArray"
        return { ok: false, folder: folder, items: [], pagination: pagination, error: "invalid_response", message: "Bookmark folder response did not include an items list.", status: 0 }
    end if

    for each item in body.items
        if hideAnime <> true or m.itemIsAnime(item) <> true
            normalized = m.normalizeItem(item, typeMap)
            if normalized.itemId > 0 then items.Push(normalized)
        end if
    end for

    if body.DoesExist("pagination") and body.pagination <> invalid and type(body.pagination) = "roAssociativeArray"
        pagination.total = m.integerField(body.pagination, "total", pagination.total)
        pagination.current = m.integerField(body.pagination, "current", pagination.current)
        pagination.perpage = m.integerField(body.pagination, "perpage", pagination.perpage)
        pagination.total_items = m.integerField(body.pagination, "total_items", pagination.total_items)
    end if

    return { ok: true, folder: folder, items: items, pagination: pagination }
end function

function kinoBookmarkNormalizeItem(item as Dynamic, typeMap = invalid as Dynamic) as Object
    title = m.stringField(item, "title", "")
    if title = "" then title = m.stringField(item, "name", "")
    if title = "" then title = "Untitled"

    normalized = {
        itemId: m.integerField(item, "id", 0)
        mediaId: 0
        title: title
        subtitle: m.subtitle(item)
        posterUrl: m.posterUrl(item)
        metadata: m.metadata(item)
        type: m.stringField(item, "type", "")
        year: m.integerField(item, "year", 0)
        imdbRating: m.stringField(item, "imdb_rating", "")
        kinopoiskRating: m.stringField(item, "kinopoisk_rating", "")
        kinopubRating: m.stringField(item, "rating", "")
    }

    return m.enrichType(normalized, typeMap)
end function

function kinoBookmarkEnrichType(item as Object, typeMap as Dynamic) as Object
    contentType = ""
    if item.DoesExist("type") and item.type <> invalid then contentType = item.type
    item.typeTitle = m.typeTitleForType(contentType, typeMap)
    item.typeBadge = m.typeBadgeForType(contentType, item.typeTitle, typeMap)
    return item
end function

function kinoBookmarkTypeTitleForType(contentType as String, typeMap as Dynamic) as String
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

function kinoBookmarkTypeBadgeForType(contentType as String, title as String, typeMap as Dynamic) as String
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

function kinoBookmarkPosterUrl(item as Dynamic) as String
    if item <> invalid and type(item) = "roAssociativeArray" and item.DoesExist("posters") and item.posters <> invalid and type(item.posters) = "roAssociativeArray"
        posters = item.posters
        url = m.stringField(posters, "medium", "")
        if url <> "" then return url
        url = m.stringField(posters, "small", "")
        if url <> "" then return url
        url = m.stringField(posters, "big", "")
        if url <> "" then return url
    end if
    return m.stringField(item, "poster", "")
end function

function kinoBookmarkSubtitle(item as Dynamic) as String
    values = []
    year = m.integerField(item, "year", 0)
    if year > 0 then values.Push(StrI(year).Trim())

    genres = m.genreTitles(item)
    if genres <> "" then values.Push(genres)

    return values.Join("  |  ")
end function

function kinoBookmarkMetadata(item as Dynamic) as String
    values = []
    countries = m.countryTitles(item)
    if countries <> "" then values.Push(countries)

    rating = m.stringField(item, "rating", "")
    if rating <> "" and rating <> "0" then values.Push("Rating " + rating)

    return values.Join("  |  ")
end function

function kinoBookmarkGenreTitles(item as Dynamic) as String
    titles = []
    genres = m.arrayField(item, "genres")
    for each genre in genres
        title = m.stringField(genre, "title", "")
        if title <> "" then titles.Push(title)
        if titles.Count() = 2 then exit for
    end for
    return titles.Join(", ")
end function

function kinoBookmarkItemIsAnime(item as Dynamic) as Boolean
    genres = m.arrayField(item, "genres")
    for each genre in genres
        if LCase(m.stringField(genre, "title", "")) = "аниме" then return true
    end for
    return false
end function

function kinoBookmarkCountryTitles(item as Dynamic) as String
    titles = []
    countries = m.arrayField(item, "countries")
    for each country in countries
        title = m.stringField(country, "title", "")
        if title <> "" then titles.Push(title)
        if titles.Count() = 2 then exit for
    end for
    return titles.Join(", ")
end function

function kinoBookmarkStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()
    return fallback
end function

function kinoBookmarkIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function kinoBookmarkArrayField(source as Dynamic, key as String) as Object
    if source = invalid or type(source) <> "roAssociativeArray" then return []
    if source.DoesExist(key) <> true or source[key] = invalid then return []
    if type(source[key]) = "roArray" then return source[key]
    return []
end function

function kinoBookmarkFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function
