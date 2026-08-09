sub init()
    m.pillNav = m.top.findNode("pillNav")
    m.leftListHost = m.top.findNode("leftListHost")
    m.gridHost = m.top.findNode("gridHost")
    m.gridContent = m.top.findNode("gridContent")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    m.errorLabel = m.top.findNode("errorLabel")
    m.errorRetryFocus = m.top.findNode("errorRetryFocus")
    m.exitDialog = m.top.findNode("exitDialog")
    m.exitDialog.observeField("dialogResult", "onExitDialogResult")

    m.gridColumns = 5
    m.gridCardWidth = 170
    m.gridCardGapX = 22
    m.gridCardGapY = 26
    m.gridViewportHeight = 596

    ' Scaled-up (focus "pop") tiles in the first row/column would otherwise
    ' get clipped flush against the viewport edge, since clippingRect starts
    ' at (0,0) with no slack — and the shadow is a CHILD of the card, so it
    ' scales up too, reaching further than its own base margin. Shift the
    ' whole viewport up-left by gridPad and grow the clip region by gridPad
    ' on every side, then shift gridContent back down-right by the same
    ' amount — cards land in the same on-screen spot as before, but now have
    ' room to scale into on all 4 edges without the shadow getting clipped.
    m.gridPad = 44
    gridBaseX = 300
    gridBaseY = 90
    contentWidth = (m.gridCardWidth * m.gridColumns) + (m.gridCardGapX * (m.gridColumns - 1))
    m.gridHost.translation = [gridBaseX - m.gridPad, gridBaseY - m.gridPad]
    m.gridHost.clippingRect = [0, 0, contentWidth + (m.gridPad * 2), m.gridViewportHeight + (m.gridPad * 2)]
    m.gridContent.translation = [m.gridPad, m.gridPad]
    ' Single fixed geometry for this screen's whole lifetime — see
    ' components/grid/VideoGrid.brs. Previously this screen rendered its
    ' whole (unpaginated, potentially large — History + New Episodes +
    ' every bookmark folder) item list as one card node per item with no
    ' cap at all; the pool bounds node/texture count to the visible
    ' viewport regardless of list length. showUnwatchedBadge is always true
    ' in the template (unlike the old per-row-selection flag) since a
    ' pooled card's node list can't change after creation — whether the
    ' badge actually renders is decided per item by updatePosterCard
    ' (item.unwatchedCount > 0), which is naturally false/absent for rows
    ' (Movies, bookmark folders) that never had one.
    m.gridPool = VideoGridPool({
        scriptRoot: m.top
        content: m.gridContent
        columns: m.gridColumns
        cardWidth: m.gridCardWidth
        cardGapX: m.gridCardGapX
        cardGapY: m.gridCardGapY
        viewportHeight: m.gridViewportHeight
        pad: m.gridPad
        layoutTemplate: { showUnwatchedBadge: true }
    })
    m.gridEmptyLabel = CreateObject("roSGNode", "Label")
    m.gridEmptyLabel.text = "No items"
    m.gridEmptyLabel.width = 700
    m.gridEmptyLabel.height = 40
    m.gridEmptyLabel.color = UiThemeLight().muted
    m.gridEmptyLabel.visible = false
    m.gridContent.appendChild(m.gridEmptyLabel)

    m.pillNav.tabs = [
        { id: "search", label: "Поиск" }
        { id: "movies", label: "Фильмы" }
        { id: "series", label: "Сериалы" }
        { id: "continue", label: "Мои" }
        { id: "library", label: "Библиотека" }
        { id: "tv", label: "ТВ" }
        { id: "settings", label: "", icon: "pkg:/images/ui/icon-settings.png" }
    ]
    m.pillNav.selectedTabId = "continue"
    m.pillNav.active = false
    m.pillNav.observeField("tabActivated", "onNavTabActivated")
    m.pillNav.observeField("focusExitDown", "onNavFocusExitDown")

    m.focusArea = "leftList"
    m.navEntryArea = "leftList"
    m.leftRows = []
    m.leftRowNodes = []
    m.selectedRowIndex = 0
    m.selectedGridIndex = 0
    m.gridItems = []
    m.pendingLoads = 0
    m.loadFailed = false
    m.pendingFocusGrid = false

    m.top.setFocus(true)
    continueScreenLoadAll()
end sub

' Fires a single token-refresh preflight before the real fan-out below —
' otherwise all 3 tasks below would independently discover an expired token
' and race to refresh it concurrently (TokenStore.brs has no cross-task
' locking; the losing refresh call fails against an already-rotated token and
' signs the user out). No-op HTTP-wise if the token is already valid.
sub continueScreenLoadAll()
    continueScreenShowState("loading")
    preflightTask = CreateObject("roSGNode", "ContentTask")
    preflightTask.command = "ensureFreshTokens"
    preflightTask.request = {}
    preflightTask.observeField("response", "onTokenPreflightResponse")
    preflightTask.control = "RUN"
    m.preflightTask = preflightTask
end sub

sub onTokenPreflightResponse(event as Object)
    continueScreenLoadAllContent()
end sub

sub continueScreenLoadAllContent()
    m.pendingLoads = 3
    m.loadFailed = false

    newEpisodesTask = CreateObject("roSGNode", "ContentTask")
    newEpisodesTask.command = "loadContinueNewEpisodesPage"
    newEpisodesTask.request = { page: 1, perpage: 50 }
    newEpisodesTask.observeField("response", "onNewEpisodesResponse")
    newEpisodesTask.control = "RUN"
    m.newEpisodesTask = newEpisodesTask

    historyTask = CreateObject("roSGNode", "ContentTask")
    historyTask.command = "loadContinueHistoryPage"
    historyTask.request = { page: 1, perpage: 50 }
    historyTask.observeField("response", "onHistoryResponse")
    historyTask.control = "RUN"
    m.historyTask = historyTask

    foldersTask = CreateObject("roSGNode", "ContentTask")
    foldersTask.command = "loadBookmarkFolders"
    foldersTask.request = {}
    foldersTask.observeField("response", "onFoldersResponse")
    foldersTask.control = "RUN"
    m.foldersTask = foldersTask
end sub

sub onNewEpisodesResponse(event as Object)
    response = event.getData()
    if continueScreenHandleAuthRequired(response) then return
    if response <> invalid and response.ok = true and response.items <> invalid
        m.newEpisodesItems = response.items
        total = response.items.Count()
        if response.pagination <> invalid and response.pagination.total_items > 0 then total = response.pagination.total_items
        m.newEpisodesCount = total
    else
        m.newEpisodesItems = []
        m.newEpisodesCount = 0
        m.loadFailed = true
    end if
    continueScreenLoadStepDone()
end sub

sub onHistoryResponse(event as Object)
    response = event.getData()
    if continueScreenHandleAuthRequired(response) then return
    if response <> invalid and response.ok = true and response.items <> invalid
        movies = []
        for each historyItem in response.items
            if historyItem.type = "movie" and historyItem.durationSeconds > 0 and historyItem.progressSeconds > 0 and historyItem.progressSeconds < historyItem.durationSeconds
                movies.Push(historyItem)
            end if
        end for
        m.moviesItems = movies
        m.moviesCount = movies.Count()
    else
        m.moviesItems = []
        m.moviesCount = 0
        m.loadFailed = true
    end if
    continueScreenLoadStepDone()
end sub

sub onFoldersResponse(event as Object)
    response = event.getData()
    if continueScreenHandleAuthRequired(response) then return
    if response <> invalid and response.ok = true and response.folders <> invalid
        m.bookmarkFolders = response.folders
    else
        m.bookmarkFolders = []
        m.loadFailed = true
    end if
    continueScreenLoadStepDone()
end sub

function continueScreenHandleAuthRequired(response as Dynamic) as Boolean
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

sub continueScreenLoadStepDone()
    m.pendingLoads = m.pendingLoads - 1
    if m.pendingLoads > 0 then return

    totalRows = m.newEpisodesCount + m.moviesCount + m.bookmarkFolders.Count()
    if m.loadFailed and totalRows = 0
        continueScreenShowState("error")
        return
    end if

    continueScreenBuildLeftRows()
    continueScreenRenderLeftList()
    continueScreenSelectRow(0)
    continueScreenShowState("content")

    if m.pendingFocusGrid
        m.pendingFocusGrid = false
        focusContent()
    end if
end sub

' Public: called by AppScene via callFunc whenever this screen is shown as a
' result of activating its pill-nav tab, so landing on "Мои" (or any other
' nav-activated screen) drops you straight into browsing tiles instead of
' the left list. On the very first-ever visit the grid hasn't loaded yet
' (continueScreenLoadAll is still in flight), so this defers itself via
' m.pendingFocusGrid, consumed once continueScreenLoadStepDone finishes
' populating row 0's items — the exact instant it becomes possible to focus
' a tile. On a repeat visit the grid already has items, so this applies
' immediately.
sub focusContent()
    if m.gridItems.Count() > 0
        m.focusArea = "grid"
        m.selectedGridIndex = 0
        continueScreenUpdateLeftListFocus()
        continueScreenUpdateGridFocus()
    else
        m.pendingFocusGrid = true
    end if
end sub

sub continueScreenBuildLeftRows()
    rows = []
    rows.Push({ kind: "newEpisodes", section: "unwatched", label: "Сериалы", count: m.newEpisodesCount, items: m.newEpisodesItems })
    rows.Push({ kind: "movies", section: "unwatched", label: "Фильмы", count: m.moviesCount, items: m.moviesItems })

    if m.bookmarkFolders <> invalid
        for each folder in m.bookmarkFolders
            rows.Push({ kind: "bookmarkFolder", section: "bookmarks", label: folder.title, count: folder.count, folderId: folder.folderId, items: invalid })
        end for
    end if

    m.leftRows = rows
end sub

sub continueScreenRenderLeftList()
    childCount = m.leftListHost.getChildCount()
    if childCount > 0 then m.leftListHost.removeChildrenIndex(childCount, 0)
    m.leftRowNodes = []

    theme = UiThemeLight()
    y = 0
    rowHeight = 34
    rowWidth = 220
    lastSection = ""

    for i = 0 to m.leftRows.Count() - 1
        row = m.leftRows[i]
        if row.section <> lastSection
            header = CreateObject("roSGNode", "Label")
            header.text = continueScreenLeftSectionHeaderText(row.section)
            header.translation = [4, y]
            header.width = rowWidth
            header.height = 22
            header.color = theme.muted
            header.font.size = 16
            m.leftListHost.appendChild(header)
            y = y + 26
            lastSection = row.section
        end if

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
        label.width = rowWidth - 50
        label.height = 22
        label.color = theme.text
        label.font.size = 18
        rowGroup.appendChild(label)

        countLabel = CreateObject("roSGNode", "Label")
        countLabel.text = StrI(row.count).Trim()
        countLabel.translation = [rowWidth - 40, 5]
        countLabel.width = 32
        countLabel.height = 22
        countLabel.horizAlign = "right"
        countLabel.color = theme.muted
        countLabel.font.size = 18
        rowGroup.appendChild(countLabel)

        m.leftListHost.appendChild(rowGroup)
        m.leftRowNodes.Push({ group: rowGroup, bg: bg, accentBar: accentBar })

        y = y + rowHeight + 4
    end for

    continueScreenUpdateLeftListFocus()
end sub

function continueScreenLeftSectionHeaderText(section as String) as String
    if section = "unwatched" then return "НЕДОСМОТРЕННЫЕ"
    if section = "bookmarks" then return "ЗАКЛАДКИ"
    return ""
end function

sub continueScreenUpdateLeftListFocus()
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
end sub

sub continueScreenSelectRow(index as Integer)
    if m.leftRows.Count() = 0 then return
    if index < 0 then index = 0
    if index >= m.leftRows.Count() then index = m.leftRows.Count() - 1
    m.selectedRowIndex = index
    continueScreenUpdateLeftListFocus()

    row = m.leftRows[index]
    if row.kind = "bookmarkFolder" and row.items = invalid
        continueScreenLoadBookmarkFolderItems(row)
        return
    end if

    m.selectedGridIndex = 0
    continueScreenSetGridItems(row.items)
end sub

sub continueScreenLoadBookmarkFolderItems(row as Object)
    continueScreenShowState("loading")
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadBookmarkFolderItems"
    task.request = { folderId: row.folderId, page: 1, perpage: 50 }
    task.observeField("response", "onBookmarkFolderItemsResponse")
    task.control = "RUN"
    m.bookmarkFolderTask = task
end sub

sub onBookmarkFolderItemsResponse(event as Object)
    response = event.getData()
    if continueScreenHandleAuthRequired(response) then return

    items = []
    folderId = 0
    if response <> invalid
        if response.items <> invalid and response.ok = true then items = response.items
        if response.DoesExist("folderId") then folderId = response.folderId
    end if

    for i = 0 to m.leftRows.Count() - 1
        row = m.leftRows[i]
        if row.kind = "bookmarkFolder" and row.folderId = folderId
            row.items = items
            m.leftRows[i] = row
            if i = m.selectedRowIndex
                m.selectedGridIndex = 0
                continueScreenSetGridItems(items)
            end if
            exit for
        end if
    end for

    continueScreenShowState("content")
end sub

sub continueScreenSetGridItems(items as Dynamic)
    if items = invalid then items = []
    m.gridItems = items
    continueScreenRenderGrid()
end sub

' Delegates to the shared virtual grid (components/grid/VideoGrid.brs) — see
' its header comment for why this no longer builds a card node per item
' (previously this rendered the whole item list at once, unbounded).
sub continueScreenRenderGrid()
    m.gridEmptyLabel.visible = (m.gridItems.Count() = 0)
    m.gridPool.setItems(m.gridItems)
    continueScreenUpdateGridFocus()
end sub

sub continueScreenUpdateGridFocus()
    m.gridPool.setFocus(m.selectedGridIndex, m.focusArea = "grid")
end sub

sub continueScreenShowState(state as String)
    m.loadingGroup.visible = state = "loading"
    m.errorGroup.visible = state = "error"
    m.leftListHost.visible = state = "content"
    m.gridHost.visible = state = "content"
end sub

sub onNavTabActivated(event as Object)
    tabId = event.getData()
    if tabId = "continue" then return
    ' Navigating away to a different screen — reset nav focus state now so
    ' that when this screen is shown again later, m.focusArea/pillNav.active
    ' are valid instead of stuck on "nav" with real focus back on m.top
    ' (which onKeyEvent has no "nav" branch for, leaving keys dead).
    onNavFocusExitDown()
    if tabId = "movies" or tabId = "series" or tabId = "library" or tabId = "tv" or tabId = "search" or tabId = "settings"
        m.top.openTabScreen = tabId
        return
    end if
    m.top.openLegacyHomeSection = continueScreenLegacySectionForTab(tabId)
end sub

function continueScreenLegacySectionForTab(tabId as String) as String
    return "home"
end function

sub onNavFocusExitDown()
    m.pillNav.active = false
    m.top.setFocus(true)
    if m.navEntryArea = "grid" and m.gridItems.Count() > 0
        m.focusArea = "grid"
        continueScreenUpdateGridFocus()
    else
        m.focusArea = "leftList"
        continueScreenUpdateLeftListFocus()
    end if
end sub

sub onExitDialogResult(event as Object)
    result = event.getData()
    m.exitDialog.visible = false
    if result = "confirm" then m.top.exitRequested = true
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false

    ' The dialog never takes real SceneGraph focus (see
    ' ListPickerDialog.brs's header comment for why) — this screen keeps it
    ' throughout, so key routing while it's open happens explicitly here.
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
            continueScreenLoadAll()
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
                continueScreenUpdateLeftListFocus()
                m.pillNav.active = true
                m.pillNav.setFocus(true)
            else
                continueScreenSelectRow(m.selectedRowIndex - 1)
            end if
            return true
        else if key = "down"
            continueScreenSelectRow(m.selectedRowIndex + 1)
            return true
        else if key = "right"
            if m.gridItems.Count() > 0
                m.focusArea = "grid"
                m.selectedGridIndex = 0
                continueScreenUpdateLeftListFocus()
                continueScreenUpdateGridFocus()
            end if
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
                m.focusArea = "leftList"
                continueScreenUpdateLeftListFocus()
                continueScreenUpdateGridFocus()
            else
                continueScreenMoveGridFocus(-1)
            end if
            return true
        else if key = "right"
            continueScreenMoveGridFocus(1)
            return true
        else if key = "down"
            continueScreenMoveGridFocus(m.gridColumns)
            return true
        else if key = "up"
            if m.selectedGridIndex < m.gridColumns
                m.focusArea = "nav"
                m.navEntryArea = "grid"
                continueScreenUpdateGridFocus()
                m.pillNav.active = true
                m.pillNav.setFocus(true)
            else
                continueScreenMoveGridFocus(-m.gridColumns)
            end if
            return true
        else if key = "OK"
            continueScreenSelectGridItem()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    return false
end function

sub continueScreenMoveGridFocus(delta as Integer)
    if m.gridItems.Count() = 0 then return
    nextIndex = m.selectedGridIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.gridItems.Count() then nextIndex = m.gridItems.Count() - 1
    m.selectedGridIndex = nextIndex
    continueScreenUpdateGridFocus()
end sub

sub continueScreenSelectGridItem()
    if m.gridItems.Count() = 0 then return
    selectedItem = m.gridItems[m.selectedGridIndex]
    if selectedItem.itemId = invalid or selectedItem.itemId <= 0 then return

    selection = { itemId: selectedItem.itemId, source: "continue" }
    if selectedItem.DoesExist("mediaId") then selection.mediaId = selectedItem.mediaId
    if selectedItem.DoesExist("targetSeasonNumber") then selection.targetSeasonNumber = selectedItem.targetSeasonNumber
    if selectedItem.DoesExist("targetEpisodeNumber") then selection.targetEpisodeNumber = selectedItem.targetEpisodeNumber
    if selectedItem.DoesExist("seasonNumber") then selection.seasonNumber = selectedItem.seasonNumber
    if selectedItem.DoesExist("episodeNumber") then selection.episodeNumber = selectedItem.episodeNumber
    m.top.videoSelected = selection
end sub
