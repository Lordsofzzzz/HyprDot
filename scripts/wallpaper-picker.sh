#!/usr/bin/env bash
# Pick and apply a wallpaper
# Usage:
#   wallpaper-picker.sh           — random wallpaper
#   wallpaper-picker.sh -r        — random wallpaper
#   wallpaper-picker.sh -s <path> — set specific wallpaper
#   wallpaper-picker.sh <path>    — set specific wallpaper
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/apply-wallpaper.sh"

WALL_DIR="${WALL_DIR:-$HOME/Pictures/wallpapers}"

random_img() {
  find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1
}

case "${1:-}" in
  -r|--random|"")
    img=$(random_img)
    [ -z "$img" ] && { echo "No wallpapers found in $WALL_DIR"; exit 1; }
    apply "$img"
    ;;
  -s|--set)
    [ -n "${2:-}" ] && apply "$2" || { echo "usage: $0 -s <path>"; exit 1; }
    ;;
  *)
    apply "$1"
    ;;
esac
