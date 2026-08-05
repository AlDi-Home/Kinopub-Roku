sub init()
    m.instructionLabel = m.top.findNode("instructionLabel")
    m.codeLabel = m.top.findNode("codeLabel")
    m.codeLabel.font.size = 170
    m.statusLabel = m.top.findNode("statusLabel")
    m.progressFill = m.top.findNode("progressFill")
    m.pollTimer = m.top.findNode("pollTimer")
    m.expiryTimer = m.top.findNode("expiryTimer")
    m.requestTimer = m.top.findNode("requestTimer")
    m.pollTimer.observeField("fire", "onPollTimer")
    m.expiryTimer.observeField("fire", "onExpiryTimer")
    m.requestTimer.observeField("fire", "onRequestTimer")

    m.pollInFlight = false
    requestDeviceCode()
end sub

sub requestDeviceCode()
    m.status = "requesting"
    m.statusLabel.text = "Requesting code..."
    m.codeLabel.text = "------"
    m.progressFill.width = 0

    print "AuthScreen: requesting device code"
    task = createAuthTask("requestDeviceCode", {})
    task.observeField("response", "onAuthTaskResponse")
    task.control = "RUN"
    m.authTask = task
    m.requestTimer.control = "start"
end sub

function createAuthTask(command as String, request as Object) as Object
    task = CreateObject("roSGNode", "AuthTask")
    task.command = command
    task.request = request
    return task
end function

sub onAuthTaskResponse(event as Object)
    result = event.getData()
    if result = invalid then return

    if result.command = "requestDeviceCode"
        handleDeviceCodeResult(result)
    else if result.command = "pollDeviceToken"
        handlePollResult(result)
    end if
end sub

sub handleDeviceCodeResult(result as Object)
    m.requestTimer.control = "stop"
    print "AuthScreen: requestDeviceCode response ok="; result.ok; " status="; result.status; " error="; result.error; " message="; result.message; " raw="; authScreenRawSnippet(result)
    if result.ok = true
        m.deviceCode = result.device.code
        m.userCode = result.device.user_code
        m.verificationUri = result.device.verification_uri
        m.interval = result.device.interval
        m.expiresIn = result.device.expires_in
        m.expiresAt = authScreenNowSeconds() + m.expiresIn
        m.codeLabel.text = m.userCode
        m.instructionLabel.text = "Go to " + m.verificationUri + " and enter"
        m.statusLabel.text = "Waiting for confirmation..."
        m.status = "waiting"
        m.pollTimer.duration = m.interval
        m.pollTimer.control = "start"
        m.expiryTimer.control = "start"
    else
        showError(result)
    end if
end sub

sub onRequestTimer()
    print "AuthScreen: requestDeviceCode timed out"
    if m.authTask <> invalid then m.authTask.control = "STOP"
    showError({ ok: false, error: "timeout", message: "Request timed out.", status: 0 })
end sub

sub onPollTimer()
    if m.status <> "waiting" then return
    if m.pollInFlight = true then return
    print "AuthScreen: polling device token"
    m.pollInFlight = true
    task = createAuthTask("pollDeviceToken", { code: m.deviceCode })
    task.observeField("response", "onAuthTaskResponse")
    task.control = "RUN"
    m.pollTask = task
end sub

sub handlePollResult(result as Object)
    m.pollInFlight = false
    print "AuthScreen: pollDeviceToken response ok="; result.ok; " pending="; result.pending; " status="; result.status; " error="; result.error; " message="; result.message; " raw="; authScreenRawSnippet(result)
    if result.ok = true
        m.pollTimer.control = "stop"
        m.expiryTimer.control = "stop"
        m.top.authCompleted = true
    else if result.pending = true
        m.statusLabel.text = "Waiting for confirmation..."
    else
        showError(result)
    end if
end sub

sub onExpiryTimer()
    if m.status <> "waiting" then return
    remaining = m.expiresAt - authScreenNowSeconds()
    if remaining <= 0
        m.pollTimer.control = "stop"
        m.expiryTimer.control = "stop"
        m.status = "expired"
        m.statusLabel.text = "Code expired. Press OK for a new code."
        m.progressFill.width = 0
        return
    end if

    percent = remaining / m.expiresIn
    if percent > 1 then percent = 1
    if percent < 0 then percent = 0
    m.progressFill.width = 640 * percent
end sub

sub showError(result as Object)
    m.pollTimer.control = "stop"
    m.expiryTimer.control = "stop"
    m.status = "error"
    if result.error = "invalid_client" or result.error = "incorrect_client_credentials"
        m.statusLabel.text = "KinoAPI credentials are invalid."
    else if result.error = "timeout"
        m.statusLabel.text = "Request timed out. Press OK to retry."
    else
        m.statusLabel.text = "Unable to sign in. Press OK to retry."
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false
    if key = "OK"
        if m.status = "error" or m.status = "expired"
            requestDeviceCode()
            return true
        end if
    else if key = "back"
        m.pollTimer.control = "stop"
        m.expiryTimer.control = "stop"
        return false
    end if
    return false
end function

function authScreenNowSeconds() as Integer
    dt = CreateObject("roDateTime")
    return dt.AsSeconds()
end function

function authScreenRawSnippet(result as Object) as String
    if result = invalid then return ""
    if not result.DoesExist("rawBody") then return ""
    if result.rawBody = invalid then return ""
    return Left(result.rawBody, 180)
end function
