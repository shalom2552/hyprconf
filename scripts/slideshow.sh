#!/usr/bin/env bash

WALL_DIR="$HOME/Pictures/wallpapers"
RELOAD_SCRIPT="$HOME/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"
TRANSITIONS=(grow outer any wipe wave pixel center)
INTERVAL=${1:-30}

while true; do
    WALL=$(ls "$WALL_DIR"/*.{jpg,jpeg,png,gif} 2>/dev/null | shuf -n1)
    [ -z "$WALL" ] && sleep "$INTERVAL" && continue

    TRANSITION="${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}"

    cp "$WALL" /tmp/lock_bg.png
    pkill mpvpaper || true
    awww img "$WALL" --transition-type "$TRANSITION" --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1
    matugen image "$WALL" && bash "$RELOAD_SCRIPT"

    sleep "$INTERVAL"
done
