#!/bin/bash
# Moves the active window to the next/prev workspace on the current monitor,
# following the same per-monitor scheme as workspace_switch.sh.
# Usage: window_to_workspace.sh next | prev

DIR="$1"

ACTIVE=$(hyprctl activewindow -j)
ACTIVE_ADDR=$(echo "$ACTIVE" | jq -r '.address')

# No active window — just switch workspace, don't try to move anything
if [[ "$ACTIVE_ADDR" == "null" || -z "$ACTIVE_ADDR" ]]; then
    bash ~/.config/hypr/scripts/workspace_switch.sh "$DIR"
    exit 0
fi

N=$(hyprctl monitors -j | jq length)
PER=$(( (${HYPR_WORKSPACES:?} + N - 1) / N ))
read -r CURRENT_WS CURRENT_MON < <(hyprctl activeworkspace -j | jq -r '[.id, .monitor] | @tsv')
(( CURRENT_WS < 1 )) && exit 0

BASE=$(( (CURRENT_WS - 1) % N + 1 ))
POS=$(( (CURRENT_WS - 1) / N ))

if [[ "$DIR" == "next" ]]; then
    TARGET_POS=$(( POS + 1 ))
    (( TARGET_POS >= PER )) && TARGET_POS=$(( PER - 1 ))
else
    TARGET_POS=$(( POS - 1 ))
    (( TARGET_POS < 0 )) && TARGET_POS=0
fi
TARGET=$(( BASE + TARGET_POS * N ))

hyprctl dispatch "hl.dsp.workspace.move({workspace='$TARGET', monitor='$CURRENT_MON'})" >/dev/null 2>&1
hyprctl dispatch "hl.dsp.window.move({workspace=$TARGET})"

hyprctl dismissnotify -1 >/dev/null 2>&1
hyprctl notify -1 1500 "rgb(ffffff)" "$(( TARGET_POS + 1 ))"
