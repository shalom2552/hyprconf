#!/usr/bin/env bash
# ~/.config/hypr/scripts/quick-search.sh
# Quick google search popup window

set -uo pipefail

WINDOW_CLASS="chrome-www.google.com__-Default"

# get window address if exists
existing_addr=$(hyprctl clients -j 2>/dev/null \
    | jq -r --arg c "$WINDOW_CLASS" '.[] | select(.class == $c) | .address' \
    | head -1)

# If open, focus and close
if [[ -n "$existing_addr" ]]; then
    hyprctl dispatch "hl.dsp.focus({window='address:$existing_addr'})" >/dev/null
    hyprctl dispatch "hl.dsp.window.close()" >/dev/null
    exit 0
fi

# Open quick search
setsid chromium --app='https://www.google.com' >/dev/null 2>&1 &
disown
