sub init()
    m.screenHost = m.top.findNode("screenHost")
    m.routeFallbackTimer = m.top.findNode("routeFallbackTimer")
    m.routeFallbackTimer.observeField("fire", "onRouteFallbackTimer")
    showLoadingScreen()
    routeFromStoredTokens()
end sub

sub routeFromStoredTokens()
    print "AppScene: starting routeFromStoredTokens"
    task = createAuthTask("routeFromStoredTokens", {})
    task.observeField("response", "onRouteTaskResponse")
    task.control = "RUN"
    m.routeTask = task
    m.routeFallbackTimer.control = "start"
end sub

function createAuthTask(command as String, request as Object) as Object
    task = CreateObject("roSGNode", "AuthTask")
    task.command = command
    task.request = request
    return task
end function

sub onRouteTaskResponse(event as Object)
    m.routeFallbackTimer.control = "stop"
    result = event.getData()
    print "AppScene: routeFromStoredTokens response "; FormatJson(result)
    if result <> invalid and result.screen = "home"
        showContinueScreen()
    else
        showAuthScreen()
    end if
end sub

sub onRouteFallbackTimer()
    print "AppScene: routeFromStoredTokens timed out; showing auth screen"
    if m.routeTask <> invalid then m.routeTask.control = "STOP"
    showAuthScreen()
end sub

sub showAuthScreen()
    clearScreenHost()
    authScreen = CreateObject("roSGNode", "AuthScreen")
    authScreen.observeField("authCompleted", "onAuthCompleted")
    m.screenHost.appendChild(authScreen)
    authScreen.setFocus(true)
end sub

sub showLoadingScreen()
    clearScreenHost()
    loadingScreen = CreateObject("roSGNode", "LoadingScreen")
    m.screenHost.appendChild(loadingScreen)
end sub

function currentMainScreen() as Dynamic
    if m.continueScreen <> invalid and m.continueScreen.visible = true then return m.continueScreen
    if m.homeScreen <> invalid and m.homeScreen.visible = true then return m.homeScreen
    if m.moviesScreen <> invalid and m.moviesScreen.visible = true then return m.moviesScreen
    if m.seriesScreen <> invalid and m.seriesScreen.visible = true then return m.seriesScreen
    if m.libraryScreen <> invalid and m.libraryScreen.visible = true then return m.libraryScreen
    if m.liveScreen <> invalid and m.liveScreen.visible = true then return m.liveScreen
    if m.searchScreen <> invalid and m.searchScreen.visible = true then return m.searchScreen
    return invalid
end function

sub hideCurrentMainScreen()
    screen = currentMainScreen()
    if screen <> invalid then screen.visible = false
end sub

sub showContinueScreen()
    hideCurrentMainScreen()

    if m.continueScreen = invalid
        continueScreen = CreateObject("roSGNode", "ContinueScreen")
        continueScreen.id = "continueScreen"
        continueScreen.observeField("signOutRequested", "onSignOutRequested")
        continueScreen.observeField("authRequired", "onAuthRequired")
        continueScreen.observeField("exitRequested", "onExitRequested")
        continueScreen.observeField("videoSelected", "onVideoSelected")
        continueScreen.observeField("openLegacyHomeSection", "onOpenLegacyHomeSection")
        continueScreen.observeField("openTabScreen", "onOpenTabScreen")
        continueScreen.observeField("openDevFonts", "onOpenDevFonts")
        m.continueScreen = continueScreen
        m.screenHost.appendChild(continueScreen)
    end if
    m.continueScreen.visible = true
    m.continueScreen.setFocus(true)
    m.continueScreen.callFunc("focusContent")
end sub

function ensureBrowseScreen(fieldName as String, contentType as String, navTabId as String) as Object
    if m[fieldName] <> invalid then return m[fieldName]

    screen = CreateObject("roSGNode", "BrowseScreen")
    screen.id = fieldName
    screen.observeField("signOutRequested", "onSignOutRequested")
    screen.observeField("authRequired", "onAuthRequired")
    screen.observeField("exitRequested", "onExitRequested")
    screen.observeField("videoSelected", "onVideoSelected")
    screen.observeField("openLegacyHomeSection", "onOpenLegacyHomeSection")
    screen.observeField("openTabScreen", "onOpenTabScreen")
    screen.observeField("openContinueScreen", "onOpenContinueScreenFromHome")
    screen.observeField("openDevFonts", "onOpenDevFonts")
    screen.callFunc("configure", contentType, navTabId)
    m[fieldName] = screen
    m.screenHost.appendChild(screen)
    return screen
end function

sub showMoviesScreen()
    hideCurrentMainScreen()
    screen = ensureBrowseScreen("moviesScreen", "movie", "movies")
    screen.visible = true
    screen.setFocus(true)
    screen.callFunc("focusContent")
end sub

sub showSeriesScreen()
    hideCurrentMainScreen()
    screen = ensureBrowseScreen("seriesScreen", "serial", "series")
    screen.visible = true
    screen.setFocus(true)
    screen.callFunc("focusContent")
end sub

sub showLibraryScreen()
    hideCurrentMainScreen()
    screen = ensureBrowseScreen("libraryScreen", "", "library")
    screen.visible = true
    screen.setFocus(true)
    screen.callFunc("focusContent")
end sub

sub showLiveScreen()
    hideCurrentMainScreen()

    if m.liveScreen = invalid
        screen = CreateObject("roSGNode", "LiveScreen")
        screen.id = "liveScreen"
        screen.observeField("signOutRequested", "onSignOutRequested")
        screen.observeField("authRequired", "onAuthRequired")
        screen.observeField("exitRequested", "onExitRequested")
        screen.observeField("livePlaybackSelected", "onLivePlaybackSelected")
        screen.observeField("openLegacyHomeSection", "onOpenLegacyHomeSection")
        screen.observeField("openTabScreen", "onOpenTabScreen")
        screen.observeField("openContinueScreen", "onOpenContinueScreenFromHome")
        screen.observeField("openDevFonts", "onOpenDevFonts")
        m.liveScreen = screen
        m.screenHost.appendChild(screen)
    end if
    m.liveScreen.visible = true
    m.liveScreen.setFocus(true)
end sub

sub showSearchScreen()
    hideCurrentMainScreen()

    if m.searchScreen = invalid
        screen = CreateObject("roSGNode", "SearchScreen")
        screen.id = "searchScreen"
        screen.observeField("signOutRequested", "onSignOutRequested")
        screen.observeField("authRequired", "onAuthRequired")
        screen.observeField("exitRequested", "onExitRequested")
        screen.observeField("videoSelected", "onVideoSelected")
        screen.observeField("openLegacyHomeSection", "onOpenLegacyHomeSection")
        screen.observeField("openTabScreen", "onOpenTabScreen")
        screen.observeField("openContinueScreen", "onOpenContinueScreenFromHome")
        screen.observeField("openDevFonts", "onOpenDevFonts")
        m.searchScreen = screen
        m.screenHost.appendChild(screen)
    end if
    m.searchScreen.visible = true
    m.searchScreen.setFocus(true)
    m.searchScreen.callFunc("focusContent")
end sub

sub onOpenTabScreen(event as Object)
    tabId = event.getData()
    if tabId = "movies" then
        showMoviesScreen()
    else if tabId = "series" then
        showSeriesScreen()
    else if tabId = "library" then
        showLibraryScreen()
    else if tabId = "tv" then
        showLiveScreen()
    else if tabId = "search" then
        showSearchScreen()
    end if
end sub

' TEMPORARY: dev-only font picker screen, see DevFontsScreen.xml header comment.
sub onOpenDevFonts(event as Object)
    if event.getData() <> true then return
    m.hiddenForDevFonts = currentMainScreen()
    hideCurrentMainScreen()
    devFontsScreen = CreateObject("roSGNode", "DevFontsScreen")
    devFontsScreen.id = "devFontsScreen"
    devFontsScreen.observeField("closeRequested", "onDevFontsClosed")
    m.devFontsScreen = devFontsScreen
    m.screenHost.appendChild(devFontsScreen)
    devFontsScreen.setFocus(true)
end sub

sub onDevFontsClosed(event as Object)
    if event.getData() <> true then return
    if m.devFontsScreen <> invalid
        removeScreenHostChild("devFontsScreen")
        m.devFontsScreen = invalid
    end if
    if m.hiddenForDevFonts <> invalid
        m.hiddenForDevFonts.visible = true
        m.hiddenForDevFonts.setFocus(true)
        m.hiddenForDevFonts = invalid
    else if m.continueScreen <> invalid
        m.continueScreen.visible = true
        m.continueScreen.setFocus(true)
    end if
end sub

sub onOpenLegacyHomeSection(event as Object)
    section = event.getData()
    if section = invalid or section = "" then return
    showHomeScreen(section)
end sub

sub showHomeScreen(initialSection = "home" as String)
    hideCurrentMainScreen()

    if m.homeScreen = invalid
        homeScreen = CreateObject("roSGNode", "HomeScreen")
        homeScreen.id = "homeScreen"
        homeScreen.initialSection = initialSection
        homeScreen.observeField("signOutRequested", "onSignOutRequested")
        homeScreen.observeField("authRequired", "onAuthRequired")
        homeScreen.observeField("exitRequested", "onExitRequested")
        homeScreen.observeField("videoSelected", "onVideoSelected")
        homeScreen.observeField("livePlaybackSelected", "onLivePlaybackSelected")
        homeScreen.observeField("openContinueScreen", "onOpenContinueScreenFromHome")
        m.homeScreen = homeScreen
        m.screenHost.appendChild(homeScreen)
    end if
    m.homeScreen.visible = true
    m.homeScreen.setFocus(true)
end sub

sub onOpenContinueScreenFromHome(event as Object)
    if event.getData() <> true then return
    showContinueScreen()
end sub

sub onLivePlaybackSelected(event as Object)
    playback = event.getData()
    if playback = invalid or playback.streamUrl = invalid or playback.streamUrl = "" then return
    showPlayerScreen(playback)
end sub

sub showVideoDetailScreen(selection as Object)
    m.hiddenMainScreen = currentMainScreen()
    if m.hiddenMainScreen <> invalid
        m.hiddenMainScreen.visible = false
    else if m.homeScreen = invalid and m.continueScreen = invalid and m.moviesScreen = invalid and m.seriesScreen = invalid and m.libraryScreen = invalid and m.liveScreen = invalid and m.searchScreen = invalid
        clearScreenHost()
    end if
    detailScreen = CreateObject("roSGNode", "VideoDetailScreen")
    detailScreen.id = "detailScreen"
    detailScreen.selection = selection
    detailScreen.observeField("backRequested", "onVideoDetailBackRequested")
    detailScreen.observeField("authRequired", "onAuthRequired")
    detailScreen.observeField("playbackRequested", "onPlaybackRequested")
    detailScreen.observeField("nextPlayback", "onVideoDetailNextPlayback")
    m.detailScreen = detailScreen
    m.screenHost.appendChild(detailScreen)
    detailScreen.setFocus(true)
end sub

sub onVideoSelected(event as Object)
    selection = event.getData()
    if selection = invalid or selection.itemId = invalid or selection.itemId <= 0 then return
    detailSelection = {
        itemId: selection.itemId
        mediaId: 0
    }
    if selection.mediaId <> invalid then detailSelection.mediaId = selection.mediaId
    if selection.DoesExist("source") then detailSelection.source = selection.source
    if selection.DoesExist("watchCount") then detailSelection.watchCount = selection.watchCount
    if selection.DoesExist("firstSeenSeconds") then detailSelection.firstSeenSeconds = selection.firstSeenSeconds
    if selection.DoesExist("lastSeenSeconds") then detailSelection.lastSeenSeconds = selection.lastSeenSeconds
    if selection.DoesExist("targetSeasonNumber") then detailSelection.targetSeasonNumber = selection.targetSeasonNumber
    if selection.DoesExist("targetEpisodeNumber") then detailSelection.targetEpisodeNumber = selection.targetEpisodeNumber
    if selection.DoesExist("seasonNumber") then detailSelection.seasonNumber = selection.seasonNumber
    if selection.DoesExist("episodeNumber") then detailSelection.episodeNumber = selection.episodeNumber
    showVideoDetailScreen(detailSelection)
end sub

sub onVideoDetailBackRequested(event as Object)
    if event.getData() = true then restoreHomeScreen()
end sub

sub onPlaybackRequested(event as Object)
    playback = event.getData()
    if playback = invalid or playback.streamUrl = invalid or playback.streamUrl = "" then return
    showPlayerScreen(playback)
end sub

sub showPlayerScreen(playback as Object)
    if m.detailScreen <> invalid then m.detailScreen.visible = false
    playerScreen = CreateObject("roSGNode", "PlayerScreen")
    playerScreen.id = "playerScreen"
    playerScreen.observeField("exitRequested", "onPlayerExitRequested")
    playerScreen.observeField("playbackError", "onPlayerPlaybackError")
    playerScreen.observeField("nextPlaybackRequested", "onPlayerNextPlaybackRequested")
    m.playerScreen = playerScreen
    m.screenHost.appendChild(playerScreen)
    playerScreen.playback = playback
    playerScreen.setFocus(true)
end sub

sub onPlayerExitRequested(event as Object)
    if event.getData() <> true then return
    closePlayerScreen()
end sub

sub onPlayerPlaybackError(event as Object)
    message = event.getData()
    if m.detailScreen <> invalid and message <> invalid and message <> "" then m.detailScreen.playbackError = message
end sub

sub onPlayerNextPlaybackRequested(event as Object)
    request = event.getData()
    if m.detailScreen = invalid
        if m.playerScreen <> invalid then m.playerScreen.nextPlayback = { ok: false, message: "No video details are available." }
        return
    end if

    m.detailScreen.nextPlaybackRequested = request
end sub

sub onVideoDetailNextPlayback(event as Object)
    nextPlayback = event.getData()
    if m.playerScreen <> invalid then m.playerScreen.nextPlayback = nextPlayback
end sub

sub closePlayerScreen()
    if m.playerScreen <> invalid
        removeScreenHostChild("playerScreen")
        m.playerScreen = invalid
    end if
    if m.detailScreen <> invalid
        m.detailScreen.visible = true
        m.detailScreen.setFocus(true)
        m.detailScreen.reloadRequested = true
    else if m.hiddenMainScreen <> invalid
        m.hiddenMainScreen.visible = true
        m.hiddenMainScreen.setFocus(true)
        m.hiddenMainScreen = invalid
    else if m.continueScreen <> invalid
        m.continueScreen.visible = true
        m.continueScreen.setFocus(true)
    else if m.homeScreen <> invalid
        m.homeScreen.visible = true
        m.homeScreen.setFocus(true)
    else if m.moviesScreen <> invalid
        m.moviesScreen.visible = true
        m.moviesScreen.setFocus(true)
    else if m.seriesScreen <> invalid
        m.seriesScreen.visible = true
        m.seriesScreen.setFocus(true)
    else if m.libraryScreen <> invalid
        m.libraryScreen.visible = true
        m.libraryScreen.setFocus(true)
    else if m.liveScreen <> invalid
        m.liveScreen.visible = true
        m.liveScreen.setFocus(true)
    else if m.searchScreen <> invalid
        m.searchScreen.visible = true
        m.searchScreen.setFocus(true)
    end if
end sub

sub restoreHomeScreen()
    if m.playerScreen <> invalid
        removeScreenHostChild("playerScreen")
        m.playerScreen = invalid
    end if
    if m.detailScreen <> invalid
        removeScreenHostChild("detailScreen")
        m.detailScreen = invalid
    end if

    if m.hiddenMainScreen <> invalid
        m.hiddenMainScreen.visible = true
        m.hiddenMainScreen.setFocus(true)
        m.hiddenMainScreen = invalid
    else if m.continueScreen <> invalid
        m.continueScreen.visible = true
        m.continueScreen.setFocus(true)
    else if m.homeScreen <> invalid
        m.homeScreen.visible = true
        m.homeScreen.setFocus(true)
    else if m.moviesScreen <> invalid
        m.moviesScreen.visible = true
        m.moviesScreen.setFocus(true)
    else if m.seriesScreen <> invalid
        m.seriesScreen.visible = true
        m.seriesScreen.setFocus(true)
    else if m.libraryScreen <> invalid
        m.libraryScreen.visible = true
        m.libraryScreen.setFocus(true)
    else if m.liveScreen <> invalid
        m.liveScreen.visible = true
        m.liveScreen.setFocus(true)
    else if m.searchScreen <> invalid
        m.searchScreen.visible = true
        m.searchScreen.setFocus(true)
    else
        showContinueScreen()
    end if
end sub

function removeScreenHostChild(childId as String) as Boolean
    if childId = invalid or childId = "" then return false
    for index = 0 to m.screenHost.getChildCount() - 1
        child = m.screenHost.getChild(index)
        if child <> invalid and child.id = childId
            m.screenHost.removeChild(child)
            return true
        end if
    end for
    return false
end function

sub clearScreenHost()
    m.homeScreen = invalid
    m.continueScreen = invalid
    m.moviesScreen = invalid
    m.seriesScreen = invalid
    m.libraryScreen = invalid
    m.liveScreen = invalid
    m.searchScreen = invalid
    m.hiddenMainScreen = invalid
    m.hiddenForDevFonts = invalid
    m.detailScreen = invalid
    m.playerScreen = invalid
    childCount = m.screenHost.getChildCount()
    if childCount > 0 then m.screenHost.removeChildrenIndex(childCount, 0)
end sub

sub onAuthCompleted(event as Object)
    if event.getData() = true then showContinueScreen()
end sub

sub onSignOutRequested(event as Object)
    if event.getData() = true
        task = createAuthTask("clearTokens", {})
        task.observeField("response", "onClearTokensResponse")
        task.control = "RUN"
        m.clearTokensTask = task
    end if
end sub

sub onAuthRequired(event as Object)
    if event.getData() <> true then return
    task = createAuthTask("clearTokens", {})
    task.observeField("response", "onClearTokensResponse")
    task.control = "RUN"
    m.clearTokensTask = task
end sub

sub onExitRequested(event as Object)
    if event.getData() = true then m.top.exitRequested = true
end sub

sub onClearTokensResponse()
    showAuthScreen()
end sub
