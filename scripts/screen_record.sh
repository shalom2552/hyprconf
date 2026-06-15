#!/usr/bin/env bash
# ~/.config/hypr/scripts/screen_record.sh
# Usage: screen_record.sh [-g]  (default: focused monitor; -g for region select)

##############################
# SCREEN RECORD
##############################

# Toggle: kill existing recording and let that instance finish + notify
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT wf-recorder
    exit 0
fi

dir="$HOME/Videos/ScreenRecordings"

# --- output file ---
mkdir -p "$dir"
filename="screen_record_$(date +%Y-%m-%d_%H-%M-%S).mp4"

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

ACTION=$(notify-send -i "$thumb" -t 6000 -A "default=Open folder" "Screen recording saved" "$filename")
# [ "$ACTION" = "default" ] && xdg-open "$dir" &
[ "$ACTION" = "default" ] && xdg-open "$dir/$filename" & # open the file itself
rm -f "$thumb"
