#!/usr/bin/env bash
# Shared wallpaper apply function — sourced by session-restore.sh and wallpaper-picker.sh
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CURRENT_LINK="$CACHE_DIR/current"

apply() {
  local img="$1"
  [ -z "$img" ] && exit 1
  [ ! -f "$img" ] && exit 1

  mkdir -p "$CACHE_DIR"
  ln -sf "$img" "$CURRENT_LINK"

  pkill swaybg 2>/dev/null || true
  swaybg -i "$img" -m fill & disown

  matugen image "$img" --source-color-index 0

  hyprctl reload 2>/dev/null || true

  pkill quickshell 2>/dev/null || true
  quickshell & disown
}
