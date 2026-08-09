function KinoApiClient(config as Object) as Object
    return {
        config: config
        defaultTimeoutMs: 15000
        pollTimeoutMs: 10000
        get: kinoApiGet
        postForm: kinoApiPostForm
        postFormBody: kinoApiPostFormBody
        post: kinoApiPost
        normalizeError: kinoApiNormalizeError
    }
end function

function kinoApiPostForm(path as String, params as Object, timeoutMs = invalid as Dynamic) as Object
    return m.post(path, params, {}, timeoutMs)
end function

function kinoApiPostFormBody(path as String, queryParams as Object, bodyParams as Object, timeoutMs = invalid as Dynamic) as Object
    return m.post(path, queryParams, bodyParams, timeoutMs)
end function

function kinoApiGet(path as String, queryParams as Object, timeoutMs = invalid as Dynamic) as Object
    requestTimeoutMs = timeoutMs
    if requestTimeoutMs = invalid then requestTimeoutMs = m.defaultTimeoutMs

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.RetainBodyOnError(true)

    query = kinoApiEncodeParams(queryParams)
    url = m.config.apiBaseUrl + path
    if query <> "" then url = url + "?" + query
    transfer.SetUrl(url)

    if transfer.AsyncGetToString() <> true
        return { ok: false, status: 0, error: "network", message: "Unable to start request." }
    end if

    msg = wait(requestTimeoutMs, port)
    if msg = invalid
        transfer.AsyncCancel()
        return { ok: false, status: 0, error: "timeout", message: "Request timed out." }
    end if

    status = msg.GetResponseCode()
    body = msg.GetString()
    json = invalid
    looksJson = kinoApiLooksLikeJson(body)
    if looksJson then json = ParseJson(body)
    #if DEV_BUILD
    print "KinoApiClient: response path="; path; " status="; status; " body="; kinoApiBodySnippet(path, body)
    #end if

    if looksJson and json = invalid
        return { ok: false, status: status, error: "invalid_response", message: "KinoAPI returned malformed JSON.", rawBody: body }
    end if

    if status >= 200 and status < 300
        return { ok: true, status: status, body: json, rawBody: body }
    end if

    normalized = m.normalizeError(status, json, body)
    normalized.rawBody = body
    return normalized
end function

function kinoApiPost(path as String, queryParams as Object, bodyParams as Object, timeoutMs = invalid as Dynamic) as Object
    requestTimeoutMs = timeoutMs
    if requestTimeoutMs = invalid then requestTimeoutMs = m.defaultTimeoutMs

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.RetainBodyOnError(true)

    query = kinoApiEncodeParams(queryParams)
    url = m.config.apiBaseUrl + path
    if query <> "" then url = url + "?" + query
    transfer.SetUrl(url)

    body = kinoApiEncodeParams(bodyParams)
    if body <> "" then transfer.AddHeader("Content-Type", "application/x-www-form-urlencoded")

    if transfer.AsyncPostFromString(body) <> true
        return { ok: false, status: 0, error: "network", message: "Unable to start request." }
    end if

    msg = wait(requestTimeoutMs, port)
    if msg = invalid
        transfer.AsyncCancel()
        return { ok: false, status: 0, error: "timeout", message: "Request timed out." }
    end if

    status = msg.GetResponseCode()
    body = msg.GetString()
    json = invalid
    looksJson = kinoApiLooksLikeJson(body)
    if looksJson then json = ParseJson(body)
    #if DEV_BUILD
    print "KinoApiClient: response path="; path; " status="; status; " body="; kinoApiBodySnippet(path, body)
    #end if

    if looksJson and json = invalid
        return { ok: false, status: status, error: "invalid_response", message: "KinoAPI returned malformed JSON.", rawBody: body }
    end if

    if status >= 200 and status < 300
        return { ok: true, status: status, body: json, rawBody: body }
    end if

    normalized = m.normalizeError(status, json, body)
    normalized.rawBody = body
    return normalized
end function

function kinoApiNormalizeError(status as Integer, body as Dynamic, rawBody = "" as String) as Object
    errorCode = "network"
    message = "KinoAPI request failed."

    if status = 401
        errorCode = "unauthorized"
        message = "Device authorization was removed. Sign in again."
    else if status = 502 or status = 503 or status = 504
        errorCode = "server_unavailable"
        message = "KinoPub service is temporarily unavailable. Please try again later."
    else if status = 500
        errorCode = "server_error"
        message = "KinoPub service encountered an error. Please try again later."
    end if

    if body <> invalid and type(body) = "roAssociativeArray"
        if body.DoesExist("error") then errorCode = body.error
        if body.DoesExist("error_description") then message = body.error_description
        if body.DoesExist("message") then message = body.message
    else if rawBody <> invalid and rawBody <> ""
        rawError = kinoApiErrorFromRawBody(rawBody)
        if rawError <> "" then errorCode = rawError
        rawMessage = kinoApiRawJsonValue(rawBody, "error_description")
        if rawMessage = "" then rawMessage = kinoApiRawJsonValue(rawBody, "message")
        if rawMessage <> "" then message = rawMessage
    end if

    return { ok: false, status: status, error: errorCode, message: message }
end function

function kinoApiLooksLikeJson(body as Dynamic) as Boolean
    if body = invalid then return false
    trimmed = body.Trim()
    if trimmed = "" then return false
    firstChar = Left(trimmed, 1)
    return firstChar = "{" or firstChar = "["
end function

' OAuth token-exchange bodies carry access/refresh tokens — never let them
' reach the device log, even in dev builds.
function kinoApiBodySnippet(path as String, body as Dynamic) as String
    if body = invalid then return ""
    if Left(path, 8) = "/oauth2/" then return "[redacted]"
    compact = body.Replace(Chr(10), " ").Replace(Chr(13), " ")
    return Left(compact, 180)
end function

function kinoApiErrorFromRawBody(rawBody as String) as String
    parsedError = kinoApiRawJsonValue(rawBody, "error")
    if parsedError <> "" then return parsedError
    if Instr(1, rawBody, "authorization_pending") > 0 then return "authorization_pending"
    if Instr(1, rawBody, "invalid_client") > 0 then return "invalid_client"
    if Instr(1, rawBody, "invalid_grant") > 0 then return "invalid_grant"
    if Instr(1, rawBody, "expired") > 0 then return "expired"
    if Instr(1, rawBody, "slow_down") > 0 then return "slow_down"
    return ""
end function

function kinoApiRawJsonValue(rawBody as String, key as String) as String
    marker = Chr(34) + key + Chr(34)
    keyIndex = Instr(1, rawBody, marker)
    if keyIndex = 0 then return ""

    colonIndex = Instr(keyIndex + Len(marker), rawBody, ":")
    if colonIndex = 0 then return ""

    valueStart = Instr(colonIndex + 1, rawBody, Chr(34))
    if valueStart = 0 then return ""

    valueEnd = Instr(valueStart + 1, rawBody, Chr(34))
    if valueEnd = 0 then return ""

    return Mid(rawBody, valueStart + 1, valueEnd - valueStart - 1)
end function

function kinoApiEncodeParams(params as Object) as String
    encoded = []
    if params = invalid then return ""
    for each key in params
        value = params[key]
        encoded.Push(kinoApiEscape(key) + "=" + kinoApiEscape(value))
    end for
    return encoded.Join("&")
end function

function kinoApiEscape(value as Dynamic) as String
    raw = kinoApiStringValue(value)
    escaped = ""
    byteArray = CreateObject("roByteArray")
    byteArray.FromAsciiString(raw)

    for index = 0 to byteArray.Count() - 1
        code = byteArray[index]

        if kinoApiIsUnreservedChar(code)
            escaped = escaped + Chr(code)
        else
            escaped = escaped + kinoApiHexByte(code)
        end if
    end for

    return escaped
end function

function kinoApiStringValue(value as Dynamic) as String
    if value = invalid then return ""

    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Boolean" or valueType = "roBoolean"
        if value then return "true"
        return "false"
    end if
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()

    return FormatJson(value)
end function

function kinoApiIsUnreservedChar(code as Integer) as Boolean
    if code >= 65 and code <= 90 then return true
    if code >= 97 and code <= 122 then return true
    if code >= 48 and code <= 57 then return true
    if code = 45 or code = 46 or code = 95 or code = 126 then return true
    return false
end function

function kinoApiHexByte(code as Integer) as String
    high = Int(code / 16)
    low = code - (high * 16)
    hexChars = "0123456789ABCDEF"
    return "%" + Mid(hexChars, high + 1, 1) + Mid(hexChars, low + 1, 1)
end function
