# HyprDot — Agent Guide

## Repo setup

- The repo is designed to live at `~/.config`. This user has it at both `/home/aditya/Hyprdot` (git repo) AND `~/.config` (live config). **Edit both** or they'll diverge.
- `README.md` lives in the repo only (not in live config).
- No test framework. Validate by restarting Quickshell or running `hyprctl reload`.

## Architecture

- **Hyprland** uses the Lua API (0.55+). Config files in `hypr/` use `hl.*` functions. Not the legacy hyprlang format.
- **Quickshell** in `quickshell/`. Entry point: `shell.qml`. Components in `quickshell/components/`, services in `quickshell/services/`.
- **matugen** generates color files from wallpaper. `Colors.qml`, `colors.css`, `colors.toml`, `hyprland-colors.lua` are generated — do not hand-edit. They're in `.gitignore`.
- **NVIDIA-specific**: `no_hardware_cursors = true` in `settings.lua`, GBM/NVIDIA env vars in `uwsm/env`. Live config has `direct_scanout = 0` (disabled).
- **Keybinds**: SUPER (Windows key) is `mainMod`.

## Gotchas

- `hypr/hyprland-colors.lua` is loaded via `dofile()`, not `require()`. Hyprland only auto-reloads `require()`d files. Wallpaper changes must run `hyprctl reload` explicitly.
- Live config at `~/.config` may have local customizations not in the repo (e.g., extra window rules, different render settings).
- `scripts/` directory referenced in README does not exist in this checkout.

## Commands

| Action | Command |
|---|---|
| Reload Hyprland | `hyprctl reload` |
| Restart Quickshell | `QS_NO_RELOAD_POPUP=1 quickshell` |
| Regenerate colors | `matugen image <path> --source-color-index 0` |
