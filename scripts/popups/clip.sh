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
            --style=full \
            --preview-label=" Preview " \
            --border-label=" Clipboard History " \
            --no-info --border=rounded --height=100% \
            --gutter=' ' \
            --color=fg:#cdd6f4,bg:-1,hl:#cba6f7 \
            --color=fg+:#cdd6f4,bg+:-1,hl+:#89dceb \
            --color=info:#89b4fa,prompt:#89dceb,pointer:#89dceb
    ) || exit 0

    [[ -z "$selected" ]] && exit 0
    echo "$selected" | cliphist decode > "$SELECTION_FILE"
    exit 0
fi

# ==== OUTER: launched by keybind ====

read -r existing_pid existing_class < <(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class | startswith("fzf-popup")) | "\(.pid) \(.class)"' \
    | head -1)

if [[ -n "$existing_pid" ]]; then
    kill "$existing_pid" 2>/dev/null || true
    [[ "$existing_class" == "$WINDOW_CLASS" ]] && exit 0
    sleep 0.15
fi

SELECTION_FILE=$(mktemp /tmp/clip-XXXXXX)
kitty --class "$WINDOW_CLASS" -e "$SCRIPT" --inner "$SELECTION_FILE"

if [[ -s "$SELECTION_FILE" ]]; then
    (setsid wl-copy < "$SELECTION_FILE"; rm -f "$SELECTION_FILE") &
    disown
else
    rm -f "$SELECTION_FILE"
fi
