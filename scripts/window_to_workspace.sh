#!/bin/bash
# Moves the active window to the next/prev workspace on the current monitor,
# following the same odd/even scheme as workspace_switch.sh.
# Usage: window_to_workspace.sh next | prev

DIR="$1"

ACTIVE=$(hyprctl activewindow -j)
ACTIVE_ADDR=$(echo "$ACTIVE" | jq -r '.address')

# No active window — just switch workspace, don't try to move anything
if [[ "$ACTIVE_ADDR" == "null" || -z "$ACTIVE_ADDR" ]]; then
    bash ~/.config/hypr/scripts/workspace_switch.sh "$DIR"
    exit 0
fi

CURRENT_WS=$(hyprctl activeworkspace -j | jq '.id')
CURRENT_MON=$(hyprctl monitors -j | jq -r \
    '.[] | select(.activeWorkspace.id == '"$CURRENT_WS"') | .name')

if (( CURRENT_WS % 2 == 1 )); then
    SET=(1 3 5 7)
else
    SET=(2 4 6 8)
fi

POS=0
for i in "${!SET[@]}"; do
    [[ "${SET[$i]}" -eq "$CURRENT_WS" ]] && POS=$i
done

if [[ "$DIR" == "next" ]]; then
    TARGET_POS=$(( POS + 1 ))
    (( TARGET_POS >= ${#SET[@]} )) && TARGET_POS=$(( ${#SET[@]} - 1 ))
else
    TARGET_POS=$(( POS - 1 ))
    (( TARGET_POS < 0 )) && TARGET_POS=0
fi
TARGET=${SET[$TARGET_POS]}

hyprctl dispatch moveworkspacetomonitor "$TARGET" "$CURRENT_MON" >/dev/null 2>&1
hyprctl dispatch movetoworkspace "$TARGET"

hyprctl dismissnotify -1 >/dev/null 2>&1
hyprctl notify -1 1500 "rgb(ffffff)" "$(( TARGET_POS + 1 ))"
