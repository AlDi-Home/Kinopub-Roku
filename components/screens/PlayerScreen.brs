sub init()
    m.videoNode = m.top.findNode("videoNode")
    m.videoNode.enableUI = false
    configureVideoHttpAgent()
    m.streamLoaderGroup = m.top.findNode("streamLoaderGroup")
    m.streamLoaderTitleLabel = m.top.findNode("streamLoaderTitleLabel")
    m.streamLoaderPercentLabel = m.top.findNode("streamLoaderPercentLabel")
    m.streamLoaderFill = m.top.findNode("streamLoaderFill")
    m.resumePromptGroup = m.top.findNode("resumePromptGroup")
    m.resumePromptMessageLabel = m.top.findNode("resumePromptMessageLabel")
    m.resumePromptOptionsHost = m.top.findNode("resumePromptOptionsHost")
    m.resumePromptCountdownLabel = m.top.findNode("resumePromptCountdownLabel")
    m.bottomRailGroup = m.top.findNode("bottomRailGroup")
    m.bottomRailBackground = m.top.findNode("bottomRailBackground")
    m.titleLabel = m.top.findNode("titleLabel")
    m.timeLabel = m.top.findNode("timeLabel")
    m.seasonCarouselGroup = m.top.findNode("seasonCarouselGroup")
    m.seasonCarouselTitleLabel = m.top.findNode("seasonCarouselTitleLabel")
    m.seasonCarouselHost = m.top.findNode("seasonCarouselHost")
    m.seasonCarouselLeftChevron = m.top.findNode("seasonCarouselLeftChevron")
    m.seasonCarouselRightChevron = m.top.findNode("seasonCarouselRightChevron")
    m.seasonCarouselStatusLabel = m.top.findNode("seasonCarouselStatusLabel")
    m.progressFocus = m.top.findNode("progressFocus")
    m.progressTrack = m.top.findNode("progressTrack")
    m.progressFill = m.top.findNode("progressFill")
    m.controlsHost = m.top.findNode("controlsHost")
    m.focusCursor = m.top.findNode("focusCursor")
    m.menuPopover = m.top.findNode("menuPopover")
    m.menuBackground = m.top.findNode("menuBackground")
    m.menuTitleLabel = m.top.findNode("menuTitleLabel")
    m.menuItemsHost = m.top.findNode("menuItemsHost")
    m.statusLabel = m.top.findNode("statusLabel")
    m.statsOverlayGroup = m.top.findNode("statsOverlayGroup")
    m.statsOverlayLinesHost = m.top.findNode("statsOverlayLinesHost")
    m.railHideTimer = m.top.findNode("railHideTimer")
    m.progressTimer = m.top.findNode("progressTimer")
    m.statusClearTimer = m.top.findNode("statusClearTimer")
    m.resumePromptTimer = m.top.findNode("resumePromptTimer")
    m.nextEpisodePromptGroup = m.top.findNode("nextEpisodePromptGroup")
    m.nextEpisodePromptMessageLabel = m.top.findNode("nextEpisodePromptMessageLabel")
    m.nextEpisodePromptOptionsHost = m.top.findNode("nextEpisodePromptOptionsHost")
    m.nextEpisodePromptCountdownLabel = m.top.findNode("nextEpisodePromptCountdownLabel")
    m.nextEpisodeCountdownTimer = m.top.findNode("nextEpisodeCountdownTimer")
    m.bufferingDebounceTimer = m.top.findNode("bufferingDebounceTimer")
    m.seekDebounceTimer = m.top.findNode("seekDebounceTimer")
    m.seekSettleTimer = m.top.findNode("seekSettleTimer")
    m.statsOverlayTimer = m.top.findNode("statsOverlayTimer")
    m.startOverPromptGroup = m.top.findNode("startOverPromptGroup")
    m.startOverPromptOptionsHost = m.top.findNode("startOverPromptOptionsHost")
    m.startOverPromptTimer = m.top.findNode("startOverPromptTimer")

    m.playback = invalid
    m.preferences = {}
    m.preferenceStore = PlayerPreferenceStore()
    m.controls = []
    m.controlNodes = []
    ' Icon row baseline: controlsHost/focusCursor both start at x=900 (see
    ' applyBottomRailLayout) — icons cluster toward the right of the rail,
    ' unlike the old wide text-label row which started at the left (x=72).
    m.controlPositions = [900, 964, 1028, 1092]
    m.controlSpacing = 64
    m.controlFocusY = 234
    m.statsOverlayVisible = false
    m.pendingResumeSeekPosition = 0
    m.focusArea = "controls"
    m.focusIndex = 0
    m.menuOpen = false
    m.menuType = ""
    m.menuItems = []
    m.menuIndex = 0
    m.menuScrollStart = 0
    m.maxVisibleMenuItems = 6
    m.resumePromptOpen = false
    m.resumePromptIndex = 0
    m.resumeStartPosition = 0
    m.resumeCountdownSeconds = 15
    m.resumePromptOptionNodes = []
    m.nextEpisodePromptOpen = false
    m.nextEpisodePromptIndex = 0
    m.nextEpisodePromptRemainingSeconds = 10
    m.nextEpisodePromptPlayback = invalid
    m.nextEpisodeRequestPending = false
    m.nextEpisodeRequested = false
    m.nextEpisodeRequestReason = ""
    m.nextEpisodePromptOptionNodes = []
    m.isPlaying = false
    m.playbackStarted = false
    m.savedAudioPreferenceApplied = false
    m.lastSavedSeconds = -1
    m.completed = false
    m.seekStepSeconds = 30
    m.seekPending = false
    m.pendingSeekPosition = invalid
    m.playbackOptions = []
    m.playbackOptionIndex = 0
    m.seasonEpisodes = []
    m.seasonCarouselCards = []
    m.seasonCarouselFocusIndex = 0
    m.seasonCarouselVisibleStart = 0
    m.maxVisibleSeasonCarouselItems = 6
    m.seasonCarouselRequestPending = false
    m.startOverPromptOpen = false
    m.startOverPromptIndex = 0
    m.startOverPromptOptions = []
    m.startOverPromptOptionNodes = []

    m.top.observeField("playback", "onPlaybackChanged")
    m.top.observeField("nextPlayback", "onNextPlaybackChanged")
    m.videoNode.observeField("state", "onVideoStateChanged")
    m.videoNode.observeField("position", "onVideoPositionChanged")
    m.videoNode.observeField("bufferingStatus", "onVideoBufferingStatusChanged")
    m.videoNode.observeField("downloadedSegment", "onVideoDownloadedSegmentChanged")
    m.videoNode.observeField("streamingSegment", "onVideoStreamingSegmentChanged")
    m.videoNode.observeField("availableAudioTracks", "onAvailableAudioTracksChanged")
    m.videoNode.observeField("availableSubtitleTracks", "onAvailableSubtitleTracksChanged")
    m.railHideTimer.observeField("fire", "onRailHideTimer")
    m.progressTimer.observeField("fire", "onProgressTimer")
    m.statusClearTimer.observeField("fire", "onStatusClearTimer")
    m.resumePromptTimer.observeField("fire", "onResumePromptTimer")
    m.nextEpisodeCountdownTimer.observeField("fire", "onNextEpisodeCountdownTimer")
    m.bufferingDebounceTimer.observeField("fire", "onBufferingDebounceTimer")
    m.seekDebounceTimer.observeField("fire", "onSeekDebounceTimer")
    m.seekSettleTimer.observeField("fire", "onSeekSettleTimer")
    m.statsOverlayTimer.observeField("fire", "onStatsOverlayTimer")
    m.startOverPromptTimer.observeField("fire", "onStartOverPromptTimer")
    m.top.setFocus(true)
end sub

sub configureVideoHttpAgent()
    if m.videoNode = invalid then return

    m.videoHttpAgent = CreateObject("roHttpAgent")
    m.videoHttpAgent.AddHeader("User-Agent", "Roku/DVP-12.0 (12.0.0.0)")
    if m.videoNode.setHttpAgent(m.videoHttpAgent) <> true
        print "PlayerScreen: failed to attach video HTTP agent"
    end if
end sub

sub onPlaybackChanged(event as Object)
    m.playback = event.getData()
    if m.playback = invalid
        resetNextEpisodeState()
        resetSeasonCarouselState()
        if m.focusArea = "seasonCarousel" then m.focusArea = "controls"
        renderSeasonCarousel()
        applyBottomRailLayout()
        updateFocusCursor()
        return
    end if

    resetNextEpisodeState()
    m.pendingResumeSeekPosition = 0
    m.preferences = m.preferenceStore.load(m.playback)
    m.titleLabel.text = playbackTitle()
    m.progressTrack.visible = isLivePlayback() <> true
    m.progressFill.visible = isLivePlayback() <> true
    buildSeasonCarouselFromPlayback()
    buildControls()
    showRail()
    updateProgressVisuals()
    startPlayback()
end sub

sub resetNextEpisodeState()
    m.nextEpisodePromptOpen = false
    m.nextEpisodePromptIndex = 0
    m.nextEpisodePromptRemainingSeconds = 10
    m.nextEpisodePromptPlayback = invalid
    m.nextEpisodeRequestPending = false
    m.nextEpisodeRequested = false
    m.nextEpisodeRequestReason = ""
    if m.nextEpisodePromptGroup <> invalid then m.nextEpisodePromptGroup.visible = false
    if m.nextEpisodeCountdownTimer <> invalid then m.nextEpisodeCountdownTimer.control = "stop"
    m.startOverPromptOpen = false
    if m.startOverPromptGroup <> invalid then m.startOverPromptGroup.visible = false
    if m.startOverPromptTimer <> invalid then m.startOverPromptTimer.control = "stop"
end sub

sub onNextPlaybackChanged(event as Object)
    response = event.getData()
    if m.seasonCarouselRequestPending = true
        if response = invalid or response.reason <> "seasonCarousel"
            m.nextEpisodeRequestPending = false
            m.nextEpisodeRequested = false
            m.nextEpisodeRequestReason = ""
            return
        end if
    end if

    m.nextEpisodeRequestPending = false
    m.seasonCarouselRequestPending = false

    if response = invalid or response.ok <> true or response.playback = invalid
        if m.nextEpisodeRequestReason = "finished"
            markCompletedIfSafe()
            exitPlayer()
        else if m.nextEpisodeRequestReason = "manualNext"
            setStatusMessage("Следующая серия недоступна", true)
        end if
        return
    end if

    if response.reason = "seasonCarousel" or response.reason = "manualNext"
        startNextPlayback(response.playback)
    else
        showNextEpisodePrompt(response.playback)
    end if
end sub

function playbackTitle() as String
    if m.playback = invalid then return ""
    title = ""
    if m.playback.title <> invalid then title = m.playback.title
    itemTitle = ""
    if m.playback.itemTitle <> invalid then itemTitle = m.playback.itemTitle
    subtitle = ""
    if m.playback.subtitle <> invalid then subtitle = m.playback.subtitle

    if itemTitle <> "" and (title = "" or title = "Video")
        title = itemTitle
    else if itemTitle <> "" and title <> itemTitle
        title = itemTitle + " - " + title
    end if

    if subtitle <> "" and subtitle <> title then return title + " - " + subtitle
    return title
end function

sub startPlayback()
    if m.playback = invalid then return
    if m.playback.streamUrl = invalid or m.playback.streamUrl = ""
        m.top.playbackError = "No playable video is available."
        m.top.exitRequested = true
        return
    end if

    m.playbackOptions = playbackStreamOptions()
    m.playbackOptionIndex = bestQualityOptionIndex(m.playbackOptions)
    if m.preferences = invalid then m.preferences = {}
    bestStream = currentPlaybackStream()
    m.preferences["qualityId"] = bestStream.id
    m.preferences["qualityUrl"] = bestStream.url
    applySavedQualityPreference()
    m.savedAudioPreferenceApplied = false
    logPlaybackStart()
    content = playbackContentNode(savedPreferredSubtitleTrackNameForPlayback())
    m.videoNode.content = content
    startPosition = resumeStartSeconds()
    if startPosition > 0
        showResumePrompt(startPosition)
        return
    end if
    startPlaybackAtPosition(0)
end sub

function autoApplySavedPlaybackPreferencesEnabled() as Boolean
    return false
end function

function autoApplySavedAudioPreferenceEnabled() as Boolean
    return true
end function

' Unlike quality (always the algorithmic best-available pick, never
' remembered) and unlike the still-disabled shared flag above, subtitle
' track choice is remembered the same way audio already is — via
' PlayerPreferenceStore.brs's series+episode key merge, so a track picked on
' one episode carries to the next episode of the same serial.
function autoApplySavedSubtitlePreferenceEnabled() as Boolean
    return true
end function

function savedPreferredSubtitleTrackNameForPlayback() as String
    if autoApplySavedSubtitlePreferenceEnabled() <> true then return ""
    return savedPreferredSubtitleTrackName()
end function

function playbackContentNode(preferredSubtitleTrackName as String) as Object
    stream = currentPlaybackStream()
    content = CreateObject("roSGNode", "ContentNode")
    content.url = stream.url
    content.title = playbackTitle()
    content.HttpHeaders = ["User-Agent: Roku/DVP-12.0 (12.0.0.0)"]
    subtitleTracks = contentSubtitleTracksForPreferred(preferredSubtitleTrackName)
    if subtitleTracks.Count() > 0 then content.SubtitleTracks = subtitleTracks
    if preferredSubtitleTrackName <> "" then content.SubtitleConfig = { TrackName: preferredSubtitleTrackName }
    content.streamFormat = "hls"

    return content
end function

' Quality options (which include the real id="auto" entry, when
' KinoItemService.brs resolved one) are added BEFORE the "default" entry —
' m.playback.streamUrl is almost always the exact same URL as the "auto"
' option's, and addPlaybackStreamOption dedupes by URL, so whichever gets
' added first claims that URL's single surviving option. Adding "default"
' first (as this used to) meant "auto" always lost that race and never
' actually appeared in m.playbackOptions, silently breaking
' bestQualityOptionIndex's "prefer Auto" tier — it never saw an "auto" id to
' prefer, even though the UI's own qualityMenuItems()/selectedQualityLabel()
' (built from m.playback.qualityOptions directly, not m.playbackOptions)
' still showed "Auto" by coincidental URL match. "default" now only adds
' something when quality options didn't already cover that URL/didn't exist.
function playbackStreamOptions() as Object
    options = []
    seen = {}
    if m.playback = invalid then return options

    if m.playback.qualityOptions <> invalid
        for each option in m.playback.qualityOptions
            if option <> invalid
                label = trackLabel(option)
                if label = "" then label = "Fallback " + StrI(options.Count() + 1).Trim()
                id = menuItemId(option)
                if id = "" then id = label
                streamFormat = "hls"
                if option.streamFormat <> invalid then streamFormat = option.streamFormat
                addPlaybackStreamOption(options, seen, id, label, option.url, streamFormat)
            end if
        end for
    end if
    addPlaybackStreamOption(options, seen, "default", "Default", m.playback.streamUrl, m.playback.streamFormat)

    return options
end function

' Picks the highest-priority option to start playback on, instead of always
' the first ("default") entry. "Auto" (the server-resolved HLS stream,
' KinoItemService.brs's kinoItemQualityOptions id="auto") is preferred above
' everything when available; otherwise falls back to KinoItemService.brs's
' own hlsKeys = ["hls4", "hls2", "hls"] priority (that list itself is
' untouched; this just makes PlayerScreen actually start on the option that
' order would prefer, rather than only reaching it via the on-failure
' fallback path). HTTP/mp4 direct-file streaming is never offered as an
' option at all (see KinoItemService.brs), so there's no tier for it here.
' Never remembered as a preference — this always runs, on every playback
' start.
function qualityOptionTier(option as Object) as Integer
    if option.id = "auto" then return 0
    haystack = LCase(option.id + " " + option.label)
    if Instr(1, haystack, "hls4") > 0 then return 1
    if Instr(1, haystack, "hls2") > 0 then return 2
    return 3
end function

function bestQualityOptionIndex(options as Object) as Integer
    if options = invalid or options.Count() = 0 then return 0

    bestIndex = 0
    bestTier = qualityOptionTier(options[0])
    for index = 1 to options.Count() - 1
        tier = qualityOptionTier(options[index])
        if tier < bestTier
            bestTier = tier
            bestIndex = index
        end if
    end for
    return bestIndex
end function

sub addPlaybackStreamOption(options as Object, seen as Object, id as String, label as String, url as Dynamic, streamFormat as Dynamic)
    if url = invalid or url = "" then return
    if seen.DoesExist(url) then return

    ' Every upstream caller now supplies "hls" explicitly (KinoItemService.brs
    ' is HLS-only) — this default only matters if a caller ever omits
    ' streamFormat, and stays "hls" rather than "mp4"/http to match.
    format = "hls"
    if streamFormat <> invalid and streamFormat <> "" then format = streamFormat
    options.Push({
        id: id
        label: label
        url: url
        streamFormat: format
    })
    seen[url] = true

    directMediaPlaylistUrl = hlsDirectMediaPlaylistUrl(url)
    if format = "hls" and directMediaPlaylistUrl <> "" and not seen.DoesExist(directMediaPlaylistUrl)
        options.Push({
            id: id + "-media"
            label: label + " media"
            url: directMediaPlaylistUrl
            streamFormat: "hls"
        })
        seen[directMediaPlaylistUrl] = true
    end if
end sub

function hlsDirectMediaPlaylistUrl(url as String) as String
    marker = "master-v"
    extension = ".m3u8"
    markerPosition = Instr(1, url, marker)
    if markerPosition = 0 then return ""

    streamIdStart = markerPosition + Len(marker)
    streamIdEnd = Instr(streamIdStart, url, extension)
    if streamIdEnd = 0 then return ""

    streamId = Mid(url, streamIdStart, streamIdEnd - streamIdStart)
    audioMarkerPosition = Instr(1, streamId, "a")
    if audioMarkerPosition <= 1 then return ""
    if audioMarkerPosition >= Len(streamId) then return ""

    videoId = Left(streamId, audioMarkerPosition - 1)
    audioId = Mid(streamId, audioMarkerPosition + 1)
    directName = "index-v" + videoId + "-a" + audioId + extension
    return Left(url, markerPosition - 1) + directName + Mid(url, streamIdEnd + Len(extension))
end function

function currentPlaybackStream() as Object
    if m.playbackOptions <> invalid and m.playbackOptionIndex >= 0 and m.playbackOptionIndex < m.playbackOptions.Count()
        return m.playbackOptions[m.playbackOptionIndex]
    end if

    if m.playback <> invalid
        return {
            id: "default"
            label: "Default"
            url: m.playback.streamUrl
            streamFormat: m.playback.streamFormat
        }
    end if

    return { id: "default", label: "Default", url: "", streamFormat: "hls" }
end function

sub logPlaybackStart()
    streamUrl = ""
    streamFormat = ""
    title = ""
    mediaId = 0
    itemId = 0
    stream = currentPlaybackStream()
    if m.playback <> invalid
        if m.playback.title <> invalid then title = m.playback.title
        if m.playback.mediaId <> invalid then mediaId = m.playback.mediaId
        if m.playback.itemId <> invalid then itemId = m.playback.itemId
    end if
    if stream.url <> invalid then streamUrl = stream.url
    if stream.streamFormat <> invalid then streamFormat = stream.streamFormat

    print "PlayerScreen: start playback itemId="; itemId; " mediaId="; mediaId; " title="; title
    print "PlayerScreen: stream option="; StrI(m.playbackOptionIndex + 1).Trim(); "/"; StrI(m.playbackOptions.Count()).Trim(); " label="; stream.label
    print "PlayerScreen: stream format="; streamFormat; " url="; playbackDiagnosticRedactedUrl(streamUrl)
end sub

' Setting m.videoNode.seek here, before playback has actually started,
' doesn't reliably take effect — the exact same Roku timing quirk already
' documented/worked around for audio-track preference (applySavedAudioPreference
' is deliberately NOT called from this sub, only once state="playing" fires
' in onVideoStateChanged; see player-audio-selection.sh's explicit check for
' that). The resume seek now follows the same pattern: stash it and apply it
' once state actually reaches "playing".
sub startPlaybackAtPosition(startPosition as Integer)
    m.playbackStarted = false
    m.pendingResumeSeekPosition = startPosition
    m.top.setFocus(true)
    showStreamLoader("Loading stream")
    m.videoNode.control = "play"
    m.isPlaying = true
    if isLivePlayback() <> true
        m.progressTimer.control = "start"
        sendProgressUpdate("start")
    end if
end sub

sub showResumePrompt(startPosition as Integer)
    m.resumeStartPosition = startPosition
    m.resumePromptOpen = true
    m.resumePromptIndex = 0
    m.resumeCountdownSeconds = 15
    m.resumePromptMessageLabel.text = "Продолжить с " + formatTime(startPosition) + "?"
    renderResumePromptOptions()
    updateResumePromptCountdown()
    m.bottomRailGroup.visible = false
    m.resumePromptGroup.visible = true
    m.resumePromptTimer.control = "start"
end sub

' index 0 = "Да" (resume from the saved position) is rendered on the RIGHT,
' index 1 = "Нет" (start over) on the LEFT — matching the reference layout.
' handleResumePromptKey() maps Left/Right to this same left-to-right visual
' order (not to raw index order), and the auto-resume countdown
' (onResumePromptTimer) always lands on index 0/"Да" either way.
sub renderResumePromptOptions()
    childCount = m.resumePromptOptionsHost.getChildCount()
    if childCount > 0 then m.resumePromptOptionsHost.removeChildrenIndex(childCount, 0)
    m.resumePromptOptionNodes = []

    labels = ["Да", "Нет"]
    buttonWidth = 140
    buttonHeight = 48
    gap = 20
    xForIndex = [buttonWidth + gap, 0]

    for index = 0 to labels.Count() - 1
        group = CreateObject("roSGNode", "Group")
        group.translation = [xForIndex[index], 0]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = buttonWidth
        bg.height = buttonHeight
        bg.color = "#4B5563"
        if index = m.resumePromptIndex then bg.color = "#F9FAFB"
        group.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.translation = [0, 14]
        label.width = buttonWidth
        label.horizAlign = "center"
        label.text = labels[index]
        label.color = "#E5E7EB"
        if index = m.resumePromptIndex then label.color = "#111827"
        group.appendChild(label)

        m.resumePromptOptionsHost.appendChild(group)
        m.resumePromptOptionNodes.Push(group)
    end for
end sub

sub updateResumePromptCountdown()
    m.resumePromptCountdownLabel.text = "Auto-resume in " + StrI(m.resumeCountdownSeconds).Trim() + " sec"
end sub

sub showNextEpisodePrompt(playback as Object)
    if playback = invalid then return

    m.nextEpisodePromptPlayback = playback
    m.nextEpisodePromptOpen = true
    m.nextEpisodePromptIndex = 0
    m.nextEpisodePromptRemainingSeconds = 10

    title = "Next episode"
    if playback.title <> invalid and playback.title <> "" then title = playback.title
    m.nextEpisodePromptMessageLabel.text = title
    renderNextEpisodePromptOptions()
    updateNextEpisodePromptCountdown()
    m.bottomRailGroup.visible = false
    m.nextEpisodePromptGroup.visible = true
    m.nextEpisodeCountdownTimer.control = "start"
end sub

sub renderNextEpisodePromptOptions()
    childCount = m.nextEpisodePromptOptionsHost.getChildCount()
    if childCount > 0 then m.nextEpisodePromptOptionsHost.removeChildrenIndex(childCount, 0)
    m.nextEpisodePromptOptionNodes = []

    labels = ["Play next now", "Keep watching"]
    for index = 0 to labels.Count() - 1
        group = CreateObject("roSGNode", "Group")
        group.translation = [0, index * 58]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = 440
        bg.height = 46
        bg.color = "#374151"
        if index = m.nextEpisodePromptIndex then bg.color = "#E5E7EB"
        group.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.translation = [18, 12]
        label.width = 404
        label.text = labels[index]
        label.color = "#D1D5DB"
        if index = m.nextEpisodePromptIndex then label.color = "#111827"
        group.appendChild(label)

        m.nextEpisodePromptOptionsHost.appendChild(group)
        m.nextEpisodePromptOptionNodes.Push(group)
    end for
end sub

sub updateNextEpisodePromptCountdown()
    m.nextEpisodePromptCountdownLabel.text = "Auto-play in " + StrI(m.nextEpisodePromptRemainingSeconds).Trim() + " sec"
end sub

sub closeNextEpisodePrompt()
    m.nextEpisodePromptOpen = false
    m.nextEpisodePromptPlayback = invalid
    m.nextEpisodeCountdownTimer.control = "stop"
    m.nextEpisodePromptGroup.visible = false
    if m.isPlaying then showRail()
end sub

sub onNextEpisodeCountdownTimer()
    if m.nextEpisodePromptOpen <> true then return

    m.nextEpisodePromptRemainingSeconds = m.nextEpisodePromptRemainingSeconds - 1
    if m.nextEpisodePromptRemainingSeconds <= 0
        chooseNextEpisodePromptOption(0)
    else
        updateNextEpisodePromptCountdown()
    end if
end sub

function handleNextEpisodePromptKey(key as String) as Boolean
    if key = "back"
        chooseNextEpisodePromptOption(1)
        return true
    else if key = "up" or key = "down"
        if m.nextEpisodePromptIndex = 0 then m.nextEpisodePromptIndex = 1 else m.nextEpisodePromptIndex = 0
        renderNextEpisodePromptOptions()
        return true
    else if key = "OK" or key = "play"
        chooseNextEpisodePromptOption(m.nextEpisodePromptIndex)
        return true
    end if

    return true
end function

sub chooseNextEpisodePromptOption(index as Integer)
    if index <> 0
        closeNextEpisodePrompt()
        return
    end if

    nextPlayback = m.nextEpisodePromptPlayback
    if nextPlayback = invalid
        closeNextEpisodePrompt()
        return
    end if

    markCompletedIfSafe()
    startNextPlayback(nextPlayback)
end sub

sub startNextPlayback(playback as Object)
    m.nextEpisodeCountdownTimer.control = "stop"
    m.nextEpisodePromptGroup.visible = false
    m.videoNode.control = "stop"
    m.progressTimer.control = "stop"
    clearPendingSeek()

    m.playback = playback
    m.preferences = m.preferenceStore.load(m.playback)
    m.titleLabel.text = playbackTitle()
    buildSeasonCarouselFromPlayback()
    m.lastSavedSeconds = -1
    m.completed = false
    m.playbackStarted = false
    m.isPlaying = false
    resetNextEpisodeState()
    buildControls()
    showRail()
    updateProgressVisuals()
    startPlayback()
end sub

function resumeStartSeconds() as Integer
    if isLivePlayback() then return 0
    if m.playback = invalid or m.playback.progressSeconds = invalid then return 0
    progress = m.playback.progressSeconds
    duration = playbackDurationSeconds()

    if progress < 15 then return 0
    if duration > 0
        if progress >= duration - 30 then return 0
        if Int((progress * 100) / duration) >= 90 then return 0
    end if

    return progress
end function

function nextEpisodePromptThresholdSeconds(duration as Integer) as Integer
    if duration <= 0 then return 0

    percentThreshold = Int((duration * 8) / 100)
    if percentThreshold < 1 then percentThreshold = 1
    if percentThreshold > 180 then return 180
    return percentThreshold
end function

sub maybeRequestNextEpisodePrompt(reason as String)
    if m.playback = invalid then return
    if m.nextEpisodeRequested = true or m.nextEpisodeRequestPending = true or m.nextEpisodePromptOpen = true then return
    if canAskForNextEpisode() <> true then return

    if reason = "threshold"
        duration = playbackDurationSeconds()
        if duration <= 0 then return
        position = currentPositionSeconds()
        if position <= 0 then return
        remaining = duration - position
        if remaining < 0 then remaining = 0
        threshold = nextEpisodePromptThresholdSeconds(duration)
        if threshold <= 0 or remaining > threshold then return
    end if

    m.nextEpisodeRequested = true
    m.nextEpisodeRequestPending = true
    m.nextEpisodeRequestReason = reason
    m.top.nextPlaybackRequested = {
        itemId: playbackIntegerField("itemId", 0)
        mediaId: playbackIntegerField("mediaId", 0)
        seasonNumber: playbackIntegerField("seasonNumber", 0)
        episodeNumber: playbackIntegerField("episodeNumber", 0)
        videoNumber: playbackIntegerField("videoNumber", 0)
        reason: reason
    }
end sub

function canAskForNextEpisode() as Boolean
    if isLivePlayback() then return false
    if m.playback = invalid then return false
    itemId = playbackIntegerField("itemId", 0)
    mediaId = playbackIntegerField("mediaId", 0)
    seasonNumber = playbackIntegerField("seasonNumber", 0)
    if itemId <= 0 or mediaId <= 0 then return false
    return seasonNumber > 0
end function

function playbackIntegerField(key as String, fallback as Integer) as Integer
    if m.playback = invalid or type(m.playback) <> "roAssociativeArray" then return fallback
    if m.playback.DoesExist(key) <> true or m.playback[key] = invalid then return fallback
    value = m.playback[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function isLivePlayback() as Boolean
    if m.playback = invalid or type(m.playback) <> "roAssociativeArray" then return false
    if m.playback.DoesExist("isLive") <> true or m.playback.isLive = invalid then return false
    valueType = type(m.playback.isLive)
    if valueType = "Boolean" or valueType = "roBoolean" then return m.playback.isLive
    return false
end function

sub resetSeasonCarouselState()
    m.seasonEpisodes = []
    m.seasonCarouselCards = []
    m.seasonCarouselFocusIndex = 0
    m.seasonCarouselVisibleStart = 0
    m.seasonCarouselRequestPending = false
end sub

sub buildSeasonCarouselFromPlayback()
    resetSeasonCarouselState()

    if m.playback = invalid or type(m.playback) <> "roAssociativeArray" then return
    if m.playback.DoesExist("seasonEpisodes") <> true or m.playback.seasonEpisodes = invalid then return
    if type(m.playback.seasonEpisodes) <> "roArray" then return

    for each episode in m.playback.seasonEpisodes
        if type(episode) = "roAssociativeArray" then m.seasonEpisodes.Push(episode)
    end for

    currentMediaId = seasonCarouselCurrentMediaId()
    for index = 0 to m.seasonEpisodes.Count() - 1
        episode = m.seasonEpisodes[index]
        episodeMediaId = seasonCarouselEpisodeIntegerField(episode, "mediaId", 0)
        if currentMediaId > 0 and episodeMediaId = currentMediaId
            m.seasonCarouselFocusIndex = index
            m.seasonCarouselVisibleStart = index
            exit for
        end if
    end for

    updateSeasonCarouselVisibleWindow()
end sub

function seasonCarouselCurrentMediaId() as Integer
    return playbackIntegerField("mediaId", 0)
end function

function hasSeasonCarousel() as Boolean
    return m.seasonEpisodes <> invalid and m.seasonEpisodes.Count() > 1
end function

sub updateSeasonCarouselVisibleWindow()
    if hasSeasonCarousel() <> true
        m.seasonCarouselVisibleStart = 0
        return
    end if

    if m.seasonCarouselFocusIndex < 0 then m.seasonCarouselFocusIndex = 0
    if m.seasonCarouselFocusIndex >= m.seasonEpisodes.Count() then m.seasonCarouselFocusIndex = m.seasonEpisodes.Count() - 1

    if m.seasonCarouselFocusIndex < m.seasonCarouselVisibleStart
        m.seasonCarouselVisibleStart = m.seasonCarouselFocusIndex
    else if m.seasonCarouselFocusIndex >= m.seasonCarouselVisibleStart + m.maxVisibleSeasonCarouselItems
        m.seasonCarouselVisibleStart = m.seasonCarouselFocusIndex - m.maxVisibleSeasonCarouselItems + 1
    end if

    maxStart = m.seasonEpisodes.Count() - m.maxVisibleSeasonCarouselItems
    if maxStart < 0 then maxStart = 0
    if m.seasonCarouselVisibleStart > maxStart then m.seasonCarouselVisibleStart = maxStart
    if m.seasonCarouselVisibleStart < 0 then m.seasonCarouselVisibleStart = 0
end sub

sub renderSeasonCarousel()
    if m.seasonCarouselGroup = invalid or m.seasonCarouselHost = invalid then return

    childCount = m.seasonCarouselHost.getChildCount()
    if childCount > 0 then m.seasonCarouselHost.removeChildrenIndex(childCount, 0)
    m.seasonCarouselCards = []

    if hasSeasonCarousel() <> true
        if m.focusArea = "seasonCarousel" then m.focusArea = "controls"
        m.seasonCarouselGroup.visible = false
        updateSeasonCarouselChevrons()
        return
    end if

    seasonNumber = playbackIntegerField("seasonNumber", 0)
    if seasonNumber > 0
        m.seasonCarouselTitleLabel.text = "Season " + StrI(seasonNumber).Trim()
    else
        m.seasonCarouselTitleLabel.text = "Season"
    end if

    updateSeasonCarouselVisibleWindow()
    startIndex = m.seasonCarouselVisibleStart
    lastIndex = startIndex + m.maxVisibleSeasonCarouselItems - 1
    if lastIndex >= m.seasonEpisodes.Count() then lastIndex = m.seasonEpisodes.Count() - 1

    for index = startIndex to lastIndex
        card = createSeasonCarouselCard(m.seasonEpisodes[index], index, index - startIndex)
        m.seasonCarouselHost.appendChild(card)
        m.seasonCarouselCards.Push(card)
    end for

    m.seasonCarouselGroup.visible = true
    updateSeasonCarouselChevrons()
end sub

function createSeasonCarouselCard(episode as Object, index as Integer, visibleIndex as Integer) as Object
    card = CreateObject("roSGNode", "Group")
    card.translation = [visibleIndex * 184, 0]

    isFocused = m.focusArea = "seasonCarousel" and index = m.seasonCarouselFocusIndex
    isCurrent = seasonCarouselEpisodeIsCurrent(episode)

    bg = CreateObject("roSGNode", "Rectangle")
    bg.width = 168
    bg.height = 86
    bg.color = "#1F2937"
    if isCurrent then bg.color = "#1D4ED8"
    card.appendChild(bg)

    poster = CreateObject("roSGNode", "Poster")
    poster.translation = [6, 6]
    poster.width = 72
    poster.height = 46
    poster.uri = seasonCarouselEpisodeStringField(episode, "thumbnailUrl", "")
    poster.loadDisplayMode = "scaleToFill"
    card.appendChild(poster)

    title = CreateObject("roSGNode", "Label")
    title.text = seasonCarouselEpisodeTitle(episode)
    title.translation = [86, 8]
    title.width = 74
    title.height = 32
    title.wrap = true
    title.color = "#F5F5F5"
    card.appendChild(title)

    meta = CreateObject("roSGNode", "Label")
    meta.text = seasonCarouselEpisodeMeta(episode)
    meta.translation = [86, 50]
    meta.width = 74
    meta.color = "#D1D5DB"
    card.appendChild(meta)

    if seasonCarouselEpisodeWatched(episode)
        watched = CreateObject("roSGNode", "Label")
        watched.text = "✓"
        watched.translation = [140, 6]
        watched.width = 20
        watched.horizAlign = "center"
        watched.color = "#34D399"
        card.appendChild(watched)
    end if

    if isCurrent
        nowLabel = CreateObject("roSGNode", "Label")
        nowLabel.text = "Now"
        nowLabel.translation = [8, 58]
        nowLabel.width = 54
        nowLabel.color = "#BFDBFE"
        card.appendChild(nowLabel)
    end if

    if isFocused
        focus = CreateObject("roSGNode", "Rectangle")
        focus.width = 168
        focus.height = 4
        focus.color = "#F5F5F5"
        card.appendChild(focus)
        focusBottom = CreateObject("roSGNode", "Rectangle")
        focusBottom.translation = [0, 82]
        focusBottom.width = 168
        focusBottom.height = 4
        focusBottom.color = "#F5F5F5"
        card.appendChild(focusBottom)
    end if

    return card
end function

sub updateSeasonCarouselChevrons()
    if m.seasonCarouselLeftChevron = invalid or m.seasonCarouselRightChevron = invalid then return
    showChevrons = hasSeasonCarousel() and m.bottomRailGroup.visible = true
    m.seasonCarouselLeftChevron.visible = showChevrons and m.seasonCarouselVisibleStart > 0
    m.seasonCarouselRightChevron.visible = showChevrons and (m.seasonCarouselVisibleStart + m.maxVisibleSeasonCarouselItems) < m.seasonEpisodes.Count()
end sub

function seasonCarouselEpisodeIsCurrent(episode as Dynamic) as Boolean
    if episode = invalid then return false
    currentMediaId = seasonCarouselCurrentMediaId()
    return currentMediaId > 0 and seasonCarouselEpisodeIntegerField(episode, "mediaId", 0) = currentMediaId
end function

function seasonCarouselEpisodeWatched(episode as Dynamic) as Boolean
    if episode = invalid then return false
    if seasonCarouselEpisodeBooleanField(episode, "watched", false) then return true
    if seasonCarouselEpisodeIntegerField(episode, "watchStatus", 0) = 1 then return true
    return false
end function

function seasonCarouselEpisodeTitle(episode as Dynamic) as String
    if episode = invalid then return ""
    title = seasonCarouselEpisodeStringField(episode, "title", "")
    if title <> "" then return title

    episodeNumber = seasonCarouselEpisodeIntegerField(episode, "episodeNumber", 0)
    if episodeNumber > 0 then return "Episode " + StrI(episodeNumber).Trim()
    return "Episode"
end function

function seasonCarouselEpisodeMeta(episode as Dynamic) as String
    if episode = invalid then return ""
    episodeNumber = seasonCarouselEpisodeIntegerField(episode, "episodeNumber", 0)
    if episodeNumber > 0 then return "E" + StrI(episodeNumber).Trim()
    return ""
end function

function seasonCarouselEpisodeStringField(episode as Dynamic, key as String, fallback as String) as String
    if episode = invalid or type(episode) <> "roAssociativeArray" then return fallback
    if episode.DoesExist(key) <> true then return fallback
    value = episode[key]
    if value = invalid then return fallback

    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    return fallback
end function

function seasonCarouselEpisodeIntegerField(episode as Dynamic, key as String, fallback as Integer) as Integer
    if episode = invalid or type(episode) <> "roAssociativeArray" then return fallback
    if episode.DoesExist(key) <> true then return fallback
    value = episode[key]
    if value = invalid then return fallback

    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function seasonCarouselEpisodeBooleanField(episode as Dynamic, key as String, fallback as Boolean) as Boolean
    if episode = invalid or type(episode) <> "roAssociativeArray" then return fallback
    if episode.DoesExist(key) <> true then return fallback
    value = episode[key]
    if value = invalid then return fallback

    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return value
    return fallback
end function

' Icon row (was 4 text labels — "Play/Pause", "Audio: X", "Subs: X",
' "Quality: X" — now 4 icons with no on-screen text; the current selection
' for audio/subtitles/quality shows as a checkmark inside that control's own
' panel instead, same as the panel's checkmark already worked before this
' change). Play/Pause has no icon at all — the remote's dedicated transport
' key already controls it regardless of OSD focus (isTransportKey/
' handleTransportKey), matching the reference screenshots showing no
' explicit play/pause control in the row.
function controlIconUri(control as String) as String
    if control = "stats" then return "pkg:/images/ui/icon-settings.png"
    if control = "subtitles" then return "pkg:/images/ui/icon-subtitles.png"
    if control = "audio" then return "pkg:/images/ui/icon-audio.png"
    if control = "quality" then return "pkg:/images/ui/icon-quality.png"
    return ""
end function

sub buildControls()
    childCount = m.controlsHost.getChildCount()
    if childCount > 0 then m.controlsHost.removeChildrenIndex(childCount, 0)
    m.controls = ["stats", "subtitles", "audio", "quality"]
    m.controlNodes = []

    for index = 0 to m.controls.Count() - 1
        icon = CreateObject("roSGNode", "Poster")
        icon.uri = controlIconUri(m.controls[index])
        icon.width = 28
        icon.height = 28
        ' 10px inset centers the 28px icon inside the 48px focus-cursor slot
        ' (see focusCursor in PlayerScreen.xml) at the same absolute X as
        ' m.controlPositions[index].
        icon.translation = [index * m.controlSpacing + 10, 10]
        m.controlsHost.appendChild(icon)
        m.controlNodes.Push(icon)
    end for

    renderSeasonCarousel()
    applyBottomRailLayout()
    updateFocusCursor()
end sub

sub applyBottomRailLayout()
    hasCarousel = hasSeasonCarousel()
    isLive = isLivePlayback()

    railY = 516
    railHeight = 204
    titleY = 18
    timeY = 22
    progressFocusY = 72
    progressTrackY = 80
    controlsY = 110
    statusY = 164
    menuY = -268

    if hasCarousel
        railY = 400
        railHeight = 320
        titleY = 24
        timeY = 28
        progressFocusY = 196
        progressTrackY = 204
        controlsY = 234
        statusY = 286
        menuY = -238
    else if isLive
        railY = 550
        railHeight = 170
        titleY = 18
        timeY = 22
        controlsY = 72
        statusY = 132
        menuY = -302
    end if

    m.bottomRailGroup.translation = [0, railY]
    m.bottomRailBackground.height = railHeight
    m.titleLabel.translation = [72, titleY]
    m.timeLabel.translation = [1030, timeY]
    m.progressFocus.translation = [68, progressFocusY]
    m.progressTrack.translation = [72, progressTrackY]
    m.progressFill.translation = [72, progressTrackY]
    m.controlsHost.translation = [900, controlsY]
    m.controlFocusY = controlsY
    m.seasonCarouselStatusLabel.translation = [72, statusY]
    m.statusLabel.translation = [72, statusY]
    m.menuPopover.translation = [860, menuY]
end sub

sub showRail()
    m.bottomRailGroup.visible = true
    updateFocusCursor()
    updateSeasonCarouselChevrons()
    if m.isPlaying and m.menuOpen <> true then m.railHideTimer.control = "start"
end sub

sub onRailHideTimer()
    if m.isPlaying and m.menuOpen <> true then hideRail()
end sub

' Counterpart to showRail() — always resets focusArea back to "controls" so
' the OSD starts fresh on the icon row the next time it's revealed, however
' it was hidden (this timer, or Back — see onKeyEvent). Without this, a
' focusArea left on "progress" (e.g. after seeking with the OSD hidden) or
' "seasonCarousel" from before the rail hid would still be in effect next
' time the rail is shown, landing focus somewhere other than the icon row.
sub hideRail()
    m.railHideTimer.control = "stop"
    m.bottomRailGroup.visible = false
    m.focusArea = "controls"
    updateFocusCursor()
    updateSeasonCarouselChevrons()
end sub

sub updateFocusCursor()
    if m.focusArea = "seasonCarousel"
        m.focusCursor.visible = false
        m.progressFocus.visible = false
        renderSeasonCarousel()
        return
    end if

    if m.focusArea = "progress"
        m.focusCursor.visible = false
        m.progressFocus.visible = m.bottomRailGroup.visible and m.menuOpen <> true
        return
    end if

    m.focusCursor.translation = [m.controlPositions[m.focusIndex], m.controlFocusY]
    m.focusCursor.visible = m.bottomRailGroup.visible and m.menuOpen <> true
    m.progressFocus.visible = false
end sub

sub updateProgressVisuals()
    if isLivePlayback()
        m.timeLabel.text = "LIVE"
        m.progressFill.width = 0
        m.progressFocus.visible = false
        return
    end if
    position = displayPositionSeconds()
    duration = playbackDurationSeconds()
    m.timeLabel.text = formatTime(position) + " / " + formatTime(duration)

    width = 0
    if duration > 0
        width = Int((position * 1136) / duration)
        if width > 1136 then width = 1136
    end if
    m.progressFill.width = width
end sub

function currentPositionSeconds() as Integer
    if m.videoNode = invalid or m.videoNode.position = invalid then return 0
    return Int(m.videoNode.position)
end function

function displayPositionSeconds() as Integer
    if m.seekPending and m.pendingSeekPosition <> invalid then return m.pendingSeekPosition
    return currentPositionSeconds()
end function

function playbackDurationSeconds() as Integer
    if m.playback = invalid or m.playback.durationSeconds = invalid then return 0
    return m.playback.durationSeconds
end function

function formatTime(seconds as Integer) as String
    if seconds < 0 then seconds = 0
    minutes = Int(seconds / 60)
    remaining = seconds - (minutes * 60)
    remainingText = StrI(remaining).Trim()
    if remaining < 10 then remainingText = "0" + remainingText
    return StrI(minutes).Trim() + ":" + remainingText
end function

sub onVideoStateChanged(event as Object)
    state = event.getData()
    print "PlayerScreen: video state="; state
    if state = "playing"
        printVideoPlaybackDiagnostics("playing")
        hideStreamLoader()
        m.isPlaying = true
        m.playbackStarted = true
        applySavedAudioPreference()
        if m.pendingResumeSeekPosition > 0
            m.videoNode.seek = m.pendingResumeSeekPosition
            m.pendingResumeSeekPosition = 0
        end if
        if isLivePlayback() <> true then m.progressTimer.control = "start"
        showRail()
    else if state = "paused"
        hideStreamLoader()
        m.isPlaying = false
        m.railHideTimer.control = "stop"
        sendProgressUpdate("pause")
        showRail()
    else if state = "buffering"
        printVideoPlaybackDiagnostics("buffering")
        startBufferingDebounce()
        m.isPlaying = false
        m.railHideTimer.control = "stop"
        showRail()
    else if state = "finished"
        hideStreamLoader()
        if m.playbackStarted <> true
            print "PlayerScreen: stream finished before playback started"
            if tryNextPlaybackStream() then return
            m.top.playbackError = "Unable to play this video. Stream ended before playback started."
            exitPlayer()
            return
        end if
        if m.nextEpisodePromptOpen
            chooseNextEpisodePromptOption(0)
            return
        end if
        if canAskForNextEpisode()
            maybeRequestNextEpisodePrompt("finished")
            if m.nextEpisodeRequestPending then return
        end if
        m.completed = true
        markCompletedIfSafe()
        exitPlayer()
    else if state = "error"
        hideStreamLoader()
        printVideoErrorDiagnostics()
        if tryNextPlaybackStream() then return
        details = videoErrorDetails()
        print "PlayerScreen: video error "; details
        m.top.playbackError = details
        exitPlayer()
    else if state = "stopped"
        hideStreamLoader()
    end if
end sub

sub startBufferingDebounce()
    if m.bufferingDebounceTimer = invalid then return
    if m.streamLoaderGroup <> invalid and m.streamLoaderGroup.visible = true then return

    m.bufferingDebounceTimer.control = "stop"
    m.bufferingDebounceTimer.control = "start"
end sub

sub onBufferingDebounceTimer()
    if m.videoNode = invalid or m.videoNode.state <> "buffering" then return
    showStreamLoader("Buffering")
end sub

sub onVideoBufferingStatusChanged()
    status = invalid
    if m.videoNode <> invalid then status = m.videoNode.bufferingStatus
    if status <> invalid and type(status) = "roAssociativeArray"
        print "PlayerScreen: buffering status percentage="; playbackDiagnosticField(status, "percentage"); " underrun="; playbackDiagnosticField(status, "isUnderrun"); " position="; currentPositionSeconds()
    end if

    if m.streamLoaderGroup = invalid or m.streamLoaderGroup.visible <> true then return
    showStreamLoader("Buffering")
end sub

sub onVideoDownloadedSegmentChanged(event as Object)
    segment = event.getData()
    if segment = invalid or type(segment) <> "roAssociativeArray" then return

    downloadDurationMs = playbackDiagnosticNumber(playbackDiagnosticField(segment, "DownloadDuration"))
    segmentSize = playbackDiagnosticNumber(playbackDiagnosticField(segment, "SegSize"))
    measuredThroughputBps = 0
    if downloadDurationMs > 0 and segmentSize > 0
        measuredThroughputBps = Int((segmentSize * 8.0 * 1000.0) / downloadDurationMs)
    end if

    segmentUrl = playbackDiagnosticString(playbackDiagnosticField(segment, "SegUrl"))
    print "PlayerScreen: downloaded segment status="; playbackDiagnosticField(segment, "Status"); " sequence="; playbackDiagnosticField(segment, "SegSequence"); " type="; playbackDiagnosticField(segment, "SegType")
    print "PlayerScreen: downloaded segment start="; playbackDiagnosticField(segment, "SegStart"); " mediaDurationMs="; playbackDiagnosticField(segment, "SegDuration"); " downloadDurationMs="; downloadDurationMs
    print "PlayerScreen: downloaded segment sizeBytes="; segmentSize; " throughputBps="; measuredThroughputBps; " declaredBitrateBps="; playbackDiagnosticField(segment, "BitrateBPS")
    print "PlayerScreen: downloaded segment width="; playbackDiagnosticField(segment, "Width"); " height="; playbackDiagnosticField(segment, "Height"); " url="; playbackDiagnosticRedactedUrl(segmentUrl)
end sub

sub onVideoStreamingSegmentChanged(event as Object)
    segment = event.getData()
    if segment = invalid or type(segment) <> "roAssociativeArray" then return

    segmentUrl = playbackDiagnosticString(playbackDiagnosticField(segment, "segUrl"))
    print "PlayerScreen: streaming segment sequence="; playbackDiagnosticField(segment, "segSequence"); " type="; playbackDiagnosticField(segment, "segTypeStr"); " start="; playbackDiagnosticField(segment, "segStart")
    print "PlayerScreen: streaming segment bitrateBps="; playbackDiagnosticField(segment, "segBitrateBps"); " width="; playbackDiagnosticField(segment, "width"); " height="; playbackDiagnosticField(segment, "height")
    print "PlayerScreen: streaming segment latencyMs="; playbackDiagnosticField(segment, "latency"); " url="; playbackDiagnosticRedactedUrl(segmentUrl)
end sub

sub printVideoPlaybackDiagnostics(reason as String)
    if m.videoNode = invalid then return

    streamInfo = m.videoNode.streamInfo
    if streamInfo <> invalid and type(streamInfo) = "roAssociativeArray"
        streamUrl = playbackDiagnosticString(playbackDiagnosticField(streamInfo, "streamUrl"))
        print "PlayerScreen: stream info reason="; reason; " underrun="; playbackDiagnosticField(streamInfo, "isUnderrun"); " resume="; playbackDiagnosticField(streamInfo, "isResume")
        print "PlayerScreen: stream info measuredBitrateBps="; playbackDiagnosticField(streamInfo, "measuredBitrate"); " streamBitrateBps="; playbackDiagnosticField(streamInfo, "streamBitrate")
        print "PlayerScreen: stream info url="; playbackDiagnosticRedactedUrl(streamUrl)
    end if

    print "PlayerScreen: media info reason="; reason; " videoFormat="; m.videoNode.videoFormat; " audioFormat="; m.videoNode.audioFormat; " timeToStartSeconds="; m.videoNode.timeToStartStreaming
end sub

function playbackDiagnosticField(data as Dynamic, fieldName as String) as Dynamic
    if data = invalid or type(data) <> "roAssociativeArray" then return invalid
    if data.DoesExist(fieldName) then return data[fieldName]

    loweredFieldName = LCase(fieldName)
    for each key in data
        if LCase(key) = loweredFieldName then return data[key]
    end for
    return invalid
end function

function playbackDiagnosticString(value as Dynamic) as String
    if value = invalid then return ""
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    return value.ToStr()
end function

function playbackDiagnosticNumber(value as Dynamic) as Float
    if value = invalid then return 0.0
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return value
    if valueType = "String" or valueType = "roString" then return Val(value)
    return 0.0
end function

function playbackDiagnosticRedactedUrl(url as String) as String
    if url = "" then return ""
    queryPosition = Instr(1, url, "?")
    if queryPosition = 0 then return url
    return Left(url, queryPosition - 1) + "?[redacted]"
end function

' "Stats for nerds" overlay — toggled by OK on the gear/"stats" control,
' ONLY by that (not by Back — deliberately not part of onKeyEvent's
' overlay-precedence chain, see the comment there). Reuses the same
' roVideoNode diagnostic fields printVideoPlaybackDiagnostics already logs
' to the console instead of re-deriving anything, just renders them
' on-screen too. Stays visible independent of the OSD rail's own auto-hide
' timer/Back handling, and is only recomputed while actually visible (see
' onVideoPositionChanged).
sub toggleStatsOverlay()
    m.statsOverlayVisible = not m.statsOverlayVisible
    if m.statsOverlayVisible
        updateStatsOverlayText()
        m.statsOverlayTimer.control = "start"
    else
        m.statsOverlayTimer.control = "stop"
    end if
    m.statsOverlayGroup.visible = m.statsOverlayVisible
end sub

' Position-change events aren't a reliable refresh cadence on their own
' (fields like audioFormat/streamInfo can still read stale/empty for a bit
' after playback starts, and some Roku firmware only ticks Video.position a
' few times a second) — a dedicated 2s timer, running only while the
' overlay is actually visible, guarantees it keeps catching up.
sub onStatsOverlayTimer()
    if m.statsOverlayVisible then updateStatsOverlayText()
end sub


function selectedAudioLanguage() as String
    audioId = m.preferenceStore.stringField(m.preferences, "audioTrackId", "")
    items = audioMenuItems()
    for each item in items
        if menuItemId(item) = audioId then return trackLanguage(item)
    end for
    if items.Count() = 1 then return trackLanguage(items[0])
    return ""
end function

sub updateStatsOverlayText()
    if m.videoNode = invalid or m.statsOverlayLinesHost = invalid then return

    ' m.videoNode.audioFormat has been observed staying empty for the whole
    ' playback session on-device (not just briefly at startup) — fall back
    ' to the selected track's own label so this always matches what's
    ' checked in the audio panel instead of showing "unknown" indefinitely.
    audioFormat = m.videoNode.audioFormat
    if audioFormat = invalid or audioFormat = "" then audioFormat = selectedAudioLabel()

    languageText = selectedAudioLanguage()
    if languageText = "" then languageText = "—"

    subLabel = selectedSubtitleLabel()
    if subLabel = "Off" then subLabel = "OFF"

    lines = []
    ' selectedQualityLabel() already includes the tier for non-Auto options
    ' (kinoItemAddQualityUrlOptions appends " hls4"/" hls2"/" hls" to the
    ' label itself) and just says "Auto" for the Auto option — a separate
    ' format tag here was redundant either way ("Auto AUTO", "1080p hls4 HLS4").
    ' No Bitrate line — Video.downloadedSegment/streamingSegment never fire
    ' at all for this content/device (confirmed: the diagnostic print lines
    ' in onVideoDownloadedSegmentChanged/onVideoStreamingSegmentChanged never
    ' appear in the console log), so there's no live figure to show; showing
    ' a permanently-stuck "measuring..." was worse than not having the line.
    lines.Push("Video: " + selectedQualityLabel())
    lines.Push("Audio: " + UCase(audioFormat))
    lines.Push("Language: " + UCase(languageText))
    lines.Push("Sub: " + subLabel)

    ' One Label per line (not a single Label with embedded newlines) —
    ' explicit, unambiguous vertical layout.
    childCount = m.statsOverlayLinesHost.getChildCount()
    if childCount > 0 then m.statsOverlayLinesHost.removeChildrenIndex(childCount, 0)
    for index = 0 to lines.Count() - 1
        row = CreateObject("roSGNode", "Label")
        row.translation = [0, index * 28]
        row.width = 416
        row.color = "#F5F5F5"
        row.text = lines[index]
        m.statsOverlayLinesHost.appendChild(row)
    end for
end sub

sub showStreamLoader(title as String)
    if m.streamLoaderGroup = invalid then return
    if title <> "Buffering" and m.bufferingDebounceTimer <> invalid then m.bufferingDebounceTimer.control = "stop"

    m.streamLoaderGroup.visible = true
    if m.streamLoaderTitleLabel <> invalid then m.streamLoaderTitleLabel.text = title

    percent = streamLoaderPercent()
    if percent >= 0
        if m.streamLoaderPercentLabel <> invalid then m.streamLoaderPercentLabel.text = title + " " + StrI(percent).Trim() + "%"
        if m.streamLoaderFill <> invalid then m.streamLoaderFill.width = Int((280 * percent) / 100)
    else
        if title = "Buffering"
            if m.streamLoaderPercentLabel <> invalid then m.streamLoaderPercentLabel.text = "Buffering..."
        else
            if m.streamLoaderPercentLabel <> invalid then m.streamLoaderPercentLabel.text = "Please wait..."
        end if
        if m.streamLoaderFill <> invalid then m.streamLoaderFill.width = 0
    end if
end sub

sub hideStreamLoader()
    if m.bufferingDebounceTimer <> invalid then m.bufferingDebounceTimer.control = "stop"
    if m.streamLoaderGroup <> invalid then m.streamLoaderGroup.visible = false
    if m.streamLoaderFill <> invalid then m.streamLoaderFill.width = 0
end sub

function streamLoaderPercent() as Integer
    if m.videoNode = invalid then return -1

    percent = streamLoaderPercentFromValue(m.videoNode.bufferingStatus)
    if percent >= 0 then return percent

    percent = streamLoaderPercentFromValue(m.videoNode.bufferedPercentage)
    if percent >= 0 then return percent

    return streamLoaderPercentFromValue(m.videoNode.downloadProgress)
end function

function streamLoaderPercentFromValue(value as Dynamic) as Integer
    if value = invalid then return -1

    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger"
        return clampStreamLoaderPercent(value)
    else if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble"
        return clampStreamLoaderPercent(Int(value))
    else if valueType = "roAssociativeArray"
        for each key in ["percentage", "percent", "bufferPercent", "bufferingPercent"]
            if value.DoesExist(key)
                percent = streamLoaderPercentFromValue(value[key])
                if percent >= 0 then return percent
            end if
        end for
    end if

    return -1
end function

function clampStreamLoaderPercent(percent as Integer) as Integer
    if percent < 0 then return 0
    if percent > 100 then return 100
    return percent
end function

function tryNextPlaybackStream() as Boolean
    if m.playbackOptions = invalid then return false
    if m.playbackOptionIndex >= m.playbackOptions.Count() - 1 then return false

    m.playbackOptionIndex = m.playbackOptionIndex + 1
    stream = currentPlaybackStream()
    print "PlayerScreen: retrying playback with stream option="; StrI(m.playbackOptionIndex + 1).Trim(); "/"; StrI(m.playbackOptions.Count()).Trim(); " label="; stream.label
    print "PlayerScreen: retry stream format="; stream.streamFormat; " url="; playbackDiagnosticRedactedUrl(stream.url)

    m.videoNode.control = "stop"
    m.playbackStarted = false
    m.videoNode.content = playbackContentNode(savedPreferredSubtitleTrackNameForPlayback())
    showStreamLoader("Loading stream")
    m.videoNode.control = "play"
    return true
end function

function videoErrorDetails() as String
    code = 0
    message = ""
    diagnostic = ""
    if m.videoNode <> invalid
        if m.videoNode.errorCode <> invalid then code = m.videoNode.errorCode
        if m.videoNode.errorMsg <> invalid then message = m.videoNode.errorMsg
        if m.videoNode.errorStr <> invalid then diagnostic = m.videoNode.errorStr
    end if

    details = "Unable to play this video. code=" + StrI(code).Trim()
    if message <> "" then details = details + " msg=" + message
    if diagnostic <> "" then details = details + " diag=" + diagnostic
    return details
end function

sub printVideoErrorDiagnostics()
    if m.videoNode = invalid then return

    print "PlayerScreen: errorCode="; m.videoNode.errorCode
    print "PlayerScreen: errorMsg="; m.videoNode.errorMsg
    print "PlayerScreen: errorStr="; m.videoNode.errorStr
    if m.videoNode.errorInfo <> invalid
        print "PlayerScreen: errorInfo="; FormatJson(m.videoNode.errorInfo)
    end if
end sub

sub onVideoPositionChanged()
    updateSeekSettle()
    updateProgressVisuals()
    maybeRequestNextEpisodePrompt("threshold")
    if m.statsOverlayVisible then updateStatsOverlayText()
end sub

sub onAvailableAudioTracksChanged()
    if m.playbackStarted = true then applySavedAudioPreference()
end sub

sub onAvailableSubtitleTracksChanged()
    if autoApplySavedSubtitlePreferenceEnabled() then applySavedSubtitlePreference()
end sub

sub onProgressTimer()
    if m.isPlaying and isLivePlayback() <> true
        sendProgressUpdate("interval")
        maybeRequestNextEpisodePrompt("threshold")
    end if
end sub

sub onResumePromptTimer()
    if m.resumePromptOpen <> true then return

    m.resumeCountdownSeconds = m.resumeCountdownSeconds - 1
    if m.resumeCountdownSeconds <= 0
        chooseResumePromptOption(0)
    else
        updateResumePromptCountdown()
    end if
end sub

sub sendProgressUpdate(reason as String)
    if m.playback = invalid then return
    if isLivePlayback() then return

    position = currentPositionSeconds()
    if position < 0 then position = 0
    if reason = "start" and position < 15 then return
    if reason <> "exit" and m.lastSavedSeconds >= 0
        delta = position - m.lastSavedSeconds
        if delta < 0 then delta = 0 - delta
        if delta < 5 then return
    end if

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "savePlaybackProgress"
    task.request = {
        itemId: m.playback.itemId
        seasonNumber: m.playback.seasonNumber
        videoNumber: m.playback.videoNumber
        timeSeconds: position
    }
    task.observeField("response", "onProgressSaveResponse")
    task.control = "RUN"
    m.progressTask = task
    setStatusMessage("Saving progress...", false)
end sub

sub onProgressSaveResponse(event as Object)
    result = event.getData()
    if result <> invalid and result.ok = true
        m.lastSavedSeconds = result.timeSeconds
        setStatusMessage("Progress saved", true)
    else
        setStatusMessage("Unable to save progress", false)
    end if
end sub

sub markCompletedIfSafe()
    if m.playback = invalid then return
    if isLivePlayback() then return

    if m.playback.watched = true
        sendProgressUpdate("finished")
        return
    end if

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "markPlaybackWatched"
    task.request = {
        itemId: m.playback.itemId
        seasonNumber: m.playback.seasonNumber
        videoNumber: m.playback.videoNumber
        watched: m.playback.watched
    }
    task.observeField("response", "onMarkWatchedResponse")
    task.control = "RUN"
    m.watchedTask = task
    setStatusMessage("Saving progress...", false)
end sub

sub onMarkWatchedResponse(event as Object)
    result = event.getData()
    if result <> invalid and result.ok = true
        setStatusMessage("Progress saved", true)
    else
        sendProgressUpdate("finished")
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false

    if m.resumePromptOpen then return handleResumePromptKey(key)
    if m.nextEpisodePromptOpen then return handleNextEpisodePromptKey(key)
    if m.startOverPromptOpen then return handleStartOverPromptKey(key)
    if m.menuOpen then return handleMenuKey(key)

    ' The stats overlay is deliberately NOT in this precedence chain — it's
    ' independent of the OSD/Back stack entirely. It only ever toggles via
    ' OK on the gear control (activateFocusedControl/toggleStatsOverlay);
    ' Back behaves exactly as if it weren't showing at all, and it stays
    ' visible across the OSD hiding/reappearing.

    ' Back dismisses the OSD first (same "closes the current overlay before
    ' the player exits" precedence as the resumePrompt/nextEpisodePrompt/
    ' menu checks above) — only exits the player on a second Back once the
    ' rail is already hidden.
    if key = "back"
        if m.bottomRailGroup.visible = true
            hideRail()
            return true
        end if
        sendProgressUpdate("exit")
        exitPlayer()
        return true
    end if

    if m.bottomRailGroup.visible <> true
        ' Left/Right jump straight into seek mode (focusArea "progress") and
        ' seek immediately, same as the remote's dedicated rewind/fastforward
        ' keys (isTransportKey below) — landing on "progress" rather than
        ' "controls" means a second Left/Right keeps seeking (handleProgressKey)
        ' instead of moving icon focus. Previously these just revealed the
        ' rail without seeking at all.
        if key = "left" or key = "right"
            if isLivePlayback() <> true then m.focusArea = "progress"
            showRail()
            if key = "left" then seekBy(0 - m.seekStepSeconds) else seekBy(m.seekStepSeconds)
            return true
        end if
        ' Down (OSD hidden) → "Сначала"/"Следующая серия" — a manually
        ' invoked alternative to opening the OSD and navigating the season
        ' carousel; doesn't apply to live playback.
        if key = "down" and isLivePlayback() <> true
            showStartOverPrompt()
            return true
        end if
        showRail()
        if isTransportKey(key) then return handleTransportKey(key)
        return true
    end if

    if m.focusArea = "progress" then return handleProgressKey(key)
    if m.focusArea = "seasonCarousel" then return handleSeasonCarouselKey(key)

    if key = "up"
        if isLivePlayback() then return true
        m.focusArea = "progress"
        updateFocusCursor()
        showRail()
        return true
    else if key = "left"
        if m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1
        updateFocusCursor()
        showRail()
        return true
    else if key = "right"
        if m.focusIndex < m.controls.Count() - 1 then m.focusIndex = m.focusIndex + 1
        updateFocusCursor()
        showRail()
        return true
    else if key = "OK"
        activateFocusedControl()
        showRail()
        return true
    else if isTransportKey(key)
        return handleTransportKey(key)
    end if

    showRail()
    return true
end function

function handleResumePromptKey(key as String) as Boolean
    if key = "back"
        m.resumePromptTimer.control = "stop"
        m.resumePromptOpen = false
        m.resumePromptGroup.visible = false
        exitPlayer()
        return true
    else if key = "left"
        ' "Нет" (index 1) renders on the left — Left moves focus toward it.
        if m.resumePromptIndex < 1 then m.resumePromptIndex = m.resumePromptIndex + 1
        renderResumePromptOptions()
        return true
    else if key = "right"
        ' "Да" (index 0) renders on the right — Right moves focus toward it.
        if m.resumePromptIndex > 0 then m.resumePromptIndex = m.resumePromptIndex - 1
        renderResumePromptOptions()
        return true
    else if key = "OK" or key = "play"
        chooseResumePromptOption(m.resumePromptIndex)
        return true
    end if

    return true
end function

sub chooseResumePromptOption(index as Integer)
    startPosition = m.resumeStartPosition
    if index = 1 then startPosition = 0

    m.resumePromptTimer.control = "stop"
    m.resumePromptOpen = false
    m.resumePromptGroup.visible = false
    if index = 1
        restartPlaybackFromBeginning()
        return
    end if
    startPlaybackAtPosition(startPosition)
end sub

sub restartPlaybackFromBeginning()
    m.videoNode.control = "stop"
    ' A fresh ContentNode resets Roku's own audio-track selection back to the
    ' stream's default — re-arm applySavedAudioPreference's one-shot guard
    ' (m.savedAudioPreferenceApplied, only ever reset in startPlayback()
    ' otherwise) so the user's saved track actually gets reapplied once this
    ' new content starts playing, instead of silently no-opping.
    m.savedAudioPreferenceApplied = false
    m.videoNode.content = playbackContentNode(savedPreferredSubtitleTrackNameForPlayback())
    m.videoNode.seek = 0
    startPlaybackAtPosition(0)
end sub

' "Сначала" / "Следующая серия" — reachable only via Down while the OSD is
' hidden (see onKeyEvent's "rail hidden" branch). Deliberately a separate
' overlay from nextEpisodePromptGroup above: that one is auto-triggered near
' the end of an episode and offers "keep watching / play next now"; this one
' is manually invoked at any point and offers "restart this episode / jump
' to the next one". Same "closes on Back, same on a short auto-dismiss
' timeout" pattern as the other prompts, but the timeout here cancels
' (no action) rather than auto-choosing an option like the resume prompt's
' countdown does.
sub showStartOverPrompt()
    m.startOverPromptOptions = [{ id: "restart", label: "Сначала" }]
    if canAskForNextEpisode() then m.startOverPromptOptions.Push({ id: "next", label: "Следующая серия" })

    m.startOverPromptOpen = true
    m.startOverPromptIndex = 0
    renderStartOverPromptOptions()
    m.startOverPromptGroup.visible = true
    m.startOverPromptTimer.control = "start"
end sub

sub renderStartOverPromptOptions()
    childCount = m.startOverPromptOptionsHost.getChildCount()
    if childCount > 0 then m.startOverPromptOptionsHost.removeChildrenIndex(childCount, 0)
    m.startOverPromptOptionNodes = []

    count = m.startOverPromptOptions.Count()
    buttonWidth = 165
    buttonHeight = 48
    gap = 20
    totalWidth = (buttonWidth * count) + (gap * (count - 1))
    startX = Int((340 - totalWidth) / 2)

    for index = 0 to count - 1
        option = m.startOverPromptOptions[index]
        group = CreateObject("roSGNode", "Group")
        group.translation = [startX + (index * (buttonWidth + gap)), 0]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = buttonWidth
        bg.height = buttonHeight
        bg.color = "#4B5563"
        if index = m.startOverPromptIndex then bg.color = "#F9FAFB"
        group.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.translation = [0, 14]
        label.width = buttonWidth
        label.horizAlign = "center"
        label.text = option.label
        label.color = "#E5E7EB"
        if index = m.startOverPromptIndex then label.color = "#111827"
        group.appendChild(label)

        m.startOverPromptOptionsHost.appendChild(group)
        m.startOverPromptOptionNodes.Push(group)
    end for
end sub

function handleStartOverPromptKey(key as String) as Boolean
    if key = "back"
        closeStartOverPrompt()
        return true
    else if key = "left"
        if m.startOverPromptIndex > 0 then m.startOverPromptIndex = m.startOverPromptIndex - 1
        renderStartOverPromptOptions()
        return true
    else if key = "right"
        if m.startOverPromptIndex < m.startOverPromptOptions.Count() - 1 then m.startOverPromptIndex = m.startOverPromptIndex + 1
        renderStartOverPromptOptions()
        return true
    else if key = "OK" or key = "play"
        chooseStartOverPromptOption(m.startOverPromptIndex)
        return true
    end if

    return true
end function

sub closeStartOverPrompt()
    m.startOverPromptTimer.control = "stop"
    m.startOverPromptOpen = false
    m.startOverPromptGroup.visible = false
end sub

sub onStartOverPromptTimer()
    if m.startOverPromptOpen then closeStartOverPrompt()
end sub

sub chooseStartOverPromptOption(index as Integer)
    if index < 0 or index >= m.startOverPromptOptions.Count() then return
    optionId = m.startOverPromptOptions[index].id
    closeStartOverPrompt()

    if optionId = "restart"
        restartPlaybackFromBeginning()
    else if optionId = "next"
        requestManualNextEpisode()
    end if
end sub

' Same request/response plumbing maybeRequestNextEpisodePrompt uses
' (m.top.nextPlaybackRequested, resolved by VideoDetailScreen via AppScene),
' just with its own reason so onNextPlaybackChanged can switch immediately
' instead of showing another confirmation — the user already explicitly
' chose "next episode" from this dialog, unlike the threshold/finished
' reasons which still ask first.
sub requestManualNextEpisode()
    if canAskForNextEpisode() <> true then return
    if m.nextEpisodeRequestPending = true
        setStatusMessage("Пожалуйста, подождите...", true)
        return
    end if

    m.nextEpisodeRequestPending = true
    m.nextEpisodeRequestReason = "manualNext"
    m.top.nextPlaybackRequested = {
        itemId: playbackIntegerField("itemId", 0)
        mediaId: playbackIntegerField("mediaId", 0)
        seasonNumber: playbackIntegerField("seasonNumber", 0)
        episodeNumber: playbackIntegerField("episodeNumber", 0)
        videoNumber: playbackIntegerField("videoNumber", 0)
        reason: "manualNext"
    }
end sub

function isTransportKey(key as String) as Boolean
    return key = "play" or key = "replay" or key = "rewind" or key = "fastforward" or key = "rev" or key = "fwd"
end function

function handleTransportKey(key as String) as Boolean
    if key = "play"
        togglePlayPause()
    else if (key = "replay" or key = "rewind" or key = "rev") and isLivePlayback() <> true
        seekBy(0 - m.seekStepSeconds)
    else if (key = "fastforward" or key = "fwd") and isLivePlayback() <> true
        seekBy(m.seekStepSeconds)
    end if
    return true
end function

function handleProgressKey(key as String) as Boolean
    if key = "up" and hasSeasonCarousel()
        m.focusArea = "seasonCarousel"
        renderSeasonCarousel()
        updateFocusCursor()
    else if key = "down"
        m.focusArea = "controls"
        updateFocusCursor()
    else if key = "left"
        seekBy(0 - m.seekStepSeconds)
    else if key = "right"
        seekBy(m.seekStepSeconds)
    else if isTransportKey(key)
        return handleTransportKey(key)
    else if key = "back"
        sendProgressUpdate("exit")
        exitPlayer()
    end if

    showRail()
    return true
end function

function handleSeasonCarouselKey(key as String) as Boolean
    if key = "down"
        m.focusArea = "progress"
        renderSeasonCarousel()
        updateFocusCursor()
    else if key = "left"
        moveSeasonCarousel(-1)
    else if key = "right"
        moveSeasonCarousel(1)
    else if key = "OK"
        selectFocusedSeasonCarouselEpisode()
    else if isTransportKey(key)
        return handleTransportKey(key)
    else if key = "back"
        sendProgressUpdate("exit")
        exitPlayer()
    end if

    showRail()
    return true
end function

sub moveSeasonCarousel(delta as Integer)
    if hasSeasonCarousel() <> true then return

    nextIndex = m.seasonCarouselFocusIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.seasonEpisodes.Count() then nextIndex = m.seasonEpisodes.Count() - 1
    if nextIndex = m.seasonCarouselFocusIndex then return

    m.seasonCarouselFocusIndex = nextIndex
    renderSeasonCarousel()
end sub

sub selectFocusedSeasonCarouselEpisode()
    if hasSeasonCarousel() <> true then return
    if m.seasonCarouselRequestPending then return
    if m.seasonCarouselFocusIndex < 0 or m.seasonCarouselFocusIndex >= m.seasonEpisodes.Count() then return

    episode = m.seasonEpisodes[m.seasonCarouselFocusIndex]
    if episode = invalid then return
    if seasonCarouselEpisodeIsCurrent(episode)
        setStatusMessage("Current episode", true)
        return
    end if
    if seasonCarouselEpisodeBooleanField(episode, "isPlayable", false) <> true
        setStatusMessage("Episode is not playable", true)
        return
    end if

    episodeMediaId = seasonCarouselEpisodeIntegerField(episode, "mediaId", 0)
    if episodeMediaId <= 0
        setStatusMessage("Episode is not playable", true)
        return
    end if

    m.seasonCarouselRequestPending = true
    m.nextEpisodeRequestPending = false
    m.nextEpisodeRequested = false
    m.nextEpisodeRequestReason = ""
    m.nextEpisodePromptOpen = false
    if m.nextEpisodePromptGroup <> invalid then m.nextEpisodePromptGroup.visible = false
    if m.nextEpisodeCountdownTimer <> invalid then m.nextEpisodeCountdownTimer.control = "stop"
    setStatusMessage("Preparing episode...", true)
    m.top.nextPlaybackRequested = {
        itemId: playbackIntegerField("itemId", 0)
        mediaId: episodeMediaId
        seasonNumber: seasonCarouselEpisodeIntegerField(episode, "seasonNumber", 0)
        episodeNumber: seasonCarouselEpisodeIntegerField(episode, "episodeNumber", 0)
        videoNumber: seasonCarouselEpisodeIntegerField(episode, "videoNumber", 0)
        reason: "seasonCarousel"
    }
end sub

sub togglePlayPause()
    if m.isPlaying
        m.videoNode.control = "pause"
        m.isPlaying = false
    else
        m.videoNode.control = "resume"
        m.isPlaying = true
    end if
    buildControls()
end sub

sub seekBy(deltaSeconds as Integer)
    if isLivePlayback() then return
    basePosition = currentPositionSeconds()
    if m.seekPending and m.pendingSeekPosition <> invalid then basePosition = m.pendingSeekPosition

    nextPosition = clampedSeekPosition(basePosition + deltaSeconds)
    m.pendingSeekPosition = nextPosition
    m.seekPending = true
    m.seekDebounceTimer.control = "stop"
    m.seekDebounceTimer.control = "start"
    updateProgressVisuals()
end sub

function clampedSeekPosition(position as Integer) as Integer
    nextPosition = position
    if nextPosition < 0 then nextPosition = 0
    duration = playbackDurationSeconds()
    if duration > 0 and nextPosition > duration - 1 then nextPosition = duration - 1
    return nextPosition
end function

sub onSeekDebounceTimer()
    applyPendingSeek()
end sub

sub applyPendingSeek()
    if m.seekPending <> true or m.pendingSeekPosition = invalid then return

    nextPosition = clampedSeekPosition(m.pendingSeekPosition)
    m.videoNode.seek = nextPosition
    m.seekSettleTimer.control = "stop"
    m.seekSettleTimer.control = "start"
    updateProgressVisuals()
end sub

sub updateSeekSettle()
    if m.seekPending <> true or m.pendingSeekPosition = invalid then return

    position = currentPositionSeconds()
    delta = position - m.pendingSeekPosition
    if delta < 0 then delta = 0 - delta
    if delta <= 2 then clearPendingSeek()
end sub

sub onSeekSettleTimer()
    clearPendingSeek()
    updateProgressVisuals()
end sub

sub clearPendingSeek()
    m.seekSettleTimer.control = "stop"
    m.seekPending = false
    m.pendingSeekPosition = invalid
end sub

sub activateFocusedControl()
    control = m.controls[m.focusIndex]
    if control = "stats"
        toggleStatsOverlay()
    else if control = "audio"
        openMenu("audio")
    else if control = "subtitles"
        openMenu("subtitles")
    else if control = "quality"
        openMenu("quality")
    end if
end sub

sub openMenu(menuType as String)
    m.menuOpen = true
    m.menuType = menuType
    m.menuIndex = 0
    m.menuScrollStart = 0
    if menuType = "audio"
        m.menuItems = audioMenuItems()
    else if menuType = "subtitles"
        m.menuItems = subtitleMenuItems()
    else
        m.menuItems = qualityMenuItems()
    end if
    updateMenuTitle()
    renderMenuItems()
    m.menuPopover.visible = true
    m.focusCursor.visible = false
    m.railHideTimer.control = "stop"
end sub

sub closeMenu()
    m.menuOpen = false
    m.menuType = ""
    m.menuPopover.visible = false
    m.focusCursor.visible = true
    updateFocusCursor()
    showRail()
end sub

sub renderMenuItems()
    childCount = m.menuItemsHost.getChildCount()
    if childCount > 0 then m.menuItemsHost.removeChildrenIndex(childCount, 0)

    ensureMenuSelectionVisible()
    updateMenuTitle()
    if m.menuItems.Count() = 0 then return

    lastVisibleIndex = m.menuScrollStart + m.maxVisibleMenuItems - 1
    if lastVisibleIndex >= m.menuItems.Count() then lastVisibleIndex = m.menuItems.Count() - 1

    ' Each row is a Group so the focused (cursor) row can get its own
    ' highlight bar behind it — distinct from the "✓" prefix, which marks
    ' the currently SAVED/applied selection, not where the cursor is.
    for index = m.menuScrollStart to lastVisibleIndex
        item = m.menuItems[index]
        visibleIndex = index - m.menuScrollStart
        isFocused = index = m.menuIndex

        rowGroup = CreateObject("roSGNode", "Group")
        rowGroup.translation = [0, visibleIndex * 34]

        if isFocused
            highlight = CreateObject("roSGNode", "Rectangle")
            highlight.translation = [-10, -3]
            highlight.width = 396
            highlight.height = 30
            highlight.color = "#F9FAFB"
            highlight.opacity = 0.22
            rowGroup.appendChild(highlight)
        end if

        label = CreateObject("roSGNode", "Label")
        label.width = 380
        label.color = "#E5E7EB"
        if isFocused then label.color = "#F9FAFB"
        prefix = "    "
        if isSelectedMenuItem(item) then prefix = "✓  "
        label.text = prefix + item.label
        rowGroup.appendChild(label)

        m.menuItemsHost.appendChild(rowGroup)
    end for
end sub

sub ensureMenuSelectionVisible()
    if m.menuIndex < m.menuScrollStart
        m.menuScrollStart = m.menuIndex
    else if m.menuIndex >= m.menuScrollStart + m.maxVisibleMenuItems
        m.menuScrollStart = m.menuIndex - m.maxVisibleMenuItems + 1
    end if

    maxStart = m.menuItems.Count() - m.maxVisibleMenuItems
    if maxStart < 0 then maxStart = 0
    if m.menuScrollStart > maxStart then m.menuScrollStart = maxStart
    if m.menuScrollStart < 0 then m.menuScrollStart = 0
end sub

sub updateMenuTitle()
    title = "КАЧЕСТВО"
    if m.menuType = "audio"
        title = "АУДИОДОРОЖКА"
    else if m.menuType = "subtitles"
        title = "СУБТИТРЫ"
    end if

    if m.menuItems <> invalid and m.menuItems.Count() > 0
        positionText = StrI(m.menuIndex + 1).Trim() + " / " + StrI(m.menuItems.Count()).Trim()
        m.menuTitleLabel.text = title + "  " + positionText
    else
        m.menuTitleLabel.text = title
    end if
end sub

function isSelectedMenuItem(item as Object) as Boolean
    if item = invalid then return false

    if m.menuType = "audio"
        return menuItemId(item) = m.preferenceStore.stringField(m.preferences, "audioTrackId", "")
    else if m.menuType = "subtitles"
        selectedId = m.preferenceStore.stringField(m.preferences, "subtitleTrackId", "")
        if selectedId = "" then selectedId = "off"
        return menuItemId(item) = selectedId
    else if m.menuType = "quality"
        selectedQuality = m.preferenceStore.stringField(m.preferences, "qualityId", "")
        if selectedQuality <> "" and menuItemId(item) = selectedQuality then return true

        selectedUrl = m.preferenceStore.stringField(m.preferences, "qualityUrl", "")
        if selectedUrl <> "" and item.url <> invalid and item.url = selectedUrl then return true

        return selectedQuality = "" and item.url <> invalid and m.playback <> invalid and item.url = m.playback.streamUrl
    end if

    return false
end function

function menuItemId(item as Object) as String
    if item = invalid then return ""
    if item.id <> invalid then return item.id
    return trackIdentifier(item)
end function

function contentSubtitleTracks() as Object
    return contentSubtitleTracksForPreferred("")
end function

function contentSubtitleTracksForPreferred(preferredTrackName as String) as Object
    tracks = []
    if m.playback = invalid or m.playback.subtitleTracks = invalid then return tracks

    for each track in m.playback.subtitleTracks
        trackName = subtitleTrackName(track)
        if trackName <> "" and trackName = preferredTrackName
            tracks.Push(subtitleTrackMetadata(track, trackName))
        end if
    end for

    for each track in m.playback.subtitleTracks
        trackName = subtitleTrackName(track)
        if trackName <> "" and trackName <> preferredTrackName
            tracks.Push(subtitleTrackMetadata(track, trackName))
        end if
    end for

    return tracks
end function

function subtitleTrackMetadata(track as Dynamic, trackName as String) as Object
    return {
        Language: trackLanguage(track)
        Description: trackLabel(track)
        TrackName: trackName
    }
end function

function audioMenuItems() as Object
    if hasAvailableAudioTracks() then return availableAudioMenuItems()

    items = []
    if m.playback <> invalid and m.playback.audioTracks <> invalid and m.playback.audioTracks.Count() > 0
        seen = {}
        for each track in m.playback.audioTracks
            label = trackLabel(track)
            if label = "" then label = "Audio " + StrI(items.Count() + 1).Trim()
            appendUniqueTrackMenuItem(items, seen, {
                id: menuItemId(track)
                label: label
                language: trackLanguage(track)
                Track: trackIdentifier(track)
            })
        end for
    else
        items.Push({ id: "default", label: "Default" })
    end if
    return items
end function

' Roku's own availableAudioTracks entries (Language/Name/Track) carry no
' codec field at all — codec info only exists in KinoPub's own metadata
' (m.playback.audioTracks, already AC3-filtered by kinoItemTrackOptions).
' Cross-reference by label so an AC3 track dropped there doesn't resurface
' here once Roku reports its own track list mid-playback: only tracks whose
' label matches a surviving (non-AC3) KinoPub track are offered, unless
' KinoPub's list isn't available at all, in which case nothing is filtered
' rather than risk hiding every track.
function audioMenuAllowedLabels() as Dynamic
    if m.playback = invalid or m.playback.audioTracks = invalid or m.playback.audioTracks.Count() = 0 then return invalid

    allowed = {}
    for each track in m.playback.audioTracks
        allowed[LCase(trackLabel(track))] = true
    end for
    return allowed
end function

function availableAudioMenuItems() as Object
    items = []
    if hasAvailableAudioTracks() <> true then return items

    allowedLabels = audioMenuAllowedLabels()
    seen = {}
    for each track in m.videoNode.availableAudioTracks
        label = trackLabel(track)
        if label = "" then label = "Audio " + StrI(items.Count() + 1).Trim()

        ' Defense in depth: also drop anything whose own label text mentions
        ' AC3, regardless of the KinoPub cross-reference below.
        isAc3 = Instr(1, LCase(label), "ac3") > 0 or Instr(1, LCase(label), "ac-3") > 0
        isAllowed = allowedLabels = invalid or allowedLabels.DoesExist(LCase(label))

        if not isAc3 and isAllowed
            appendUniqueTrackMenuItem(items, seen, {
                id: trackIdentifier(track)
                label: label
                language: trackLanguage(track)
                Track: trackIdentifier(track)
            })
        end if
    end for

    return items
end function

function subtitleMenuItems() as Object
    items = [{ id: "off", label: "Off", url: "" }]
    if m.videoNode <> invalid and m.videoNode.availableSubtitleTracks <> invalid and m.videoNode.availableSubtitleTracks.Count() > 0
        seen = {}
        for each track in m.videoNode.availableSubtitleTracks
            appendUniqueTrackMenuItem(items, seen, subtitleMenuItemForAvailableTrack(track))
        end for
    else if m.playback <> invalid and m.playback.subtitleTracks <> invalid
        seen = {}
        for each track in m.playback.subtitleTracks
            appendUniqueTrackMenuItem(items, seen, track)
        end for
    end if
    return items
end function

sub appendUniqueTrackMenuItem(items as Object, seen as Object, item as Dynamic)
    key = trackDedupeKey(item)
    if key <> "" and seen.DoesExist(key) then return

    items.Push(item)
    if key <> "" then seen[key] = true
end sub

function subtitleMenuItemForAvailableTrack(track as Dynamic) as Object
    trackName = subtitleTrackName(track)
    sourceTrack = subtitleSourceTrackForTrackName(trackName)
    if sourceTrack <> invalid
        label = trackLabel(sourceTrack)
        if label = "" or label = "Default" then label = trackLabel(track)
        return {
            id: menuItemId(sourceTrack)
            label: label
            language: trackLanguage(sourceTrack)
            TrackName: trackName
        }
    end if

    return {
        id: trackName
        label: trackLabel(track)
        language: trackLanguage(track)
        TrackName: trackName
    }
end function

function subtitleSourceTrackForTrackName(trackName as String) as Dynamic
    if trackName = "" then return invalid
    if m.playback = invalid or m.playback.subtitleTracks = invalid then return invalid

    for each sourceTrack in m.playback.subtitleTracks
        if subtitleTrackName(sourceTrack) = trackName then return sourceTrack
    end for

    return invalid
end function

function qualityMenuItems() as Object
    items = []
    if m.playback <> invalid and m.playback.qualityOptions <> invalid and m.playback.qualityOptions.Count() > 0
        for each option in m.playback.qualityOptions
            items.Push(option)
        end for
    else if m.playback <> invalid
        items.Push({
            id: "default"
            label: "Default"
            url: m.playback.streamUrl
            streamFormat: m.playback.streamFormat
        })
    end if
    return items
end function

function selectedAudioLabel() as String
    audioId = m.preferenceStore.stringField(m.preferences, "audioTrackId", "")
    items = audioMenuItems()
    for each item in items
        if menuItemId(item) = audioId then return trackLabel(item)
    end for
    if items.Count() = 1 then return trackLabel(items[0])
    return "Default"
end function

function selectedSubtitleLabel() as String
    subtitleId = m.preferenceStore.stringField(m.preferences, "subtitleTrackId", "")
    if subtitleId = "" or subtitleId = "off" then return "Off"

    items = subtitleMenuItems()
    for each item in items
        if menuItemId(item) = subtitleId then return trackLabel(item)
    end for
    return "On"
end function

function selectedQualityLabel() as String
    qualityId = m.preferenceStore.stringField(m.preferences, "qualityId", "")
    qualityUrl = m.preferenceStore.stringField(m.preferences, "qualityUrl", "")
    items = qualityMenuItems()
    stream = currentPlaybackStream()

    for each item in items
        if qualityId <> "" and menuItemId(item) = qualityId then return trackLabel(item)
        if qualityUrl <> "" and item.url <> invalid and item.url = qualityUrl then return trackLabel(item)
        if qualityId = "" and qualityUrl = "" and item.url <> invalid and item.url = stream.url then return trackLabel(item)
    end for

    return "Default"
end function

function trackIdentifier(track as Dynamic) as String
    if track = invalid or type(track) <> "roAssociativeArray" then return ""
    for each key in ["Track", "track", "TrackName", "trackName", "id", "Id", "ID", "url"]
        if track.DoesExist(key) and track[key] <> invalid and track[key] <> "" then return track[key]
    end for
    return ""
end function

function trackDedupeKey(track as Dynamic) as String
    if track = invalid or type(track) <> "roAssociativeArray" then return ""

    label = LCase(trackSemanticLabel(track))
    language = LCase(trackLanguage(track))
    if label <> "" and language <> "" then return "label:" + label + "|language:" + language
    if label <> "" then return "label:" + label

    id = LCase(trackIdentifier(track))
    if id <> "" then return "id:" + id
    return ""
end function

function trackSemanticLabel(track as Dynamic) as String
    if track = invalid or type(track) <> "roAssociativeArray" then return ""
    for each key in ["Name", "name", "Description", "description", "label", "title", "language", "Language", "lang"]
        if track.DoesExist(key) and track[key] <> invalid and track[key] <> "" then return track[key]
    end for
    return ""
end function

function subtitleTrackName(track as Dynamic) as String
    if track = invalid or type(track) <> "roAssociativeArray" then return ""
    for each key in ["TrackName", "trackName", "url", "Url", "URL"]
        if track.DoesExist(key) and track[key] <> invalid and track[key] <> "" then return track[key]
    end for
    return ""
end function

function trackLabel(track as Dynamic) as String
    if track = invalid or type(track) <> "roAssociativeArray" then return "Default"
    for each key in ["Name", "name", "Description", "description", "label", "title", "language", "Language", "lang"]
        if track.DoesExist(key) and track[key] <> invalid and track[key] <> "" then return track[key]
    end for
    return trackIdentifier(track)
end function

function trackLanguage(track as Dynamic) as String
    if track = invalid or type(track) <> "roAssociativeArray" then return ""
    for each key in ["Language", "language", "lang", "Lang"]
        if track.DoesExist(key) and track[key] <> invalid and track[key] <> "" then return track[key]
    end for
    return ""
end function

function handleMenuKey(key as String) as Boolean
    if key = "back" or key = "left"
        closeMenu()
        return true
    else if key = "up"
        if m.menuIndex > 0 then m.menuIndex = m.menuIndex - 1
        renderMenuItems()
        return true
    else if key = "down"
        if m.menuIndex < m.menuItems.Count() - 1 then m.menuIndex = m.menuIndex + 1
        renderMenuItems()
        return true
    else if key = "OK"
        if m.menuItems.Count() = 0 then return true
        selected = m.menuItems[m.menuIndex]
        if m.menuType = "audio"
            applyAudioSelection(selected)
        else if m.menuType = "subtitles"
            applySubtitleSelection(selected)
        else if m.menuType = "quality"
            applyQualitySelection(selected)
        end if
        closeMenu()
        return true
    end if
    return true
end function

sub applyAudioSelection(track as Object)
    if track = invalid then return

    trackId = menuItemId(track)
    if trackId = "" then return

    if m.preferences = invalid then m.preferences = {}
    audioSelectionApplied = false
    if hasAvailableAudioTracks()
        m.videoNode.audioTrack = trackId
        audioSelectionApplied = true
    end if
    m.preferences["audioTrackId"] = trackId
    m.preferences["audioTrackLabel"] = trackLabel(track)
    m.preferences["audioTrackLanguage"] = trackLanguage(track)
    m.preferences["audioCurrentTrack"] = trackId
    m.preferenceStore.save(m.playback, m.preferences)
    m.savedAudioPreferenceApplied = audioSelectionApplied

    setStatusMessage("Audio: " + selectedAudioLabel(), true)
    sendProgressUpdate("audio")
end sub

sub applySubtitleSelection(track as Object)
    if m.preferences = invalid then m.preferences = {}

    if track = invalid or menuItemId(track) = "off"
        m.preferences["subtitleTrackId"] = "off"
        m.preferences["subtitleTrackLabel"] = "Off"
        m.preferences["subtitleTrackLanguage"] = ""
        m.preferences["subtitleTrackName"] = ""
        m.preferenceStore.save(m.playback, m.preferences)
        if m.videoNode <> invalid
            m.videoNode.globalCaptionMode = "Off"
            m.videoNode.subtitleTrack = ""
        end if
        setStatusMessage("Subtitles: Off", true)
        sendProgressUpdate("subtitles")
        return
    end if

    trackName = subtitleTrackName(track)
    if trackName = "" then trackName = menuItemId(track)
    if trackName = "" then return

    m.preferences["subtitleTrackId"] = menuItemId(track)
    m.preferences["subtitleTrackLabel"] = trackLabel(track)
    m.preferences["subtitleTrackLanguage"] = trackLanguage(track)
    m.preferences["subtitleTrackName"] = trackName
    m.preferenceStore.save(m.playback, m.preferences)

    if m.videoNode <> invalid
        m.videoNode.globalCaptionMode = "On"
        if hasAvailableSubtitleTracks()
            m.videoNode.subtitleTrack = trackName
        else
            reloadPlaybackWithSubtitle(trackName)
        end if
    end if

    setStatusMessage("Subtitles: " + selectedSubtitleLabel(), true)
    sendProgressUpdate("subtitles")
end sub

sub reloadPlaybackWithSubtitle(trackName as String)
    if m.videoNode = invalid then return

    position = currentPositionSeconds()
    wasPlaying = m.isPlaying
    m.videoNode.control = "stop"
    ' Re-arm applySavedAudioPreference's one-shot guard — a fresh ContentNode
    ' resets Roku's own audio-track selection, so without this the reload
    ' would silently drop the user's saved audio track (see
    ' restartPlaybackFromBeginning's identical comment).
    m.savedAudioPreferenceApplied = false
    m.videoNode.content = playbackContentNode(trackName)
    if position > 0 then m.videoNode.seek = position
    if wasPlaying
        m.videoNode.control = "play"
        m.isPlaying = true
    end if
end sub

sub applyQualitySelection(option as Object)
    if option = invalid then return
    if m.preferences = invalid then m.preferences = {}

    selectedIndex = playbackOptionIndexForQuality(option)
    if selectedIndex < 0
        setStatusMessage("Quality unavailable", true)
        return
    end if

    previousIndex = m.playbackOptionIndex
    m.playbackOptionIndex = selectedIndex
    stream = currentPlaybackStream()

    m.preferences["qualityId"] = menuItemId(option)
    m.preferences["qualityUrl"] = stream.url
    m.preferences["qualityLabel"] = trackLabel(option)
    m.preferences["qualityStreamFormat"] = stream.streamFormat
    m.preferenceStore.save(m.playback, m.preferences)

    setStatusMessage("Quality: " + selectedQualityLabel(), true)
    if previousIndex <> selectedIndex then reloadPlaybackWithQuality(option)
    sendProgressUpdate("quality")
end sub

function playbackOptionIndexForQuality(option as Dynamic) as Integer
    if option = invalid or m.playbackOptions = invalid then return -1

    optionId = menuItemId(option)
    optionUrl = ""
    if type(option) = "roAssociativeArray" and option.DoesExist("url") and option.url <> invalid then optionUrl = option.url

    for index = 0 to m.playbackOptions.Count() - 1
        stream = m.playbackOptions[index]
        if optionUrl <> "" and stream.url <> invalid and stream.url = optionUrl then return index
        if optionId <> "" and stream.id <> invalid and stream.id = optionId then return index
    end for

    return -1
end function

sub reloadPlaybackWithQuality(option as Object)
    if m.videoNode = invalid then return

    position = currentPositionSeconds()
    wasPlaying = m.isPlaying
    clearPendingSeek()
    m.videoNode.control = "stop"
    ' Re-arm applySavedAudioPreference's one-shot guard — see
    ' restartPlaybackFromBeginning's identical comment.
    m.savedAudioPreferenceApplied = false
    m.videoNode.content = playbackContentNode(savedPreferredSubtitleTrackNameForPlayback())
    if position > 0 then m.videoNode.seek = position
    if wasPlaying
        m.videoNode.control = "play"
        m.isPlaying = true
    end if
end sub

sub applySavedPreferences()
    applySavedAudioPreference()
    applySavedSubtitlePreference()
end sub

sub applySavedAudioPreference()
    if autoApplySavedAudioPreferenceEnabled() <> true then return
    if m.savedAudioPreferenceApplied = true then return
    if m.videoNode = invalid then return
    if hasAvailableAudioTracks() <> true then return

    track = findSavedAudioTrack()
    if track = invalid then return

    trackId = menuItemId(track)
    if trackId = "" or trackId = "default" then return

    print "PlayerScreen: applying saved audio track="; trackId; " label="; trackLabel(track)
    m.videoNode.audioTrack = trackId
    m.savedAudioPreferenceApplied = true
end sub

function hasAvailableAudioTracks() as Boolean
    return m.videoNode <> invalid and m.videoNode.availableAudioTracks <> invalid and m.videoNode.availableAudioTracks.Count() > 0
end function

function hasAvailableSubtitleTracks() as Boolean
    return m.videoNode <> invalid and m.videoNode.availableSubtitleTracks <> invalid and m.videoNode.availableSubtitleTracks.Count() > 0
end function

function findSavedAudioTrack() as Dynamic
    if m.preferences = invalid then return invalid
    if hasAvailableAudioTracks() <> true then return invalid

    savedId = m.preferenceStore.stringField(m.preferences, "audioTrackId", "")
    savedLabel = m.preferenceStore.stringField(m.preferences, "audioTrackLabel", "")
    savedLanguage = m.preferenceStore.stringField(m.preferences, "audioTrackLanguage", "")
    if savedId = "" and savedLabel = "" and savedLanguage = "" then return invalid

    items = availableAudioMenuItems()
    if savedId <> ""
        for each item in items
            if menuItemId(item) = savedId then return item
        end for
    end if

    if savedLabel <> "" and savedLanguage <> ""
        for each item in items
            if LCase(trackLabel(item)) = LCase(savedLabel) and LCase(trackLanguage(item)) = LCase(savedLanguage) then return item
        end for
    end if

    if savedLabel <> ""
        for each item in items
            if LCase(trackLabel(item)) = LCase(savedLabel) then return item
        end for
    end if

    if savedLanguage <> ""
        for each item in items
            if LCase(trackLanguage(item)) = LCase(savedLanguage) then return item
        end for
    end if

    return invalid
end function

function savedPreferredSubtitleTrackName() as String
    if m.preferences = invalid then return ""

    subtitleId = m.preferenceStore.stringField(m.preferences, "subtitleTrackId", "")
    if subtitleId = "" or subtitleId = "off" then return ""

    if m.playback <> invalid and m.playback.subtitleTracks <> invalid
        for each item in m.playback.subtitleTracks
            if menuItemId(item) = subtitleId then return subtitleTrackName(item)
        end for
    end if

    return m.preferenceStore.stringField(m.preferences, "subtitleTrackName", "")
end function

sub applySavedSubtitlePreference()
    if autoApplySavedSubtitlePreferenceEnabled() <> true then return
    trackName = savedPreferredSubtitleTrackName()
    if trackName = "" then return
    if m.videoNode = invalid then return

    m.videoNode.globalCaptionMode = "On"
    if hasAvailableSubtitleTracks() then m.videoNode.subtitleTrack = trackName
end sub

sub applySavedQualityPreference()
    if autoApplySavedPlaybackPreferencesEnabled() <> true then return
    if m.preferences = invalid or m.playbackOptions = invalid then return

    savedId = m.preferenceStore.stringField(m.preferences, "qualityId", "")
    savedUrl = m.preferenceStore.stringField(m.preferences, "qualityUrl", "")
    if savedId = "" and savedUrl = "" then return

    for index = 0 to m.playbackOptions.Count() - 1
        stream = m.playbackOptions[index]
        if savedUrl <> "" and stream.url <> invalid and stream.url = savedUrl
            m.playbackOptionIndex = index
            return
        end if
        if savedId <> "" and stream.id <> invalid and stream.id = savedId
            m.playbackOptionIndex = index
            return
        end if
    end for
end sub

sub setStatusMessage(message as String, autoClear as Boolean)
    m.statusClearTimer.control = "stop"
    m.statusLabel.text = message
    if autoClear then m.statusClearTimer.control = "start"
end sub

sub onStatusClearTimer()
    m.statusLabel.text = ""
end sub

sub exitPlayer()
    m.progressTimer.control = "stop"
    m.railHideTimer.control = "stop"
    m.statusClearTimer.control = "stop"
    m.resumePromptTimer.control = "stop"
    m.nextEpisodeCountdownTimer.control = "stop"
    m.bufferingDebounceTimer.control = "stop"
    m.seekDebounceTimer.control = "stop"
    m.statsOverlayTimer.control = "stop"
    clearPendingSeek()
    m.videoNode.control = "stop"
    m.top.exitRequested = true
end sub
