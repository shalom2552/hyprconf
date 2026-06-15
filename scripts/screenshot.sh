#!/usr/bin/env bash
# ~/.config/hypr/scripts/screenshot.sh
# Usage: screenshot.sh [region|full]  (default: region)

##############################
# SCREENSHOT
##############################

MODE="${1:-region}"
DIR="$HOME/Pictures/Screenshots"
FILE="$DIR/Screenshot-$(date +%F_%T).png"
mkdir -p "$DIR"

case "$MODE" in
    full)
        grim - | tee "$FILE" | wl-copy
        TITLE="Full screen screenshot saved"
        ;;
    region|*)
        grim -g "$(slurp)" - | tee "$FILE" | wl-copy
        TITLE="Region screenshot saved"
        ;;
esac

ACTION=$(notify-send -i "$FILE" -t 6000 -A "default=Open folder" "$TITLE" "$(basename "$FILE")")
[ "$ACTION" = "default" ] && xdg-open "$DIR" &
