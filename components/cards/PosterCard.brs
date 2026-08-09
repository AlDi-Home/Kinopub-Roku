' Shared poster-card builder for the new light-theme screens.
' Included via <script> alongside components/theme/UiTheme.brs.
' Function names are prefixed posterCard*/poster* to avoid colliding with the
' near-identical (dark-theme) card builders still in HomeScreen.brs, since
' BrightScript sub/function names are global across every loaded script in
' the channel regardless of which component included them.

' Builds a card's node skeleton — every node that can ever appear for the
' given layout's flags, created once — then hands off to updatePosterCard to
' fill in the item-specific content. Skeleton shape (which optional nodes
' exist at all) is decided entirely by `layout`'s boolean flags, never by
' `item`'s data, so a pooled card (components/grid/VideoGrid.brs) can be
' rebound to a completely different item later via updatePosterCard without
' ever changing its own child list — only visibility/content toggles per
' rebind. Non-pooled callers (VideoDetailScreen.brs's rail rows, legacy
' HomeScreen.brs) are unaffected: they only ever read the returned handles'
' .node/.focusBg/.focusShadow, and this returns a superset of that.
function createPosterCard(item as Object, layout as Object) as Object
    theme = UiThemeLight()

    card = CreateObject("roSGNode", "Group")
    card.scaleRotateCenter = [Int(layout.cardWidth / 2), Int(layout.cardHeight / 2)]

    focusShadow = posterCardAppendShadow(card, layout)

    focusBg = CreateObject("roSGNode", "Rectangle")
    focusBg.width = layout.cardWidth
    focusBg.height = layout.cardHeight
    if layout.DoesExist("focusOverlay") and layout.focusOverlay
        focusColor = posterCardVisualStateColor(true, false)
        if layout.DoesExist("focusSurface") then focusColor = layout.focusSurface
        focusBg.color = focusColor
    else
        focusBg.color = theme.surface
    end if
    card.appendChild(focusBg)

    if layout.DoesExist("focusFrame") and layout.focusFrame
        posterCardAppendFocusFrame(card, layout, theme.focusBorder)
    end if

    fallback = CreateObject("roSGNode", "Rectangle")
    fallback.translation = [layout.posterX, 8]
    fallback.width = layout.posterWidth
    fallback.height = layout.posterHeight
    fallback.color = theme.posterFallback
    fallback.visible = true
    card.appendChild(fallback)

    poster = CreateObject("roSGNode", "Poster")
    poster.translation = [layout.posterX, 8]
    poster.width = layout.posterWidth
    poster.height = layout.posterHeight
    poster.loadDisplayMode = "scaleToFit"
    card.appendChild(poster)

    handles = { node: card, focusBg: focusBg, focusShadow: focusShadow, fallback: fallback, poster: poster }

    if layout.DoesExist("showUnwatchedBadge") and layout.showUnwatchedBadge
        badge = posterCardBuildUnwatchedBadge(card, layout, theme)
        handles.unwatchedBadgeBg = badge.bg
        handles.unwatchedBadgeLabel = badge.label
    end if

    if layout.DoesExist("showWatchedBadge") and layout.showWatchedBadge
        badge = posterCardBuildWatchedBadge(card, layout, theme)
        handles.watchedBadgeBg = badge.bg
        handles.watchedBadgeLabel = badge.label
    end if

    title = CreateObject("roSGNode", "Label")
    title.translation = [layout.textX, layout.titleY]
    title.width = layout.textWidth
    title.height = layout.titleHeight
    title.wrap = false
    title.color = theme.text
    title.font.size = 18
    card.appendChild(title)
    handles.title = title

    if layout.DoesExist("showYear") and layout.showYear
        year = CreateObject("roSGNode", "Label")
        yearY = 190
        if layout.DoesExist("yearY") then yearY = layout.yearY
        year.translation = [layout.textX, yearY]
        year.width = layout.textWidth
        year.height = 24
        year.font.size = 24
        year.horizAlign = "right"
        year.color = theme.muted
        card.appendChild(year)
        handles.year = year
    end if

    subtitle = CreateObject("roSGNode", "Label")
    subtitle.translation = [layout.textX, layout.subtitleY]
    subtitle.width = layout.textWidth
    subtitle.height = layout.subtitleHeight
    subtitle.color = theme.muted
    card.appendChild(subtitle)
    handles.subtitle = subtitle

    if layout.DoesExist("showProgress") and layout.showProgress
        progressY = 154
        if layout.DoesExist("progressY") then progressY = layout.progressY

        progressBg = CreateObject("roSGNode", "Rectangle")
        progressBg.translation = [layout.posterX, progressY]
        progressBg.width = layout.posterWidth
        progressBg.height = 5
        progressBg.color = theme.progressTrack
        card.appendChild(progressBg)

        progressFill = CreateObject("roSGNode", "Rectangle")
        progressFill.translation = [layout.posterX, progressY]
        progressFill.height = 5
        progressFill.color = theme.progressFill
        card.appendChild(progressFill)

        handles.progressBg = progressBg
        handles.progressFill = progressFill
    end if

    updatePosterCard(handles, item, layout)
    return handles
end function

' Rewrites every visual field a card's skeleton supports for a (possibly
' brand new) item + position, resetting each optional node's state before
' reapplying it — a pooled card previously showing e.g. a watched-badged
' movie must never "leak" that badge onto a live-TV channel card it gets
' rebound to. `layout` supplies the current x/y (position may differ from
' creation time — a pooled card's slot moves as the grid scrolls) and the
' same size/flag fields createPosterCard used to build the skeleton.
sub updatePosterCard(handles as Object, item as Object, layout as Object)
    if layout.DoesExist("x") and layout.DoesExist("y") then handles.node.translation = [layout.x, layout.y]

    handles.poster.uri = item.posterUrl
    handles.title.text = item.title

    subtitleText = item.subtitle
    if subtitleText = invalid or subtitleText = "" then subtitleText = item.metadata
    if subtitleText = invalid then subtitleText = ""
    handles.subtitle.text = subtitleText
    subtitleVisible = false
    if layout.DoesExist("focusOverlay") and layout.focusOverlay and subtitleText <> "" then subtitleVisible = true
    if layout.DoesExist("showYear") and layout.showYear then subtitleVisible = false
    handles.subtitle.visible = subtitleVisible

    if handles.DoesExist("year")
        yearText = posterCardYearText(item)
        handles.year.visible = yearText <> ""
        if yearText <> "" then handles.year.text = yearText
    end if

    if handles.DoesExist("unwatchedBadgeBg")
        count = posterCardIntegerField(item, "unwatchedCount", 0)
        visible = count > 0
        handles.unwatchedBadgeBg.visible = visible
        handles.unwatchedBadgeLabel.visible = visible
        if visible then handles.unwatchedBadgeLabel.text = StrI(count).Trim()
    end if

    if handles.DoesExist("watchedBadgeBg")
        visible = posterCardBooleanField(item, "watched", false)
        handles.watchedBadgeBg.visible = visible
        handles.watchedBadgeLabel.visible = visible
    end if

    if handles.DoesExist("progressBg")
        visible = posterCardProgressVisible(item)
        handles.progressBg.visible = visible
        handles.progressFill.visible = visible
        if visible then handles.progressFill.width = posterCardProgressWidth(item, layout.posterWidth)
    end if
end sub

' Soft drop shadow shown behind the currently-focused tile, paired with a
' scale-up on the card itself (caller sets cardInfo.node.scale) for a "pop"
' effect. Built hidden/behind everything (appended first); caller toggles
' cardInfo.focusShadow.visible on focus change.
function posterCardAppendShadow(card as Object, layout as Object) as Object
    margin = 16
    shadow = CreateObject("roSGNode", "Poster")
    shadow.translation = [-margin, -margin]
    shadow.width = layout.cardWidth + (margin * 2)
    shadow.height = layout.cardHeight + (margin * 2)
    shadow.uri = "pkg:/images/ui/tile-shadow.png"
    shadow.visible = false
    card.appendChild(shadow)
    return shadow
end function

function posterCardVisualStateColor(isFocused as Boolean, isSelected as Boolean) as String
    theme = UiThemeLight()
    if isFocused then return theme.surfaceFocus
    if isSelected then return theme.surfaceSelected
    return theme.surface
end function

function posterCardBaseFocusColor(hasOverlay as Boolean) as String
    return posterCardVisualStateColor(hasOverlay <> true, false)
end function

sub posterCardAppendFocusFrame(card as Object, layout as Object, color as String)
    frameSize = 4

    top = CreateObject("roSGNode", "Rectangle")
    top.width = layout.cardWidth
    top.height = frameSize
    top.color = color
    card.appendChild(top)

    bottom = CreateObject("roSGNode", "Rectangle")
    bottom.translation = [0, layout.cardHeight - frameSize]
    bottom.width = layout.cardWidth
    bottom.height = frameSize
    bottom.color = color
    card.appendChild(bottom)

    left = CreateObject("roSGNode", "Rectangle")
    left.width = frameSize
    left.height = layout.cardHeight
    left.color = color
    card.appendChild(left)

    right = CreateObject("roSGNode", "Rectangle")
    right.translation = [layout.cardWidth - frameSize, 0]
    right.width = frameSize
    right.height = layout.cardHeight
    right.color = color
    card.appendChild(right)
end sub

function posterCardYearText(item as Object) as String
    if item = invalid or type(item) <> "roAssociativeArray" then return ""
    if item.DoesExist("year") <> true or item.year = invalid then return ""

    valueType = type(item.year)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger"
        if item.year > 0 then return StrI(item.year).Trim()
    else if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble"
        year = Int(item.year)
        if year > 0 then return StrI(year).Trim()
    else if valueType = "String" or valueType = "roString"
        return item.year.Trim()
    end if

    return ""
end function

' Poster fills nearly the full tile width/height; only a thin strip below
' the image is reserved for the title. `width` drives every other
' proportion so the grid can size tiles to fill available horizontal space.
function posterCompactLayout(x as Integer, y as Integer, width = 200 as Integer) as Object
    posterX = 4
    posterWidth = width - (posterX * 2)
    posterHeight = Int(posterWidth * 1.5)
    titleY = 8 + posterHeight + 4
    titleHeight = 26
    cardHeight = titleY + titleHeight + 4

    return {
        x: x
        y: y
        cardWidth: width
        cardHeight: cardHeight
        posterX: posterX
        posterWidth: posterWidth
        posterHeight: posterHeight
        textX: 6
        textWidth: width - 12
        titleY: titleY
        titleHeight: titleHeight
        subtitleY: titleY + titleHeight
        subtitleHeight: 0
    }
end function

function posterFeaturedLayout(x as Integer, y as Integer) as Object
    return {
        x: x
        y: y
        cardWidth: 190
        cardHeight: 258
        posterX: 23
        posterWidth: 144
        posterHeight: 192
        textX: 12
        textWidth: 166
        titleY: 210
        titleHeight: 42
        subtitleY: 235
        subtitleHeight: 20
        yearY: 234
        progressY: 202
        focusOverlay: true
        focusFrame: true
        focusSurface: "#D9E9F2"
    }
end function

function posterCardIntegerField(item as Dynamic, key as String, fallback as Integer) as Integer
    if item = invalid or type(item) <> "roAssociativeArray" then return fallback
    if item.DoesExist(key) <> true or item[key] = invalid then return fallback
    value = item[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function posterCardStringField(item as Dynamic, key as String, fallback as String) as String
    if item = invalid or type(item) <> "roAssociativeArray" then return fallback
    if item.DoesExist(key) <> true or item[key] = invalid then return fallback
    value = item[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    return fallback
end function

function posterCardBooleanField(item as Dynamic, key as String, fallback as Boolean) as Boolean
    if item = invalid or type(item) <> "roAssociativeArray" then return fallback
    if item.DoesExist(key) <> true or item[key] = invalid then return fallback
    value = item[key]
    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return value
    return fallback
end function

function posterCardProgressVisible(item as Dynamic) as Boolean
    return posterCardIntegerField(item, "durationSeconds", 0) > 0 and posterCardIntegerField(item, "progressSeconds", 0) > 0
end function

function posterCardProgressWidth(item as Object, maxWidth as Integer) as Integer
    durationSeconds = posterCardIntegerField(item, "durationSeconds", 0)
    progressSeconds = posterCardIntegerField(item, "progressSeconds", 0)
    if durationSeconds <= 0 or progressSeconds <= 0 then return 0
    width = Int((progressSeconds * maxWidth) / durationSeconds)
    if width < 1 then width = 1
    if width > maxWidth then width = maxWidth
    return width
end function

sub posterCardAppendTypeBadge(card as Object, item as Object, theme as Object)
    badgeText = posterCardTypeBadgeText(item)
    if badgeText = "" then return

    chipWidth = 64

    badgeBg = CreateObject("roSGNode", "Rectangle")
    badgeBg.translation = [24, 14]
    badgeBg.width = chipWidth
    badgeBg.height = 24
    badgeBg.color = theme.chipBg
    badgeBg.opacity = 0.92
    card.appendChild(badgeBg)

    badgeBorderTop = CreateObject("roSGNode", "Rectangle")
    badgeBorderTop.translation = [24, 14]
    badgeBorderTop.width = chipWidth
    badgeBorderTop.height = 1
    badgeBorderTop.color = theme.chipBorder
    card.appendChild(badgeBorderTop)

    badgeBorderBottom = CreateObject("roSGNode", "Rectangle")
    badgeBorderBottom.translation = [24, 37]
    badgeBorderBottom.width = chipWidth
    badgeBorderBottom.height = 1
    badgeBorderBottom.color = theme.chipBorder
    card.appendChild(badgeBorderBottom)

    badgeBorderLeft = CreateObject("roSGNode", "Rectangle")
    badgeBorderLeft.translation = [24, 14]
    badgeBorderLeft.width = 1
    badgeBorderLeft.height = 24
    badgeBorderLeft.color = theme.chipBorder
    card.appendChild(badgeBorderLeft)

    badgeBorderRight = CreateObject("roSGNode", "Rectangle")
    badgeBorderRight.translation = [23 + chipWidth, 14]
    badgeBorderRight.width = 1
    badgeBorderRight.height = 24
    badgeBorderRight.color = theme.chipBorder
    card.appendChild(badgeBorderRight)

    label = CreateObject("roSGNode", "Label")
    label.text = badgeText
    label.translation = [24, 15]
    label.width = chipWidth
    label.height = 22
    label.horizAlign = "center"
    label.color = theme.chipText
    card.appendChild(label)
end sub

function posterCardTypeBadgeText(item as Dynamic) as String
    if item = invalid or type(item) <> "roAssociativeArray" then return ""
    if item.DoesExist("typeBadge") <> true or item.typeBadge = invalid then return ""
    badge = item.typeBadge
    if type(badge) <> "String" and type(badge) <> "roString" then return ""
    badge = badge.Trim()
    badge = UCase(badge)
    if Len(badge) > 3 then badge = Left(badge, 3)
    return badge
end function

' Up to 3 small rating chips (IMDb text-only, Kinopoisk icon+score, KinoPub-P
' icon+score) overlaid near the poster's bottom edge. Opt-in via
' layout.showRatingBadges; each chip is individually omitted when its rating
' value is empty or "0".
sub posterCardAppendRatingBadges(card as Object, item as Object, layout as Object, theme as Object)
    if layout.DoesExist("showRatingBadges") <> true or layout.showRatingBadges <> true then return

    badges = []

    imdbRating = posterCardStringField(item, "imdbRating", "")
    if imdbRating <> "" and imdbRating <> "0" then badges.Push({ text: "IMDb " + imdbRating, icon: "", width: 74 })

    kpRating = posterCardStringField(item, "kinopoiskRating", "")
    if kpRating <> "" and kpRating <> "0" then badges.Push({ text: kpRating, icon: "pkg:/images/ui/icon-kinopoisk.png", width: 50 })

    pRating = posterCardStringField(item, "kinopubRating", "")
    if pRating <> "" and pRating <> "0" then badges.Push({ text: pRating, icon: "pkg:/images/ui/icon-kinopub.png", width: 50 })

    if badges.Count() = 0 then return

    badgeHeight = 22
    y = 8 + layout.posterHeight - badgeHeight - 6
    x = layout.posterX + 6

    for each badge in badges
        posterCardAppendRatingChip(card, badge, x, y, badgeHeight, theme)
        x = x + badge.width + 4
    end for
end sub

sub posterCardAppendRatingChip(card as Object, badge as Object, x as Integer, y as Integer, height as Integer, theme as Object)
    bg = CreateObject("roSGNode", "Rectangle")
    bg.translation = [x, y]
    bg.width = badge.width
    bg.height = height
    bg.color = theme.badgeBg
    bg.opacity = 0.92
    card.appendChild(bg)

    textX = x + 6
    if badge.icon <> ""
        icon = CreateObject("roSGNode", "Poster")
        icon.translation = [x + 4, y + 3]
        icon.width = height - 6
        icon.height = height - 6
        icon.uri = badge.icon
        icon.loadDisplayMode = "scaleToFit"
        card.appendChild(icon)
        textX = x + height - 2
    end if

    label = CreateObject("roSGNode", "Label")
    label.text = badge.text
    label.translation = [textX, y + 2]
    label.width = badge.width - (textX - x) - 4
    label.height = height - 4
    label.horizAlign = "left"
    label.color = theme.badgeText
    card.appendChild(label)
end sub

' Red top-right count badge for in-progress serials with unwatched episodes.
' Built unconditionally whenever layout.showUnwatchedBadge is set (skeleton
' existence, not item-driven) — updatePosterCard toggles .visible per item
' based on item.unwatchedCount.
function posterCardBuildUnwatchedBadge(card as Object, layout as Object, theme as Object) as Object
    size = 28
    bx = layout.posterX + layout.posterWidth - size - 6
    by = 14

    bg = CreateObject("roSGNode", "Rectangle")
    bg.translation = [bx, by]
    bg.width = size
    bg.height = size
    bg.color = theme.unwatchedBadgeBg
    card.appendChild(bg)

    label = CreateObject("roSGNode", "Label")
    label.translation = [bx, by + Int((size - 22) / 2)]
    label.width = size
    label.height = 22
    label.horizAlign = "center"
    label.color = theme.unwatchedBadgeText
    card.appendChild(label)

    return { bg: bg, label: label }
end function

' Small checkmark badge for a fully-watched season/item (bottom-left of the
' poster, distinct from the unwatched-count badge's top-right position since
' an item is never both). Built unconditionally whenever
' layout.showWatchedBadge is set; updatePosterCard toggles .visible per item
' based on item.watched.
function posterCardBuildWatchedBadge(card as Object, layout as Object, theme as Object) as Object
    size = 28
    bx = layout.posterX + 6
    by = 8 + layout.posterHeight - size - 6

    bg = CreateObject("roSGNode", "Rectangle")
    bg.translation = [bx, by]
    bg.width = size
    bg.height = size
    bg.color = theme.watchedBadgeBg
    card.appendChild(bg)

    label = CreateObject("roSGNode", "Label")
    label.text = "✓"
    label.translation = [bx, by + Int((size - 22) / 2)]
    label.width = size
    label.height = 22
    label.horizAlign = "center"
    label.color = theme.watchedBadgeText
    card.appendChild(label)

    return { bg: bg, label: label }
end function
