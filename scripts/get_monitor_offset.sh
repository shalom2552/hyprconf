#!/bin/bash
# Writes primary monitor offset to /tmp/qs_monitor_offset as "x y w h"
# Primary = first non-rotated (landscape) monitor; falls back to first monitor.

hyprctl monitors -j \
    | jq -r '([.[] | select(.transform % 2 == 0)] | sort_by(.x) | .[0])
             // .[0]
             | [.x, .y, .width, .height] | join(" ")' \
    > /tmp/qs_monitor_offset
