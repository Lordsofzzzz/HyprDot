#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="${WALL_DIR:-$HOME/Downloads}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CURRENT_LINK="$CACHE_DIR/current"
mkdir -p "$CACHE_DIR"

apply() {
  local img="$1"
  [ -z "$img" ] && exit 1
  [ ! -f "$img" ] && exit 1

  ln -sf "$img" "$CURRENT_LINK"

  pkill swaybg 2>/dev/null || true
  swaybg -i "$img" -m fill & disown

  matugen image "$img" --prefer saturation

  hyprctl reload 2>/dev/null || true

  pkill quickshell 2>/dev/null || true
  quickshell & disown
}

random_img() {
  find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1
}

case "${1:-}" in
  "")          img=$(random_img); apply "$img" ;;
  -r|--random) img=$(random_img); apply "$img" ;;
  -s|--set)    [ -n "${2:-}" ] && apply "$2" || { echo "usage: $0 -s <path>"; exit 1; } ;;
  --restore)
    if [ -L "$CURRENT_LINK" ] && [ -f "$(readlink "$CURRENT_LINK")" ]; then
      img="$(readlink "$CURRENT_LINK")"
      matugen image "$img" --prefer saturation
      pkill swaybg 2>/dev/null || true
      swaybg -i "$img" -m fill & disown
      hyprctl reload 2>/dev/null || true
      pkill quickshell 2>/dev/null || true
      quickshell & disown
    fi ;;
  *) apply "$1" ;;
esac
