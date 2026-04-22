#!/usr/bin/env bash
# ~/.config/hypr/scripts/popups/power.sh
# Fuzzy system power menu popup for Hyprland.

set -uo pipefail

SCRIPT="$(realpath "$0")"
WINDOW_CLASS="fzf-popup-power"

# ==== COLORS (Tokyo Night) ====

C_BLUE='\x1b[38;2;122;162;247m'
C_YELLOW='\x1b[38;2;224;175;104m'
C_PURPLE='\x1b[38;2;187;154;247m'
C_ORANGE='\x1b[38;2;255;158;100m'
C_RED='\x1b[38;2;247;118;142m'
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
    "󰌾|${C_BLUE}|${LOCK}|loginctl lock-session || hyprlock"
    "󰗼|${C_YELLOW}|${LOGOUT}|loginctl terminate-user \"$USER\""
    "󰖔|${C_PURPLE}|${SUSPEND}|systemctl suspend"
    "󰜉|${C_ORANGE}|${REBOOT}|systemctl reboot"
    "󰐥|${C_RED}|${SHUTDOWN}|systemctl poweroff"
)

CONFIRM_LABELS=("$LOGOUT" "$REBOOT" "$SHUTDOWN" "$LOCK")

# ==== HELPERS ====

confirm() {
    printf '\n  %b%s%b\n  %b❯%b %s now? %b[Y/n]%b ' \
        "$C_RED" "──────────────────" "$C_RESET" \
        "$C_YELLOW" "$C_RESET" \
        "$1" \
        "$C_BLUE" "$C_RESET" >/dev/tty
    read -r reply </dev/tty
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
        --delimiter=$'\t' \
        --with-nth=1 \
        --prompt="> " \
        --pointer="▶" \
        --marker="✓" \
        --border-label=" System " \
        --no-info \
        --border=rounded \
        --height=100% \
        --color=fg:#c0caf5,bg:-1,hl:#bb9af7 \
        --color=fg+:#c0caf5,bg+:-1,hl+:#7dcfff \
        --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff \
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

existing=$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class | startswith("fzf-popup")) | .class' \
    | head -1)

if [[ -n "$existing" ]]; then
    hyprctl dispatch killwindow "class:${existing}"
    [[ "$existing" == "$WINDOW_CLASS" ]] && exit 0
    sleep 0.05
fi

RESULT_FILE=$(mktemp /tmp/power-XXXXXX)
kitty --class "$WINDOW_CLASS" -e "$SCRIPT" --inner "$RESULT_FILE"

cmd=$(cat "$RESULT_FILE")
rm -f "$RESULT_FILE"
[[ -n "$cmd" ]] && bash -c "$cmd"
