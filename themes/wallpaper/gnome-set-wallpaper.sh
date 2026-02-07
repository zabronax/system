#!/usr/bin/env bash
# Set wallpaper on GNOME via gsettings (Linux)
# Usage: gnome-set-wallpaper.sh <mode> <path-or-list-file>
#   mode: "exact"  - set specific wallpaper path (file:// URI)
#         "random" - not implemented yet

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
    echo "Not implemented yet." >&2
    exit 1
    ;;
  *)
    echo "Invalid mode: $MODE. Must be 'exact' or 'random'" >&2
    exit 1
    ;;
esac

[[ -f "$WALLPAPER_PATH" ]] || {
  echo "File not found: $WALLPAPER_PATH" >&2
  exit 1
}

# Build file:// URI (escape special chars for URI)
URI="file://${WALLPAPER_PATH// /%20}"

gsettings set org.gnome.desktop.background picture-uri "$URI"
gsettings set org.gnome.desktop.background picture-uri-dark "$URI"
