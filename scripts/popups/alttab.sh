#!/usr/bin/env bash
# ~/.config/hypr/scripts/popups/alttab.sh
# Fuzzy window switcher popup for Hyprland.

set -uo pipefail

SCRIPT="$(realpath "$0")"
WINDOW_CLASS="fzf-popup-alttab"

# ==== COLORS (Tokyo Night) ====

C_BLUE='\x1b[38;2;122;162;247m'
C_PURPLE='\x1b[38;2;187;154;247m'
C_YELLOW='\x1b[38;2;224;175;104m'
C_RESET='\x1b[0m'

# ==== INNER: runs inside kitty ====

if [[ "${1:-}" == "--inner" ]]; then
    RESULT_FILE="${2:-}"
    active_addr=$(hyprctl activewindow -j | jq -r '.address')

    selected=$(
        hyprctl clients -j | jq -r '
            [.[] | select(.mapped and (.hidden | not) and .title != "" and (.class | startswith("fzf-popup") | not))]
            | sort_by(.workspace.id, .focusHistoryID)
            | .[]
            | [
                (if (.class | startswith("chrome-"))
                 then (.class | ltrimstr("chrome-") | split("__")[0] | ltrimstr("www."))
                 else .class end),
                .address
              ]
            | join("\t")
        ' | while IFS=$'\t' read -r name addr; do
            marker=" "
            [[ "$addr" == "$active_addr" ]] && marker="${C_YELLOW}◆${C_RESET}"
            printf "%b%s%b %s\t%s\n" \
                "$C_PURPLE" "$name" "$C_RESET" \
                "$marker" \
                "$addr"
        done | fzf \
            --ansi \
            --delimiter=$'\t' \
            --with-nth=1 \
            --prompt="window > " \
            --pointer="▶" \
            --marker="✓" \
            --border-label=" Windows " \
            --no-info \
            --border=rounded \
            --height=100% \
            --color=fg:#c0caf5,bg:-1,hl:#bb9af7 \
            --color=fg+:#c0caf5,bg+:-1,hl+:#7dcfff \
            --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
    ) || exit 0

    printf "%s" "$selected" | cut -f2 > "$RESULT_FILE"
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

RESULT_FILE=$(mktemp /tmp/alttab-XXXXXX)
kitty --class "$WINDOW_CLASS" -e "$SCRIPT" --inner "$RESULT_FILE"

addr=$(cat "$RESULT_FILE")
rm -f "$RESULT_FILE"
[[ -n "$addr" ]] && hyprctl dispatch focuswindow "address:$addr"
