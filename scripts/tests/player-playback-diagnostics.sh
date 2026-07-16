#!/usr/bin/env bash
set -euo pipefail

file="components/screens/PlayerScreen.brs"

grep -q 'observeField("downloadedSegment", "onVideoDownloadedSegmentChanged")' "$file"
grep -q 'observeField("streamingSegment", "onVideoStreamingSegmentChanged")' "$file"
grep -q 'sub onVideoDownloadedSegmentChanged' "$file"
grep -q 'sub onVideoStreamingSegmentChanged' "$file"
grep -q 'sub printVideoPlaybackDiagnostics' "$file"
grep -q 'measuredBitrateBps=' "$file"
grep -q 'declaredBitrateBps=' "$file"
grep -q 'downloadDurationMs=' "$file"
grep -q 'throughputBps=' "$file"
grep -q 'underrun=' "$file"
grep -q 'function playbackDiagnosticRedactedUrl' "$file"
grep -Fq '"?[redacted]"' "$file"

if grep -q 'print "PlayerScreen: stream format="; streamFormat; " url="; streamUrl' "$file"; then
  echo "Playback logs must redact signed stream query parameters." >&2
  exit 1
fi
