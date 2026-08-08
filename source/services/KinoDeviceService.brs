' Device info + settings, per https://kinoapi.com/api_device.html.
' "Settings" is a keyed object (not a list) where each entry is either a
' checkbox ({label, value: 0/1}) or, when tagged type:"list", a picker
' ({label, value: [{id,label,description,selected}, ...]}). This service only
' normalizes the three settings the Settings screen exposes (support4k,
' serverLocation, streamingType) — the API also returns others (supportSsl,
' supportHevc, supportHdr, mixedPlaylist) that aren't surfaced there yet.

function KinoDeviceService(client as Object) as Object
    return {
        client: client
        currentDevice: kinoDeviceCurrentDevice
        loadSettings: kinoDeviceLoadSettings
        updateSetting: kinoDeviceUpdateSetting
        normalizeSettings: kinoDeviceNormalizeSettings
        normalizeCheckboxSetting: kinoDeviceNormalizeCheckboxSetting
        normalizeListSetting: kinoDeviceNormalizeListSetting
        integerField: kinoDeviceIntegerField
        failure: kinoDeviceFailure
    }
end function

function kinoDeviceCurrentDevice(accessToken as String) as Object
    response = m.client.get("/v1/device/info", { access_token: accessToken }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)

    device = invalid
    if response.body <> invalid and type(response.body) = "roAssociativeArray" and response.body.DoesExist("device") then device = response.body.device

    id = m.integerField(device, "id", 0)
    if id <= 0 then return { ok: false, error: "invalid_response", message: "Unable to identify this device.", status: response.status }

    return { ok: true, id: id }
end function

function kinoDeviceLoadSettings(accessToken as String, deviceId as Integer) as Object
    response = m.client.get("/v1/device/" + StrI(deviceId).Trim() + "/settings", { access_token: accessToken }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)

    settingsBody = invalid
    if response.body <> invalid and type(response.body) = "roAssociativeArray" and response.body.DoesExist("settings") then settingsBody = response.body.settings

    return { ok: true, settings: m.normalizeSettings(settingsBody) }
end function

' value is always a String here (e.g. "1"/"0" for a checkbox, or a list
' option's id) — the API client only speaks form-encoded bodies, so keeping
' every value a plain string sidesteps any Boolean/Integer encoding
' ambiguity (see KinoApiClient.brs's kinoApiStringValue).
function kinoDeviceUpdateSetting(accessToken as String, deviceId as Integer, key as String, value as String) as Object
    body = {}
    body[key] = value
    response = m.client.post("/v1/device/" + StrI(deviceId).Trim() + "/settings", { access_token: accessToken }, body, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return { ok: true }
end function

function kinoDeviceNormalizeSettings(body as Dynamic) as Object
    if body = invalid or type(body) <> "roAssociativeArray" then body = {}
    return {
        support4k: m.normalizeCheckboxSetting(body, "support4k")
        serverLocation: m.normalizeListSetting(body, "serverLocation")
        streamingType: m.normalizeListSetting(body, "streamingType")
    }
end function

function kinoDeviceNormalizeCheckboxSetting(body as Object, key as String) as Boolean
    if body.DoesExist(key) <> true or body[key] = invalid or type(body[key]) <> "roAssociativeArray" then return false
    entry = body[key]
    if entry.DoesExist("value") <> true or entry.value = invalid then return false
    value = entry.value
    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value <> 0
    return false
end function

' Returns {options: [{id, title}], selectedId} — ids are stringified so
' callers can hand them straight to ListPickerDialog (which, like every
' other picker in this app, works in string ids throughout).
function kinoDeviceNormalizeListSetting(body as Object, key as String) as Object
    options = []
    selectedId = ""

    if body.DoesExist(key) = true and body[key] <> invalid and type(body[key]) = "roAssociativeArray"
        entry = body[key]
        if entry.DoesExist("value") = true and entry.value <> invalid and type(entry.value) = "roArray"
            for each optionEntry in entry.value
                id = m.integerField(optionEntry, "id", 0)
                idText = StrI(id).Trim()
                title = idText
                if optionEntry.DoesExist("label") and optionEntry.label <> invalid and optionEntry.label <> "" then title = optionEntry.label
                options.Push({ id: idText, title: title })

                selected = m.integerField(optionEntry, "selected", 0)
                if selected <> 0 then selectedId = idText
            end for
        end if
    end if

    return { options: options, selectedId: selectedId }
end function

function kinoDeviceIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    if valueType = "String" or valueType = "roString"
        trimmed = value.Trim()
        if trimmed <> "" then return trimmed.ToInt()
    end if
    return fallback
end function

function kinoDeviceFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function
