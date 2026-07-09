#!/usr/bin/env bash
set -euo pipefail

file="components/screens/PlayerScreen.brs"

if grep -q "Quality disabled for debugging" "$file"; then
  echo "Quality selection must not be stubbed out." >&2
  exit 1
fi

grep -q "sub applyQualitySelection(option as Object)" "$file"
grep -q "sub reloadPlaybackWithQuality(option as Object)" "$file"
grep -q 'm.preferences\["qualityId"\]' "$file"
grep -q 'm.preferences\["qualityUrl"\]' "$file"
grep -q 'm.preferences\["qualityLabel"\]' "$file"
grep -q "selectedIndex = playbackOptionIndexForQuality(option)" "$file"
grep -q "m.playbackOptionIndex = selectedIndex" "$file"
grep -q "m.videoNode.content = playbackContentNode(savedPreferredSubtitleTrackNameForPlayback())" "$file"
grep -q "function playbackOptionIndexForQuality(option as Dynamic) as Integer" "$file"
grep -q "sub applySavedQualityPreference()" "$file"
