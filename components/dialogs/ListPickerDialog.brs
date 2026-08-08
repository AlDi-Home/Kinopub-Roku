' Generic reusable option-list picker overlay (Type/Genre/Country/Year/Status
' filters, or any future {id,title} list).
'
' Deliberately does NOT take real SceneGraph focus (no setFocus/onKeyEvent
' here) — the owning screen keeps focus the entire time and calls
' moveSelection()/confirmSelection() via callFunc while this is visible,
' checking m.filterPickerDialog.visible at the top of its own onKeyEvent.
' An earlier version gave this component real focus via setFocus(true) and
' its own onKeyEvent, mirroring ExitConfirmDialog — but transferring focus
' back to the caller from inside a field-change observer that itself fires
' synchronously from within THIS component's onKeyEvent (reentrant, still on
' the call stack) turned out not to reliably stick on Roku: the visual
' "focused" state updated fine, but real key routing silently stayed on
' this (now hidden) dialog, so every subsequent keypress kept landing here
' instead of the screen — matching the "OK re-triggers a reload, Left/Back
' do nothing" symptom this was rewritten to fix. Not transferring focus at
' all sidesteps the whole problem, same as how the legacy Browse page's own
' picker (HomeScreen.brs's browsePickerGroup) always worked — one screen
' holds focus throughout, a boolean flag routes keys internally.
'
' configure() is a callFunc, not a field: init() runs synchronously inside
' CreateObject(), so a field set afterward is invisible to it — see
' BrowseScreen.brs's header comment for the fuller explanation of why this
' codebase uses callFunc for post-construction setup everywhere.
' Helper names are prefixed listPickerDialog* since top-level names are
' global across the whole channel; init() is the per-instance-safe
' exception.

sub init()
    m.panelBg = m.top.findNode("panelBg")
    m.titleLabel = m.top.findNode("titleLabel")
    m.rowsHost = m.top.findNode("rowsHost")
    m.cursor = m.top.findNode("cursor")
    m.statusLabel = m.top.findNode("statusLabel")

    theme = UiThemeLight()
    m.titleLabel.color = theme.text
    m.statusLabel.color = theme.muted

    m.rowHeight = 44
    m.maxRows = 5
    m.items = []
    m.selectedIndex = 0
    m.rowNodes = []
    m.rowIndexes = []
end sub

sub configure(title as String, items as Object, selectedId as String)
    m.titleLabel.text = title
    m.items = items
    m.selectedIndex = listPickerDialogIndexForId(items, selectedId)
    listPickerDialogRenderRows()
end sub

function listPickerDialogIndexForId(items as Object, id as String) as Integer
    for i = 0 to items.Count() - 1
        if items[i].id = id then return i
    end for
    return 0
end function

sub listPickerDialogRenderRows()
    childCount = m.rowsHost.getChildCount()
    if childCount > 0 then m.rowsHost.removeChildrenIndex(childCount, 0)
    m.rowNodes = []
    m.rowIndexes = []

    theme = UiThemeLight()
    count = m.items.Count()

    if count = 0
        m.statusLabel.text = "Нет доступных значений"
        m.cursor.visible = false
        return
    end if

    startIndex = m.selectedIndex - 2
    if startIndex < 0 then startIndex = 0
    maxStart = count - m.maxRows
    if maxStart < 0 then maxStart = 0
    if startIndex > maxStart then startIndex = maxStart
    lastIndex = startIndex + m.maxRows - 1
    if lastIndex >= count then lastIndex = count - 1

    for index = startIndex to lastIndex
        row = CreateObject("roSGNode", "Label")
        row.text = m.items[index].title
        row.translation = [12, (index - startIndex) * m.rowHeight + 10]
        row.width = 356
        row.height = 24
        row.color = theme.text
        m.rowsHost.appendChild(row)
        m.rowNodes.Push(row)
        m.rowIndexes.Push(index)
    end for

    m.statusLabel.text = StrI(m.selectedIndex + 1).Trim() + " / " + StrI(count).Trim()

    listPickerDialogUpdateCursor()
end sub

sub listPickerDialogUpdateCursor()
    for i = 0 to m.rowIndexes.Count() - 1
        if m.rowIndexes[i] = m.selectedIndex
            m.cursor.translation = [20, 58 + (i * m.rowHeight)]
            m.cursor.visible = true
            return
        end if
    end for
    m.cursor.visible = false
end sub

sub listPickerDialogMove(delta as Integer)
    if m.items.Count() = 0 then return
    nextIndex = m.selectedIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.items.Count() then nextIndex = m.items.Count() - 1
    if nextIndex = m.selectedIndex then return
    m.selectedIndex = nextIndex
    listPickerDialogRenderRows()
end sub

' Public: called by the owning screen via callFunc while this dialog is
' visible.
sub moveSelection(delta as Integer)
    listPickerDialogMove(delta)
end sub

' Public: called by the owning screen via callFunc on OK.
sub confirmSelection()
    if m.items.Count() = 0 then return
    selected = m.items[m.selectedIndex]
    m.top.dialogResult = { action: "confirm", id: selected.id, title: selected.title }
end sub
