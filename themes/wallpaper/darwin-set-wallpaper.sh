#!/usr/bin/env bash
# Set wallpaper on macOS using AppleScript
# Usage: darwin-set-wallpaper.sh <mode> <path-or-list-file>
#   mode: "exact"  - set specific wallpaper path
#         "random" - pick random wallpaper from list file (one path per line)

set -euo pipefail

[[ $# -eq 2 ]] || {
  echo "Usage: $0 <exact|random> <wallpaper-path|wallpaper-list-file>" >&2
  exit 1
}

MODE="$1"
ARG="$2"

case "$MODE" in
  exact)
    WALLPAPER_PATH="$ARG"
    ;;
  random)
    [[ -r "$ARG" ]] || { echo "Cannot read: $ARG" >&2; exit 1; }
    # Read wallpaper paths from the file (one path per line)
    # Filter out empty lines
    mapfile -t WALLPAPERS < <(grep -v '^[[:space:]]*$' "$ARG")
    # Check if any wallpapers were found
    (( ${#WALLPAPERS[@]} > 0 )) || { echo "No wallpapers found in: $ARG" >&2; exit 1; }
    # Pick a random wallpaper from the list
    # Use $RANDOM which gives a random integer between 0 and 32767
    RANDOM_INDEX=$((RANDOM % ${#WALLPAPERS[@]}))
    WALLPAPER_PATH="${WALLPAPERS[$RANDOM_INDEX]}"
    ;;
  *)
    echo "Invalid mode: $MODE. Must be 'exact' or 'random'" >&2
    exit 1
    ;;
esac

# Escape double quotes for AppleScript
osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"${WALLPAPER_PATH//\"/\\\"}\""
