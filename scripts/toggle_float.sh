#!/bin/bash

BEFORE=$(hyprctl activewindow -j | jq -r '.floating')

hyprctl dispatch "hl.dsp.window.float({action='toggle'})"

if [[ "$BEFORE" == "false" ]]; then
    read -r MON_W MON_H < <(hyprctl monitors -j | jq -r '
        .[] | select(.focused == true) |
        if (.transform % 2) == 1 then "\(.height) \(.width)"
        else "\(.width) \(.height)" end
    ')

    TARGET_W=$(( MON_W * 2 / 3 ))
    TARGET_H=$(( MON_H * 2 / 3 ))

    hyprctl dispatch "hl.dsp.window.resize({x=$TARGET_W, y=$TARGET_H, exact=true})"
    hyprctl dispatch "hl.dsp.window.center()"
fi
