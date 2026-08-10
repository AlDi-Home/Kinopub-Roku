function KinoItemService(client as Object) as Object
    return {
        client: client
        detail: kinoItemDetail
        similar: kinoItemSimilar
        trailer: kinoItemTrailer
        mediaLinks: kinoItemMediaLinks
        normalizeResponse: kinoItemNormalizeResponse
        normalizeSimilarResponse: kinoItemNormalizeSimilarResponse
        normalizeSimilarItem: kinoItemNormalizeSimilarItem
        normalizeTrailerResponse: kinoItemNormalizeTrailerResponse
        normalizeMediaLinksResponse: kinoItemNormalizeMediaLinksResponse
        normalizeVideos: kinoItemNormalizeVideos
        normalizeSeasons: kinoItemNormalizeSeasons
        normalizeMedia: kinoItemNormalizeMedia
        mergeMediaLinkFields: kinoItemMergeMediaLinkFields
        mediaStream: kinoItemMediaStream
        streamFromUrlContainer: kinoItemStreamFromUrlContainer
        qualityOptions: kinoItemQualityOptions
        addQualityUrlOptions: kinoItemAddQualityUrlOptions
        trackOptions: kinoItemTrackOptions
        sourceFileLabel: kinoItemSourceFileLabel
        streamFormatForUrl: kinoItemStreamFormatForUrl
        watchStatus: kinoItemWatchStatus
        watchedState: kinoItemWatchedState
        progressSeconds: kinoItemProgressSeconds
        subscribed: kinoItemSubscribed
        posterUrl: kinoItemPosterUrl
        backdropUrl: kinoItemBackdropUrl
        description: kinoItemDescription
        metadata: kinoItemMetadata
        detailFacts: kinoItemDetailFacts
        appendFact: kinoItemAppendFact
        stringField: kinoItemStringField
        integerField: kinoItemIntegerField
        booleanField: kinoItemBooleanField
        arrayField: kinoItemArrayField
        failure: kinoItemFailure
    }
end function

function kinoItemDetail(accessToken as String, itemId as Integer) as Object
    if itemId <= 0
        return { ok: false, error: "invalid_item", message: "Unable to open this video.", status: 0 }
    end if

    response = m.client.get("/v1/items/" + StrI(itemId).Trim(), { access_token: accessToken }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeResponse(response.body, itemId)
end function

function kinoItemSimilar(accessToken as String, itemId as Integer, perpage = 6 as Integer) as Object
    if itemId <= 0 then return { ok: false, error: "invalid_item", message: "Unable to load similar videos.", status: 0 }

    response = m.client.get("/v1/items/similar", { access_token: accessToken, id: itemId, perpage: perpage }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeSimilarResponse(response.body)
end function

function kinoItemTrailer(accessToken as String, itemId as Integer) as Object
    if itemId <= 0 then return { ok: false, error: "invalid_item", message: "Unable to load trailer.", status: 0 }

    response = m.client.get("/v1/items/trailer", { access_token: accessToken, id: itemId }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeTrailerResponse(response.body)
end function

function kinoItemMediaLinks(accessToken as String, media as Object) as Object
    mediaId = m.integerField(media, "mediaId", 0)
    if mediaId <= 0
        return { ok: false, error: "invalid_media", message: "Unable to refresh this video.", status: 0 }
    end if

    response = m.client.get("/v1/items/media-links", { access_token: accessToken, mid: mediaId }, m.client.defaultTimeoutMs)
    if response.ok <> true then return m.failure(response)
    return m.normalizeMediaLinksResponse(response.body, media)
end function

function kinoItemNormalizeResponse(body as Dynamic, requestedItemId as Integer) as Object
    item = invalid
    if body <> invalid and type(body) = "roAssociativeArray"
        if body.DoesExist("item") then item = body.item else item = body
    end if

    if item = invalid or type(item) <> "roAssociativeArray"
        return { ok: false, error: "invalid_response", message: "Video details were not available.", status: 0 }
    end if

    itemId = m.integerField(item, "id", requestedItemId)
    title = m.stringField(item, "title", "")
    if title = "" then title = m.stringField(item, "name", "")
    if title = "" then title = "Untitled"

    videos = m.normalizeVideos(item)
    seasons = m.normalizeSeasons(item)
    playableCount = 0
    for each video in videos
        if video.isPlayable then playableCount = playableCount + 1
    end for
    for each season in seasons
        for each episode in season.episodes
            if episode.isPlayable then playableCount = playableCount + 1
        end for
    end for

    return {
        ok: true
        item: {
            itemId: itemId
            title: title
            originalTitle: m.stringField(item, "original_title", "")
            type: m.stringField(item, "type", "")
            posterUrl: m.posterUrl(item)
            backdropUrl: m.backdropUrl(item)
            description: m.description(item)
            metadata: m.metadata(item)
            detailFacts: m.detailFacts(item)
            imdbRating: m.stringField(item, "imdb_rating", "")
            kinopoiskRating: m.stringField(item, "kinopoisk_rating", "")
            kinopubRating: m.stringField(item, "rating", "")
            videos: videos
            seasons: seasons
            playableCount: playableCount
            subscribed: m.subscribed(item)
        }
    }
end function

' KinoPub's /v1/items/<id> documents this field under both "subscribed" and
' the alias "in_watchlist" — read whichever is present.
function kinoItemSubscribed(item as Dynamic) as Boolean
    if item <> invalid and type(item) = "roAssociativeArray" and item.DoesExist("subscribed")
        return m.booleanField(item, "subscribed", false)
    end if
    return m.booleanField(item, "in_watchlist", false)
end function

function kinoItemNormalizeSimilarResponse(body as Dynamic) as Object
    items = []

    if body <> invalid
        if type(body) = "roArray"
            for each item in body
                normalized = m.normalizeSimilarItem(item)
                if normalized.itemId > 0 then items.Push(normalized)
                if items.Count() = 6 then exit for
            end for
        else if type(body) = "roAssociativeArray"
            if body.DoesExist("items") and body.items <> invalid
                if type(body.items) = "roArray"
                    for each item in body.items
                        normalized = m.normalizeSimilarItem(item)
                        if normalized.itemId > 0 then items.Push(normalized)
                        if items.Count() = 6 then exit for
                    end for
                else if type(body.items) = "roAssociativeArray"
                    for each sectionKey in body.items
                        section = body.items[sectionKey]
                        if section <> invalid and type(section) = "roAssociativeArray" and section.DoesExist("items") and section.items <> invalid and type(section.items) = "roArray"
                            for each item in section.items
                                normalized = m.normalizeSimilarItem(item)
                                if normalized.itemId > 0 then items.Push(normalized)
                                if items.Count() = 6 then exit for
                            end for
                        else if section <> invalid and type(section) = "roArray"
                            for each item in section
                                normalized = m.normalizeSimilarItem(item)
                                if normalized.itemId > 0 then items.Push(normalized)
                                if items.Count() = 6 then exit for
                            end for
                        end if
                        if items.Count() = 6 then exit for
                    end for
                end if
            end if
        end if
    end if

    return { ok: true, items: items }
end function

function kinoItemNormalizeSimilarItem(item as Dynamic) as Object
    title = m.stringField(item, "title", "")
    if title = "" then title = m.stringField(item, "name", "")
    if title = "" then title = "Untitled"

    subtitleParts = []
    year = m.integerField(item, "year", 0)
    if year > 0 then subtitleParts.Push(StrI(year).Trim())

    contentType = m.stringField(item, "type", "")
    if contentType <> "" then subtitleParts.Push(contentType)

    return {
        itemId: m.integerField(item, "id", 0)
        mediaId: 0
        title: title
        subtitle: subtitleParts.Join("  |  ")
        posterUrl: m.posterUrl(item)
        type: contentType
    }
end function

function kinoItemNormalizeTrailerResponse(body as Dynamic) as Object
    trailer = invalid

    if body <> invalid
        if type(body) = "roArray"
            for each entry in body
                if entry <> invalid and type(entry) = "roAssociativeArray" and entry.DoesExist("trailer")
                    trailer = entry.trailer
                    exit for
                end if
            end for
        else if type(body) = "roAssociativeArray"
            if body.DoesExist("trailer") then trailer = body.trailer else trailer = body
        end if
    end if

    if trailer = invalid or type(trailer) <> "roAssociativeArray"
        return { ok: true, trailer: invalid }
    end if

    streamUrl = ""
    qualityOptions = []
    files = m.arrayField(trailer, "files")
    for index = 0 to files.Count() - 1
        file = files[index]
        if file <> invalid and type(file) = "roAssociativeArray"
            url = m.stringField(file, "url", "")
            if url <> ""
                label = m.stringField(file, "quality", "")
                if label <> "" then label = label + "p" else label = "Trailer"
                qualityOptions.Push({
                    id: label
                    label: label
                    url: url
                    streamFormat: m.streamFormatForUrl(url)
                    isAuto: false
                })
                if streamUrl = "" then streamUrl = url
            end if
        end if
    end for

    return {
        ok: true
        trailer: {
            id: m.stringField(trailer, "id", "")
            title: "Trailer"
            externalUrl: m.stringField(trailer, "url", "")
            streamUrl: streamUrl
            streamFormat: m.streamFormatForUrl(streamUrl)
            qualityOptions: qualityOptions
            isPlayable: streamUrl <> ""
        }
    }
end function

function kinoItemNormalizeVideos(item as Object) as Object
    videos = []
    sourceVideos = m.arrayField(item, "videos")
    for index = 0 to sourceVideos.Count() - 1
        videos.Push(m.normalizeMedia(sourceVideos[index], 0, index + 1))
    end for
    return videos
end function

function kinoItemNormalizeSeasons(item as Object) as Object
    seasons = []
    sourceSeasons = m.arrayField(item, "seasons")
    for seasonIndex = 0 to sourceSeasons.Count() - 1
        sourceSeason = sourceSeasons[seasonIndex]
        if sourceSeason <> invalid and type(sourceSeason) = "roAssociativeArray"
            seasonNumber = m.integerField(sourceSeason, "number", seasonIndex + 1)
            title = m.stringField(sourceSeason, "title", "")
            if title = "" then title = "Season " + StrI(seasonNumber).Trim()

            episodes = []
            sourceEpisodes = m.arrayField(sourceSeason, "episodes")
            for episodeIndex = 0 to sourceEpisodes.Count() - 1
                episodes.Push(m.normalizeMedia(sourceEpisodes[episodeIndex], seasonNumber, episodeIndex + 1))
            end for

            seasons.Push({
                title: title
                number: seasonNumber
                episodes: episodes
            })
        end if
    end for
    return seasons
end function

function kinoItemNormalizeMedia(media as Dynamic, seasonNumber as Integer, fallbackEpisodeNumber as Integer) as Object
    stream = m.mediaStream(media)
    qualityOptions = m.qualityOptions(media, stream)
    tracks = m.trackOptions(media)
    title = m.stringField(media, "title", "")
    episodeNumber = m.integerField(media, "number", fallbackEpisodeNumber)
    if title = "" and seasonNumber > 0 then title = "Episode " + StrI(episodeNumber).Trim()
    if title = "" then title = "Video"
    watchStatus = m.watchStatus(media)

    return {
        mediaId: m.integerField(media, "id", 0)
        title: title
        subtitle: m.stringField(media, "subtitle", "")
        seasonNumber: seasonNumber
        episodeNumber: episodeNumber
        videoNumber: episodeNumber
        durationSeconds: m.integerField(media, "duration", 0)
        thumbnailUrl: m.stringField(media, "thumbnail", "")
        watchStatus: watchStatus
        watched: watchStatus = 1
        progressSeconds: m.progressSeconds(media)
        streamUrl: stream.url
        streamFormat: stream.format
        qualityOptions: qualityOptions
        audioTracks: tracks.audio
        subtitleTracks: tracks.subtitles
        isPlayable: stream.url <> ""
    }
end function

function kinoItemNormalizeMediaLinksResponse(body as Dynamic, media as Object) as Object
    if media = invalid or type(media) <> "roAssociativeArray"
        return { ok: false, error: "invalid_media", message: "Unable to refresh this video.", status: 0 }
    end if

    merged = m.mergeMediaLinkFields(media, body)
    refreshed = m.normalizeMedia(merged, m.integerField(media, "seasonNumber", 0), m.integerField(media, "episodeNumber", 1))
    refreshed.title = m.stringField(media, "title", refreshed.title)
    refreshed.subtitle = m.stringField(media, "subtitle", refreshed.subtitle)
    refreshed.mediaId = m.integerField(media, "mediaId", refreshed.mediaId)
    refreshed.videoNumber = m.integerField(media, "videoNumber", refreshed.videoNumber)
    refreshed.durationSeconds = m.integerField(media, "durationSeconds", refreshed.durationSeconds)
    refreshed.watchStatus = m.integerField(media, "watchStatus", refreshed.watchStatus)
    refreshed.watched = m.booleanField(media, "watched", refreshed.watched)
    refreshed.progressSeconds = m.integerField(media, "progressSeconds", refreshed.progressSeconds)

    if refreshed.streamUrl = ""
        return { ok: false, error: "no_playable_stream", message: "No playable video is available.", status: 0, media: refreshed }
    end if

    return { ok: true, media: refreshed }
end function

function kinoItemMergeMediaLinkFields(media as Object, body as Dynamic) as Object
    merged = {}
    for each key in media
        merged[key] = media[key]
    end for

    source = body
    if body <> invalid and type(body) = "roAssociativeArray"
        if body.DoesExist("media") and body.media <> invalid
            source = body.media
        else if body.DoesExist("links") and body.links <> invalid
            source = body.links
        else if body.DoesExist("item") and body.item <> invalid
            source = body.item
        end if
    end if

    if source <> invalid and type(source) = "roAssociativeArray"
        if source.DoesExist("files") then merged.files = source.files
        if source.DoesExist("subtitles") then merged.subtitles = source.subtitles
        if source.DoesExist("audios") then merged.audios = source.audios
        if source.DoesExist("audio") then merged.audio = source.audio
        if source.DoesExist("hls") then merged.hls = source.hls
        if source.DoesExist("url") then merged.url = source.url
    end if

    return merged
end function

' HLS-only by product decision — a direct mp4/"http" file is never returned
' here even when that's the only stream the API offers for this media; see
' kinoItemStreamFromUrlContainer's matching hlsKeys list.
function kinoItemMediaStream(media as Dynamic) as Object
    if media = invalid or type(media) <> "roAssociativeArray" then return { url: "", format: "" }

    if media.DoesExist("files") and media.files <> invalid
        files = media.files
        if type(files) = "roAssociativeArray"
            hls = m.stringField(files, "hls", "")
            if hls <> "" then return { url: hls, format: "hls" }

            hlsFallback = ""
            for each key in files
                candidate = files[key]
                if type(candidate) = "String" or type(candidate) = "roString"
                    if Instr(1, candidate, ".m3u8") > 0 then hlsFallback = candidate
                end if
            end for
            if hlsFallback <> "" then return { url: hlsFallback, format: "hls" }
        else if type(files) = "roArray"
            hlsFallback = ""
            for each file in files
                if file <> invalid and type(file) = "roAssociativeArray"
                    urlStream = { url: "", format: "" }
                    if file.DoesExist("urls") and file.urls <> invalid then urlStream = m.streamFromUrlContainer(file.urls)
                    if urlStream.url = "" and file.DoesExist("url") and file.url <> invalid then urlStream = m.streamFromUrlContainer(file.url)
                    if urlStream.url = "" then urlStream = { url: m.stringField(file, "url", ""), format: m.stringField(file, "format", "") }
                    if urlStream.url <> "" and (urlStream.format = "hls" or Instr(1, urlStream.url, ".m3u8") > 0)
                        hlsFallback = urlStream.url
                    end if
                else if type(file) = "String" or type(file) = "roString"
                    if Instr(1, file, ".m3u8") > 0 then hlsFallback = file
                end if
            end for
            if hlsFallback <> "" then return { url: hlsFallback, format: "hls" }
        end if
    end if

    directHls = m.stringField(media, "hls", "")
    if directHls <> "" then return { url: directHls, format: "hls" }

    return { url: "", format: "" }
end function

function kinoItemStreamFromUrlContainer(container as Dynamic) as Object
    if container = invalid then return { url: "", format: "" }

    containerType = type(container)
    if containerType = "String" or containerType = "roString"
        if Instr(1, container, ".m3u8") > 0 then return { url: container, format: "hls" }
        return { url: "", format: "" }
    end if

    if containerType <> "roAssociativeArray" then return { url: "", format: "" }

    ' "http" (direct mp4 file) deliberately excluded — HLS-only per product
    ' decision, so this never returns/offers a direct-file stream.
    hlsKeys = ["hls4", "hls2", "hls"]
    for each key in hlsKeys
        url = m.stringField(container, key, "")
        if url <> "" then return { url: url, format: "hls" }
    end for

    directUrl = m.stringField(container, "url", "")
    if directUrl <> "" and Instr(1, directUrl, ".m3u8") > 0 then return { url: directUrl, format: "hls" }

    return { url: "", format: "" }
end function

function kinoItemQualityOptions(media as Dynamic, selectedStream as Object) as Object
    options = []
    seen = {}

    if selectedStream <> invalid and selectedStream.url <> "" and selectedStream.format = "hls"
        options.Push({
            id: "auto"
            label: "Auto"
            url: selectedStream.url
            streamFormat: "hls"
            isAuto: true
        })
        seen[selectedStream.url] = true
    end if

    if media <> invalid and type(media) = "roAssociativeArray" and media.DoesExist("files") and media.files <> invalid
        files = media.files
        if type(files) = "roAssociativeArray"
            for each key in files
                candidate = files[key]
                if type(candidate) = "String" or type(candidate) = "roString"
                    if Instr(1, candidate, "http") = 1 and not seen.DoesExist(candidate)
                        options.Push({
                            id: key
                            label: m.sourceFileLabel(key, candidate)
                            url: candidate
                            streamFormat: m.streamFormatForUrl(candidate)
                            isAuto: false
                        })
                        seen[candidate] = true
                    end if
                end if
            end for
        else if type(files) = "roArray"
            for each file in files
                if file <> invalid and type(file) = "roAssociativeArray"
                    label = m.stringField(file, "quality", "")
                    if label = "" then label = m.stringField(file, "name", "")
                    if label = "" then label = m.sourceFileLabel(label, "")
                    if file.DoesExist("urls") and file.urls <> invalid
                        m.addQualityUrlOptions(options, seen, label, file.urls)
                    else if file.DoesExist("url") and file.url <> invalid and type(file.url) = "roAssociativeArray"
                        m.addQualityUrlOptions(options, seen, label, file.url)
                    end if

                    urlStream = { url: "", format: "" }
                    if file.DoesExist("urls") and file.urls <> invalid then urlStream = m.streamFromUrlContainer(file.urls)
                    if urlStream.url = "" and file.DoesExist("url") and file.url <> invalid then urlStream = m.streamFromUrlContainer(file.url)
                    if urlStream.url = "" then urlStream = { url: m.stringField(file, "url", ""), format: m.stringField(file, "format", "") }

                    if urlStream.url <> "" and not seen.DoesExist(urlStream.url)
                        if label = "" then label = m.sourceFileLabel(label, urlStream.url)
                        options.Push({
                            id: label
                            label: label
                            url: urlStream.url
                            streamFormat: urlStream.format
                            isAuto: urlStream.format = "hls"
                        })
                        seen[urlStream.url] = true
                    end if
                end if
            end for
        end if
    end if

    if options.Count() = 0 and selectedStream <> invalid and selectedStream.url <> ""
        options.Push({
            id: "default"
            label: "Default"
            url: selectedStream.url
            streamFormat: selectedStream.format
            isAuto: selectedStream.format = "hls"
        })
    end if

    return options
end function

sub kinoItemAddQualityUrlOptions(options as Object, seen as Object, baseLabel as String, urls as Dynamic)
    if urls = invalid or type(urls) <> "roAssociativeArray" then return

    ' "http" (direct mp4 file) deliberately excluded — HLS-only.
    for each key in ["hls4", "hls2", "hls"]
        url = m.stringField(urls, key, "")
        if url <> "" and not seen.DoesExist(url)
            label = baseLabel
            if label = "" then label = m.sourceFileLabel(key, url)
            label = label + " " + key
            options.Push({
                id: label + "-" + key
                label: label
                url: url
                streamFormat: "hls"
                isAuto: true
            })
            seen[url] = true
        end if
    end for
end sub

function kinoItemSourceFileLabel(key as String, url as String) as String
    lowerKey = LCase(key)
    if Instr(1, lowerKey, "1080") > 0 then return "1080p"
    if Instr(1, lowerKey, "720") > 0 then return "720p"
    if Instr(1, lowerKey, "480") > 0 then return "480p"
    if Instr(1, lowerKey, "360") > 0 then return "360p"
    if Instr(1, LCase(url), ".m3u8") > 0 then return "Auto"
    if key <> "" then return key
    return "Default"
end function

function kinoItemStreamFormatForUrl(url as String) as String
    if Instr(1, url, ".m3u8") > 0 then return "hls"
    return "mp4"
end function

function kinoItemTrackOptions(media as Dynamic) as Object
    audio = []
    subtitles = []

    if media <> invalid and type(media) = "roAssociativeArray"
        sourceAudio = m.arrayField(media, "audio")
        if sourceAudio.Count() = 0 then sourceAudio = m.arrayField(media, "audios")
        for index = 0 to sourceAudio.Count() - 1
            track = sourceAudio[index]
            if track <> invalid and type(track) = "roAssociativeArray"
                ' Roku doesn't support AC3/E-AC3 decode on most models — drop
                ' these tracks entirely rather than offer a pick that won't
                ' actually play audio. kinoapi.com's audio track schema
                ' exposes a dedicated "codec" field (e.g. "aac"/"ac3") ; the
                ' substring match also catches "eac3"/"ac-3" spellings.
                codec = LCase(m.stringField(track, "codec", ""))
                if Instr(1, codec, "ac3") = 0
                    label = m.stringField(track, "title", "")
                    if label = "" then label = m.stringField(track, "lang", "")
                    if label = "" then label = "Audio " + StrI(index + 1).Trim()
                    audio.Push({
                        id: m.stringField(track, "id", label)
                        label: label
                        language: m.stringField(track, "lang", "")
                    })
                end if
            end if
        end for

        sourceSubtitles = m.arrayField(media, "subtitles")
        for index = 0 to sourceSubtitles.Count() - 1
            track = sourceSubtitles[index]
            if track <> invalid and type(track) = "roAssociativeArray"
                label = m.stringField(track, "title", "")
                if label = "" then label = m.stringField(track, "lang", "")
                if label = "" then label = "Subtitle " + StrI(index + 1).Trim()
                subtitles.Push({
                    id: m.stringField(track, "id", label)
                    label: label
                    language: m.stringField(track, "lang", "")
                    url: m.stringField(track, "url", "")
                })
            end if
        end for
    end if

    return { audio: audio, subtitles: subtitles }
end function

function kinoItemWatchStatus(media as Dynamic) as Integer
    if media <> invalid and type(media) = "roAssociativeArray" and media.DoesExist("watching") and media.watching <> invalid and type(media.watching) = "roAssociativeArray"
        if media.watching.DoesExist("status") and media.watching.status <> invalid
            statusType = type(media.watching.status)
            if statusType = "Integer" or statusType = "roInt" or statusType = "roInteger" or statusType = "Float" or statusType = "Double" or statusType = "roFloat" or statusType = "roDouble"
                status = m.integerField(media.watching, "status", -1)
                if status = -1 or status = 0 or status = 1 then return status
            end if
        end if
    end if

    watched = m.integerField(media, "watched", -1)
    if watched > 0 then return 1
    if watched = 0 then return -1

    if m.booleanField(media, "watched", false) then return 1
    return -1
end function

function kinoItemWatchedState(media as Dynamic) as Boolean
    return m.watchStatus(media) = 1
end function

function kinoItemProgressSeconds(media as Dynamic) as Integer
    if media <> invalid and type(media) = "roAssociativeArray" and media.DoesExist("watching") and media.watching <> invalid and type(media.watching) = "roAssociativeArray"
        progress = m.integerField(media.watching, "time", 0)
        if progress > 0 then return progress
    end if

    return m.integerField(media, "time", 0)
end function

function kinoItemPosterUrl(item as Dynamic) as String
    if item <> invalid and type(item) = "roAssociativeArray" and item.DoesExist("posters") and item.posters <> invalid and type(item.posters) = "roAssociativeArray"
        posters = item.posters
        url = m.stringField(posters, "medium", "")
        if url <> "" then return url
        url = m.stringField(posters, "big", "")
        if url <> "" then return url
        url = m.stringField(posters, "small", "")
        if url <> "" then return url
    end if

    return m.stringField(item, "poster", "")
end function

function kinoItemBackdropUrl(item as Dynamic) as String
    if item <> invalid and type(item) = "roAssociativeArray" and item.DoesExist("posters") and item.posters <> invalid and type(item.posters) = "roAssociativeArray"
        posters = item.posters
        url = m.stringField(posters, "wide", "")
        if url <> "" then return url
        url = m.stringField(posters, "big", "")
        if url <> "" then return url
    end if

    return m.stringField(item, "background", "")
end function

function kinoItemDescription(item as Dynamic) as String
    description = m.stringField(item, "plot", "")
    if description <> "" then return description

    description = m.stringField(item, "description", "")
    if description <> "" then return description

    description = m.stringField(item, "overview", "")
    if description <> "" then return description

    return m.stringField(item, "summary", "")
end function

function kinoItemMetadata(item as Dynamic) as Object
    values = []
    year = m.integerField(item, "year", 0)
    if year > 0 then values.Push(StrI(year).Trim())

    country = m.stringField(item, "country", "")
    if country <> "" then values.Push(country)

    genre = m.stringField(item, "genre", "")
    if genre <> "" then values.Push(genre)

    rating = m.stringField(item, "rating", "")
    if rating <> "" then values.Push(rating)

    return values
end function

function kinoItemDetailFacts(item as Dynamic) as Object
    facts = []
    if item = invalid or type(item) <> "roAssociativeArray" then return facts

    m.appendFact(facts, "Director", m.stringField(item, "director", ""))
    m.appendFact(facts, "Cast", m.stringField(item, "cast", ""))
    m.appendFact(facts, "Voice", m.stringField(item, "voice", ""))

    quality = m.stringField(item, "quality", "")
    if quality <> "" and quality <> "0"
        normalizedQuality = LCase(quality)
        if Instr(1, normalizedQuality, "p") = 0 then quality = quality + "p"
        m.appendFact(facts, "Quality", quality)
    end if

    audioParts = []
    langs = m.integerField(item, "langs", 0)
    if langs > 0 then audioParts.Push(StrI(langs).Trim() + " audio")
    if m.booleanField(item, "ac3", false) or m.integerField(item, "ac3", 0) > 0 then audioParts.Push("AC-3")
    subtitles = m.integerField(item, "subtitles", 0)
    if subtitles > 0 then audioParts.Push(StrI(subtitles).Trim() + " subtitles")
    m.appendFact(facts, "Tracks", audioParts.Join(", "))

    ratingParts = []
    imdbRating = m.stringField(item, "imdb_rating", "")
    if imdbRating <> "" and imdbRating <> "0" then ratingParts.Push("IMDb " + imdbRating)
    kpRating = m.stringField(item, "kinopoisk_rating", "")
    if kpRating <> "" and kpRating <> "0" then ratingParts.Push("KP " + kpRating)
    localRating = m.stringField(item, "rating", "")
    if localRating <> "" and localRating <> "0" then ratingParts.Push("KinoPub " + localRating)
    m.appendFact(facts, "Ratings", ratingParts.Join("  |  "))

    statsParts = []
    views = m.integerField(item, "views", 0)
    if views > 0 then statsParts.Push(StrI(views).Trim() + " views")
    comments = m.integerField(item, "comments", 0)
    if comments > 0 then statsParts.Push(StrI(comments).Trim() + " comments")
    m.appendFact(facts, "Activity", statsParts.Join(", "))

    if item.DoesExist("finished") and item.finished <> invalid
        if m.booleanField(item, "finished", false)
            m.appendFact(facts, "Series", "Finished")
        else
            m.appendFact(facts, "Series", "In production")
        end if
    end if

    if m.booleanField(item, "advert", false) then m.appendFact(facts, "Note", "Contains ads")

    return facts
end function

sub kinoItemAppendFact(facts as Object, label as String, value as String)
    value = value.Trim()
    if value = "" then return
    if facts.Count() >= 8 then return
    if Len(value) > 72 then value = Left(value, 69) + "..."

    facts.Push({
        label: label
        value: value
    })
end sub

function kinoItemStringField(source as Dynamic, key as String, fallback as String) as String
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback

    value = source[key]
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return StrI(value).Trim()
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Str(value).Trim()
    return fallback
end function

function kinoItemIntegerField(source as Dynamic, key as String, fallback as Integer) as Integer
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback

    value = source[key]
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then return Int(value)
    return fallback
end function

function kinoItemBooleanField(source as Dynamic, key as String, fallback as Boolean) as Boolean
    if source = invalid or type(source) <> "roAssociativeArray" then return fallback
    if source.DoesExist(key) <> true or source[key] = invalid then return fallback

    value = source[key]
    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then return value <> 0
    if valueType = "String" or valueType = "roString"
        normalized = value.Trim()
        normalized = LCase(normalized)
        if normalized = "true" or normalized = "1" then return true
        if normalized = "false" or normalized = "0" then return false
    end if
    return fallback
end function

function kinoItemArrayField(source as Dynamic, key as String) as Object
    if source = invalid or type(source) <> "roAssociativeArray" then return []
    if source.DoesExist(key) <> true or source[key] = invalid then return []
    if type(source[key]) = "roArray" then return source[key]
    return []
end function

function kinoItemFailure(response as Object) as Object
    errorCode = response.error
    if errorCode = invalid or errorCode = "" then errorCode = "network"
    return { ok: false, error: errorCode, message: response.message, status: response.status, rawBody: response.rawBody }
end function
