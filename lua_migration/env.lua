-- ~/.config/hypr/env.conf

--===========================
-- ENVIRONMENT VARIABLES
--===========================

hl.env("XCURSOR_SIZE","24")
hl.env("HYPRCURSOR_SIZE","24")

-- Essential Wayland Environment Variables
hl.env("XDG_CURRENT_DESKTOP","Hyprland")
hl.env("XDG_SESSION_TYPE","wayland")
hl.env("XDG_SESSION_DESKTOP","Hyprland")
hl.env("GDK_BACKEND","wayland","x11","*")
hl.env(GTK_THEME,"Adwaita:dark")

-- Toolkit Settings
hl.env(QT_QPA_PLATFORM,"wayland;xcb")
hl.env("SDL_VIDEODRIVER","wayland")
hl.env("CLUTTER_BACKEND","wayland")

-- XDG Base Directories
hl.env(XDG_CONFIG_HOME,"$HOME/.config")
hl.env(XDG_CACHE_HOME,"$HOME/.cache")
hl.env(XDG_DATA_HOME,"$HOME/.local/share")
hl.env(XDG_STATE_HOME,"$HOME/.local/state")

