#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="${WALL_DIR:-$HOME/Downloads}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CURRENT_LINK="$CACHE_DIR/current"
mkdir -p "$CACHE_DIR"

pick() {
  if command -v rofi &>/dev/null; then
    selected=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
      | rofi -dmenu -p "Wallpaper" -theme ~/.config/rofi/wallpaper.rasi 2>/dev/null)
  else
    # fix: was missing -o between -iname flags (AND instead of OR — found nothing)
    selected=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)
  fi
  echo "${selected:-}"
}

apply() {
  local img="$1"
  [ -z "$img" ] && exit 1
  [ ! -f "$img" ] && exit 1

  ln -sf "$img" "$CURRENT_LINK"

  pkill swaybg 2>/dev/null || true
  swaybg -i "$img" -m fill & disown

  matugen image "$img" --prefer saturation

  # reload hyprland colors (dofile picks it up on next hl.config reload)
  hyprctl reload 2>/dev/null || true

  pkill quickshell 2>/dev/null || true
  quickshell & disown
}

case "${1:-}" in
  "")          img=$(pick); apply "$img" ;;
  -r|--random) img=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1); apply "$img" ;;
  -s|--set)    apply "$2" ;;
  --restore)
    if [ -L "$CURRENT_LINK" ] && [ -f "$(readlink "$CURRENT_LINK")" ]; then
      img="$(readlink "$CURRENT_LINK")"
      pkill swaybg 2>/dev/null || true
      swaybg -i "$img" -m fill & disown
      pkill quickshell 2>/dev/null || true
      quickshell & disown
    fi ;;
  *) apply "$1" ;;
esac
