' Shared "filtered poster-grid" screen used by the Movies, Series, and
' Library pill-nav tabs. Structurally a copy of ContinueScreen.brs's two-pane
' layout (PillNavBar + left panel + poster grid + up-arrow-to-nav focus
' machine), adapted for two modes (m.mode, set in configure()):
'  - "shortcut" for Movies/Series: contentType fixed to "movie"/"serial",
'    left list is KinoPub's fresh/hot/popular shortcut lists — dedicated
'    endpoints, see https://kinoapi.com/api_video.html#shortcut. These
'    endpoints reject an empty/missing `type`, confirmed via a 400
'    "Отсутствуют обязательные параметры: type", so they can't serve
'    Library's "everything" case.
'  - "filterbar" for Library: contentType "", no left list — instead a
'    horizontal Тип/Жанр/Страна/Год/Статус filter bar (matching the
'    original legacy Browse page's UX, HomeScreen.xml's browseFilterBar/
'    browsePickerGroup) above a full-width grid, via the regular /v1/items
'    endpoint (loadBrowseItems), which treats every filter as optional.
'  - real server-side pagination instead of "render the whole bounded list"
' All top-level helpers are prefixed browseScreen*/onBrowseItems* to
' avoid colliding with ContinueScreen.brs's identically-shaped globals — every
' top-level sub/function in this channel shares one global namespace
' regardless of which component's <script> tags loaded it. init()/onKeyEvent()
' and observeField-callback names are the exception (resolved per-instance),
' so those are safely left matching ContinueScreen.brs's names.
'
' contentType/navTabId are NOT interface fields: init() runs synchronously
' inside CreateObject(), before the caller (AppScene's ensureBrowseScreen) can
' assign anything afterward, so a field set post-construction is invisible to
' init() — every instance would silently init as whatever the XML default
' was. AppScene instead calls the "configure" interface function explicitly
' right after creation, which runs on demand rather than at a fixed point in
' the node's lifecycle.

sub init()
    m.pillNav = m.top.findNode("pillNav")
    m.leftListHost = m.top.findNode("leftListHost")
    m.leftListContent = m.top.findNode("leftListContent")
    m.filterBarHost = m.top.findNode("filterBarHost")
    m.gridHost = m.top.findNode("gridHost")
    m.gridContent = m.top.findNode("gridContent")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    m.errorLabel = m.top.findNode("errorLabel")
    m.errorRetryFocus = m.top.findNode("errorRetryFocus")
    m.exitDialog = m.top.findNode("exitDialog")
    m.exitDialog.observeField("dialogResult", "onExitDialogResult")
    m.filterPickerDialog = m.top.findNode("filterPickerDialog")
    m.filterPickerDialog.observeField("dialogResult", "onFilterPickerResult")

    m.gridColumns = 5
    m.gridCardWidth = 170
    m.gridCardGapX = 22
    m.gridCardGapY = 26
    m.gridRowStep = 0
    m.gridContentOffsetY = 0
    m.gridViewportHeight = 596
    m.gridScrollAnimation = invalid
    m.gridScrollInterpolator = invalid

    ' Same clipping-padding trick as ContinueScreen.brs: shift the viewport
    ' up-left, grow the clip region by the pad on every side, shift the
    ' content group back down-right — gives focus-pop tiles room to scale
    ' without getting clipped at the viewport edges. Base position/viewport
    ' height depend on mode (filterbar has no left column but does have a
    ' filter bar above it), so this is finished off by browseScreenLayoutGrid,
    ' called from configure() once the mode is known.
    m.gridPad = 44

    ' Filter bar (Library / "filterbar" mode): 5 buttons, findNode'd once in
    ' a fixed order matching the XML.
    m.filterButtonNodes = [
        { id: "type", bg: m.top.findNode("filterTypeBg"), label: m.top.findNode("filterTypeLabel") }
        { id: "genre", bg: m.top.findNode("filterGenreBg"), label: m.top.findNode("filterGenreLabel") }
        { id: "country", bg: m.top.findNode("filterCountryBg"), label: m.top.findNode("filterCountryLabel") }
        { id: "year", bg: m.top.findNode("filterYearBg"), label: m.top.findNode("filterYearLabel") }
        { id: "finished", bg: m.top.findNode("filterFinishedBg"), label: m.top.findNode("filterFinishedLabel") }
    ]
    m.filterValues = { contentType: "", genreId: "", countryId: "", yearRange: "all", finished: "any" }
    m.filterOptions = { typeMap: {}, genres: [], countries: [] }
    m.selectedFilterIndex = 0
    m.activeFilterId = ""

    ' Left list: rows pivot-scale from the left edge (x=0), so only
    ' vertical + right-edge clip slack is needed, not a symmetric pad.
    m.leftRowHeight = 34
    m.leftRowWidth = 220
    m.leftRowStep = m.leftRowHeight + 4
    m.leftListOffsetY = 0
    m.leftListViewportHeight = 596
    m.leftListScrollAnimation = invalid
    m.leftListScrollInterpolator = invalid
    m.leftListPadTop = 8
    m.leftListPadBottom = 8
    m.leftListPadRight = 20
    leftBaseX = 30
    leftBaseY = 90
    m.leftListHost.translation = [leftBaseX, leftBaseY - m.leftListPadTop]
    m.leftListHost.clippingRect = [0, 0, m.leftRowWidth + m.leftListPadRight, m.leftListViewportHeight + m.leftListPadTop + m.leftListPadBottom]
    m.leftListContent.translation = [0, m.leftListPadTop]

    m.pillNav.tabs = [
        { id: "search", label: "Поиск" }
        { id: "movies", label: "Фильмы" }
        { id: "series", label: "Сериалы" }
        { id: "continue", label: "Мои" }
        { id: "library", label: "Библиотека" }
        { id: "tv", label: "ТВ" }
        { id: "settings", label: "", icon: "pkg:/images/ui/icon-settings.png" }
    ]
    m.pillNav.active = false
    m.pillNav.observeField("tabActivated", "onNavTabActivated")
    m.pillNav.observeField("focusExitDown", "onNavFocusExitDown")

    m.contentType = "movie"
    m.navTabId = "movies"
    m.focusArea = "leftList"
    m.navEntryArea = "leftList"
    m.leftRows = []
    m.leftRowNodes = []
    m.selectedRowIndex = 0
    m.selectedGridIndex = 0
    m.gridItems = []
    m.gridCardNodes = []
    m.gridPage = 0
    m.gridPagination = invalid
    m.gridPendingIsAppend = false
    m.gridLoadingMore = false
    m.gridReachedEnd = false
    m.mode = "shortcut"
    m.gridActiveKey = ""
    m.gridItemCap = 300
    m.pendingFocusGrid = false

    m.top.setFocus(true)
end sub

' Called explicitly by AppScene right after CreateObject — see the header
' comment above for why this can't just be a field read in init().
sub configure(contentType as String, navTabId as String)
    m.contentType = contentType
    m.navTabId = navTabId
    m.pillNav.selectedTabId = navTabId

    if contentType = ""
        ' Library: no fixed content type, filter bar instead of a left list
        ' — see the header comment for why the shortcut endpoints can't
        ' serve this "everything" case.
        m.mode = "filterbar"
        m.gridColumns = 6
        ' Filter bar sits at y=70 (see BrowseScreen.xml), bottom edge 114 —
        ' the 46px gap down to the grid's own top (160) isn't just visual
        ' spacing: the focus-pop scale/shadow effect on the top row relies
        ' on ~44px of clip padding (m.gridPad) to not get cut off, and
        ' clippingRect isn't reliably enforced on every runtime this ships
        ' to (see the windowing comment on browseScreenUpdateGridVisibility)
        ' — so that padding routinely renders unclipped. A gap smaller than
        ' the pad (previously 26px here) let the top row's popped card bleed
        ' straight into the filter bar. Bottom margin is trimmed to 16
        ' (720-160-544=16) since an unclipped bleed there only reaches blank
        ' canvas, not another control.
        browseScreenLayoutGrid(30, 160, 544)
        browseScreenRenderFilterBar()
        m.selectedFilterIndex = 0
        m.focusArea = "filterBar"
        m.navEntryArea = "filterBar"
        browseScreenUpdateFilterBarFocus()
        ' Fire the grid load immediately with default sentinels (all/any) —
        ' don't block on genre/country options finishing; those only matter
        ' once a picker is actually opened.
        browseScreenReloadGridForFilters()
        browseScreenLoadFilterOptions()
    else
        ' Movies/Series: fixed content type, left list is the 3 shortcuts.
        m.mode = "shortcut"
        m.gridColumns = 5
        browseScreenLayoutGrid(300, 90, 596)
        browseScreenBuildShortcutRows()
        browseScreenRenderLeftList()
        browseScreenSelectRow(0)
    end if
end sub

sub browseScreenLayoutGrid(gridBaseX as Integer, gridBaseY as Integer, viewportHeight as Integer)
    m.gridViewportHeight = viewportHeight
    contentWidth = (m.gridCardWidth * m.gridColumns) + (m.gridCardGapX * (m.gridColumns - 1))
    m.gridHost.translation = [gridBaseX - m.gridPad, gridBaseY - m.gridPad]
    m.gridHost.clippingRect = [0, 0, contentWidth + (m.gridPad * 2), m.gridViewportHeight + (m.gridPad * 2)]
    m.gridContent.translation = [m.gridPad, m.gridPad]
end sub

' Left list is the KinoPub "shortcut" video lists — dedicated endpoints, not
' a genre filter. See https://kinoapi.com/api_video.html#shortcut.
sub browseScreenBuildShortcutRows()
    noun = browseScreenContentTypeNoun(m.contentType)
    m.leftRows = [
        { id: "fresh", label: "Свежие " + noun, shortcut: "fresh" }
        { id: "hot", label: "Горячие " + noun, shortcut: "hot" }
        { id: "popular", label: "Популярные " + noun, shortcut: "popular" }
    ]
end sub

function browseScreenContentTypeNoun(contentType as String) as String
    if contentType = "movie" then return "фильмы"
    if contentType = "serial" then return "сериалы"
    return "видео"
end function

' Fetches Type/Genre/Country option lists for the filter pickers, in the
' background — the grid's own first load doesn't wait on this (see
' configure()). A single loadBrowseOptions call returns all three
' (ContentTask.brs's contentTaskLoadBrowseOptions bundles typeMap in with
' genres/countries).
sub browseScreenLoadFilterOptions()
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadBrowseOptions"
    task.request = {}
    task.observeField("response", "onFilterOptionsResponse")
    task.control = "RUN"
    m.filterOptionsTask = task
end sub

sub onFilterOptionsResponse(event as Object)
    response = event.getData()
    if browseScreenHandleAuthRequired(response) then return
    if response = invalid or response.ok <> true then return

    if response.typeMap <> invalid then m.filterOptions.typeMap = response.typeMap
    if response.genres <> invalid then m.filterOptions.genres = response.genres
    if response.countries <> invalid then m.filterOptions.countries = response.countries

    browseScreenRenderFilterBar()
end sub

' Option lists ported from HomeScreen.brs's browseTypeOptions/
' browseYearOptions/browseFinishedOptions/browseOptionsWithAny — same ids,
' since KinoBrowseService's kinoBrowseYearRange/kinoBrowseFinishedValue (and
' the server, for type/genre/country ids) interpret these exact strings.
function browseScreenTypeOptions() as Object
    items = [{ id: "", title: "Все" }]
    for each typeId in m.filterOptions.typeMap
        entry = m.filterOptions.typeMap[typeId]
        title = typeId
        if entry <> invalid and entry.DoesExist("title") and entry.title <> "" then title = entry.title
        items.Push({ id: typeId, title: title })
    end for
    return items
end function

function browseScreenOptionsWithAny(items as Object, anyTitle as String) as Object
    result = [{ id: "", title: anyTitle }]
    for each item in items
        result.Push({ id: item.id, title: item.title })
    end for
    return result
end function

function browseScreenYearOptions() as Object
    return [
        { id: "all", title: "Все" }
        { id: "2020s", title: "2020-е" }
        { id: "2010s", title: "2010-е" }
        { id: "2000s", title: "2000-е" }
        { id: "1990s", title: "1990-е" }
        { id: "1980s", title: "1980-е" }
        { id: "older", title: "Раньше" }
    ]
end function

function browseScreenFinishedOptions() as Object
    return [
        { id: "any", title: "Любой" }
        { id: "finished", title: "Окончен" }
        { id: "unfinished", title: "Неокончен" }
    ]
end function

function browseScreenFilterOptionsForFilter(filterId as String) as Object
    if filterId = "type" then return browseScreenTypeOptions()
    if filterId = "genre" then return browseScreenOptionsWithAny(m.filterOptions.genres, "Любой")
    if filterId = "country" then return browseScreenOptionsWithAny(m.filterOptions.countries, "Любая")
    if filterId = "year" then return browseScreenYearOptions()
    if filterId = "finished" then return browseScreenFinishedOptions()
    return []
end function

function browseScreenFilterPickerTitle(filterId as String) as String
    if filterId = "type" then return "Выберите тип"
    if filterId = "genre" then return "Выберите жанр"
    if filterId = "country" then return "Выберите страну"
    if filterId = "year" then return "Выберите год"
    if filterId = "finished" then return "Выберите статус"
    return ""
end function

function browseScreenFilterValueForId(filterId as String) as String
    if filterId = "type" then return m.filterValues.contentType
    if filterId = "genre" then return m.filterValues.genreId
    if filterId = "country" then return m.filterValues.countryId
    if filterId = "year" then return m.filterValues.yearRange
    if filterId = "finished" then return m.filterValues.finished
    return ""
end function

sub browseScreenSetFilterValue(filterId as String, value as String)
    if filterId = "type" then m.filterValues.contentType = value
    if filterId = "genre" then m.filterValues.genreId = value
    if filterId = "country" then m.filterValues.countryId = value
    if filterId = "year" then m.filterValues.yearRange = value
    if filterId = "finished" then m.filterValues.finished = value
end sub

function browseScreenTitleForValue(items as Object, value as String) as String
    for each item in items
        if item.id = value then return item.title
    end for
    if items.Count() > 0 then return items[0].title
    return ""
end function

sub browseScreenRenderFilterBar()
    prefixes = { type: "Тип: ", genre: "Жанр: ", country: "Страна: ", year: "Год: ", finished: "Статус: " }
    for each node in m.filterButtonNodes
        items = browseScreenFilterOptionsForFilter(node.id)
        value = browseScreenFilterValueForId(node.id)
        title = browseScreenTitleForValue(items, value)
        node.label.text = prefixes[node.id] + title
    end for
end sub

sub browseScreenUpdateFilterBarFocus()
    theme = UiThemeLight()
    for i = 0 to m.filterButtonNodes.Count() - 1
        node = m.filterButtonNodes[i]
        isFocused = (i = m.selectedFilterIndex) and (m.focusArea = "filterBar")
        if isFocused
            node.bg.color = theme.surfaceFocus
        else
            node.bg.color = theme.surfaceAlt
        end if
    end for
end sub

' Opens the picker WITHOUT transferring real SceneGraph focus to it — this
' screen keeps focus the entire time; see ListPickerDialog.brs's header
' comment for why (giving the dialog real focus turned out not to reliably
' hand it back). onKeyEvent checks m.filterPickerDialog.visible at the top
' and routes Up/Down/OK to it via callFunc while it's open.
sub browseScreenOpenFilterPicker()
    filterId = m.filterButtonNodes[m.selectedFilterIndex].id
    m.activeFilterId = filterId
    items = browseScreenFilterOptionsForFilter(filterId)
    selectedId = browseScreenFilterValueForId(filterId)
    m.filterPickerDialog.callFunc("configure", browseScreenFilterPickerTitle(filterId), items, selectedId)
    m.filterPickerDialog.visible = true
end sub

sub onFilterPickerResult(event as Object)
    result = event.getData()
    m.filterPickerDialog.visible = false
    if result <> invalid and result.action = "confirm"
        browseScreenSetFilterValue(m.activeFilterId, result.id)
        browseScreenRenderFilterBar()
        ' Once the filtered page loads, jump focus straight to the first
        ' tile instead of leaving it on the filter bar — consumed in
        ' onBrowseItemsResponse once the (async) reload actually lands.
        m.pendingFocusGrid = true
        browseScreenReloadGridForFilters()
    end if
    m.activeFilterId = ""
    browseScreenUpdateFilterBarFocus()
end sub

sub browseScreenReloadGridForFilters()
    m.selectedGridIndex = 0
    m.gridPage = 0
    m.gridPagination = invalid
    m.gridReachedEnd = false
    browseScreenShowState("loading")
    browseScreenLoadGridPage(1, false)
end sub

' Public: called by AppScene via callFunc whenever this screen is shown as a
' result of activating its pill-nav tab, so landing on Movies/Series/Library
' drops you straight into browsing tiles instead of the left list/filter
' bar. Screens here are only ever created via nav activation in the first
' place, so this also covers the very-first-ever visit: the grid hasn't
' loaded yet at that point (configure()'s initial load is still in flight),
' so this just sets m.pendingFocusGrid and onBrowseItemsResponse's fresh-
' load branch consumes it the instant items actually become available. On a
' repeat visit the grid already has items, so this applies immediately.
sub focusContent()
    if m.gridItems.Count() > 0
        m.focusArea = "grid"
        m.selectedGridIndex = 0
        if m.mode = "filterbar" then browseScreenUpdateFilterBarFocus() else browseScreenUpdateLeftListFocus()
        browseScreenUpdateGridFocus()
    else
        m.pendingFocusGrid = true
    end if
end sub

function browseScreenHandleAuthRequired(response as Dynamic) as Boolean
    if response = invalid or type(response) <> "roAssociativeArray" then return false
    errorCode = ""
    if response.DoesExist("error") and response.error <> invalid then errorCode = LCase(response.error)
    isAuthError = false
    if response.DoesExist("status") and response.status = 401 then isAuthError = true
    if errorCode = "auth_required" or errorCode = "unauthorized" or errorCode = "invalid_grant" then isAuthError = true
    if isAuthError
        m.top.authRequired = true
        return true
    end if
    return false
end function

sub browseScreenRenderLeftList()
    childCount = m.leftListContent.getChildCount()
    if childCount > 0 then m.leftListContent.removeChildrenIndex(childCount, 0)
    m.leftRowNodes = []
    m.leftListOffsetY = 0
    m.leftListContent.translation = [0, m.leftListPadTop]

    theme = UiThemeLight()
    rowHeight = m.leftRowHeight
    rowWidth = m.leftRowWidth

    for i = 0 to m.leftRows.Count() - 1
        row = m.leftRows[i]
        y = i * m.leftRowStep

        rowGroup = CreateObject("roSGNode", "Group")
        rowGroup.translation = [0, y]
        rowGroup.scaleRotateCenter = [0, Int(rowHeight / 2)]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = rowWidth
        bg.height = rowHeight
        bg.color = theme.surfaceAlt
        rowGroup.appendChild(bg)

        accentBar = CreateObject("roSGNode", "Rectangle")
        accentBar.width = 4
        accentBar.height = rowHeight
        accentBar.color = theme.focusBorder
        accentBar.visible = false
        rowGroup.appendChild(accentBar)

        label = CreateObject("roSGNode", "Label")
        label.text = row.label
        label.translation = [10, 5]
        label.width = rowWidth - 20
        label.height = 22
        label.color = theme.text
        label.font.size = 18
        rowGroup.appendChild(label)

        m.leftListContent.appendChild(rowGroup)
        m.leftRowNodes.Push({ group: rowGroup, bg: bg, accentBar: accentBar })
    end for

    browseScreenUpdateLeftListVisibility()
    browseScreenUpdateLeftListFocus()
end sub

sub browseScreenUpdateLeftListVisibility()
    if m.leftRowStep = 0 then return
    firstVisibleRow = Int(m.leftListOffsetY / m.leftRowStep)
    lastVisibleRow = Int((m.leftListOffsetY + m.leftListViewportHeight - 1) / m.leftRowStep)
    for i = 0 to m.leftRowNodes.Count() - 1
        m.leftRowNodes[i].group.visible = (i >= firstVisibleRow) and (i <= lastVisibleRow)
    end for
end sub

sub browseScreenUpdateLeftListFocus()
    theme = UiThemeLight()
    for i = 0 to m.leftRowNodes.Count() - 1
        node = m.leftRowNodes[i]
        isSelected = i = m.selectedRowIndex
        isFocused = isSelected and m.focusArea = "leftList"
        node.accentBar.visible = isFocused
        if isFocused
            node.bg.color = theme.surfaceFocus
            node.group.scale = [1.06, 1.06]
        else if isSelected
            node.bg.color = theme.surfaceSelected
            node.group.scale = [1.0, 1.0]
        else
            node.bg.color = theme.surfaceAlt
            node.group.scale = [1.0, 1.0]
        end if
    end for
    browseScreenScrollLeftListToFocus()
end sub

sub browseScreenScrollLeftListToFocus()
    if m.leftRowNodes.Count() = 0 or m.leftRowStep = 0 then return

    rowTop = m.selectedRowIndex * m.leftRowStep
    rowBottom = rowTop + m.leftRowStep

    currentOffset = m.leftListOffsetY
    newOffset = currentOffset

    if rowTop < currentOffset
        newOffset = rowTop
    else if rowBottom > (currentOffset + m.leftListViewportHeight)
        newOffset = rowBottom - m.leftListViewportHeight
    end if

    if newOffset < 0 then newOffset = 0
    if newOffset <> currentOffset
        browseScreenAnimateLeftListScroll(currentOffset, newOffset)
        m.leftListOffsetY = newOffset
        browseScreenUpdateLeftListVisibility()
    end if
end sub

sub browseScreenAnimateLeftListScroll(fromY as Integer, toY as Integer)
    if m.leftListScrollAnimation = invalid
        animation = CreateObject("roSGNode", "Animation")
        animation.duration = 0.25
        animation.easeFunction = "inOutQuad"
        interpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        interpolator.key = [0, 1]
        interpolator.fieldToInterp = "leftListContent.translation"
        animation.appendChild(interpolator)
        m.top.appendChild(animation)
        m.leftListScrollAnimation = animation
        m.leftListScrollInterpolator = interpolator
    end if

    m.leftListScrollInterpolator.keyValue = [[0, m.leftListPadTop - fromY], [0, m.leftListPadTop - toY]]
    m.leftListScrollAnimation.control = "start"
end sub

sub browseScreenSelectRow(index as Integer)
    if m.leftRows.Count() = 0 then return
    if index < 0 then index = 0
    if index >= m.leftRows.Count() then index = m.leftRows.Count() - 1
    m.selectedRowIndex = index
    browseScreenUpdateLeftListFocus()

    m.selectedGridIndex = 0
    m.gridPage = 0
    m.gridPagination = invalid
    m.gridReachedEnd = false
    browseScreenShowState("loading")
    browseScreenLoadGridPage(1, false)
end sub

sub browseScreenLoadGridPage(page as Integer, isAppend as Boolean)
    m.gridPendingIsAppend = isAppend
    m.gridLoadingMore = true

    task = CreateObject("roSGNode", "ContentTask")

    if m.mode = "filterbar"
        task.command = "loadBrowseItems"
        task.request = { page: page, perpage: 50, contentType: m.filterValues.contentType, genreId: m.filterValues.genreId, countryId: m.filterValues.countryId, yearRange: m.filterValues.yearRange, finished: m.filterValues.finished }
    else
        shortcut = ""
        if m.leftRows.Count() > 0 and m.selectedRowIndex >= 0 and m.selectedRowIndex < m.leftRows.Count()
            shortcut = m.leftRows[m.selectedRowIndex].shortcut
        end if
        m.gridActiveKey = shortcut
        task.command = "loadShortcutItems"
        task.request = { page: page, perpage: 50, contentType: m.contentType, shortcut: shortcut }
    end if

    task.observeField("response", "onBrowseItemsResponse")
    task.control = "RUN"
    m.browseItemsTask = task
end sub

sub onBrowseItemsResponse(event as Object)
    response = event.getData()
    isAppend = m.gridPendingIsAppend
    m.gridLoadingMore = false

    if browseScreenHandleAuthRequired(response) then return

    ' Discard a response for filters/a shortcut the user has since navigated
    ' away from (fields are echoed back by the matching ContentTask command).
    if response <> invalid
        if m.mode = "filterbar"
            if response.DoesExist("contentType") and response.contentType <> m.filterValues.contentType then return
            if response.DoesExist("genreId") and response.genreId <> m.filterValues.genreId then return
            if response.DoesExist("countryId") and response.countryId <> m.filterValues.countryId then return
            if response.DoesExist("yearRange") and response.yearRange <> m.filterValues.yearRange then return
            if response.DoesExist("finished") and response.finished <> m.filterValues.finished then return
        end if
        if m.mode = "shortcut" and response.DoesExist("shortcut") and response.shortcut <> m.gridActiveKey then return
    end if

    if response = invalid or response.ok <> true or response.items = invalid
        if isAppend
            m.gridReachedEnd = true
        else
            m.pendingFocusGrid = false
            browseScreenShowState("error")
        end if
        return
    end if

    m.gridPagination = response.pagination
    m.gridPage = response.page

    if isAppend
        startIndex = m.gridItems.Count()
        m.gridItems.Append(response.items)
        if m.gridPagination <> invalid and m.gridPagination.total_items <= m.gridItems.Count() then m.gridReachedEnd = true
        browseScreenAppendGridItems(startIndex, response.items)
        browseScreenUpdateGridVisibility()
    else
        m.gridItems = response.items
        if m.gridPagination <> invalid and m.gridPagination.total_items <= m.gridItems.Count() then m.gridReachedEnd = true
        if m.pendingFocusGrid
            m.pendingFocusGrid = false
            if m.gridItems.Count() > 0
                m.focusArea = "grid"
                m.selectedGridIndex = 0
            end if
            if m.mode = "filterbar" then browseScreenUpdateFilterBarFocus() else browseScreenUpdateLeftListFocus()
        end if
        browseScreenResetGrid()
        browseScreenShowState("content")
    end if
end sub

sub browseScreenResetGrid()
    childCount = m.gridContent.getChildCount()
    if childCount > 0 then m.gridContent.removeChildrenIndex(childCount, 0)
    m.gridCardNodes = []
    m.gridContentOffsetY = 0
    m.gridContent.translation = [m.gridPad, m.gridPad]

    if m.gridItems.Count() = 0
        empty = CreateObject("roSGNode", "Label")
        empty.text = "Нет результатов"
        empty.width = 700
        empty.height = 40
        empty.color = UiThemeLight().muted
        m.gridContent.appendChild(empty)
        m.gridRowStep = 0
        return
    end if

    m.gridRowStep = posterCompactLayout(0, 0, m.gridCardWidth).cardHeight + m.gridCardGapY
    browseScreenAppendGridItems(0, m.gridItems)
    browseScreenUpdateGridVisibility()
    browseScreenUpdateGridFocus()
end sub

sub browseScreenAppendGridItems(startIndex as Integer, newItems as Object)
    if m.gridRowStep = 0 then m.gridRowStep = posterCompactLayout(0, 0, m.gridCardWidth).cardHeight + m.gridCardGapY
    columns = m.gridColumns
    cardW = m.gridCardWidth

    for i = 0 to newItems.Count() - 1
        index = startIndex + i
        gridItem = newItems[i]
        column = index MOD columns
        row = Int(index / columns)

        x = column * (cardW + m.gridCardGapX)
        y = row * m.gridRowStep
        layout = posterCompactLayout(x, y, cardW)

        cardInfo = createPosterCard(gridItem, layout)
        m.gridContent.appendChild(cardInfo.node)
        m.gridCardNodes.Push({ node: cardInfo.node, focusBg: cardInfo.focusBg, focusShadow: cardInfo.focusShadow, index: index, row: row })
    end for
end sub

' Same strict zero-buffer visibility windowing as ContinueScreen.brs — not
' relying on clippingRect being enforced on every runtime this ships to.
sub browseScreenUpdateGridVisibility()
    if m.gridRowStep = 0 then return
    firstVisibleRow = Int(m.gridContentOffsetY / m.gridRowStep)
    lastVisibleRow = Int((m.gridContentOffsetY + m.gridViewportHeight - 1) / m.gridRowStep)
    for each cardNode in m.gridCardNodes
        cardNode.node.visible = (cardNode.row >= firstVisibleRow) and (cardNode.row <= lastVisibleRow)
    end for
end sub

sub browseScreenUpdateGridFocus()
    theme = UiThemeLight()
    for each cardNode in m.gridCardNodes
        isFocused = cardNode.index = m.selectedGridIndex and m.focusArea = "grid"
        cardNode.focusShadow.visible = isFocused
        if isFocused
            cardNode.focusBg.color = theme.surfaceFocus
            cardNode.node.scale = [1.16, 1.16]
        else
            cardNode.focusBg.color = theme.surface
            cardNode.node.scale = [1.0, 1.0]
        end if
    end for
    browseScreenScrollGridToFocus()
    browseScreenMaybeLoadNextPage()
end sub

sub browseScreenScrollGridToFocus()
    if m.gridCardNodes.Count() = 0 or m.gridRowStep = 0 then return

    focusedRow = Int(m.selectedGridIndex / m.gridColumns)
    rowTop = focusedRow * m.gridRowStep
    rowBottom = rowTop + m.gridRowStep

    currentOffset = m.gridContentOffsetY
    newOffset = currentOffset

    if rowTop < currentOffset
        newOffset = rowTop
    else if rowBottom > (currentOffset + m.gridViewportHeight)
        newOffset = rowBottom - m.gridViewportHeight
    end if

    if newOffset < 0 then newOffset = 0
    if newOffset <> currentOffset
        browseScreenAnimateGridScroll(currentOffset, newOffset)
        m.gridContentOffsetY = newOffset
        browseScreenUpdateGridVisibility()
    end if
end sub

sub browseScreenAnimateGridScroll(fromY as Integer, toY as Integer)
    if m.gridScrollAnimation = invalid
        animation = CreateObject("roSGNode", "Animation")
        animation.duration = 0.25
        animation.easeFunction = "inOutQuad"
        interpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        interpolator.key = [0, 1]
        interpolator.fieldToInterp = "gridContent.translation"
        animation.appendChild(interpolator)
        m.top.appendChild(animation)
        m.gridScrollAnimation = animation
        m.gridScrollInterpolator = interpolator
    end if

    m.gridScrollInterpolator.keyValue = [[m.gridPad, m.gridPad - fromY], [m.gridPad, m.gridPad - toY]]
    m.gridScrollAnimation.control = "start"
end sub

' Fetch the next page once focus is within 2 rows of the bottom of what's
' currently loaded. Guarded by a flat item cap (see m.gridItemCap, init())
' rather than true node virtualization — a pragmatic bound for this pass.
sub browseScreenMaybeLoadNextPage()
    if m.gridLoadingMore or m.gridReachedEnd then return
    if m.gridItems.Count() = 0 or m.gridItems.Count() >= m.gridItemCap then return
    if m.gridRowStep = 0 then return

    totalRows = Int((m.gridItems.Count() - 1) / m.gridColumns) + 1
    focusedRow = Int(m.selectedGridIndex / m.gridColumns)
    if focusedRow >= totalRows - 2
        browseScreenLoadGridPage(m.gridPage + 1, true)
    end if
end sub

sub browseScreenShowState(state as String)
    m.loadingGroup.visible = state = "loading"
    m.errorGroup.visible = state = "error"
    m.gridHost.visible = state = "content"
    if m.mode = "filterbar"
        m.filterBarHost.visible = state = "content"
        m.leftListHost.visible = false
    else
        m.leftListHost.visible = state = "content"
        m.filterBarHost.visible = false
    end if
end sub

sub browseScreenRetryLoad()
    browseScreenShowState("loading")
    browseScreenLoadGridPage(1, false)
end sub

sub onNavTabActivated(event as Object)
    tabId = event.getData()
    if tabId = m.navTabId then return
    ' Navigating away to a different screen — reset nav focus state now so
    ' that when this screen is shown again later, m.focusArea/pillNav.active
    ' are valid instead of stuck on "nav" with real focus back on m.top
    ' (which onKeyEvent has no "nav" branch for, leaving keys dead).
    onNavFocusExitDown()
    if tabId = "continue"
        m.top.openContinueScreen = true
        return
    end if
    if tabId = "settings"
        m.top.openDevFonts = true
        return
    end if
    if tabId = "movies" or tabId = "series" or tabId = "library" or tabId = "tv" or tabId = "search"
        m.top.openTabScreen = tabId
        return
    end if
    m.top.openLegacyHomeSection = browseScreenLegacySectionForTab(tabId)
end sub

function browseScreenLegacySectionForTab(tabId as String) as String
    return "home"
end function

sub onNavFocusExitDown()
    m.pillNav.active = false
    m.top.setFocus(true)
    if m.navEntryArea = "grid" and m.gridItems.Count() > 0
        m.focusArea = "grid"
        browseScreenUpdateGridFocus()
    else if m.mode = "filterbar"
        m.focusArea = "filterBar"
        browseScreenUpdateFilterBarFocus()
    else
        m.focusArea = "leftList"
        browseScreenUpdateLeftListFocus()
    end if
end sub

sub onExitDialogResult(event as Object)
    result = event.getData()
    m.exitDialog.visible = false
    if result = "confirm" then m.top.exitRequested = true
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false

    ' Dialogs never take real SceneGraph focus (see ListPickerDialog.brs's
    ' header comment) — this screen keeps it throughout, so key routing to
    ' whichever dialog is open has to happen explicitly, here, before
    ' anything else.
    if m.filterPickerDialog.visible
        if key = "up"
            m.filterPickerDialog.callFunc("moveSelection", -1)
        else if key = "down"
            m.filterPickerDialog.callFunc("moveSelection", 1)
        else if key = "OK"
            m.filterPickerDialog.callFunc("confirmSelection")
        else if key = "back" or key = "left"
            m.filterPickerDialog.visible = false
        end if
        return true
    end if

    if m.exitDialog.visible
        if key = "left" or key = "right"
            m.exitDialog.callFunc("toggleSelection")
        else if key = "OK"
            m.exitDialog.callFunc("confirmSelection")
        else if key = "back"
            m.exitDialog.visible = false
        end if
        return true
    end if

    if m.errorGroup.visible
        if key = "OK"
            browseScreenRetryLoad()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    if m.focusArea = "leftList"
        if key = "up"
            if m.selectedRowIndex = 0
                m.focusArea = "nav"
                m.navEntryArea = "leftList"
                browseScreenUpdateLeftListFocus()
                m.pillNav.active = true
                m.pillNav.setFocus(true)
            else
                browseScreenSelectRow(m.selectedRowIndex - 1)
            end if
            return true
        else if key = "down"
            browseScreenSelectRow(m.selectedRowIndex + 1)
            return true
        else if key = "right"
            if m.gridItems.Count() > 0
                m.focusArea = "grid"
                m.selectedGridIndex = 0
                browseScreenUpdateLeftListFocus()
                browseScreenUpdateGridFocus()
            end if
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    if m.focusArea = "filterBar"
        if key = "left"
            if m.selectedFilterIndex > 0
                m.selectedFilterIndex = m.selectedFilterIndex - 1
                browseScreenUpdateFilterBarFocus()
            end if
            return true
        else if key = "right"
            if m.selectedFilterIndex < m.filterButtonNodes.Count() - 1
                m.selectedFilterIndex = m.selectedFilterIndex + 1
                browseScreenUpdateFilterBarFocus()
            end if
            return true
        else if key = "up"
            m.focusArea = "nav"
            m.navEntryArea = "filterBar"
            browseScreenUpdateFilterBarFocus()
            m.pillNav.active = true
            m.pillNav.setFocus(true)
            return true
        else if key = "down"
            if m.gridItems.Count() > 0
                m.focusArea = "grid"
                m.selectedGridIndex = 0
                browseScreenUpdateFilterBarFocus()
                browseScreenUpdateGridFocus()
            end if
            return true
        else if key = "OK"
            browseScreenOpenFilterPicker()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    if m.focusArea = "grid"
        if key = "left"
            if m.selectedGridIndex MOD m.gridColumns = 0
                if m.mode = "shortcut"
                    m.focusArea = "leftList"
                    browseScreenUpdateLeftListFocus()
                    browseScreenUpdateGridFocus()
                else if m.mode = "filterbar"
                    m.focusArea = "filterBar"
                    browseScreenUpdateGridFocus()
                    browseScreenUpdateFilterBarFocus()
                end if
            else
                browseScreenMoveGridFocus(-1)
            end if
            return true
        else if key = "right"
            browseScreenMoveGridFocus(1)
            return true
        else if key = "down"
            browseScreenMoveGridFocus(m.gridColumns)
            return true
        else if key = "up"
            if m.selectedGridIndex < m.gridColumns
                if m.mode = "filterbar"
                    m.focusArea = "filterBar"
                    browseScreenUpdateGridFocus()
                    browseScreenUpdateFilterBarFocus()
                else
                    m.focusArea = "nav"
                    m.navEntryArea = "grid"
                    browseScreenUpdateGridFocus()
                    m.pillNav.active = true
                    m.pillNav.setFocus(true)
                end if
            else
                browseScreenMoveGridFocus(-m.gridColumns)
            end if
            return true
        else if key = "OK"
            browseScreenSelectGridItem()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    return false
end function

sub browseScreenMoveGridFocus(delta as Integer)
    if m.gridItems.Count() = 0 then return
    nextIndex = m.selectedGridIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.gridItems.Count() then nextIndex = m.gridItems.Count() - 1
    m.selectedGridIndex = nextIndex
    browseScreenUpdateGridFocus()
end sub

sub browseScreenSelectGridItem()
    if m.gridItems.Count() = 0 then return
    selectedItem = m.gridItems[m.selectedGridIndex]
    if selectedItem.itemId = invalid or selectedItem.itemId <= 0 then return

    selection = { itemId: selectedItem.itemId, source: "browse" }
    if selectedItem.DoesExist("mediaId") then selection.mediaId = selectedItem.mediaId
    m.top.videoSelected = selection
end sub
