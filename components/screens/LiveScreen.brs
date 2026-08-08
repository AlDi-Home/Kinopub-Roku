' Live TV grid — KinoTvService returns a flat, unpaginated, unfiltered
' channel/event list, so unlike BrowseScreen there's no left list and no
' incremental loading, just a single load + the grid half of ContinueScreen's
' pattern (render whole bounded list, strict visibility windowing, smooth
' scroll). Top-level names are global across the whole channel regardless of
' which component's <script> tags loaded them (see BrowseScreen.brs's header
' comment), hence the liveScreen* prefix on every plain helper; init()/
' onKeyEvent()/observeField-callback names are the exception and safely reuse
' the same names as the other screens.

sub init()
    m.pillNav = m.top.findNode("pillNav")
    m.gridHost = m.top.findNode("gridHost")
    m.gridContent = m.top.findNode("gridContent")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    m.exitDialog = m.top.findNode("exitDialog")
    m.exitDialog.observeField("dialogResult", "onExitDialogResult")

    m.gridColumns = 6
    m.gridCardWidth = 170
    m.gridCardGapX = 22
    m.gridCardGapY = 26
    m.gridRowStep = 0
    m.gridContentOffsetY = 0
    m.gridViewportHeight = 596
    m.gridScrollAnimation = invalid
    m.gridScrollInterpolator = invalid

    ' Same clipping-padding trick as ContinueScreen.brs/BrowseScreen.brs.
    m.gridPad = 44
    gridBaseX = 30
    gridBaseY = 90
    contentWidth = (m.gridCardWidth * m.gridColumns) + (m.gridCardGapX * (m.gridColumns - 1))
    m.gridHost.translation = [gridBaseX - m.gridPad, gridBaseY - m.gridPad]
    m.gridHost.clippingRect = [0, 0, contentWidth + (m.gridPad * 2), m.gridViewportHeight + (m.gridPad * 2)]
    m.gridContent.translation = [m.gridPad, m.gridPad]

    m.pillNav.tabs = [
        { id: "search", label: "Поиск" }
        { id: "movies", label: "Фильмы" }
        { id: "series", label: "Сериалы" }
        { id: "continue", label: "Мои" }
        { id: "library", label: "Библиотека" }
        { id: "tv", label: "ТВ" }
        { id: "settings", label: "", icon: "pkg:/images/ui/icon-settings.png" }
    ]
    m.pillNav.selectedTabId = "tv"
    m.pillNav.active = false
    m.pillNav.observeField("tabActivated", "onNavTabActivated")
    m.pillNav.observeField("focusExitDown", "onNavFocusExitDown")

    m.focusArea = "grid"
    m.gridItems = []
    m.gridCardNodes = []
    m.selectedGridIndex = 0

    m.top.setFocus(true)
    liveScreenLoad()
end sub

sub liveScreenLoad()
    liveScreenShowState("loading")
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadLiveTv"
    task.request = {}
    task.observeField("response", "onLiveItemsResponse")
    task.control = "RUN"
    m.liveTask = task
end sub

sub onLiveItemsResponse(event as Object)
    response = event.getData()
    if liveScreenHandleAuthRequired(response) then return

    if response = invalid or response.ok <> true or response.items = invalid
        liveScreenShowState("error")
        return
    end if

    m.gridItems = response.items
    m.selectedGridIndex = 0
    liveScreenRenderGrid()
    liveScreenShowState("content")
end sub

function liveScreenHandleAuthRequired(response as Dynamic) as Boolean
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

sub liveScreenRenderGrid()
    childCount = m.gridContent.getChildCount()
    if childCount > 0 then m.gridContent.removeChildrenIndex(childCount, 0)
    m.gridCardNodes = []
    m.gridContentOffsetY = 0
    m.gridContent.translation = [m.gridPad, m.gridPad]

    if m.gridItems.Count() = 0
        empty = CreateObject("roSGNode", "Label")
        empty.text = "Нет доступных трансляций"
        empty.width = 700
        empty.height = 40
        empty.color = UiThemeLight().muted
        m.gridContent.appendChild(empty)
        m.gridRowStep = 0
        return
    end if

    columns = m.gridColumns
    cardW = m.gridCardWidth
    m.gridRowStep = posterCompactLayout(0, 0, cardW).cardHeight + m.gridCardGapY

    for index = 0 to m.gridItems.Count() - 1
        gridItem = m.gridItems[index]
        column = index MOD columns
        row = Int(index / columns)

        x = column * (cardW + m.gridCardGapX)
        y = row * m.gridRowStep
        layout = posterCompactLayout(x, y, cardW)

        cardInfo = createPosterCard(gridItem, layout)
        m.gridContent.appendChild(cardInfo.node)
        m.gridCardNodes.Push({ node: cardInfo.node, focusBg: cardInfo.focusBg, focusShadow: cardInfo.focusShadow, index: index, row: row })
    end for

    liveScreenUpdateGridVisibility()
    liveScreenUpdateGridFocus()
end sub

sub liveScreenUpdateGridVisibility()
    if m.gridRowStep = 0 then return
    firstVisibleRow = Int(m.gridContentOffsetY / m.gridRowStep)
    lastVisibleRow = Int((m.gridContentOffsetY + m.gridViewportHeight - 1) / m.gridRowStep)
    for each cardNode in m.gridCardNodes
        cardNode.node.visible = (cardNode.row >= firstVisibleRow) and (cardNode.row <= lastVisibleRow)
    end for
end sub

sub liveScreenUpdateGridFocus()
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
    liveScreenScrollGridToFocus()
end sub

sub liveScreenScrollGridToFocus()
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
        liveScreenAnimateGridScroll(currentOffset, newOffset)
        m.gridContentOffsetY = newOffset
        liveScreenUpdateGridVisibility()
    end if
end sub

sub liveScreenAnimateGridScroll(fromY as Integer, toY as Integer)
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

sub liveScreenShowState(state as String)
    m.loadingGroup.visible = state = "loading"
    m.errorGroup.visible = state = "error"
    m.gridHost.visible = state = "content"
end sub

sub onNavTabActivated(event as Object)
    tabId = event.getData()
    if tabId = "tv" then return
    ' Navigating away — reset nav focus state now so keys still work when
    ' this screen is shown again later (see BrowseScreen.brs's identical
    ' comment on this exact bug).
    onNavFocusExitDown()
    if tabId = "continue"
        m.top.openContinueScreen = true
        return
    end if
    if tabId = "movies" or tabId = "series" or tabId = "library" or tabId = "search" or tabId = "settings"
        m.top.openTabScreen = tabId
        return
    end if
    m.top.openLegacyHomeSection = liveScreenLegacySectionForTab(tabId)
end sub

function liveScreenLegacySectionForTab(tabId as String) as String
    return "home"
end function

sub onNavFocusExitDown()
    m.pillNav.active = false
    m.top.setFocus(true)
    m.focusArea = "grid"
    liveScreenUpdateGridFocus()
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
            liveScreenLoad()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    if m.focusArea = "grid"
        if key = "left"
            if m.selectedGridIndex MOD m.gridColumns <> 0 then liveScreenMoveGridFocus(-1)
            return true
        else if key = "right"
            liveScreenMoveGridFocus(1)
            return true
        else if key = "down"
            liveScreenMoveGridFocus(m.gridColumns)
            return true
        else if key = "up"
            if m.selectedGridIndex < m.gridColumns
                m.focusArea = "nav"
                liveScreenUpdateGridFocus()
                m.pillNav.active = true
                m.pillNav.setFocus(true)
            else
                liveScreenMoveGridFocus(-m.gridColumns)
            end if
            return true
        else if key = "OK"
            liveScreenSelectGridItem()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    return false
end function

sub liveScreenMoveGridFocus(delta as Integer)
    if m.gridItems.Count() = 0 then return
    nextIndex = m.selectedGridIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.gridItems.Count() then nextIndex = m.gridItems.Count() - 1
    m.selectedGridIndex = nextIndex
    liveScreenUpdateGridFocus()
end sub

sub liveScreenSelectGridItem()
    if m.gridItems.Count() = 0 then return
    item = m.gridItems[m.selectedGridIndex]
    if item.streamUrl = invalid or item.streamUrl = "" then return

    m.top.livePlaybackSelected = {
        title: item.title
        subtitle: item.subtitle
        itemId: 0
        mediaId: 0
        seasonNumber: 0
        videoNumber: 0
        progressSeconds: 0
        durationSeconds: 0
        streamUrl: item.streamUrl
        streamFormat: item.streamFormat
        qualityOptions: item.qualityOptions
        isLive: true
    }
end sub
