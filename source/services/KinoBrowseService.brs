function KinoBrowseService(client as Object) as Object
    return {
        client: client
        genreSectionName: "kinogenres"
        countrySectionName: "kinocountries"
        cacheTtlSeconds: 86400
        fetchOptionsTimeoutMs: 1500
        loadOptions: kinoBrowseLoadOptions
        listItems: kinoBrowseListItems
        listShortcut: kinoBrowseListShortcut
        shortcutEndpoint: kinoBrowseShortcutEndpoint
        optionList: kinoBrowseOptionList
        fetchOptionList: kinoBrowseFetchOptionList
        loadOptionCache: kinoBrowseLoadOptionCache
        saveOptionCache: kinoBrowseSaveOptionCache
        normalizeOptionsResponse: kinoBrowseNormalizeOptionsResponse
        normalizeOption: kinoBrowseNormalizeOption
        normalizeItemsResponse: kinoBrowseNormalizeItemsResponse
        normalizeItem: kinoBrowseNormalizeItem
        queryParams: kinoBrowseQueryParams
        yearRange: kinoBrowseYearRange
        finishedValue: kinoBrowseFinishedValue
        enrichType: kinoBrowseEnrichType
        typeTitleForType: kinoBrowseTypeTitleForType
        typeBadgeForType: kinoBrowseTypeBadgeForType
        posterUrl: kinoBrowsePosterUrl
        subtitle: kinoBrowseSubtitle
        metadata: kinoBrowseMetadata
        genreTitles: kinoBrowseGenreTitles
        countryTitles: kinoBrowseCountryTitles
        itemIsAnime: kinoBrowseItemIsAnime
        stringField: kinoBrowseStringField
        integerField: kinoBrowseIntegerField
        arrayField: kinoBrowseArrayField
        nowSeconds: kinoBrowseNowSeconds
        failure: kinoBrowseFailure
    }
end function

function kinoBrowseLoadOptions(accessToken as String, typeMap as Object) as Object
    genres = m.optionList(accessToken, "genres", "/v1/genres", m.genreSectionName)
    countries = m.optionList(accessToken, "countries", "/v1/countries", m.countrySectionName)

    return {
        ok: true
        typeMap: typeMap
        genres: genres.items
        countries: countries.items
        genreError: genres.error
        countryError: countries.error
    }
end function

function kinoBrowseOptionList(accessToken as String, listName as String, endpoint as String, sectionName as String) as Object
    cached = m.loadOptionCache(sectionName)
    now = m.nowSeconds()
    if cached.valid = true and cached.cachedAt > 0 and cached.cachedAt + m.cacheTtlSeconds > now
        return { ok: true, items: cached.items, error: "" }
    end if

    fetched = m.fetchOptionList(accessToken, listName, endpoint)
    if fetched.ok = true
        m.saveOptionCache(sectionName, fetched.items, now)
        return { ok: true, items: fetched.items, error: "" }
    end if

    if cached.valid = true then return { ok: true, items: cached.items, error: fetched.message }
    return { ok: false, items: [], error: fetched.message }
end function

function kinoBrowseFetchOptionList(accessToken as String, listName as String, endpoint as String) as Object
    response = m.client.get(endpoint, { access_token: accessToken }, m.fetchOptionsTimeoutMs)
    if response.ok <> true then return m.failure(response)
    items = m.normalizeOptionsResponse(response.body, listName)
    if items.Count() = 0
        return { ok: false, items: [], error: "invalid_response", message: "Browse options were not available.", status: response.status }
    end if
    return { ok: true, items: items }
end function

function kinoBrowseLoadOptionCache(sectionName as String) as Object
    section = CreateObject("roRegistrySection", sectionName)
    rawItems = section.Read("itemsJson")
    rawCachedAt = section.Read("itemsCachedAt")
    if rawItems = invalid or rawItems = "" then return { valid: false, items: [], cachedAt: 0 }

    parsed = ParseJson(rawItems)
    if parsed = invalid or type(parsed) <> "roArray" or parsed.Count() = 0 then return { valid: false, items: [], cachedAt: 0 }

    cachedAt = 0
    if rawCachedAt <> invalid and rawCachedAt <> "" then cachedAt = Val(rawCachedAt)
    return { valid: true, items: parsed, cachedAt: cachedAt }
end function

sub kinoBrowseSaveOptionCache(sectionName as String, items as Object, now as Integer)
    if items = invalid then return
    section = CreateObject("roRegistrySection", sectionName)
    section.Write("itemsJson", FormatJson(items))
    section.Write("itemsCachedAt", StrI(now).Trim())
    section.Flush()
end sub

function kinoBrowseNormalizeOptionsResponse(body as Dynamic, listName as String) as Object
    sourceItems = []
    normalized = []

    if body <> invalid and type(body) = "roAssociativeArray"
        if body.DoesExist(listName) and body[listName] <> invalid and type(body[listName]) = "roArray"
            sourceItems = body[listName]
        else if body.DoesExist("items") and body.items <> invalid and type(body.items) = "roArray"
            sourceItems = body.items
        end if
    else if body <> invalid and type(body) = "roArray"
        sourceItems = body
    end if

    for each optionItem in sourceItems
        option = m.normalizeOption(optionItem)
        if option.id <> "" then normalized.Push(option)
    end for

    return normalized
end function

function kinoBrowseNormalizeOption(optionItem as Dynamic) as Object
    id = m.stringField(optionItem, "id", "")
    if id = "" then id = m.stringField(optionItem, "slug", "")
    if id = "" then id = m.stringField(optionItem, "alias", "")
    if id = "" then id = m.stringField(optionItem, "name", "")

    title = m.stringField(optionItem, "title", "")
    if title = "" then title = m.stringField(optionItem, "name", "")
    if title = "" then title = id

    return {
        id: id
        title: title
    }
end function

function kinoBrowseListItems(accessToken as String, request as Object, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    page = m.integerField(request, "page", 1)
    perpage = m.integerField(request, "perpage", 20)
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50

    queryParams = m.queryParams(accessToken, request, page, perpage)
    response = m.client.get("/v1/items", queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)

    ' Library's own Жанр filter already lets someone explicitly ask for a
    ' specific genre, including Аниме — don't second-guess that choice by
    ' silently emptying the results out from under them. The blanket filter
    ' only applies when browsing "Любой" (no genre picked).
    effectiveHideAnime = hideAnime
    if m.stringField(request, "genreId", "") <> "" then effectiveHideAnime = false

    return m.normalizeItemsResponse(response.body, page, perpage, typeMap, effectiveHideAnime)
end function

' "Shortcut" video lists (fresh/hot/popular) are dedicated endpoints, not a
' filter on /v1/items — see https://kinoapi.com/api_video.html#shortcut.
function kinoBrowseListShortcut(accessToken as String, shortcut as String, request as Object, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    page = m.integerField(request, "page", 1)
    perpage = m.integerField(request, "perpage", 20)
    if page < 1 then page = 1
    if perpage < 1 then perpage = 20
    if perpage > 50 then perpage = 50

    endpoint = m.shortcutEndpoint(shortcut)
    if endpoint = ""
        pagination = { total: 0, current: page, perpage: perpage, total_items: 0 }
        return { ok: false, items: [], pagination: pagination, error: "invalid_shortcut", message: "Unknown shortcut.", status: 0 }
    end if

    queryParams = { access_token: accessToken, page: page, perpage: perpage }
    contentType = m.stringField(request, "contentType", "")
    if contentType <> "" then queryParams.type = contentType

    response = m.client.get(endpoint, queryParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeItemsResponse(response.body, page, perpage, typeMap, hideAnime)
end function

function kinoBrowseShortcutEndpoint(shortcut as String) as String
    if shortcut = "fresh" then return "/v1/items/fresh"
    if shortcut = "hot" then return "/v1/items/hot"
    if shortcut = "popular" then return "/v1/items/popular"
    return ""
end function

function kinoBrowseQueryParams(accessToken as String, request as Object, page as Integer, perpage as Integer) as Object
    queryParams = {
        access_token: accessToken
        page: page
        perpage: perpage
        sort: "year-"
    }

    contentType = m.stringField(request, "contentType", "")
    if contentType <> "" then queryParams.type = contentType

    genreId = m.stringField(request, "genreId", "")
    if genreId <> "" then queryParams.genre = genreId

    countryId = m.stringField(request, "countryId", "")
    if countryId <> "" then queryParams.country = countryId

    range = m.yearRange(m.stringField(request, "yearRange", "all"))
    if range.from > 0 then queryParams.year_from = range.from
    if range.to > 0 then queryParams.year_to = range.to

    finished = m.finishedValue(m.stringField(request, "finished", "any"))
    if finished <> "" then queryParams.finished = finished

    return queryParams
end function

function kinoBrowseYearRange(rangeId as String) as Object
    if rangeId = "2020s" then return { from: 2020, to: 2029 }
    if rangeId = "2010s" then return { from: 2010, to: 2019 }
    if rangeId = "2000s" then return { from: 2000, to: 2009 }
    if rangeId = "1990s" then return { from: 1990, to: 1999 }
    if rangeId = "1980s" then return { from: 1980, to: 1989 }
    if rangeId = "older" then return { from: 0, to: 1979 }
    return { from: 0, to: 0 }
end function

function kinoBrowseFinishedValue(finishedId as String) as String
    if finishedId = "finished" then return "1"
    if finishedId = "unfinished" then return "0"
    return ""
end function

function kinoBrowseNormalizeItemsResponse(body as Dynamic, requestedPage as Integer, requestedPerPage as Integer, typeMap = invalid as Dynamic, hideAnime = false as Boolean) as Object
    items = []
    pagination = {
        total: 0
        current: requestedPage
        perpage: requestedPerPage
        total_items: 0
    }

    if body = invalid or type(body) <> "roAssociativeArray"
        return { ok: false, items: [], pagination: pagination, error: "invalid_response", message: "Browse response was not readable.", status: 0 }
    end if

    if body.DoesExist("items") <> true or body.items = invalid or type(body.items) <> "roArray"
        return { ok: false, items: [], pagination: pagination, error: "invalid_response", message: "Browse response did not include an items list.", status: 0 }
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

    return { ok: true, items: items, pagination: pagination }
end function

function kinoBrowseNormalizeItem(item as Dynamic, typeMap = invalid as Dynamic) as Object
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

function kinoBrowseEnrichType(item as Object, typeMap as Dynamic) as Object
    contentType = ""
    if item.DoesExist("type") and item.type <> invalid then contentType = item.type
    item.typeTitle = m.typeTitleForType(contentType, typeMap)
    item.typeBadge = m.typeBadgeForType(contentType, item.typeTitle, typeMap)
    return item
end function

function kinoBrowseTypeTitleForType(contentType as String, typeMap as Dynamic) as String
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

function kinoBrowseTypeBadgeForType(contentType as String, title as String, typeMap as Dynamic) as String
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

function kinoBrowsePosterUrl(item as Dynamic) as String
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

function kinoBrowseSubtitle(item as Dynamic) as String
    values = []
    year = m.integerField(item, "year", 0)
    if year > 0 then values.Push(StrI(year).Trim())
    genres = m.genreTitles(item)
    if genres <> "" then values.Push(genres)
    return values.Join("  |  ")
end function

function kinoBrowseMetadata(item as Dynamic) as String
    values = []
    countries = m.countryTitles(item)
    if countries <> "" then values.Push(countries)
    rating = m.stringField(item, "rating", "")
    if rating <> "" and rating <> "0" then values.Push("Rating " + rating)
    return values.Join("  |  ")
end function

function kinoBrowseGenreTitles(item as Dynamic) as String
    titles = []
    genres = m.arrayField(item, "genres")
    for each genre in genres
        title = m.stringField(genre, "title", "")
        if title <> "" then titles.Push(title)
        if titles.Count() = 2 then exit for
    end for
    return titles.Join(", ")
end function

' Settings screen's "Скрывать Аниме" toggle. KinoPub has no dedicated
' content type for anime (types are movie/serial/3D/concert/documovie/
' docuserial/tvshow) — anime titles are just movies/serials tagged with the
' "Аниме" genre, so filtering has to check the raw item's genres list.
function kinoBrowseItemIsAnime(item as Dynamic) as Boolean
    genres = m.arrayField(item, "genres")
    for each genre in genres
        if LCase(m.stringField(genre, "title", "")) = "аниме" then return true
    end for
    return false
end function

function kinoBrowseCountryTitles(item as Dynamic) as String
    titles = []
    countries = m.arrayField(item, "countries")
    for each country in countries
        title = m.stringField(country, "title", "")
        if title <> "" then titles.Push(title)
        if titles.Count() = 2 then exit for
    end for
    return titles.Join(", ")
end function

function kinoBrowseStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()
    return fallback
end function

function kinoBrowseIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function kinoBrowseArrayField(source as Dynamic, key as String) as Object
    if source = invalid or type(source) <> "roAssociativeArray" then return []
    if source.DoesExist(key) <> true or source[key] = invalid then return []
    if type(source[key]) = "roArray" then return source[key]
    return []
end function

function kinoBrowseNowSeconds() as Integer
    dt = CreateObject("roDateTime")
    return dt.AsSeconds()
end function

function kinoBrowseFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function
