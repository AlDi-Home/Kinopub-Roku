sub init()
    m.logoLabel = m.top.findNode("logoLabel")
    m.pillHost = m.top.findNode("pillHost")
    m.outerPill = m.top.findNode("outerPill")
    m.focusPill = m.top.findNode("focusPill")
    m.innerPill = m.top.findNode("innerPill")
    m.tabHost = m.top.findNode("tabHost")
    m.tabNodes = []
    m.focusedIndex = 0

    m.outerH = 44
    m.innerH = 36
    m.innerInsetY = Int((m.outerH - m.innerH) / 2)
    m.tabPaddingX = 16

    theme = UiThemeLight()

    m.logoLabel.color = theme.text
    m.logoLabel.font.size = 28
    logoWidth = Int(m.logoLabel.boundingRect().width) + 6
    m.logoLabel.width = logoWidth
    m.pillHost.translation = [logoWidth + 24, 0]

    m.outerPill.translation = [0, 0]
    m.outerPill.height = m.outerH
    m.outerPill.color = theme.pillUnselectedBg
    m.outerPill.cornerRadius = Int(m.outerH / 2)

    m.focusPill.height = m.innerH
    m.focusPill.color = theme.surfaceFocus
    m.focusPill.cornerRadius = Int(m.innerH / 2)
    m.focusPill.visible = false

    m.innerPill.height = m.innerH
    m.innerPill.color = theme.pillSelectedBg
    m.innerPill.cornerRadius = Int(m.innerH / 2)
    m.innerPill.visible = false
end sub

sub onTabsChanged()
    renderTabs()
end sub

sub onSelectedTabIdChange()
    updateTabVisuals()
end sub

' Keyboard-focus position (m.focusedIndex, used for Left/Right + the pop
' highlight) is tracked separately from which tab is actually selected
' (m.top.selectedTabId, the white pill) — each screen owns its own PillNavBar
' instance and that instance persists across visits, so without this,
' re-entering the nav bar resumes focus wherever it was left (e.g. still on
' the first tab from this instance's initial render, or wherever it was the
' last time this exact screen's nav bar had focus) instead of the tab that's
' actually current. Re-sync every time the nav bar gains focus.
sub onActiveChange()
    if m.top.active = true then m.focusedIndex = indexForSelectedTab()
    updateTabVisuals()
end sub

function indexForSelectedTab() as Integer
    for i = 0 to m.tabNodes.Count() - 1
        if m.tabNodes[i].id = m.top.selectedTabId then return i
    end for
    return 0
end function

sub renderTabs()
    childCount = m.tabHost.getChildCount()
    if childCount > 0 then m.tabHost.removeChildrenIndex(childCount, 0)
    m.tabNodes = []
    m.focusedIndex = 0

    tabDefs = m.top.tabs
    if tabDefs = invalid then return

    theme = UiThemeLight()
    x = m.tabPaddingX
    tabHeight = m.outerH

    for each tabDef in tabDefs
        hasIcon = tabDef.DoesExist("icon") and tabDef.icon <> ""

        if hasIcon
            textWidth = 22
            iconSize = 20
            contentNode = CreateObject("roSGNode", "Poster")
            contentNode.translation = [x + Int((textWidth - iconSize) / 2), Int((tabHeight - iconSize) / 2)]
            contentNode.width = iconSize
            contentNode.height = iconSize
            contentNode.uri = tabDef.icon
            contentNode.loadDisplayMode = "scaleToFit"
            contentNode.scaleRotateCenter = [Int(iconSize / 2), Int(iconSize / 2)]
            m.tabHost.appendChild(contentNode)
        else
            contentNode = CreateObject("roSGNode", "Label")
            contentNode.font.size = 22
            contentNode.color = theme.text
            contentNode.horizAlign = "center"
            contentNode.vertAlign = "center"
            contentNode.height = tabHeight
            contentNode.text = tabDef.label
            textWidth = Int(contentNode.boundingRect().width) + 14
            if textWidth < 34 then textWidth = 34
            contentNode.translation = [x, 0]
            contentNode.width = textWidth
            contentNode.scaleRotateCenter = [Int(textWidth / 2), Int(tabHeight / 2)]
            m.tabHost.appendChild(contentNode)
        end if

        m.tabNodes.Push({ id: tabDef.id, x: x, width: textWidth, content: contentNode })

        x = x + textWidth + m.tabPaddingX
    end for

    m.outerPill.width = x

    updateTabVisuals()
end sub

sub updateTabVisuals()
    selectedNode = invalid
    for each node in m.tabNodes
        if node.id = m.top.selectedTabId then selectedNode = node
    end for

    if selectedNode <> invalid
        pillX = selectedNode.x - Int(m.tabPaddingX / 2)
        pillWidth = selectedNode.width + m.tabPaddingX
        m.innerPill.translation = [pillX, m.innerInsetY]
        m.innerPill.width = pillWidth
        m.innerPill.visible = true
    else
        m.innerPill.visible = false
    end if

    focusedNode = invalid
    if m.top.active = true and m.focusedIndex >= 0 and m.focusedIndex < m.tabNodes.Count()
        focusedNode = m.tabNodes[m.focusedIndex]
    end if

    if focusedNode <> invalid
        pillX = focusedNode.x - Int(m.tabPaddingX / 2)
        pillWidth = focusedNode.width + m.tabPaddingX
        m.focusPill.translation = [pillX, m.innerInsetY]
        m.focusPill.width = pillWidth
        m.focusPill.visible = true
    else
        m.focusPill.visible = false
    end if

    for i = 0 to m.tabNodes.Count() - 1
        node = m.tabNodes[i]
        isFocused = (focusedNode <> invalid) and (i = m.focusedIndex)
        if isFocused
            node.content.scale = [1.12, 1.12]
        else
            node.content.scale = [1.0, 1.0]
        end if
    end for
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false
    if m.top.active <> true then return false
    if m.tabNodes.Count() = 0 then return false

    if key = "left"
        if m.focusedIndex > 0
            m.focusedIndex = m.focusedIndex - 1
            updateTabVisuals()
        end if
        return true
    else if key = "right"
        if m.focusedIndex < m.tabNodes.Count() - 1
            m.focusedIndex = m.focusedIndex + 1
            updateTabVisuals()
        end if
        return true
    else if key = "OK"
        m.top.tabActivated = m.tabNodes[m.focusedIndex].id
        return true
    else if key = "down"
        m.top.focusExitDown = true
        return true
    end if

    return false
end function
