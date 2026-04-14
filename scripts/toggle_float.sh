#!/bin/bash
# Toggle floating for the active window.
# If the window just became floating (had no prior float size), resize and center it.

BEFORE=$(hyprctl activewindow -j | jq -r '.floating')

hyprctl dispatch togglefloating

# Only resize if it just became floating
if [[ "$BEFORE" == "false" ]]; then
    # Get monitor logical dimensions (swap w/h for 90°/270° rotated monitors)
    read -r MON_W MON_H < <(hyprctl monitors -j | jq -r '
        .[] | select(.focused == true) |
        if (.transform % 2) == 1 then "\(.height) \(.width)"
        else "\(.width) \(.height)" end
    ')

    TARGET_W=$(( MON_W * 2 / 3 ))
    TARGET_H=$(( MON_H * 2 / 3 ))

    hyprctl dispatch resizeactive exact "$TARGET_W" "$TARGET_H"
    hyprctl dispatch centerwindow
fi
