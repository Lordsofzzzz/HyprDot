#!/usr/bin/env bash
# Restore the last wallpaper + theme on session start
# Called from Hyprland autostart: hl.on("hyprland.start", ...)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/apply-wallpaper.sh"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CURRENT_LINK="$CACHE_DIR/current"

if [ -L "$CURRENT_LINK" ] && [ -f "$(readlink "$CURRENT_LINK")" ]; then
  apply "$(readlink "$CURRENT_LINK")"
fi

quickshell & disown
