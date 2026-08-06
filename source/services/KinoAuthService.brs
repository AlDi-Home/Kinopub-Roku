function KinoAuthService(client as Object, tokenStoreService as Object) as Object
    return {
        client: client
        tokenStore: tokenStoreService
        requestDeviceCode: kinoAuthRequestDeviceCode
        pollDeviceToken: kinoAuthPollDeviceToken
        refreshToken: kinoAuthRefreshToken
        notifyDevice: kinoAuthNotifyDevice
        deviceNotifyInfo: kinoAuthDeviceNotifyInfo
        tokensFromResponse: kinoAuthTokensFromResponse
        baseParams: kinoAuthBaseParams
        failure: kinoAuthFailure
    }
end function

function kinoAuthRequestDeviceCode() as Object
    params = m.baseParams()
    params.grant_type = "device_code"
    response = m.client.postForm("/oauth2/device", params, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return { ok: true, device: response.body }
end function

function kinoAuthPollDeviceToken(code as String) as Object
    params = m.baseParams()
    params.grant_type = "device_token"
    params.code = code
    response = m.client.postForm("/oauth2/device", params, m.client.pollTimeoutMs)
    if response.ok <> true
        if response.error = "authorization_pending" then return { ok: false, pending: true, error: "authorization_pending", message: "" }
        return m.failure(response)
    end if

    tokens = m.tokensFromResponse(response.body)
    m.tokenStore.save(tokens)
    return { ok: true, tokens: tokens }
end function

function kinoAuthRefreshToken(refreshToken as String) as Object
    params = m.baseParams()
    params.grant_type = "refresh_token"
    params.refresh_token = refreshToken
    response = m.client.postForm("/oauth2/token", params, m.client.defaultTimeoutMs)
    if response.ok <> true
        m.tokenStore.clear()
        return m.failure(response)
    end if

    tokens = m.tokensFromResponse(response.body)
    m.tokenStore.save(tokens)
    return { ok: true, tokens: tokens }
end function

function kinoAuthNotifyDevice(accessToken as String) as Object
    queryParams = { access_token: accessToken }
    deviceInfo = m.deviceNotifyInfo()
    bodyParams = {
        title: deviceInfo.title
        hardware: deviceInfo.hardware
        software: deviceInfo.software
    }
    response = m.client.postFormBody("/v1/device/notify", queryParams, bodyParams, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return { ok: true }
end function

function kinoAuthDeviceNotifyInfo() as Object
    software = "Roku OS"

    deviceInfo = CreateObject("roDeviceInfo")
    if deviceInfo <> invalid
        modelDetails = deviceInfo.GetModelDetails()
        title = kinoAuthDeviceTitle(deviceInfo, modelDetails)
        hardware = kinoAuthDeviceHardware(deviceInfo)

        osVersion = kinoAuthFormattedOsVersion(deviceInfo.GetOSVersion())
        if osVersion <> "" then software = "Firmware/" + osVersion
    else
        title = "Roku"
        hardware = "Roku"
    end if

    return {
        title: title
        hardware: hardware
        software: software
    }
end function

function kinoAuthDeviceTitle(deviceInfo as Object, modelDetails as Dynamic) as String
    modelType = kinoAuthStringValue(deviceInfo.GetModelType())
    screenSize = ""

    screenSize = kinoAuthAssocStringValue(modelDetails, "ScreenSize")

    if modelType <> "" and screenSize <> "" then return "Roku" + LCase(modelType) + screenSize

    displayName = kinoAuthStringValue(deviceInfo.GetModelDisplayName())
    if displayName <> "" then return displayName

    friendlyName = kinoAuthStringValue(deviceInfo.GetFriendlyName())
    if friendlyName <> "" then return friendlyName

    model = kinoAuthStringValue(deviceInfo.GetModel())
    if model <> "" then return "Roku/" + model

    return "Roku"
end function

function kinoAuthDeviceHardware(deviceInfo as Object) as String
    model = kinoAuthStringValue(deviceInfo.GetModel())
    if model <> "" then return "Roku/" + model

    displayName = kinoAuthStringValue(deviceInfo.GetModelDisplayName())
    if displayName <> "" then return displayName

    return "Roku"
end function

function kinoAuthFormattedOsVersion(osVersion as Dynamic) as String
    if osVersion = invalid or type(osVersion) <> "roAssociativeArray" then return ""
    if osVersion.DoesExist("major") = false then return ""
    if osVersion.DoesExist("minor") = false then return ""
    if osVersion.DoesExist("revision") = false then return ""
    if osVersion.DoesExist("build") = false then return ""

    major = kinoAuthStringValue(osVersion.major)
    minor = kinoAuthStringValue(osVersion.minor)
    revision = kinoAuthStringValue(osVersion.revision)
    build = kinoAuthStringValue(osVersion.build)
    if major = "" or minor = "" or revision = "" or build = "" then return ""

    return major + "." + minor + "." + revision + "-" + build
end function

function kinoAuthAssocStringValue(values as Dynamic, key as String) as String
    if values = invalid or type(values) <> "roAssociativeArray" then return ""

    if values.DoesExist(key) then return kinoAuthStringValue(values[key])

    lowerKey = LCase(key)
    if values.DoesExist(lowerKey) then return kinoAuthStringValue(values[lowerKey])

    return ""
end function

function kinoAuthStringValue(value as Dynamic) as String
    if value = invalid then return ""

    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()

    return ""
end function

function kinoAuthTokensFromResponse(body as Object) as Object
    now = kinoAuthNowSeconds()
    accessExpiresIn = 3600
    if body.DoesExist("expires_in") then accessExpiresIn = body.expires_in

    return {
        accesstoken: body.access_token
        refreshtoken: body.refresh_token
        tokentype: body.token_type
        accessexpiresat: now + accessExpiresIn
        refreshexpiresat: now + (30 * 24 * 60 * 60)
    }
end function

function kinoAuthBaseParams() as Object
    return {
        client_id: m.client.config.clientId
        client_secret: m.client.config.clientSecret
    }
end function

function kinoAuthFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, pending: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function

function kinoAuthNowSeconds() as Integer
    dt = CreateObject("roDateTime")
    return dt.AsSeconds()
end function
