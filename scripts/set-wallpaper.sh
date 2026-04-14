#!/bin/bash
sleep 3
WALL=$(ls ~/Pictures/wallpapers/*.{jpg,jpeg,png} 2>/dev/null | shuf -n1)
awww img --outputs DP-3 "$WALL"
awww img --outputs HDMI-A-1 "$WALL"
