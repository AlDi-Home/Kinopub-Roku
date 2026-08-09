#!/usr/bin/env bash
set -euo pipefail

grep -q 'id="seasonCarouselGroup"' components/screens/PlayerScreen.xml
grep -q 'id="seasonCarouselHost"' components/screens/PlayerScreen.xml
grep -q 'id="seasonCarouselLeftChevron"' components/screens/PlayerScreen.xml
grep -q 'id="seasonCarouselRightChevron"' components/screens/PlayerScreen.xml
grep -q 'id="seasonCarouselStatusLabel"' components/screens/PlayerScreen.xml

grep -q 'm.seasonEpisodes = \[\]' components/screens/PlayerScreen.brs
grep -q 'm.seasonCarouselFocusIndex = 0' components/screens/PlayerScreen.brs
grep -q 'm.seasonCarouselVisibleStart = 0' components/screens/PlayerScreen.brs
grep -q 'm.maxVisibleSeasonCarouselItems' components/screens/PlayerScreen.brs
grep -q 'm.seasonCarouselRequestPending = false' components/screens/PlayerScreen.brs
grep -q 'if m.playback = invalid' components/screens/PlayerScreen.brs
grep -q 'if m.focusArea = "seasonCarousel" then m.focusArea = "controls"' components/screens/PlayerScreen.brs
grep -q 'renderSeasonCarousel()' components/screens/PlayerScreen.brs

grep -q 'sub buildSeasonCarouselFromPlayback' components/screens/PlayerScreen.brs
grep -q 'sub renderSeasonCarousel' components/screens/PlayerScreen.brs
grep -q 'function createSeasonCarouselCard' components/screens/PlayerScreen.brs
grep -q 'sub updateSeasonCarouselChevrons' components/screens/PlayerScreen.brs
grep -q 'sub moveSeasonCarousel' components/screens/PlayerScreen.brs
grep -q 'sub selectFocusedSeasonCarouselEpisode' components/screens/PlayerScreen.brs
grep -q 'function seasonCarouselCurrentMediaId' components/screens/PlayerScreen.brs
grep -q 'if key = "up" and hasSeasonCarousel()' components/screens/PlayerScreen.brs
grep -q 'if key = "down"' components/screens/PlayerScreen.brs
grep -q 'm.focusArea = "progress"' components/screens/PlayerScreen.brs

grep -q 'focusArea = "seasonCarousel"' components/screens/PlayerScreen.brs
grep -q 'reason: "seasonCarousel"' components/screens/PlayerScreen.brs
grep -q 'thumbnailUrl' components/screens/PlayerScreen.brs
grep -q 'Now' components/screens/PlayerScreen.brs
grep -q '✓' components/screens/PlayerScreen.brs

grep -q 'seasonEpisodes: videoDetailScreenSeasonEpisodesForMedia(media)' components/screens/VideoDetailScreen.brs
grep -q 'function videoDetailScreenSeasonEpisodesForMedia' components/screens/VideoDetailScreen.brs
grep -q 'thumbnailUrl: episode.thumbnailUrl' components/screens/VideoDetailScreen.brs
grep -q 'watched: episode.watched' components/screens/VideoDetailScreen.brs
grep -q 'requestMediaId > 0 and media.mediaId <> invalid and media.mediaId = requestMediaId' components/screens/VideoDetailScreen.brs
