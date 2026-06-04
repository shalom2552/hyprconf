#!/usr/bin/bash

dir="$HOME/Videos/Screen_captures"

# --- output file ---
mkdir -p "$dir"
filename="screen_capture_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# --- region ---
if [[ "$1" == "-g" ]]; then
    geometry=$(slurp) || exit 1
    section=(-g "$geometry")
else
    output=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name') || exit 1
    section=(-o "$output")
fi

# --- record ---
wf-recorder -f "$dir/$filename" "${section[@]}" --audio="$(pactl get-default-sink).monitor"

# --- notify ---
thumb=$(mktemp --suffix=.png)
ffmpeg -y -i "$dir/$filename" -frames:v 1 "$thumb" 2>/dev/null
notify-send -i "$thumb" "Screen recording saved" "$filename" -t 2000
