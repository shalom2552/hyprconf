#!/bin/bash

WALL_DIR="$HOME/Pictures/wallpapers"
TRANSITIONS=(grow outer any wipe wave pixel center)
TRANSITION="${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}"

WALL=$(ls "$WALL_DIR"/*.{jpg,jpeg,png} 2>/dev/null | shuf -n1)
[ -z "$WALL" ] && exit 1

MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
for MON in $MONITORS; do
    awww img --outputs "$MON" "$WALL" \
        --transition-type "$TRANSITION" \
        --transition-pos 0.5,0.5 \
        --transition-fps 144 \
        --transition-duration 1
done
