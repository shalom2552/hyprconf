#!/bin/bash

sleep 3
WALL=$(ls ~/Pictures/wallpapers/*.{jpg,jpeg,png} 2>/dev/null | shuf -n1)
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')

for MON in $MONITORS; do
    awww img --outputs "$MON" "$WALL"
done
