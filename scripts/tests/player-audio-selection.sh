#!/usr/bin/env bash
set -euo pipefail

file="components/screens/PlayerScreen.brs"

grep -q "audioSelectionApplied = false" "$file"
grep -q "audioSelectionApplied = true" "$file"
grep -q "m.savedAudioPreferenceApplied = audioSelectionApplied" "$file"
grep -q "m.videoNode.audioTrack = trackId" "$file"
grep -q "applySavedAudioPreference()" "$file"
grep -q "sub startPlaybackAtPosition" "$file"
grep -q "function autoApplySavedAudioPreferenceEnabled" "$file"
grep -q "function availableAudioMenuItems" "$file"
grep -A 8 'if state = "playing"' "$file" | grep -q "applySavedAudioPreference()"
grep -A 6 "sub onAvailableAudioTracksChanged" "$file" | grep -q "if m.playbackStarted = true then applySavedAudioPreference()"
grep -q 'm.preferences\["audioCurrentTrack"\] = trackId' "$file"
if grep -A 8 "sub startPlaybackAtPosition" "$file" | grep -q "applySavedAudioPreference()"; then
  echo "Saved audio must be applied after availableAudioTracks changes, not during playback startup." >&2
  exit 1
fi
