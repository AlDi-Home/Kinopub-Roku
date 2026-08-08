' Shared Yes/No exit-confirmation overlay for the light-theme screens
' (ContinueScreen/BrowseScreen/LiveScreen).
'
' Deliberately does NOT take real SceneGraph focus (no setFocus/onKeyEvent
' here) — the owning screen keeps focus the entire time and calls
' toggleSelection()/confirmSelection() via callFunc while this is visible,
' checking m.exitDialog.visible at the top of its own onKeyEvent, and sets
' m.exitDialog.visible = false itself on Back. See ListPickerDialog.brs's
' header comment for why this component was changed to this shape (an
' earlier version gave dialogs real focus, which turned out not to reliably
' hand focus back to the caller — same root cause, same fix, applied here
' for consistency and because the exit dialog shares the exact pattern).
' Helper names are prefixed exitConfirmDialog* since top-level names are
' global across the whole channel; init() is the per-instance-safe
' exception.

sub init()
    m.yesBg = m.top.findNode("yesBg")
    m.noBg = m.top.findNode("noBg")
    m.yesLabel = m.top.findNode("yesLabel")
    m.noLabel = m.top.findNode("noLabel")

    theme = UiThemeLight()
    m.yesLabel.color = theme.text
    m.noLabel.color = theme.text
    m.yesLabel.font.size = 20
    m.noLabel.font.size = 20

    m.selectedIndex = 1
    exitConfirmDialogUpdateVisuals()
end sub

sub exitConfirmDialogUpdateVisuals()
    theme = UiThemeLight()
    if m.selectedIndex = 0
        m.yesBg.color = theme.surfaceFocus
        m.noBg.color = theme.surfaceAlt
    else
        m.yesBg.color = theme.surfaceAlt
        m.noBg.color = theme.surfaceFocus
    end if
end sub

' Public: called by the owning screen via callFunc on Left/Right.
sub toggleSelection()
    if m.selectedIndex = 0 then m.selectedIndex = 1 else m.selectedIndex = 0
    exitConfirmDialogUpdateVisuals()
end sub

' Public: called by the owning screen via callFunc on OK.
sub confirmSelection()
    if m.selectedIndex = 0
        m.top.dialogResult = "confirm"
    else
        m.top.dialogResult = "cancel"
    end if
end sub
