' Search screen — merged search bar (box + Тип/Поле/Сорт. chips), an
' on-screen RU/EN/symbols keyboard, recent searches, and a paginated results
' grid. Singleton pattern like LiveScreen.brs (no per-instance configure()
' params needed). Ported from HomeScreen.brs's legacy Search section:
' keyboard row layouts/geometry/navigation are kept verbatim (see
' searchScreenKeyboardRows/searchScreenRenderKeyboard/
' searchScreenMoveKeyboardVertical), restyled to the light theme; the results
' grid instead reuses BrowseScreen.brs's newer append-pagination pattern
' (legacy's own grid code was already superseded when Browse was ported off
' it). All top-level helpers are prefixed searchScreen* — see
' BrowseScreen.brs's header comment for why (every sub/function in this
' channel is global regardless of which component's <script> tags loaded it;
' init()/onKeyEvent()/observeField-callback names are the exception).

sub init()
    m.pillNav = m.top.findNode("pillNav")
    m.searchMessageLabel = m.top.findNode("searchMessageLabel")
    m.keyboardHost = m.top.findNode("keyboardHost")
    m.keyboardKeysHost = m.top.findNode("keyboardKeysHost")
    m.recentSearchesHost = m.top.findNode("recentSearchesHost")
    m.gridHost = m.top.findNode("gridHost")
    m.gridContent = m.top.findNode("gridContent")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.noResultsGroup = m.top.findNode("noResultsGroup")
    m.noResultsLabel = m.top.findNode("noResultsLabel")
    m.errorGroup = m.top.findNode("errorGroup")
    m.exitDialog = m.top.findNode("exitDialog")
    m.exitDialog.observeField("dialogResult", "onExitDialogResult")
    m.filterPickerDialog = m.top.findNode("filterPickerDialog")
    m.filterPickerDialog.observeField("dialogResult", "onFilterPickerResult")

    ' Bar: search box + Тип/Поле/Сорт. chips, findNode'd once in a fixed
    ' order matching the XML (index 0 = box).
    m.barButtonNodes = [
        { id: "box", bg: m.top.findNode("searchBoxBg"), label: m.top.findNode("searchBoxLabel") }
        { id: "type", bg: m.top.findNode("filterTypeBg"), label: m.top.findNode("filterTypeLabel") }
        { id: "field", bg: m.top.findNode("filterFieldBg"), label: m.top.findNode("filterFieldLabel") }
        { id: "sort", bg: m.top.findNode("filterSortBg"), label: m.top.findNode("filterSortLabel") }
    ]
    m.selectedBarIndex = 0
    m.activeFilterId = ""
    m.filterOptions = { typeMap: {} }

    m.searchQuery = ""
    m.searchSubmittedQuery = ""
    m.searchSortByYear = true
    m.searchContentType = ""
    m.searchField = "title"

    ' On-screen keyboard state.
    m.searchKeyboardLayout = "ru"
    m.searchKeyboardPreviousTextLayout = "ru"
    m.searchKeyboardIndex = 0
    m.searchKeyboardKeys = []

    ' Recent searches — unmodified SearchHistoryStore service, registry-
    ' backed, max 10 entries, MRU de-dupe.
    m.searchHistoryStore = SearchHistoryStore()
    m.recentSearches = m.searchHistoryStore.load()
    m.recentRowNodes = []
    m.selectedRecentIndex = 0

    ' Results grid — same shape/roles as BrowseScreen.brs's grid subsystem.
    m.gridColumns = 6
    m.gridCardWidth = 170
    m.gridCardGapX = 22
    m.gridCardGapY = 26
    m.gridRowStep = 0
    m.gridContentOffsetY = 0
    m.gridViewportHeight = 544
    m.gridScrollAnimation = invalid
    m.gridScrollInterpolator = invalid
    ' Same clip-padding trick as Library's filterbar mode (BrowseScreen.brs's
    ' configure()) — the 46px gap between the bar (bottom edge 114) and the
    ' grid's top (160) matters because clippingRect isn't reliably enforced
    ' on every runtime this ships to, so the focus-pop clip padding below
    ' routinely renders unclipped.
    m.gridPad = 44
    gridBaseX = 30
    gridBaseY = 160
    contentWidth = (m.gridCardWidth * m.gridColumns) + (m.gridCardGapX * (m.gridColumns - 1))
    m.gridHost.translation = [gridBaseX - m.gridPad, gridBaseY - m.gridPad]
    m.gridHost.clippingRect = [0, 0, contentWidth + (m.gridPad * 2), m.gridViewportHeight + (m.gridPad * 2)]
    m.gridContent.translation = [m.gridPad, m.gridPad]

    m.gridItems = []
    m.gridCardNodes = []
    m.selectedGridIndex = 0
    m.gridPage = 0
    m.gridPagination = invalid
    m.gridPendingIsAppend = false
    m.gridLoadingMore = false
    m.gridReachedEnd = false
    m.gridItemCap = 300
    m.pendingFocusGrid = false

    m.pillNav.tabs = [
        { id: "search", label: "Поиск" }
        { id: "movies", label: "Фильмы" }
        { id: "series", label: "Сериалы" }
        { id: "continue", label: "Мои" }
        { id: "library", label: "Библиотека" }
        { id: "tv", label: "ТВ" }
        { id: "settings", label: "", icon: "pkg:/images/ui/icon-settings.png" }
    ]
    m.pillNav.selectedTabId = "search"
    m.pillNav.active = false
    m.pillNav.observeField("tabActivated", "onNavTabActivated")
    m.pillNav.observeField("focusExitDown", "onNavFocusExitDown")

    m.focusArea = "bar"

    searchScreenRenderBar()
    searchScreenRenderRecent()
    searchScreenShowState(searchScreenIdleStateName())
    searchScreenLoadOptions()

    m.top.setFocus(true)
end sub

' ---------------------------------------------------------------------------
' Bar (search box + Тип/Поле/Сорт.)
' ---------------------------------------------------------------------------

sub searchScreenRenderBar()
    theme = UiThemeLight()
    if m.searchQuery <> ""
        m.barButtonNodes[0].label.text = m.searchQuery
        m.barButtonNodes[0].label.color = theme.text
    else
        m.barButtonNodes[0].label.text = "Поиск..."
        m.barButtonNodes[0].label.color = theme.muted
    end if

    m.barButtonNodes[1].label.text = "Тип: " + searchScreenTitleForValue(searchScreenTypeOptions(), m.searchContentType)
    m.barButtonNodes[2].label.text = "Поле: " + searchScreenTitleForValue(searchScreenFieldOptions(), m.searchField)

    sortValue = "newest"
    if m.searchSortByYear <> true then sortValue = "relevance"
    m.barButtonNodes[3].label.text = "Сорт.: " + searchScreenTitleForValue(searchScreenSortOptions(), sortValue)
end sub

function searchScreenTitleForValue(items as Object, value as String) as String
    for each item in items
        if item.id = value then return item.title
    end for
    if items.Count() > 0 then return items[0].title
    return ""
end function

function searchScreenTypeOptions() as Object
    items = [{ id: "", title: "Все" }]
    for each typeId in m.filterOptions.typeMap
        entry = m.filterOptions.typeMap[typeId]
        title = typeId
        if entry <> invalid and entry.DoesExist("title") and entry.title <> "" then title = entry.title
        items.Push({ id: typeId, title: title })
    end for
    return items
end function

function searchScreenFieldOptions() as Object
    return [
        { id: "title", title: "Название" }
        { id: "director", title: "Режиссёр" }
        { id: "cast", title: "Актёры" }
    ]
end function

function searchScreenSortOptions() as Object
    return [
        { id: "newest", title: "Новые" }
        { id: "relevance", title: "Релевантность" }
    ]
end function

sub searchScreenUpdateBarFocus()
    theme = UiThemeLight()
    for i = 0 to m.barButtonNodes.Count() - 1
        node = m.barButtonNodes[i]
        isFocused = (i = m.selectedBarIndex) and (m.focusArea = "bar")
        if isFocused
            node.bg.color = theme.surfaceFocus
        else
            node.bg.color = theme.surfaceAlt
        end if
    end for
end sub

sub searchScreenLoadOptions()
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadSearchOptions"
    task.request = {}
    task.observeField("response", "onSearchOptionsResponse")
    task.control = "RUN"
    m.searchOptionsTask = task
end sub

sub onSearchOptionsResponse(event as Object)
    response = event.getData()
    if searchScreenHandleAuthRequired(response) then return
    if response = invalid or response.ok <> true then return
    if response.typeMap <> invalid then m.filterOptions.typeMap = response.typeMap
    searchScreenRenderBar()
end sub

function searchScreenHandleAuthRequired(response as Dynamic) as Boolean
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

' Opens the picker WITHOUT transferring real SceneGraph focus to it — see
' ListPickerDialog.brs's header comment for why (giving the dialog real focus
' turned out not to reliably hand it back). onKeyEvent checks
' m.filterPickerDialog.visible at the top and routes Up/Down/OK to it via
' callFunc while it's open.
sub searchScreenOpenFilterPicker(filterId as String)
    m.activeFilterId = filterId
    items = searchScreenOptionsForFilterId(filterId)
    selectedId = searchScreenValueForFilterId(filterId)
    title = "Выберите тип"
    if filterId = "field" then title = "Выберите поле"
    m.filterPickerDialog.callFunc("configure", title, items, selectedId)
    m.filterPickerDialog.visible = true
end sub

function searchScreenOptionsForFilterId(filterId as String) as Object
    if filterId = "type" then return searchScreenTypeOptions()
    if filterId = "field" then return searchScreenFieldOptions()
    return []
end function

function searchScreenValueForFilterId(filterId as String) as String
    if filterId = "type" then return m.searchContentType
    if filterId = "field" then return m.searchField
    return ""
end function

sub onFilterPickerResult(event as Object)
    result = event.getData()
    m.filterPickerDialog.visible = false
    if result <> invalid and result.action = "confirm"
        if m.activeFilterId = "type" then m.searchContentType = result.id
        if m.activeFilterId = "field" then m.searchField = result.id
        searchScreenRenderBar()
        searchScreenRefreshIfSubmitted()
    end if
    m.activeFilterId = ""
    searchScreenUpdateBarFocus()
end sub

sub searchScreenToggleSort()
    m.searchSortByYear = m.searchSortByYear <> true
    searchScreenRenderBar()
    searchScreenRefreshIfSubmitted()
end sub

' No-op if nothing has been submitted yet — contentTaskSearchItems rejects an
' empty q server-task-side (ContentTask.brs's contentTaskSearchItems), so
' firing a reload here before any query exists would just misfire.
sub searchScreenRefreshIfSubmitted()
    if m.searchSubmittedQuery.Trim() = "" then return
    m.selectedGridIndex = 0
    m.gridPage = 0
    m.gridPagination = invalid
    m.gridReachedEnd = false
    m.pendingFocusGrid = true
    searchScreenShowState("loading")
    searchScreenLoadResultsPage(1, false)
end sub

' ---------------------------------------------------------------------------
' On-screen keyboard — ported verbatim from HomeScreen.brs's Search section
' (searchKeyboardRows/renderSearchKeyboard/activateSearchKeyboardKey/
' moveSearchKeyboard/moveSearchKeyboardVertical), restyled to the light theme.
' The separate translucent cursor-overlay rectangle legacy used is dropped —
' it only existed to add a second highlight layer against the old dark
' theme; one surfaceFocus fill per focused key matches every other focus
' indicator already in this app.
' ---------------------------------------------------------------------------

function searchScreenKeyboardRows() as Object
    if m.searchKeyboardLayout = "en"
        return [
            ["a", "b", "c", "d", "e", "f"]
            ["g", "h", "i", "j", "k", "l"]
            ["m", "n", "o", "p", "q", "r"]
            ["s", "t", "u", "v", "w", "x"]
            ["y", "z"]
            ["RU", "123", "Space", "Backspace", "Clear", "Search"]
        ]
    else if m.searchKeyboardLayout = "symbols"
        return [
            ["1", "2", "3", "4", "5", "6"]
            ["7", "8", "9", "0", "?", "!"]
            [",", ".", ":", "-", "'", Chr(34)]
            ["/", "@", "#", "&", "(", ")"]
            ["+", "=", "_"]
            ["ABC", "Space", "Backspace", "Clear", "Search"]
        ]
    end if

    return [
        ["а", "б", "в", "г", "д", "е"]
        ["ё", "ж", "з", "и", "й", "к"]
        ["л", "м", "н", "о", "п", "р"]
        ["с", "т", "у", "ф", "х", "ц"]
        ["ч", "ш", "щ", "ъ", "ы", "ь"]
        ["э", "ю", "я"]
        ["EN", "123", "Space", "Backspace", "Clear", "Search"]
    ]
end function

function searchScreenKeyboardActionForLabel(label as String) as Object
    if label = "RU" then return { type: "layout", value: "ru", label: "RU" }
    if label = "EN" then return { type: "layout", value: "en", label: "EN" }
    if label = "123" then return { type: "layout", value: "symbols", label: "123" }
    if label = "ABC" then return { type: "layout", value: "alpha", label: "ABC" }
    if label = "Space" then return { type: "space", value: " ", label: "Space" }
    if label = "Backspace" then return { type: "backspace", value: "", label: "Backspace" }
    if label = "Clear" then return { type: "clear", value: "", label: "Clear" }
    if label = "Search" then return { type: "search", value: "", label: "Search" }
    return { type: "char", value: label, label: label }
end function

sub searchScreenRenderKeyboard()
    childCount = m.keyboardKeysHost.getChildCount()
    if childCount > 0 then m.keyboardKeysHost.removeChildrenIndex(childCount, 0)

    m.searchKeyboardKeys = []
    theme = UiThemeLight()
    rows = searchScreenKeyboardRows()

    for rowIndex = 0 to rows.Count() - 1
        row = rows[rowIndex]
        actionX = 0

        for columnIndex = 0 to row.Count() - 1
            labelText = row[columnIndex]
            key = searchScreenKeyboardActionForLabel(labelText)
            keyWidth = 52
            keyHeight = 42
            keyGap = 10
            actionGap = 10
            if key.type = "space" then keyWidth = 118
            if key.type = "backspace" then keyWidth = 132
            if key.type = "clear" then keyWidth = 92
            if key.type = "search" then keyWidth = 112

            x = columnIndex * (52 + keyGap)
            if rowIndex = rows.Count() - 1
                x = actionX
                actionX = actionX + keyWidth + actionGap
            end if
            y = rowIndex * 50

            group = CreateObject("roSGNode", "Group")
            group.translation = [x, y]

            bg = CreateObject("roSGNode", "Rectangle")
            bg.width = keyWidth
            bg.height = keyHeight
            bg.color = theme.surfaceAlt
            group.appendChild(bg)

            label = CreateObject("roSGNode", "Label")
            label.text = key.label
            label.width = keyWidth
            label.height = keyHeight
            label.horizAlign = "center"
            label.vertAlign = "center"
            label.color = theme.text
            label.font.size = 18
            group.appendChild(label)

            m.keyboardKeysHost.appendChild(group)
            key.x = x
            key.y = y
            key.width = keyWidth
            key.row = rowIndex
            key.column = columnIndex
            key.bg = bg
            m.searchKeyboardKeys.Push(key)
        end for
    end for

    if m.searchKeyboardIndex >= m.searchKeyboardKeys.Count() then m.searchKeyboardIndex = m.searchKeyboardKeys.Count() - 1
    if m.searchKeyboardIndex < 0 then m.searchKeyboardIndex = 0
    searchScreenUpdateKeyboardFocus()
end sub

sub searchScreenUpdateKeyboardFocus()
    theme = UiThemeLight()
    for index = 0 to m.searchKeyboardKeys.Count() - 1
        key = m.searchKeyboardKeys[index]
        if key.bg <> invalid
            if index = m.searchKeyboardIndex
                key.bg.color = theme.surfaceFocus
            else
                key.bg.color = theme.surfaceAlt
            end if
        end if
    end for
end sub

sub searchScreenMoveKeyboard(delta as Integer)
    if m.searchKeyboardKeys.Count() = 0 then return
    nextIndex = m.searchKeyboardIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.searchKeyboardKeys.Count() then nextIndex = m.searchKeyboardKeys.Count() - 1
    m.searchKeyboardIndex = nextIndex
    searchScreenUpdateKeyboardFocus()
end sub

sub searchScreenMoveKeyboardVertical(direction as Integer)
    if m.searchKeyboardKeys.Count() = 0 then return
    current = m.searchKeyboardKeys[m.searchKeyboardIndex]
    targetRow = current.row + direction
    bestIndex = m.searchKeyboardIndex
    bestDistance = 9999

    for index = 0 to m.searchKeyboardKeys.Count() - 1
        candidate = m.searchKeyboardKeys[index]
        if candidate.row = targetRow
            distance = Abs(candidate.column - current.column)
            if distance < bestDistance
                bestDistance = distance
                bestIndex = index
            end if
        end if
    end for

    m.searchKeyboardIndex = bestIndex
    searchScreenUpdateKeyboardFocus()
end sub

sub searchScreenActivateKeyboardKey()
    if m.searchKeyboardKeys.Count() = 0 then return
    key = m.searchKeyboardKeys[m.searchKeyboardIndex]

    if key.type = "char"
        m.searchQuery = m.searchQuery + key.value
    else if key.type = "space"
        m.searchQuery = m.searchQuery + " "
    else if key.type = "backspace"
        if Len(m.searchQuery) > 0 then m.searchQuery = Left(m.searchQuery, Len(m.searchQuery) - 1)
    else if key.type = "clear"
        m.searchQuery = ""
    else if key.type = "layout"
        if key.value = "symbols"
            if m.searchKeyboardLayout <> "symbols" then m.searchKeyboardPreviousTextLayout = m.searchKeyboardLayout
            m.searchKeyboardLayout = "symbols"
        else if key.value = "alpha"
            if m.searchKeyboardPreviousTextLayout <> "en" and m.searchKeyboardPreviousTextLayout <> "ru"
                m.searchKeyboardPreviousTextLayout = "ru"
            end if
            m.searchKeyboardLayout = m.searchKeyboardPreviousTextLayout
        else
            m.searchKeyboardLayout = key.value
            m.searchKeyboardPreviousTextLayout = key.value
        end if
        m.searchKeyboardIndex = 0
        searchScreenRenderKeyboard()
    else if key.type = "search"
        searchScreenSubmitSearch()
        return
    end if

    searchScreenRenderBar()
end sub

sub searchScreenOpenKeyboard()
    m.focusArea = "keyboard"
    m.searchMessageLabel.text = ""
    searchScreenRenderKeyboard()
    searchScreenShowState("keyboard")
end sub

sub searchScreenCloseKeyboard()
    m.focusArea = "bar"
    m.selectedBarIndex = 0
    searchScreenUpdateBarFocus()
    if m.gridItems.Count() > 0
        searchScreenShowState("grid")
    else
        searchScreenShowState(searchScreenIdleStateName())
    end if
end sub

' ---------------------------------------------------------------------------
' Recent searches
' ---------------------------------------------------------------------------

sub searchScreenRenderRecent()
    childCount = m.recentSearchesHost.getChildCount()
    if childCount > 0 then m.recentSearchesHost.removeChildrenIndex(childCount, 0)
    m.recentRowNodes = []

    theme = UiThemeLight()
    rowHeight = 44
    rowWidth = 420
    rowStep = rowHeight + 8

    for i = 0 to m.recentSearches.Count() - 1
        query = m.recentSearches[i]

        rowGroup = CreateObject("roSGNode", "Group")
        rowGroup.translation = [0, i * rowStep]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = rowWidth
        bg.height = rowHeight
        bg.color = theme.surfaceAlt
        rowGroup.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.text = query
        label.translation = [16, 12]
        label.width = rowWidth - 32
        label.height = 20
        label.color = theme.text
        rowGroup.appendChild(label)

        m.recentSearchesHost.appendChild(rowGroup)
        m.recentRowNodes.Push({ group: rowGroup, bg: bg })
    end for

    if m.selectedRecentIndex >= m.recentRowNodes.Count() then m.selectedRecentIndex = 0
    searchScreenUpdateRecentFocus()
end sub

sub searchScreenUpdateRecentFocus()
    theme = UiThemeLight()
    for i = 0 to m.recentRowNodes.Count() - 1
        node = m.recentRowNodes[i]
        isFocused = (i = m.selectedRecentIndex) and (m.focusArea = "recent")
        if isFocused
            node.bg.color = theme.surfaceFocus
        else
            node.bg.color = theme.surfaceAlt
        end if
    end for
end sub

sub searchScreenMoveRecentFocus(delta as Integer)
    if m.recentRowNodes.Count() = 0 then return
    nextIndex = m.selectedRecentIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.recentRowNodes.Count() then nextIndex = m.recentRowNodes.Count() - 1
    m.selectedRecentIndex = nextIndex
    searchScreenUpdateRecentFocus()
end sub

sub searchScreenSelectRecent()
    if m.recentSearches.Count() = 0 then return
    query = m.recentSearches[m.selectedRecentIndex]
    m.searchQuery = query
    searchScreenRenderBar()
    searchScreenSubmitSearch()
end sub

' ---------------------------------------------------------------------------
' Results grid — copy-adapted from BrowseScreen.brs's grid subsystem
' (append-based pagination, stale-response guard, strict zero-buffer
' visibility windowing, smooth-scroll animation, gridItemCap safety cap).
' ---------------------------------------------------------------------------

sub searchScreenLoadResultsPage(page as Integer, isAppend as Boolean)
    m.gridPendingIsAppend = isAppend
    m.gridLoadingMore = true

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "searchItems"
    task.request = { q: m.searchSubmittedQuery, page: page, perpage: 20, sortByYear: m.searchSortByYear, contentType: m.searchContentType, searchField: m.searchField }
    task.observeField("response", "onSearchResultsResponse")
    task.control = "RUN"
    m.searchResultsTask = task
end sub

sub onSearchResultsResponse(event as Object)
    response = event.getData()
    isAppend = m.gridPendingIsAppend
    m.gridLoadingMore = false

    if searchScreenHandleAuthRequired(response) then return

    ' Discard a response for a query/filters the user has since changed —
    ' fields are echoed back by contentTaskSearchItems.
    if response <> invalid
        if response.DoesExist("q") and response.q <> m.searchSubmittedQuery then return
        if response.DoesExist("sortByYear") and response.sortByYear <> m.searchSortByYear then return
        if response.DoesExist("contentType") and response.contentType <> m.searchContentType then return
        if response.DoesExist("searchField") and response.searchField <> m.searchField then return
    end if

    if response = invalid or response.ok <> true or response.items = invalid
        if isAppend
            m.gridReachedEnd = true
        else
            m.pendingFocusGrid = false
            searchScreenShowState("error")
        end if
        return
    end if

    m.gridPagination = response.pagination
    m.gridPage = response.page

    if isAppend
        startIndex = m.gridItems.Count()
        m.gridItems.Append(response.items)
        if m.gridPagination <> invalid and m.gridPagination.total_items <= m.gridItems.Count() then m.gridReachedEnd = true
        searchScreenAppendGridItems(startIndex, response.items)
        searchScreenUpdateGridVisibility()
    else
        m.gridItems = response.items
        if m.gridPagination <> invalid and m.gridPagination.total_items <= m.gridItems.Count() then m.gridReachedEnd = true

        if m.gridItems.Count() = 0
            m.pendingFocusGrid = false
            m.noResultsLabel.text = "Нет результатов по запросу «" + m.searchSubmittedQuery + "»"
            m.focusArea = "bar"
            m.selectedBarIndex = 0
            searchScreenUpdateBarFocus()
            searchScreenShowState("emptyResults")
            return
        end if

        if m.pendingFocusGrid
            m.pendingFocusGrid = false
            m.focusArea = "grid"
            m.selectedGridIndex = 0
            searchScreenUpdateBarFocus()
        end if
        searchScreenResetGrid()
        searchScreenShowState("grid")
    end if
end sub

sub searchScreenResetGrid()
    childCount = m.gridContent.getChildCount()
    if childCount > 0 then m.gridContent.removeChildrenIndex(childCount, 0)
    m.gridCardNodes = []
    m.gridContentOffsetY = 0
    m.gridContent.translation = [m.gridPad, m.gridPad]

    if m.gridItems.Count() = 0
        m.gridRowStep = 0
        return
    end if

    m.gridRowStep = posterCompactLayout(0, 0, m.gridCardWidth).cardHeight + m.gridCardGapY
    searchScreenAppendGridItems(0, m.gridItems)
    searchScreenUpdateGridVisibility()
    searchScreenUpdateGridFocus()
end sub

sub searchScreenAppendGridItems(startIndex as Integer, newItems as Object)
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

' Same strict zero-buffer visibility windowing as BrowseScreen.brs — not
' relying on clippingRect being enforced on every runtime this ships to.
sub searchScreenUpdateGridVisibility()
    if m.gridRowStep = 0 then return
    firstVisibleRow = Int(m.gridContentOffsetY / m.gridRowStep)
    lastVisibleRow = Int((m.gridContentOffsetY + m.gridViewportHeight - 1) / m.gridRowStep)
    for each cardNode in m.gridCardNodes
        cardNode.node.visible = (cardNode.row >= firstVisibleRow) and (cardNode.row <= lastVisibleRow)
    end for
end sub

sub searchScreenUpdateGridFocus()
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
    searchScreenScrollGridToFocus()
    searchScreenMaybeLoadNextPage()
end sub

sub searchScreenScrollGridToFocus()
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
        searchScreenAnimateGridScroll(currentOffset, newOffset)
        m.gridContentOffsetY = newOffset
        searchScreenUpdateGridVisibility()
    end if
end sub

sub searchScreenAnimateGridScroll(fromY as Integer, toY as Integer)
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
' currently loaded. Guarded by a flat item cap (m.gridItemCap, init()).
sub searchScreenMaybeLoadNextPage()
    if m.gridLoadingMore or m.gridReachedEnd then return
    if m.gridItems.Count() = 0 or m.gridItems.Count() >= m.gridItemCap then return
    if m.gridRowStep = 0 then return

    totalRows = Int((m.gridItems.Count() - 1) / m.gridColumns) + 1
    focusedRow = Int(m.selectedGridIndex / m.gridColumns)
    if focusedRow >= totalRows - 2
        searchScreenLoadResultsPage(m.gridPage + 1, true)
    end if
end sub

sub searchScreenMoveGridFocus(delta as Integer)
    if m.gridItems.Count() = 0 then return
    nextIndex = m.selectedGridIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.gridItems.Count() then nextIndex = m.gridItems.Count() - 1
    m.selectedGridIndex = nextIndex
    searchScreenUpdateGridFocus()
end sub

sub searchScreenSelectGridItem()
    if m.gridItems.Count() = 0 then return
    selectedItem = m.gridItems[m.selectedGridIndex]
    if selectedItem.itemId = invalid or selectedItem.itemId <= 0 then return

    selection = { itemId: selectedItem.itemId, source: "search" }
    if selectedItem.DoesExist("mediaId") then selection.mediaId = selectedItem.mediaId
    m.top.videoSelected = selection
end sub

' ---------------------------------------------------------------------------
' Submit / state
' ---------------------------------------------------------------------------

sub searchScreenSubmitSearch()
    query = m.searchQuery.Trim()
    if query = ""
        m.searchMessageLabel.text = "Введите запрос для поиска."
        return
    end if

    m.searchMessageLabel.text = ""
    m.searchSubmittedQuery = query
    m.searchHistoryStore.saveQuery(query)
    m.recentSearches = m.searchHistoryStore.load()
    m.selectedRecentIndex = 0
    searchScreenRenderRecent()

    m.selectedGridIndex = 0
    m.gridPage = 0
    m.gridPagination = invalid
    m.gridReachedEnd = false
    m.gridItems = []
    ' Jump focus straight to the first tile once the page lands — consumed
    ' in onSearchResultsResponse, same idiom as Library's filter-picker
    ' confirm (BrowseScreen.brs's onFilterPickerResult).
    m.pendingFocusGrid = true

    m.focusArea = "bar"
    m.selectedBarIndex = 0
    searchScreenUpdateBarFocus()

    searchScreenShowState("loading")
    searchScreenLoadResultsPage(1, false)
end sub

sub searchScreenShowState(state as String)
    m.keyboardHost.visible = state = "keyboard"
    m.recentSearchesHost.visible = state = "recent"
    m.top.findNode("emptyPlaceholderGroup").visible = state = "empty"
    m.gridHost.visible = state = "grid"
    m.loadingGroup.visible = state = "loading"
    m.noResultsGroup.visible = state = "emptyResults"
    m.errorGroup.visible = state = "error"
end sub

function searchScreenIdleStateName() as String
    if m.searchQuery.Trim() = "" and m.recentSearches.Count() > 0 then return "recent"
    return "empty"
end function

sub searchScreenRetryLoad()
    searchScreenShowState("loading")
    searchScreenLoadResultsPage(1, false)
end sub

' ---------------------------------------------------------------------------
' Nav / focus routing
' ---------------------------------------------------------------------------

sub onNavTabActivated(event as Object)
    tabId = event.getData()
    if tabId = "search" then return
    ' Navigating away — reset nav focus state now so keys still work when
    ' this screen is shown again later (see BrowseScreen.brs's identical
    ' comment on this exact bug).
    onNavFocusExitDown()
    if tabId = "continue"
        m.top.openContinueScreen = true
        return
    end if
    if tabId = "settings"
        m.top.openDevFonts = true
        return
    end if
    if tabId = "movies" or tabId = "series" or tabId = "library" or tabId = "tv"
        m.top.openTabScreen = tabId
        return
    end if
    m.top.openLegacyHomeSection = "home"
end sub

' The bar always sits between the grid/recent list and the nav — Up from
' either of those lands on the bar, never straight on nav (same "always
' bottlenecks through the secondary control row" shape as Library's
' filterbar mode) — so re-entering from nav always lands on the bar too.
sub onNavFocusExitDown()
    m.pillNav.active = false
    m.top.setFocus(true)
    m.focusArea = "bar"
    searchScreenUpdateBarFocus()
end sub

' Public: called by AppScene via callFunc right after showing this screen as
' a result of activating its pill-nav tab. Lands on the first result tile if
' a prior search this session already populated the grid; otherwise lands on
' the search box — the one universal, always-actionable control. No
' pendingFocusGrid-style async race to guard here unlike BrowseScreen.brs:
' this screen never auto-loads anything on construction, so the grid only
' ever populates in response to an explicit user submit.
sub focusContent()
    if m.gridItems.Count() > 0
        m.focusArea = "grid"
        m.selectedGridIndex = 0
        searchScreenUpdateBarFocus()
        searchScreenUpdateGridFocus()
    else
        m.focusArea = "bar"
        m.selectedBarIndex = 0
        searchScreenUpdateBarFocus()
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
            searchScreenRetryLoad()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    if m.focusArea = "keyboard"
        if key = "left"
            searchScreenMoveKeyboard(-1)
            return true
        else if key = "right"
            searchScreenMoveKeyboard(1)
            return true
        else if key = "up"
            searchScreenMoveKeyboardVertical(-1)
            return true
        else if key = "down"
            searchScreenMoveKeyboardVertical(1)
            return true
        else if key = "OK"
            searchScreenActivateKeyboardKey()
            return true
        else if key = "back"
            searchScreenCloseKeyboard()
            return true
        end if
        return false
    end if

    if m.focusArea = "bar"
        if key = "left"
            if m.selectedBarIndex > 0
                m.selectedBarIndex = m.selectedBarIndex - 1
                searchScreenUpdateBarFocus()
            end if
            return true
        else if key = "right"
            if m.selectedBarIndex < m.barButtonNodes.Count() - 1
                m.selectedBarIndex = m.selectedBarIndex + 1
                searchScreenUpdateBarFocus()
            end if
            return true
        else if key = "up"
            m.focusArea = "nav"
            searchScreenUpdateBarFocus()
            m.pillNav.active = true
            m.pillNav.setFocus(true)
            return true
        else if key = "down"
            if m.gridItems.Count() > 0
                m.focusArea = "grid"
                m.selectedGridIndex = 0
                searchScreenUpdateBarFocus()
                searchScreenUpdateGridFocus()
            else if m.recentSearchesHost.visible
                m.focusArea = "recent"
                searchScreenUpdateBarFocus()
                searchScreenUpdateRecentFocus()
            end if
            return true
        else if key = "OK"
            barId = m.barButtonNodes[m.selectedBarIndex].id
            if barId = "box"
                searchScreenOpenKeyboard()
            else if barId = "type" or barId = "field"
                searchScreenOpenFilterPicker(barId)
            else if barId = "sort"
                searchScreenToggleSort()
            end if
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    if m.focusArea = "recent"
        if key = "up"
            if m.selectedRecentIndex = 0
                m.focusArea = "bar"
                searchScreenUpdateRecentFocus()
                searchScreenUpdateBarFocus()
            else
                searchScreenMoveRecentFocus(-1)
            end if
            return true
        else if key = "down"
            searchScreenMoveRecentFocus(1)
            return true
        else if key = "OK"
            searchScreenSelectRecent()
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
                m.focusArea = "bar"
                searchScreenUpdateGridFocus()
                searchScreenUpdateBarFocus()
            else
                searchScreenMoveGridFocus(-1)
            end if
            return true
        else if key = "right"
            searchScreenMoveGridFocus(1)
            return true
        else if key = "down"
            searchScreenMoveGridFocus(m.gridColumns)
            return true
        else if key = "up"
            if m.selectedGridIndex < m.gridColumns
                m.focusArea = "bar"
                searchScreenUpdateGridFocus()
                searchScreenUpdateBarFocus()
            else
                searchScreenMoveGridFocus(-m.gridColumns)
            end if
            return true
        else if key = "OK"
            searchScreenSelectGridItem()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    return false
end function
