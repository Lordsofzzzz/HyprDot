-- ~/.config/hypr/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("bash ~/.config/scripts/session-restore.sh")
    hl.exec_cmd("pgrep -x quickshell >/dev/null || QS_NO_RELOAD_POPUP=1 quickshell")
end)
