#!/usr/bin/env bash
# ~/.config/hypr/scripts/popups/power.sh
# Fuzzy system power menu popup for Hyprland.

set -uo pipefail

SCRIPT="$(realpath "$0")"
WINDOW_CLASS="fzf-popup-power"

# ==== COLORS (Catppuccin Mocha) ====

C_BLUE='\x1b[38;2;137;180;250m'
C_YELLOW='\x1b[38;2;249;226;175m'
C_PURPLE='\x1b[38;2;203;166;247m'
C_ORANGE='\x1b[38;2;250;179;135m'
C_RED='\x1b[38;2;243;139;168m'
C_RESET='\x1b[0m'

# ==== ACTIONS ====

LOCK="Lock"
LOGOUT="Logout"
SUSPEND="Suspend"
REBOOT="Reboot"
SHUTDOWN="Shutdown"

# Format: "Icon|Color|Label|Command"
# Symbols: 󰌾 Lock, 󰗼 Logout, 󰖔 Suspend, 󰜉 Reboot, 󰐥 Shutdown
ACTIONS=(
    "󰌾|${C_BLUE}|${LOCK}|hyprlock"
    "󰗼|${C_YELLOW}|${LOGOUT}|uwsm stop"
    "󰖔|${C_PURPLE}|${SUSPEND}|systemctl suspend"
    "󰜉|${C_ORANGE}|${REBOOT}|systemctl reboot"
    "󰐥|${C_RED}|${SHUTDOWN}|systemctl poweroff"
)

CONFIRM_LABELS=("$LOGOUT" "$REBOOT" "$SHUTDOWN")

# ==== HELPERS ====

confirm() {
    printf '\e[?25l\n\n  %b%s%b\n  %b❯%b %s now? %b[Y/n]%b\n ' \
        "$C_YELLOW" "──────────────────" "$C_RESET" \
        "$C_YELLOW" "$C_RESET" \
        "$1" \
        "$C_BLUE" "$C_RESET" >/dev/tty
    read -r -n 1 reply </dev/tty
    printf '\e[?25h' >/dev/tty
    [[ "${reply,,}" != "n" ]]
}

list_actions() {
    for entry in "${ACTIONS[@]}"; do
        IFS='|' read -r icon color label cmd <<< "$entry"
        printf "%b%s%b  %-8s\t%s\n" "$color" "$icon" "$C_RESET" "$label" "$cmd"
    done
}

# ==== INNER: runs inside kitty ====

if [[ "${1:-}" == "--inner" ]]; then
    RESULT_FILE="${2:-}"

    selected=$(list_actions | fzf \
        --ansi \
        --style=full \
        --delimiter=$'\t' \
        --with-nth=1 \
        --prompt="> " \
        --pointer="▶" \
        --marker="✓" \
        --border-label=" System " \
        --no-info \
        --border=rounded \
        --height=100% \
        --gutter=' ' \
        --color=fg:#cdd6f4,bg:-1,hl:#cba6f7 \
        --color=fg+:#cdd6f4,bg+:-1,hl+:#89dceb \
        --color=info:#89b4fa,prompt:#89dceb,pointer:#89dceb \
    ) || exit 0

    label=$(echo "$selected" | cut -f1 | sed 's/^[^ ]* *//')
    cmd=$(echo "$selected" | cut -f2-)

    needs_confirm=false
    for cl in "${CONFIRM_LABELS[@]}"; do
        [[ "$label" == *"$cl"* ]] && needs_confirm=true && break
    done

    if [[ "$needs_confirm" == true ]]; then
        confirm "$cl" || exit 0
    fi

    printf "%s" "$cmd" > "$RESULT_FILE"
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

RESULT_FILE=$(mktemp /tmp/power-XXXXXX)
kitty --class "$WINDOW_CLASS" -e "$SCRIPT" --inner "$RESULT_FILE"

cmd=$(cat "$RESULT_FILE")
rm -f "$RESULT_FILE"
[[ -n "$cmd" ]] && bash -c "$cmd"
