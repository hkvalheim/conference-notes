#!/usr/bin/env bash
# Extract still frames from a video at given HH:MM:SS timestamps.
#
# Usage:
#   extract_frames.sh VIDEO OUTPUT_DIR TIMESTAMP [TIMESTAMP ...]
#
# Example:
#   extract_frames.sh media/TALK-SLUG/source.mp4 docs/images/TALK-SLUG \
#     00:03:12 00:14:05 00:27:40
#
# Writes one JPEG per timestamp, named frame-HHMMSS.jpg, into OUTPUT_DIR.
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 VIDEO OUTPUT_DIR TIMESTAMP [TIMESTAMP ...]" >&2
  exit 1
fi

video="$1"
outdir="$2"
shift 2

if [ ! -f "$video" ]; then
  echo "No such video file: $video" >&2
  exit 1
fi

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg not found - install with: brew install ffmpeg" >&2; exit 1; }

mkdir -p "$outdir"

for ts in "$@"; do
  if ! [[ "$ts" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    echo "Skipping invalid timestamp (expected HH:MM:SS): $ts" >&2
    continue
  fi
  safe_ts="${ts//:/}"
  out="$outdir/frame-${safe_ts}.jpg"
  ffmpeg -y -ss "$ts" -i "$video" -frames:v 1 -q:v 3 "$out" -loglevel error
  echo "Wrote: $out" >&2
done
