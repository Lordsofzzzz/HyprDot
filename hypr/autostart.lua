-- ~/.config/hypr/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("bash ~/.config/scripts/session-restore.sh")
end)
