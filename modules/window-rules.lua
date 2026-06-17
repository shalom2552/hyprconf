-- ~/.config/hypr/modules/window-rules.lua
--===========================
-- WINDOW RULES
--===========================

-- Suppress maximize requests from all apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland drag issues
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

--===========================
-- FZF POPUP LAUNCHERS
--===========================

-- Base — common props for all fzf-popup-* subclasses
hl.window_rule({
    name  = "fzf-popup-base",
    match = { class = "^(fzf-popup-.*)$" },
    float        = true,
    center       = true,
    opacity      = "1.0 1.0",
    stay_focused = true,
    dim_around   = true,
    pin          = true,
})

-- App launcher
hl.window_rule({
    name  = "fzf-popup-launch",
    match = { class = "^(fzf-popup-launch)$" },
    size = "500 500",
})

-- Power menu
hl.window_rule({
    name  = "fzf-popup-power",
    match = { class = "^(fzf-popup-power)$" },
    size = "220 250",
})

-- Clipboard
hl.window_rule({
    name  = "fzf-popup-clip",
    match = { class = "^(fzf-popup-clip)$" },
    size = "800 500",
})

-- Window switcher
hl.window_rule({
    name  = "fzf-popup-alttab",
    match = { class = "^(fzf-popup-alttab)$" },
    size = "250 300",
})

-- Wallpaper
hl.window_rule({
    name  = "fzf-popup-wall",
    match = { class = "^(fzf-popup-wall)$" },
    size = "900 400",
})

--===========================
-- TRANSPARENCY
--===========================

-- NOTE: moved to apearance
-- -- Default transparency for all windows
-- hl.window_rule({
--     name    = "default-transparency",
--     match   = { class = ".*" },
--     opacity = "0.8 0.8",
-- })

-- Opaque exceptions — media players, image viewers
hl.window_rule({
    name    = "opaque-media",
    match   = { class = "^(mpv|vlc|loupe|eog)$" },
    opacity = "1.0 override",
})

-- Opaque when fullscreen
hl.window_rule({
    name    = "opaque-fullscreen",
    match   = { fullscreen = true },
    opacity = "1.0 override",
})

-- Transparency toggle target: windows tagged "opaque" render fully opaque
-- This tule must be last transparent rule
-- Keybind (SUPER+SHIFTY+Z)
hl.window_rule({
    name    = "tag-opaque",
    match   = { tag = "opaque" },
    opacity = "1.0 override",
})

--===========================
-- APP RULES
--===========================

-- hyprland-run floating terminal
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Zen Browser Picture-in-Picture
hl.window_rule({
    name  = "pip",
    match = { class = "^(zen)$", title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
    size  = "640 360",
})
