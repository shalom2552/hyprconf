#!/usr/bin/env bash
# ~/.config/hypr/scripts/popups/clip.sh
# Self-contained clipboard picker popup for Hyprland.
# Keybind calls this directly; it manages its own kitty window.

set -uo pipefail

SCRIPT="$(realpath "$0")"
WINDOW_CLASS="fzf-popup-clip"

# ==== INNER: runs inside kitty — must check BEFORE the guard ====
if [[ "${1:-}" == "--inner" ]]; then
    SELECTION_FILE="${2:-}"
    selected=$(
        cliphist list \
        | fzf \
            --prompt="clip > " --pointer="▶" --marker="✓" \
            --bind="del:execute(echo {} | cliphist delete)+reload(cliphist list)" \
            --with-nth=2.. \
            --preview='echo {} | cliphist decode 2>/dev/null | cat -v | head -50' \
            --preview-window=right:50%:wrap \
            --preview-label=" Preview " \
            --border-label=" Clipboard History " \
            --no-info --border=rounded --height=100% \
            --color=fg:#c0caf5,bg:-1,hl:#bb9af7 \
            --color=fg+:#c0caf5,bg+:-1,hl+:#7dcfff \
            --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
    ) || exit 0

    [[ -z "$selected" ]] && exit 0
    echo "$selected" | cliphist decode > "$SELECTION_FILE"
    exit 0
fi

# ==== OUTER: launched by keybind ====

existing=$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class | startswith("fzf-popup")) | .class' \
    | head -1)

if [[ -n "$existing" ]]; then
    hyprctl dispatch killwindow "class:${existing}"
    [[ "$existing" == "$WINDOW_CLASS" ]] && exit 0
    sleep 0.05
fi

SELECTION_FILE=$(mktemp /tmp/clip-XXXXXX)
kitty --class "$WINDOW_CLASS" -e "$SCRIPT" --inner "$SELECTION_FILE"

if [[ -s "$SELECTION_FILE" ]]; then
    (setsid wl-copy < "$SELECTION_FILE"; rm -f "$SELECTION_FILE") &
    disown
else
    rm -f "$SELECTION_FILE"
fi
