#!/bin/bash
# Cycle workspaces per monitor. With N monitors, each owns ws k, k+N, k+2N, ...
# Usage: workspace_switch.sh next | prev

DIR="$1"

N=$(hyprctl monitors -j | jq length)
PER=$(( (${HYPR_WORKSPACES:?} + N - 1) / N ))
read -r CURRENT_WS CURRENT_WINDOWS CURRENT_MON < <(hyprctl activeworkspace -j | jq -r '[.id, .windows, .monitor] | @tsv')
(( CURRENT_WS < 1 )) && exit 0

BASE=$(( (CURRENT_WS - 1) % N + 1 ))
POS=$(( (CURRENT_WS - 1) / N ))

if [[ "$DIR" == "next" ]]; then
    if [[ "$CURRENT_WINDOWS" -eq 0 && "$POS" -gt 0 ]]; then
        TARGET_POS=0  # empty workspace past first — wrap to start
    else
        TARGET_POS=$(( POS + 1 ))
        (( TARGET_POS >= PER )) && TARGET_POS=$(( PER - 1 ))
    fi
else
    TARGET_POS=$(( POS - 1 ))
    (( TARGET_POS < 0 )) && TARGET_POS=0
fi
TARGET=$(( BASE + TARGET_POS * N ))

hyprctl dispatch "hl.dsp.workspace.move({workspace='$TARGET', monitor='$CURRENT_MON'})" >/dev/null 2>&1
hyprctl dispatch "hl.dsp.focus({workspace=$TARGET})"

hyprctl dismissnotify -1 >/dev/null 2>&1
hyprctl notify -1 1500 "rgb(ffffff)" "$(( TARGET_POS + 1 ))"
