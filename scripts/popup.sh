#!/usr/bin/env bash
# ~/.config/hypr/scripts/popup.sh
#
# Generic popup wrapper for Hyprland keybinds.
# Spawns a floating kitty window running any command (binary or script path).
# Prevents duplicate popups — kills existing if open, toggles off if same popup.
#
# Window class is derived as "fzf-popup-<cmdname>" so each command gets its
# own windowrule entry for size; no dynamic resizing needed.
#
# If the command supports --print (outputs a desktop file path), popup.sh
# captures it and dispatches via hyprctl for proper Wayland env.
#
# Usage: popup.sh <command> [--print|-p]
#   popup.sh launch --print
#   popup.sh power
#   popup.sh clip

set -uo pipefail


# ==== CONSTANTS ====

STATE_FILE="/tmp/fzf_popup_cmd"

CMD="${1:-}"
EXTRA_ARGS="${2:-}"

[[ -z "$CMD" ]] && { echo "Usage: popup.sh <command>"; exit 1; }

# Resolve to full path if not absolute
[[ "$CMD" != /* ]] && CMD="$HOME/.local/bin/$CMD"

# Derive window class from command basename: fzf-popup-launch, fzf-popup-power, etc.
WINDOW_CLASS="fzf-popup-$(basename "$CMD")"


# ==== GUARD: toggle or switch ====

existing=$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class | startswith("fzf-popup")) | .class' \
    | head -1)

if [[ -n "$existing" ]]; then
    hyprctl dispatch killwindow "class:${existing}"
    rm -f "$STATE_FILE"
    [[ "$existing" == "$WINDOW_CLASS" ]] && exit 0
    sleep 0.05
fi


# ==== SPAWN ====

echo "$CMD" > "$STATE_FILE"

if [[ "$EXTRA_ARGS" == "--print" || "$EXTRA_ARGS" == "-p" ]]; then
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
    CLIP_OUT="/tmp/fzf_popup_clipboard"
    rm -f "$CLIP_OUT"
    FZF_POPUP_OUT="$CLIP_OUT" kitty --class "$WINDOW_CLASS" -e "$CMD"
    rm -f "$STATE_FILE"
    if [[ -f "$CLIP_OUT" ]]; then
        wl-copy < "$CLIP_OUT" &
        rm -f "$CLIP_OUT"
    fi
fi
