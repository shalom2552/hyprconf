#!/usr/bin/env bash
# ~/.config/hypr/scripts/screenshot.sh
# Usage: screenshot.sh [region|full]  (default: region)

##############################
# SCREENSHOT
##############################

MODE="${1:-region}"
FILE="$HOME/Pictures/Screenshots/Screenshot-$(date +%F_%T).png"

mkdir -p "$HOME/Pictures/Screenshots"

case "$MODE" in
    full)
        grim - | tee "$FILE" | wl-copy
        notify-send -i "$FILE" "Full screen screenshot saved" -t 2000
        ;;
    region|*)
        grim -g "$(slurp)" - | tee "$FILE" | wl-copy
        notify-send -i "$FILE" "Region screenshot saved" -t 2000
        ;;
esac
