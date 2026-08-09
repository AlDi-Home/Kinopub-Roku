' Video detail screen — full-bleed hero (backdrop art, title, description,
' Play/Trailer/Bookmark action stack) with a below-hero region that shows
' EITHER a "Сезоны" row of poster-card tiles OR the active season's episode
' list, never both at once (see videoDetailScreenApplySectionVisibility) —
' matching the reference app's flow, where selecting a season opens a
' dedicated episode view rather than an inline expansion.
'
' This is a full rewrite of the previous dark, split-panel screen. The
' interface (8 fields below) is byte-identical to before — AppScene.brs
' needs no changes. Data loading, the "auto-focus first unwatched episode"
' priority scan, Play/Trailer preflight payloads, the next-episode/in-player
' season-carousel contract (onNextPlaybackRequested and everything it calls),
' and the bookmark-folder overlay are ported from the old file with the same
' behavior, restyled to the light theme. Dropped in this pass: the modal
' "read full description" overlay, the recommendations ("Similar") rail, and
' the detailed tech-info panel — see CHANGELOG/the design plan for why.
'
' All top-level helpers are prefixed videoDetailScreen* — see
' BrowseScreen.brs's header comment for why (every sub/function in this
' channel is global regardless of which component's <script> tags loaded it;
' init()/onKeyEvent()/observeField-callback names are the exception). The
' old file used unprefixed names; fixed as part of this rewrite.

sub init()
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    m.errorLabel = m.top.findNode("errorLabel")
    m.detailGroup = m.top.findNode("detailGroup")
    m.detailScrollHost = m.top.findNode("detailScrollHost")

    m.backdropPoster = m.top.findNode("backdropPoster")
    m.heroTitleLabel = m.top.findNode("heroTitleLabel")
    m.heroMetaLabel = m.top.findNode("heroMetaLabel")
    m.heroBadgesHost = m.top.findNode("heroBadgesHost")
    m.descriptionFocusBg = m.top.findNode("descriptionFocusBg")
    m.heroDescriptionLabel = m.top.findNode("heroDescriptionLabel")
    m.heroActionsHost = m.top.findNode("heroActionsHost")
    m.playbackErrorLabel = m.top.findNode("playbackErrorLabel")

    m.descriptionOverlayGroup = m.top.findNode("descriptionOverlayGroup")
    m.descriptionOverlayTitleLabel = m.top.findNode("descriptionOverlayTitleLabel")
    m.descriptionOverlayTextLabel = m.top.findNode("descriptionOverlayTextLabel")

    m.contentSection = m.top.findNode("contentSection")
    m.contentHost = m.top.findNode("contentHost")
    m.contentClipHost = m.top.findNode("contentClipHost")
    m.episodesSection = m.top.findNode("episodesSection")
    m.episodesHeadingLabel = m.top.findNode("episodesHeadingLabel")
    m.episodesHost = m.top.findNode("episodesHost")
    m.episodesClipHost = m.top.findNode("episodesClipHost")
    m.noMediaLabel = m.top.findNode("noMediaLabel")

    m.bookmarkOverlayGroup = m.top.findNode("bookmarkOverlayGroup")
    m.bookmarkOverlayStatusLabel = m.top.findNode("bookmarkOverlayStatusLabel")
    m.bookmarkOverlayFoldersHost = m.top.findNode("bookmarkOverlayFoldersHost")

    ' Content row list (seasons tiles / recommendations rail / ratings /
    ' tech info), stacked vertically below the hero and scrolled into view
    ' exactly like the episode list (flat render + animated
    ' translation) — see videoDetailScreenRenderContent. Rail-type rows
    ' (seasons/recommendations) reuse the same clip-padding trick as
    ' BrowseScreen.brs's grid for their createPosterCard tiles' focus-pop
    ' scale effect. The clip starts above the below-hero boundary (-railPad,
    ' not 0) since — unlike Stage 1's single always-visible "Сезоны" label —
    ' there's no static heading outside the clip to avoid overlapping; every
    ' row (headings included) is built fully at runtime inside contentHost.
    m.railCardWidth = 170
    m.railCardGapX = 22
    m.railPad = 44
    m.maxVisibleRailTiles = 6
    m.railContentWidth = (m.railCardWidth * m.maxVisibleRailTiles) + (m.railCardGapX * (m.maxVisibleRailTiles - 1))
    m.contentViewportHeight = 340
    m.contentClipHost.translation = [64 - m.railPad, -m.railPad]
    m.contentClipHost.clippingRect = [0, 0, m.railContentWidth + (m.railPad * 2), m.contentViewportHeight + (m.railPad * 2)]
    m.contentHost.translation = [m.railPad, m.railPad]
    m.contentScrollOffsetY = 0
    m.contentScrollAnimation = invalid
    m.contentScrollInterpolator = invalid
    m.contentRows = []
    m.contentRowIndex = 0

    ' Episode list: flat render, scrolled into view via animated translation
    ' on episodesHost (ContinueScreen.brs's continueScreenScrollGridToFocus
    ' pattern) — no per-row scale effect here, so no clip padding needed.
    m.episodeRowStep = 84
    m.episodesViewportHeightDefault = 284
    ' Once inside the episode list, the whole page (detailGroup, hero
    ' included) scrolls up by the hero's full height so the list gets nearly
    ' the whole screen instead of just the ~284px strip below a permanently
    ' pinned hero — see videoDetailScreenSetHeroScrolled.
    m.episodesViewportHeightExpanded = 640
    m.episodesViewportHeight = m.episodesViewportHeightDefault
    m.episodesClipHost.translation = [64, 56]
    m.episodesClipHost.clippingRect = [0, 0, 1152, m.episodesViewportHeight]
    m.episodesHost.translation = [0, 0]
    m.heroScrollOffset = 380
    m.heroScrolled = false
    m.heroScrollAnimation = invalid
    m.heroScrollInterpolator = invalid

    m.selection = invalid
    m.item = invalid
    m.trailer = invalid
    m.detailRequestGeneration = 0
    m.isSeries = false
    m.hasSeasonsRow = false
    m.seasons = []
    m.currentSeasonIndex = 0
    m.currentEpisodeIndex = 0
    m.focusArea = "actions"
    m.selectedActionIndex = 0
    m.actionRows = []
    m.episodeRowNodes = []
    m.episodesScrollOffsetY = 0
    m.episodesScrollAnimation = invalid
    m.episodesScrollInterpolator = invalid

    m.bookmarkFolders = []
    m.itemBookmarkFolders = []
    m.bookmarkOverlayRowNodes = []
    m.selectedBookmarkFolderIndex = 0
    m.bookmarkOverlayOpen = false
    m.descriptionOverlayOpen = false

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

sub onSelectionChanged(event as Object)
    m.selection = event.getData()
    videoDetailScreenLoadDetail()
end sub

sub onReloadRequested(event as Object)
    if event.getData() = true then videoDetailScreenLoadDetail()
end sub

sub onPlaybackError(event as Object)
    message = event.getData()
    if message <> invalid and message <> "" then videoDetailScreenSetStatusMessage(message)
end sub

sub videoDetailScreenSetStatusMessage(text as String)
    m.playbackErrorLabel.text = text
    m.playbackErrorLabel.visible = text <> ""
end sub

' ---------------------------------------------------------------------------
' Data load
' ---------------------------------------------------------------------------

sub videoDetailScreenLoadDetail()
    if m.selection = invalid or m.selection.itemId = invalid or m.selection.itemId <= 0
        videoDetailScreenShowError("Не удалось открыть это видео.")
        return
    end if

    videoDetailScreenShowState("loading")
    m.detailRequestGeneration = m.detailRequestGeneration + 1
    requestGeneration = m.detailRequestGeneration
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadItemDetail"
    task.request = {
        itemId: m.selection.itemId
        mediaId: videoDetailScreenSelectedMediaId()
        generation: requestGeneration
    }
    if m.selection.DoesExist("targetSeasonNumber") then task.request.targetSeasonNumber = m.selection.targetSeasonNumber
    if m.selection.DoesExist("targetEpisodeNumber") then task.request.targetEpisodeNumber = m.selection.targetEpisodeNumber
    if m.selection.DoesExist("seasonNumber") then task.request.seasonNumber = m.selection.seasonNumber
    if m.selection.DoesExist("episodeNumber") then task.request.episodeNumber = m.selection.episodeNumber
    task.observeField("response", "onDetailResponse")
    task.control = "RUN"
    m.detailTask = task
end sub

' A newer videoDetailScreenLoadDetail() call (e.g. selecting a recommendation
' tile reloads this same screen instance) can leave an older ContentTask
' still running on its own thread with no way to cancel it — Roku Tasks have
' no cancel-on-reassignment lifecycle event, so its response would otherwise
' still land here and overwrite the newer page. Ignore anything that isn't
' for the request we're currently waiting on.
sub onDetailResponse(event as Object)
    response = event.getData()
    if response <> invalid and response.generation <> invalid and response.generation <> m.detailRequestGeneration then return
    if response = invalid or response.ok <> true
        if videoDetailScreenResponseRequiresSignIn(response)
            videoDetailScreenRequestSignInAgain(response)
            return
        end if
        message = "Не удалось загрузить информацию о видео."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        videoDetailScreenShowError(message)
        return
    end if

    if response.item = invalid
        videoDetailScreenShowError("Информация о видео недоступна.")
        return
    end if

    m.item = response.item
    m.trailer = invalid
    videoDetailScreenCancelPlaybackPreflight()
    videoDetailScreenBuildPlayableModel()
    m.isSeries = m.item.seasons <> invalid and m.item.seasons.Count() > 0
    ' Folds in the rare multi-part-movie case (no real season data, but more
    ' than one video) so it gets the same tile->dedicated-episode-view
    ' treatment as a single-season serial, via the same seasons row in
    ' videoDetailScreenRenderContent — instead of a separate direct
    ' actions->episodes fallback, which would otherwise be unreachable now
    ' that "content" (almost always available, at minimum the info row)
    ' outranks it in the Down-from-actions priority chain.
    m.hasSeasonsRow = m.isSeries or (m.seasons.Count() = 1 and videoDetailScreenPlayableEpisodesForSeason(0).Count() > 1)

    m.focusArea = "actions"
    m.selectedActionIndex = 0
    m.contentRowIndex = 0
    m.contentScrollOffsetY = 0
    m.contentHost.translation = [m.railPad, m.railPad]
    videoDetailScreenSetStatusMessage("")
    m.heroScrolled = false
    m.detailScrollHost.translation = [0, 0]
    m.episodesViewportHeight = m.episodesViewportHeightDefault
    m.episodesClipHost.clippingRect = [0, 0, 1152, m.episodesViewportHeight]
    videoDetailScreenCloseDescriptionOverlay()

    videoDetailScreenRenderHero()
    videoDetailScreenRenderActions()
    videoDetailScreenRenderContent()
    videoDetailScreenRenderEpisodes()
    videoDetailScreenApplySectionVisibility()
    videoDetailScreenUpdateDescriptionFocus()
    videoDetailScreenLoadItemBookmarkFolders()
    videoDetailScreenShowState("detail")
    videoDetailScreenLoadDetailExtras(response.itemId, m.detailRequestGeneration)
end sub

' Similar items (recommendations row) and the trailer are non-critical —
' fired only after the base page has already rendered, so they never delay
' first paint (see contentTaskLoadItemDetailExtras).
sub videoDetailScreenLoadDetailExtras(itemId as Integer, requestGeneration as Integer)
    task = CreateObject("roSGNode", "ContentTask")
    task.command = "loadItemDetailExtras"
    task.request = { itemId: itemId, generation: requestGeneration }
    task.observeField("response", "onDetailExtrasResponse")
    task.control = "RUN"
    m.detailExtrasTask = task
end sub

sub onDetailExtrasResponse(event as Object)
    response = event.getData()
    if response = invalid or response.generation <> m.detailRequestGeneration then return
    if response.ok <> true or m.item = invalid then return

    m.item.similarItems = response.similarItems
    m.item.trailer = response.trailer
    m.trailer = response.trailer

    previousActionId = ""
    if m.actionRows.Count() > 0 and m.selectedActionIndex < m.actionRows.Count() then previousActionId = m.actionRows[m.selectedActionIndex].id
    videoDetailScreenRenderActions()
    if previousActionId <> ""
        for i = 0 to m.actionRows.Count() - 1
            if m.actionRows[i].id = previousActionId
                m.selectedActionIndex = i
                exit for
            end if
        end for
        videoDetailScreenUpdateActionsFocus()
    end if

    ' The recommendations row is only safe to splice into the already-built
    ' content row list before the user has scrolled into it — recommendations
    ' arrive well before hero->actions->content navigation is realistically
    ' possible, so skipping the rare late case is not a practical regression.
    if m.focusArea = "actions" or m.focusArea = "description"
        videoDetailScreenRenderContent()
    end if
end sub

function videoDetailScreenSelectedMediaId() as Integer
    if m.selection = invalid or m.selection.mediaId = invalid then return 0
    return m.selection.mediaId
end function

sub videoDetailScreenShowState(state as String)
    m.loadingGroup.visible = state = "loading"
    m.errorGroup.visible = state = "error"
    m.detailGroup.visible = state = "detail"
end sub

sub videoDetailScreenShowError(message as String)
    m.errorLabel.text = message
    videoDetailScreenShowState("error")
end sub

function videoDetailScreenResponseRequiresSignIn(response as Dynamic) as Boolean
    if response = invalid or type(response) <> "roAssociativeArray" then return false
    if response.DoesExist("status") and response.status <> invalid and response.status = 401 then return true
    if response.DoesExist("error") <> true or response.error = invalid then return false
    errorCode = response.error
    if type(errorCode) <> "String" and type(errorCode) <> "roString" then return false
    errorCode = LCase(errorCode)
    return errorCode = "auth_required" or errorCode = "unauthorized" or errorCode = "invalid_grant"
end function

sub videoDetailScreenRequestSignInAgain(response as Dynamic)
    m.top.authRequired = true
end sub

function videoDetailScreenIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

' ---------------------------------------------------------------------------
' Playable model — which season/episode is "active", and the auto-focus
' "first unwatched" priority scan. Ported verbatim from the old file's
' buildPlayableModel/selectTargetEpisodeFromResponse.
' ---------------------------------------------------------------------------

function videoDetailScreenPlayableEpisodesForSeason(seasonIndex as Integer) as Object
    if seasonIndex < 0 or seasonIndex >= m.seasons.Count() then return []
    if m.seasons[seasonIndex].episodes = invalid then return []
    return m.seasons[seasonIndex].episodes
end function

sub videoDetailScreenBuildPlayableModel()
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
        m.seasons.Push({ title: "Видео", number: 0, episodes: videos })
    end if

    m.currentSeasonIndex = 0
    m.currentEpisodeIndex = 0
    if videoDetailScreenSelectTargetEpisodeFromResponse(m.selection) then return
    targetMediaId = videoDetailScreenSelectedMediaId()

    if targetMediaId > 0
        for seasonIndex = 0 to m.seasons.Count() - 1
            episodes = videoDetailScreenPlayableEpisodesForSeason(seasonIndex)
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
        episodes = videoDetailScreenPlayableEpisodesForSeason(seasonIndex)
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
        episodes = videoDetailScreenPlayableEpisodesForSeason(seasonIndex)
        for episodeIndex = 0 to episodes.Count() - 1
            if episodes[episodeIndex].isPlayable = true
                m.currentSeasonIndex = seasonIndex
                m.currentEpisodeIndex = episodeIndex
                return
            end if
        end for
    end for
end sub

function videoDetailScreenSelectTargetEpisodeFromResponse(response as Dynamic) as Boolean
    if response = invalid or type(response) <> "roAssociativeArray" then return false

    targetSeasonNumber = 0
    targetEpisodeNumber = 0
    if response.DoesExist("targetSeasonNumber") then targetSeasonNumber = videoDetailScreenIntegerField(response, "targetSeasonNumber", 0)
    if response.DoesExist("targetEpisodeNumber") then targetEpisodeNumber = videoDetailScreenIntegerField(response, "targetEpisodeNumber", 0)
    if targetSeasonNumber <= 0 and response.DoesExist("seasonNumber") then targetSeasonNumber = videoDetailScreenIntegerField(response, "seasonNumber", 0)
    if targetEpisodeNumber <= 0 and response.DoesExist("episodeNumber") then targetEpisodeNumber = videoDetailScreenIntegerField(response, "episodeNumber", 0)
    if targetSeasonNumber <= 0 and targetEpisodeNumber <= 0 then return false

    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        if targetSeasonNumber <= 0 or season.number = targetSeasonNumber
            episodes = videoDetailScreenPlayableEpisodesForSeason(seasonIndex)
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

function videoDetailScreenCurrentMedia() as Dynamic
    if m.seasons.Count() = 0 then return invalid
    if m.currentSeasonIndex < 0 then m.currentSeasonIndex = 0
    if m.currentSeasonIndex >= m.seasons.Count() then m.currentSeasonIndex = m.seasons.Count() - 1

    episodes = []
    if m.seasons[m.currentSeasonIndex].episodes <> invalid then episodes = m.seasons[m.currentSeasonIndex].episodes
    if episodes.Count() = 0 then return invalid

    if m.currentEpisodeIndex < 0 then m.currentEpisodeIndex = 0
    if m.currentEpisodeIndex >= episodes.Count() then m.currentEpisodeIndex = episodes.Count() - 1

    return episodes[m.currentEpisodeIndex]
end function

' ---------------------------------------------------------------------------
' Hero (title/metadata/badges/description/backdrop)
' ---------------------------------------------------------------------------

sub videoDetailScreenRenderHero()
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

    m.heroTitleLabel.text = title
    m.heroMetaLabel.text = videoDetailScreenJoinMetadata(metadata)
    m.heroDescriptionLabel.text = description

    heroImage = backdropUrl
    if heroImage = "" then heroImage = posterUrl
    m.backdropPoster.uri = heroImage
    m.backdropPoster.visible = heroImage <> ""

    videoDetailScreenRenderBadges()
end sub

' Description is a focus stop above the action stack (Up from Play) —
' highlighted via descriptionFocusBg (a Rectangle behind the label, opacity
' toggled here) since the label itself has no natural "button" chrome.
sub videoDetailScreenUpdateDescriptionFocus()
    if m.focusArea = "description"
        m.descriptionFocusBg.opacity = 0.18
    else
        m.descriptionFocusBg.opacity = 0
    end if
end sub

' Full-text "semiwindow" overlay — same "dialog never takes real focus"
' pattern as the bookmark overlay (see its header comment): the screen keeps
' focus throughout, checks m.descriptionOverlayOpen at the top of its own
' onKeyEvent, and Back/OK both close it, returning to whatever m.focusArea
' already was (never changed while the overlay is open).
sub videoDetailScreenOpenDescriptionOverlay()
    description = ""
    if m.item <> invalid and m.item.description <> invalid then description = m.item.description
    if description = "" then return

    title = ""
    if m.item <> invalid and m.item.title <> invalid then title = m.item.title

    m.descriptionOverlayTitleLabel.text = title
    m.descriptionOverlayTextLabel.text = description
    m.descriptionOverlayGroup.visible = true
    m.descriptionOverlayOpen = true
end sub

sub videoDetailScreenCloseDescriptionOverlay()
    m.descriptionOverlayGroup.visible = false
    m.descriptionOverlayOpen = false
end sub

function videoDetailScreenJoinMetadata(values as Dynamic) as String
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

' Small "4K"/"CC"/"AC3"/"FINISHED"-style chips, derived client-side from
' item.detailFacts (already built server-side by KinoItemService) — no
' service change needed.
sub videoDetailScreenRenderBadges()
    childCount = m.heroBadgesHost.getChildCount()
    if childCount > 0 then m.heroBadgesHost.removeChildrenIndex(childCount, 0)

    chips = []
    facts = []
    if m.item <> invalid and m.item.detailFacts <> invalid then facts = m.item.detailFacts

    for each fact in facts
        if fact.label = "Quality"
            chip = videoDetailScreenQualityChipText(fact.value)
            if chip <> "" then chips.Push(chip)
        else if fact.label = "Tracks"
            if Instr(1, fact.value, "AC-3") > 0 then chips.Push("AC3")
            if Instr(1, fact.value, "subtitles") > 0 then chips.Push("CC")
        else if fact.label = "Series"
            if fact.value = "Finished" then chips.Push("FINISHED")
        end if
    end for

    x = 0
    for each chipText in chips
        width = Len(chipText) * 11 + 20

        bg = CreateObject("roSGNode", "Rectangle")
        bg.translation = [x, 0]
        bg.width = width
        bg.height = 24
        bg.color = "#FFFFFF"
        bg.opacity = 0.16
        m.heroBadgesHost.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.text = chipText
        label.translation = [x + 10, 3]
        label.width = width - 20
        label.height = 18
        label.color = "#FFFFFF"
        label.font.size = 14
        m.heroBadgesHost.appendChild(label)

        x = x + width + 8
    end for
end sub

function videoDetailScreenQualityChipText(quality as Dynamic) as String
    if quality = invalid or type(quality) <> "String" and type(quality) <> "roString" then return ""
    q = LCase(quality)
    if Instr(1, q, "2160") > 0 then return "4K"
    if Instr(1, q, "1440") > 0 then return "QHD"
    if Instr(1, q, "1080") > 0 then return "FHD"
    if Instr(1, q, "720") > 0 then return "HD"
    return UCase(quality)
end function

' ---------------------------------------------------------------------------
' Actions (Play / Trailer / Bookmark)
' ---------------------------------------------------------------------------

sub videoDetailScreenRenderActions()
    childCount = m.heroActionsHost.getChildCount()
    if childCount > 0 then m.heroActionsHost.removeChildrenIndex(childCount, 0)
    m.actionRows = []

    rows = [{ id: "play", label: videoDetailScreenPlayLabel() }]
    if videoDetailScreenHasPlayableTrailer() then rows.Push({ id: "trailer", label: "▶  Трейлер" })
    rows.Push({ id: "bookmark", label: videoDetailScreenBookmarkLabel() })

    rowHeight = 46
    rowGap = 10
    rowWidth = 260

    for i = 0 to rows.Count() - 1
        row = rows[i]
        y = i * (rowHeight + rowGap)

        group = CreateObject("roSGNode", "Group")
        group.translation = [0, y]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = rowWidth
        bg.height = rowHeight
        bg.color = "#FFFFFF"
        bg.opacity = 0.14
        group.appendChild(bg)

        label = CreateObject("roSGNode", "Label")
        label.text = row.label
        label.translation = [16, 13]
        label.width = rowWidth - 32
        label.height = 20
        label.color = "#FFFFFF"
        group.appendChild(label)

        m.heroActionsHost.appendChild(group)
        m.actionRows.Push({ id: row.id, group: group, bg: bg, label: label })
    end for

    if m.selectedActionIndex >= m.actionRows.Count() then m.selectedActionIndex = 0
    videoDetailScreenUpdateActionsFocus()
end sub

function videoDetailScreenPlayLabel() as String
    media = videoDetailScreenCurrentMedia()
    if media <> invalid and media.seasonNumber <> invalid and media.seasonNumber > 0
        return "▶  Смотреть S" + StrI(media.seasonNumber).Trim() + "E" + StrI(media.episodeNumber).Trim()
    end if
    return "▶  Смотреть"
end function

function videoDetailScreenBookmarkLabel() as String
    count = 0
    if m.itemBookmarkFolders <> invalid then count = m.itemBookmarkFolders.Count()
    if count > 0 then return "♥  В закладках (" + StrI(count).Trim() + ")"
    return "♡  В закладки"
end function

sub videoDetailScreenUpdateActionsFocus()
    theme = UiThemeLight()
    for i = 0 to m.actionRows.Count() - 1
        row = m.actionRows[i]
        isFocused = (i = m.selectedActionIndex) and (m.focusArea = "actions")
        if isFocused
            row.bg.color = theme.focusBorder
            row.bg.opacity = 0.9
        else
            row.bg.color = "#FFFFFF"
            row.bg.opacity = 0.14
        end if
    end for
end sub

function videoDetailScreenHasPlayableTrailer() as Boolean
    if m.trailer = invalid then return false
    if m.trailer.streamUrl = invalid or m.trailer.streamUrl = "" then return false
    return true
end function

sub videoDetailScreenStartTrailerPlayback()
    if videoDetailScreenHasPlayableTrailer() <> true
        videoDetailScreenSetStatusMessage("Трейлер недоступен.")
        return
    end if

    m.top.playbackRequested = {
        itemId: m.item.itemId
        mediaId: 0
        itemTitle: m.item.title
        title: "Трейлер"
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

' ---------------------------------------------------------------------------
' Content — below-hero scrollable stack of rows: seasons tiles (rail),
' recommendations (rail), ratings, tech info. Mutually exclusive with the
' episode list (videoDetailScreenApplySectionVisibility). Rebuilt as a whole
' by videoDetailScreenRenderContent whenever the item changes. (A comments
' row briefly existed here in an earlier version — removed since KinoPub
' deprecated comments/reviews on the main site.)
' ---------------------------------------------------------------------------

sub videoDetailScreenRenderContent()
    childCount = m.contentHost.getChildCount()
    if childCount > 0 then m.contentHost.removeChildrenIndex(childCount, 0)
    m.contentRows = []

    y = 12

    if m.hasSeasonsRow
        row = videoDetailScreenBuildRailRow("seasons", "Сезоны", y)
        row.items = m.seasons
        row.cursorIndex = m.currentSeasonIndex
        m.contentRows.Push(row)
        videoDetailScreenRenderSeasonTiles(row)
        y = y + row.height + 28
    end if

    if m.item.similarItems <> invalid and m.item.similarItems.Count() > 0
        row = videoDetailScreenBuildRailRow("recommendations", "Похожее", y)
        row.items = m.item.similarItems
        row.cursorIndex = 0
        m.contentRows.Push(row)
        videoDetailScreenRenderRecommendationTiles(row)
        y = y + row.height + 28
    end if

    if videoDetailScreenHasAnyRating()
        row = videoDetailScreenRenderRatingsRow(y)
        m.contentRows.Push(row)
        y = y + row.height + 28
    end if

    if m.item.detailFacts <> invalid and m.item.detailFacts.Count() > 0
        row = videoDetailScreenRenderInfoRow(y)
        m.contentRows.Push(row)
    end if

    if m.contentRowIndex >= m.contentRows.Count() then m.contentRowIndex = m.contentRows.Count() - 1
    if m.contentRowIndex < 0 then m.contentRowIndex = 0
    videoDetailScreenUpdateContentFocus()
end sub

function videoDetailScreenHasAnyRating() as Boolean
    if m.item = invalid then return false
    if m.item.imdbRating <> invalid and m.item.imdbRating <> "" and m.item.imdbRating <> "0" then return true
    if m.item.kinopoiskRating <> invalid and m.item.kinopoiskRating <> "" and m.item.kinopoiskRating <> "0" then return true
    if m.item.kinopubRating <> invalid and m.item.kinopubRating <> "" and m.item.kinopubRating <> "0" then return true
    return false
end function

' Shared scaffold (heading + windowed horizontal tile rail + chevrons) for
' both the seasons row and the recommendations row — they differ only in
' which items feed the tiles, card badge options, and what OK does with the
' focused one (videoDetailScreenActivateContentRow), all keyed off
' row.rowType. Caller fills in row.items/row.cursorIndex after this returns.
'
' Tiles start at y=60 (not a tighter 30) so the focused tile's 1.16x
' scale-up — which bleeds roughly (285 * 0.16) / 2 =~ 23px above its nominal
' top — still clears the 24px-tall heading above it with a few px to spare;
' 30 wasn't enough clearance and let the popped top-row tile visually
' overlap the heading text (same bug, same fix, as Stage 1's single-purpose
' seasons row — regressed here when it was generalized into this shared
' builder for Stage 2, now fixed in the one place both rows share).
function videoDetailScreenBuildRailRow(rowType as String, headingText as String, y as Integer) as Object
    railTop = 60
    rowHeight = railTop + 285

    node = CreateObject("roSGNode", "Group")
    node.translation = [0, y]

    heading = CreateObject("roSGNode", "Label")
    heading.text = headingText
    heading.width = 400
    heading.height = 24
    heading.color = "#FFFFFF"
    node.appendChild(heading)

    railClip = CreateObject("roSGNode", "Group")
    railClip.translation = [-m.railPad, railTop - m.railPad]
    railClip.clippingRect = [0, 0, m.railContentWidth + (m.railPad * 2), 285 + (m.railPad * 2)]
    node.appendChild(railClip)

    railHost = CreateObject("roSGNode", "Group")
    railHost.translation = [m.railPad, m.railPad]
    railClip.appendChild(railHost)

    leftChevron = CreateObject("roSGNode", "Label")
    leftChevron.text = "<"
    leftChevron.translation = [-24, railTop + 130]
    leftChevron.width = 32
    leftChevron.horizAlign = "center"
    leftChevron.color = "#D1D9E0"
    leftChevron.visible = false
    node.appendChild(leftChevron)

    rightChevron = CreateObject("roSGNode", "Label")
    rightChevron.text = ">"
    rightChevron.translation = [m.railContentWidth + 24, railTop + 130]
    rightChevron.width = 32
    rightChevron.horizAlign = "center"
    rightChevron.color = "#D1D9E0"
    rightChevron.visible = false
    node.appendChild(rightChevron)

    m.contentHost.appendChild(node)

    return {
        rowType: rowType
        y: y
        height: rowHeight
        node: node
        railHost: railHost
        leftChevron: leftChevron
        rightChevron: rightChevron
        items: []
        cursorIndex: 0
        visibleStart: 0
        tileNodes: []
    }
end function

' Tile chrome is semi-transparent white ("frosted glass") rather than fully
' see-through: createPosterCard's title/subtitle text (PosterCard.brs, a
' shared component used by every grid in the app) is hardcoded dark, so it
' needs some opaque backing to stay legible against the backdrop image below
' it — unlike the episode rows/other content rows below, which this screen
' builds itself and can freely recolor for full light-on-dark contrast.
sub videoDetailScreenRenderSeasonTiles(row as Object)
    childCount = row.railHost.getChildCount()
    if childCount > 0 then row.railHost.removeChildrenIndex(childCount, 0)
    row.tileNodes = []

    count = m.seasons.Count()
    if count = 0 then return

    if row.cursorIndex < 0 then row.cursorIndex = 0
    if row.cursorIndex >= count then row.cursorIndex = count - 1

    startIndex = row.visibleStart
    if row.cursorIndex < startIndex then startIndex = row.cursorIndex
    if row.cursorIndex >= startIndex + m.maxVisibleRailTiles then startIndex = row.cursorIndex - m.maxVisibleRailTiles + 1
    maxStart = count - m.maxVisibleRailTiles
    if maxStart < 0 then maxStart = 0
    if startIndex > maxStart then startIndex = maxStart
    if startIndex < 0 then startIndex = 0
    row.visibleStart = startIndex

    lastIndex = startIndex + m.maxVisibleRailTiles - 1
    if lastIndex >= count then lastIndex = count - 1

    posterUrl = ""
    if m.item <> invalid and m.item.posterUrl <> invalid then posterUrl = m.item.posterUrl

    for index = startIndex to lastIndex
        season = m.seasons[index]
        seasonItem = {
            title: season.title
            posterUrl: posterUrl
            unwatchedCount: videoDetailScreenSeasonUnwatchedCount(index)
            watched: videoDetailScreenSeasonAllWatched(index)
        }

        x = (index - startIndex) * (m.railCardWidth + m.railCardGapX)
        layout = posterCompactLayout(x, 0, m.railCardWidth)
        layout.showUnwatchedBadge = true
        layout.showWatchedBadge = true
        cardInfo = createPosterCard(seasonItem, layout)
        row.railHost.appendChild(cardInfo.node)
        row.tileNodes.Push({ node: cardInfo.node, focusBg: cardInfo.focusBg, focusShadow: cardInfo.focusShadow, index: index })
    end for

    row.leftChevron.visible = startIndex > 0
    row.rightChevron.visible = (startIndex + m.maxVisibleRailTiles) < count
end sub

sub videoDetailScreenRenderRecommendationTiles(row as Object)
    childCount = row.railHost.getChildCount()
    if childCount > 0 then row.railHost.removeChildrenIndex(childCount, 0)
    row.tileNodes = []

    items = m.item.similarItems
    count = items.Count()
    if count = 0 then return

    if row.cursorIndex < 0 then row.cursorIndex = 0
    if row.cursorIndex >= count then row.cursorIndex = count - 1

    startIndex = row.visibleStart
    if row.cursorIndex < startIndex then startIndex = row.cursorIndex
    if row.cursorIndex >= startIndex + m.maxVisibleRailTiles then startIndex = row.cursorIndex - m.maxVisibleRailTiles + 1
    maxStart = count - m.maxVisibleRailTiles
    if maxStart < 0 then maxStart = 0
    if startIndex > maxStart then startIndex = maxStart
    if startIndex < 0 then startIndex = 0
    row.visibleStart = startIndex

    lastIndex = startIndex + m.maxVisibleRailTiles - 1
    if lastIndex >= count then lastIndex = count - 1

    for index = startIndex to lastIndex
        x = (index - startIndex) * (m.railCardWidth + m.railCardGapX)
        layout = posterCompactLayout(x, 0, m.railCardWidth)
        cardInfo = createPosterCard(items[index], layout)
        row.railHost.appendChild(cardInfo.node)
        row.tileNodes.Push({ node: cardInfo.node, focusBg: cardInfo.focusBg, focusShadow: cardInfo.focusShadow, index: index })
    end for

    row.leftChevron.visible = startIndex > 0
    row.rightChevron.visible = (startIndex + m.maxVisibleRailTiles) < count
end sub

sub videoDetailScreenUpdateRailRowFocus(row as Object, isRowFocused as Boolean)
    isSeasonsRow = row.rowType = "seasons"
    for each tileNode in row.tileNodes
        isFocused = isRowFocused and (tileNode.index = row.cursorIndex)
        isActive = isSeasonsRow and (tileNode.index = m.currentSeasonIndex)
        tileNode.focusShadow.visible = isFocused
        if isFocused
            tileNode.focusBg.color = "#BFDBFE"
            tileNode.focusBg.opacity = 1.0
            tileNode.node.scale = [1.16, 1.16]
        else if isActive
            tileNode.focusBg.color = "#FFFFFF"
            tileNode.focusBg.opacity = 0.7
            tileNode.node.scale = [1.0, 1.0]
        else
            tileNode.focusBg.color = "#FFFFFF"
            tileNode.focusBg.opacity = 0.5
            tileNode.node.scale = [1.0, 1.0]
        end if
    end for
end sub

function videoDetailScreenSeasonUnwatchedCount(seasonIndex as Integer) as Integer
    episodes = videoDetailScreenPlayableEpisodesForSeason(seasonIndex)
    count = 0
    for each episode in episodes
        if episode.isPlayable = true and episode.watched <> true then count = count + 1
    end for
    return count
end function

function videoDetailScreenSeasonAllWatched(seasonIndex as Integer) as Boolean
    episodes = videoDetailScreenPlayableEpisodesForSeason(seasonIndex)
    playableCount = 0
    for each episode in episodes
        if episode.isPlayable = true then playableCount = playableCount + 1
    end for
    if playableCount = 0 then return false
    return videoDetailScreenSeasonUnwatchedCount(seasonIndex) = 0
end function

' Entering a season tile (OK): if it's already the active season, keep the
' existing episode selection (preserves e.g. a resume-in-progress episode
' picked by the initial global scan); otherwise rescan just that season.
sub videoDetailScreenSelectSeason(seasonIndex as Integer)
    if seasonIndex < 0 or seasonIndex >= m.seasons.Count() then return
    if seasonIndex <> m.currentSeasonIndex
        m.currentSeasonIndex = seasonIndex
        videoDetailScreenSelectFirstUnwatchedInSeason(seasonIndex)
    end if
    m.focusArea = "episodes"
    videoDetailScreenSetHeroScrolled(true)
    videoDetailScreenRenderEpisodes()
    videoDetailScreenRenderActions()
    videoDetailScreenApplySectionVisibility()
end sub

sub videoDetailScreenSelectFirstUnwatchedInSeason(seasonIndex as Integer)
    episodes = videoDetailScreenPlayableEpisodesForSeason(seasonIndex)
    for index = 0 to episodes.Count() - 1
        if episodes[index].isPlayable = true and episodes[index].watched <> true
            m.currentEpisodeIndex = index
            return
        end if
    end for
    for index = 0 to episodes.Count() - 1
        if episodes[index].isPlayable = true
            m.currentEpisodeIndex = index
            return
        end if
    end for
    m.currentEpisodeIndex = 0
end sub

' ---------------------------------------------------------------------------
' Ratings row — up to 3 static boxes (IMDb/Kinopoisk/KinoPub), only the
' ratings that are actually present. Reuses the existing rating icon assets
' already shipped for PosterCard.brs's grid-card rating badges.
' ---------------------------------------------------------------------------

function videoDetailScreenRenderRatingsRow(y as Integer) as Object
    rowHeight = 24 + 8 + 56

    node = CreateObject("roSGNode", "Group")
    node.translation = [0, y]

    focusBg = CreateObject("roSGNode", "Rectangle")
    focusBg.width = 700
    focusBg.height = rowHeight
    focusBg.color = "#FFFFFF"
    focusBg.opacity = 0
    node.appendChild(focusBg)

    heading = CreateObject("roSGNode", "Label")
    heading.text = "Рейтинги"
    heading.width = 400
    heading.height = 24
    heading.color = "#FFFFFF"
    node.appendChild(heading)

    boxes = []
    if m.item.imdbRating <> invalid and m.item.imdbRating <> "" and m.item.imdbRating <> "0" then boxes.Push({ label: "IMDb", value: m.item.imdbRating, icon: "" })
    if m.item.kinopoiskRating <> invalid and m.item.kinopoiskRating <> "" and m.item.kinopoiskRating <> "0" then boxes.Push({ label: "Кинопоиск", value: m.item.kinopoiskRating, icon: "pkg:/images/ui/icon-kinopoisk.png" })
    if m.item.kinopubRating <> invalid and m.item.kinopubRating <> "" and m.item.kinopubRating <> "0" then boxes.Push({ label: "KinoPub", value: m.item.kinopubRating, icon: "pkg:/images/ui/icon-kinopub.png" })

    x = 0
    for each ratingBox in boxes
        boxWidth = 180
        boxGroup = CreateObject("roSGNode", "Group")
        boxGroup.translation = [x, 32]

        boxBg = CreateObject("roSGNode", "Rectangle")
        boxBg.width = boxWidth
        boxBg.height = 56
        boxBg.color = "#FFFFFF"
        boxBg.opacity = 0.12
        boxGroup.appendChild(boxBg)

        textX = 14
        if ratingBox.icon <> ""
            icon = CreateObject("roSGNode", "Poster")
            icon.translation = [14, 14]
            icon.width = 28
            icon.height = 28
            icon.uri = ratingBox.icon
            icon.loadDisplayMode = "scaleToFit"
            boxGroup.appendChild(icon)
            textX = 50
        end if

        valueLabel = CreateObject("roSGNode", "Label")
        valueLabel.text = ratingBox.value
        valueLabel.translation = [textX, 8]
        valueLabel.width = boxWidth - textX - 10
        valueLabel.height = 24
        valueLabel.color = "#FFFFFF"
        valueLabel.font.size = 20
        boxGroup.appendChild(valueLabel)

        nameLabel = CreateObject("roSGNode", "Label")
        nameLabel.text = ratingBox.label
        nameLabel.translation = [textX, 32]
        nameLabel.width = boxWidth - textX - 10
        nameLabel.height = 18
        nameLabel.color = "#D1D9E0"
        nameLabel.font.size = 13
        boxGroup.appendChild(nameLabel)

        node.appendChild(boxGroup)
        x = x + boxWidth + 16
    end for

    m.contentHost.appendChild(node)

    return { rowType: "ratings", y: y, height: rowHeight, node: node, focusBg: focusBg }
end function

' ---------------------------------------------------------------------------
' Info row — item.detailFacts (already computed server-response-side by
' KinoItemService.brs), translated to Russian at render time only. The
' underlying English keys stay untouched since videoDetailScreenRenderBadges
' (the hero's 4K/CC/AC3/FINISHED chips) matches on those exact labels. Skips
' the "Ratings" fact — redundant with the dedicated ratings row above.
' ---------------------------------------------------------------------------

function videoDetailScreenInfoLabelRu(label as String) as String
    if label = "Director" then return "Режиссёр"
    if label = "Cast" then return "Актёры"
    if label = "Voice" then return "Озвучка"
    if label = "Quality" then return "Качество"
    if label = "Tracks" then return "Дорожки"
    if label = "Activity" then return "Активность"
    if label = "Series" then return "Статус"
    if label = "Note" then return "Заметка"
    return label
end function

function videoDetailScreenRenderInfoRow(y as Integer) as Object
    facts = []
    for each fact in m.item.detailFacts
        if fact.label <> "Ratings" then facts.Push(fact)
    end for

    ' Smaller font + tighter line height than a plain 24px default so this
    ' (always the last row) leaves a bit of breathing room between its last
    ' line and the bottom of the scrollable viewport — a flat 24px-per-line
    ' block ran flush against the edge with nothing below it.
    lineHeight = 20
    fontSize = 16
    lineCount = facts.Count()
    if lineCount = 0 then lineCount = 1
    rowHeight = 24 + 8 + (lineCount * lineHeight) + 16

    node = CreateObject("roSGNode", "Group")
    node.translation = [0, y]

    focusBg = CreateObject("roSGNode", "Rectangle")
    focusBg.width = 700
    focusBg.height = rowHeight
    focusBg.color = "#FFFFFF"
    focusBg.opacity = 0
    node.appendChild(focusBg)

    heading = CreateObject("roSGNode", "Label")
    heading.text = "Общая информация"
    heading.width = 400
    heading.height = 24
    heading.color = "#FFFFFF"
    node.appendChild(heading)

    if facts.Count() = 0
        empty = CreateObject("roSGNode", "Label")
        empty.text = "Нет данных"
        empty.translation = [0, 32]
        empty.width = 700
        empty.height = lineHeight
        empty.color = "#D1D9E0"
        empty.font.size = fontSize
        node.appendChild(empty)
    else
        for index = 0 to facts.Count() - 1
            fact = facts[index]
            lineY = 32 + (index * lineHeight)

            label = CreateObject("roSGNode", "Label")
            label.text = videoDetailScreenInfoLabelRu(fact.label)
            label.translation = [0, lineY]
            label.width = 180
            label.height = lineHeight
            label.color = "#D1D9E0"
            label.font.size = fontSize
            node.appendChild(label)

            value = CreateObject("roSGNode", "Label")
            value.text = fact.value
            value.translation = [190, lineY]
            value.width = 520
            value.height = lineHeight
            value.color = "#FFFFFF"
            value.font.size = fontSize
            node.appendChild(value)
        end for
    end if

    m.contentHost.appendChild(node)

    return { rowType: "info", y: y, height: rowHeight, node: node, focusBg: focusBg }
end function

' ---------------------------------------------------------------------------
' Content row focus/scroll — Up/Down moves m.contentRowIndex between rows;
' Left/Right moves a row-local horizontal cursor, only meaningful for the
' rail row types (seasons/recommendations). Scroll-to-focus mirrors the
' episode list's flat-render-and-animate-translation technique, generalized
' from a fixed row step to each row's actual computed height.
' ---------------------------------------------------------------------------

sub videoDetailScreenUpdateContentFocus()
    for i = 0 to m.contentRows.Count() - 1
        row = m.contentRows[i]
        isRowFocused = (i = m.contentRowIndex) and (m.focusArea = "content")
        if row.rowType = "seasons" or row.rowType = "recommendations"
            videoDetailScreenUpdateRailRowFocus(row, isRowFocused)
        else if row.focusBg <> invalid
            if isRowFocused then row.focusBg.opacity = 0.16 else row.focusBg.opacity = 0
        end if
    end for
    videoDetailScreenScrollContentToFocus()
end sub

sub videoDetailScreenMoveContentRow(delta as Integer)
    if m.contentRows.Count() = 0 then return
    nextIndex = m.contentRowIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= m.contentRows.Count() then nextIndex = m.contentRows.Count() - 1
    if nextIndex = m.contentRowIndex then return
    m.contentRowIndex = nextIndex
    videoDetailScreenUpdateContentFocus()
end sub

sub videoDetailScreenMoveContentRailCursor(delta as Integer)
    if m.contentRows.Count() = 0 then return
    row = m.contentRows[m.contentRowIndex]
    if row.rowType <> "seasons" and row.rowType <> "recommendations" then return

    itemCount = row.items.Count()
    if itemCount = 0 then return

    nextIndex = row.cursorIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= itemCount then nextIndex = itemCount - 1
    if nextIndex = row.cursorIndex then return
    row.cursorIndex = nextIndex

    if row.rowType = "seasons"
        videoDetailScreenRenderSeasonTiles(row)
    else
        videoDetailScreenRenderRecommendationTiles(row)
    end if
    videoDetailScreenUpdateRailRowFocus(row, true)
end sub

' OK on the focused row: drills into the dedicated episode view for a
' seasons-row tile, or re-selects a recommended item (reloads this same
' screen instance on that item — the old dark-theme file's
' selectSimilarItem() behavior). No-op on ratings/info rows.
sub videoDetailScreenActivateContentRow()
    if m.contentRows.Count() = 0 then return
    row = m.contentRows[m.contentRowIndex]
    if row.rowType = "seasons"
        videoDetailScreenSelectSeason(row.cursorIndex)
    else if row.rowType = "recommendations"
        item = row.items[row.cursorIndex]
        if item.itemId > 0
            m.top.selection = { itemId: item.itemId, mediaId: item.mediaId, source: "similar" }
        end if
    end if
end sub

sub videoDetailScreenScrollContentToFocus()
    if m.contentRows.Count() = 0 then return
    row = m.contentRows[m.contentRowIndex]

    rowTop = row.y
    rowBottom = rowTop + row.height

    currentOffset = m.contentScrollOffsetY
    newOffset = currentOffset

    if rowTop < currentOffset
        newOffset = rowTop
    else if rowBottom > (currentOffset + m.contentViewportHeight)
        newOffset = rowBottom - m.contentViewportHeight
    end if

    if newOffset < 0 then newOffset = 0
    if newOffset <> currentOffset
        videoDetailScreenAnimateContentScroll(currentOffset, newOffset)
        m.contentScrollOffsetY = newOffset
    end if
end sub

sub videoDetailScreenAnimateContentScroll(fromY as Integer, toY as Integer)
    if m.contentScrollAnimation = invalid
        animation = CreateObject("roSGNode", "Animation")
        animation.duration = 0.25
        animation.easeFunction = "inOutQuad"
        interpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        interpolator.key = [0, 1]
        interpolator.fieldToInterp = "contentHost.translation"
        animation.appendChild(interpolator)
        m.top.appendChild(animation)
        m.contentScrollAnimation = animation
        m.contentScrollInterpolator = interpolator
    end if

    m.contentScrollInterpolator.keyValue = [[m.railPad, m.railPad - fromY], [m.railPad, m.railPad - toY]]
    m.contentScrollAnimation.control = "start"
end sub

' ---------------------------------------------------------------------------
' Episode list (flat render, scrolled into view — no windowing)
' ---------------------------------------------------------------------------

sub videoDetailScreenRenderEpisodes()
    childCount = m.episodesHost.getChildCount()
    if childCount > 0 then m.episodesHost.removeChildrenIndex(childCount, 0)
    m.episodeRowNodes = []
    m.episodesHost.translation = [0, 0]
    m.episodesScrollOffsetY = 0

    if m.seasons.Count() = 0
        m.noMediaLabel.visible = true
        return
    end if

    if m.currentSeasonIndex < 0 then m.currentSeasonIndex = 0
    if m.currentSeasonIndex >= m.seasons.Count() then m.currentSeasonIndex = m.seasons.Count() - 1

    season = m.seasons[m.currentSeasonIndex]
    m.episodesHeadingLabel.text = season.title
    episodes = videoDetailScreenPlayableEpisodesForSeason(m.currentSeasonIndex)

    if episodes.Count() = 0
        m.noMediaLabel.visible = true
        return
    end if
    m.noMediaLabel.visible = false

    if m.currentEpisodeIndex < 0 then m.currentEpisodeIndex = 0
    if m.currentEpisodeIndex >= episodes.Count() then m.currentEpisodeIndex = episodes.Count() - 1

    for index = 0 to episodes.Count() - 1
        rowInfo = videoDetailScreenCreateEpisodeRow(episodes[index], index)
        m.episodesHost.appendChild(rowInfo.node)
        m.episodeRowNodes.Push({ node: rowInfo.node, bg: rowInfo.bg, index: index })
    end for

    videoDetailScreenUpdateEpisodesFocus()
end sub

' Built by this screen (not a shared component like PosterCard.brs), so
' rows can go fully light-on-dark to sit directly on the backdrop image —
' see videoDetailScreenRenderSeasonTiles's comment for why season/
' recommendation tiles can't do the same.
function videoDetailScreenCreateEpisodeRow(episode as Object, index as Integer) as Object
    row = CreateObject("roSGNode", "Group")
    row.translation = [0, index * m.episodeRowStep]

    bg = CreateObject("roSGNode", "Rectangle")
    bg.width = 700
    bg.height = 74
    bg.color = "#FFFFFF"
    bg.opacity = 0.1
    row.appendChild(bg)

    title = CreateObject("roSGNode", "Label")
    title.text = episode.title
    title.translation = [18, 10]
    title.width = 560
    title.color = "#FFFFFF"
    row.appendChild(title)

    subtitleText = videoDetailScreenMediaSubtitle(episode)
    progressText = videoDetailScreenEpisodeProgressText(episode)
    if progressText <> ""
        if subtitleText <> "" then subtitleText = subtitleText + "  |  " + progressText else subtitleText = progressText
    end if
    subtitle = CreateObject("roSGNode", "Label")
    subtitle.text = subtitleText
    subtitle.translation = [18, 42]
    subtitle.width = 600
    subtitle.color = "#D1D9E0"
    row.appendChild(subtitle)

    if videoDetailScreenEpisodeWatchStatus(episode) = 1
        videoDetailScreenAppendWatchedCheck(row)
    else
        dot = CreateObject("roSGNode", "Label")
        dot.text = "●"
        dot.translation = [660, 10]
        dot.width = 26
        dot.horizAlign = "center"
        dot.color = "#9CA3AF"
        row.appendChild(dot)
    end if

    return { node: row, bg: bg }
end function

sub videoDetailScreenAppendWatchedCheck(row as Object)
    check = CreateObject("roSGNode", "Label")
    check.text = "✓"
    check.translation = [660, 10]
    check.width = 26
    check.horizAlign = "center"
    check.color = "#4ADE80"
    row.appendChild(check)
end sub

function videoDetailScreenMediaSubtitle(media as Object) as String
    parts = []
    if media.seasonNumber > 0
        parts.Push("S" + StrI(media.seasonNumber).Trim() + " E" + StrI(media.episodeNumber).Trim())
    end if
    if media.durationSeconds > 0
        parts.Push(StrI(Int(media.durationSeconds / 60)).Trim() + " мин")
    end if
    if media.isPlayable <> true then parts.Push("Недоступно")
    return videoDetailScreenJoinMetadata(parts)
end function

function videoDetailScreenEpisodeWatchStatus(media as Dynamic) as Integer
    if media = invalid then return -1
    if media.watchStatus <> invalid then return media.watchStatus
    if media.watched = true then return 1
    if media.progressSeconds <> invalid and media.progressSeconds > 0 then return 0
    return -1
end function

function videoDetailScreenEpisodeVideoNumber(media as Dynamic) as Integer
    if media = invalid then return 0
    if media.videoNumber <> invalid and media.videoNumber > 0 then return media.videoNumber
    if media.episodeNumber <> invalid and media.episodeNumber > 0 then return media.episodeNumber
    return 0
end function

function videoDetailScreenWatchedToggleKey(seasonNumber as Integer, videoNumber as Integer) as String
    return StrI(seasonNumber).Trim() + ":" + StrI(videoNumber).Trim()
end function

function videoDetailScreenEpisodeProgressText(media as Dynamic) as String
    if media = invalid then return ""
    if videoDetailScreenEpisodeWatchStatus(media) <> 0 then return ""
    if media.progressSeconds = invalid or media.progressSeconds <= 0 then return ""

    if media.durationSeconds <> invalid and media.durationSeconds > 0
        percent = Int((media.progressSeconds * 100) / media.durationSeconds)
        if percent < 1 then percent = 1
        if percent > 99 then percent = 99
        return StrI(percent).Trim() + "%"
    end if

    return videoDetailScreenFormatEpisodeProgressTime(media.progressSeconds)
end function

function videoDetailScreenFormatEpisodeProgressTime(seconds as Integer) as String
    if seconds < 0 then seconds = 0
    minutes = Int(seconds / 60)
    remaining = seconds - (minutes * 60)
    remainingText = StrI(remaining).Trim()
    if remaining < 10 then remainingText = "0" + remainingText
    return StrI(minutes).Trim() + ":" + remainingText
end function

sub videoDetailScreenUpdateEpisodesFocus()
    for each rowNode in m.episodeRowNodes
        isFocused = (rowNode.index = m.currentEpisodeIndex) and (m.focusArea = "episodes")
        if isFocused
            rowNode.bg.color = "#BFDBFE"
            rowNode.bg.opacity = 0.55
        else
            rowNode.bg.color = "#FFFFFF"
            rowNode.bg.opacity = 0.1
        end if
    end for
    videoDetailScreenScrollEpisodesToFocus()
end sub

sub videoDetailScreenScrollEpisodesToFocus()
    if m.episodeRowNodes.Count() = 0 then return

    rowTop = m.currentEpisodeIndex * m.episodeRowStep
    rowBottom = rowTop + m.episodeRowStep

    currentOffset = m.episodesScrollOffsetY
    newOffset = currentOffset

    if rowTop < currentOffset
        newOffset = rowTop
    else if rowBottom > (currentOffset + m.episodesViewportHeight)
        newOffset = rowBottom - m.episodesViewportHeight
    end if

    if newOffset < 0 then newOffset = 0
    if newOffset <> currentOffset
        videoDetailScreenAnimateEpisodesScroll(currentOffset, newOffset)
        m.episodesScrollOffsetY = newOffset
    end if
end sub

sub videoDetailScreenAnimateEpisodesScroll(fromY as Integer, toY as Integer)
    if m.episodesScrollAnimation = invalid
        animation = CreateObject("roSGNode", "Animation")
        animation.duration = 0.25
        animation.easeFunction = "inOutQuad"
        interpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        interpolator.key = [0, 1]
        interpolator.fieldToInterp = "episodesHost.translation"
        animation.appendChild(interpolator)
        m.top.appendChild(animation)
        m.episodesScrollAnimation = animation
        m.episodesScrollInterpolator = interpolator
    end if

    m.episodesScrollInterpolator.keyValue = [[0, -fromY], [0, -toY]]
    m.episodesScrollAnimation.control = "start"
end sub

' Scrolls the foreground content (detailScrollHost — hero text/actions and
' below-hero seasons/episodes, not just episodesHost within its own small
' clip) up by the hero's full height when entering the episode list, and
' back down when leaving it. The backdrop image/scrim stay fixed (they're
' siblings of detailScrollHost, not inside it) so they read as a static
' page background rather than scrolling off with the foreground. Frees up
' nearly the entire screen for episodes instead of the ~284px strip below a
' permanently pinned hero. Toggled from every focusArea transition into/out
' of "episodes".
sub videoDetailScreenSetHeroScrolled(scrolled as Boolean)
    if scrolled = m.heroScrolled then return
    m.heroScrolled = scrolled

    fromY = 0
    toY = 0
    if scrolled
        toY = -m.heroScrollOffset
        m.episodesViewportHeight = m.episodesViewportHeightExpanded
    else
        fromY = -m.heroScrollOffset
        m.episodesViewportHeight = m.episodesViewportHeightDefault
    end if
    m.episodesClipHost.clippingRect = [0, 0, 1152, m.episodesViewportHeight]

    if m.heroScrollAnimation = invalid
        animation = CreateObject("roSGNode", "Animation")
        animation.duration = 0.3
        animation.easeFunction = "inOutQuad"
        interpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        interpolator.key = [0, 1]
        interpolator.fieldToInterp = "detailScrollHost.translation"
        animation.appendChild(interpolator)
        m.top.appendChild(animation)
        m.heroScrollAnimation = animation
        m.heroScrollInterpolator = interpolator
    end if

    m.heroScrollInterpolator.keyValue = [[0, fromY], [0, toY]]
    m.heroScrollAnimation.control = "start"

    videoDetailScreenScrollEpisodesToFocus()
end sub

sub videoDetailScreenMoveEpisode(delta as Integer)
    episodes = videoDetailScreenPlayableEpisodesForSeason(m.currentSeasonIndex)
    if episodes.Count() = 0 then return
    nextIndex = m.currentEpisodeIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex >= episodes.Count() then nextIndex = episodes.Count() - 1
    if nextIndex = m.currentEpisodeIndex then return
    m.currentEpisodeIndex = nextIndex
    videoDetailScreenSetStatusMessage("")
    videoDetailScreenUpdateEpisodesFocus()
    videoDetailScreenRenderActions()
end sub

' Which of contentSection/episodesSection is visible below the hero, driven
' purely by m.focusArea — content (ratings/info at minimum, almost always
' available) is now relevant for every item, not just series, so there's no
' isSeries branch here anymore (Stage 1 had one).
sub videoDetailScreenApplySectionVisibility()
    m.contentSection.visible = m.focusArea <> "episodes"
    m.episodesSection.visible = m.focusArea = "episodes"
end sub

' ---------------------------------------------------------------------------
' Watched toggle (options/* key on a focused episode)
' ---------------------------------------------------------------------------

sub videoDetailScreenToggleCurrentEpisodeWatched()
    if m.pendingWatchedToggleKey <> "" then return
    if m.item = invalid or m.item.itemId <= 0 then return

    media = videoDetailScreenCurrentMedia()
    if media = invalid then return

    seasonNumber = 0
    if media.seasonNumber <> invalid then seasonNumber = media.seasonNumber
    videoNumber = videoDetailScreenEpisodeVideoNumber(media)
    if videoNumber <= 0 then return

    targetWatched = videoDetailScreenEpisodeWatchStatus(media) <> 1
    m.pendingWatchedToggleKey = videoDetailScreenWatchedToggleKey(seasonNumber, videoNumber)

    task = CreateObject("roSGNode", "ContentTask")
    task.command = "toggleEpisodeWatched"
    task.request = { itemId: m.item.itemId, seasonNumber: seasonNumber, videoNumber: videoNumber, watched: targetWatched }
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
        if videoDetailScreenResponseRequiresSignIn(response) then videoDetailScreenRequestSignInAgain(response)
        return
    end if

    if videoDetailScreenWatchedToggleKey(response.seasonNumber, response.videoNumber) <> pendingKey then return
    videoDetailScreenApplyEpisodeWatchedState(response.seasonNumber, response.videoNumber, response.watched)
end sub

sub videoDetailScreenApplyEpisodeWatchedState(seasonNumber as Integer, videoNumber as Integer, watched as Boolean)
    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        seasonMatches = true
        if seasonNumber > 0 and season <> invalid and season.number <> invalid and season.number <> seasonNumber then seasonMatches = false

        if season <> invalid and season.episodes <> invalid and seasonMatches
            for episodeIndex = 0 to season.episodes.Count() - 1
                episode = season.episodes[episodeIndex]
                if episode <> invalid and videoDetailScreenEpisodeVideoNumber(episode) = videoNumber
                    episode.watched = watched
                    if watched
                        episode.watchStatus = 1
                    else
                        episode.watchStatus = -1
                    end if
                    episode.progressSeconds = 0
                    if seasonIndex = m.currentSeasonIndex then videoDetailScreenRenderEpisodes()
                    ' Full content rebuild refreshes the seasons row's
                    ' unwatched-count badges.
                    videoDetailScreenRenderContent()
                    return
                end if
            end for
        end if
    end for
end sub

' ---------------------------------------------------------------------------
' Play — preflight (refresh stream links), payload shape shared with the
' next-episode/season-carousel contract below.
' ---------------------------------------------------------------------------

sub videoDetailScreenStartSelectedPlayback()
    media = videoDetailScreenCurrentMedia()
    if media = invalid
        videoDetailScreenSetStatusMessage("Видео недоступно.")
        return
    end if
    if media.isPlayable <> true
        videoDetailScreenSetStatusMessage("Видео недоступно.")
        return
    end if

    streamUrl = ""
    if media.streamUrl <> invalid then streamUrl = media.streamUrl
    if streamUrl = ""
        videoDetailScreenSetStatusMessage("Видео недоступно.")
        return
    end if

    videoDetailScreenStartPlaybackPreflight(media)
end sub

function videoDetailScreenPlaybackPayloadForMedia(media as Object) as Object
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
        seasonEpisodes: videoDetailScreenSeasonEpisodesForMedia(media)
    }
end function

function videoDetailScreenSeasonEpisodesForMedia(media as Dynamic) as Object
    episodes = []
    if media = invalid or m.seasons = invalid then return episodes
    if media.seasonNumber = invalid or media.seasonNumber <= 0 then return episodes

    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        if season <> invalid and season.number <> invalid and season.number = media.seasonNumber
            if season.episodes = invalid then return episodes
            for each episode in season.episodes
                payload = videoDetailScreenSeasonCarouselEpisodePayload(episode)
                if payload <> invalid then episodes.Push(payload)
            end for
            return episodes
        end if
    end for

    return episodes
end function

function videoDetailScreenSeasonCarouselEpisodePayload(episode as Dynamic) as Dynamic
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

sub videoDetailScreenStartPlaybackPreflight(media as Object)
    payload = videoDetailScreenPlaybackPayloadForMedia(media)
    mediaId = 0
    if media.mediaId <> invalid then mediaId = media.mediaId

    if mediaId <= 0
        m.top.playbackRequested = payload
        return
    end if

    if m.pendingPlaybackMediaId = mediaId then return

    m.pendingPlaybackMediaId = mediaId
    m.pendingPlaybackPayload = payload
    videoDetailScreenSetStatusMessage("Подготовка видео...")

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

    if videoDetailScreenResponseRequiresSignIn(response)
        videoDetailScreenRequestSignInAgain(response)
        return
    end if

    if response <> invalid and response.ok = true and response.media <> invalid
        responseMediaId = 0
        if response.media.mediaId <> invalid then responseMediaId = response.media.mediaId
        if responseMediaId <> pendingMediaId then return
        videoDetailScreenSetStatusMessage("")
        m.top.playbackRequested = videoDetailScreenPlaybackPayloadForMedia(response.media)
        return
    end if

    if fallbackPayload <> invalid and fallbackPayload.streamUrl <> invalid and fallbackPayload.streamUrl <> ""
        videoDetailScreenSetStatusMessage("")
        m.top.playbackRequested = fallbackPayload
        return
    end if

    message = "Видео недоступно."
    if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
    videoDetailScreenSetStatusMessage(message)
end sub

sub videoDetailScreenCancelPlaybackPreflight()
    if m.mediaLinksTask <> invalid then m.mediaLinksTask.control = "STOP"
    m.mediaLinksTask = invalid
    m.pendingPlaybackMediaId = 0
    m.pendingPlaybackPayload = invalid
    if m.nextMediaLinksTask <> invalid then m.nextMediaLinksTask.control = "STOP"
    m.nextMediaLinksTask = invalid
    m.pendingNextPlaybackMediaId = 0
    m.pendingNextPlaybackPayload = invalid
end sub

' ---------------------------------------------------------------------------
' Next-episode / in-player season-carousel contract with PlayerScreen.brs —
' ported verbatim (rename only). UI-state-independent: only reads
' m.seasons/m.item, never m.focusArea, so this rewrite doesn't affect it.
' ---------------------------------------------------------------------------

sub onNextPlaybackRequested(event as Object)
    request = event.getData()
    reason = videoDetailScreenNextPlaybackRequestReason(request)
    if reason = "seasonCarousel"
        media = videoDetailScreenRequestedPlayableMedia(request)
    else
        media = videoDetailScreenNextPlayableMediaAfter(request)
    end if
    if media = invalid
        m.top.nextPlayback = { ok: false, reason: reason, message: "Следующий эпизод недоступен." }
        return
    end if

    videoDetailScreenPrepareNextPlaybackPreflight(media, request)
end sub

function videoDetailScreenNextPlayableMediaAfter(request as Dynamic) as Dynamic
    if request = invalid or m.seasons = invalid or m.seasons.Count() = 0 then return invalid

    requestMediaId = videoDetailScreenNextPlaybackIntegerField(request, "mediaId", 0)
    requestSeasonNumber = videoDetailScreenNextPlaybackIntegerField(request, "seasonNumber", 0)
    requestVideoNumber = videoDetailScreenNextPlaybackIntegerField(request, "videoNumber", 0)
    requestEpisodeNumber = videoDetailScreenNextPlaybackIntegerField(request, "episodeNumber", requestVideoNumber)

    foundCurrent = false
    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        episodes = []
        if season <> invalid and season.episodes <> invalid then episodes = season.episodes

        for episodeIndex = 0 to episodes.Count() - 1
            episode = episodes[episodeIndex]
            if foundCurrent and episode <> invalid and episode.isPlayable = true then return episode

            if videoDetailScreenNextPlaybackMatchesMedia(episode, requestMediaId, requestSeasonNumber, requestVideoNumber, requestEpisodeNumber)
                foundCurrent = true
            end if
        end for
    end for

    return invalid
end function

function videoDetailScreenRequestedPlayableMedia(request as Dynamic) as Dynamic
    if request = invalid or m.seasons = invalid or m.seasons.Count() = 0 then return invalid

    requestMediaId = videoDetailScreenNextPlaybackIntegerField(request, "mediaId", 0)
    requestSeasonNumber = videoDetailScreenNextPlaybackIntegerField(request, "seasonNumber", 0)
    requestVideoNumber = videoDetailScreenNextPlaybackIntegerField(request, "videoNumber", 0)
    requestEpisodeNumber = videoDetailScreenNextPlaybackIntegerField(request, "episodeNumber", requestVideoNumber)

    for seasonIndex = 0 to m.seasons.Count() - 1
        season = m.seasons[seasonIndex]
        episodes = []
        if season <> invalid and season.episodes <> invalid then episodes = season.episodes

        for episodeIndex = 0 to episodes.Count() - 1
            episode = episodes[episodeIndex]
            if episode <> invalid and episode.isPlayable = true and videoDetailScreenNextPlaybackMatchesMedia(episode, requestMediaId, requestSeasonNumber, requestVideoNumber, requestEpisodeNumber)
                return episode
            end if
        end for
    end for

    return invalid
end function

function videoDetailScreenNextPlaybackMatchesMedia(media as Dynamic, requestMediaId as Integer, requestSeasonNumber as Integer, requestVideoNumber as Integer, requestEpisodeNumber as Integer) as Boolean
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

sub videoDetailScreenPrepareNextPlaybackPreflight(media as Object, request as Dynamic)
    payload = videoDetailScreenPlaybackPayloadForMedia(media)
    reason = videoDetailScreenNextPlaybackRequestReason(request)
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
    reason = videoDetailScreenNextPlaybackRequestReasonFromPayload(fallbackPayload)
    pendingMediaId = m.pendingNextPlaybackMediaId
    m.pendingNextPlaybackMediaId = 0
    m.pendingNextPlaybackPayload = invalid
    m.nextMediaLinksTask = invalid

    if pendingMediaId <= 0 then return

    if videoDetailScreenResponseRequiresSignIn(response)
        videoDetailScreenRequestSignInAgain(response)
        return
    end if

    if response <> invalid and response.ok = true and response.media <> invalid
        responseMediaId = 0
        if response.media.mediaId <> invalid then responseMediaId = response.media.mediaId
        if responseMediaId = pendingMediaId
            m.top.nextPlayback = { ok: true, playback: videoDetailScreenPlaybackPayloadForMedia(response.media), reason: reason }
            return
        end if
        if fallbackPayload <> invalid and fallbackPayload.streamUrl <> invalid and fallbackPayload.streamUrl <> ""
            m.top.nextPlayback = { ok: true, playback: fallbackPayload, reason: reason }
            return
        end if
        message = "Следующий эпизод недоступен."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        m.top.nextPlayback = { ok: false, message: message, reason: reason }
        return
    end if

    if fallbackPayload <> invalid and fallbackPayload.streamUrl <> invalid and fallbackPayload.streamUrl <> ""
        m.top.nextPlayback = { ok: true, playback: fallbackPayload, reason: reason }
        return
    end if

    message = "Следующий эпизод недоступен."
    if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
    m.top.nextPlayback = { ok: false, message: message, reason: reason }
end sub

function videoDetailScreenNextPlaybackRequestReason(request as Dynamic) as String
    if request = invalid or type(request) <> "roAssociativeArray" then return ""
    if request.DoesExist("reason") <> true or request.reason = invalid then return ""
    if type(request.reason) = "String" or type(request.reason) = "roString" then return request.reason
    return ""
end function

function videoDetailScreenNextPlaybackRequestReasonFromPayload(payload as Dynamic) as String
    if payload = invalid or type(payload) <> "roAssociativeArray" then return ""
    if payload.DoesExist("requestReason") <> true or payload.requestReason = invalid then return ""
    if type(payload.requestReason) = "String" or type(payload.requestReason) = "roString" then return payload.requestReason
    return ""
end function

function videoDetailScreenNextPlaybackIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback
    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

' ---------------------------------------------------------------------------
' Bookmark folder overlay — restyled to the light dialog aesthetic, ported
' behavior verbatim.
' ---------------------------------------------------------------------------

sub videoDetailScreenLoadItemBookmarkFolders()
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
        if videoDetailScreenResponseRequiresSignIn(response) then videoDetailScreenRequestSignInAgain(response)
        return
    end if
    m.itemBookmarkFolders = []
    if response.folders <> invalid then m.itemBookmarkFolders = response.folders
    videoDetailScreenRenderActions()
    if m.bookmarkOverlayOpen then videoDetailScreenRenderBookmarkOverlayFolders()
end sub

sub videoDetailScreenOpenBookmarkOverlay()
    if m.item = invalid or m.item.itemId <= 0 then return
    m.bookmarkOverlayOpen = true
    m.bookmarkOverlayGroup.visible = true
    m.bookmarkOverlayStatusLabel.text = "Загрузка папок..."
    m.bookmarkFolders = []
    videoDetailScreenRenderBookmarkOverlayFolders()
    videoDetailScreenLoadBookmarkFoldersForOverlay()
end sub

sub videoDetailScreenCloseBookmarkOverlay()
    m.bookmarkOverlayOpen = false
    m.bookmarkOverlayGroup.visible = false
end sub

sub videoDetailScreenLoadBookmarkFoldersForOverlay()
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
        if videoDetailScreenResponseRequiresSignIn(response)
            videoDetailScreenRequestSignInAgain(response)
            return
        end if
        message = "Не удалось загрузить папки закладок."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        m.bookmarkOverlayStatusLabel.text = message
        return
    end if

    m.bookmarkFolders = []
    if response.folders <> invalid then m.bookmarkFolders = response.folders
    if m.selectedBookmarkFolderIndex >= m.bookmarkFolders.Count() then m.selectedBookmarkFolderIndex = m.bookmarkFolders.Count() - 1
    if m.selectedBookmarkFolderIndex < 0 then m.selectedBookmarkFolderIndex = 0

    if m.bookmarkFolders.Count() = 0
        m.bookmarkOverlayStatusLabel.text = "Пока нет папок закладок."
    else
        m.bookmarkOverlayStatusLabel.text = "Выберите папку"
    end if
    videoDetailScreenRenderBookmarkOverlayFolders()
end sub

sub videoDetailScreenRenderBookmarkOverlayFolders()
    if m.bookmarkOverlayFoldersHost = invalid then return
    theme = UiThemeLight()
    childCount = m.bookmarkOverlayFoldersHost.getChildCount()
    if childCount > 0 then m.bookmarkOverlayFoldersHost.removeChildrenIndex(childCount, 0)
    m.bookmarkOverlayRowNodes = []

    maxRows = m.bookmarkFolders.Count()
    if maxRows > 6 then maxRows = 6
    for index = 0 to maxRows - 1
        folder = m.bookmarkFolders[index]
        row = CreateObject("roSGNode", "Group")
        row.translation = [0, index * 50]

        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = 380
        bg.height = 42
        bg.color = theme.surfaceAlt
        row.appendChild(bg)

        marker = CreateObject("roSGNode", "Label")
        if videoDetailScreenBookmarkFolderContainsItem(folder.folderId)
            marker.text = "Вкл"
        else
            marker.text = "Выкл"
        end if
        marker.translation = [14, 11]
        marker.width = 44
        marker.color = theme.muted
        row.appendChild(marker)

        label = CreateObject("roSGNode", "Label")
        label.text = folder.title
        label.translation = [64, 11]
        label.width = 236
        label.color = theme.text
        row.appendChild(label)

        count = CreateObject("roSGNode", "Label")
        count.text = videoDetailScreenBookmarkFolderCountText(folder)
        count.translation = [300, 11]
        count.width = 64
        count.color = theme.muted
        count.horizAlign = "right"
        row.appendChild(count)

        m.bookmarkOverlayFoldersHost.appendChild(row)
        m.bookmarkOverlayRowNodes.Push(bg)
    end for

    videoDetailScreenUpdateBookmarkOverlayFocus()
end sub

function videoDetailScreenBookmarkFolderContainsItem(folderId as Integer) as Boolean
    if m.itemBookmarkFolders = invalid then return false
    for each folder in m.itemBookmarkFolders
        if folder <> invalid and folder.folderId = folderId then return true
    end for
    return false
end function

function videoDetailScreenBookmarkFolderCountText(folder as Dynamic) as String
    if folder = invalid or folder.count = invalid then return ""
    return StrI(folder.count).Trim()
end function

sub videoDetailScreenUpdateBookmarkOverlayFocus()
    theme = UiThemeLight()
    for index = 0 to m.bookmarkOverlayRowNodes.Count() - 1
        if index = m.selectedBookmarkFolderIndex
            m.bookmarkOverlayRowNodes[index].color = theme.surfaceFocus
        else
            m.bookmarkOverlayRowNodes[index].color = theme.surfaceAlt
        end if
    end for
end sub

sub videoDetailScreenMoveBookmarkOverlayFolder(delta as Integer)
    if m.bookmarkFolders.Count() = 0 then return
    nextIndex = m.selectedBookmarkFolderIndex + delta
    if nextIndex < 0 then nextIndex = 0
    maxIndex = m.bookmarkFolders.Count() - 1
    if maxIndex > 5 then maxIndex = 5
    if nextIndex > maxIndex then nextIndex = maxIndex
    m.selectedBookmarkFolderIndex = nextIndex
    videoDetailScreenUpdateBookmarkOverlayFocus()
end sub

sub videoDetailScreenToggleSelectedBookmarkFolder()
    if m.item = invalid or m.bookmarkFolders.Count() = 0 then return
    folder = m.bookmarkFolders[m.selectedBookmarkFolderIndex]
    m.bookmarkOverlayStatusLabel.text = "Обновление закладки..."

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
        if videoDetailScreenResponseRequiresSignIn(response)
            videoDetailScreenRequestSignInAgain(response)
            return
        end if
        message = "Не удалось обновить закладку."
        if response <> invalid and response.message <> invalid and response.message <> "" then message = response.message
        m.bookmarkOverlayStatusLabel.text = message
        return
    end if

    m.bookmarkOverlayStatusLabel.text = "Закладка обновлена."
    videoDetailScreenLoadItemBookmarkFolders()
    videoDetailScreenLoadBookmarkFoldersForOverlay()
end sub

' ---------------------------------------------------------------------------
' onKeyEvent — focusArea state machine: "actions" / "description" /
' "content" / "episodes"
' ---------------------------------------------------------------------------

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false

    if m.descriptionOverlayOpen
        if key = "back" or key = "OK" then videoDetailScreenCloseDescriptionOverlay()
        return true
    end if

    if m.bookmarkOverlayOpen
        if key = "back"
            videoDetailScreenCloseBookmarkOverlay()
        else if key = "up"
            videoDetailScreenMoveBookmarkOverlayFolder(-1)
        else if key = "down"
            videoDetailScreenMoveBookmarkOverlayFolder(1)
        else if key = "OK"
            videoDetailScreenToggleSelectedBookmarkFolder()
        end if
        return true
    end if

    ' Back from the episode list (reached via OK on a season tile) pops back
    ' to the content row list instead of leaving the screen — a deliberate,
    ' one-off exception to this app's usual "Back always exits" convention,
    ' since episodes here is a genuine drill-down from the seasons row, not
    ' a peer state. Doesn't apply to a single-season/movie's episode list,
    ' which has no seasons row to pop to.
    if key = "back" and m.focusArea = "episodes" and m.hasSeasonsRow
        videoDetailScreenCancelPlaybackPreflight()
        m.focusArea = "content"
        videoDetailScreenSetHeroScrolled(false)
        videoDetailScreenApplySectionVisibility()
        videoDetailScreenUpdateEpisodesFocus()
        videoDetailScreenUpdateContentFocus()
        return true
    end if

    if key = "back"
        videoDetailScreenCancelPlaybackPreflight()
        m.top.backRequested = true
        return true
    end if

    if m.errorGroup.visible
        if key = "OK"
            videoDetailScreenLoadDetail()
            return true
        end if
        return false
    end if

    if m.detailGroup.visible <> true then return false

    if m.focusArea = "actions"
        if key = "up"
            if m.selectedActionIndex > 0
                m.selectedActionIndex = m.selectedActionIndex - 1
                videoDetailScreenUpdateActionsFocus()
            else
                m.focusArea = "description"
                videoDetailScreenUpdateActionsFocus()
                videoDetailScreenUpdateDescriptionFocus()
            end if
            return true
        else if key = "down"
            if m.selectedActionIndex < m.actionRows.Count() - 1
                m.selectedActionIndex = m.selectedActionIndex + 1
                videoDetailScreenUpdateActionsFocus()
            else if m.contentRows.Count() > 0
                m.focusArea = "content"
                videoDetailScreenApplySectionVisibility()
                videoDetailScreenUpdateActionsFocus()
                videoDetailScreenUpdateContentFocus()
            end if
            return true
        else if key = "OK"
            actionId = m.actionRows[m.selectedActionIndex].id
            if actionId = "play"
                videoDetailScreenStartSelectedPlayback()
            else if actionId = "trailer"
                videoDetailScreenStartTrailerPlayback()
            else if actionId = "bookmark"
                videoDetailScreenOpenBookmarkOverlay()
            end if
            return true
        end if
        return false
    end if

    if m.focusArea = "description"
        if key = "down"
            m.focusArea = "actions"
            m.selectedActionIndex = 0
            videoDetailScreenUpdateDescriptionFocus()
            videoDetailScreenUpdateActionsFocus()
            return true
        else if key = "OK"
            videoDetailScreenOpenDescriptionOverlay()
            return true
        end if
        return false
    end if

    if m.focusArea = "content"
        if key = "left"
            videoDetailScreenMoveContentRailCursor(-1)
            return true
        else if key = "right"
            videoDetailScreenMoveContentRailCursor(1)
            return true
        else if key = "up"
            if m.contentRowIndex = 0
                m.focusArea = "actions"
                videoDetailScreenApplySectionVisibility()
                videoDetailScreenUpdateContentFocus()
                videoDetailScreenUpdateActionsFocus()
            else
                videoDetailScreenMoveContentRow(-1)
            end if
            return true
        else if key = "down"
            videoDetailScreenMoveContentRow(1)
            return true
        else if key = "OK"
            videoDetailScreenActivateContentRow()
            return true
        end if
        return false
    end if

    if m.focusArea = "episodes"
        if key = "up"
            if m.currentEpisodeIndex = 0
                if m.hasSeasonsRow then m.focusArea = "content" else m.focusArea = "actions"
                videoDetailScreenSetHeroScrolled(false)
                videoDetailScreenApplySectionVisibility()
                videoDetailScreenUpdateEpisodesFocus()
                if m.focusArea = "content" then videoDetailScreenUpdateContentFocus() else videoDetailScreenUpdateActionsFocus()
            else
                videoDetailScreenMoveEpisode(-1)
            end if
            return true
        else if key = "down"
            videoDetailScreenMoveEpisode(1)
            return true
        else if key = "OK"
            videoDetailScreenStartSelectedPlayback()
            return true
        else if key = "options"
            videoDetailScreenToggleCurrentEpisodeWatched()
            return true
        end if
        return false
    end if

    return false
end function
