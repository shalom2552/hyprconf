# ~/.config/hypr/env.conf

##############################
# ENVIRONMENT VARIABLES
##############################

env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24

# --- Essential Wayland Environment Variables ---
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = GDK_BACKEND,wayland,x11,*
env = GTK_THEME,Adwaita:dark

# --- Toolkit Settings ---
env = QT_QPA_PLATFORM,wayland;xcb
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland

# --- XDG Base Directories ---
env = XDG_CONFIG_HOME,$HOME/.config
env = XDG_CACHE_HOME,$HOME/.cache
env = XDG_DATA_HOME,$HOME/.local/share
env = XDG_STATE_HOME,$HOME/.local/state

