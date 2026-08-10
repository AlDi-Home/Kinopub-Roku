' Settings ("gear" tab) — account summary (KinoUserService's /v1/user) plus a
' short list of device settings (KinoDeviceService's /v1/device/{id}/settings,
' see https://kinoapi.com/api_device.html): 4K support, server location, and
' streaming type, matching what was asked for. The API also exposes
' supportSsl/supportHevc/supportHdr/mixedPlaylist on the same endpoint, not
' surfaced here since nobody asked for them — add rows the same way if that
' changes. Singleton pattern like LiveScreen.brs (no per-instance configure()
' needed). All top-level helpers are prefixed settingsScreen* — see
' BrowseScreen.brs's header comment for why (every sub/function in this
' channel is global regardless of which component's <script> tags loaded it;
' init()/onKeyEvent()/observeField-callback names are the exception).

sub init()
    m.pillNav = m.top.findNode("pillNav")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    m.contentGroup = m.top.findNode("contentGroup")

    m.accountNameLabel = m.top.findNode("accountNameLabel")
    m.accountUsernameLabel = m.top.findNode("accountUsernameLabel")
    m.accountStatusLabel = m.top.findNode("accountStatusLabel")
    m.accountDaysLabel = m.top.findNode("accountDaysLabel")
    m.accountEndLabel = m.top.findNode("accountEndLabel")
    m.accountRegisteredLabel = m.top.findNode("accountRegisteredLabel")
    m.accountVersionLabel = m.top.findNode("accountVersionLabel")
    m.settingsRowsHost = m.top.findNode("settingsRowsHost")
    m.settingsMessageLabel = m.top.findNode("settingsMessageLabel")

    m.exitDialog = m.top.findNode("exitDialog")
    m.exitDialog.observeField("dialogResult", "onExitDialogResult")
    m.filterPickerDialog = m.top.findNode("filterPickerDialog")
    m.filterPickerDialog.observeField("dialogResult", "onFilterPickerResult")

    m.accountInfo = invalid
    m.accountReady = false
    m.accountFailed = false

    m.deviceId = 0
    m.support4k = false
    m.serverLocationOptions = []
    m.serverLocationSelectedId = ""
    m.streamingTypeOptions = []
    m.streamingTypeSelectedId = ""
    m.deviceReady = false
    m.deviceFailed = false

    m.appSettingsStore = AppSettingsStore()
    m.hideAnime = m.appSettingsStore.loadHideAnime()

    m.activeSettingId = ""
    m.settingsRows = []
    m.settingsRowNodes = []
    m.selectedRowIndex = 0

    m.pillNav.tabs = [
        { id: "search", label: "Поиск" }
        { id: "movies", label: "Фильмы" }
        { id: "series", label: "Сериалы" }
        { id: "continue", label: "Мои" }
        { id: "library", label: "Библиотека" }
        { id: "tv", label: "ТВ" }
        { id: "settings", label: "", icon: "pkg:/images/ui/icon-settings.png" }
    ]
    m.pillNav.selectedTabId = "settings"
    m.pillNav.active = false
    m.pillNav.observeField("tabActivated", "onNavTabActivated")
    m.pillNav.observeField("focusExitDown", "onNavFocusExitDown")

    m.focusArea = "rows"

    m.top.setFocus(true)
    settingsScreenLoadAll()
end sub

' Fires a single token-refresh preflight before the real fan-out below —
' otherwise both tasks below would independently discover an expired token
' and race to refresh it concurrently (TokenStore.brs has no cross-task
' locking; the losing refresh call fails against an already-rotated token and
' signs the user out). No-op HTTP-wise if the token is already valid.
sub settingsScreenLoadAll()
    settingsScreenShowState("loading")
    m.accountReady = false
    m.accountFailed = false
    m.deviceReady = false
    m.deviceFailed = false
    m.settingsMessageLabel.text = ""

    preflightTask = CreateObject("roSGNode", "ContentTask")
    preflightTask.command = "ensureFreshTokens"
    preflightTask.request = {}
    preflightTask.observeField("response", "onTokenPreflightResponse")
    preflightTask.control = "RUN"
    m.preflightTask = preflightTask
end sub

sub onTokenPreflightResponse(event as Object)
    settingsScreenLoadAllContent()
end sub

sub settingsScreenLoadAllContent()
    accountTask = CreateObject("roSGNode", "ContentTask")
    accountTask.command = "loadUserInfo"
    accountTask.request = {}
    accountTask.observeField("response", "onAccountInfoResponse")
    accountTask.control = "RUN"
    m.accountTask = accountTask

    deviceTask = CreateObject("roSGNode", "ContentTask")
    deviceTask.command = "loadDeviceSettings"
    deviceTask.request = {}
    deviceTask.observeField("response", "onDeviceSettingsResponse")
    deviceTask.control = "RUN"
    m.deviceTask = deviceTask
end sub

sub onAccountInfoResponse(event as Object)
    response = event.getData()
    if settingsScreenHandleAuthRequired(response) then return

    if response = invalid or response.ok <> true or response.user = invalid
        m.accountFailed = true
    else
        m.accountInfo = response.user
        m.accountReady = true
    end if
    settingsScreenEvaluateState()
end sub

sub onDeviceSettingsResponse(event as Object)
    response = event.getData()
    if settingsScreenHandleAuthRequired(response) then return

    if response = invalid or response.ok <> true or response.settings = invalid
        m.deviceFailed = true
    else
        m.deviceId = response.deviceId
        m.support4k = response.settings.support4k
        m.serverLocationOptions = response.settings.serverLocation.options
        m.serverLocationSelectedId = response.settings.serverLocation.selectedId
        m.streamingTypeOptions = response.settings.streamingType.options
        m.streamingTypeSelectedId = response.settings.streamingType.selectedId
        m.deviceReady = true
    end if
    settingsScreenEvaluateState()
end sub

function settingsScreenHandleAuthRequired(response as Dynamic) as Boolean
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

sub settingsScreenEvaluateState()
    if m.accountFailed or m.deviceFailed
        settingsScreenShowState("error")
        return
    end if
    if m.accountReady <> true or m.deviceReady <> true then return

    settingsScreenRenderAccount()
    m.settingsRows = settingsScreenBuildRows()
    settingsScreenRenderRows()
    settingsScreenShowState("content")
end sub

sub settingsScreenRetryLoad()
    settingsScreenLoadAll()
end sub

' ---------------------------------------------------------------------------
' Account
' ---------------------------------------------------------------------------

sub settingsScreenRenderAccount()
    info = m.accountInfo
    theme = UiThemeLight()

    displayName = settingsScreenStringField(info, "displayName", "Аккаунт")
    m.accountNameLabel.text = displayName
    m.accountNameLabel.font.size = 28

    username = settingsScreenStringField(info, "username", "")
    if username <> ""
        m.accountUsernameLabel.text = "Логин: " + username
    else
        m.accountUsernameLabel.text = ""
    end if

    active = settingsScreenBooleanField(info, "subscriptionActive", false)
    if active
        m.accountStatusLabel.text = "Подписка активна"
        m.accountStatusLabel.color = "#16A34A"
    else
        m.accountStatusLabel.text = "Подписка неактивна"
        m.accountStatusLabel.color = theme.unwatchedBadgeBg
    end if

    daysLeft = settingsScreenNumberField(info, "subscriptionDaysLeft", -1)
    if daysLeft >= 0
        m.accountDaysLabel.text = "Осталось дней: " + StrI(Int(daysLeft)).Trim()
    else
        m.accountDaysLabel.text = ""
    end if

    endDate = settingsScreenStringField(info, "subscriptionEndDate", "")
    if endDate <> ""
        m.accountEndLabel.text = "Окончание подписки: " + endDate
    else
        m.accountEndLabel.text = ""
    end if

    registeredDate = settingsScreenStringField(info, "registeredDate", "")
    if registeredDate <> ""
        m.accountRegisteredLabel.text = "Регистрация: " + registeredDate
    else
        m.accountRegisteredLabel.text = ""
    end if

    appBuildInfo = BuildInfo()
    m.accountVersionLabel.text = "Версия приложения: " + appBuildInfo.displayVersion
end sub

function settingsScreenStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    return fallback
end function

function settingsScreenNumberField(source as Dynamic, key as String, fallback as Float) as Float
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return value
    return fallback
end function

function settingsScreenBooleanField(source as Dynamic, key as String, fallback as Boolean) as Boolean
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return value
    return fallback
end function

' ---------------------------------------------------------------------------
' Device settings rows
' ---------------------------------------------------------------------------

function settingsScreenTitleForListValue(options as Object, selectedId as String) as String
    for each option in options
        if option.id = selectedId then return option.title
    end for
    return "Не задано"
end function

function settingsScreenBuildRows() as Object
    fourKText = "Нет"
    if m.support4k = true then fourKText = "Да"

    hideAnimeText = "Нет"
    if m.hideAnime = true then hideAnimeText = "Да"

    return [
        { id: "support4k", label: "Поддержка 4K: " + fourKText }
        { id: "serverLocation", label: "Сервер: " + settingsScreenTitleForListValue(m.serverLocationOptions, m.serverLocationSelectedId) }
        { id: "streamingType", label: "Тип трансляции: " + settingsScreenTitleForListValue(m.streamingTypeOptions, m.streamingTypeSelectedId) }
        { id: "hideAnime", label: "Скрывать Аниме: " + hideAnimeText }
        { id: "signOut", label: "Выйти из аккаунта" }
    ]
end function

sub settingsScreenRenderRows()
    childCount = m.settingsRowsHost.getChildCount()
    if childCount > 0 then m.settingsRowsHost.removeChildrenIndex(childCount, 0)
    m.settingsRowNodes = []

    theme = UiThemeLight()
    rowWidth = 560
    rowHeight = 48
    rowStep = rowHeight + 10

    for i = 0 to m.settingsRows.Count() - 1
        row = m.settingsRows[i]
        y = i * rowStep

        group = CreateObject("roSGNode", "Group")
        group.translation = [0, y]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = rowWidth
        bg.height = rowHeight
        bg.color = theme.surfaceAlt
        group.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.text = row.label
        label.translation = [16, 14]
        label.width = rowWidth - 32
        label.height = 20
        label.color = theme.text
        group.appendChild(label)

        m.settingsRowsHost.appendChild(group)
        m.settingsRowNodes.Push({ group: group, bg: bg })
    end for

    if m.selectedRowIndex >= m.settingsRowNodes.Count() then m.selectedRowIndex = 0
    settingsScreenUpdateRowFocus()
end sub

sub settingsScreenUpdateRowFocus()
    theme = UiThemeLight()
    for i = 0 to m.settingsRowNodes.Count() - 1
        node = m.settingsRowNodes[i]
        isFocused = (i = m.selectedRowIndex) and (m.focusArea = "rows")
        if isFocused
            node.bg.color = theme.surfaceFocus
        else
            node.bg.color = theme.surfaceAlt
        end if
    end for
end sub

sub settingsScreenMoveRowFocus(delta as Integer)
    if m.settingsRowNodes.Count() = 0 then return
    nextIndex = m.selectedRowIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.settingsRowNodes.Count() then nextIndex = m.settingsRowNodes.Count() - 1
    m.selectedRowIndex = nextIndex
    settingsScreenUpdateRowFocus()
end sub

sub settingsScreenActivateRow()
    if m.settingsRows.Count() = 0 then return
    row = m.settingsRows[m.selectedRowIndex]

    if row.id = "support4k"
        settingsScreenToggleSupport4k()
    else if row.id = "hideAnime"
        settingsScreenToggleHideAnime()
    else if row.id = "serverLocation" or row.id = "streamingType"
        settingsScreenOpenFilterPicker(row.id)
    else if row.id = "signOut"
        m.top.signOutRequested = true
    end if
end sub

sub settingsScreenToggleSupport4k()
    m.support4k = m.support4k <> true
    m.settingsRows = settingsScreenBuildRows()
    settingsScreenRenderRows()

    value = "0"
    if m.support4k then value = "1"
    settingsScreenSendUpdate("support4k", value)
end sub

' Purely local (registry-backed) preference — no device API round trip, so
' unlike settingsScreenToggleSupport4k() this can't fail and never needs
' settingsScreenSendUpdate/re-sync-on-failure.
sub settingsScreenToggleHideAnime()
    m.hideAnime = m.hideAnime <> true
    m.appSettingsStore.saveHideAnime(m.hideAnime)
    m.settingsRows = settingsScreenBuildRows()
    settingsScreenRenderRows()
end sub

sub settingsScreenOpenFilterPicker(settingId as String)
    m.activeSettingId = settingId
    title = "Выберите сервер"
    options = m.serverLocationOptions
    selectedId = m.serverLocationSelectedId
    if settingId = "streamingType"
        title = "Выберите тип трансляции"
        options = m.streamingTypeOptions
        selectedId = m.streamingTypeSelectedId
    end if
    m.filterPickerDialog.callFunc("configure", title, options, selectedId)
    m.filterPickerDialog.visible = true
end sub

sub onFilterPickerResult(event as Object)
    result = event.getData()
    m.filterPickerDialog.visible = false
    if result <> invalid and result.action = "confirm"
        if m.activeSettingId = "serverLocation"
            m.serverLocationSelectedId = result.id
        else if m.activeSettingId = "streamingType"
            m.streamingTypeSelectedId = result.id
        end if
        m.settingsRows = settingsScreenBuildRows()
        settingsScreenRenderRows()
        settingsScreenSendUpdate(m.activeSettingId, result.id)
    end if
    m.activeSettingId = ""
    settingsScreenUpdateRowFocus()
end sub

sub settingsScreenSendUpdate(key as String, value as String)
    m.settingsMessageLabel.text = ""
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "updateDeviceSetting"
    task.request = { deviceId: m.deviceId, key: key, value: value }
    task.observeField("response", "onUpdateDeviceSettingResponse")
    task.control = "RUN"
    m.updateSettingTask = task
end sub

' On failure, re-fetch the whole device settings payload instead of manually
' reverting the optimistic local change — one source of truth to resync
' against instead of duplicating revert logic per field type/shape.
sub onUpdateDeviceSettingResponse(event as Object)
    response = event.getData()
    if settingsScreenHandleAuthRequired(response) then return
    if response = invalid or response.ok <> true
        m.settingsMessageLabel.text = "Не удалось сохранить настройку"
        settingsScreenLoadAll()
    end if
end sub

' ---------------------------------------------------------------------------
' Nav / focus routing
' ---------------------------------------------------------------------------

sub settingsScreenShowState(state as String)
    m.loadingGroup.visible = state = "loading"
    m.errorGroup.visible = state = "error"
    m.contentGroup.visible = state = "content"
end sub

sub onNavTabActivated(event as Object)
    tabId = event.getData()
    if tabId = "settings" then return
    ' Navigating away — reset nav focus state now so keys still work when
    ' this screen is shown again later (see BrowseScreen.brs's identical
    ' comment on this exact bug).
    onNavFocusExitDown()
    if tabId = "continue"
        m.top.openContinueScreen = true
        return
    end if
    if tabId = "movies" or tabId = "series" or tabId = "library" or tabId = "tv" or tabId = "search"
        m.top.openTabScreen = tabId
        return
    end if
    m.top.openLegacyHomeSection = "home"
end sub

sub onNavFocusExitDown()
    m.pillNav.active = false
    m.top.setFocus(true)
    m.focusArea = "rows"
    settingsScreenUpdateRowFocus()
end sub

' Public: called by AppScene via callFunc right after showing this screen as
' a result of activating its pill-nav tab. Unlike BrowseScreen.brs's
' focusContent(), there's no secondary panel to prefer landing on over — the
' rows are the only content — so this just re-asserts the default and is a
' no-op if account/device data hasn't loaded yet (settingsScreenRenderRows()
' re-applies focus once it has).
sub focusContent()
    m.focusArea = "rows"
    m.selectedRowIndex = 0
    settingsScreenUpdateRowFocus()
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
            settingsScreenRetryLoad()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    if m.focusArea = "rows"
        if key = "up"
            if m.selectedRowIndex = 0
                m.focusArea = "nav"
                settingsScreenUpdateRowFocus()
                m.pillNav.active = true
                m.pillNav.setFocus(true)
            else
                settingsScreenMoveRowFocus(-1)
            end if
            return true
        else if key = "down"
            settingsScreenMoveRowFocus(1)
            return true
        else if key = "OK"
            settingsScreenActivateRow()
            return true
        else if key = "back"
            m.exitDialog.visible = true
            return true
        end if
        return false
    end if

    return false
end function
