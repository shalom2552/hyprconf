#!/usr/bin/env bash
# ~/.config/hypr/scripts/screen_record.sh
# Usage: screen_record.sh  (pick screen, window or region in the share picker)

##############################
# SCREEN RECORD
##############################

# Toggle: kill existing recording and let that instance finish + notify
if pgrep -f '^gpu-screen-recorder' > /dev/null; then
    pkill -INT -f '^gpu-screen-recorder'
    exit 0
fi

dir="$HOME/Videos/ScreenRecordings"

# --- output file ---
mkdir -p "$dir"
filename="screen_record_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# --- indicator ---
hyprctl notify -1 7200000 "rgb(f38ba8)" "🔴" >/dev/null

# --- record ---
# timeout: 2 hours, signal: INT (kill) after 2 hours
timeout --signal=INT --kill-after=30s 2h gpu-screen-recorder -w portal -fallback-cpu-encoding yes -a default_output -o "$dir/$filename"
hyprctl eval "for _, n in ipairs(hl.notification.get()) do if n:get_text() == '🔴' then n:dismiss() end end" >/dev/null

# canceled in picker
[ -f "$dir/$filename" ] || exit 0

# --- notify ---
thumb=$(mktemp --suffix=.png)
ffmpeg -y -i "$dir/$filename" -frames:v 1 "$thumb" 2>/dev/null

ACTION=$(notify-send -i "$thumb" -t 6000 -A "default=Open folder" "Screen recording saved" "$filename")
# [ "$ACTION" = "default" ] && xdg-open "$dir" &
[ "$ACTION" = "default" ] && xdg-open "$dir/$filename" & # open the file itself
rm -f "$thumb"
