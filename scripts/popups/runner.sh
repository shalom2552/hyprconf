#!/usr/bin/env bash
# ~/.config/hypr/scripts/popups/runner.sh
# Terminal command runner popup for Hyprland.

set -uo pipefail

WINDOW_CLASS="fzf-popup-runner"
PROMPT=$'\e[1;38;2;187;154;247m ❯ \e[0m'

read -r existing_pid existing_class < <(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class | startswith("fzf-popup")) | "\(.pid) \(.class)"' \
    | head -1)

if [[ -n "$existing_pid" ]]; then
    kill "$existing_pid" 2>/dev/null || true
    [[ "$existing_class" == "$WINDOW_CLASS" ]] && exit 0
    sleep 0.15
fi

kitty --class "$WINDOW_CLASS" -e zsh -c '
    read -r "cmd?$1" && [[ -n "$cmd" ]] || exit 0
    setsid zsh -ic "$cmd" </dev/null &>/dev/null &!
    sleep 0.1
' runner "$PROMPT"
