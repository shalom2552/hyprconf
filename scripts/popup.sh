#!/usr/bin/env bash
# ~/.config/hypr/scripts/popup.sh
#
# Generic popup wrapper for Hyprland keybinds.
# Spawns a floating kitty window running any command (binary or script path).
# Prevents duplicate popups — focuses existing window if already open.
#
# If the command supports --print (outputs a desktop file path), popup.sh
# captures it and dispatches via hyprctl for proper Wayland env.
#
# Usage: popup.sh <command> [--print]
#   popup.sh launch --print
#   popup.sh ~/.config/hypr/scripts/picker/power.sh

set -uo pipefail


# ==== CONSTANTS ====

WINDOW_CLASS="fzf-popup"
STATE_FILE="/tmp/fzf_popup_cmd"
CMD="${1:-}"
EXTRA_ARGS="${2:-}"

[[ -z "$CMD" ]] && { echo "Usage: popup.sh <command>"; exit 1; }

# Resolve to full path if not absolute (covers ~/.local/bin which may not be
# in Hyprland's PATH at keybind-exec time)
[[ "$CMD" != /* ]] && CMD="$HOME/.local/bin/$CMD"


# ==== GUARD: toggle or switch ====

if hyprctl clients -j 2>/dev/null | jq -e --arg c "$WINDOW_CLASS" '.[] | select(.class == $c)' > /dev/null 2>&1; then
    current_cmd=$(cat "$STATE_FILE" 2>/dev/null || echo "")
    hyprctl dispatch killwindow "class:$WINDOW_CLASS"
    rm -f "$STATE_FILE"
    # Same popup → close only (toggle off)
    [[ "$current_cmd" == "$CMD" ]] && exit 0
    # Different popup → fall through to spawn new one
    sleep 0.05
fi


# ==== SPAWN ====

echo "$CMD" > "$STATE_FILE"

if [[ "$EXTRA_ARGS" == "--print" || "$EXTRA_ARGS" == "-p" ]]; then
    # Run kitty, capture the printed desktop file path, then dispatch via hyprctl
    RESULT=$(mktemp)
    kitty --class "$WINDOW_CLASS" -e bash -c "$CMD --print > $RESULT"
    rm -f "$STATE_FILE"

    desktop_file=$(cat "$RESULT")
    rm -f "$RESULT"
    [[ -z "$desktop_file" ]] && exit 0

    app_id="$(basename "$desktop_file" .desktop)"
    exec_cmd=$(grep -m1 "^Exec=" "$desktop_file" | cut -d= -f2- | sed 's/ %[a-zA-Z]//g')

    if grep -q "^Terminal=true" "$desktop_file"; then
        hyprctl dispatch exec -- kitty -e bash -c "$exec_cmd"
    else
        hyprctl dispatch exec -- gtk-launch "$app_id"
    fi
else
    exec kitty --class "$WINDOW_CLASS" -e "$CMD"
fi
