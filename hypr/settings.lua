-- ~/.config/hypr/settings.lua
hl.config({
    general = {
        gaps_in          = 3,
        gaps_out         = 10,
        border_size      = 2,
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },
    decoration = {
        rounding         = 3,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
        blur = {
            enabled            = true,
            size               = 6,
            passes             = 2,
            vibrancy           = 0.1696,
            ignore_opacity     = true,
        },
    },
    animations = { enabled = true },
    dwindle    = { preserve_split = true },
    master     = { new_status = "master" },
    misc       = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
        vrr                     = 2,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
        disable_hyprland_guiutils_check = true,
        disable_xdg_env_checks = true,
    },
})

hl.config({
    cursor = { no_hardware_cursors = true },
})

hl.config({
    xwayland = { force_zero_scaling = true },
})

hl.config({
    render = { direct_scanout = 2 },
})

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = { natural_scroll = true },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
