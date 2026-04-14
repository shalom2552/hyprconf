#!/usr/bin/env bash

# Reload Kitty instances
killall -USR1 .kitty-wrapped

# Reload Neovim instances
# We use 2>/dev/null on the nvim command to silently ignore stale/dead sockets
for server in $(find "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" -name "nvim*" -type s 2>/dev/null); do
    nvim --server "$server" --remote-send '<C-\><C-n>:lua _G.reload_matugen_colors()<CR>' 2>/dev/null &
done

# Reload CAVA
if pgrep -x "cava" > /dev/null; then
    # Rebuild the final config file from the base and newly generated colors
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    # Tell CAVA to reload the config
    killall -USR1 cava
fi

wait
