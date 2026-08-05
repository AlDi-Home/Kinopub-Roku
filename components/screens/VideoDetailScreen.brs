sub init()
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    m.errorLabel = m.top.findNode("errorLabel")
    m.retryFocusBg = m.top.findNode("retryFocusBg")
    m.detailGroup = m.top.findNode("detailGroup")
    m.heroArtworkPoster = m.top.findNode("heroArtworkPoster")
    m.poster = m.top.findNode("poster")
    m.posterFallback = m.top.findNode("posterFallback")
    m.detailFactsGroup = m.top.findNode("detailFactsGroup")
    m.detailFactsHost = m.top.findNode("detailFactsHost")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metadataLabel = m.top.findNode("metadataLabel")
    m.historyMetaGroup = m.top.findNode("historyMetaGroup")
    m.historyMetaLabel = m.top.findNode("historyMetaLabel")
    m.descriptionFocusBg = m.top.findNode("descriptionFocusBg")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.playFocusBg = m.top.findNode("playFocusBg")
    m.playButtonLabel = m.top.findNode("playButtonLabel")
    m.bookmarkActionGroup = m.top.findNode("bookmarkActionGroup")
    m.bookmarkFocusBg = m.top.findNode("bookmarkFocusBg")
    m.bookmarkLabel = m.top.findNode("bookmarkLabel")
    m.playbackErrorLabel = m.top.findNode("playbackErrorLabel")
    m.panelTitleLabel = m.top.findNode("panelTitleLabel")
    m.seasonTabsHost = m.top.findNode("seasonTabsHost")
    m.episodeListHost = m.top.findNode("episodeListHost")
    m.episodeCursor = m.top.findNode("episodeCursor")
    m.episodeScrollUpChevron = m.top.findNode("episodeScrollUpChevron")
    m.episodeScrollDownChevron = m.top.findNode("episodeScrollDownChevron")
    m.noMediaLabel = m.top.findNode("noMediaLabel")
    m.trailerGroup = m.top.findNode("trailerGroup")
    m.trailerFocusBg = m.top.findNode("trailerFocusBg")
    m.trailerLabel = m.top.findNode("trailerLabel")
    m.similarGroup = m.top.findNode("similarGroup")
    m.similarHost = m.top.findNode("similarHost")
    m.similarCursor = m.top.findNode("similarCursor")
    m.descriptionOverlayGroup = m.top.findNode("descriptionOverlayGroup")
    m.descriptionOverlayTextLabel = m.top.findNode("descriptionOverlayTextLabel")
    m.descriptionOverlayScrollUpChevron = m.top.findNode("descriptionOverlayScrollUpChevron")
    m.descriptionOverlayScrollDownChevron = m.top.findNode("descriptionOverlayScrollDownChevron")
    m.bookmarkOverlayGroup = m.top.findNode("bookmarkOverlayGroup")
    m.bookmarkOverlayStatusLabel = m.top.findNode("bookmarkOverlayStatusLabel")
    m.bookmarkOverlayFoldersHost = m.top.findNode("bookmarkOverlayFoldersHost")

    m.selection = invalid
    m.item = invalid
    m.trailer = invalid
    m.similarItems = []
    m.seasons = []
    m.currentSeasonIndex = 0
    m.currentEpisodeIndex = 0
    m.focusArea = "episodes"
    m.episodeRows = []
    m.episodeRowIndexes = []
    m.seasonTabBgs = []
    m.visibleEpisodeStart = 0
    m.defaultMaxVisibleEpisodes = 6
    m.maxVisibleEpisodes = m.defaultMaxVisibleEpisodes
    m.seasonTabWidth = 78
    m.seasonTabHeight = 38
    m.seasonTabGap = 14
    m.seasonTabRowHeight = 48
    m.seasonTabPanelWidth = 380
    m.baseEpisodeListY = 104
    m.episodeListY = m.baseEpisodeListY
    m.episodeListBottomY = 604
    m.descriptionOverlayScrollStart = 0
    m.descriptionOverlayMaxLines = 11
    m.descriptionOverlayLineLength = 76
    m.selectedSimilarIndex = 0
    m.similarCardWidth = 118
    m.similarCardSpacing = 130
    m.maxVisibleSimilarItems = 3
    m.bookmarkFolders = []
    m.itemBookmarkFolders = []
    m.bookmarkOverlayRows = []
    m.bookmarkOverlayRowBgs = []
    m.selectedBookmarkFolderIndex = 0
    m.bookmarkOverlayOpen = false
    m.bookmarkStatusMessage = ""
    m.pendingPlaybackMediaId = 0
    m.pendingPlaybackPayload = invalid
    m.pendingNextPlaybackMediaId = 0
    m.pendingNextPlaybackPayload = invalid
    m.pendingWatchedToggleKey = ""

    m.top.observeField("selection", "onSelectionChanged")
    m.top.observeField("playbackError", "onPlaybackError")
    m.top.observeField("reloadRequested", "onReloadRequested")
    m.top.observeField("nextPlaybackRequested", "onNextPlaybackRequested")
    m.top.setFocus(true)
end sub

function detailUiPalette() as Object
    return {
        background: "#090B0F"
        surface: "#172033"
        surfaceRaised: "#1E293B"
        surfaceFocus: "#1D4ED8"
        primary: "#2563EB"
        primaryFocus: "#60A5FA"
        primaryText: "#F8FAFC"
        text: "#F8FAFC"
        muted: "#9BA7BA"
        success: "#34D399"
        error: "#FCA5A5"
    }
end function

function detailButtonColor(isFocused as Boolean, isPrimary as Boolean) as String
    palette = detailUiPalette()
    if isPrimary
        if isFocused then return palette.primaryFocus
        return palette.primary
    end if
    if isFocused then return palette.surfaceFocus
    return palette.surface
end function

sub onSelectionChanged(event as Object)
    m.selection = event.getData()
    loadDetail()
end sub

sub onReloadRequested(event as Object)
    if event.getData() = true then loadDetail()
end sub

sub onPlaybackError(event as Object)
    message = event.getData()
    if message <> invalid and message <> "" then m.playbackErrorLabel.text = message
end sub

sub loadDetail()
    if m.selection = invalid or m.selection.itemId = invalid or m.selection.itemId <= 0
        showError("Unable to open this video.")
        return
    end if

    showState("loading")
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadItemDetail"
    task.request = {
        itemId: m.selection.itemId
        mediaId: selectedMediaId()
    }
    if m.selection.DoesExist("targetSeasonNumber") then task.request.targetSeasonNumber = m.selection.targetSeasonNumber
    if m.selection.DoesExist("targetEpisodeNumber") then task.request.targetEpisodeNumber = m.selection.targetEpisodeNumber
    if m.selection.DoesExist("seasonNumber") then task.request.seasonNumber = m.selection.seasonNumber
    if m.selection.DoesExist("episodeNumber") then task.request.episodeNumber = m.selection.episodeNumber
    task.observeField("response", "onDetailResponse")
    task.control = "RUN"
    m.detailTask = task
end sub

sub onDetailResponse(event as Object)
    response = event.getData()
    if response = invalid or response.ok <> true
        if responseRequiresSignIn(response)
            requestSignInAgain(response)
            return
        end if
        message = "Unable to load video details."
        if response <> invalid and response.message <> invalid and response.message <> ""
            message = response.message
        end if
        showError(message)
        return
    end if

    if response.item = invalid
        showError("Video details were not available.")
        return
    end if

    m.item = response.item
    m.trailer = invalid
    if m.item.trailer <> invalid then m.trailer = m.item.trailer
    m.similarItems = []
    if m.item.similarItems <> invalid then m.similarItems = m.item.similarItems
    m.selectedSimilarIndex = 0
    cancelPlaybackPreflight()
    buildPlayableModel()
    m.focusArea = "episodes"
    renderDetail()
    loadItemBookmarkFolders()
    showState("detail")
end sub

function selectedMediaId() as Integer
    if m.selection = invalid or m.selection.mediaId = invalid then return 0
    return m.selection.mediaId
end function

sub buildPlayableModel()
    m.seasons = []

    if m.item = invalid
        m.currentSeasonIndex = 0
        m.currentEpisodeIndex = 0
        return
    end if

    if m.item.seasons <> invalid and m.item.seasons.Count() > 0
        for each season in m.item.seasons
            if season <> invalid then m.seasons.Push(season)
        end for
    else
        videos = []
        if m.item.videos <> invalid then videos = m.item.videos
        m.seasons.Push({
            title: "Video"
            number: 0
            episodes: videos
        })
    end if

    m.currentSeasonIndex = 0
    m.currentEpisodeIndex = 0
    if selectTargetEpisodeFromResponse(m.selection) then return
    targetMediaId = selectedMediaId()

    if targetMediaId > 0
        for seasonIndex = 0 to m.seasons.Count() - 1
            episodes = playableEpisodesForSeason(seasonIndex)

            for episodeIndex = 0 to episodes.Count() - 1
                if episodes[episodeIndex].mediaId = targetMediaId
                    m.currentSeasonIndex = seasonIndex
                    m.currentEpisodeIndex = episodeIndex
                    return
                end if
            end for
        end for
    end if

    for seasonIndex = 0 to m.seasons.Count() - 1
        episodes = playableEpisodesForSeason(seasonIndex)

        for episodeIndex = 0 to episodes.Count() - 1
            episode = episodes[episodeIndex]
            if episode.isPlayable = true and episode.watched <> true
                m.currentSeasonIndex = seasonIndex
                m.currentEpisodeIndex = episodeIndex
                return
            end if
        end for
    end for

    for seasonIndex = 0 to m.seasons.Count() - 1
        episodes = playableEpisodesForSeason(seasonIndex)

        for episodeIndex = 0 to episodes.Count() - 1
            if episodes[episodeIndex].isPlayable = true
                m.currentSeasonIndex = seasonIndex
                m.currentEpisodeIndex = episodeIndex
                return
            end if
        end for
    end for
end sub

function selectTargetEpisodeFromResponse(response as Dynamic) as Boolean
    if response = invalid or type(response) <> "roAssociativeArray" then return false

    targetSeasonNumber = 0
    targetEpisodeNumber = 0
    if response.DoesExist("targetSeasonNumber") then targetSeasonNumber = detailIntegerField(response, "targetSeasonNumber", 0)
    if response.DoesExist("targetEpisodeNumber") then targetEpisodeNumber = detailIntegerField(response, "targetEpisodeNumber", 0)
    if targetSeasonNumber <= 0 and response.DoesExist("seasonNumber") then targetSeasonNumber = detailIntegerField(response, "seasonNumber", 0)
    if targetEpisodeNumber <= 0 and response.DoesExist("episodeNumber") then targetEpisodeNumber = detailIntegerField(response, "episodeNumber", 0)
    if targetSeasonNumber <= 0 and targetEpisodeNumber <= 0 then return false

    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        if targetSeasonNumber <= 0 or season.number = targetSeasonNumber
            episodes = playableEpisodesForSeason(seasonIndex)
            for episodeIndex = 0 to episodes.Count() - 1
                episode = episodes[episodeIndex]
                if targetEpisodeNumber <= 0 or episode.episodeNumber = targetEpisodeNumber
                    m.currentSeasonIndex = seasonIndex
                    m.currentEpisodeIndex = episodeIndex
                    return true
                end if
            end for
        end if
    end for

    return false
end function

function detailIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function playableEpisodesForSeason(seasonIndex as Integer) as Object
    if seasonIndex < 0 or seasonIndex >= m.seasons.Count() then return []
    if m.seasons[seasonIndex].episodes = invalid then return []
    return m.seasons[seasonIndex].episodes
end function

sub renderDetail()
    title = ""
    metadata = []
    description = ""
    backdropUrl = ""
    posterUrl = ""

    if m.item.title <> invalid then title = m.item.title
    if m.item.metadata <> invalid then metadata = m.item.metadata
    if m.item.description <> invalid then description = m.item.description
    if m.item.backdropUrl <> invalid then backdropUrl = m.item.backdropUrl
    if m.item.posterUrl <> invalid then posterUrl = m.item.posterUrl

    m.titleLabel.text = title
    m.metadataLabel.text = joinMetadata(metadata)
    m.descriptionLabel.text = description
    renderHistoryMetadata()
    renderDetailFacts()
    closeDescriptionOverlay()
    m.heroArtworkPoster.uri = backdropUrl
    m.heroArtworkPoster.visible = backdropUrl <> ""
    m.poster.uri = posterUrl
    m.poster.visible = posterUrl <> ""
    m.posterFallback.visible = true
    m.playbackErrorLabel.text = ""

    applyDetailExtrasLayout()
    renderSeasonTabs()
    renderEpisodeList()
    renderDetailExtras()
    updateSelectedMediaVisuals()
    updateDescriptionFocusVisual()
    updateDetailExtrasFocusVisuals()
end sub

sub renderDetailFacts()
    if m.detailFactsGroup = invalid or m.detailFactsHost = invalid then return

    childCount = m.detailFactsHost.getChildCount()
    if childCount > 0 then m.detailFactsHost.removeChildrenIndex(childCount, 0)

    if m.item = invalid
        m.detailFactsGroup.visible = false
        return
    end if
    if m.item.detailFacts = invalid or type(m.item.detailFacts) <> "roArray" or m.item.detailFacts.Count() = 0
        m.detailFactsGroup.visible = false
        return
    end if

    maxRows = m.item.detailFacts.Count()
    if maxRows > 7 then maxRows = 7

    for index = 0 to maxRows - 1
        m.detailFactsHost.appendChild(createDetailFactRow(m.item.detailFacts[index], index))
    end for

    m.detailFactsGroup.visible = true
end sub

function createDetailFactRow(fact as Object, index as Integer) as Object
    palette = detailUiPalette()
    row = CreateObject("roSGNode", "Group")
    row.translation = [0, index * 32]

    label = CreateObject("roSGNode", "Label")
    label.text = fact.label
    label.width = 96
    label.color = palette.muted
    row.appendChild(label)

    value = CreateObject("roSGNode", "Label")
    value.text = fact.value
    value.translation = [108, 0]
    value.width = 340
    value.color = "#D1D5DB"
    row.appendChild(value)

    return row
end function

sub renderHistoryMetadata()
    if m.historyMetaGroup = invalid or m.historyMetaLabel = invalid then return

    text = historyMetadataText()
    if text = ""
        applyHistoryMetadataLayout(false)
        m.historyMetaGroup.visible = false
        m.historyMetaLabel.text = ""
        return
    end if

    applyHistoryMetadataLayout(true)
    m.historyMetaLabel.text = text
    m.historyMetaGroup.visible = true
end sub

sub applyHistoryMetadataLayout(hasHistoryMetadata as Boolean)
    if m.descriptionFocusBg = invalid or m.descriptionLabel = invalid then return

    if hasHistoryMetadata
        m.descriptionFocusBg.translation = [-10, 424]
        m.descriptionFocusBg.height = 102
        m.descriptionLabel.translation = [0, 434]
        m.descriptionLabel.height = 84
    else
        m.descriptionFocusBg.translation = [-10, 402]
        m.descriptionFocusBg.height = 134
        m.descriptionLabel.translation = [0, 412]
        m.descriptionLabel.height = 112
    end if
end sub

function historyMetadataText() as String
    if m.selection = invalid then return ""

    watchCount = selectionIntegerField("watchCount", 0)
    firstSeenSeconds = selectionIntegerField("firstSeenSeconds", 0)
    lastSeenSeconds = selectionIntegerField("lastSeenSeconds", 0)
    if watchCount <= 0 and firstSeenSeconds <= 0 and lastSeenSeconds <= 0 then return ""

    parts = []
    if watchCount > 0
        countText = StrI(watchCount).Trim() + " watch"
        if watchCount <> 1 then countText = countText + "es"
        parts.Push(countText)
    end if

    if firstSeenSeconds > 0 then parts.Push("First " + formatHistoryDate(firstSeenSeconds))
    if lastSeenSeconds > 0 then parts.Push("Last " + formatHistoryDate(lastSeenSeconds))

    return joinMetadata(parts)
end function

function selectionIntegerField(key as String, fallback as Integer) as Integer
    if m.selection = invalid or type(m.selection) <> "roAssociativeArray" then return fallback
    if m.selection.DoesExist(key) <> true or m.selection[key] = invalid then return fallback

    value = m.selection[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function formatHistoryDate(seconds as Integer) as String
    if seconds <= 0 then return ""

    dateTime = CreateObject("roDateTime")
    dateTime.FromSeconds(seconds)

    monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    month = dateTime.GetMonth()
    if month < 1 or month > 12 then return ""

    return monthNames[month - 1] + " " + StrI(dateTime.GetDayOfMonth()).Trim() + ", " + StrI(dateTime.GetYear()).Trim()
end function

sub applyDetailExtrasLayout()
    if hasDetailExtras()
        m.episodeListBottomY = 422
    else
        m.episodeListBottomY = 604
    end if
end sub

function hasDetailExtras() as Boolean
    return hasPlayableTrailer() or hasSimilarItems()
end function

function hasPlayableTrailer() as Boolean
    if m.trailer = invalid then return false
    if m.trailer.streamUrl = invalid or m.trailer.streamUrl = "" then return false
    return true
end function

function hasSimilarItems() as Boolean
    return m.similarItems <> invalid and m.similarItems.Count() > 0
end function

sub renderDetailExtras()
    renderTrailerAction()
    renderSimilarItems()
    updateDetailExtrasFocusVisuals()
end sub

sub renderTrailerAction()
    if m.trailerGroup = invalid then return

    if hasPlayableTrailer() <> true
        m.trailerGroup.visible = false
        return
    end if

    m.trailerLabel.text = "Play trailer"
    m.trailerGroup.visible = true
end sub

sub renderSimilarItems()
    if m.similarGroup = invalid or m.similarHost = invalid then return

    childCount = m.similarHost.getChildCount()
    if childCount > 0 then m.similarHost.removeChildrenIndex(childCount, 0)

    if hasSimilarItems() <> true
        m.similarGroup.visible = false
        if m.similarCursor <> invalid then m.similarCursor.visible = false
        return
    end if

    if m.selectedSimilarIndex < 0 then m.selectedSimilarIndex = 0
    if m.selectedSimilarIndex >= m.similarItems.Count() then m.selectedSimilarIndex = m.similarItems.Count() - 1

    lastIndex = m.maxVisibleSimilarItems - 1
    if lastIndex >= m.similarItems.Count() then lastIndex = m.similarItems.Count() - 1

    for index = 0 to lastIndex
        m.similarHost.appendChild(createSimilarCard(m.similarItems[index], index))
    end for

    m.similarGroup.visible = true
end sub

function createSimilarCard(item as Object, index as Integer) as Object
    palette = detailUiPalette()
    card = CreateObject("roSGNode", "Group")
    card.translation = [index * m.similarCardSpacing, 0]

    bg = CreateObject("roSGNode", "Rectangle")
    bg.width = 118
    bg.height = 92
    bg.color = palette.surface
    card.appendChild(bg)

    poster = CreateObject("roSGNode", "Poster")
    poster.translation = [6, 6]
    poster.width = 44
    poster.height = 66
    poster.uri = item.posterUrl
    poster.loadDisplayMode = "scaleToFit"
    card.appendChild(poster)

    title = CreateObject("roSGNode", "Label")
    title.text = item.title
    title.translation = [56, 10]
    title.width = 56
    title.height = 38
    title.wrap = true
    title.color = palette.text
    card.appendChild(title)

    subtitle = CreateObject("roSGNode", "Label")
    subtitle.text = item.subtitle
    subtitle.translation = [56, 56]
    subtitle.width = 56
    subtitle.color = palette.muted
    card.appendChild(subtitle)

    return card
end function

sub updateDetailExtrasFocusVisuals()
    palette = detailUiPalette()
    if m.trailerFocusBg <> invalid
        if m.focusArea = "trailer" and m.trailerGroup.visible = true
            m.trailerFocusBg.color = detailButtonColor(true, false)
            m.trailerLabel.color = palette.primaryText
        else
            m.trailerFocusBg.color = detailButtonColor(false, false)
            m.trailerLabel.color = "#D1D5DB"
        end if
    end if

    if m.similarCursor <> invalid
        showCursor = m.focusArea = "similar" and m.similarGroup.visible = true and hasSimilarItems()
        if showCursor
            visibleIndex = m.selectedSimilarIndex
            if visibleIndex >= m.maxVisibleSimilarItems then visibleIndex = m.maxVisibleSimilarItems - 1
            m.similarCursor.translation = [visibleIndex * m.similarCardSpacing, 34]
            m.similarCursor.visible = true
        else
            m.similarCursor.visible = false
        end if
    end if
end sub

function firstDetailExtrasFocusArea() as String
    if hasPlayableTrailer() then return "trailer"
    if hasSimilarItems() then return "similar"
    return ""
end function

sub moveSimilar(delta as Integer)
    if hasSimilarItems() <> true then return

    nextIndex = m.selectedSimilarIndex + delta
    if nextIndex < 0 then nextIndex = 0
    maxIndex = m.similarItems.Count() - 1
    if maxIndex >= m.maxVisibleSimilarItems then maxIndex = m.maxVisibleSimilarItems - 1
    if nextIndex > maxIndex then nextIndex = maxIndex
    m.selectedSimilarIndex = nextIndex
    updateDetailExtrasFocusVisuals()
end sub

sub startTrailerPlayback()
    if hasPlayableTrailer() <> true
        m.playbackErrorLabel.text = "No playable trailer is available."
        return
    end if

    m.top.playbackRequested = {
        itemId: m.item.itemId
        mediaId: 0
        itemTitle: m.item.title
        title: "Trailer"
        subtitle: ""
        seasonNumber: 0
        episodeNumber: 0
        videoNumber: 0
        durationSeconds: 0
        progressSeconds: 0
        watchStatus: -1
        watched: false
        streamUrl: m.trailer.streamUrl
        streamFormat: m.trailer.streamFormat
        qualityOptions: m.trailer.qualityOptions
        audioTracks: []
        subtitleTracks: []
    }
end sub

sub selectSimilarItem()
    if hasSimilarItems() <> true then return
    if m.selectedSimilarIndex < 0 or m.selectedSimilarIndex >= m.similarItems.Count() then return

    item = m.similarItems[m.selectedSimilarIndex]
    if item.itemId = invalid or item.itemId <= 0 then return

    m.top.selection = {
        itemId: item.itemId
        mediaId: item.mediaId
        source: "similar"
    }
end sub

sub loadItemBookmarkFolders()
    if m.item = invalid or m.item.itemId <= 0 then return

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadItemBookmarkFolders"
    task.request = { itemId: m.item.itemId }
    task.observeField("response", "onItemBookmarkFoldersResponse")
    task.control = "RUN"
    m.itemBookmarkFoldersTask = task
end sub

sub onItemBookmarkFoldersResponse(event as Object)
    response = event.getData()
    if response = invalid or response.ok <> true
        if responseRequiresSignIn(response) then requestSignInAgain(response)
        return
    end if
    m.itemBookmarkFolders = []
    if response.folders <> invalid then m.itemBookmarkFolders = response.folders
    renderBookmarkAction()
    if m.bookmarkOverlayOpen then renderBookmarkOverlayFolders()
end sub

sub renderBookmarkAction()
    if m.bookmarkLabel = invalid then return
    count = 0
    if m.itemBookmarkFolders <> invalid then count = m.itemBookmarkFolders.Count()
    if count > 0
        m.bookmarkLabel.text = "Bookmarked (" + StrI(count).Trim() + ")"
    else
        m.bookmarkLabel.text = "Bookmarks"
    end if
    updateBookmarkActionFocus()
end sub

sub updateBookmarkActionFocus()
    if m.bookmarkFocusBg = invalid then return
    palette = detailUiPalette()
    if m.focusArea = "bookmark"
        m.bookmarkFocusBg.color = detailButtonColor(true, false)
        m.bookmarkLabel.color = palette.primaryText
    else
        m.bookmarkFocusBg.color = detailButtonColor(false, false)
        m.bookmarkLabel.color = "#D1D5DB"
    end if
end sub

sub openBookmarkOverlay()
    if m.item = invalid or m.item.itemId <= 0 then return
    m.bookmarkOverlayOpen = true
    m.bookmarkOverlayGroup.visible = true
    m.bookmarkOverlayStatusLabel.text = "Loading folders..."
    m.bookmarkFolders = []
    renderBookmarkOverlayFolders()
    loadBookmarkFoldersForOverlay()
end sub

sub closeBookmarkOverlay()
    m.bookmarkOverlayOpen = false
    m.bookmarkOverlayGroup.visible = false
end sub

sub loadBookmarkFoldersForOverlay()
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadBookmarkFolders"
    task.request = {}
    task.observeField("response", "onBookmarkOverlayFoldersResponse")
    task.control = "RUN"
    m.bookmarkOverlayTask = task
end sub

sub onBookmarkOverlayFoldersResponse(event as Object)
    response = event.getData()
    if response = invalid or response.ok <> true
        if responseRequiresSignIn(response)
            requestSignInAgain(response)
            return
        end if
        message = "Unable to load bookmark folders."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        m.bookmarkOverlayStatusLabel.text = message
        return
    end if

    m.bookmarkFolders = []
    if response.folders <> invalid then m.bookmarkFolders = response.folders
    if m.selectedBookmarkFolderIndex >= m.bookmarkFolders.Count() then m.selectedBookmarkFolderIndex = m.bookmarkFolders.Count() - 1
    if m.selectedBookmarkFolderIndex < 0 then m.selectedBookmarkFolderIndex = 0

    if m.bookmarkFolders.Count() = 0
        m.bookmarkOverlayStatusLabel.text = "No bookmark folders yet."
    else
        m.bookmarkOverlayStatusLabel.text = "Choose a folder"
    end if
    renderBookmarkOverlayFolders()
end sub

sub renderBookmarkOverlayFolders()
    if m.bookmarkOverlayFoldersHost = invalid then return
    palette = detailUiPalette()
    childCount = m.bookmarkOverlayFoldersHost.getChildCount()
    if childCount > 0 then m.bookmarkOverlayFoldersHost.removeChildrenIndex(childCount, 0)
    m.bookmarkOverlayRows = []
    m.bookmarkOverlayRowBgs = []

    maxRows = m.bookmarkFolders.Count()
    if maxRows > 6 then maxRows = 6
    for index = 0 to maxRows - 1
        folder = m.bookmarkFolders[index]
        row = CreateObject("roSGNode", "Group")
        row.translation = [0, index * 50]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = 504
        bg.height = 42
        bg.color = palette.surface
        row.appendChild(bg)

        marker = CreateObject("roSGNode", "Label")
        if bookmarkFolderContainsItem(folder.folderId)
            marker.text = "On"
        else
            marker.text = "Off"
        end if
        marker.translation = [14, 11]
        marker.width = 44
        marker.color = "#D1D5DB"
        row.appendChild(marker)

        label = CreateObject("roSGNode", "Label")
        label.text = folder.title
        label.translation = [64, 11]
        label.width = 360
        label.color = palette.text
        row.appendChild(label)

        count = CreateObject("roSGNode", "Label")
        count.text = bookmarkFolderCountText(folder)
        count.translation = [424, 11]
        count.width = 64
        count.color = palette.muted
        count.horizAlign = "right"
        row.appendChild(count)

        m.bookmarkOverlayFoldersHost.appendChild(row)
        m.bookmarkOverlayRows.Push(row)
        m.bookmarkOverlayRowBgs.Push(bg)
    end for

    updateBookmarkOverlayFocus()
end sub

function bookmarkFolderContainsItem(folderId as Integer) as Boolean
    if m.itemBookmarkFolders = invalid then return false
    for each folder in m.itemBookmarkFolders
        if folder <> invalid and folder.folderId = folderId then return true
    end for
    return false
end function

function bookmarkFolderCountText(folder as Dynamic) as String
    if folder = invalid or folder.count = invalid then return ""
    return StrI(folder.count).Trim()
end function

sub updateBookmarkOverlayFocus()
    palette = detailUiPalette()
    for index = 0 to m.bookmarkOverlayRowBgs.Count() - 1
        if index = m.selectedBookmarkFolderIndex
            m.bookmarkOverlayRowBgs[index].color = palette.surfaceFocus
        else
            m.bookmarkOverlayRowBgs[index].color = palette.surface
        end if
    end for
end sub

sub moveBookmarkOverlayFolder(delta as Integer)
    if m.bookmarkFolders.Count() = 0 then return
    nextIndex = m.selectedBookmarkFolderIndex + delta
    if nextIndex < 0 then nextIndex = 0
    maxIndex = m.bookmarkFolders.Count() - 1
    if maxIndex > 5 then maxIndex = 5
    if nextIndex > maxIndex then nextIndex = maxIndex
    m.selectedBookmarkFolderIndex = nextIndex
    updateBookmarkOverlayFocus()
end sub

sub toggleSelectedBookmarkFolder()
    if m.item = invalid or m.bookmarkFolders.Count() = 0 then return
    folder = m.bookmarkFolders[m.selectedBookmarkFolderIndex]
    m.bookmarkOverlayStatusLabel.text = "Updating bookmark..."

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "toggleItemBookmark"
    task.request = { itemId: m.item.itemId, folderId: folder.folderId }
    task.observeField("response", "onToggleItemBookmarkResponse")
    task.control = "RUN"
    m.toggleBookmarkTask = task
end sub

sub onToggleItemBookmarkResponse(event as Object)
    response = event.getData()
    if response = invalid or response.ok <> true
        if responseRequiresSignIn(response)
            requestSignInAgain(response)
            return
        end if
        message = "Unable to update bookmark."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        m.bookmarkOverlayStatusLabel.text = message
        return
    end if

    m.bookmarkOverlayStatusLabel.text = "Bookmark updated."
    loadItemBookmarkFolders()
    loadBookmarkFoldersForOverlay()
end sub

function joinMetadata(values as Dynamic) as String
    if values = invalid or values.Count() = 0 then return ""

    text = ""
    for index = 0 to values.Count() - 1
        if values[index] <> invalid and values[index] <> ""
            if text <> "" then text = text + "  |  "
            text = text + values[index]
        end if
    end for
    return text
end function

function descriptionOverlayLines() as Object
    lines = []
    if m.descriptionLabel = invalid or m.descriptionLabel.text = invalid or m.descriptionLabel.text = "" then return lines

    text = m.descriptionLabel.text
    lineLength = m.descriptionOverlayLineLength
    if lineLength < 20 then lineLength = 20

    position = 1
    while position <= Len(text)
        lines.Push(Mid(text, position, lineLength))
        position = position + lineLength
    end while

    return lines
end function

sub openDescriptionOverlay()
    lines = descriptionOverlayLines()
    if lines.Count() = 0 then return

    m.descriptionOverlayScrollStart = 0
    m.descriptionOverlayGroup.visible = true
    renderDescriptionOverlayText()
end sub

sub closeDescriptionOverlay()
    if m.descriptionOverlayGroup = invalid then return
    m.descriptionOverlayGroup.visible = false
    m.descriptionOverlayScrollStart = 0
    updateDescriptionFocusVisual()
end sub

sub scrollDescriptionOverlay(delta as Integer)
    if m.descriptionOverlayGroup = invalid or m.descriptionOverlayGroup.visible <> true then return

    lines = descriptionOverlayLines()
    maxStart = lines.Count() - m.descriptionOverlayMaxLines
    if maxStart < 0 then maxStart = 0

    nextStart = m.descriptionOverlayScrollStart + delta
    if nextStart < 0 then nextStart = 0
    if nextStart > maxStart then nextStart = maxStart

    m.descriptionOverlayScrollStart = nextStart
    renderDescriptionOverlayText()
end sub

sub renderDescriptionOverlayText()
    lines = descriptionOverlayLines()
    text = ""
    if lines.Count() > 0
        startIndex = m.descriptionOverlayScrollStart
        lastIndex = startIndex + m.descriptionOverlayMaxLines - 1
        if lastIndex >= lines.Count() then lastIndex = lines.Count() - 1

        for index = startIndex to lastIndex
            if text <> "" then text = text + Chr(10)
            text = text + lines[index]
        end for
    end if

    m.descriptionOverlayTextLabel.text = text
    m.descriptionOverlayScrollUpChevron.visible = m.descriptionOverlayScrollStart > 0
    m.descriptionOverlayScrollDownChevron.visible = (m.descriptionOverlayScrollStart + m.descriptionOverlayMaxLines) < lines.Count()
end sub

sub updateDescriptionFocusVisual()
    if m.descriptionFocusBg = invalid then return
    palette = detailUiPalette()
    m.descriptionFocusBg.color = palette.surfaceFocus
    if m.focusArea = "description" and m.detailGroup.visible = true and m.descriptionOverlayGroup.visible <> true
        m.descriptionFocusBg.opacity = 0.74
    else
        m.descriptionFocusBg.opacity = 0
    end if
end sub

sub renderSeasonTabs()
    palette = detailUiPalette()
    childCount = m.seasonTabsHost.getChildCount()
    if childCount > 0 then m.seasonTabsHost.removeChildrenIndex(childCount, 0)
    m.seasonTabBgs = []
    tabRows = 0

    if m.seasons.Count() = 0
        m.panelTitleLabel.text = "Video"
        updateEpisodeListLayout(0)
        return
    end if

    if m.seasons.Count() <= 1
        m.panelTitleLabel.text = m.seasons[0].title
        updateEpisodeListLayout(0)
        return
    end if

    m.panelTitleLabel.text = "Episodes"
    tabX = 0
    tabY = 0
    tabRows = 1

    for index = 0 to m.seasons.Count() - 1
        if tabX > 0 and tabX + m.seasonTabWidth > m.seasonTabPanelWidth
            tabX = 0
            tabY = tabY + m.seasonTabRowHeight
            tabRows = tabRows + 1
        end if

        tabGroup = CreateObject("roSGNode", "Group")
        tabGroup.translation = [tabX, tabY]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = m.seasonTabWidth
        bg.height = m.seasonTabHeight
        bg.color = palette.surface
        tabGroup.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.text = "S" + StrI(m.seasons[index].number).Trim()
        label.translation = [20, 10]
        label.color = "#D1D5DB"
        tabGroup.appendChild(label)

        m.seasonTabsHost.appendChild(tabGroup)
        m.seasonTabBgs.Push(bg)
        tabX = tabX + m.seasonTabWidth + m.seasonTabGap
    end for

    updateEpisodeListLayout(tabRows)
end sub

sub updateEpisodeListLayout(tabRows as Integer)
    m.episodeListY = m.baseEpisodeListY
    if tabRows > 1
        m.episodeListY = m.baseEpisodeListY + ((tabRows - 1) * m.seasonTabRowHeight)
    end if

    m.episodeListHost.translation = [0, m.episodeListY]
    m.episodeCursor.translation = [0, m.episodeListY]
    if m.episodeScrollUpChevron <> invalid
        m.episodeScrollUpChevron.translation = [396, m.episodeListY]
    end if
    m.noMediaLabel.translation = [0, m.episodeListY + 14]

    availableHeight = m.episodeListBottomY - m.episodeListY
    maxVisible = Int((availableHeight + 10) / 84)
    if maxVisible < 1 then maxVisible = 1
    if maxVisible > m.defaultMaxVisibleEpisodes then maxVisible = m.defaultMaxVisibleEpisodes
    m.maxVisibleEpisodes = maxVisible
    if m.episodeScrollDownChevron <> invalid
        downY = m.episodeListY + ((m.maxVisibleEpisodes - 1) * 84)
        if downY < m.episodeListY then downY = m.episodeListY
        m.episodeScrollDownChevron.translation = [396, downY]
    end if
    updateEpisodeScrollChevrons()
end sub

sub renderEpisodeList()
    childCount = m.episodeListHost.getChildCount()
    if childCount > 0 then m.episodeListHost.removeChildrenIndex(childCount, 0)
    m.episodeRows = []
    m.episodeRowIndexes = []

    if m.seasons.Count() = 0
        showNoPlayableMedia()
        return
    end if

    if m.currentSeasonIndex < 0 then m.currentSeasonIndex = 0
    if m.currentSeasonIndex >= m.seasons.Count()
        m.currentSeasonIndex = m.seasons.Count() - 1
    end if

    episodes = []
    if m.seasons[m.currentSeasonIndex].episodes <> invalid
        episodes = m.seasons[m.currentSeasonIndex].episodes
    end if

    if episodes.Count() = 0
        showNoPlayableMedia()
        return
    end if

    if m.currentEpisodeIndex < 0 then m.currentEpisodeIndex = 0
    if m.currentEpisodeIndex >= episodes.Count()
        m.currentEpisodeIndex = episodes.Count() - 1
    end if
    updateVisibleEpisodeWindow()

    m.noMediaLabel.visible = false
    m.playbackErrorLabel.text = ""
    startIndex = m.visibleEpisodeStart
    lastIndex = startIndex + m.maxVisibleEpisodes - 1
    if lastIndex >= episodes.Count() then lastIndex = episodes.Count() - 1

    for index = startIndex to lastIndex
        episode = episodes[index]
        visibleIndex = index - startIndex
        rowInfo = createEpisodeRow(episode, visibleIndex)
        m.episodeListHost.appendChild(rowInfo.node)
        m.episodeRows.Push(rowInfo.bg)
        m.episodeRowIndexes.Push(index)
    end for
    updateEpisodeScrollChevrons()
end sub

function createEpisodeRow(episode as Object, visibleIndex as Integer) as Object
    palette = detailUiPalette()
    row = CreateObject("roSGNode", "Group")
    row.translation = [0, visibleIndex * 84]

    bg = CreateObject("roSGNode", "Rectangle")
    bg.width = 380
    bg.height = 74
    bg.color = palette.surface
    row.appendChild(bg)

    accent = CreateObject("roSGNode", "Rectangle")
    accent.translation = [0, 0]
    accent.width = 4
    accent.height = 74
    accent.color = palette.primaryFocus
    accent.opacity = 0.52
    row.appendChild(accent)

    title = CreateObject("roSGNode", "Label")
    title.text = episode.title
    title.translation = [18, 10]
    title.width = 290
    title.color = palette.text
    row.appendChild(title)

    subtitle = CreateObject("roSGNode", "Label")
    subtitle.text = mediaSubtitle(episode)
    progressText = episodeProgressText(episode)
    if progressText <> ""
        if subtitle.text <> "" then subtitle.text = subtitle.text + "  |  " + progressText else subtitle.text = progressText
    end if
    subtitle.translation = [18, 42]
    subtitle.width = 330
    subtitle.color = palette.muted
    if episodeWatchStatus(episode) = 0 and progressText <> "" then subtitle.color = palette.success
    row.appendChild(subtitle)

    if episodeWatchStatus(episode) = 1 then appendWatchedCheck(row)

    return { node: row, bg: bg }
end function

sub updateVisibleEpisodeWindow()
    episodes = playableEpisodesForSeason(m.currentSeasonIndex)
    if episodes.Count() = 0
        m.visibleEpisodeStart = 0
        return
    end if

    if m.currentEpisodeIndex < m.visibleEpisodeStart
        m.visibleEpisodeStart = m.currentEpisodeIndex
    else if m.currentEpisodeIndex >= m.visibleEpisodeStart + m.maxVisibleEpisodes
        m.visibleEpisodeStart = m.currentEpisodeIndex - m.maxVisibleEpisodes + 1
    end if

    maxStart = episodes.Count() - m.maxVisibleEpisodes
    if maxStart < 0 then maxStart = 0
    if m.visibleEpisodeStart > maxStart then m.visibleEpisodeStart = maxStart
    if m.visibleEpisodeStart < 0 then m.visibleEpisodeStart = 0
end sub

sub updateEpisodeScrollChevrons()
    if m.episodeScrollUpChevron = invalid or m.episodeScrollDownChevron = invalid then return

    episodes = playableEpisodesForSeason(m.currentSeasonIndex)
    showEpisodeHints = m.detailGroup.visible and episodes.Count() > 0 and episodes.Count() > m.maxVisibleEpisodes
    if showEpisodeHints <> true
        m.episodeScrollUpChevron.visible = false
        m.episodeScrollDownChevron.visible = false
        return
    end if

    m.episodeScrollUpChevron.visible = m.visibleEpisodeStart > 0
    m.episodeScrollDownChevron.visible = (m.visibleEpisodeStart + m.maxVisibleEpisodes) < episodes.Count()
end sub

function mediaSubtitle(media as Object) as String
    parts = []
    if media.seasonNumber > 0
        seasonText = "S" + StrI(media.seasonNumber).Trim()
        episodeText = " E" + StrI(media.episodeNumber).Trim()
        parts.Push(seasonText + episodeText)
    end if
    if media.durationSeconds > 0
        parts.Push(StrI(Int(media.durationSeconds / 60)).Trim() + " min")
    end if
    if media.isPlayable <> true then parts.Push("Unavailable")
    return joinMetadata(parts)
end function

function episodeWatchStatus(media as Dynamic) as Integer
    if media = invalid then return -1
    if media.watchStatus <> invalid then return media.watchStatus
    if media.watched = true then return 1
    if media.progressSeconds <> invalid and media.progressSeconds > 0 then return 0
    return -1
end function

function episodeVideoNumber(media as Dynamic) as Integer
    if media = invalid then return 0
    if media.videoNumber <> invalid and media.videoNumber > 0 then return media.videoNumber
    if media.episodeNumber <> invalid and media.episodeNumber > 0 then return media.episodeNumber
    return 0
end function

function watchedToggleKey(seasonNumber as Integer, videoNumber as Integer) as String
    return StrI(seasonNumber).Trim() + ":" + StrI(videoNumber).Trim()
end function

function episodeProgressText(media as Dynamic) as String
    if media = invalid then return ""
    if episodeWatchStatus(media) <> 0 then return ""
    if media.progressSeconds = invalid or media.progressSeconds <= 0 then return ""

    if media.durationSeconds <> invalid and media.durationSeconds > 0
        percent = Int((media.progressSeconds * 100) / media.durationSeconds)
        if percent < 1 then percent = 1
        if percent > 99 then percent = 99
        return StrI(percent).Trim() + "%"
    end if

    return formatEpisodeProgressTime(media.progressSeconds)
end function

function formatEpisodeProgressTime(seconds as Integer) as String
    if seconds < 0 then seconds = 0
    minutes = Int(seconds / 60)
    remaining = seconds - (minutes * 60)
    remainingText = StrI(remaining).Trim()
    if remaining < 10 then remainingText = "0" + remainingText
    return StrI(minutes).Trim() + ":" + remainingText
end function

sub appendWatchedCheck(row as Object)
    palette = detailUiPalette()
    check = CreateObject("roSGNode", "Label")
    check.text = "✓"
    check.translation = [338, 10]
    check.width = 26
    check.horizAlign = "center"
    check.color = palette.success
    row.appendChild(check)
end sub

sub showState(state as String)
    m.loadingGroup.visible = state = "loading"
    m.errorGroup.visible = state = "error"
    m.detailGroup.visible = state = "detail"
    updateEpisodeScrollChevrons()
    updateDetailExtrasFocusVisuals()
end sub

sub showError(message as String)
    m.errorLabel.text = message
    m.focusArea = "retry"
    showState("error")
end sub

function responseRequiresSignIn(response as Dynamic) as Boolean
    if response = invalid or type(response) <> "roAssociativeArray" then return false
    if response.DoesExist("status") and response.status <> invalid and response.status = 401 then return true
    if response.DoesExist("error") <> true or response.error = invalid then return false
    errorCode = response.error
    if type(errorCode) <> "String" and type(errorCode) <> "roString" then return false
    errorCode = LCase(errorCode)
    return errorCode = "auth_required" or errorCode = "unauthorized" or errorCode = "invalid_grant"
end function

sub requestSignInAgain(response as Dynamic)
    m.top.authRequired = true
end sub

function currentMedia() as Dynamic
    if m.seasons.Count() = 0 then return invalid

    if m.currentSeasonIndex < 0 then m.currentSeasonIndex = 0
    if m.currentSeasonIndex >= m.seasons.Count()
        m.currentSeasonIndex = m.seasons.Count() - 1
    end if

    episodes = []
    if m.seasons[m.currentSeasonIndex].episodes <> invalid
        episodes = m.seasons[m.currentSeasonIndex].episodes
    end if
    if episodes.Count() = 0 then return invalid

    if m.currentEpisodeIndex < 0 then m.currentEpisodeIndex = 0
    if m.currentEpisodeIndex >= episodes.Count()
        m.currentEpisodeIndex = episodes.Count() - 1
    end if

    return episodes[m.currentEpisodeIndex]
end function

function currentEpisodeIsLast() as Boolean
    episodes = playableEpisodesForSeason(m.currentSeasonIndex)
    if episodes.Count() = 0 then return false
    return m.currentEpisodeIndex >= episodes.Count() - 1
end function

sub updateSelectedMediaVisuals()
    palette = detailUiPalette()
    media = currentMedia()
    oldVisibleStart = m.visibleEpisodeStart
    updateVisibleEpisodeWindow()
    if oldVisibleStart <> m.visibleEpisodeStart
        renderEpisodeList()
    end if
    updateEpisodeScrollChevrons()

    for index = 0 to m.seasonTabBgs.Count() - 1
        if index = m.currentSeasonIndex
            m.seasonTabBgs[index].color = palette.primary
        else
            m.seasonTabBgs[index].color = palette.surface
        end if
    end for

    for index = 0 to m.episodeRows.Count() - 1
        rowIndex = m.episodeRowIndexes[index]
        if rowIndex = m.currentEpisodeIndex
            m.episodeRows[index].color = palette.surfaceRaised
        else
            m.episodeRows[index].color = palette.surface
        end if
    end for

    if media = invalid
        m.playButtonLabel.text = "Unavailable"
        m.playFocusBg.color = palette.surface
        m.playButtonLabel.color = "#D1D5DB"
        updateBookmarkActionFocus()
        m.episodeCursor.visible = false
        return
    end if

    if media.isPlayable
        m.playButtonLabel.text = "Play"
        m.playbackErrorLabel.text = ""
    else
        m.playButtonLabel.text = "Unavailable"
        m.playbackErrorLabel.text = "No playable video is available."
    end if

    if m.focusArea = "play"
        m.playFocusBg.color = detailButtonColor(true, true)
    else
        m.playFocusBg.color = detailButtonColor(false, true)
    end if
    m.playButtonLabel.color = palette.primaryText
    updateDescriptionFocusVisual()
    updateBookmarkActionFocus()
    updateDetailExtrasFocusVisuals()

    visibleIndex = m.currentEpisodeIndex - m.visibleEpisodeStart
    m.episodeCursor.translation = [0, m.episodeListY + (visibleIndex * 84)]
    m.episodeCursor.visible = m.focusArea = "episodes" and m.episodeRows.Count() > 0
end sub

sub showNoPlayableMedia()
    m.noMediaLabel.visible = true
    m.playbackErrorLabel.text = "No playable video is available."
    m.episodeCursor.visible = false
    updateEpisodeScrollChevrons()
end sub

sub moveEpisode(delta as Integer)
    if m.seasons.Count() = 0 then return
    if m.currentSeasonIndex < 0 or m.currentSeasonIndex >= m.seasons.Count() then return

    episodes = []
    if m.seasons[m.currentSeasonIndex].episodes <> invalid
        episodes = m.seasons[m.currentSeasonIndex].episodes
    end if
    if episodes.Count() = 0 then return

    nextIndex = m.currentEpisodeIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= episodes.Count() then nextIndex = episodes.Count() - 1

    m.currentEpisodeIndex = nextIndex
    m.playbackErrorLabel.text = ""
    updateSelectedMediaVisuals()
end sub

sub moveSeason(delta as Integer)
    if m.seasons.Count() <= 1 then return

    nextIndex = m.currentSeasonIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.seasons.Count() then nextIndex = m.seasons.Count() - 1
    if nextIndex = m.currentSeasonIndex then return

    m.currentSeasonIndex = nextIndex
    m.currentEpisodeIndex = 0
    m.playbackErrorLabel.text = ""
    renderEpisodeList()
    updateSelectedMediaVisuals()
end sub

sub toggleCurrentEpisodeWatched()
    if m.pendingWatchedToggleKey <> "" then return
    if m.item = invalid or m.item.itemId <= 0 then return

    media = currentMedia()
    if media = invalid
        m.playbackErrorLabel.text = "Unable to update watched status."
        return
    end if

    seasonNumber = 0
    if media.seasonNumber <> invalid then seasonNumber = media.seasonNumber
    videoNumber = episodeVideoNumber(media)
    if videoNumber <= 0
        m.playbackErrorLabel.text = "Unable to update watched status."
        return
    end if

    targetWatched = episodeWatchStatus(media) <> 1
    m.pendingWatchedToggleKey = watchedToggleKey(seasonNumber, videoNumber)
    m.playbackErrorLabel.text = "Updating watched status..."

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "toggleEpisodeWatched"
    task.request = {
        itemId: m.item.itemId
        seasonNumber: seasonNumber
        videoNumber: videoNumber
        watched: targetWatched
    }
    task.observeField("response", "onToggleEpisodeWatchedResponse")
    task.control = "RUN"
    m.toggleWatchedTask = task
end sub

sub onToggleEpisodeWatchedResponse(event as Object)
    response = event.getData()
    m.toggleWatchedTask = invalid
    pendingKey = m.pendingWatchedToggleKey
    m.pendingWatchedToggleKey = ""

    if response = invalid or response.ok <> true
        if responseRequiresSignIn(response)
            requestSignInAgain(response)
            return
        end if
        message = "Unable to update watched status."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        m.playbackErrorLabel.text = message
        return
    end if

    if watchedToggleKey(response.seasonNumber, response.videoNumber) <> pendingKey then return
    applyEpisodeWatchedState(response.seasonNumber, response.videoNumber, response.watched)
    if response.watched = true
        m.playbackErrorLabel.text = "Marked watched."
    else
        m.playbackErrorLabel.text = "Marked unwatched."
    end if
end sub

sub applyEpisodeWatchedState(seasonNumber as Integer, videoNumber as Integer, watched as Boolean)
    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        seasonMatches = true
        if seasonNumber > 0 and season <> invalid and season.number <> invalid and season.number <> seasonNumber then seasonMatches = false

        if season <> invalid and season.episodes <> invalid and seasonMatches
            for episodeIndex = 0 to season.episodes.Count() - 1
                episode = season.episodes[episodeIndex]
                if episode <> invalid and episodeVideoNumber(episode) = videoNumber
                    episode.watched = watched
                    if watched
                        episode.watchStatus = 1
                    else
                        episode.watchStatus = -1
                    end if
                    episode.progressSeconds = 0
                    if seasonIndex = m.currentSeasonIndex then renderEpisodeList()
                    updateSelectedMediaVisuals()
                    return
                end if
            end for
        end if
    end for
end sub

sub startSelectedPlayback()
    media = currentMedia()
    if media = invalid
        m.playbackErrorLabel.text = "No playable video is available."
        return
    end if
    if media.isPlayable <> true
        m.playbackErrorLabel.text = "No playable video is available."
        return
    end if

    streamUrl = ""
    if media.streamUrl <> invalid then streamUrl = media.streamUrl
    if streamUrl = ""
        m.playbackErrorLabel.text = "No playable video is available."
        return
    end if

    startPlaybackPreflight(media)
end sub

function playbackPayloadForMedia(media as Object) as Object
    videoNumber = 1
    if media.videoNumber <> invalid then videoNumber = media.videoNumber else videoNumber = media.episodeNumber

    return {
        itemId: m.item.itemId
        mediaId: media.mediaId
        itemTitle: m.item.title
        title: media.title
        subtitle: media.subtitle
        seasonNumber: media.seasonNumber
        episodeNumber: media.episodeNumber
        videoNumber: videoNumber
        durationSeconds: media.durationSeconds
        progressSeconds: media.progressSeconds
        watchStatus: media.watchStatus
        watched: media.watched
        streamUrl: media.streamUrl
        streamFormat: media.streamFormat
        qualityOptions: media.qualityOptions
        audioTracks: media.audioTracks
        subtitleTracks: media.subtitleTracks
        seasonEpisodes: seasonEpisodesForMedia(media)
    }
end function

function seasonEpisodesForMedia(media as Dynamic) as Object
    episodes = []
    if media = invalid or m.seasons = invalid then return episodes
    if media.seasonNumber = invalid or media.seasonNumber <= 0 then return episodes

    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        if season <> invalid and season.number <> invalid and season.number = media.seasonNumber
            if season.episodes = invalid then return episodes
            for each episode in season.episodes
                payload = seasonCarouselEpisodePayload(episode)
                if payload <> invalid then episodes.Push(payload)
            end for
            return episodes
        end if
    end for

    return episodes
end function

function seasonCarouselEpisodePayload(episode as Dynamic) as Dynamic
    if episode = invalid then return invalid

    videoNumber = 1
    if episode.videoNumber <> invalid then videoNumber = episode.videoNumber else videoNumber = episode.episodeNumber

    return {
        itemId: m.item.itemId
        mediaId: episode.mediaId
        itemTitle: m.item.title
        title: episode.title
        subtitle: episode.subtitle
        seasonNumber: episode.seasonNumber
        episodeNumber: episode.episodeNumber
        videoNumber: videoNumber
        durationSeconds: episode.durationSeconds
        progressSeconds: episode.progressSeconds
        watchStatus: episode.watchStatus
        watched: episode.watched
        thumbnailUrl: episode.thumbnailUrl
        isPlayable: episode.isPlayable
        streamUrl: episode.streamUrl
        streamFormat: episode.streamFormat
        qualityOptions: episode.qualityOptions
        audioTracks: episode.audioTracks
        subtitleTracks: episode.subtitleTracks
    }
end function

sub startPlaybackPreflight(media as Object)
    payload = playbackPayloadForMedia(media)
    mediaId = 0
    if media.mediaId <> invalid then mediaId = media.mediaId

    if mediaId <= 0
        m.top.playbackRequested = payload
        return
    end if

    if m.pendingPlaybackMediaId = mediaId
        return
    end if

    m.pendingPlaybackMediaId = mediaId
    m.pendingPlaybackPayload = payload
    m.playbackErrorLabel.text = "Preparing video..."

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "refreshMediaLinks"
    task.request = { media: media }
    task.observeField("response", "onMediaLinksRefreshResponse")
    task.control = "RUN"
    m.mediaLinksTask = task
end sub

sub onMediaLinksRefreshResponse(event as Object)
    response = event.getData()
    fallbackPayload = m.pendingPlaybackPayload
    pendingMediaId = m.pendingPlaybackMediaId
    m.pendingPlaybackMediaId = 0
    m.pendingPlaybackPayload = invalid
    m.mediaLinksTask = invalid

    if pendingMediaId <= 0 then return

    if responseRequiresSignIn(response)
        requestSignInAgain(response)
        return
    end if

    if response <> invalid and response.ok = true and response.media <> invalid
        responseMediaId = 0
        if response.media.mediaId <> invalid then responseMediaId = response.media.mediaId
        if responseMediaId <> pendingMediaId then return
        m.playbackErrorLabel.text = ""
        m.top.playbackRequested = playbackPayloadForMedia(response.media)
        return
    end if

    if fallbackPayload <> invalid and fallbackPayload.streamUrl <> invalid and fallbackPayload.streamUrl <> ""
        m.playbackErrorLabel.text = ""
        m.top.playbackRequested = fallbackPayload
        return
    end if

    message = "No playable video is available."
    if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
    m.playbackErrorLabel.text = message
end sub

sub onNextPlaybackRequested(event as Object)
    request = event.getData()
    reason = nextPlaybackRequestReason(request)
    if reason = "seasonCarousel"
        media = requestedPlayableMedia(request)
    else
        media = nextPlayableMediaAfter(request)
    end if
    if media = invalid
        m.top.nextPlayback = {
            ok: false
            reason: reason
            message: "No next episode is available."
        }
        return
    end if

    prepareNextPlaybackPreflight(media, request)
end sub

function nextPlayableMediaAfter(request as Dynamic) as Dynamic
    if request = invalid or m.seasons = invalid or m.seasons.Count() = 0 then return invalid

    requestMediaId = nextPlaybackIntegerField(request, "mediaId", 0)
    requestSeasonNumber = nextPlaybackIntegerField(request, "seasonNumber", 0)
    requestVideoNumber = nextPlaybackIntegerField(request, "videoNumber", 0)
    requestEpisodeNumber = nextPlaybackIntegerField(request, "episodeNumber", requestVideoNumber)

    foundCurrent = false
    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        episodes = []
        if season <> invalid and season.episodes <> invalid then episodes = season.episodes

        for episodeIndex = 0 to episodes.Count() - 1
            episode = episodes[episodeIndex]
            if foundCurrent and episode <> invalid and episode.isPlayable = true then return episode

            if nextPlaybackMatchesMedia(episode, requestMediaId, requestSeasonNumber, requestVideoNumber, requestEpisodeNumber)
                foundCurrent = true
            end if
        end for
    end for

    return invalid
end function

function requestedPlayableMedia(request as Dynamic) as Dynamic
    if request = invalid or m.seasons = invalid or m.seasons.Count() = 0 then return invalid

    requestMediaId = nextPlaybackIntegerField(request, "mediaId", 0)
    requestSeasonNumber = nextPlaybackIntegerField(request, "seasonNumber", 0)
    requestVideoNumber = nextPlaybackIntegerField(request, "videoNumber", 0)
    requestEpisodeNumber = nextPlaybackIntegerField(request, "episodeNumber", requestVideoNumber)

    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        episodes = []
        if season <> invalid and season.episodes <> invalid then episodes = season.episodes

        for episodeIndex = 0 to episodes.Count() - 1
            episode = episodes[episodeIndex]
            if episode <> invalid and episode.isPlayable = true and nextPlaybackMatchesMedia(episode, requestMediaId, requestSeasonNumber, requestVideoNumber, requestEpisodeNumber)
                return episode
            end if
        end for
    end for

    return invalid
end function

function nextPlaybackMatchesMedia(media as Dynamic, requestMediaId as Integer, requestSeasonNumber as Integer, requestVideoNumber as Integer, requestEpisodeNumber as Integer) as Boolean
    if media = invalid then return false
    if requestMediaId > 0 and media.mediaId <> invalid and media.mediaId = requestMediaId then return true

    mediaSeasonNumber = 0
    if media.seasonNumber <> invalid then mediaSeasonNumber = media.seasonNumber
    if requestSeasonNumber > 0 and mediaSeasonNumber <> requestSeasonNumber then return false

    mediaVideoNumber = 0
    if media.videoNumber <> invalid then mediaVideoNumber = media.videoNumber
    if requestVideoNumber > 0 and mediaVideoNumber = requestVideoNumber then return true

    mediaEpisodeNumber = 0
    if media.episodeNumber <> invalid then mediaEpisodeNumber = media.episodeNumber
    return requestEpisodeNumber > 0 and mediaEpisodeNumber = requestEpisodeNumber
end function

sub prepareNextPlaybackPreflight(media as Object, request as Dynamic)
    payload = playbackPayloadForMedia(media)
    reason = nextPlaybackRequestReason(request)
    payload.requestReason = reason
    mediaId = 0
    if media.mediaId <> invalid then mediaId = media.mediaId

    if mediaId <= 0
        m.top.nextPlayback = { ok: true, playback: payload, reason: reason }
        return
    end if

    m.pendingNextPlaybackMediaId = mediaId
    m.pendingNextPlaybackPayload = payload

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "refreshMediaLinks"
    task.request = { media: media }
    task.observeField("response", "onNextMediaLinksRefreshResponse")
    task.control = "RUN"
    m.nextMediaLinksTask = task
end sub

sub onNextMediaLinksRefreshResponse(event as Object)
    response = event.getData()
    fallbackPayload = m.pendingNextPlaybackPayload
    reason = nextPlaybackRequestReasonFromPayload(fallbackPayload)
    pendingMediaId = m.pendingNextPlaybackMediaId
    m.pendingNextPlaybackMediaId = 0
    m.pendingNextPlaybackPayload = invalid
    m.nextMediaLinksTask = invalid

    if pendingMediaId <= 0 then return

    if responseRequiresSignIn(response)
        requestSignInAgain(response)
        return
    end if

    if response <> invalid and response.ok = true and response.media <> invalid
        responseMediaId = 0
        if response.media.mediaId <> invalid then responseMediaId = response.media.mediaId
        if responseMediaId = pendingMediaId
            m.top.nextPlayback = { ok: true, playback: playbackPayloadForMedia(response.media), reason: reason }
            return
        end if
        if fallbackPayload <> invalid and fallbackPayload.streamUrl <> invalid and fallbackPayload.streamUrl <> ""
            m.top.nextPlayback = { ok: true, playback: fallbackPayload, reason: reason }
            return
        end if
        message = "No playable next episode is available."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        m.top.nextPlayback = { ok: false, message: message, reason: reason }
        return
    end if

    if fallbackPayload <> invalid and fallbackPayload.streamUrl <> invalid and fallbackPayload.streamUrl <> ""
        m.top.nextPlayback = { ok: true, playback: fallbackPayload, reason: reason }
        return
    end if

    message = "No playable next episode is available."
    if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
    m.top.nextPlayback = { ok: false, message: message, reason: reason }
end sub

function nextPlaybackRequestReason(request as Dynamic) as String
    if request = invalid or type(request) <> "roAssociativeArray" then return ""
    if request.DoesExist("reason") <> true or request.reason = invalid then return ""
    if type(request.reason) = "String" or type(request.reason) = "roString" then return request.reason
    return ""
end function

function nextPlaybackRequestReasonFromPayload(payload as Dynamic) as String
    if payload = invalid or type(payload) <> "roAssociativeArray" then return ""
    if payload.DoesExist("requestReason") <> true or payload.requestReason = invalid then return ""
    if type(payload.requestReason) = "String" or type(payload.requestReason) = "roString" then return payload.requestReason
    return ""
end function

function nextPlaybackIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

sub cancelPlaybackPreflight()
    if m.mediaLinksTask <> invalid then m.mediaLinksTask.control = "STOP"
    m.mediaLinksTask = invalid
    m.pendingPlaybackMediaId = 0
    m.pendingPlaybackPayload = invalid
    if m.nextMediaLinksTask <> invalid then m.nextMediaLinksTask.control = "STOP"
    m.nextMediaLinksTask = invalid
    m.pendingNextPlaybackMediaId = 0
    m.pendingNextPlaybackPayload = invalid
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false

    if m.bookmarkOverlayOpen
        if key = "back"
            closeBookmarkOverlay()
            return true
        else if key = "up"
            moveBookmarkOverlayFolder(-1)
            return true
        else if key = "down"
            moveBookmarkOverlayFolder(1)
            return true
        else if key = "OK"
            toggleSelectedBookmarkFolder()
            return true
        end if
        return true
    end if

    if m.descriptionOverlayGroup.visible
        if key = "back" or key = "OK"
            closeDescriptionOverlay()
            return true
        else if key = "up"
            scrollDescriptionOverlay(-1)
            return true
        else if key = "down"
            scrollDescriptionOverlay(1)
            return true
        end if
        return true
    end if

    if key = "back"
        cancelPlaybackPreflight()
        m.top.backRequested = true
        return true
    end if

    if m.errorGroup.visible
        if key = "OK"
            loadDetail()
            return true
        end if
        return false
    end if

    if m.detailGroup.visible <> true then return false

    if m.focusArea = "episodes"
        if key = "up"
            moveEpisode(-1)
            return true
        else if key = "down"
            if currentEpisodeIsLast() and firstDetailExtrasFocusArea() <> ""
                m.focusArea = firstDetailExtrasFocusArea()
                updateSelectedMediaVisuals()
                return true
            end if
            moveEpisode(1)
            return true
        else if key = "left"
            if m.seasons.Count() > 1 and m.currentSeasonIndex > 0
                moveSeason(-1)
            else
                m.focusArea = "play"
                updateSelectedMediaVisuals()
            end if
            return true
        else if key = "right"
            moveSeason(1)
            return true
        else if key = "OK"
            startSelectedPlayback()
            return true
        else if key = "options"
            toggleCurrentEpisodeWatched()
            return true
        end if
    else if m.focusArea = "play"
        if key = "up"
            m.focusArea = "description"
            updateSelectedMediaVisuals()
            return true
        else if key = "down"
            extrasFocus = firstDetailExtrasFocusArea()
            if extrasFocus <> ""
                m.focusArea = extrasFocus
                updateSelectedMediaVisuals()
                return true
            end if
        else if key = "right"
            m.focusArea = "bookmark"
            updateSelectedMediaVisuals()
            return true
        else if key = "OK"
            startSelectedPlayback()
            return true
        end if
    else if m.focusArea = "bookmark"
        if key = "up"
            m.focusArea = "description"
            updateSelectedMediaVisuals()
            return true
        else if key = "down"
            extrasFocus = firstDetailExtrasFocusArea()
            if extrasFocus <> ""
                m.focusArea = extrasFocus
            else
                m.focusArea = "play"
            end if
            updateSelectedMediaVisuals()
            return true
        else if key = "left"
            m.focusArea = "play"
            updateSelectedMediaVisuals()
            return true
        else if key = "right"
            m.focusArea = "episodes"
            updateSelectedMediaVisuals()
            return true
        else if key = "OK"
            openBookmarkOverlay()
            return true
        end if
    else if m.focusArea = "description"
        if key = "down"
            m.focusArea = "play"
            updateSelectedMediaVisuals()
            return true
        else if key = "right"
            m.focusArea = "episodes"
            updateSelectedMediaVisuals()
            return true
        else if key = "OK"
            openDescriptionOverlay()
            return true
        end if
    else if m.focusArea = "trailer"
        if key = "up"
            m.focusArea = "episodes"
            updateSelectedMediaVisuals()
            return true
        else if key = "down"
            if hasSimilarItems()
                m.focusArea = "similar"
            else
                m.focusArea = "play"
            end if
            updateSelectedMediaVisuals()
            return true
        else if key = "left"
            m.focusArea = "play"
            updateSelectedMediaVisuals()
            return true
        else if key = "right"
            if hasSimilarItems()
                m.focusArea = "similar"
            else
                m.focusArea = "episodes"
            end if
            updateSelectedMediaVisuals()
            return true
        else if key = "OK"
            startTrailerPlayback()
            return true
        end if
    else if m.focusArea = "similar"
        if key = "up"
            if hasPlayableTrailer()
                m.focusArea = "trailer"
            else
                m.focusArea = "episodes"
            end if
            updateSelectedMediaVisuals()
            return true
        else if key = "left"
            moveSimilar(-1)
            return true
        else if key = "right"
            moveSimilar(1)
            return true
        else if key = "OK"
            selectSimilarItem()
            return true
        end if
    end if

    return false
end function
