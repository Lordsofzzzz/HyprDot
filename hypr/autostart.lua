-- ~/.config/hypr/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("bash ~/.local/bin/wallpaper-picker.sh --restore")
    hl.exec_cmd("quickshell")
end)
