#!/bin/bash
# Cycle workspaces per monitor: odd=left (HDMI-A-1), even=right (DP-3)
# Usage: workspace_switch.sh next | prev

DIR="$1"

read -r CURRENT_WS CURRENT_WINDOWS < <(hyprctl activeworkspace -j | jq -r '[.id, .windows] | @tsv')
CURRENT_MON=$(hyprctl monitors -j | jq -r '.[] | select(.activeWorkspace.id == '"$CURRENT_WS"') | .name')

(( CURRENT_WS % 2 == 1 )) && SET=(1 3 5 7) || SET=(2 4 6 8)

POS=0
for i in "${!SET[@]}"; do [[ "${SET[$i]}" -eq "$CURRENT_WS" ]] && POS=$i; done

if [[ "$DIR" == "next" ]]; then
    if [[ "$CURRENT_WINDOWS" -eq 0 && "$POS" -gt 0 ]]; then
        TARGET_POS=0  # empty workspace past first — wrap to start
    else
        TARGET_POS=$(( POS + 1 ))
        (( TARGET_POS >= ${#SET[@]} )) && TARGET_POS=$(( ${#SET[@]} - 1 ))
    fi
else
    TARGET_POS=$(( POS - 1 ))
    (( TARGET_POS < 0 )) && TARGET_POS=0
fi
TARGET=${SET[$TARGET_POS]}

hyprctl dispatch moveworkspacetomonitor "$TARGET" "$CURRENT_MON" >/dev/null 2>&1
hyprctl dispatch workspace "$TARGET"

hyprctl dismissnotify -1 >/dev/null 2>&1
hyprctl notify -1 1500 "rgb(ffffff)" "$(( TARGET_POS + 1 ))"
