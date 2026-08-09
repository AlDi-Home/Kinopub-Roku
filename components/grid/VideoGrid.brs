' Shared virtualized poster grid, used by BrowseScreen.brs, SearchScreen.brs,
' LiveScreen.brs, and ContinueScreen.brs — previously each built one
' createPosterCard node (components/cards/PosterCard.brs) per item up front,
' up to 300 items (uncapped in Live/Continue), with poster.uri set
' immediately on all of them; only toggling .visible on scroll, which
' doesn't stop the image load/decode or free the texture. Roku hardware
' genuinely struggles with hundreds of concurrently-loading Poster textures.
'
' VideoGridPool(config) instead keeps a small fixed pool of card nodes (only
' enough to cover the visible viewport plus a small buffer) and *rebinds*
' them (via PosterCard.brs's updatePosterCard) to whichever items are
' currently scrolled into view, as scroll/focus moves — never more nodes or
' image loads than the pool size, regardless of how many items the list
' actually has.
'
' Constructor-AA idiom (no BrightScript classes) matching this repo's
' source/services/KinoXService.brs pattern, just not a real API-backed
' service — methods are plain top-level functions referenced by the returned
' AA, called as pool.setItems(...) etc. (implicit `m` inside those functions
' is the AA itself, the standard BrightScript idiom used throughout this
' codebase).
'
' config fields:
'   scriptRoot     the screen's m.top — the scroll animation (below) is
'                   appended here, matching every screen's pre-existing
'                   per-screen scroll-animation technique exactly
'   content        the roSGNode Group cards are appended to (must have
'                   id="gridContent" in XML — hardcoded into the scroll
'                   animation's fieldToInterp below, true of all 4 screens)
'   columns        grid column count
'   cardWidth/cardGapX/cardGapY   card sizing/spacing (posterCompactLayout)
'   viewportHeight the visible scroll viewport's height in pixels
'   pad            the existing clip-padding trick's pad value (44 in every
'                   current caller) — content's resting translation and the
'                   scroll animation's keyValue both need it
'   layoutTemplate optional AA of posterCompactLayout flags (e.g.
'                   {showUnwatchedBadge: true}) — decides which optional
'                   nodes (badges/year/progress) exist in EVERY pooled card,
'                   for the pool's entire lifetime (a pooled card's node
'                   list can never change after creation; per-item
'                   visibility of those nodes is still item-data-driven via
'                   updatePosterCard, e.g. a badge node can exist on every
'                   card but only render itself when that item's own
'                   unwatchedCount > 0)
'   bufferRows     optional, defaults to 2 — extra off-screen rows kept
'                   bound so scrolling one row doesn't pop in unbound cards

function VideoGridPool(config as Object) as Object
    pool = {
        scriptRoot: config.scriptRoot
        content: config.content
        columns: config.columns
        cardWidth: config.cardWidth
        cardGapX: config.cardGapX
        cardGapY: config.cardGapY
        viewportHeight: config.viewportHeight
        pad: config.pad
        layoutTemplate: config.layoutTemplate
        bufferRows: 2

        items: []
        slots: []
        rowStep: 0
        poolRows: 0
        poolSize: 0
        offsetY: 0
        firstVisibleRow: 0
        lastVisibleRow: -1
        focusedIndex: -1
        isFocused: false
        scrollAnimation: invalid
        scrollInterpolator: invalid

        setItems: videoGridPoolSetItems
        appendItems: videoGridPoolAppendItems
        setFocus: videoGridPoolSetFocus
        rowCount: videoGridPoolRowCount
    }
    if config.DoesExist("bufferRows") then pool.bufferRows = config.bufferRows

    videoGridPoolBuildPool(pool)
    return pool
end function

sub videoGridPoolBuildPool(pool as Object)
    baseLayout = posterCompactLayout(0, 0, pool.cardWidth)
    pool.rowStep = baseLayout.cardHeight + pool.cardGapY
    pool.poolRows = Int((pool.viewportHeight + pool.rowStep - 1) / pool.rowStep) + pool.bufferRows
    pool.poolSize = pool.poolRows * pool.columns
    pool.firstVisibleRow = 0
    pool.lastVisibleRow = Int((pool.viewportHeight - 1) / pool.rowStep)

    placeholderItem = { title: "", subtitle: "", posterUrl: "", metadata: "" }
    pool.slots = []
    for i = 0 to pool.poolSize - 1
        layout = posterCompactLayout(0, 0, pool.cardWidth)
        if pool.layoutTemplate <> invalid
            for each key in pool.layoutTemplate
                layout[key] = pool.layoutTemplate[key]
            end for
        end if
        handles = createPosterCard(placeholderItem, layout)
        handles.node.visible = false
        pool.content.appendChild(handles.node)
        pool.slots.Push({ handles: handles, boundIndex: -1 })
    end for
end sub

function videoGridPoolLayoutFor(pool as Object, row as Integer, col as Integer) as Object
    x = col * (pool.cardWidth + pool.cardGapX)
    y = row * pool.rowStep
    layout = posterCompactLayout(x, y, pool.cardWidth)
    if pool.layoutTemplate <> invalid
        for each key in pool.layoutTemplate
            layout[key] = pool.layoutTemplate[key]
        end for
    end if
    return layout
end function

' Only rebinds a pool slot (poster.uri churn) when the item it should now
' show actually changed since the last call — rows still fully on-screen
' between two calls are left untouched. Visibility is still forced strictly
' to [firstVisibleRow, lastVisibleRow] here (not left to clippingRect alone)
' — clippingRect isn't reliably enforced on every runtime this ships to, a
' constraint already noted by every caller's own clip-padding setup.
sub videoGridPoolRebindWindow(pool as Object)
    itemCount = pool.items.Count()
    windowStartRow = pool.firstVisibleRow - 1
    if windowStartRow < 0 then windowStartRow = 0

    for slotIndex = 0 to pool.poolSize - 1
        rowInWindow = Int(slotIndex / pool.columns)
        col = slotIndex - (rowInWindow * pool.columns)
        absoluteRow = windowStartRow + rowInWindow
        itemIndex = (absoluteRow * pool.columns) + col
        slot = pool.slots[slotIndex]

        if itemIndex >= 0 and itemIndex < itemCount
            if slot.boundIndex <> itemIndex
                layout = videoGridPoolLayoutFor(pool, absoluteRow, col)
                updatePosterCard(slot.handles, pool.items[itemIndex], layout)
                slot.boundIndex = itemIndex
            end if
            slot.handles.node.visible = (absoluteRow >= pool.firstVisibleRow and absoluteRow <= pool.lastVisibleRow)
        else
            slot.handles.node.visible = false
            slot.boundIndex = -1
        end if
    end for
end sub

sub videoGridPoolApplyFocusVisual(pool as Object)
    theme = UiThemeLight()
    for each slot in pool.slots
        isFocused = pool.isFocused and slot.boundIndex >= 0 and slot.boundIndex = pool.focusedIndex
        slot.handles.focusShadow.visible = isFocused
        if isFocused
            slot.handles.focusBg.color = theme.surfaceFocus
            slot.handles.node.scale = [1.16, 1.16]
        else
            slot.handles.focusBg.color = theme.surface
            slot.handles.node.scale = [1.0, 1.0]
        end if
    end for
end sub

' Replaces a screen's *ResetGrid/*RenderGrid body: hands the pool a (usually
' freshly reloaded) items array reference and resets scroll to the top.
' Deliberately does not touch focus — pair with an immediate setFocus() call
' after, exactly like every existing caller's ResetGrid ended by calling
' UpdateGridFocus itself.
sub videoGridPoolSetItems(itemsRef as Object)
    m.items = itemsRef
    m.offsetY = 0
    m.content.translation = [m.pad, m.pad]
    if m.rowStep > 0
        m.firstVisibleRow = 0
        m.lastVisibleRow = Int((m.viewportHeight - 1) / m.rowStep)
    end if
    ' A new items array (e.g. switching left-menu rows/tabs) may still map
    ' slot->itemIndex identically to the old list (slot 0 -> index 0, etc.)
    ' — RebindWindow's own dedupe only compares that numeric index, so
    ' without this it would wrongly conclude nothing changed and leave
    ' every card showing the previous list's content.
    for each slot in m.slots
        slot.boundIndex = -1
    end for
    videoGridPoolRebindWindow(m)
end sub

' Replaces the pagination "load more" append path. m.items already shares
' the same underlying array reference the screen appended to, so nothing
' needs reassigning here — just lets any pool slots that were sitting on the
' unbound tail (itemIndex >= old count) pick up their now-real items.
sub videoGridPoolAppendItems(newCount as Integer)
    videoGridPoolRebindWindow(m)
    videoGridPoolApplyFocusVisual(m)
end sub

' Replaces a screen's *UpdateGridFocus: moves the scroll window if needed
' (animated, same technique/duration every screen already used) and
' refreshes which pool slot (if any) shows the focus-pop visual.
sub videoGridPoolSetFocus(index as Integer, isFocused as Boolean)
    m.focusedIndex = index
    m.isFocused = isFocused
    videoGridPoolScrollToFocus(m)
    videoGridPoolRebindWindow(m)
    videoGridPoolApplyFocusVisual(m)
end sub

sub videoGridPoolScrollToFocus(pool as Object)
    if pool.rowStep <= 0 then return
    currentOffset = pool.offsetY
    newOffset = currentOffset

    if pool.focusedIndex >= 0 and pool.items.Count() > 0
        focusedRow = Int(pool.focusedIndex / pool.columns)
        rowTop = focusedRow * pool.rowStep
        rowBottom = rowTop + pool.rowStep
        if rowTop < currentOffset then newOffset = rowTop
        if rowBottom > (currentOffset + pool.viewportHeight) then newOffset = rowBottom - pool.viewportHeight
        if newOffset < 0 then newOffset = 0
    end if

    if newOffset <> currentOffset then videoGridPoolAnimateScroll(pool, currentOffset, newOffset)
    pool.offsetY = newOffset
    pool.firstVisibleRow = Int(newOffset / pool.rowStep)
    pool.lastVisibleRow = Int((newOffset + pool.viewportHeight - 1) / pool.rowStep)
end sub

sub videoGridPoolAnimateScroll(pool as Object, fromY as Integer, toY as Integer)
    if pool.scrollAnimation = invalid
        animation = CreateObject("roSGNode", "Animation")
        animation.duration = 0.25
        animation.easeFunction = "inOutQuad"
        interpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        interpolator.key = [0, 1]
        interpolator.fieldToInterp = "gridContent.translation"
        animation.appendChild(interpolator)
        pool.scriptRoot.appendChild(animation)
        pool.scrollAnimation = animation
        pool.scrollInterpolator = interpolator
    end if

    pool.scrollInterpolator.keyValue = [[pool.pad, pool.pad - fromY], [pool.pad, pool.pad - toY]]
    pool.scrollAnimation.control = "start"
end sub

function videoGridPoolRowCount() as Integer
    if m.columns <= 0 or m.items.Count() = 0 then return 0
    return Int((m.items.Count() - 1) / m.columns) + 1
end function
