function KinoSearchService(client as Object) as Object
    return {
        client: client
        search: kinoSearchItems
        normalizeResponse: kinoSearchNormalizeResponse
        normalizeItem: kinoSearchNormalizeItem
        enrichType: kinoSearchEnrichType
        typeTitleForType: kinoSearchTypeTitleForType
        typeBadgeForType: kinoSearchTypeBadgeForType
        posterUrl: kinoSearchPosterUrl
        subtitle: kinoSearchSubtitle
        metadata: kinoSearchMetadata
        genreTitles: kinoSearchGenreTitles
        countryTitles: kinoSearchCountryTitles
        itemIsAnime: kinoSearchItemIsAnime
        stringField: kinoSearchStringField
        integerField: kinoSearchIntegerField
        arrayField: kinoSearchArrayField
        failure: kinoSearchFailure
    }
end function

function kinoSearchItems(accessToken as String, query as String, page as Integer, perpage as Integer, typeMap = invalid as Dynamic, sortByYear = true as Boolean, contentType = "" as String, searchField = "title" as String, hideAnime = false as Boolean) as Object
    trimmedQuery = query.Trim()
    if trimmedQuery = ""
        return { ok: false, error: "invalid_query", message: "Enter a search term.", status: 0 }
    end if

    normalizedField = LCase(searchField.Trim())
    if normalizedField <> "director" and normalizedField <> "cast" then normalizedField = "title"

    queryParams = {
        access_token: accessToken
        page: page
        perpage: perpage
    }
    queryParams[normalizedField] = trimmedQuery

    selectedType = contentType.Trim()
    if selectedType <> "" then queryParams.type = selectedType
    if sortByYear then queryParams.sort = "year-"

    response = m.client.get("/v1/items", queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeResponse(response.body, page, perpage, typeMap, hideAnime)
end function

function kinoSearchNormalizeResponse(body as Dynamic, requestedPage as Integer, requestedPerPage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    items = []
    pagination = {
        total: 0
        current: requestedPage
        perpage: requestedPerPage
        total_items: 0
    }

    if body = invalid or type(body) <> "roAssociativeArray"
        return { ok: false, items: [], pagination: pagination, error: "invalid_response", message: "Search response was not readable.", status: 0 }
    end if

    if body.DoesExist("items") <> true or body.items = invalid or type(body.items) <> "roArray"
        return { ok: false, items: [], pagination: pagination, error: "invalid_response", message: "Search response did not include an items list.", status: 0 }
    end if

    for each item in body.items
        if hideAnime <> true or m.itemIsAnime(item) <> true
            normalized = m.normalizeItem(item, typeMap)
            if normalized.itemId > 0 then items.Push(normalized)
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

function kinoSearchNormalizeItem(item as Dynamic, typeMap = invalid as Dynamic) as Object
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
    }

    return m.enrichType(normalized, typeMap)
end function

function kinoSearchEnrichType(item as Object, typeMap as Dynamic) as Object
    contentType = ""
    if item.DoesExist("type") and item.type <> invalid then contentType = item.type
    item.typeTitle = m.typeTitleForType(contentType, typeMap)
    item.typeBadge = m.typeBadgeForType(contentType, item.typeTitle, typeMap)
    return item
end function

function kinoSearchTypeTitleForType(contentType as String, typeMap as Dynamic) as String
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

function kinoSearchTypeBadgeForType(contentType as String, title as String, typeMap as Dynamic) as String
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

function kinoSearchPosterUrl(item as Dynamic) as String
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

function kinoSearchSubtitle(item as Dynamic) as String
    values = []
    year = m.integerField(item, "year", 0)
    if year > 0 then values.Push(StrI(year).Trim())

    contentType = m.stringField(item, "type", "")
    if contentType <> "" then values.Push(contentType)

    genres = m.genreTitles(item)
    if genres <> "" then values.Push(genres)

    return values.Join("  |  ")
end function

function kinoSearchMetadata(item as Dynamic) as String
    values = []
    countries = m.countryTitles(item)
    if countries <> "" then values.Push(countries)

    rating = m.stringField(item, "rating", "")
    if rating <> "" and rating <> "0" then values.Push("Rating " + rating)

    return values.Join("  |  ")
end function

function kinoSearchGenreTitles(item as Dynamic) as String
    titles = []
    genres = m.arrayField(item, "genres")
    for each genre in genres
        title = m.stringField(genre, "title", "")
        if title <> "" then titles.Push(title)
        if titles.Count() = 2 then exit for
    end for
    return titles.Join(", ")
end function

function kinoSearchItemIsAnime(item as Dynamic) as Boolean
    genres = m.arrayField(item, "genres")
    for each genre in genres
        if LCase(m.stringField(genre, "title", "")) = "аниме" then return true
    end for
    return false
end function

function kinoSearchCountryTitles(item as Dynamic) as String
    titles = []
    countries = m.arrayField(item, "countries")
    for each country in countries
        title = m.stringField(country, "title", "")
        if title <> "" then titles.Push(title)
        if titles.Count() = 2 then exit for
    end for
    return titles.Join(", ")
end function

function kinoSearchStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()
    return fallback
end function

function kinoSearchIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function kinoSearchArrayField(source as Dynamic, key as String) as Object
    if source = invalid or type(source) <> "roAssociativeArray" then return []
    if source.DoesExist(key) <> true or source[key] = invalid then return []
    if type(source[key]) = "roArray" then return source[key]
    return []
end function

function kinoSearchFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function
