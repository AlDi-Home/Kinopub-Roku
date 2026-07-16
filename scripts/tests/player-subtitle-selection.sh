#!/usr/bin/env bash
set -euo pipefail

file="components/screens/PlayerScreen.brs"

if grep -q "Subtitles disabled for debugging" "$file"; then
  echo "Subtitle selection must not be stubbed out." >&2
  exit 1
fi

grep -q "subtitleTracks = contentSubtitleTracksForPreferred(preferredSubtitleTrackName)" "$file"
grep -q "content.SubtitleTracks = subtitleTracks" "$file"
grep -q "content.SubtitleConfig = { TrackName: preferredSubtitleTrackName }" "$file"
grep -q "function savedPreferredSubtitleTrackNameForPlayback" "$file"
grep -q "content = playbackContentNode(savedPreferredSubtitleTrackNameForPlayback())" "$file"
grep -q 'm.videoNode.globalCaptionMode = "On"' "$file"
grep -q 'm.videoNode.globalCaptionMode = "Off"' "$file"
grep -q "m.videoNode.subtitleTrack = trackName" "$file"
grep -q "m.preferences\\[\"subtitleTrackId\"\\]" "$file"
grep -q "reloadPlaybackWithSubtitle(trackName)" "$file"
